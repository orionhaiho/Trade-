//+------------------------------------------------------------------+
//| AG_Recovery.mqh                                                  |
//| Startup recovery, order reconciliation, basket consistency,      |
//| fresh-install detection and state-lost fail-closed handling.     |
//+------------------------------------------------------------------+
#ifndef AG_RECOVERY_MQH
#define AG_RECOVERY_MQH

#include "AG_Types.mqh"
#include "AG_Math.mqh"
#include "AG_Logger.mqh"
#include "AG_Environment.mqh"
#include "AG_BasketManager.mqh"
#include "AG_RiskManager.mqh"
#include "AG_Persistence.mqh"
#include "AG_Execution.mqh"

//+------------------------------------------------------------------+
//| Any EA footprint (positions or deals) for this symbol + magics?  |
//+------------------------------------------------------------------+
bool HasEAFootprint()
  {
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      ulong tk=PositionGetTicket(i);
      if(tk==0)
         continue;
      long mg=PositionGetInteger(POSITION_MAGIC);
      if(PositionGetString(POSITION_SYMBOL)==g_spec.name && (mg==g_cfg.magicBuy || mg==g_cfg.magicSell))
         return true;
     }
   datetime from=(datetime)((long)TimeCurrent()-(long)AG_FRESH_LOOKBACK_DAYS*86400);
   if(!HistorySelect(from,TimeCurrent()+86400))
      return true;                                  // cannot prove absence => not fresh
   int n=HistoryDealsTotal();
   for(int i=0; i<n; i++)
     {
      ulong tk=HistoryDealGetTicket(i);
      if(tk==0)
         continue;
      long mg=HistoryDealGetInteger(tk,DEAL_MAGIC);
      if(HistoryDealGetString(tk,DEAL_SYMBOL)==g_spec.name && (mg==g_cfg.magicBuy || mg==g_cfg.magicSell))
         return true;
     }
   return false;
  }

void FreshInit()
  {
   double eq=AccountInfoDouble(ACCOUNT_EQUITY);
   for(int i=0; i<AG_LOCK_COUNT; i++)
      ClearLock(i);
   for(int s=0; s<AG_SIDES; s++)
      g_basket[s].ResetAll();
   g_hwm=eq;
   g_apBase=eq;
   g_dayStart=AG_DayStart(TimeTradeServer());
   g_dailySnap=0.0;
   g_lastResetToken=g_cfg.resetToken;      // a token present at first install is consumed, not applied
   g_globalSafe=false;
   g_globalSafeReason="";
   g_nextBasketId=1;
   InitFlowBaseline();
   g_log.Event("FRESH_INIT",-1,0,0,0,0.0,eq,0.0,0.0,0,"HWM="+DoubleToString(eq,2));
   MarkDirty();
  }

//--- state missing/corrupt with EA footprint: SAFE MODE + every lock active (fail-closed)
void StateLost(const string why)
  {
   double eq=AccountInfoDouble(ACCOUNT_EQUITY);
   for(int s=0; s<AG_SIDES; s++)
     {
      g_basket[s].ResetAll();
      g_basket[s].safeMode=true;
      g_basket[s].safeReason="STATE_LOST";
      g_basket[s].state=BS_SAFE_MODE;
     }
   g_hwm=eq;
   g_apBase=eq;
   g_dayStart=AG_DayStart(TimeTradeServer());
   g_dailySnap=0.0;
   g_lastResetToken=g_cfg.resetToken;      // never let the current input unlock a lost state silently
   g_globalSafe=true;
   g_globalSafeReason="STATE_LOST: "+why;
   InitFlowBaseline();
   for(int i=0; i<AG_LOCK_COUNT; i++)
     {
      ClearLock(i);
      ActivateLock(i,0.0,0.0,"STATE_LOST: "+why);
     }
   g_log.Event("SAFE_MODE_STATE_LOST",-1,0,0,0,0.0,eq,0.0,0.0,0,why+" -> all locks active, manual reset required");
   MarkDirty();
  }

//+------------------------------------------------------------------+
//| OnInit recovery entry point.                                     |
//+------------------------------------------------------------------+
void RecoverStateAfterRestart()
  {
   g_basket[AG_BUY].Setup(AG_BUY,g_cfg.magicBuy);
   g_basket[AG_SELL].Setup(AG_SELL,g_cfg.magicSell);
   if(!g_cfg.enablePersistentState)
     {
      FreshInit();
      return;
     }
   if((bool)MQLInfoInteger(MQL_TESTER))
     {
      if(FileIsExist(StateFileMain()))
         FileDelete(StateFileMain());
     }
   string why;
   ENUM_LOAD_RESULT r=LoadState(why);
   if(r==LOAD_OK)
     {
      g_basket[AG_BUY].Setup(AG_BUY,g_cfg.magicBuy);
      g_basket[AG_SELL].Setup(AG_SELL,g_cfg.magicSell);
      for(int s=0; s<AG_SIDES; s++)
         g_basket[s].ClearCloseTrackers();
      g_log.Event("STATE_LOADED",-1,0,0,0,0.0,g_hwm,0.0,0.0,0,
                  "HWM="+DoubleToString(g_hwm,2)+" locks="+(string)AnyLockActive()+" globalSafe="+(string)g_globalSafe);
      return;
     }
   if(r==LOAD_MISSING && !HasEAFootprint())
     {
      FreshInit();
      SaveState();
      return;
     }
   StateLost(why);
   SaveState();
  }

//+------------------------------------------------------------------+
//| Reconcile an outstanding intent (Addendum §10).                  |
//| Never resends. Uses order/position identifiers, magic, symbol,   |
//| side, volume and time; comment is not used.                      |
//+------------------------------------------------------------------+
void ConfirmFill(CBasket &b,const long pid,const long fillMsc,const double price,const double vol,const string how)
  {
   b.AddPid(pid);
   if(fillMsc>b.lastFillTimeMsc)
      b.lastFillTimeMsc=fillMsc;
   datetime fb=AG_MinuteStart(fillMsc);
   if(fb>b.lastOrderBar)
      b.lastOrderBar=fb;
   g_log.Event(b.intent.kind==INTENT_ENTRY ? "OPEN_ENTRY_CONFIRMED" : "OPEN_ADD_CONFIRMED",b.side,b.magic,b.basketId,b.count,vol,b.netOpen,b.budget,0.0,
               b.intent.retcode,how+" pid="+(string)pid+" fill="+DoubleToString(price,g_spec.digits)+" layer="+(string)b.intent.layer);
   if(b.intent.kind==INTENT_ENTRY && b.startTime==0)
      b.startTime=(datetime)(fillMsc/1000);
   b.ClearIntent();
   if(b.safeMode && b.safeReason=="UNRESOLVED_INTENT")
     {
      b.safeMode=false;
      b.safeReason="";
      g_log.Event("SAFE_MODE_EXIT_RECONCILED",b.side,b.magic,b.basketId,b.count,b.totalVol,b.netOpen,b.budget,0.0,0,"intent resolved");
     }
   if(b.state!=BS_CLOSING)
      b.SetState(b.safeMode ? BS_SAFE_MODE : BS_ACTIVE,"fill confirmed");
   MarkDirty();
  }

void ReconcileIntent(CBasket &b,const MqlTick &t)
  {
   if(!b.HasIntent())
      return;
   long now=NowServerMsc(t);
   long minMsc=b.intent.requestTimeMsc-2000;
//--- 1) open position of this side not yet attributed
   for(int i=0; i<b.count; i++)
     {
      if(b.HasPid(b.pos[i].pid))
         continue;
      if(b.pos[i].timeMsc<minMsc)
         continue;
      if(b.intent.orderTicket>0 && b.pos[i].pid!=(long)b.intent.orderTicket)
         continue;
      if(b.pos[i].volume>b.intent.volume+g_spec.volStep*1e-6)
         continue;
      ConfirmFill(b,b.pos[i].pid,b.pos[i].timeMsc,b.pos[i].openPrice,b.pos[i].volume,"position");
      return;
     }
//--- 2) order still being processed on the server
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      ulong ot=OrderGetTicket(i);
      if(ot==0)
         continue;
      if(OrderGetString(ORDER_SYMBOL)==g_spec.name && OrderGetInteger(ORDER_MAGIC)==b.magic)
         return;                                                // wait
     }
//--- 3) filled and already closed (or closed externally): IN deal in history
   if(HistorySelect((datetime)(minMsc/1000)-5,TimeCurrent()+86400))
     {
      int n=HistoryDealsTotal();
      for(int i=0; i<n; i++)
        {
         ulong dt=HistoryDealGetTicket(i);
         if(dt==0)
            continue;
         if(HistoryDealGetString(dt,DEAL_SYMBOL)!=g_spec.name || HistoryDealGetInteger(dt,DEAL_MAGIC)!=b.magic)
            continue;
         if(HistoryDealGetInteger(dt,DEAL_ENTRY)!=DEAL_ENTRY_IN)
            continue;
         long dtype=HistoryDealGetInteger(dt,DEAL_TYPE);
         if((b.side==AG_BUY && dtype!=DEAL_TYPE_BUY) || (b.side==AG_SELL && dtype!=DEAL_TYPE_SELL))
            continue;
         long tm=HistoryDealGetInteger(dt,DEAL_TIME_MSC);
         if(tm<minMsc)
            continue;
         long pid=HistoryDealGetInteger(dt,DEAL_POSITION_ID);
         if(b.HasPid(pid))
            continue;
         if(b.intent.orderTicket>0 && HistoryDealGetInteger(dt,DEAL_ORDER)!=(long)b.intent.orderTicket)
            continue;
         ConfirmFill(b,pid,tm,HistoryDealGetDouble(dt,DEAL_PRICE),HistoryDealGetDouble(dt,DEAL_VOLUME),"history(position not open)");
         g_log.Event("RECONCILE_FILLED_THEN_CLOSED",b.side,b.magic,b.basketId,b.count,0.0,b.netOpen,b.budget,0.0,0,"pid="+(string)pid);
         if(b.count==0 && b.state!=BS_CLOSING)
           {
            b.closeReason=CR_EXTERNAL;
            b.SetState(BS_CLOSING,"filled then closed outside EA");
           }
         return;
        }
     }
//--- 4) nothing found
   long elapsed=now-b.intent.requestTimeMsc;
   if(b.intent.status==INTENT_ST_ACCEPTED && elapsed>g_cfg.pendingTimeoutMs)
     {
      b.intent.status=INTENT_ST_UNKNOWN;
      if(b.state!=BS_CLOSING)
         b.SetState(BS_RECOVERY,"accepted but no position after "+(string)elapsed+" ms");
      MarkDirty();
     }
   else
      if(b.intent.status==INTENT_ST_SENT)
        {
         b.intent.status=INTENT_ST_UNKNOWN;      // persisted but result never recorded (crash/restart)
         if(b.state!=BS_CLOSING)
            b.SetState(BS_RECOVERY,"intent without recorded result");
         MarkDirty();
        }
   if(b.intent.status==INTENT_ST_UNKNOWN && elapsed>(long)g_cfg.reconcileTimeoutSec*1000 && !b.safeMode)
     {
      b.EnterSafe("UNRESOLVED_INTENT");
      MarkDirty();
     }
  }

//--- true when an unresolved intent has no evidence at all and is old enough to be discarded by a manual reset
bool IntentDiscardable(CBasket &b,const MqlTick &t)
  {
   if(!b.HasIntent())
      return true;
   if(b.UnlistedCount()>0)
      return false;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      ulong ot=OrderGetTicket(i);
      if(ot!=0 && OrderGetString(ORDER_SYMBOL)==g_spec.name && OrderGetInteger(ORDER_MAGIC)==b.magic)
         return false;
     }
   return (NowServerMsc(t)-b.intent.requestTimeMsc)>(long)g_cfg.reconcileTimeoutSec*1000;
  }

//+------------------------------------------------------------------+
//| Consistency between terminal positions and basket state.         |
//+------------------------------------------------------------------+
void CheckBasketConsistency(CBasket &b)
  {
   if(b.wrongType)
      b.EnterSafe("WRONG_TYPE_POSITION_WITH_EA_MAGIC");
   if(b.count>g_cfg.maxLayers || VolSteps(b.totalVol)>VolSteps(g_cfg.maxSideLots))
      b.EnterSafe("LAYER_LIMIT_VIOLATION");
   if(!b.HasIntent() && b.count>0 && b.UnlistedCount()>0)
     {
      if(b.state==BS_IDLE || !b.budgetVerified)
         b.EnterSafe("UNKNOWN_POSITION_NO_BUDGET");
      else
         b.EnterSafe("UNLISTED_POSITION");
     }
   if(b.count>0 && !b.budgetVerified && !b.HasIntent())
      b.EnterSafe("BUDGET_UNKNOWN");

//--- emergency close when the protection limit is unknown (Addendum §9.2)
   if(b.safeMode && b.count>0 && !b.budgetVerified && g_cfg.safeModeCloseIfUnknown && b.state!=BS_CLOSING)
     {
      b.closeReason=CR_SAFE_EMERGENCY;
      b.SetState(BS_CLOSING,"risk state unknown -> emergency close");
      MarkDirty();
     }

//--- positions vanished while basket active (closed outside the EA or while offline)
   if(b.count==0 && !b.HasIntent() && b.pidCount>0
      && (b.state==BS_ACTIVE || b.state==BS_RECOVERY || b.state==BS_ADD_PENDING || b.state==BS_ENTRY_PENDING))
     {
      bool complete=false;
      BasketFinalPL(b,complete);
      if(complete)
        {
         b.closeReason=CR_EXTERNAL;
         b.SetState(BS_CLOSING,"positions closed outside EA / while offline");
        }
      else
         b.EnterSafe("POSITIONS_MISSING_HISTORY_UNVERIFIED");
      MarkDirty();
     }
  }

#endif
//+------------------------------------------------------------------+
