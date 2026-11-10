//+------------------------------------------------------------------+
//| XAUUSDc_AdaptiveGrid.mq5                                         |
//| Adaptive Mean-Reversion Grid, M1, independent BUY/SELL baskets.  |
//| No martingale, no lot escalation, bounded grid, risk-gated.      |
//|                                                                  |
//| Design documents: Documentation/Phase0..Phase3                   |
//| STATUS: source written without MetaEditor - NOT COMPILED here.   |
//+------------------------------------------------------------------+
#property copyright "XAUUSDc Adaptive Grid"
#property version   "1.00"
#property description "Adaptive mean-reversion grid for XAUUSDc M1 (hedging accounts only)."
#property description "Software basket SL is a trigger, not a guaranteed maximum loss."

#include <AdaptiveGrid\AG_Types.mqh>
#include <AdaptiveGrid\AG_Math.mqh>
#include <AdaptiveGrid\AG_Logger.mqh>
#include <AdaptiveGrid\AG_Environment.mqh>
#include <AdaptiveGrid\AG_Indicators.mqh>
#include <AdaptiveGrid\AG_Signals.mqh>
#include <AdaptiveGrid\AG_GridManager.mqh>
#include <AdaptiveGrid\AG_BasketManager.mqh>
#include <AdaptiveGrid\AG_RiskManager.mqh>
#include <AdaptiveGrid\AG_Persistence.mqh>
#include <AdaptiveGrid\AG_Execution.mqh>
#include <AdaptiveGrid\AG_Recovery.mqh>

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "01. GENERAL"
input string            InpSymbol                         = "XAUUSDc";
input ENUM_TIMEFRAMES   InpTF                             = PERIOD_M1;
input long              MagicBuy                          = 10001;
input long              MagicSell                         = 10002;
input bool              AllowBuy                          = true;
input bool              AllowSell                         = true;
input string            RequiredAccountCurrency           = "USC";

input group "02. GRID"
input double            InitialLot                        = 0.01;
input double            LotMultiplier                     = 1.0;   // must stay 1.0 (validated)
input int               MaxLayers                         = 5;
input double            MaxSideLots                       = 0.05;
input int               ATRPeriod                         = 14;
input double            ATRMultiplier                     = 0.80;
input double            MinGridUSD                        = 0.50;  // price units
input double            MaxGridUSD                        = 1.50;  // price units
input double            MaxATR_USD                        = 3.00;  // ATR(M1) above this blocks new orders

input group "03. ENTRY FILTER"
input ENUM_SIGNAL_MODE  SignalMode                        = SIGNAL_TWO_CANDLE;
input int               RSIPeriod                         = 7;
input double            RSI_Buy                           = 25.0;
input double            RSI_Sell                          = 75.0;
input int               BBPeriod                          = 20;
input double            BBDeviation                       = 2.0;
input int               ADXPeriod                         = 14;
input double            MaxADX                            = 22.0;

input group "04. BASKET MANAGEMENT"
input ENUM_BUDGET_BASE  BasketBudgetBase                  = BUDGET_BASE_EQUITY;
input double            BasketRiskPercent                 = 1.0;
input bool              UseBasketSLFromRiskBudget         = true;
input double            BasketTP_AccountCurrency          = 1.50;
input double            BasketSL_AccountCurrency          = 5.00;  // used when UseBasketSLFromRiskBudget=false; never wider than budget

input group "05. ACCOUNT PROTECTION"
input double            MaxCombinedLoss_AccountCurrency   = 10.00;
input double            DailyLoss_AccountCurrency         = 10.00; // EA-scope (symbol + magics)
input double            MaxEquityDDPercent                = 5.0;   // account equity vs flow-adjusted HWM
input double            AccountProtectionDailyLossPercent = 3.0;   // account equity vs server-day start
input bool              CloseAllOnRiskLimit               = true;

input group "06. RISK STRESS"
input double            StressMoveATR                     = 1.0;
input double            SlippageStressPoints              = 30.0;
input double            SpreadStressMultiplier            = 1.0;
input double            CommissionPerLotEstimate          = 0.0;   // per lot per side, used until a real deal is observed
input double            MaxMarginUsage                    = 0.50;

input group "07. EXECUTION"
input double            MaxSpreadUSD                      = 0.30;  // Ask-Bid in price units
input int               MaxSlippagePoints                 = 30;    // request deviation
input int               CooldownSeconds                   = 60;
input int               MaxCloseRetries                   = 5;
input int               CloseRetryDelayMs                 = 500;
input int               PendingTimeoutMs                  = 10000;
input int               ReconcileTimeoutSec               = 30;
input int               SessionEdgeBlockMinutes           = 15;
input bool              UseNewsFilter                     = false; // not implemented: true blocks trading (fail-closed)

input group "08. RECOVERY & RESET"
input bool              EnablePersistentState             = true;
input bool              SafeModeCloseIfRiskStateUnknown   = true;
input ENUM_RESET_TARGET ResetLockTarget                   = RESET_NONE;
input long              ResetLockToken                    = 0;     // change to a NEW number to perform one reset

input group "09. DIAGNOSTICS"
input bool              EnableCSVLog                      = true;
input bool              EnableDetailedJournal             = true;
input bool              ShowDashboard                     = true;

//+------------------------------------------------------------------+
//| Globals                                                          |
//+------------------------------------------------------------------+
bool     g_inCycle=false;
bool     g_initOk=false;
MqlTick  g_tick;
bool     g_newsWarned=false;
bool     g_tokenWarned=false;
string   g_blockReason="";
bool     g_flowOk=true;

//+------------------------------------------------------------------+
void LoadConfig()
  {
   g_cfg.symbol=InpSymbol;
   g_cfg.tf=InpTF;
   g_cfg.magicBuy=MagicBuy;
   g_cfg.magicSell=MagicSell;
   g_cfg.allowBuy=AllowBuy;
   g_cfg.allowSell=AllowSell;
   g_cfg.requiredCurrency=RequiredAccountCurrency;
   g_cfg.initialLot=InitialLot;
   g_cfg.lotMultiplier=LotMultiplier;
   g_cfg.maxLayers=MaxLayers;
   g_cfg.maxSideLots=MaxSideLots;
   g_cfg.atrPeriod=ATRPeriod;
   g_cfg.atrMultiplier=ATRMultiplier;
   g_cfg.minGrid=MinGridUSD;
   g_cfg.maxGrid=MaxGridUSD;
   g_cfg.maxATR=MaxATR_USD;
   g_cfg.signalMode=SignalMode;
   g_cfg.rsiPeriod=RSIPeriod;
   g_cfg.rsiBuy=RSI_Buy;
   g_cfg.rsiSell=RSI_Sell;
   g_cfg.bbPeriod=BBPeriod;
   g_cfg.bbDev=BBDeviation;
   g_cfg.adxPeriod=ADXPeriod;
   g_cfg.maxADX=MaxADX;
   g_cfg.budgetBase=BasketBudgetBase;
   g_cfg.basketRiskPct=BasketRiskPercent;
   g_cfg.useSLFromBudget=UseBasketSLFromRiskBudget;
   g_cfg.basketTP=BasketTP_AccountCurrency;
   g_cfg.basketSL=BasketSL_AccountCurrency;
   g_cfg.maxCombinedLoss=MaxCombinedLoss_AccountCurrency;
   g_cfg.dailyLoss=DailyLoss_AccountCurrency;
   g_cfg.maxEquityDDPct=MaxEquityDDPercent;
   g_cfg.accountProtPct=AccountProtectionDailyLossPercent;
   g_cfg.closeAllOnRiskLimit=CloseAllOnRiskLimit;
   g_cfg.stressMoveATR=StressMoveATR;
   g_cfg.slippageStressPts=SlippageStressPoints;
   g_cfg.spreadStressMult=SpreadStressMultiplier;
   g_cfg.commissionPerLotEst=CommissionPerLotEstimate;
   g_cfg.maxMarginUsage=MaxMarginUsage;
   g_cfg.maxSpread=MaxSpreadUSD;
   g_cfg.maxSlippagePts=MaxSlippagePoints;
   g_cfg.cooldownSec=CooldownSeconds;
   g_cfg.maxCloseRetries=MaxCloseRetries;
   g_cfg.closeRetryDelayMs=CloseRetryDelayMs;
   g_cfg.pendingTimeoutMs=PendingTimeoutMs;
   g_cfg.reconcileTimeoutSec=ReconcileTimeoutSec;
   g_cfg.sessionEdgeMin=SessionEdgeBlockMinutes;
   g_cfg.useNewsFilter=UseNewsFilter;
   g_cfg.enablePersistentState=EnablePersistentState;
   g_cfg.safeModeCloseIfUnknown=SafeModeCloseIfRiskStateUnknown;
   g_cfg.resetTarget=ResetLockTarget;
   g_cfg.resetToken=ResetLockToken;
   g_cfg.enableCSV=EnableCSVLog;
   g_cfg.detailedJournal=EnableDetailedJournal;
   g_cfg.showDashboard=ShowDashboard;
  }

void LogInputs()
  {
   PrintFormat("[AG] INPUTS symbol=%s magicBuy=%I64d magicSell=%I64d allowBuy=%d allowSell=%d ccy=%s",
               g_cfg.symbol,g_cfg.magicBuy,g_cfg.magicSell,(int)g_cfg.allowBuy,(int)g_cfg.allowSell,g_cfg.requiredCurrency);
   PrintFormat("[AG] INPUTS lot=%.2f mult=%.2f maxLayers=%d maxSideLots=%.2f ATR=%d x%.2f grid=[%.2f,%.2f] maxATR=%.2f",
               g_cfg.initialLot,g_cfg.lotMultiplier,g_cfg.maxLayers,g_cfg.maxSideLots,g_cfg.atrPeriod,g_cfg.atrMultiplier,g_cfg.minGrid,g_cfg.maxGrid,g_cfg.maxATR);
   PrintFormat("[AG] INPUTS signal=%s RSI(%d) buy<=%.1f sell>=%.1f BB(%d,%.1f) ADX(%d)<%.1f",
               EnumToString(g_cfg.signalMode),g_cfg.rsiPeriod,g_cfg.rsiBuy,g_cfg.rsiSell,g_cfg.bbPeriod,g_cfg.bbDev,g_cfg.adxPeriod,g_cfg.maxADX);
   PrintFormat("[AG] INPUTS budgetBase=%s risk%%=%.2f slFromBudget=%d TP=%.2f SL=%.2f combined=%.2f daily=%.2f eqDD%%=%.2f ap%%=%.2f closeAll=%d",
               EnumToString(g_cfg.budgetBase),g_cfg.basketRiskPct,(int)g_cfg.useSLFromBudget,g_cfg.basketTP,g_cfg.basketSL,
               g_cfg.maxCombinedLoss,g_cfg.dailyLoss,g_cfg.maxEquityDDPct,g_cfg.accountProtPct,(int)g_cfg.closeAllOnRiskLimit);
   PrintFormat("[AG] INPUTS stressATR=%.2f slipStressPts=%.1f spreadMult=%.2f commEst=%.4f marginUse=%.2f maxSpread=%.3f dev=%d cooldown=%d",
               g_cfg.stressMoveATR,g_cfg.slippageStressPts,g_cfg.spreadStressMult,g_cfg.commissionPerLotEst,g_cfg.maxMarginUsage,
               g_cfg.maxSpread,g_cfg.maxSlippagePts,g_cfg.cooldownSec);
   PrintFormat("[AG] INPUTS closeRetries=%d retryMs=%d pendingMs=%d reconcileSec=%d sessionEdge=%d news=%d persist=%d safeClose=%d reset=%s token=%I64d",
               g_cfg.maxCloseRetries,g_cfg.closeRetryDelayMs,g_cfg.pendingTimeoutMs,g_cfg.reconcileTimeoutSec,g_cfg.sessionEdgeMin,
               (int)g_cfg.useNewsFilter,(int)g_cfg.enablePersistentState,(int)g_cfg.safeModeCloseIfUnknown,EnumToString(g_cfg.resetTarget),g_cfg.resetToken);
  }

//+------------------------------------------------------------------+
int OnInit()
  {
   LoadConfig();
   string err="";
   if(!ValidateEnvironment(err))
     {
      Print("[AG][INIT_FAILED] ",err);
      Alert("XAUUSDc_AdaptiveGrid INIT_FAILED: ",err);
      return INIT_FAILED;
     }
   bool tester=(bool)MQLInfoInteger(MQL_TESTER);
   g_log.Init(g_spec.name,g_spec.point,g_spec.digits,g_cfg.enableCSV,g_cfg.detailedJournal,tester);
   LogInputs();
   if(!InitIndicators(err))
     {
      Print("[AG][INIT_FAILED] ",err);
      g_log.Deinit();
      return INIT_FAILED;
     }
   RecoverStateAfterRestart();
   g_log.Event("INIT_OK",-1,0,0,0,0.0,AccountInfoDouble(ACCOUNT_EQUITY),0.0,0.0,0,
               "ccy="+AccountInfoString(ACCOUNT_CURRENCY)+" hedging=VALID filling="+EnumToString(g_filling)
               +" calc="+EnvStatusText(g_envCalc)+" version="+AG_VERSION);
   EventSetTimer(1);
   g_initOk=true;
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   if(g_initOk)
     {
      SaveState();
      g_log.Event("DEINIT",-1,0,0,0,0.0,AccountInfoDouble(ACCOUNT_EQUITY),0.0,0.0,0,"reason="+(string)reason);
     }
   ReleaseIndicators();
   g_log.Deinit();
   Comment("");
  }

void OnTick()  { if(g_initOk) RunCycle(true); }
void OnTimer() { if(g_initOk) RunCycle(false); }

void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result)
  {
   //--- hint only: the next cycle re-reads positions/orders/deals (source of truth)
   if(g_initOk && !g_inCycle)
      RunCycle(false);
  }

//+------------------------------------------------------------------+
//| Main cycle (Phase 2 §2, Addendum §11). Steps 1-9 always run.     |
//+------------------------------------------------------------------+
void RunCycle(const bool fromTick)
  {
   if(g_inCycle)
      return;
   g_inCycle=true;

   MqlTick t;
   bool tickOk=(SymbolInfoTick(g_spec.name,t) && t.bid>0.0 && t.ask>0.0);
   if(tickOk)
      g_tick=t;
   else
      t=g_tick;

//--- 1. sync positions (symbol + magic + type) and fees
   for(int s=0; s<AG_SIDES; s++)
      g_basket[s].Scan();
//--- 2. reconcile outstanding requests, then consistency
   for(int s=0; s<AG_SIDES; s++)
      ReconcileIntent(g_basket[s],t);
   for(int s=0; s<AG_SIDES; s++)
      CheckBasketConsistency(g_basket[s]);
//--- 3. account / daily / combined risk and locks
   g_flowOk=UpdateExternalFlows();
   NewServerDayCheck();
   ComputeAccountMetrics();
   g_dailyValid=ComputeEADailyPL();
   EvaluateRiskLocks();
   DailyAutoReset(g_stateWriteOk);
   EnforceLockClose();
//--- 4-5. basket P/L and TP/SL
   for(int s=0; s<AG_SIDES; s++)
      EvaluateBasketExit(g_basket[s]);
//--- 6. closing / retries
   for(int s=0; s<AG_SIDES; s++)
      CloseBasketSafely(g_basket[s],t,tickOk);
//--- manual reset, persistence
   ProcessManualReset(t);
   PersistIfDirty();
//--- 7-12. new orders only from ticks, only when nothing blocks
   UpdateLogContext(t);
   if(fromTick && tickOk)
      TryNewOrders(t);
   if(g_cfg.showDashboard)
      UpdateDashboard(t);
   g_lastCycleServer=TimeTradeServer();
   g_inCycle=false;
  }

//+------------------------------------------------------------------+
void EnforceLockClose()
  {
   int id=HighestLock();
   if(id<0)
      return;
   if(!g_cfg.closeAllOnRiskLimit)
     {
      static datetime lastWarn=0;
      if(TimeTradeServer()-lastWarn>=60 && (g_basket[AG_BUY].count>0 || g_basket[AG_SELL].count>0))
        {
         lastWarn=TimeTradeServer();
         g_log.Warn("Lock "+LockName(id)+" active but CloseAllOnRiskLimit=false: positions left open");
        }
      return;
     }
   for(int s=0; s<AG_SIDES; s++)
     {
      if(g_basket[s].state==BS_CLOSING)
         continue;
      if(g_basket[s].count>0 || g_basket[s].HasIntent())
        {
         g_basket[s].closeReason=LockCloseReason(id);
         g_basket[s].SetState(BS_CLOSING,"lock "+LockName(id));
         MarkDirty();
        }
     }
  }

//+------------------------------------------------------------------+
//| Basket TP/SL on net P/L after estimated exit fees (Phase 3 §5.2) |
//+------------------------------------------------------------------+
void EvaluateBasketExit(CBasket &b)
  {
   if(b.count==0 || b.state==BS_CLOSING || b.state==BS_IDLE)
      return;
   if(!b.budgetVerified || b.effSL<=0.0)
      return;                                    // protection unknown: handled by SAFE MODE
   double net=b.NetAfterExit();
   if(net>=g_cfg.basketTP-AG_EPS_MONEY)
     {
      b.closeReason=CR_TP;
      g_log.Event("BASKET_TP_HIT",b.side,b.magic,b.basketId,b.count,b.totalVol,net,b.budget,0.0,0,
                  "net="+DoubleToString(net,4)+" >= TP "+DoubleToString(g_cfg.basketTP,2));
      b.SetState(BS_CLOSING,"basket TP");
      MarkDirty();
     }
   else
      if(net<=-b.effSL+AG_EPS_MONEY)
        {
         b.closeReason=CR_SL;
         g_log.Event("BASKET_SL_HIT",b.side,b.magic,b.basketId,b.count,b.totalVol,net,b.budget,0.0,0,
                     "net="+DoubleToString(net,4)+" <= -"+DoubleToString(b.effSL,4));
         b.SetState(BS_CLOSING,"basket SL");
         MarkDirty();
        }
  }

//+------------------------------------------------------------------+
//| Manual reset via ResetLockTarget + new ResetLockToken (§13).     |
//+------------------------------------------------------------------+
void ProcessManualReset(const MqlTick &t)
  {
   if(g_cfg.resetTarget==RESET_NONE)
      return;
   if(g_cfg.resetToken==g_lastResetToken)
     {
      if(!g_tokenWarned)
         g_log.Event("RESET_TOKEN_ALREADY_USED",-1,0,0,0,0.0,0.0,0.0,0.0,0,"token="+(string)g_cfg.resetToken);
      g_tokenWarned=true;
      return;
     }
   g_lastResetToken=g_cfg.resetToken;          // consumed even when verification fails
   g_tokenWarned=true;
   MarkDirty();
   string target=EnumToString(g_cfg.resetTarget);
   string why="";
   double eq=AccountInfoDouble(ACCOUNT_EQUITY);
   switch(g_cfg.resetTarget)
     {
      case RESET_DAILY_LOSS:
         g_log.Event("RESET_TARGET_NOT_ALLOWED",-1,0,0,0,0.0,0.0,0.0,0.0,0,"Daily lock only resets on a new server day");
         return;
      case RESET_ACCOUNT_PROTECTION:
         if(!g_locks[LOCK_ACCOUNT_PROTECTION].active) { why="lock not active"; break; }
         if(!VerifyBeforeUnlock(why,g_stateWriteOk)) break;
         g_apBase=eq;
         ClearLock(LOCK_ACCOUNT_PROTECTION);
         g_log.Event("UNLOCK_ACCOUNT_PROTECTION_MANUAL",-1,0,0,0,0.0,eq,0.0,0.0,0,"apBase rebased to "+DoubleToString(eq,2));
         return;
      case RESET_EQUITY_DD:
         if(!g_locks[LOCK_EQUITY_DD].active) { why="lock not active"; break; }
         if(!VerifyBeforeUnlock(why,g_stateWriteOk)) break;
         g_log.Event("UNLOCK_EQUITY_DD_MANUAL",-1,0,0,0,0.0,eq,g_hwm,0.0,0,"HWM rebased "+DoubleToString(g_hwm,2)+" -> "+DoubleToString(eq,2));
         g_hwm=eq;
         ClearLock(LOCK_EQUITY_DD);
         return;
      case RESET_COMBINED_LOSS:
         if(!g_locks[LOCK_COMBINED_LOSS].active) { why="lock not active"; break; }
         if(!VerifyBeforeUnlock(why,g_stateWriteOk)) break;
         if(g_combinedNet<=-g_cfg.maxCombinedLoss+AG_EPS_MONEY) { why="combined loss still beyond limit"; break; }
         ClearLock(LOCK_COMBINED_LOSS);
         g_log.Event("UNLOCK_COMBINED_LOSS_MANUAL",-1,0,0,0,0.0,g_combinedNet,0.0,0.0,0,"verified");
         return;
      case RESET_SAFE_MODE:
        {
         if(!AnySafeMode()) { why="SAFE MODE not active"; break; }
         bool ok=true;
         for(int s=0; s<AG_SIDES && ok; s++)
           {
            if(g_basket[s].count>0 || g_basket[s].wrongType) { why=SideText(s)+" still has EA positions"; ok=false; }
            else if(!IntentDiscardable(g_basket[s],t))       { why=SideText(s)+" intent still has evidence or is too recent"; ok=false; }
           }
         if(!ok || !g_stateWriteOk) { if(ok) why="state file not writable"; break; }
         for(int s=0; s<AG_SIDES; s++)
           {
            if(g_basket[s].HasIntent())
               g_log.Event("INTENT_DISCARDED_MANUAL",s,g_basket[s].magic,g_basket[s].basketId,0,g_basket[s].intent.volume,0.0,0.0,0.0,
                           g_basket[s].intent.retcode,"no position/order/deal evidence");
            g_basket[s].ClearIntent();
            g_basket[s].safeMode=false;
            g_basket[s].safeReason="";
            g_basket[s].ClearBasket();
           }
         g_globalSafe=false;
         g_globalSafeReason="";
         g_log.Event("SAFE_MODE_EXIT_MANUAL",-1,0,0,0,0.0,eq,0.0,0.0,0,"verified: no EA positions, no pending evidence");
         return;
        }
      default:
         why="unknown target";
     }
   g_log.Event("RESET_REFUSED",-1,0,0,0,0.0,0.0,0.0,0.0,0,target+": "+why);
  }

//+------------------------------------------------------------------+
void LogReject(CBasket &b,const string reason,const double stress,const double vol)
  {
   if(!g_log.ShouldLogReject(b.side,reason,iTime(g_spec.name,PERIOD_M1,0)))
      return;
   g_log.Event(reason,b.side,b.magic,b.basketId,b.count,vol,b.netOpen,b.budget,stress,0,reason);
  }

//+------------------------------------------------------------------+
//| Gates common to entry and add (filters, rate).                   |
//+------------------------------------------------------------------+
bool CommonOrderFilters(CBasket &b,const MqlTick &t,const datetime bar,string &reason)
  {
   if(!RegimeAllowsNewOrders(g_snap))                          { reason="REJECT_ADX_REGIME";       return false; }
   if(!ATRIsValid(g_snap,reason))                              { return false; }
   if(t.ask-t.bid>g_cfg.maxSpread+1e-9)                        { reason="REJECT_SPREAD";           return false; }
   if(!IsWithinTradeSession(TimeTradeServer(),g_cfg.sessionEdgeMin)) { reason="REJECT_SESSION";   return false; }
   if(!AG_OnePerBarOK(bar,b.lastOrderBar))                     { reason="REJECT_ONE_PER_BAR";      return false; }
   if(!AG_CooldownOK((long)t.time_msc,b.lastFillTimeMsc,g_cfg.cooldownSec)) { reason="REJECT_COOLDOWN"; return false; }
   return true;
  }

//+------------------------------------------------------------------+
void TryNewOrders(const MqlTick &t)
  {
   g_blockReason="";
   if(AnyLockActive())          { g_blockReason="LOCK_"+LockName(HighestLock()); return; }
   if(g_globalSafe)             { g_blockReason="GLOBAL_SAFE_MODE"; return; }
   if(!g_stateWriteOk)          { g_blockReason="STATE_WRITE_FAILED"; return; }
   if(g_cfg.useNewsFilter)
     {
      if(!g_newsWarned)
         g_log.Event("NEWS_FILTER_UNAVAILABLE",-1,0,0,0,0.0,0.0,0.0,0.0,0,"UseNewsFilter=true but no calendar integration: trading blocked");
      g_newsWarned=true;
      g_blockReason="NEWS_FILTER_UNAVAILABLE";
      return;
     }
   string why;
   if(!IsTradingAllowedNow(why)) { g_blockReason=why; return; }
   if(g_envCalc!=ENV_VALID)
     {
      string e;
      if(!VerifyProfitCalc(e)) { g_blockReason="CALC_"+EnvStatusText(g_envCalc); return; }
     }
   if(!g_dailyValid)            { g_blockReason="DAILY_UNKNOWN"; return; }
   if(!g_flowOk)                { g_blockReason="FLOW_SCAN_INCOMPLETE"; return; }

   datetime bar=iTime(g_spec.name,PERIOD_M1,0);
   if(bar==0)                   { g_blockReason="NO_BAR"; return; }
   datetime b1=iTime(g_spec.name,PERIOD_M1,1);
   if(!g_snap.valid || g_snap.bar1Time!=b1)
      ReadSnapshot(g_snap);
   UpdateLogContext(t);

   if(g_cfg.allowBuy)
     {
      TryInitialEntry(g_basket[AG_BUY],g_basket[AG_SELL],t,bar);
      TryGridAdd(g_basket[AG_BUY],g_basket[AG_SELL],t,bar);
     }
   if(g_cfg.allowSell)
     {
      TryInitialEntry(g_basket[AG_SELL],g_basket[AG_BUY],t,bar);
      TryGridAdd(g_basket[AG_SELL],g_basket[AG_BUY],t,bar);
     }
  }

//+------------------------------------------------------------------+
//| Initial entry: only on the first tick of a new M1 bar.           |
//+------------------------------------------------------------------+
void TryInitialEntry(CBasket &b,CBasket &o,const MqlTick &t,const datetime bar)
  {
   if(b.state!=BS_IDLE || b.safeMode || b.count>0 || b.HasIntent())
      return;
   if(bar<=b.lastProcessedBar)
      return;
   b.lastProcessedBar=bar;                       // evaluated once per bar, even if rejected
   MarkSoftDirty();
   if(!g_snap.valid)
     {
      LogReject(b,"REJECT_INDICATOR_NOT_READY_"+g_snap.err,0.0,0.0);
      return;
     }
   bool sig=(b.side==AG_BUY) ? CheckBuySignal(g_snap) : CheckSellSignal(g_snap);
   if(!sig)
      return;
   g_log.Event("SIGNAL_"+SideText(b.side),b.side,b.magic,0,0,0.0,0.0,0.0,0.0,0,
               "mode="+EnumToString(g_cfg.signalMode)+" C2="+DoubleToString(g_snap.close2,g_spec.digits)+" RSI2="+DoubleToString(g_snap.rsi2,2)
               +" C1="+DoubleToString(g_snap.close1,g_spec.digits)+" ADX1="+DoubleToString(g_snap.adx1,2));
   string reason;
   if(!CommonOrderFilters(b,t,bar,reason))
     { LogReject(b,reason,0.0,g_cfg.initialLot); return; }

   double base=(g_cfg.budgetBase==BUDGET_BASE_BALANCE) ? AccountInfoDouble(ACCOUNT_BALANCE) : AccountInfoDouble(ACCOUNT_EQUITY);
   double budget=AG_CalcBudget(base,g_cfg.basketRiskPct);
   double effSL=AG_CalcEffectiveSL(g_cfg.useSLFromBudget,g_cfg.basketSL,budget);
   double proj,add;
   if(!RiskGate(b,o,INTENT_ENTRY,g_cfg.initialLot,t,g_snap.atr1,effSL,proj,add,reason))
     { LogReject(b,reason,proj,g_cfg.initialLot); return; }

//--- basket identity + immutable budget snapshot (persisted together with the intent)
   b.basketId=g_nextBasketId++;
   b.startTime=TimeTradeServer();
   b.equityAtStart=base;
   b.budget=budget;
   b.effSL=effSL;
   b.budgetVerified=true;
   b.closeReason=CR_NONE;
   b.pidCount=0;
   uint rc;
   if(!ExecuteOrderSafely(b,g_cfg.initialLot,INTENT_ENTRY,1,t,bar,rc,reason))
     {
      if(b.state==BS_IDLE)
         b.ClearBasket();
      g_log.Event(reason,b.side,b.magic,0,0,g_cfg.initialLot,0.0,budget,proj,rc,"entry not sent/rejected");
      MarkDirty();
      return;
     }
   g_log.Event("OPEN_ENTRY_SENT",b.side,b.magic,b.basketId,0,g_cfg.initialLot,0.0,budget,proj,rc,
               "effSL="+DoubleToString(effSL,4)+" stress="+DoubleToString(proj,4)+" "+reason);
  }

//+------------------------------------------------------------------+
//| Grid add-on: checked on every tick, max one order per bar.       |
//+------------------------------------------------------------------+
void TryGridAdd(CBasket &b,CBasket &o,const MqlTick &t,const datetime bar)
  {
   if(b.state!=BS_ACTIVE || b.safeMode || b.count==0 || b.HasIntent())
      return;
   if(!g_snap.valid)
      return;
   double gd=CalculateGridDistance(g_snap.atr1);
   if(gd<=0.0)
     { LogReject(b,"REJECT_ATR_INVALID",0.0,0.0); return; }
   if(!GridTriggerHit(b.side,t,b.lastFillPrice,gd))
      return;
   string reason;
   if(!CommonOrderFilters(b,t,bar,reason))
     { LogReject(b,reason,0.0,g_cfg.initialLot); return; }
   double proj,add;
   if(!RiskGate(b,o,INTENT_ADD,g_cfg.initialLot,t,g_snap.atr1,b.effSL,proj,add,reason))
     { LogReject(b,reason,proj,g_cfg.initialLot); return; }
   uint rc;
   int layer=b.count+1;
   if(!ExecuteOrderSafely(b,g_cfg.initialLot,INTENT_ADD,layer,t,bar,rc,reason))
     {
      g_log.Event(reason,b.side,b.magic,b.basketId,b.count,g_cfg.initialLot,b.netOpen,b.budget,proj,rc,"add not sent/rejected");
      return;
     }
   g_log.Event("OPEN_ADD_SENT",b.side,b.magic,b.basketId,b.count,g_cfg.initialLot,b.netOpen,b.budget,proj,rc,
               "layer="+(string)layer+" gd="+DoubleToString(gd,g_spec.digits)+" lastFill="+DoubleToString(b.lastFillPrice,g_spec.digits)
               +" addLoss="+DoubleToString(add,4));
  }

//+------------------------------------------------------------------+
void UpdateLogContext(const MqlTick &t)
  {
   g_log.ctxBid=t.bid;
   g_log.ctxAsk=t.ask;
   g_log.ctxBar=iTime(g_spec.name,PERIOD_M1,0);
   if(g_snap.valid)
     {
      g_log.ctxATR=g_snap.atr1;
      g_log.ctxADX=g_snap.adx1;
      g_log.ctxRSI=g_snap.rsi2;
      g_log.ctxBBUp=g_snap.bbUp1;
      g_log.ctxBBLo=g_snap.bbLo1;
      g_log.ctxGrid=CalculateGridDistance(g_snap.atr1);
     }
  }

//+------------------------------------------------------------------+
void UpdateDashboard(const MqlTick &t)
  {
   string s="XAUUSDc Adaptive Grid v"+AG_VERSION+"  (software SL is NOT a guaranteed max loss)\n";
   s+="ENV symbol="+EnvStatusText(g_envSymbol)+" hedging="+EnvStatusText(g_envHedging)+" ccy="+EnvStatusText(g_envCurrency)
      +" specs="+EnvStatusText(g_envSpecs)+" calc="+EnvStatusText(g_envCalc)+" fees="+(g_feeRateVerified ? "VALID" : "UNKNOWN")
      +" state="+(g_stateWriteOk ? "VALID" : "INVALID")+"\n";
   string locks="";
   for(int i=0; i<AG_LOCK_COUNT; i++)
      if(g_locks[i].active)
         locks+=LockName(i)+" ";
   s+="LOCKS: "+(StringLen(locks)>0 ? locks : "none")+"  SAFE: "+(g_globalSafe ? "GLOBAL("+g_globalSafeReason+") " : "")
      +(g_basket[AG_BUY].safeMode ? "BUY("+g_basket[AG_BUY].safeReason+") " : "")
      +(g_basket[AG_SELL].safeMode ? "SELL("+g_basket[AG_SELL].safeReason+")" : "")+"\n";
   s+="Block: "+(StringLen(g_blockReason)>0 ? g_blockReason : "-")+"\n";
   s+=StringFormat("Spread %.3f (%.0f pt)  ATR1 %.3f  GD %.3f  ADX1 %.1f  RSI2 %.1f  snap=%s\n",
                   t.ask-t.bid,(g_spec.point>0 ? (t.ask-t.bid)/g_spec.point : 0.0),g_snap.atr1,CalculateGridDistance(g_snap.atr1),
                   g_snap.adx1,g_snap.rsi2,(g_snap.valid ? "VALID" : "INVALID"));
   for(int k=0; k<AG_SIDES; k++)
      s+=StringFormat("%s %s id=%I64d layers=%d vol=%.2f net=%.2f budget=%.2f SL=%.2f TP=%.2f\n",SideText(k),BasketStateText(g_basket[k].state),
                      g_basket[k].basketId,g_basket[k].count,g_basket[k].totalVol,g_basket[k].NetAfterExit(),g_basket[k].budget,g_basket[k].effSL,g_cfg.basketTP);
   s+=StringFormat("EA daily %.2f / -%.2f (%s)  Combined %.2f / -%.2f\n",g_eaDailyPL,g_cfg.dailyLoss,(g_dailyValid ? "VALID" : "UNKNOWN"),
                   g_combinedNet,g_cfg.maxCombinedLoss);
   s+=StringFormat("Equity %.2f  HWM %.2f  DD %.2f / %.2f   AP loss %.2f / %.2f (base %.2f)\n",AccountInfoDouble(ACCOUNT_EQUITY),
                   g_hwm,g_eqDD,g_eqLimit,g_apLoss,g_apLimit,g_apBase);
   Comment(s);
  }
//+------------------------------------------------------------------+
