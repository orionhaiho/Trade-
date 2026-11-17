//+------------------------------------------------------------------+
//| LLB_Approval.mqh                                                 |
//| ApprovalManager (R-TGM-05..08, R-SEC-03/04, invariants 1-4).     |
//| Order of checks for a callback:                                  |
//|  1 chat + user allow-list   2 data format   3 Signal ID exists   |
//|  4 button belongs to the proposal message                        |
//|  REJECT: ACTIVE -> REJECTED, otherwise idempotent no-op          |
//|  ACCEPT: ACTIVE? EA ready? not expired? structure not touched    |
//|          (fresh tick scan)? Precheck (price/volume/margin/...)?  |
//|          -> ACCEPTED -> ExecutionManager.Execute                 |
//| A refused ACCEPT never changes state (except EXPIRED /           |
//| INVALIDATED which are facts); the user may retry until expiry.   |
//+------------------------------------------------------------------+
#ifndef LLB_APPROVAL_MQH
#define LLB_APPROVAL_MQH

#include "LLB_Defines.mqh"
#include "LLB_Utils.mqh"
#include "LLB_Logger.mqh"
#include "LLB_Proposals.mqh"
#include "LLB_Execution.mqh"
#include "LLB_Telegram.mqh"

//--- services implemented by the Coordinator (avoids circular includes)
class CLLBApprovalServices
  {
public:
   virtual bool      ServicesReady(string &why)=0;
   virtual bool      FreshTouchCheck(const int pidx,string &why)=0;   // true = structure intact up to now
   virtual bool      SpecFor(const string sym,LLBSymbolSpec &spec)=0;
   virtual void      OurPositionIds(long &ids[])=0;
   virtual void      Notify(const string text)=0;
  };

class CLLBApprovalManager
  {
private:
   CLLBProposalManager  *m_pm;
   CLLBExecutionManager *m_em;
   CLLBTelegramGateway  *m_tg;
   CLLBApprovalServices *m_svc;

public:
                     CLLBApprovalManager(void)
     {
      m_pm=NULL;
      m_em=NULL;
      m_tg=NULL;
      m_svc=NULL;
     }

   void              Init(CLLBProposalManager *pm,CLLBExecutionManager *em,CLLBTelegramGateway *tg,CLLBApprovalServices *svc)
     {
      m_pm=pm;
      m_em=em;
      m_tg=tg;
      m_svc=svc;
     }

   //--- Telegram callback entry point
   void              HandleCallback(const LLBTelegramCallback &cb,const datetime now)
     {
      if(!m_tg.IsAuthorized(cb.chatId,cb.fromId))
        {
         g_llbLog.Warn("APR",StringFormat("UNAUTHORIZED_CALLBACK chat=%I64d from=%I64d data=%s - ignored, no state change",
                                          cb.chatId,cb.fromId,LLB_Truncate(cb.data,64)));
         m_tg.QueueAnswer(cb.queryId,"Not authorized.",true);
         return;
        }
      int decision=LLB_DEC_NONE;
      string id;
      if(!LLB_ParseCallbackData(cb.data,decision,id))
        {
         g_llbLog.Warn("APR","MALFORMED_CALLBACK data="+LLB_Truncate(cb.data,64));
         m_tg.QueueAnswer(cb.queryId,"Invalid request.",true);
         return;
        }
      int pidx=m_pm.Find(id);
      if(pidx<0)
        {
         g_llbLog.Warn("APR","UNKNOWN_SIGNAL_ID "+id+" - not managed by this EA instance (same bot token used elsewhere?)");
         m_tg.QueueAnswer(cb.queryId,"Unknown Signal ID: "+id,true);
         return;
        }
      if(m_pm.items[pidx].tgMessageId>0 && cb.messageId!=m_pm.items[pidx].tgMessageId)
        {
         g_llbLog.Warn("APR",StringFormat("CALLBACK_MESSAGE_MISMATCH %s message=%I64d expected=%I64d",id,cb.messageId,m_pm.items[pidx].tgMessageId));
         m_tg.QueueAnswer(cb.queryId,"This button does not belong to the proposal message.",true);
         return;
        }
      g_llbLog.Info("APR",StringFormat("CALLBACK %s %s from user %I64d",LLB_DecisionName(decision),id,cb.fromId));
      bool alert=false;
      string answer=ProcessDecision(pidx,decision,cb.fromId,now,alert);
      m_tg.QueueAnswer(cb.queryId,answer,alert);
     }

   //--- shared by Telegram and the Strategy-Tester auto-approval (tester only)
   string            ProcessDecision(const int pidx,const int decision,const long user,const datetime now,bool &alert)
     {
      alert=true;
      if(pidx<0 || pidx>=m_pm.Count())
         return "Unknown proposal.";
      string id=m_pm.items[pidx].signalId;
      int state=m_pm.items[pidx].state;
      //--- REJECT -----------------------------------------------------
      if(decision==LLB_DEC_REJECT)
        {
         if(state!=LLB_PS_ACTIVE)
           {
            g_llbLog.Info("APR","REJECT ignored for "+id+": already "+LLB_ProposalStateName(state));
            return "Already "+LLB_ProposalStateName(state)+" - nothing changed.";
           }
         m_pm.SetDecision(pidx,LLB_DEC_REJECT,user,now);
         m_pm.Transition(pidx,LLB_PS_REJECTED,"REJECTED by user "+IntegerToString(user));
         alert=false;
         return "REJECTED - no order will be sent.";
        }
      if(decision!=LLB_DEC_ACCEPT)
         return "Invalid decision.";
      //--- ACCEPT -----------------------------------------------------
      if(state!=LLB_PS_ACTIVE)
        {
         g_llbLog.Info("APR","ACCEPT ignored for "+id+": already "+LLB_ProposalStateName(state));
         return "Already "+LLB_ProposalStateName(state)+" - nothing changed.";
        }
      string why;
      if(!m_svc.ServicesReady(why))
        {
         g_llbLog.Warn("APR","ACCEPT refused "+id+": "+why);
         return "Refused: EA not ready ("+why+"). Proposal stays ACTIVE - try again.";
        }
      if(now>=m_pm.items[pidx].expiresTime)
        {
         m_pm.Transition(pidx,LLB_PS_EXPIRED,"EXPIRED (checked at ACCEPT)");
         return "Refused: proposal EXPIRED at "+LLB_TimeStr(m_pm.items[pidx].expiresTime)+" (server).";
        }
      if(!m_svc.FreshTouchCheck(pidx,why))
        {
         g_llbLog.Warn("APR","ACCEPT refused "+id+": "+why);
         return "Refused: "+why;
        }
      if(m_pm.items[pidx].state!=LLB_PS_ACTIVE)
         return "Refused: proposal is "+LLB_ProposalStateName(m_pm.items[pidx].state)+".";
      LLBSymbolSpec spec;
      if(!m_svc.SpecFor(m_pm.items[pidx].symbol,spec))
         return "Refused: symbol "+m_pm.items[pidx].symbol+" unavailable.";
      long ids[];
      m_svc.OurPositionIds(ids);
      double vol=0.0;
      if(!m_em.Precheck(m_pm.items[pidx],spec,now,ids,vol,why))
        {
         g_llbLog.Warn("APR","ACCEPT refused "+id+": "+why);
         return "Refused (proposal stays ACTIVE until expiry): "+why;
        }
      m_pm.SetDecision(pidx,LLB_DEC_ACCEPT,user,now);
      if(!m_pm.Transition(pidx,LLB_PS_ACCEPTED,"ACCEPTED by user "+IntegerToString(user)))
         return "Refused: state transition failed.";
      string msg;
      bool placed=m_em.Execute(m_pm,pidx,spec,now,ids,msg);
      m_svc.Notify((placed ? LLB_IconOk() : LLB_IconWarn())+" "+msg);
      alert=!placed;
      return placed ? "ACCEPTED - pending order placed." : "ACCEPTED - "+LLB_Truncate(msg,150);
     }
  };

#endif
//+------------------------------------------------------------------+
