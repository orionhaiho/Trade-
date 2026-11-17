//+------------------------------------------------------------------+
//| LLB_Proposals.mqh                                                |
//| ProposalManager: creation, Signal ID, de-duplication, expiry,    |
//| state machine (every transition validated + journaled at once).  |
//| Other modules READ items[] but must change state only through    |
//| Transition()/ForceState()/Set*() so that nothing bypasses the    |
//| table in LLB_CanTransition() or the journal.                     |
//+------------------------------------------------------------------+
#ifndef LLB_PROPOSALS_MQH
#define LLB_PROPOSALS_MQH

#include "LLB_Defines.mqh"
#include "LLB_Utils.mqh"
#include "LLB_Logger.mqh"
#include "LLB_Persistence.mqh"

class CLLBProposalManager
  {
private:
   CLLBPersistence  *m_per;
   int               m_seqDate;
   int               m_seq;
   string            m_changed[];

   bool              Journal(const int idx)
     {
      if(m_per==NULL)
         return false;
      bool ok=m_per.AppendLine(LLB_FILE_SIGNALS,LLB_SignalCsvHeader(),LLB_SignalToCsv(items[idx],TimeTradeServer()));
      if(!ok)
         g_llbLog.Error("PRP","JOURNAL_WRITE_FAILED "+items[idx].signalId);
      return ok;
     }

   void              MarkChanged(const int idx)
     {
      string id=items[idx].signalId;
      for(int i=0; i<ArraySize(m_changed); i++)
         if(m_changed[i]==id)
            return;
      int n=ArraySize(m_changed);
      ArrayResize(m_changed,n+1);
      m_changed[n]=id;
     }

   int               MaxSeqForDate(const int date8)
     {
      int mx=0;
      for(int i=0; i<ArraySize(items); i++)
        {
         string sym;
         int st,dir,d8,seq;
         if(LLB_ParseSignalId(items[i].signalId,sym,st,dir,d8,seq) && d8==date8 && seq>mx)
            mx=seq;
        }
      return mx;
     }

public:
   LLBTradeProposal  items[];

                     CLLBProposalManager(void)
     {
      m_per=NULL;
      m_seqDate=0;
      m_seq=0;
     }

   void              Init(CLLBPersistence *per) { m_per=per; }
   int               Count(void) { return ArraySize(items); }

   int               Find(const string id)
     {
      for(int i=ArraySize(items)-1; i>=0; i--)
         if(items[i].signalId==id)
            return i;
      return -1;
     }

   int               FindByExecId(const string execId)
     {
      if(execId=="")
         return -1;
      for(int i=ArraySize(items)-1; i>=0; i--)
         if(items[i].execId==execId)
            return i;
      return -1;
     }

   //--- loads the latest valid snapshot of every signal from signals.csv
   bool              Load(const datetime now,int &corrupt,string &err)
     {
      corrupt=0;
      err="";
      ArrayResize(items,0);
      string lines[];
      if(!m_per.ReadAll(LLB_FILE_SIGNALS,lines))
         return true;                                   // no journal yet
      string seen[];
      string keep[];
      int ns=0;
      for(int i=ArraySize(lines)-1; i>=0; i--)
        {
         string l=lines[i];
         if(StringLen(l)==0 || StringGetCharacter(l,0)=='#')
            continue;
         LLBTradeProposal p;
         if(!LLB_SignalFromCsv(l,p))
           {
            corrupt++;
            continue;
           }
         bool dup=false;
         for(int k=0; k<ns; k++)
            if(seen[k]==p.signalId)
              {
               dup=true;
               break;
              }
         if(dup)
            continue;
         ArrayResize(seen,ns+1,256);
         seen[ns]=p.signalId;
         ns++;
         int kn=ArraySize(keep);
         ArrayResize(keep,kn+1,256);
         keep[kn]=l;
         string sym;
         int st,dir,d8,seq;
         if(LLB_ParseSignalId(p.signalId,sym,st,dir,d8,seq))
            EnsureSequenceAtLeast(d8,seq);
         bool inMemory=(!LLB_IsTerminalProposal(p.state) || (long)now-(long)p.createdTime<=(long)LLB_KEEP_DAYS*86400);
         if(inMemory)
           {
            int n=ArraySize(items);
            ArrayResize(items,n+1,64);
            items[n]=p;
           }
        }
      //--- items were collected newest-first; restore chronological order
      int cnt=ArraySize(items);
      for(int a=0; a<cnt/2; a++)
        {
         int b=cnt-1-a;
         LLBTradeProposal tmp=items[a];
         items[a]=items[b];
         items[b]=tmp;
        }
      if(m_per.SizeOf(LLB_FILE_SIGNALS)>LLB_JOURNAL_MAX_BYTES)
        {
         string chrono[];
         int kn=ArraySize(keep);
         ArrayResize(chrono,kn);
         for(int i=0; i<kn; i++)
            chrono[i]=keep[kn-1-i];
         m_per.ArchiveAndRewrite(LLB_FILE_SIGNALS,LLB_SignalCsvHeader(),chrono);
        }
      return true;
     }

   //--- daily sequence used in Signal ID / Execution ID ----------------
   void              SetSequence(const int date8,const int seq) { m_seqDate=date8; m_seq=seq; }
   int               SeqDate(void) { return m_seqDate; }
   int               SeqValue(void) { return m_seq; }

   void              EnsureSequenceAtLeast(const int date8,const int seq)
     {
      if(date8>m_seqDate)
        {
         m_seqDate=date8;
         m_seq=seq;
        }
      else
         if(date8==m_seqDate && seq>m_seq)
            m_seq=seq;
     }

   int               NextSequence(const datetime now)
     {
      int d=LLB_Date8(now);
      if(d!=m_seqDate)
        {
         m_seqDate=d;
         m_seq=MaxSeqForDate(d);
        }
      m_seq++;
      return m_seq;
     }

   //--- "same opportunity" (A-14, A-20)
   bool              IsDuplicate(const LLBSignalCandidate &c,string &why)
     {
      for(int i=0; i<ArraySize(items); i++)
        {
         if(items[i].symbol!=c.symbol || items[i].strategy!=c.strategy || items[i].direction!=c.direction)
            continue;
         if(items[i].signalBarTime==c.signalBarTime)
           {
            why="DUPLICATE_SAME_SIGNAL_BAR "+items[i].signalId;
            return true;
           }
         if(items[i].level==c.level &&
            (items[i].state==LLB_PS_ACTIVE || items[i].state==LLB_PS_ACCEPTED || items[i].state==LLB_PS_EXECUTING))
           {
            why="PREVIOUS_PROPOSAL_STILL_VALID "+items[i].signalId;
            return true;
           }
        }
      return false;
     }

   int               Create(const LLBSignalCandidate &c,const double sl,const double tp,const double rr,const MqlTick &tk,
                            const double point,const int digits,const datetime now,string &why)
     {
      why="";
      if(!c.valid)
        {
         why="CANDIDATE_INVALID";
         return -1;
        }
      if(IsDuplicate(c,why))
         return -1;
      int seq=NextSequence(now);
      LLBTradeProposal p;
      p.Reset();
      p.signalId=LLB_MakeSignalId(c.symbol,c.strategy,c.direction,LLB_Date8(now),seq);
      p.symbol=c.symbol;
      p.strategy=c.strategy;
      p.direction=c.direction;
      p.level=c.level;
      p.levelPrice=c.levelPrice;
      p.entry=c.entry;
      p.sl=sl;
      p.tp=tp;
      p.rr=rr;
      p.atr=c.atr;
      p.bid=tk.bid;
      p.ask=tk.ask;
      p.spreadPoints=(point>0.0) ? (int)MathRound((tk.ask-tk.bid)/point) : 0;
      p.digits=digits;
      p.createdTime=now;
      p.expiresTime=now+((c.strategy==LLB_STRAT_SWEEP) ? LLB_SWEEP_EXPIRY_SEC : LLB_BREAKOUT_EXPIRY_SEC);
      p.signalBarTime=c.signalBarTime;
      p.refSwingPrice=c.refSwingPrice;
      p.refSwingTime=c.refSwingTime;
      p.monitorFromMsc=((long)c.signalBarTime+LLB_M15_SECONDS)*1000;
      p.state=LLB_PS_ACTIVE;
      p.stateReason="CREATED";
      p.execId=LLB_ExecIdFromSignalId(p.signalId);
      p.reason=c.reason;
      if(p.execId=="")
        {
         why="SIGNAL_ID_FORMAT_ERROR "+p.signalId;
         return -1;
        }
      int n=ArraySize(items);
      ArrayResize(items,n+1,64);
      items[n]=p;
      Journal(n);
      return n;
     }

   //--- the ONLY normal way to change a proposal state
   bool              Transition(const int idx,const int to,const string reason)
     {
      if(idx<0 || idx>=ArraySize(items))
         return false;
      int from=items[idx].state;
      if(from==to)
         return true;
      if(!LLB_CanTransition(from,to))
        {
         g_llbLog.Error("PRP","ILLEGAL_TRANSITION "+items[idx].signalId+" "+LLB_ProposalStateName(from)+" -> "
                        +LLB_ProposalStateName(to)+" ("+reason+")");
         return false;
        }
      items[idx].state=to;
      items[idx].stateReason=reason;
      Journal(idx);
      MarkChanged(idx);
      g_llbLog.Info("PRP",items[idx].signalId+" "+LLB_ProposalStateName(from)+" -> "+LLB_ProposalStateName(to)+" | "+reason);
      return true;
     }

   //--- reconciliation repair: broker reality wins (logged as warning)
   bool              ForceState(const int idx,const int to,const string reason)
     {
      if(idx<0 || idx>=ArraySize(items))
         return false;
      int from=items[idx].state;
      if(from==to)
         return true;
      items[idx].state=to;
      items[idx].stateReason=reason;
      Journal(idx);
      MarkChanged(idx);
      g_llbLog.Warn("PRP","STATE_REPAIRED "+items[idx].signalId+" "+LLB_ProposalStateName(from)+" -> "+LLB_ProposalStateName(to)+" | "+reason);
      return true;
     }

   bool              SetDecision(const int idx,const int decision,const long user,const datetime when)
     {
      if(idx<0 || idx>=ArraySize(items))
         return false;
      items[idx].decision=decision;
      items[idx].decisionUser=user;
      items[idx].decisionTime=when;
      return true;                                      // journaled by the following Transition()
     }

   bool              SetMessageId(const int idx,const long msgId)
     {
      if(idx<0 || idx>=ArraySize(items))
         return false;
      items[idx].tgMessageId=msgId;
      Journal(idx);
      return true;
     }

   void              SetChecked(const int idx,const long msc)
     {
      if(idx>=0 && idx<ArraySize(items))
         items[idx].checkedMsc=msc;
     }

   //--- ACTIVE proposals past their expiration time -> EXPIRED
   int               ProcessExpiry(const datetime now)
     {
      int cnt=0;
      for(int i=0; i<ArraySize(items); i++)
         if(items[i].state==LLB_PS_ACTIVE && now>=items[i].expiresTime)
           {
            if(Transition(i,LLB_PS_EXPIRED,"EXPIRED at "+LLB_TimeStr(items[i].expiresTime)))
               cnt++;
           }
      return cnt;
     }

   int               TakeChanged(string &out[])
     {
      int n=ArraySize(m_changed);
      ArrayResize(out,n);
      for(int i=0; i<n; i++)
         out[i]=m_changed[i];
      ArrayResize(m_changed,0);
      return n;
     }

   //--- dashboard: newest open proposal of a symbol, else the newest one
   int               LatestForSymbol(const string sym)
     {
      int newest=-1;
      for(int i=ArraySize(items)-1; i>=0; i--)
        {
         if(items[i].symbol!=sym)
            continue;
         if(!LLB_IsTerminalProposal(items[i].state))
            return i;
         if(newest<0)
            newest=i;
        }
      return newest;
     }

   //--- forget old terminal proposals (they stay in the journal)
   void              Prune(const datetime now)
     {
      int w=0;
      int n=ArraySize(items);
      for(int i=0; i<n; i++)
        {
         bool drop=(LLB_IsTerminalProposal(items[i].state) && (long)now-(long)items[i].createdTime>(long)LLB_KEEP_DAYS*86400);
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
