//+------------------------------------------------------------------+
//| AG_RiskManager.mqh                                               |
//| Locks, EA daily loss, account protection, HWM equity drawdown,   |
//| combined loss, stress projected risk and the Risk Gate.          |
//| Formulas: Phase3_Quantitative_Formulas.md §6-§11                 |
//+------------------------------------------------------------------+
#ifndef AG_RISKMANAGER_MQH
#define AG_RISKMANAGER_MQH

#include "AG_Types.mqh"
#include "AG_Math.mqh"
#include "AG_Logger.mqh"
#include "AG_Environment.mqh"
#include "AG_BasketManager.mqh"
#include "AG_GridManager.mqh"

//--- persisted risk state
AGLock   g_locks[AG_LOCK_COUNT];
double   g_hwm=0.0;                 // equity high watermark, shifted by external flows
double   g_apBase=0.0;              // account protection base (equity at server day start, shifted by flows)
double   g_netFlow=0.0;             // cumulative deposits(+)/withdrawals(-) since baseline
datetime g_flowScanTime=0;          // last processed flow deal time
string   g_flowTickets="";          // ';'-list of flow deal tickets processed at g_flowScanTime
datetime g_dayStart=0;              // current server day start
double   g_dailySnap=0.0;           // EA open value at day start (§8)
long     g_lastResetToken=0;
bool     g_globalSafe=false;
string   g_globalSafeReason="";
long     g_nextBasketId=1;

//--- runtime metrics (recomputed each cycle)
double   g_eaDailyPL=0.0;
bool     g_dailyValid=false;
double   g_combinedNet=0.0;
double   g_eqDD=0.0, g_eqLimit=0.0;
double   g_apLoss=0.0, g_apLimit=0.0;
datetime g_lastCycleServer=0;

//--- daily realized cache
datetime g_dailyCacheDay=0;
int      g_dailyCacheDeals=-1;
int      g_dailyCacheOpenCount=-1;
double   g_dailyCacheRealized=0.0;
double   g_dailyCacheClosedFee=0.0;

//--- dirty flags for persistence
bool     g_stateDirty=false;        // critical: save this cycle
bool     g_stateSoftDirty=false;    // throttled save

void MarkDirty()     { g_stateDirty=true; }
void MarkSoftDirty() { g_stateSoftDirty=true; }

bool AnyLockActive()
  {
   for(int i=0; i<AG_LOCK_COUNT; i++)
      if(g_locks[i].active)
         return true;
   return false;
  }

bool AnySafeMode()
  {
   return (g_globalSafe || g_basket[AG_BUY].safeMode || g_basket[AG_SELL].safeMode);
  }

int HighestLock()
  {
   for(int i=0; i<AG_LOCK_COUNT; i++)
      if(g_locks[i].active)
         return i;
   return -1;
  }

void ClearLock(const int id)
  {
   g_locks[id].active=false;
   g_locks[id].triggerTime=0;
   g_locks[id].triggerValue=0.0;
   g_locks[id].threshold=0.0;
   g_locks[id].lockDate=0;
   g_locks[id].reason="";
  }

long NowServerMsc(const MqlTick &t)
  {
   long a=(long)t.time_msc;
   long b=(long)TimeTradeServer()*1000;
   return (a>b ? a : b);
  }

//+------------------------------------------------------------------+
//| External cash flows (deposit/withdrawal/credit/bonus)            |
//+------------------------------------------------------------------+
bool FlowAlreadyProcessed(const ulong tk)
  {
   return (StringFind(";"+g_flowTickets+";",";"+(string)tk+";")>=0);
  }

//--- fresh baseline: mark all existing flow deals as processed WITHOUT applying them
void InitFlowBaseline()
  {
   g_netFlow=0.0;
   g_flowTickets="";
   g_flowScanTime=TimeCurrent();
   if(!HistorySelect(0,TimeCurrent()+86400))
      return;
   int n=HistoryDealsTotal();
   datetime maxT=0;
   for(int i=0; i<n; i++)
     {
      ulong tk=HistoryDealGetTicket(i);
      if(tk==0)
         continue;
      long type=HistoryDealGetInteger(tk,DEAL_TYPE);
      if(type!=DEAL_TYPE_BALANCE && type!=DEAL_TYPE_CREDIT && type!=DEAL_TYPE_BONUS)
         continue;
      datetime tm=(datetime)HistoryDealGetInteger(tk,DEAL_TIME);
      if(tm>maxT)
        {
         maxT=tm;
         g_flowTickets="";
        }
      if(tm==maxT)
         g_flowTickets+=(StringLen(g_flowTickets)>0 ? ";" : "")+(string)tk;
     }
   if(maxT>g_flowScanTime)
      g_flowScanTime=maxT;
   else
      if(maxT<g_flowScanTime)
         g_flowTickets="";
  }

//--- throttle: full flow scan only when balance/credit changed, every 60 s, or when forced
double   g_flowLastBalance=-1.0;
double   g_flowLastCredit=-1.0;
datetime g_flowLastScan=0;

//--- applies new flows to HWM and AP base. Returns false if history unavailable.
bool UpdateExternalFlows(const bool force=false)
  {
   double bal=AccountInfoDouble(ACCOUNT_BALANCE);
   double cre=AccountInfoDouble(ACCOUNT_CREDIT);
   datetime nowSrv=TimeTradeServer();
   if(!force && bal==g_flowLastBalance && cre==g_flowLastCredit && (nowSrv-g_flowLastScan)<60)
      return true;
   g_flowLastBalance=bal;
   g_flowLastCredit=cre;
   g_flowLastScan=nowSrv;
   datetime from=g_flowScanTime-60;
   if(from<0)
      from=0;
   if(!HistorySelect(from,TimeCurrent()+86400))
      return false;
   int n=HistoryDealsTotal();
   for(int i=0; i<n; i++)
     {
      ulong tk=HistoryDealGetTicket(i);
      if(tk==0)
         continue;
      long type=HistoryDealGetInteger(tk,DEAL_TYPE);
      if(type!=DEAL_TYPE_BALANCE && type!=DEAL_TYPE_CREDIT && type!=DEAL_TYPE_BONUS)
         continue;
      datetime tm=(datetime)HistoryDealGetInteger(tk,DEAL_TIME);
      if(tm<g_flowScanTime)
         continue;
      if(FlowAlreadyProcessed(tk))
         continue;
      double amt=HistoryDealGetDouble(tk,DEAL_PROFIT);
      g_hwm+=amt;
      g_apBase+=amt;
      g_netFlow+=amt;
      if(tm>g_flowScanTime)
        {
         g_flowScanTime=tm;
         g_flowTickets="";
        }
      g_flowTickets+=(StringLen(g_flowTickets)>0 ? ";" : "")+(string)tk;
      g_log.Event("EXTERNAL_FLOW",-1,0,0,0,0.0,amt,0.0,0.0,0,
                  "type="+(string)type+" amount="+DoubleToString(amt,2)+" hwm="+DoubleToString(g_hwm,2)+" apBase="+DoubleToString(g_apBase,2));
      MarkDirty();
     }
   return true;
  }

//+------------------------------------------------------------------+
//| EA daily P/L (§8). Uses g_basket[].netOpen from this cycle scan. |
//+------------------------------------------------------------------+
bool ComputeEADailyPL()
  {
   if(!HistorySelect(g_dayStart,TimeCurrent()+86400))
      return false;
   int n=HistoryDealsTotal();
   int openCount=g_basket[AG_BUY].count+g_basket[AG_SELL].count;
   if(!(g_dailyCacheDay==g_dayStart && g_dailyCacheDeals==n && g_dailyCacheOpenCount==openCount))
     {
      //--- collect OUT deals on our symbol (ownership resolved afterwards)
      long   opid[];
      double oval[];
      for(int i=0; i<n; i++)
        {
         ulong tk=HistoryDealGetTicket(i);
         if(tk==0)
            continue;
         if(HistoryDealGetString(tk,DEAL_SYMBOL)!=g_spec.name)
            continue;
         long entry=HistoryDealGetInteger(tk,DEAL_ENTRY);
         if(entry!=DEAL_ENTRY_OUT && entry!=DEAL_ENTRY_OUT_BY)
            continue;
         int k=ArraySize(opid);
         ArrayResize(opid,k+1);
         ArrayResize(oval,k+1);
         opid[k]=HistoryDealGetInteger(tk,DEAL_POSITION_ID);
         oval[k]=HistoryDealGetDouble(tk,DEAL_PROFIT)+HistoryDealGetDouble(tk,DEAL_SWAP)
                 +HistoryDealGetDouble(tk,DEAL_COMMISSION)+HistoryDealGetDouble(tk,DEAL_FEE);
        }
      double realized=0.0,closedFee=0.0;
      long   donePid[];
      for(int k=0; k<ArraySize(opid); k++)
        {
         long mg;
         if(!GetOwnerMagic(opid[k],mg))
            return false;                   // cannot attribute => daily unknown (fail-closed)
         if(mg!=g_cfg.magicBuy && mg!=g_cfg.magicSell)
            continue;
         realized+=oval[k];
         if(AG_FindLong(donePid,opid[k])>=0)
            continue;
         int d=ArraySize(donePid);
         ArrayResize(donePid,d+1);
         donePid[d]=opid[k];
         //--- fully closed (no longer open in either basket) => its entry fees belong here
         bool stillOpen=false;
         for(int s=0; s<AG_SIDES && !stillOpen; s++)
            for(int j=0; j<g_basket[s].count; j++)
               if(g_basket[s].pos[j].pid==opid[k])
                 {
                  stillOpen=true;
                  break;
                 }
         if(!stillOpen)
           {
            double fee,fin;
            bool out;
            long m2,tm;
            if(!ReadPositionHistory(opid[k],fee,fin,out,m2,tm))
               return false;
            closedFee+=fee;
           }
        }
      g_dailyCacheDay=g_dayStart;
      g_dailyCacheDeals=n;
      g_dailyCacheOpenCount=openCount;
      g_dailyCacheRealized=realized;
      g_dailyCacheClosedFee=closedFee;
     }
   double openNow=g_basket[AG_BUY].netOpen+g_basket[AG_SELL].netOpen;
   g_eaDailyPL=AG_CalcDailyPL(g_dailyCacheRealized,g_dailyCacheClosedFee,openNow,g_dailySnap);
   return true;
  }

//+------------------------------------------------------------------+
//| New server day: snapshot + AP base. Late snapshot => Snap = 0.   |
//+------------------------------------------------------------------+
void NewServerDayCheck()
  {
   datetime today=AG_DayStart(TimeTradeServer());
   if(today==g_dayStart)
      return;
   bool continuous=(g_lastCycleServer>0 && (TimeTradeServer()-g_lastCycleServer)<=120);
   double openNow=g_basket[AG_BUY].netOpen+g_basket[AG_SELL].netOpen;
   g_dayStart=today;
   g_dailySnap=continuous ? openNow : 0.0;     // conservative when the boundary was not observed live
   g_apBase=AccountInfoDouble(ACCOUNT_EQUITY);
   g_dailyCacheDeals=-1;
   g_log.Event(continuous ? "NEW_SERVER_DAY" : "NEW_SERVER_DAY_LATE_SNAPSHOT",-1,0,0,0,0.0,g_dailySnap,0.0,0.0,0,
               "day="+TimeToString(today,TIME_DATE)+" snap="+DoubleToString(g_dailySnap,2)+" apBase="+DoubleToString(g_apBase,2));
   MarkDirty();
  }

//+------------------------------------------------------------------+
void ComputeAccountMetrics()
  {
   double eq=AccountInfoDouble(ACCOUNT_EQUITY);
   if(eq>g_hwm)
     {
      g_hwm=eq;
      MarkSoftDirty();
     }
   AG_DrawdownBreached(g_hwm,eq,g_cfg.maxEquityDDPct,g_eqDD,g_eqLimit);
   AG_DrawdownBreached(g_apBase,eq,g_cfg.accountProtPct,g_apLoss,g_apLimit);
   g_combinedNet=g_basket[AG_BUY].netOpen+g_basket[AG_SELL].netOpen;
  }

//+------------------------------------------------------------------+
void ActivateLock(const int id,const double value,const double threshold,const string reason)
  {
   if(g_locks[id].active)
      return;
   g_locks[id].active=true;
   g_locks[id].triggerTime=TimeTradeServer();
   g_locks[id].triggerValue=value;
   g_locks[id].threshold=threshold;
   g_locks[id].lockDate=g_dayStart;
   g_locks[id].reason=reason;
   g_log.Event("LOCK_"+LockName(id),-1,0,0,0,0.0,value,threshold,0.0,0,reason);
   MarkDirty();
  }

int LockCloseReason(const int id)
  {
   switch(id)
     {
      case LOCK_ACCOUNT_PROTECTION: return CR_LOCK_ACCOUNT;
      case LOCK_EQUITY_DD:          return CR_LOCK_EQUITY;
      case LOCK_COMBINED_LOSS:      return CR_LOCK_COMBINED;
      case LOCK_DAILY_LOSS:         return CR_LOCK_DAILY;
     }
   return CR_NONE;
  }

//+------------------------------------------------------------------+
//| Evaluates all locks in priority order. Account-level triggers    |
//| re-scan cash flows once before locking (avoid false withdrawal). |
//+------------------------------------------------------------------+
void EvaluateRiskLocks()
  {
   double eq=AccountInfoDouble(ACCOUNT_EQUITY);
   bool apHit=AG_DrawdownBreached(g_apBase,eq,g_cfg.accountProtPct,g_apLoss,g_apLimit);
   bool eqHit=AG_DrawdownBreached(g_hwm,eq,g_cfg.maxEquityDDPct,g_eqDD,g_eqLimit);
   if((apHit && !g_locks[LOCK_ACCOUNT_PROTECTION].active) || (eqHit && !g_locks[LOCK_EQUITY_DD].active))
     {
      UpdateExternalFlows(true);
      eq=AccountInfoDouble(ACCOUNT_EQUITY);
      apHit=AG_DrawdownBreached(g_apBase,eq,g_cfg.accountProtPct,g_apLoss,g_apLimit);
      eqHit=AG_DrawdownBreached(g_hwm,eq,g_cfg.maxEquityDDPct,g_eqDD,g_eqLimit);
     }
   if(apHit)
      ActivateLock(LOCK_ACCOUNT_PROTECTION,g_apLoss,g_apLimit,
                   "Account equity loss "+DoubleToString(g_apLoss,2)+" >= "+DoubleToString(g_apLimit,2)+" (base "+DoubleToString(g_apBase,2)+")");
   if(eqHit)
      ActivateLock(LOCK_EQUITY_DD,g_eqDD,g_eqLimit,
                   "Equity DD "+DoubleToString(g_eqDD,2)+" >= "+DoubleToString(g_eqLimit,2)+" (HWM "+DoubleToString(g_hwm,2)+")");
   if(g_combinedNet<=-g_cfg.maxCombinedLoss+AG_EPS_MONEY)
      ActivateLock(LOCK_COMBINED_LOSS,g_combinedNet,g_cfg.maxCombinedLoss,
                   "Combined net "+DoubleToString(g_combinedNet,2)+" <= -"+DoubleToString(g_cfg.maxCombinedLoss,2));
   if(g_dailyValid && g_eaDailyPL<=-g_cfg.dailyLoss+AG_EPS_MONEY)
      ActivateLock(LOCK_DAILY_LOSS,g_eaDailyPL,g_cfg.dailyLoss,
                   "EA daily P/L "+DoubleToString(g_eaDailyPL,2)+" <= -"+DoubleToString(g_cfg.dailyLoss,2));
  }

//+------------------------------------------------------------------+
//| Common verification before any lock is cleared (Phase 2 §4.3).   |
//+------------------------------------------------------------------+
bool VerifyBeforeUnlock(string &why,const bool stateWriteOk)
  {
   for(int s=0; s<AG_SIDES; s++)
     {
      if(g_basket[s].HasIntent())
        { why=SideText(s)+" has an unreconciled intent"; return false; }
      int st=g_basket[s].state;
      if(!(st==BS_IDLE || (st==BS_ACTIVE && g_basket[s].budgetVerified)))
        { why=SideText(s)+" basket state "+BasketStateText(st)+" not verified"; return false; }
      if(g_basket[s].wrongType)
        { why=SideText(s)+" has wrong-type positions with EA magic"; return false; }
     }
   if(!stateWriteOk)
     { why="state file not writable"; return false; }
   return true;
  }

//--- Daily lock: auto reset on a later server day when no higher lock / SAFE MODE
void DailyAutoReset(const bool stateWriteOk)
  {
   if(!g_locks[LOCK_DAILY_LOSS].active)
      return;
   if(g_dayStart<=g_locks[LOCK_DAILY_LOSS].lockDate)
      return;
   if(g_locks[LOCK_ACCOUNT_PROTECTION].active || g_locks[LOCK_EQUITY_DD].active || g_locks[LOCK_COMBINED_LOSS].active || AnySafeMode())
      return;
   string why;
   if(!VerifyBeforeUnlock(why,stateWriteOk))
      return;
   ClearLock(LOCK_DAILY_LOSS);
   g_log.Event("UNLOCK_DAILY_LOSS_AUTO",-1,0,0,0,0.0,g_eaDailyPL,g_cfg.dailyLoss,0.0,0,"new server day "+TimeToString(g_dayStart,TIME_DATE));
   MarkDirty();
  }

//+------------------------------------------------------------------+
//| Stress projection for the basket + optional new order (§6).      |
//+------------------------------------------------------------------+
bool EstimateWorstCaseRisk(CBasket &b,const double volNew,const MqlTick &t,const double atr1,double &projLoss,string &reason)
  {
   projLoss=0.0;
   if(!MathIsValidNumber(atr1) || atr1<=0.0 || t.bid<=0.0 || t.ask<=0.0)
     { reason="REJECT_RISK_CALC_FAILED"; return false; }
   double slip  =g_cfg.slippageStressPts*g_spec.point;
   double spread=t.ask-t.bid;
   double sprAdd=MathMax(0.0,(g_cfg.spreadStressMult-1.0)*spread);
   double move  =atr1*g_cfg.stressMoveATR;
   double pNew,pStr;
   if(b.side==AG_BUY)
     {
      pNew=t.ask+slip;
      pStr=t.bid-move-slip-sprAdd;
     }
   else
     {
      pNew=t.bid-slip;
      pStr=t.ask+move+slip+sprAdd;
     }
   if(pStr<=0.0)
     { reason="REJECT_RISK_CALC_FAILED"; return false; }
   double rate=FeeRatePerLot();
   double plStr=0.0;
   for(int i=0; i<b.count; i++)
     {
      double pl=0.0;
      if(!OrderCalcProfit(b.otype,g_spec.name,b.pos[i].volume,b.pos[i].openPrice,pStr,pl) || !MathIsValidNumber(pl))
        { reason="REJECT_RISK_CALC_FAILED"; return false; }
      plStr+=pl+b.pos[i].swap+b.pos[i].feeIn;
     }
   if(volNew>0.0)
     {
      double pl=0.0;
      if(!OrderCalcProfit(b.otype,g_spec.name,volNew,pNew,pStr,pl) || !MathIsValidNumber(pl))
        { reason="REJECT_RISK_CALC_FAILED"; return false; }
      plStr+=pl+rate*volNew;
     }
   plStr+=rate*(b.totalVol+volNew);
   projLoss=MathMax(0.0,-plStr);
   return true;
  }

//+------------------------------------------------------------------+
//| Risk Gate G1..G7 (§7). Must be called immediately before send.   |
//+------------------------------------------------------------------+
bool RiskGate(CBasket &b,CBasket &o,const int kind,const double vol,const MqlTick &t,const double atr1,
              const double candidateEffSL,double &projLoss,double &addLoss,string &reason)
  {
   projLoss=0.0;
   addLoss=0.0;
//--- G7 volume / layers first (cheap, no money math)
   if(!IsValidSymbolVolume(vol))
     { reason="REJECT_INVALID_VOLUME"; return false; }
   if(b.count+1>g_cfg.maxLayers)
     { reason="REJECT_MAX_LAYERS"; return false; }
   if(VolSteps(b.totalVol)+VolSteps(vol)>VolSteps(g_cfg.maxSideLots))
     { reason="REJECT_MAX_SIDE_LOTS"; return false; }
   if(!b.historyOk || !o.historyOk)
     { reason="REJECT_HISTORY_UNAVAILABLE"; return false; }
   if(!g_dailyValid)
     { reason="REJECT_DAILY_UNKNOWN"; return false; }

//--- G1 basket budget
   double effSL=(kind==INTENT_ENTRY) ? candidateEffSL : b.effSL;
   if(effSL<=0.0 || !MathIsValidNumber(effSL))
     { reason="REJECT_INVALID_SL"; return false; }
   if(kind==INTENT_ADD && !b.budgetVerified)
     { reason="REJECT_BUDGET_UNVERIFIED"; return false; }
   if(!EstimateWorstCaseRisk(b,vol,t,atr1,projLoss,reason))
      return false;
   if(projLoss>effSL+AG_EPS_MONEY)
     {
      reason=(kind==INTENT_ENTRY && vol<=g_spec.volMin+g_spec.volStep*1e-6) ? "REJECT_MIN_VOLUME_EXCEEDS_RISK_BUDGET" : "REJECT_BASKET_BUDGET";
      return false;
     }
   if(kind==INTENT_ENTRY && vol>g_spec.volMin+g_spec.volStep*1e-6)
     {
      //--- informative: would even the minimum volume fit? (never used to change the volume)
      double pMin=0.0;
      string r2;
      if(EstimateWorstCaseRisk(b,g_spec.volMin,t,atr1,pMin,r2) && pMin>effSL+AG_EPS_MONEY)
        { reason="REJECT_MIN_VOLUME_EXCEEDS_RISK_BUDGET"; return false; }
     }
   addLoss=AG_CalcAddLoss(projLoss,b.netOpen);

//--- G2 combined
   double otherLoss=MathMax(0.0,-o.netOpen);
   if(projLoss+otherLoss>g_cfg.maxCombinedLoss+AG_EPS_MONEY)
     { reason="REJECT_COMBINED_LOSS"; return false; }
//--- G3 daily headroom
   if(MathMax(0.0,-g_eaDailyPL)+addLoss>g_cfg.dailyLoss+AG_EPS_MONEY)
     { reason="REJECT_DAILY_HEADROOM"; return false; }
//--- G4 equity DD headroom
   if(g_eqDD+addLoss>g_eqLimit+AG_EPS_MONEY)
     { reason="REJECT_EQUITY_DD_HEADROOM"; return false; }
//--- G5 account protection headroom
   if(g_apLoss+addLoss>g_apLimit+AG_EPS_MONEY)
     { reason="REJECT_ACCOUNT_PROTECTION_HEADROOM"; return false; }
//--- G6 margin (OrderCheck is done again in Execution right before OrderSend)
   double price=(b.side==AG_BUY) ? t.ask : t.bid;
   double margin=0.0;
   if(!OrderCalcMargin(b.otype,g_spec.name,vol,price,margin) || !MathIsValidNumber(margin) || margin<0.0)
     { reason="REJECT_MARGIN_CALC_FAILED"; return false; }
   if(margin>AccountInfoDouble(ACCOUNT_MARGIN_FREE)*g_cfg.maxMarginUsage)
     { reason="REJECT_MARGIN"; return false; }
   reason="RISK_GATE_PASS";
   return true;
  }

#endif
//+------------------------------------------------------------------+
