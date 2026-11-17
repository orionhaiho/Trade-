//+------------------------------------------------------------------+
//| LLB_Execution.mqh                                                |
//| ExecutionManager - the ONLY module that calls OrderSend /        |
//| OrderCheck (R-EXE-01). Opening orders are pending Buy Stop /     |
//| Sell Stop only (R-EXE-03); TRADE_ACTION_DEAL is used exclusively |
//| to CLOSE an EA-owned position (invariant 10).                    |
//|                                                                  |
//| Execute(): re-validate -> OrderCheck -> journal SUBMITTING ->    |
//| OrderSend -> classify. Ambiguous results are never re-sent       |
//| (R-EXE-08); they are reconciled from orders/deals/positions.     |
//+------------------------------------------------------------------+
#ifndef LLB_EXECUTION_MQH
#define LLB_EXECUTION_MQH

#include "LLB_Defines.mqh"
#include "LLB_Utils.mqh"
#include "LLB_Logger.mqh"
#include "LLB_Persistence.mqh"
#include "LLB_MarketData.mqh"
#include "LLB_Risk.mqh"
#include "LLB_Proposals.mqh"

void LLB_AddEvent(LLBExecEvent &events[],const int type,const int index,const long positionId,const string text)
  {
   int n=ArraySize(events);
   ArrayResize(events,n+1);
   events[n].type=type;
   events[n].index=index;
   events[n].positionId=positionId;
   events[n].text=text;
  }

//--- position selection by POSITION_IDENTIFIER (works for hedging and netting)
bool LLB_SelectPositionById(const long id,ulong &ticket)
  {
   ticket=0;
   if(id<=0)
      return false;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      ulong t=PositionGetTicket(i);
      if(t==0)
         continue;
      if(PositionGetInteger(POSITION_IDENTIFIER)==id)
        {
         ticket=t;
         return true;
        }
     }
   return false;
  }

class CLLBExecutionManager
  {
private:
   CLLBPersistence  *m_per;
   CLLBRisk         *m_risk;
   CLLBMarketData   *m_md;
   ulong             m_magic;
   int               m_closeDeviation;
   bool              m_allowEaExpiry;
   bool              m_netting;
   bool              m_tester;

   bool              Journal(const int idx)
     {
      if(m_per==NULL)
         return false;
      bool ok=m_per.AppendLine(LLB_FILE_EXECUTIONS,LLB_ExecCsvHeader(),LLB_ExecToCsv(items[idx],TimeTradeServer()));
      if(!ok)
         g_llbLog.Error("EXE","JOURNAL_WRITE_FAILED "+items[idx].execId);
      return ok;
     }

   bool              IsFinal(const LLBExecutionRecord &e)
     {
      if(e.state==LLB_EX_PRECHECK_FAILED || e.state==LLB_EX_REJECTED || e.state==LLB_EX_NOT_FOUND)
         return true;
      if(e.state==LLB_EX_PLACED)
         return (e.orderState==LLB_OS_FILLED || e.orderState==LLB_OS_EXPIRED || e.orderState==LLB_OS_CANCELLED_EA
                 || e.orderState==LLB_OS_CANCELLED_EXT || e.orderState==LLB_OS_REJECTED);
      return false;
     }

   double            SameDirectionVolume(const string sym,const int dir)
     {
      double v=0.0;
      for(int i=PositionsTotal()-1; i>=0; i--)
        {
         ulong t=PositionGetTicket(i);
         if(t==0 || PositionGetString(POSITION_SYMBOL)!=sym)
            continue;
         long pt=PositionGetInteger(POSITION_TYPE);
         if((dir==LLB_DIR_BUY && pt==POSITION_TYPE_BUY) || (dir==LLB_DIR_SELL && pt==POSITION_TYPE_SELL))
            v+=PositionGetDouble(POSITION_VOLUME);
        }
      for(int i=OrdersTotal()-1; i>=0; i--)
        {
         ulong t=OrderGetTicket(i);
         if(t==0 || OrderGetString(ORDER_SYMBOL)!=sym)
            continue;
         long ot=OrderGetInteger(ORDER_TYPE);
         bool buy=(ot==ORDER_TYPE_BUY_STOP || ot==ORDER_TYPE_BUY_LIMIT || ot==ORDER_TYPE_BUY_STOP_LIMIT);
         bool sell=(ot==ORDER_TYPE_SELL_STOP || ot==ORDER_TYPE_SELL_LIMIT || ot==ORDER_TYPE_SELL_STOP_LIMIT);
         if((dir==LLB_DIR_BUY && buy) || (dir==LLB_DIR_SELL && sell))
            v+=OrderGetDouble(ORDER_VOLUME_CURRENT);
        }
      return v;
     }

   bool              SymbolHasPendingOrder(const string sym)
     {
      for(int i=OrdersTotal()-1; i>=0; i--)
        {
         ulong t=OrderGetTicket(i);
         if(t!=0 && OrderGetString(ORDER_SYMBOL)==sym)
            return true;
        }
      return false;
     }

   void              RecordPrecheckFailure(const LLBTradeProposal &p,const string why)
     {
      LLBExecutionRecord e;
      e.Reset();
      e.execId=p.execId;
      e.signalId=p.signalId;
      e.symbol=p.symbol;
      e.direction=p.direction;
      e.orderType=(p.direction==LLB_DIR_BUY) ? (int)ORDER_TYPE_BUY_STOP : (int)ORDER_TYPE_SELL_STOP;
      e.state=LLB_EX_PRECHECK_FAILED;
      e.entry=p.entry;
      e.sl=p.sl;
      e.tp=p.tp;
      e.expiration=p.expiresTime;
      e.submitMsc=(long)TimeTradeServer()*1000;
      e.refSwingPrice=p.refSwingPrice;
      e.monitorFromMsc=p.monitorFromMsc;
      e.note="NOT SENT: "+why;
      int n=ArraySize(items);
      ArrayResize(items,n+1,32);
      items[n]=e;
      Journal(n);
     }

   //--- market filling policy for CLOSING deals, validated by OrderCheck
   bool              ChooseMarketFilling(MqlTradeRequest &rq,const LLBSymbolSpec &spec,MqlTradeCheckResult &ck)
     {
      ENUM_ORDER_TYPE_FILLING cands[3];
      int n=0;
      if((spec.fillingMode&SYMBOL_FILLING_FOK)!=0)
         cands[n++]=ORDER_FILLING_FOK;
      if((spec.fillingMode&SYMBOL_FILLING_IOC)!=0)
         cands[n++]=ORDER_FILLING_IOC;
      cands[n++]=ORDER_FILLING_RETURN;
      for(int i=0; i<n; i++)
        {
         rq.type_filling=cands[i];
         ZeroMemory(ck);
         if(OrderCheck(rq,ck))
            return true;
         if(ck.retcode!=TRADE_RETCODE_INVALID_FILL)
            return false;
        }
      return false;
     }

   //--- filling policy for PENDING orders: RETURN first (MQL5 docs), then the symbol's FOK/IOC.
   //--- Only OrderCheck is used here - nothing is sent while choosing.
   bool              ChoosePendingFilling(MqlTradeRequest &rq,const LLBSymbolSpec &spec,MqlTradeCheckResult &ck)
     {
      ENUM_ORDER_TYPE_FILLING cands[3];
      int n=0;
      cands[n++]=ORDER_FILLING_RETURN;
      if((spec.fillingMode&SYMBOL_FILLING_FOK)!=0)
         cands[n++]=ORDER_FILLING_FOK;
      if((spec.fillingMode&SYMBOL_FILLING_IOC)!=0)
         cands[n++]=ORDER_FILLING_IOC;
      for(int i=0; i<n; i++)
        {
         rq.type_filling=cands[i];
         ZeroMemory(ck);
         if(OrderCheck(rq,ck))
            return true;
         if(ck.retcode!=TRADE_RETCODE_INVALID_FILL)
            return false;
        }
      return false;
     }

   //--- fill volume / average price of this execution's order from deal history
   void              FillDetails(const int i)
     {
      long pid=items[i].positionId;
      if(pid<=0 || !HistorySelectByPosition(pid))
         return;
      double vol=0.0,pv=0.0;
      ulong first=0;
      int n=HistoryDealsTotal();
      for(int k=0; k<n; k++)
        {
         ulong d=HistoryDealGetTicket(k);
         if(d==0)
            continue;
         if((ulong)HistoryDealGetInteger(d,DEAL_ORDER)!=items[i].orderTicket)
            continue;
         if(HistoryDealGetInteger(d,DEAL_ENTRY)!=DEAL_ENTRY_IN)
            continue;
         double dv=HistoryDealGetDouble(d,DEAL_VOLUME);
         vol+=dv;
         pv+=dv*HistoryDealGetDouble(d,DEAL_PRICE);
         if(first==0)
            first=d;
        }
      if(vol>0.0)
        {
         items[i].fillVolume=vol;
         items[i].fillPrice=pv/vol;
         items[i].dealTicket=first;
        }
     }

   //--- locate the order of an execution whose OrderSend result is unknown
   bool              FindOrderForExec(const int i,const datetime now,ulong &ticket)
     {
      ticket=0;
      string id=items[i].execId;
      //--- 1. open pending orders (comment, then parameters)
      for(int k=OrdersTotal()-1; k>=0; k--)
        {
         ulong t=OrderGetTicket(k);
         if(t==0 || (ulong)OrderGetInteger(ORDER_MAGIC)!=m_magic || OrderGetString(ORDER_SYMBOL)!=items[i].symbol)
            continue;
         string cid;
         if(LLB_ExecIdFromComment(OrderGetString(ORDER_COMMENT),cid) && cid==id)
           {
            ticket=t;
            return true;
           }
         if(OrderGetInteger(ORDER_TYPE)==items[i].orderType
            && MathAbs(OrderGetDouble(ORDER_PRICE_OPEN)-items[i].entry)<1e-6*MathMax(1.0,items[i].entry)
            && MathAbs(OrderGetDouble(ORDER_SL)-items[i].sl)<1e-6*MathMax(1.0,items[i].sl)
            && MathAbs(OrderGetDouble(ORDER_TP)-items[i].tp)<1e-6*MathMax(1.0,items[i].tp)
            && MathAbs(OrderGetDouble(ORDER_VOLUME_INITIAL)-items[i].volume)<1e-8
            && OrderGetInteger(ORDER_TIME_SETUP_MSC)>=items[i].submitMsc-600000)
           {
            ticket=t;
            return true;
           }
        }
      //--- 2. history orders (already filled / expired / cancelled)
      datetime from=(datetime)(items[i].submitMsc/1000)-3600;
      if(HistorySelect(from,now+86400))
        {
         int n=HistoryOrdersTotal();
         for(int k=n-1; k>=0; k--)
           {
            ulong t=HistoryOrderGetTicket(k);
            if(t==0 || (ulong)HistoryOrderGetInteger(t,ORDER_MAGIC)!=m_magic || HistoryOrderGetString(t,ORDER_SYMBOL)!=items[i].symbol)
               continue;
            string cid;
            if(LLB_ExecIdFromComment(HistoryOrderGetString(t,ORDER_COMMENT),cid) && cid==id)
              {
               ticket=t;
               return true;
              }
           }
        }
      //--- 3. open positions opened by that order
      for(int k=PositionsTotal()-1; k>=0; k--)
        {
         ulong t=PositionGetTicket(k);
         if(t==0 || PositionGetString(POSITION_SYMBOL)!=items[i].symbol)
            continue;
         string cid;
         if(LLB_ExecIdFromComment(PositionGetString(POSITION_COMMENT),cid) && cid==id)
           {
            ticket=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
            return true;
           }
        }
      return false;
     }

   //--- order of a PLACED execution: pending / partial / filled / expired / cancelled
   void              UpdateOrderState(const int i,const datetime now,LLBExecEvent &events[])
     {
      ulong tk=items[i].orderTicket;
      if(tk==0)
         return;
      if(OrderSelect(tk))
        {
         double vinit=OrderGetDouble(ORDER_VOLUME_INITIAL);
         double vcur=OrderGetDouble(ORDER_VOLUME_CURRENT);
         if(vcur<vinit-1e-9 && items[i].orderState!=LLB_OS_PARTIAL)
           {
            items[i].orderState=LLB_OS_PARTIAL;
            long pid=OrderGetInteger(ORDER_POSITION_ID);
            if(pid>0)
               items[i].positionId=pid;
            FillDetails(i);
            Journal(i);
            LLB_AddEvent(events,LLB_EV_FILLED,i,items[i].positionId,
                         StringFormat("partial fill %s/%s lots",DoubleToString(vinit-vcur,2),DoubleToString(vinit,2)));
           }
         else
            if(items[i].orderState==LLB_OS_NONE)
              {
               items[i].orderState=LLB_OS_PENDING;
               Journal(i);
              }
         return;
        }
      if(!HistoryOrderSelect(tk))
        {
         HistorySelect((datetime)(items[i].submitMsc/1000)-3600,now+86400);
         if(!HistoryOrderSelect(tk))
           {
            if(!items[i].historyWarned)
              {
               g_llbLog.Warn("EXE","order #"+(string)tk+" of "+items[i].execId+" not visible yet (history sync) - will retry");
               items[i].historyWarned=true;
              }
            return;
           }
        }
      long hs=HistoryOrderGetInteger(tk,ORDER_STATE);
      double vinit=HistoryOrderGetDouble(tk,ORDER_VOLUME_INITIAL);
      double vcur=HistoryOrderGetDouble(tk,ORDER_VOLUME_CURRENT);
      long pid=HistoryOrderGetInteger(tk,ORDER_POSITION_ID);
      double filled=vinit-vcur;
      int newState=items[i].orderState;
      if(hs==ORDER_STATE_FILLED)
         newState=LLB_OS_FILLED;
      else
         if(hs==ORDER_STATE_EXPIRED)
            newState=LLB_OS_EXPIRED;
         else
            if(hs==ORDER_STATE_CANCELED)
               newState=(items[i].cancelReason!="") ? LLB_OS_CANCELLED_EA : LLB_OS_CANCELLED_EXT;
            else
               if(hs==ORDER_STATE_REJECTED)
                  newState=LLB_OS_REJECTED;
               else
                  return;                                  // transitional state: wait
      if(newState==items[i].orderState)
         return;
      int prev=items[i].orderState;
      items[i].orderState=newState;
      if(pid>0)
         items[i].positionId=pid;
      if(filled>1e-9)
         FillDetails(i);
      Journal(i);
      if(newState==LLB_OS_FILLED)
        {
         LLB_AddEvent(events,LLB_EV_FILLED,i,items[i].positionId,"order filled");
         return;
        }
      //--- expired/cancelled after a partial fill: the filled part is a position to manage
      if(filled>1e-9 && items[i].positionId>0 && prev!=LLB_OS_PARTIAL)
         LLB_AddEvent(events,LLB_EV_FILLED,i,items[i].positionId,"partial fill before "+LLB_OrderStateName(newState));
      int ev=LLB_EV_CANCELLED;
      if(newState==LLB_OS_EXPIRED)
         ev=LLB_EV_EXPIRED;
      if(newState==LLB_OS_REJECTED)
         ev=LLB_EV_REJECTED;
      LLB_AddEvent(events,ev,i,items[i].positionId,"order "+LLB_OrderStateName(newState)
                   +((items[i].cancelReason!="") ? " ("+items[i].cancelReason+")" : ""));
     }

public:
   LLBExecutionRecord items[];

                     CLLBExecutionManager(void)
     {
      m_per=NULL;
      m_risk=NULL;
      m_md=NULL;
      m_magic=0;
      m_closeDeviation=50;
      m_allowEaExpiry=false;
      m_netting=false;
      m_tester=false;
     }

   void              Init(CLLBPersistence *per,CLLBRisk *risk,CLLBMarketData *md,const ulong magic,const int closeDeviation,
                          const bool allowEaExpiry,const bool netting,const bool tester)
     {
      m_per=per;
      m_risk=risk;
      m_md=md;
      m_magic=magic;
      m_closeDeviation=closeDeviation;
      m_allowEaExpiry=allowEaExpiry;
      m_netting=netting;
      m_tester=tester;
     }

   int               Count(void) { return ArraySize(items); }

   int               Find(const string execId)
     {
      for(int i=ArraySize(items)-1; i>=0; i--)
         if(items[i].execId==execId)
            return i;
      return -1;
     }

   int               FindBySignal(const string signalId)
     {
      for(int i=ArraySize(items)-1; i>=0; i--)
         if(items[i].signalId==signalId)
            return i;
      return -1;
     }

   bool              Load(const datetime now,int &corrupt,string &err)
     {
      corrupt=0;
      err="";
      ArrayResize(items,0);
      string lines[];
      if(!m_per.ReadAll(LLB_FILE_EXECUTIONS,lines))
         return true;
      string seen[];
      string keep[];
      int ns=0;
      for(int i=ArraySize(lines)-1; i>=0; i--)
        {
         string l=lines[i];
         if(StringLen(l)==0 || StringGetCharacter(l,0)=='#')
            continue;
         LLBExecutionRecord e;
         if(!LLB_ExecFromCsv(l,e))
           {
            corrupt++;
            continue;
           }
         bool dup=false;
         for(int k=0; k<ns; k++)
            if(seen[k]==e.execId)
              {
               dup=true;
               break;
              }
         if(dup)
            continue;
         ArrayResize(seen,ns+1,256);
         seen[ns]=e.execId;
         ns++;
         int kn=ArraySize(keep);
         ArrayResize(keep,kn+1,256);
         keep[kn]=l;
         bool inMemory=(!IsFinal(e) || (long)now-e.submitMsc/1000<=(long)LLB_KEEP_DAYS*86400);
         if(inMemory)
           {
            int n=ArraySize(items);
            ArrayResize(items,n+1,32);
            items[n]=e;
           }
        }
      int cnt=ArraySize(items);
      for(int a=0; a<cnt/2; a++)
        {
         int b=cnt-1-a;
         LLBExecutionRecord tmp=items[a];
         items[a]=items[b];
         items[b]=tmp;
        }
      if(m_per.SizeOf(LLB_FILE_EXECUTIONS)>LLB_JOURNAL_MAX_BYTES)
        {
         string chrono[];
         int kn=ArraySize(keep);
         ArrayResize(chrono,kn);
         for(int i=0; i<kn; i++)
            chrono[i]=keep[kn-1-i];
         m_per.ArchiveAndRewrite(LLB_FILE_EXECUTIONS,LLB_ExecCsvHeader(),chrono);
        }
      return true;
     }

   //--- any order / position / history order of this execution id on the broker
   bool              BrokerHasExec(const string execId,const datetime now,ulong &ticket,string &where)
     {
      ticket=0;
      where="";
      for(int k=OrdersTotal()-1; k>=0; k--)
        {
         ulong t=OrderGetTicket(k);
         string cid;
         if(t!=0 && (ulong)OrderGetInteger(ORDER_MAGIC)==m_magic && LLB_ExecIdFromComment(OrderGetString(ORDER_COMMENT),cid) && cid==execId)
           {
            ticket=t;
            where="open order";
            return true;
           }
        }
      for(int k=PositionsTotal()-1; k>=0; k--)
        {
         ulong t=PositionGetTicket(k);
         string cid;
         if(t!=0 && LLB_ExecIdFromComment(PositionGetString(POSITION_COMMENT),cid) && cid==execId)
           {
            ticket=t;
            where="open position";
            return true;
           }
        }
      if(HistorySelect(now-7*86400,now+86400))
        {
         int n=HistoryOrdersTotal();
         for(int k=n-1; k>=0; k--)
           {
            ulong t=HistoryOrderGetTicket(k);
            string cid;
            if(t!=0 && (ulong)HistoryOrderGetInteger(t,ORDER_MAGIC)==m_magic
               && LLB_ExecIdFromComment(HistoryOrderGetString(t,ORDER_COMMENT),cid) && cid==execId)
              {
               ticket=t;
               where="history order";
               return true;
              }
           }
        }
      return false;
     }

   //--- highest daily sequence present in broker comments for a date (YYMMDD)
   int               MaxBrokerSeq(const int date6,const datetime now)
     {
      int mx=0;
      string cid;
      int d6,seq;
      for(int k=OrdersTotal()-1; k>=0; k--)
        {
         ulong t=OrderGetTicket(k);
         if(t!=0 && (ulong)OrderGetInteger(ORDER_MAGIC)==m_magic && LLB_ExecIdFromComment(OrderGetString(ORDER_COMMENT),cid)
            && LLB_ParseExecId(cid,d6,seq) && d6==date6 && seq>mx)
            mx=seq;
        }
      for(int k=PositionsTotal()-1; k>=0; k--)
        {
         ulong t=PositionGetTicket(k);
         if(t!=0 && LLB_ExecIdFromComment(PositionGetString(POSITION_COMMENT),cid) && LLB_ParseExecId(cid,d6,seq) && d6==date6 && seq>mx)
            mx=seq;
        }
      if(HistorySelect(LLB_DayStart(now)-86400,now+86400))
        {
         int n=HistoryOrdersTotal();
         for(int k=0; k<n; k++)
           {
            ulong t=HistoryOrderGetTicket(k);
            if(t!=0 && (ulong)HistoryOrderGetInteger(t,ORDER_MAGIC)==m_magic
               && LLB_ExecIdFromComment(HistoryOrderGetString(t,ORDER_COMMENT),cid) && LLB_ParseExecId(cid,d6,seq) && d6==date6 && seq>mx)
               mx=seq;
           }
        }
      return mx;
     }

   //+------------------------------------------------------------------+
   //| Pre-send verification - NO side effects (R-EXE-02, A-07, A-08,   |
   //| A-10, A-12, invariants 5/6/7/10).                                |
   //+------------------------------------------------------------------+
   bool              Precheck(const LLBTradeProposal &p,const LLBSymbolSpec &spec,const datetime now,const long &ourPosIds[],
                              double &volume,string &why)
     {
      volume=0.0;
      why="";
      if(!spec.valid || spec.name!=p.symbol)
        { why="SYMBOL_SPEC_UNAVAILABLE"; return false; }
      if(!m_tester && !(bool)TerminalInfoInteger(TERMINAL_CONNECTED))
        { why="NO_BROKER_CONNECTION"; return false; }
      if(!(bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
        { why="TERMINAL_ALGO_TRADING_DISABLED"; return false; }
      if(!(bool)MQLInfoInteger(MQL_TRADE_ALLOWED))
        { why="EA_LIVE_TRADING_NOT_ALLOWED"; return false; }
      if(!(bool)AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
        { why="ACCOUNT_TRADE_DISABLED"; return false; }
      if(!(bool)AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
        { why="ACCOUNT_EXPERT_TRADING_DISABLED"; return false; }
      long tm=SymbolInfoInteger(spec.name,SYMBOL_TRADE_MODE);
      if(tm==SYMBOL_TRADE_MODE_DISABLED || tm==SYMBOL_TRADE_MODE_CLOSEONLY)
        { why="SYMBOL_TRADE_MODE_"+EnumToString((ENUM_SYMBOL_TRADE_MODE)tm); return false; }
      if(tm==SYMBOL_TRADE_MODE_LONGONLY && p.direction==LLB_DIR_SELL)
        { why="SYMBOL_LONG_ONLY"; return false; }
      if(tm==SYMBOL_TRADE_MODE_SHORTONLY && p.direction==LLB_DIR_BUY)
        { why="SYMBOL_SHORT_ONLY"; return false; }
      if(!m_tester && !m_md.IsTradeSessionOpen(spec.name,now))
        { why="MARKET_CLOSED (outside trade session)"; return false; }
      if((spec.orderMode&SYMBOL_ORDER_STOP)==0)
        { why="STOP_ORDERS_NOT_ALLOWED"; return false; }
      if((spec.orderMode&SYMBOL_ORDER_SL)==0 || (spec.orderMode&SYMBOL_ORDER_TP)==0)
        { why="SL_TP_NOT_ALLOWED"; return false; }
      bool specified=((spec.expirationMode&SYMBOL_EXPIRATION_SPECIFIED)!=0);
      if(!specified && !m_allowEaExpiry)
        { why="BROKER_DOES_NOT_SUPPORT_SPECIFIED_EXPIRATION (InpAllowEaManagedExpiry=false)"; return false; }
      if(!specified && (spec.expirationMode&SYMBOL_EXPIRATION_GTC)==0)
        { why="NO_USABLE_EXPIRATION_MODE"; return false; }
      if((long)p.expiresTime-(long)now<LLB_MIN_EXPIRY_LEFT_SEC)
        { why="PROPOSAL_EXPIRES_TOO_SOON"; return false; }
      //--- current price: the pending stop order must still be placeable (A-08)
      MqlTick tk;
      if(!m_md.GetTick(spec.name,tk))
        { why="NO_CURRENT_QUOTE"; return false; }
      double tick=spec.tickSize;
      long stopsPts=SymbolInfoInteger(spec.name,SYMBOL_TRADE_STOPS_LEVEL);
      if(stopsPts<spec.stopsLevel)
         stopsPts=spec.stopsLevel;
      double stops=(double)stopsPts*spec.point;
      if(p.direction==LLB_DIR_BUY)
        {
         if(!(p.sl<p.entry && p.entry<p.tp))
           { why="SLTP_GEOMETRY_INVALID"; return false; }
         if(LLB_PriceAtOrAbove(tk.ask,p.entry,tick))
           {
            why=StringFormat("PRICE_ALREADY_AT_OR_ABOVE_ENTRY ask=%s entry=%s (no market order)",DoubleToString(tk.ask,spec.digits),DoubleToString(p.entry,spec.digits));
            return false;
           }
         if(p.entry-tk.ask<stops-tick*0.5)
           { why="ENTRY_INSIDE_STOPS_LEVEL"; return false; }
         if(p.entry-p.sl<stops-tick*0.5 || p.tp-p.entry<stops-tick*0.5)
           { why="SL_TP_INSIDE_STOPS_LEVEL"; return false; }
        }
      else
        {
         if(!(p.tp<p.entry && p.entry<p.sl))
           { why="SLTP_GEOMETRY_INVALID"; return false; }
         if(LLB_PriceAtOrBelow(tk.bid,p.entry,tick))
           {
            why=StringFormat("PRICE_ALREADY_AT_OR_BELOW_ENTRY bid=%s entry=%s (no market order)",DoubleToString(tk.bid,spec.digits),DoubleToString(p.entry,spec.digits));
            return false;
           }
         if(tk.bid-p.entry<stops-tick*0.5)
           { why="ENTRY_INSIDE_STOPS_LEVEL"; return false; }
         if(p.sl-p.entry<stops-tick*0.5 || p.entry-p.tp<stops-tick*0.5)
           { why="SL_TP_INSIDE_STOPS_LEVEL"; return false; }
        }
      //--- volume (invariant 7)
      if(!m_risk.ComputeVolume(spec,p.direction,p.entry,p.sl,volume,why))
         return false;
      if(spec.volLimit>0.0 && SameDirectionVolume(spec.name,p.direction)+volume>spec.volLimit+1e-9)
        { why="SYMBOL_VOLUME_LIMIT_EXCEEDED"; return false; }
      //--- margin
      double margin=0.0;
      ENUM_ORDER_TYPE mt=(p.direction==LLB_DIR_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      ResetLastError();
      if(!OrderCalcMargin(mt,spec.name,volume,p.entry,margin))
        { why="ORDERCALCMARGIN_FAILED err="+(string)GetLastError(); return false; }
      double freeMargin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      if(margin>freeMargin)
        {
         why=StringFormat("NOT_ENOUGH_MARGIN need=%s free=%s",DoubleToString(margin,2),DoubleToString(freeMargin,2));
         return false;
        }
      long lim=AccountInfoInteger(ACCOUNT_LIMIT_ORDERS);
      if(lim>0 && OrdersTotal()>=lim)
        { why="ACCOUNT_PENDING_ORDER_LIMIT"; return false; }
      //--- netting: never merge into another position/order on the symbol (A-12)
      if(m_netting)
        {
         if(PositionSelect(spec.name))
           { why="NETTING_SYMBOL_HAS_OPEN_POSITION"; return false; }
         if(SymbolHasPendingOrder(spec.name))
           { why="NETTING_SYMBOL_HAS_PENDING_ORDER"; return false; }
        }
      //--- optional daily loss limit
      double realized=0.0;
      string dwhy;
      if(m_risk.DailyLossBlocked(now,ourPosIds,realized,dwhy))
        { why=dwhy; return false; }
      //--- one execution per Signal ID (invariant 5)
      if(FindBySignal(p.signalId)>=0)
        { why="EXECUTION_RECORD_ALREADY_EXISTS"; return false; }
      ulong exTicket=0;
      string where;
      if(BrokerHasExec(p.execId,now,exTicket,where))
        { why="EXECUTION_ALREADY_ON_BROKER ("+where+" #"+(string)exTicket+")"; return false; }
      return true;
     }

   //+------------------------------------------------------------------+
   //| Execute an ACCEPTED proposal (called by ApprovalManager only)    |
   //| Returns true only when the broker confirmed the pending order.   |
   //+------------------------------------------------------------------+
   bool              Execute(CLLBProposalManager *pm,const int pidx,const LLBSymbolSpec &spec,const datetime now,const long &ourPosIds[],string &msg)
     {
      msg="";
      if(pm==NULL || pidx<0 || pidx>=pm.Count())
        {
         msg="INTERNAL: proposal index invalid";
         return false;
        }
      LLBTradeProposal p=pm.items[pidx];
      //--- invariants 1/2/3/4: only an ACCEPTED proposal with an ACCEPT decision, before expiry
      if(p.state!=LLB_PS_ACCEPTED || p.decision!=LLB_DEC_ACCEPT)
        {
         msg="REFUSED: "+p.signalId+" is "+LLB_ProposalStateName(p.state)+" / decision "+LLB_DecisionName(p.decision);
         g_llbLog.Error("EXE",msg);
         return false;
        }
      if(now>=p.expiresTime)
        {
         pm.Transition(pidx,LLB_PS_EXECUTION_FAILED,"EXPIRED_BEFORE_SUBMIT");
         msg="EXECUTION FAILED "+p.signalId+": expired before submission";
         return false;
        }
      double volume=0.0;
      string why;
      if(!Precheck(p,spec,now,ourPosIds,volume,why))
        {
         RecordPrecheckFailure(p,why);
         pm.Transition(pidx,LLB_PS_EXECUTION_FAILED,"PRECHECK: "+why);
         msg="EXECUTION FAILED "+p.signalId+": "+why+" (no order sent)";
         return false;
        }
      MqlTradeRequest rq;
      MqlTradeResult  rs;
      MqlTradeCheckResult ck;
      ZeroMemory(rq);
      ZeroMemory(rs);
      ZeroMemory(ck);
      bool specified=((spec.expirationMode&SYMBOL_EXPIRATION_SPECIFIED)!=0);
      rq.action      =TRADE_ACTION_PENDING;
      rq.symbol      =spec.name;
      rq.volume      =volume;
      rq.type        =(p.direction==LLB_DIR_BUY) ? ORDER_TYPE_BUY_STOP : ORDER_TYPE_SELL_STOP;
      rq.price       =NormalizeDouble(p.entry,spec.digits);
      rq.sl          =NormalizeDouble(p.sl,spec.digits);
      rq.tp          =NormalizeDouble(p.tp,spec.digits);
      rq.deviation   =0;
      rq.magic       =m_magic;
      rq.type_filling=ORDER_FILLING_RETURN;          // MQL5 docs: pending orders use RETURN regardless of execution mode
      rq.type_time   =specified ? ORDER_TIME_SPECIFIED : ORDER_TIME_GTC;
      rq.expiration  =specified ? p.expiresTime : (datetime)0;
      rq.comment     =LLB_EntryComment(p.execId);
      ResetLastError();
      if(!ChoosePendingFilling(rq,spec,ck))
        {
         why=StringFormat("ORDERCHECK rc=%u %s %s",ck.retcode,LLB_RetcodeText(ck.retcode),ck.comment);
         RecordPrecheckFailure(p,why);
         pm.Transition(pidx,LLB_PS_EXECUTION_FAILED,why);
         msg="EXECUTION FAILED "+p.signalId+": "+why+" (no order sent)";
         return false;
        }
      //--- persist SUBMITTING before sending (R-EXE-07)
      LLBExecutionRecord e;
      e.Reset();
      e.execId=p.execId;
      e.signalId=p.signalId;
      e.symbol=spec.name;
      e.direction=p.direction;
      e.orderType=(int)rq.type;
      e.state=LLB_EX_SUBMITTING;
      e.orderState=LLB_OS_NONE;
      e.volume=volume;
      e.entry=rq.price;
      e.sl=rq.sl;
      e.tp=rq.tp;
      e.expiration=p.expiresTime;
      e.typeTime=(int)rq.type_time;
      e.filling=(int)rq.type_filling;
      e.submitMsc=(long)TimeTradeServer()*1000;
      e.refSwingPrice=p.refSwingPrice;
      e.monitorFromMsc=p.monitorFromMsc;
      e.structState=LLB_ST_INTACT;
      e.checkedMsc=p.checkedMsc;
      int eidx=ArraySize(items);
      ArrayResize(items,eidx+1,32);
      items[eidx]=e;
      if(!Journal(eidx))
        {
         items[eidx].state=LLB_EX_PRECHECK_FAILED;
         items[eidx].note="PERSIST_FAILED_NOT_SENT";
         pm.Transition(pidx,LLB_PS_EXECUTION_FAILED,"PERSIST_FAILED: SUBMITTING record not written - order NOT sent");
         msg="EXECUTION FAILED "+p.signalId+": cannot write executions.csv - order NOT sent (fail-safe)";
         return false;
        }
      pm.Transition(pidx,LLB_PS_EXECUTING,"SUBMITTING "+p.execId);
      //--- the single order-opening OrderSend of the EA
      ResetLastError();
      bool sent=OrderSend(rq,rs);
      int lastErr=GetLastError();
      uint rc=rs.retcode;
      items[eidx].retcode=rc;
      items[eidx].retComment=rs.comment;
      items[eidx].orderTicket=rs.order;
      items[eidx].dealTicket=rs.deal;
      if(LLB_IsRetcodeAccepted(rc) && rs.order>0)
        {
         items[eidx].state=LLB_EX_PLACED;
         items[eidx].orderState=LLB_OS_PENDING;
         Journal(eidx);
         pm.Transition(pidx,LLB_PS_EXECUTED,StringFormat("PLACED #%I64u rc=%u",rs.order,rc));
         msg=StringFormat("ORDER PLACED %s\n%s #%I64u vol %s @ %s\nSL %s | TP %s\nExpires %s (server)",p.signalId,
                          LLB_OrderTypeName((int)rq.type),rs.order,DoubleToString(volume,2),DoubleToString(rq.price,spec.digits),
                          DoubleToString(rq.sl,spec.digits),DoubleToString(rq.tp,spec.digits),LLB_TimeStr(p.expiresTime));
         if(!specified)
            msg+="\nNote: broker has no SPECIFIED expiration - EA deletes the order at expiry (EA must stay online)";
         string vmsg;
         if(!VerifyPlacedOrder(eidx,spec,vmsg))
            msg+="\n"+vmsg;
         return true;
        }
      if(LLB_IsRetcodeClearReject(rc))
        {
         items[eidx].state=LLB_EX_REJECTED;
         Journal(eidx);
         string r=StringFormat("BROKER_REJECT rc=%u %s %s",rc,LLB_RetcodeText(rc),rs.comment);
         pm.Transition(pidx,LLB_PS_EXECUTION_FAILED,r);
         msg="EXECUTION FAILED "+p.signalId+": "+r;
         return false;
        }
      items[eidx].state=LLB_EX_UNKNOWN;
      items[eidx].note=StringFormat("sent=%s rc=%u err=%d",sent ? "true" : "false",rc,lastErr);
      Journal(eidx);
      msg=StringFormat("RESULT UNKNOWN %s (rc=%u %s). The order is NOT re-sent; reconciling with broker orders/deals.",
                       p.signalId,rc,LLB_RetcodeText(rc));
      g_llbLog.Warn("EXE",msg);
      return false;
     }

   //--- broker order parameters must equal the request (A-32)
   bool              VerifyPlacedOrder(const int eidx,const LLBSymbolSpec &spec,string &msg)
     {
      msg="";
      ulong tk=items[eidx].orderTicket;
      if(tk==0 || !OrderSelect(tk))
         return true;                                    // already triggered or not listed yet: reconciliation checks the position
      double op=OrderGetDouble(ORDER_PRICE_OPEN);
      double osl=OrderGetDouble(ORDER_SL);
      double otp=OrderGetDouble(ORDER_TP);
      if(LLB_PriceEq(op,items[eidx].entry,spec.tickSize) && LLB_PriceEq(osl,items[eidx].sl,spec.tickSize) && LLB_PriceEq(otp,items[eidx].tp,spec.tickSize))
         return true;
      msg=StringFormat("ORDER PARAMETER MISMATCH #%I64u broker price/SL/TP=%s/%s/%s expected %s/%s/%s - deleting order",tk,
                       DoubleToString(op,spec.digits),DoubleToString(osl,spec.digits),DoubleToString(otp,spec.digits),
                       DoubleToString(items[eidx].entry,spec.digits),DoubleToString(items[eidx].sl,spec.digits),DoubleToString(items[eidx].tp,spec.digits));
      g_llbLog.Error("EXE",msg);
      string dm;
      DeleteOrder(eidx,"SLTP_MISMATCH",spec,dm);
      return false;
     }

   //--- delete the pending order of an execution (invalidation, mismatch, EA-managed expiry)
   bool              DeleteOrder(const int eidx,const string reason,const LLBSymbolSpec &spec,string &msg)
     {
      msg="";
      if(eidx<0 || eidx>=ArraySize(items))
         return false;
      ulong ticket=items[eidx].orderTicket;
      if(ticket==0)
        {
         msg="NO_ORDER_TICKET";
         return false;
        }
      if(!OrderSelect(ticket))
        {
         msg="ORDER_NOT_PENDING_ANYMORE";
         return false;
        }
      if((ulong)OrderGetInteger(ORDER_MAGIC)!=m_magic || OrderGetString(ORDER_SYMBOL)!=items[eidx].symbol)
        {
         msg="ORDER_NOT_OWNED_BY_EA - refused";
         g_llbLog.Error("EXE",msg+" #"+(string)ticket);
         return false;
        }
      MqlTick tk;
      if(spec.freezeLevel>0 && SymbolInfoTick(spec.name,tk))
        {
         double fz=(double)spec.freezeLevel*spec.point;
         double cur=(items[eidx].direction==LLB_DIR_BUY) ? tk.ask : tk.bid;
         if(MathAbs(OrderGetDouble(ORDER_PRICE_OPEN)-cur)<=fz)
           {
            msg="ORDER_INSIDE_FREEZE_LEVEL - retry later";
            return false;
           }
        }
      MqlTradeRequest rq;
      MqlTradeResult  rs;
      ZeroMemory(rq);
      ZeroMemory(rs);
      rq.action=TRADE_ACTION_REMOVE;
      rq.order=ticket;
      string prevReason=items[eidx].cancelReason;
      items[eidx].cancelReason=reason;
      items[eidx].lastActionMs=LLB_NowMs();
      items[eidx].actionAttempts++;
      Journal(eidx);
      ResetLastError();
      bool sent=OrderSend(rq,rs);
      uint rc=rs.retcode;
      if(LLB_IsRetcodeAccepted(rc))
        {
         msg=StringFormat("pending order #%I64u delete requested (%s)",ticket,reason);
         g_llbLog.Info("EXE",items[eidx].execId+" "+msg);
         return true;
        }
      if(LLB_IsRetcodeClearReject(rc))
        {
         items[eidx].cancelReason=prevReason;
         Journal(eidx);
        }
      msg=StringFormat("delete #%I64u failed sent=%s rc=%u %s",ticket,sent ? "true" : "false",rc,LLB_RetcodeText(rc));
      g_llbLog.Warn("EXE",items[eidx].execId+" "+msg);
      return false;
     }

   //--- close an EA-owned position (structure invalidation / unsettable SL)
   bool              ClosePosition(const LLBManagedPosition &m,const LLBSymbolSpec &spec,const string reason,uint &rc,string &msg)
     {
      rc=0;
      msg="";
      ulong ticket=0;
      if(!LLB_SelectPositionById(m.positionId,ticket))
        {
         msg="POSITION_NOT_FOUND";
         return false;
        }
      if(PositionGetString(POSITION_SYMBOL)!=m.symbol)
        {
         msg="POSITION_SYMBOL_MISMATCH - refused";
         return false;
        }
      double vol=PositionGetDouble(POSITION_VOLUME);
      long ptype=PositionGetInteger(POSITION_TYPE);
      int pdir=(ptype==POSITION_TYPE_BUY) ? LLB_DIR_BUY : LLB_DIR_SELL;
      if(pdir!=m.direction)
        {
         msg="POSITION_DIRECTION_MISMATCH - refused";
         return false;
        }
      if(m_netting && MathAbs(vol-m.volume)>spec.volStep*0.5)
        {
         msg="NETTING_VOLUME_MISMATCH (ownership conflict) - refused";
         return false;
        }
      if(!m_netting && (ulong)PositionGetInteger(POSITION_MAGIC)!=m_magic)
        {
         msg="POSITION_MAGIC_MISMATCH - refused";
         return false;
        }
      MqlTick tk;
      if(!SymbolInfoTick(spec.name,tk))
        {
         msg="NO_QUOTE";
         return false;
        }
      MqlTradeRequest rq;
      MqlTradeResult  rs;
      MqlTradeCheckResult ck;
      ZeroMemory(rq);
      ZeroMemory(rs);
      ZeroMemory(ck);
      rq.action   =TRADE_ACTION_DEAL;
      rq.position =ticket;
      rq.symbol   =spec.name;
      rq.volume   =vol;
      rq.type     =(pdir==LLB_DIR_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
      rq.price    =NormalizeDouble((pdir==LLB_DIR_BUY) ? tk.bid : tk.ask,spec.digits);
      rq.deviation=(ulong)MathMax(m_closeDeviation,0);
      rq.magic    =m_magic;
      rq.comment  =LLB_CloseComment(m.execId);
      if(!ChooseMarketFilling(rq,spec,ck))
        {
         rc=ck.retcode;
         msg=StringFormat("close #%I64d OrderCheck failed rc=%u %s %s",m.positionId,ck.retcode,LLB_RetcodeText(ck.retcode),ck.comment);
         return false;
        }
      ResetLastError();
      bool sent=OrderSend(rq,rs);
      rc=rs.retcode;
      msg=StringFormat("close #%I64d (%s) vol=%s sent=%s rc=%u %s",m.positionId,reason,DoubleToString(vol,2),sent ? "true" : "false",rc,LLB_RetcodeText(rc));
      return LLB_IsRetcodeAccepted(rc);
     }

   //--- attach the approved SL/TP when they are missing, or tighten an SL that is WIDER than approved.
   //--- An existing SL is never moved further away (invariant 9) and an existing TP is never changed.
   bool              ModifyPositionStops(const LLBManagedPosition &m,const LLBSymbolSpec &spec,uint &rc,string &msg,bool &priceBeyondSl)
     {
      rc=0;
      msg="";
      priceBeyondSl=false;
      if(m.expectedSl<=0.0 || m.expectedTp<=0.0)
        {
         msg="EXPECTED_SLTP_UNKNOWN";
         return false;
        }
      ulong ticket=0;
      if(!LLB_SelectPositionById(m.positionId,ticket))
        {
         msg="POSITION_NOT_FOUND";
         return false;
        }
      if(PositionGetString(POSITION_SYMBOL)!=m.symbol || (!m_netting && (ulong)PositionGetInteger(POSITION_MAGIC)!=m_magic))
        {
         msg="POSITION_NOT_OWNED - refused";
         return false;
        }
      if(m_netting && MathAbs(PositionGetDouble(POSITION_VOLUME)-m.volume)>spec.volStep*0.5)
        {
         msg="NETTING_VOLUME_MISMATCH - refused";
         return false;
        }
      double curSl=PositionGetDouble(POSITION_SL);
      double curTp=PositionGetDouble(POSITION_TP);
      double sl=curSl;
      double tp=curTp;
      if(!LLB_SlWithinApproved(m.direction,curSl,m.expectedSl,spec.tickSize))
         sl=m.expectedSl;                                // missing or wider than approved -> approved SL (tighter)
      if(curTp<=0.0)
         tp=m.expectedTp;                                // missing -> approved TP
      if(LLB_PriceEq(sl,curSl,spec.tickSize) && LLB_PriceEq(tp,curTp,spec.tickSize))
        {
         msg="SLTP_ALREADY_ACCEPTABLE";
         return true;
        }
      if(curSl>0.0 && ((m.direction==LLB_DIR_BUY && sl<curSl) || (m.direction==LLB_DIR_SELL && sl>curSl)))
        {
         msg="REFUSED: would widen the stop loss";
         return false;
        }
      MqlTick tk;
      if(!SymbolInfoTick(spec.name,tk))
        {
         msg="NO_QUOTE";
         return false;
        }
      double stops=(double)spec.stopsLevel*spec.point;
      if(m.direction==LLB_DIR_BUY)
        {
         if(tk.bid<=sl)
           {
            priceBeyondSl=true;
            msg="PRICE_BEYOND_EXPECTED_SL";
            return false;
           }
         if(tk.bid-sl<stops || tp-tk.bid<stops)
           {
            msg="SLTP_INSIDE_STOPS_LEVEL";
            return false;
           }
        }
      else
        {
         if(tk.ask>=sl)
           {
            priceBeyondSl=true;
            msg="PRICE_BEYOND_EXPECTED_SL";
            return false;
           }
         if(sl-tk.ask<stops || tk.ask-tp<stops)
           {
            msg="SLTP_INSIDE_STOPS_LEVEL";
            return false;
           }
        }
      MqlTradeRequest rq;
      MqlTradeResult  rs;
      ZeroMemory(rq);
      ZeroMemory(rs);
      rq.action  =TRADE_ACTION_SLTP;
      rq.position=ticket;
      rq.symbol  =spec.name;
      rq.sl      =NormalizeDouble(sl,spec.digits);
      rq.tp      =NormalizeDouble(tp,spec.digits);
      rq.magic   =m_magic;
      ResetLastError();
      bool sent=OrderSend(rq,rs);
      rc=rs.retcode;
      msg=StringFormat("set SL/TP #%I64d -> %s/%s sent=%s rc=%u %s",m.positionId,DoubleToString(sl,spec.digits),DoubleToString(tp,spec.digits),
                       sent ? "true" : "false",rc,LLB_RetcodeText(rc));
      return LLB_IsRetcodeAccepted(rc);
     }

   //--- pending order that the EA must delete itself (GTC fallback, A-07)
   bool              NeedsEaExpiry(const int i,const datetime now)
     {
      return (items[i].state==LLB_EX_PLACED && (items[i].orderState==LLB_OS_PENDING || items[i].orderState==LLB_OS_PARTIAL)
              && items[i].typeTime==(int)ORDER_TIME_GTC && items[i].expiration>0 && now>=items[i].expiration);
     }

   bool              IsLivePending(const int i)
     {
      return (items[i].state==LLB_EX_PLACED && (items[i].orderState==LLB_OS_PENDING || items[i].orderState==LLB_OS_PARTIAL));
     }

   void              SetStructInvalid(const int i,const string why)
     {
      if(items[i].structState==LLB_ST_INVALIDATED)
         return;
      items[i].structState=LLB_ST_INVALIDATED;
      items[i].note+=" | "+why;
      Journal(i);
     }

   //+------------------------------------------------------------------+
   //| Reconciliation with broker orders / deals / positions (§8)       |
   //+------------------------------------------------------------------+
   int               Reconcile(CLLBProposalManager *pm,const datetime now,const bool stable,const bool startup,LLBExecEvent &events[])
     {
      int cnt=0;
      for(int i=0; i<ArraySize(items); i++)
        {
         int st=items[i].state;
         if(st==LLB_EX_SUBMITTING || st==LLB_EX_UNKNOWN)
           {
            ulong tk=0;
            if(FindOrderForExec(i,now,tk))
              {
               items[i].orderTicket=tk;
               items[i].state=LLB_EX_PLACED;
               items[i].orderState=LLB_OS_PENDING;
               items[i].note+=" | RECONCILED_FOUND";
               Journal(i);
               int pidx=pm.Find(items[i].signalId);
               if(pidx>=0)
                 {
                  string r="RECONCILED: order #"+(string)tk+" found on broker";
                  if(!pm.Transition(pidx,LLB_PS_EXECUTED,r))
                     pm.ForceState(pidx,LLB_PS_EXECUTED,r);
                 }
               LLB_AddEvent(events,LLB_EV_PLACED,i,0,"order #"+(string)tk+" confirmed by reconciliation");
               cnt++;
               st=LLB_EX_PLACED;
              }
            else
              {
               long ageMs=(long)now*1000-items[i].submitMsc;
               bool giveUp=stable && ((startup && st==LLB_EX_SUBMITTING) || ageMs>=(long)LLB_UNKNOWN_RESOLVE_SEC*1000);
               if(giveUp)
                 {
                  items[i].state=LLB_EX_NOT_FOUND;
                  items[i].note+=" | NOT_FOUND_AFTER_RECONCILE";
                  Journal(i);
                  int pidx=pm.Find(items[i].signalId);
                  if(pidx>=0)
                     pm.Transition(pidx,LLB_PS_EXECUTION_FAILED,"NOT_FOUND_AFTER_RECONCILE (order never re-sent)");
                  LLB_AddEvent(events,LLB_EV_FAILED,i,0,"no order found on broker after reconciliation - execution failed, nothing re-sent");
                  cnt++;
                 }
               continue;
              }
           }
         if(st==LLB_EX_PLACED && (items[i].orderState==LLB_OS_PENDING || items[i].orderState==LLB_OS_PARTIAL || items[i].orderState==LLB_OS_NONE))
            UpdateOrderState(i,now,events);
        }
      return cnt;
     }

   //--- adopt EA orders/positions that have no execution record (journal loss, late fills)
   int               AdoptOrphans(CLLBProposalManager *pm,const datetime now,const bool includeHistory,LLBExecEvent &events[])
     {
      int cnt=0;
      //--- history orders of the last days (filled/expired/cancelled while the EA was offline)
      if(includeHistory && HistorySelect(now-3*86400,now+86400))
        {
         int hn=HistoryOrdersTotal();
         for(int k=0; k<hn; k++)
           {
            ulong t=HistoryOrderGetTicket(k);
            if(t==0 || (ulong)HistoryOrderGetInteger(t,ORDER_MAGIC)!=m_magic)
               continue;
            string execId;
            if(!LLB_ExecIdFromComment(HistoryOrderGetString(t,ORDER_COMMENT),execId))
               continue;
            if(Find(execId)>=0)
               continue;
            long hs=HistoryOrderGetInteger(t,ORDER_STATE);
            int os=LLB_OS_NONE;
            if(hs==ORDER_STATE_FILLED)
               os=LLB_OS_FILLED;
            else
               if(hs==ORDER_STATE_EXPIRED)
                  os=LLB_OS_EXPIRED;
               else
                  if(hs==ORDER_STATE_CANCELED)
                     os=LLB_OS_CANCELLED_EXT;
                  else
                     if(hs==ORDER_STATE_REJECTED)
                        os=LLB_OS_REJECTED;
                     else
                        continue;
            LLBExecutionRecord r;
            r.Reset();
            r.execId=execId;
            r.symbol=HistoryOrderGetString(t,ORDER_SYMBOL);
            long ot=HistoryOrderGetInteger(t,ORDER_TYPE);
            r.orderType=(int)ot;
            r.direction=(ot==ORDER_TYPE_BUY_STOP || ot==ORDER_TYPE_BUY_LIMIT || ot==ORDER_TYPE_BUY_STOP_LIMIT || ot==ORDER_TYPE_BUY) ? LLB_DIR_BUY : LLB_DIR_SELL;
            r.state=LLB_EX_PLACED;
            r.orderState=os;
            r.volume=HistoryOrderGetDouble(t,ORDER_VOLUME_INITIAL);
            r.entry=HistoryOrderGetDouble(t,ORDER_PRICE_OPEN);
            r.sl=HistoryOrderGetDouble(t,ORDER_SL);
            r.tp=HistoryOrderGetDouble(t,ORDER_TP);
            r.expiration=(datetime)HistoryOrderGetInteger(t,ORDER_TIME_EXPIRATION);
            r.typeTime=(int)HistoryOrderGetInteger(t,ORDER_TYPE_TIME);
            r.filling=(int)HistoryOrderGetInteger(t,ORDER_TYPE_FILLING);
            r.submitMsc=HistoryOrderGetInteger(t,ORDER_TIME_SETUP_MSC);
            r.orderTicket=t;
            r.positionId=HistoryOrderGetInteger(t,ORDER_POSITION_ID);
            double filled=r.volume-HistoryOrderGetDouble(t,ORDER_VOLUME_CURRENT);
            r.fillVolume=(filled>0.0) ? filled : 0.0;
            r.note="ORPHAN_HISTORY_ADOPTED";
            int pidx=pm.FindByExecId(execId);
            if(pidx>=0)
              {
               r.signalId=pm.items[pidx].signalId;
               r.refSwingPrice=pm.items[pidx].refSwingPrice;
               r.monitorFromMsc=pm.items[pidx].monitorFromMsc;
               pm.ForceState(pidx,LLB_PS_EXECUTED,"ORPHAN_ADOPTED: history order #"+(string)t+" "+LLB_OrderStateName(os));
              }
            else
               r.signalId="UNKNOWN";
            int n=ArraySize(items);
            ArrayResize(items,n+1,32);
            items[n]=r;
            if(r.positionId>0 && r.fillVolume>0.0)
               FillDetails(n);
            Journal(n);
            if(r.positionId>0 && r.fillVolume>0.0)
               LLB_AddEvent(events,LLB_EV_FILLED,n,r.positionId,"adopted EA history order #"+(string)t+" ("+LLB_OrderStateName(os)+")");
            else
               LLB_AddEvent(events,LLB_EV_ORPHAN,n,0,"adopted EA history order #"+(string)t+" ("+LLB_OrderStateName(os)+")");
            cnt++;
           }
        }
      for(int k=OrdersTotal()-1; k>=0; k--)
        {
         ulong t=OrderGetTicket(k);
         if(t==0 || (ulong)OrderGetInteger(ORDER_MAGIC)!=m_magic)
            continue;
         string execId;
         if(!LLB_ExecIdFromComment(OrderGetString(ORDER_COMMENT),execId))
            continue;
         int e=Find(execId);
         if(e>=0)
           {
            bool dead=(items[e].state==LLB_EX_NOT_FOUND || items[e].state==LLB_EX_REJECTED || items[e].state==LLB_EX_PRECHECK_FAILED);
            if(!dead)
               continue;
            items[e].state=LLB_EX_PLACED;
            items[e].orderState=LLB_OS_PENDING;
            items[e].orderTicket=t;
            items[e].note+=" | REPAIRED_LIVE_ORDER_FOUND";
            Journal(e);
            int pidx=pm.Find(items[e].signalId);
            if(pidx>=0)
               pm.ForceState(pidx,LLB_PS_EXECUTED,"REPAIRED: live order #"+(string)t+" found on broker");
            LLB_AddEvent(events,LLB_EV_ORPHAN,e,0,"live order #"+(string)t+" found for a record marked failed - state repaired");
            cnt++;
            continue;
           }
         LLBExecutionRecord r;
         r.Reset();
         r.execId=execId;
         r.symbol=OrderGetString(ORDER_SYMBOL);
         long ot=OrderGetInteger(ORDER_TYPE);
         r.orderType=(int)ot;
         r.direction=(ot==ORDER_TYPE_BUY_STOP || ot==ORDER_TYPE_BUY_LIMIT || ot==ORDER_TYPE_BUY_STOP_LIMIT) ? LLB_DIR_BUY : LLB_DIR_SELL;
         r.state=LLB_EX_PLACED;
         r.orderState=LLB_OS_PENDING;
         r.volume=OrderGetDouble(ORDER_VOLUME_INITIAL);
         r.entry=OrderGetDouble(ORDER_PRICE_OPEN);
         r.sl=OrderGetDouble(ORDER_SL);
         r.tp=OrderGetDouble(ORDER_TP);
         r.expiration=(datetime)OrderGetInteger(ORDER_TIME_EXPIRATION);
         r.typeTime=(int)OrderGetInteger(ORDER_TYPE_TIME);
         r.filling=(int)OrderGetInteger(ORDER_TYPE_FILLING);
         r.submitMsc=OrderGetInteger(ORDER_TIME_SETUP_MSC);
         r.orderTicket=t;
         r.note="ORPHAN_ADOPTED";
         int pidx=pm.FindByExecId(execId);
         if(pidx>=0)
           {
            r.signalId=pm.items[pidx].signalId;
            r.refSwingPrice=pm.items[pidx].refSwingPrice;
            r.monitorFromMsc=pm.items[pidx].monitorFromMsc;
            pm.ForceState(pidx,LLB_PS_EXECUTED,"ORPHAN_ADOPTED: live order #"+(string)t);
           }
         else
            r.signalId="UNKNOWN";
         int n=ArraySize(items);
         ArrayResize(items,n+1,32);
         items[n]=r;
         Journal(n);
         LLB_AddEvent(events,LLB_EV_ORPHAN,n,0,"adopted EA pending order #"+(string)t+" without execution record");
         cnt++;
        }
      for(int k=PositionsTotal()-1; k>=0; k--)
        {
         ulong t=PositionGetTicket(k);
         if(t==0)
            continue;
         string execId;
         if(!LLB_ExecIdFromComment(PositionGetString(POSITION_COMMENT),execId))
            continue;
         long pid=PositionGetInteger(POSITION_IDENTIFIER);
         int e=Find(execId);
         if(e>=0)
           {
            if(items[e].positionId==pid && (items[e].orderState==LLB_OS_FILLED || items[e].orderState==LLB_OS_PARTIAL))
               continue;
            if(items[e].state!=LLB_EX_PLACED && items[e].state!=LLB_EX_NOT_FOUND && items[e].state!=LLB_EX_REJECTED
               && items[e].state!=LLB_EX_PRECHECK_FAILED)
               continue;                                       // SUBMITTING/UNKNOWN: Reconcile() handles it
            items[e].state=LLB_EX_PLACED;
            items[e].orderState=LLB_OS_FILLED;
            items[e].positionId=pid;
            items[e].note+=" | POSITION_LINKED";
            Journal(e);
            int pidx=pm.Find(items[e].signalId);
            if(pidx>=0 && pm.items[pidx].state!=LLB_PS_EXECUTED)
               pm.ForceState(pidx,LLB_PS_EXECUTED,"REPAIRED: position #"+(string)pid+" found on broker");
            LLB_AddEvent(events,LLB_EV_FILLED,e,pid,"position #"+(string)pid+" linked by reconciliation");
            cnt++;
            continue;
           }
         if(!m_netting && (ulong)PositionGetInteger(POSITION_MAGIC)!=m_magic)
            continue;
         LLBExecutionRecord r;
         r.Reset();
         r.execId=execId;
         r.symbol=PositionGetString(POSITION_SYMBOL);
         r.direction=(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) ? LLB_DIR_BUY : LLB_DIR_SELL;
         r.orderType=(r.direction==LLB_DIR_BUY) ? (int)ORDER_TYPE_BUY_STOP : (int)ORDER_TYPE_SELL_STOP;
         r.state=LLB_EX_PLACED;
         r.orderState=LLB_OS_FILLED;
         r.volume=PositionGetDouble(POSITION_VOLUME);
         r.entry=PositionGetDouble(POSITION_PRICE_OPEN);
         r.sl=PositionGetDouble(POSITION_SL);
         r.tp=PositionGetDouble(POSITION_TP);
         r.submitMsc=PositionGetInteger(POSITION_TIME_MSC);
         r.positionId=pid;
         r.fillPrice=r.entry;
         r.fillVolume=r.volume;
         r.note="ORPHAN_POSITION_ADOPTED";
         int pidx=pm.FindByExecId(execId);
         if(pidx>=0)
           {
            r.signalId=pm.items[pidx].signalId;
            r.refSwingPrice=pm.items[pidx].refSwingPrice;
            r.monitorFromMsc=pm.items[pidx].monitorFromMsc;
            r.sl=pm.items[pidx].sl;
            r.tp=pm.items[pidx].tp;
            pm.ForceState(pidx,LLB_PS_EXECUTED,"ORPHAN_ADOPTED: position #"+(string)pid);
           }
         else
            r.signalId="UNKNOWN";
         int n=ArraySize(items);
         ArrayResize(items,n+1,32);
         items[n]=r;
         Journal(n);
         LLB_AddEvent(events,LLB_EV_FILLED,n,pid,"adopted EA position #"+(string)pid+" without execution record");
         cnt++;
        }
      return cnt;
     }

   //--- forget old final records (they stay in the journal)
   void              Prune(const datetime now)
     {
      int w=0;
      int n=ArraySize(items);
      for(int i=0; i<n; i++)
        {
         bool drop=(IsFinal(items[i]) && (long)now-items[i].submitMsc/1000>(long)LLB_KEEP_DAYS*86400);
         if(drop)
            continue;
         if(w!=i)
            items[w]=items[i];
         w++;
        }
      if(w!=n)
         ArrayResize(items,w);
     }
  };

#endif
//+------------------------------------------------------------------+
