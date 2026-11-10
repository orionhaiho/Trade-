//+------------------------------------------------------------------+
//| AG_Execution.mqh                                                 |
//| The ONLY module that sends trade requests.                       |
//| - Open: OrderCheck -> persist intent -> OrderSend -> classify    |
//| - Close: by ticket, scope-checked, bounded retries               |
//+------------------------------------------------------------------+
#ifndef AG_EXECUTION_MQH
#define AG_EXECUTION_MQH

#include "AG_Types.mqh"
#include "AG_Logger.mqh"
#include "AG_Environment.mqh"
#include "AG_BasketManager.mqh"
#include "AG_RiskManager.mqh"
#include "AG_Persistence.mqh"

#define AG_CLOSE_CONFIRM_MS 1000
#define AG_CLOSE_SLOW_MS    30000

bool IsAcceptedRetcode(const uint rc)
  {
   return (rc==TRADE_RETCODE_DONE || rc==TRADE_RETCODE_DONE_PARTIAL || rc==TRADE_RETCODE_PLACED);
  }

//--- request definitely NOT executed by the server
bool IsClearReject(const uint rc)
  {
   switch(rc)
     {
      case TRADE_RETCODE_REQUOTE:
      case TRADE_RETCODE_REJECT:
      case TRADE_RETCODE_CANCEL:
      case TRADE_RETCODE_INVALID:
      case TRADE_RETCODE_INVALID_VOLUME:
      case TRADE_RETCODE_INVALID_PRICE:
      case TRADE_RETCODE_INVALID_STOPS:
      case TRADE_RETCODE_TRADE_DISABLED:
      case TRADE_RETCODE_MARKET_CLOSED:
      case TRADE_RETCODE_NO_MONEY:
      case TRADE_RETCODE_PRICE_CHANGED:
      case TRADE_RETCODE_PRICE_OFF:
      case TRADE_RETCODE_INVALID_EXPIRATION:
      case TRADE_RETCODE_ORDER_CHANGED:
      case TRADE_RETCODE_TOO_MANY_REQUESTS:
      case TRADE_RETCODE_NO_CHANGES:
      case TRADE_RETCODE_SERVER_DISABLES_AT:
      case TRADE_RETCODE_CLIENT_DISABLES_AT:
      case TRADE_RETCODE_LOCKED:
      case TRADE_RETCODE_FROZEN:
      case TRADE_RETCODE_INVALID_FILL:
      case TRADE_RETCODE_ONLY_REAL:
      case TRADE_RETCODE_LIMIT_ORDERS:
      case TRADE_RETCODE_LIMIT_VOLUME:
      case TRADE_RETCODE_INVALID_ORDER:
      case TRADE_RETCODE_POSITION_CLOSED:
         return true;
     }
   return false;
  }

//--- retcodes that must not consume a close attempt (wait for market)
bool IsWaitRetcode(const uint rc)
  {
   return (rc==TRADE_RETCODE_MARKET_CLOSED || rc==TRADE_RETCODE_TRADE_DISABLED || rc==TRADE_RETCODE_CONNECTION
           || rc==TRADE_RETCODE_SERVER_DISABLES_AT || rc==TRADE_RETCODE_CLIENT_DISABLES_AT);
  }

//+------------------------------------------------------------------+
//| Opens one layer. Caller MUST have passed RiskGate in this cycle. |
//| For ENTRY the caller has already set basketId/budget fields.     |
//| Returns true when the request may have been executed (accepted  |
//| or unknown) => basket waits for reconciliation.                  |
//+------------------------------------------------------------------+
bool ExecuteOrderSafely(CBasket &b,const double vol,const int kind,const int layer,const MqlTick &t,
                        const datetime bar,uint &rc,string &reason)
  {
   rc=0;
   MqlTradeRequest rq;
   MqlTradeResult  rs;
   MqlTradeCheckResult ck;
   ZeroMemory(rq);
   ZeroMemory(rs);
   ZeroMemory(ck);
   rq.action      =TRADE_ACTION_DEAL;
   rq.symbol      =g_spec.name;
   rq.volume      =vol;
   rq.type        =b.otype;
   rq.price       =NormalizeDouble(b.side==AG_BUY ? t.ask : t.bid,g_spec.digits);
   rq.deviation   =(ulong)g_cfg.maxSlippagePts;
   rq.magic       =(ulong)b.magic;
   rq.type_filling=g_filling;
   rq.comment     ="AG|"+(b.side==AG_BUY ? "B" : "S")+"|"+(string)b.basketId+"|L"+(string)layer;

   if(!OrderCheck(rq,ck))
     {
      rc=ck.retcode;
      reason=(ck.retcode==TRADE_RETCODE_NO_MONEY) ? "REJECT_MARGIN" : "REJECT_ORDER_CHECK_"+(string)ck.retcode+"_"+ck.comment;
      return false;
     }

//--- persist intent BEFORE sending (crash between here and send => reconcile finds nothing => SAFE MODE)
   int prevState=b.state;
   b.intent.kind=kind;
   b.intent.status=INTENT_ST_SENT;
   b.intent.magic=b.magic;
   b.intent.volume=vol;
   b.intent.requestTimeMsc=(long)t.time_msc;
   b.intent.orderTicket=0;
   b.intent.dealTicket=0;
   b.intent.retcode=0;
   b.intent.layer=layer;
   b.lastOrderBar=bar;
   b.SetState(kind==INTENT_ENTRY ? BS_ENTRY_PENDING : BS_ADD_PENDING,"order intent persisted");
   if(!SaveState())
     {
      b.ClearIntent();
      b.state=prevState;
      reason="REJECT_STATE_WRITE";
      return false;
     }

   ResetLastError();
   bool sent=OrderSend(rq,rs);
   rc=rs.retcode;
   b.intent.retcode=rc;
   b.intent.orderTicket=rs.order;
   b.intent.dealTicket=rs.deal;

   if(IsAcceptedRetcode(rc))
     {
      b.intent.status=INTENT_ST_ACCEPTED;
      MarkDirty();
      SaveState();
      g_log.Event("ORDER_ACCEPTED",b.side,b.magic,b.basketId,b.count,vol,b.netOpen,b.budget,0.0,rc,
                  "order="+(string)rs.order+" deal="+(string)rs.deal+" price="+DoubleToString(rs.price,g_spec.digits)+" layer="+(string)layer);
      return true;
     }
   if(IsClearReject(rc))
     {
      b.ClearIntent();
      if(kind==INTENT_ENTRY)
         b.ClearBasket();
      else
         b.state=BS_ACTIVE;
      MarkDirty();
      SaveState();
      reason="REJECT_BROKER_"+(string)rc+"_"+rs.comment;
      return false;
     }
//--- ambiguous: never resend, reconcile
   b.intent.status=INTENT_ST_UNKNOWN;
   b.SetState(BS_RECOVERY,"ambiguous OrderSend result rc="+(string)rc+" sent="+(string)sent+" err="+(string)GetLastError());
   MarkDirty();
   SaveState();
   g_log.Event("ORDER_RESULT_UNKNOWN",b.side,b.magic,b.basketId,b.count,vol,b.netOpen,b.budget,0.0,rc,"pending reconciliation");
   reason="PENDING_RECONCILIATION";
   return true;
  }

//+------------------------------------------------------------------+
//| Closes one position by ticket after verifying scope.             |
//+------------------------------------------------------------------+
bool ClosePositionByTicket(CBasket &b,const ulong ticket,const MqlTick &t,uint &rc,string &why)
  {
   rc=0;
   if(!PositionSelectByTicket(ticket))
     { why="position already gone"; return true; }
   if(PositionGetString(POSITION_SYMBOL)!=g_spec.name || PositionGetInteger(POSITION_MAGIC)!=b.magic
      || (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)!=b.ptype)
     {
      why="CLOSE_REFUSED_OUT_OF_SCOPE";
      g_log.Event("CLOSE_REFUSED_SCOPE",b.side,b.magic,b.basketId,b.count,0.0,0.0,0.0,0.0,0,"ticket="+(string)ticket);
      return false;
     }
   MqlTradeRequest rq;
   MqlTradeResult  rs;
   ZeroMemory(rq);
   ZeroMemory(rs);
   rq.action      =TRADE_ACTION_DEAL;
   rq.position    =ticket;
   rq.symbol      =g_spec.name;
   rq.volume      =PositionGetDouble(POSITION_VOLUME);
   rq.type        =(b.side==AG_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
   rq.price       =NormalizeDouble(b.side==AG_BUY ? t.bid : t.ask,g_spec.digits);
   rq.deviation   =(ulong)g_cfg.maxSlippagePts;
   rq.magic       =(ulong)b.magic;
   rq.type_filling=g_filling;
   rq.comment     ="AG|CLOSE|"+(string)b.basketId;
   ResetLastError();
   bool sent=OrderSend(rq,rs);
   rc=rs.retcode;
   why="sent="+(string)sent+" rc="+(string)rc+" "+rs.comment+" err="+(string)GetLastError();
   return IsAcceptedRetcode(rc);
  }

//+------------------------------------------------------------------+
//| Final realized P/L of a finished basket from deal history.       |
//+------------------------------------------------------------------+
double BasketFinalPL(CBasket &b,bool &complete)
  {
   complete=true;
   double total=0.0;
   for(int i=0; i<b.pidCount; i++)
     {
      double fee,fin;
      bool out;
      long mg,tm;
      if(!ReadPositionHistory(b.pids[i],fee,fin,out,mg,tm) || !out)
        {
         complete=false;
         continue;
        }
      total+=fin;
     }
   return total;
  }

//+------------------------------------------------------------------+
//| CLOSING state processing (Phase 2 §3).                           |
//+------------------------------------------------------------------+
void CloseBasketSafely(CBasket &b,const MqlTick &t,const bool tickOk)
  {
   if(b.state!=BS_CLOSING)
      return;
//--- done: no positions and no outstanding intent
   if(b.count==0)
     {
      if(b.HasIntent())
         return;                                  // a late fill may still appear
      bool complete=false;
      double fin=BasketFinalPL(b,complete);
      g_log.Event(complete ? "BASKET_CLOSED" : "BASKET_CLOSED_PL_UNVERIFIED",b.side,b.magic,b.basketId,b.pidCount,0.0,fin,b.budget,0.0,0,
                  "reason="+CloseReasonText(b.closeReason)+" positions="+(string)b.pidCount);
      b.ClearBasket();
      MarkDirty();
      return;
     }
   if(!tickOk)
      return;
   long now=NowServerMsc(t);
   for(int i=0; i<b.count; i++)
     {
      ulong tk=b.pos[i].ticket;
      int k=b.TrackerIndex(tk);
      long wait=(b.clAttempts[k]>=g_cfg.maxCloseRetries) ? AG_CLOSE_SLOW_MS : (long)MathMax(g_cfg.closeRetryDelayMs,0);
      if(b.clLastMs[k]>0 && now-b.clLastMs[k]<wait)
         continue;
      uint rc;
      string why;
      bool ok=ClosePositionByTicket(b,tk,t,rc,why);
      b.clLastMs[k]=now;
      if(ok)
        {
         //--- wait for confirmation before any resend
         b.clLastMs[k]=now+AG_CLOSE_CONFIRM_MS-wait;
         g_log.Event("CLOSE_SENT",b.side,b.magic,b.basketId,b.count,b.pos[i].volume,b.netOpen,b.budget,0.0,rc,
                     "ticket="+(string)tk+" reason="+CloseReasonText(b.closeReason));
        }
      else
        {
         if(IsWaitRetcode(rc))
            b.clLastMs[k]=now+AG_CLOSE_SLOW_MS-wait;   // market closed / no connection: retry in 30 s, no attempt consumed
         else
            b.clAttempts[k]++;
         g_log.Event(b.clAttempts[k]>=g_cfg.maxCloseRetries ? "CLOSE_RETRY_EXHAUSTED" : "CLOSE_FAIL",b.side,b.magic,b.basketId,b.count,
                     b.pos[i].volume,b.netOpen,b.budget,0.0,rc,"ticket="+(string)tk+" attempts="+(string)b.clAttempts[k]+" "+why);
        }
     }
  }

#endif
//+------------------------------------------------------------------+
