//+------------------------------------------------------------------+
//| LLB_Positions.mqh                                                |
//| PositionManager (R-POS-01..07): tracks only positions opened by  |
//| EA executions (magic + execution id), verifies broker SL/TP,     |
//| detects ownership conflicts on netting accounts, closes on       |
//| touch invalidation through ExecutionManager, records the close   |
//| (reason, profit, commission, swap, fee).                         |
//| No trailing, break-even, partial close, scaling (R-POS-04).      |
//+------------------------------------------------------------------+
#ifndef LLB_POSITIONS_MQH
#define LLB_POSITIONS_MQH

#include "LLB_Defines.mqh"
#include "LLB_Utils.mqh"
#include "LLB_Logger.mqh"
#include "LLB_Persistence.mqh"
#include "LLB_Execution.mqh"

class CLLBPositionManager
  {
private:
   CLLBPersistence      *m_per;
   CLLBExecutionManager *m_exec;
   ulong                 m_magic;
   bool                  m_netting;

   bool              Journal(const int idx)
     {
      if(m_per==NULL)
         return false;
      bool ok=m_per.AppendLine(LLB_FILE_POSITIONS,LLB_PosCsvHeader(),LLB_PosToCsv(items[idx],TimeTradeServer()));
      if(!ok)
         g_llbLog.Error("POS","JOURNAL_WRITE_FAILED #"+(string)items[idx].positionId);
      return ok;
     }

   //--- fills close data from deal history; true when the position is fully closed
   bool              ReadClosedFromHistory(const int idx)
     {
      long pid=items[idx].positionId;
      if(!HistorySelectByPosition(pid))
         return false;
      int n=HistoryDealsTotal();
      double inVol=0.0,outVol=0.0,outPx=0.0;
      double profit=0.0,comm=0.0,swp=0.0,fee=0.0;
      datetime lastOut=0;
      long lastReason=-1;
      string lastComment="";
      for(int k=0; k<n; k++)
        {
         ulong d=HistoryDealGetTicket(k);
         if(d==0)
            continue;
         long entry=HistoryDealGetInteger(d,DEAL_ENTRY);
         double v=HistoryDealGetDouble(d,DEAL_VOLUME);
         profit+=HistoryDealGetDouble(d,DEAL_PROFIT);
         comm+=HistoryDealGetDouble(d,DEAL_COMMISSION);
         swp+=HistoryDealGetDouble(d,DEAL_SWAP);
         fee+=HistoryDealGetDouble(d,DEAL_FEE);
         if(entry==DEAL_ENTRY_IN)
            inVol+=v;
         if(entry==DEAL_ENTRY_OUT || entry==DEAL_ENTRY_OUT_BY || entry==DEAL_ENTRY_INOUT)
           {
            outVol+=v;
            outPx+=v*HistoryDealGetDouble(d,DEAL_PRICE);
            datetime t=(datetime)HistoryDealGetInteger(d,DEAL_TIME);
            if(t>=lastOut)
              {
               lastOut=t;
               lastReason=HistoryDealGetInteger(d,DEAL_REASON);
               lastComment=HistoryDealGetString(d,DEAL_COMMENT);
              }
           }
        }
      if(outVol<=0.0 || outVol+1e-9<inVol)
         return false;
      items[idx].closeTime=lastOut;
      items[idx].closePrice=outPx/outVol;
      items[idx].profit=profit;
      items[idx].commission=comm;
      items[idx].swap=swp;
      items[idx].fee=fee;
      int cr=LLB_CR_OTHER;
      if(lastReason==DEAL_REASON_SL)
         cr=LLB_CR_SL;
      else
         if(lastReason==DEAL_REASON_TP)
            cr=LLB_CR_TP;
         else
            if(lastReason==DEAL_REASON_SO)
               cr=LLB_CR_STOP_OUT;
            else
               if(lastReason==DEAL_REASON_CLIENT || lastReason==DEAL_REASON_MOBILE || lastReason==DEAL_REASON_WEB)
                  cr=LLB_CR_MANUAL;
               else
                  if(lastReason==DEAL_REASON_EXPERT)
                    {
                     //--- closed by an EA request: attribute to the reason the EA recorded
                     if(items[idx].closeRequested && items[idx].closeReason==LLB_CR_SLTP_UNSETTABLE)
                        cr=LLB_CR_SLTP_UNSETTABLE;
                     else
                        if(items[idx].closeRequested && items[idx].structState==LLB_ST_INVALIDATED)
                           cr=LLB_CR_INVALIDATION;
                        else
                           cr=LLB_CR_EA_OTHER;
                    }
      items[idx].closeReason=cr;
      items[idx].closeNote=StringFormat("deal_reason=%I64d comment=%s",lastReason,lastComment);
      return true;
     }

public:
   LLBManagedPosition items[];

                     CLLBPositionManager(void)
     {
      m_per=NULL;
      m_exec=NULL;
      m_magic=0;
      m_netting=false;
     }

   void              Init(CLLBPersistence *per,CLLBExecutionManager *exec,const ulong magic,const bool netting)
     {
      m_per=per;
      m_exec=exec;
      m_magic=magic;
      m_netting=netting;
     }

   int               Count(void) { return ArraySize(items); }

   int               FindById(const long id)
     {
      for(int i=ArraySize(items)-1; i>=0; i--)
         if(items[i].positionId==id)
            return i;
      return -1;
     }

   void              CollectIds(long &ids[])
     {
      ArrayResize(ids,ArraySize(items));
      for(int i=0; i<ArraySize(items); i++)
         ids[i]=items[i].positionId;
     }

   int               OpenCount(const string sym)
     {
      int c=0;
      for(int i=0; i<ArraySize(items); i++)
         if(items[i].symbol==sym && items[i].state!=LLB_POS_CLOSED)
            c++;
      return c;
     }

   bool              Load(const datetime now,int &corrupt,string &err)
     {
      corrupt=0;
      err="";
      ArrayResize(items,0);
      string lines[];
      if(!m_per.ReadAll(LLB_FILE_POSITIONS,lines))
         return true;
      long seen[];
      string keep[];
      int ns=0;
      for(int i=ArraySize(lines)-1; i>=0; i--)
        {
         string l=lines[i];
         if(StringLen(l)==0 || StringGetCharacter(l,0)=='#')
            continue;
         LLBManagedPosition m;
         if(!LLB_PosFromCsv(l,m))
           {
            corrupt++;
            continue;
           }
         bool dup=false;
         for(int k=0; k<ns; k++)
            if(seen[k]==m.positionId)
              {
               dup=true;
               break;
              }
         if(dup)
            continue;
         ArrayResize(seen,ns+1,256);
         seen[ns]=m.positionId;
         ns++;
         int kn=ArraySize(keep);
         ArrayResize(keep,kn+1,256);
         keep[kn]=l;
         bool inMemory=(m.state!=LLB_POS_CLOSED || (long)now-(long)m.closeTime<=(long)LLB_KEEP_DAYS*86400);
         if(inMemory)
           {
            int n=ArraySize(items);
            ArrayResize(items,n+1,32);
            items[n]=m;
           }
        }
      int cnt=ArraySize(items);
      for(int a=0; a<cnt/2; a++)
        {
         int b=cnt-1-a;
         LLBManagedPosition tmp=items[a];
         items[a]=items[b];
         items[b]=tmp;
        }
      if(m_per.SizeOf(LLB_FILE_POSITIONS)>LLB_JOURNAL_MAX_BYTES)
        {
         string chrono[];
         int kn=ArraySize(keep);
         ArrayResize(chrono,kn);
         for(int i=0; i<kn; i++)
            chrono[i]=keep[kn-1-i];
         m_per.ArchiveAndRewrite(LLB_FILE_POSITIONS,LLB_PosCsvHeader(),chrono);
        }
      return true;
     }

   //--- start managing the position produced by an execution (fill event)
   int               Track(const LLBExecutionRecord &e,const long positionId,const double volStep,string &msg)
     {
      msg="";
      if(positionId<=0)
         return -1;
      int idx=FindById(positionId);
      bool isNew=(idx<0);
      if(isNew)
        {
         LLBManagedPosition m;
         m.Reset();
         m.positionId=positionId;
         m.execId=e.execId;
         m.signalId=e.signalId;
         m.symbol=e.symbol;
         m.direction=e.direction;
         m.expectedSl=e.sl;
         m.expectedTp=e.tp;
         m.refSwingPrice=e.refSwingPrice;
         m.monitorFromMsc=e.monitorFromMsc;
         m.structState=e.structState;
         m.checkedMsc=e.checkedMsc;
         idx=ArraySize(items);
         ArrayResize(items,idx+1,32);
         items[idx]=m;
        }
      ulong ticket=0;
      if(LLB_SelectPositionById(positionId,ticket))
        {
         items[idx].volume=PositionGetDouble(POSITION_VOLUME);
         items[idx].openPrice=PositionGetDouble(POSITION_PRICE_OPEN);
         items[idx].sl=PositionGetDouble(POSITION_SL);
         items[idx].tp=PositionGetDouble(POSITION_TP);
         items[idx].openTime=(datetime)PositionGetInteger(POSITION_TIME);
         items[idx].state=LLB_POS_OPEN;
         double ourVol=(e.fillVolume>0.0) ? e.fillVolume : e.volume;
         if(m_netting && MathAbs(items[idx].volume-ourVol)>volStep*0.5)
            items[idx].ownership=LLB_OWN_CONFLICT;
         msg=StringFormat("FILLED %s position #%I64d %s %s lots @ %s SL %s TP %s",e.signalId,positionId,LLB_DirName(e.direction),
                          DoubleToString(items[idx].volume,2),DoubleToString(items[idx].openPrice,6),
                          DoubleToString(items[idx].sl,6),DoubleToString(items[idx].tp,6));
        }
      else
        {
         //--- already closed before we saw it (EA offline / fast SL)
         items[idx].volume=(e.fillVolume>0.0) ? e.fillVolume : e.volume;
         items[idx].openPrice=e.fillPrice;
         if(ReadClosedFromHistory(idx))
           {
            items[idx].state=LLB_POS_CLOSED;
            msg=StringFormat("FILLED AND ALREADY CLOSED %s position #%I64d reason %s profit %s",e.signalId,positionId,
                             LLB_CloseReasonName(items[idx].closeReason),DoubleToString(items[idx].profit,2));
           }
         else
            msg=StringFormat("position #%I64d of %s not visible yet - will reconcile",positionId,e.signalId);
        }
      Journal(idx);
      return idx;
     }

   //--- refresh open positions from the terminal; returns events for notifications
   void              Reconcile(const datetime now,const string &symbols[],const double &volSteps[],const double &tickSizes[],LLBExecEvent &events[])
     {
      for(int i=0; i<ArraySize(items); i++)
        {
         if(items[i].state==LLB_POS_CLOSED)
            continue;
         double volStep=0.01;
         double tick=0.0;
         for(int s=0; s<ArraySize(symbols); s++)
            if(symbols[s]==items[i].symbol)
              {
               volStep=volSteps[s];
               tick=tickSizes[s];
              }
         ulong ticket=0;
         if(LLB_SelectPositionById(items[i].positionId,ticket))
           {
            double vol=PositionGetDouble(POSITION_VOLUME);
            double sl=PositionGetDouble(POSITION_SL);
            double tp=PositionGetDouble(POSITION_TP);
            items[i].floating=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
            bool changed=(MathAbs(vol-items[i].volume)>1e-9 || MathAbs(sl-items[i].sl)>1e-9 || MathAbs(tp-items[i].tp)>1e-9);
            items[i].volume=vol;
            items[i].sl=sl;
            items[i].tp=tp;
            double tolTick=(tick>0.0) ? tick : 1e-6;
            //--- protected = SL attached and not wider than approved (a tighter manual SL is respected) + TP attached
            bool verified=(LLB_SlWithinApproved(items[i].direction,sl,items[i].expectedSl,tolTick) && tp>0.0);
            if(verified!=items[i].sltpVerified)
              {
               items[i].sltpVerified=verified;
               changed=true;
              }
            if(m_netting && items[i].ownership==LLB_OWN_OK)
              {
               int e=m_exec.Find(items[i].execId);
               double ourVol=(e>=0 && m_exec.items[e].fillVolume>0.0) ? m_exec.items[e].fillVolume : items[i].volume;
               if(MathAbs(vol-ourVol)>volStep*0.5)
                 {
                  items[i].ownership=LLB_OWN_CONFLICT;
                  changed=true;
                 }
              }
            if(items[i].ownership==LLB_OWN_CONFLICT && !items[i].conflictNotified)
              {
               items[i].conflictNotified=true;
               LLB_AddEvent(events,LLB_EV_POS_INFO,i,items[i].positionId,
                            "OWNERSHIP CONFLICT on netting position #"+(string)items[i].positionId+" (volume changed outside the EA) - EA will NOT close or modify it");
              }
            if(items[i].state==LLB_POS_CLOSING && items[i].lastCloseMs>0 && LLB_NowMs()-items[i].lastCloseMs>10000)
              {
               items[i].state=LLB_POS_OPEN;                 // close not confirmed: allow a verified retry
               changed=true;
              }
            if(changed)
               Journal(i);
            continue;
           }
         //--- not open anymore: closed?
         if(ReadClosedFromHistory(i))
           {
            items[i].state=LLB_POS_CLOSED;
            items[i].floating=0.0;
            Journal(i);
            LLB_AddEvent(events,LLB_EV_POS_CLOSED,i,items[i].positionId,
                         StringFormat("POSITION CLOSED #%I64d %s reason %s | profit %s commission %s swap %s fee %s",items[i].positionId,
                                      items[i].signalId,LLB_CloseReasonName(items[i].closeReason),DoubleToString(items[i].profit,2),
                                      DoubleToString(items[i].commission,2),DoubleToString(items[i].swap,2),DoubleToString(items[i].fee,2)));
           }
        }
     }

   //--- structure touched after the fill (SRS 4.5): request close via ExecutionManager
   void              MarkStructureInvalid(const int i,const string why)
     {
      if(items[i].structState==LLB_ST_INVALIDATED)
         return;
      items[i].structState=LLB_ST_INVALIDATED;
      items[i].closeNote=why;
      Journal(i);
      g_llbLog.Warn("POS","STRUCTURE_INVALIDATED #"+(string)items[i].positionId+" "+items[i].signalId+" "+why);
     }

   //--- per-cycle actions: SL/TP verification and invalidation closes (throttled)
   void              ProcessActions(const int i,const LLBSymbolSpec &spec,LLBExecEvent &events[])
     {
      if(i<0 || i>=ArraySize(items))
         return;
      if(items[i].state!=LLB_POS_OPEN || items[i].ownership==LLB_OWN_CONFLICT)
         return;
      long nowMs=LLB_NowMs();
      //--- 1. invalidated structure -> close (broker SL stays as the independent protection)
      if(items[i].structState==LLB_ST_INVALIDATED)
        {
         if(items[i].closeAttempts>=LLB_MAX_CLOSE_ATTEMPTS)
           {
            if(!items[i].exhaustedNotified)
              {
               items[i].exhaustedNotified=true;
               LLB_AddEvent(events,LLB_EV_POS_INFO,i,items[i].positionId,"CLOSE ATTEMPTS EXHAUSTED for #"+(string)items[i].positionId
                            +" - broker SL/TP still protect the position; close it manually if needed");
              }
            return;
           }
         if(items[i].lastCloseMs>0 && nowMs-items[i].lastCloseMs<LLB_CLOSE_RETRY_MS)
            return;
         uint rc=0;
         string msg;
         items[i].lastCloseMs=nowMs;
         items[i].closeAttempts++;
         items[i].closeRequested=true;
         bool ok=m_exec.ClosePosition(items[i],spec,"STRUCTURE_INVALIDATION",rc,msg);
         if(ok)
           {
            items[i].state=LLB_POS_CLOSING;
            Journal(i);
            LLB_AddEvent(events,LLB_EV_POS_INFO,i,items[i].positionId,"STRUCTURE INVALIDATED - closing position: "+msg);
           }
         else
           {
            if(msg=="POSITION_NOT_FOUND")
               return;                                      // already closed: Reconcile() records it
            g_llbLog.Warn("POS","close attempt "+(string)items[i].closeAttempts+" failed: "+msg);
            if(rc==TRADE_RETCODE_MARKET_CLOSED || rc==TRADE_RETCODE_CONNECTION || rc==TRADE_RETCODE_TRADE_DISABLED)
               items[i].closeAttempts--;                    // waiting for the market does not consume an attempt
            if(items[i].closeAttempts==1)
               LLB_AddEvent(events,LLB_EV_POS_INFO,i,items[i].positionId,"STRUCTURE INVALIDATED - close failed ("+msg+"), retrying; broker SL remains active");
           }
         return;
        }
      //--- 2. broker SL/TP must equal the expected values (R-EXE-10)
      if(!items[i].sltpVerified && items[i].expectedSl>0.0 && items[i].expectedTp>0.0)
        {
         if(items[i].sltpAttempts>=LLB_MAX_SLTP_ATTEMPTS)
            return;
         if(items[i].lastSltpMs>0 && nowMs-items[i].lastSltpMs<LLB_SLTP_RETRY_MS)
            return;
         items[i].lastSltpMs=nowMs;
         items[i].sltpAttempts++;
         uint rc=0;
         string msg;
         bool beyond=false;
         bool ok=m_exec.ModifyPositionStops(items[i],spec,rc,msg,beyond);
         if(ok)
           {
            if(msg=="SLTP_ALREADY_ACCEPTABLE")
               items[i].sltpVerified=true;
            else
               LLB_AddEvent(events,LLB_EV_POS_INFO,i,items[i].positionId,"SL/TP missing or wider than approved - set: "+msg);
            return;
           }
         if(beyond)
           {
            //--- price already beyond the expected SL: no protective SL can be placed -> close (risk-reducing)
            items[i].closeReason=LLB_CR_SLTP_UNSETTABLE;
            items[i].closeRequested=true;
            items[i].lastCloseMs=nowMs;
            items[i].closeAttempts++;
            uint rc2=0;
            string msg2;
            if(m_exec.ClosePosition(items[i],spec,"SLTP_UNSETTABLE",rc2,msg2))
               items[i].state=LLB_POS_CLOSING;
            Journal(i);
            LLB_AddEvent(events,LLB_EV_POS_INFO,i,items[i].positionId,"SL could not be set (price beyond SL) - closing: "+msg2);
            return;
           }
         if(items[i].sltpAttempts==LLB_MAX_SLTP_ATTEMPTS)
            LLB_AddEvent(events,LLB_EV_POS_INFO,i,items[i].positionId,"WARNING SL/TP mismatch on #"+(string)items[i].positionId+" could not be fixed: "+msg);
        }
     }

   void              Prune(const datetime now)
     {
      int w=0;
      int n=ArraySize(items);
      for(int i=0; i<n; i++)
        {
         bool drop=(items[i].state==LLB_POS_CLOSED && (long)now-(long)items[i].closeTime>(long)LLB_KEEP_DAYS*86400);
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
