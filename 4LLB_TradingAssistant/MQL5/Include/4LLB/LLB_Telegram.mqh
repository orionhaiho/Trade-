//+------------------------------------------------------------------+
//| LLB_Telegram.mqh                                                 |
//| TelegramGateway (R-TGM-01..04, R-SEC-01/02/05/06).               |
//| - token from InpTgBotToken or MQL5\Files\4LLB\telegram_token.txt |
//|   (never hard-coded, registered as a secret in the logger, the   |
//|   request URL that contains it is never logged)                  |
//| - outbox with priorities (callback answers first), short polling |
//|   getUpdates with a persisted offset, exponential backoff        |
//| - WebRequest is synchronous: timeouts are short and failures     |
//|   back off, so the analysis engine keeps running (A-16)          |
//| WebRequest requires https://api.telegram.org in Tools > Options >|
//| Expert Advisors > "Allow WebRequest for listed URL".             |
//+------------------------------------------------------------------+
#ifndef LLB_TELEGRAM_MQH
#define LLB_TELEGRAM_MQH

#include "LLB_Defines.mqh"
#include "LLB_Utils.mqh"
#include "LLB_Logger.mqh"
#include "LLB_Json.mqh"

#define LLB_TGK_ANSWER    0
#define LLB_TGK_PROPOSAL  1
#define LLB_TGK_TEXT      2
#define LLB_TGK_EDIT      3
#define LLB_TG_MAX_TEXT   3900
#define LLB_TG_MAX_QUEUE  200

struct LLBTgOut
  {
   int               kind;
   string            method;
   string            body;
   string            signalId;
   int               attempts;
   long              notBeforeMs;
  };

//+------------------------------------------------------------------+
//| Pure helpers (unit tested)                                       |
//+------------------------------------------------------------------+
string LLB_SanitizeToken(const string s)
  {
   string out="";
   int n=StringLen(s);
   for(int i=0; i<n; i++)
     {
      ushort c=StringGetCharacter(s,i);
      bool ok=((c>='0' && c<='9') || (c>='a' && c<='z') || (c>='A' && c<='Z') || c==':' || c=='_' || c=='-');
      if(ok)
         out+=ShortToString(c);
     }
   return out;
  }

bool LLB_IsTokenFormat(const string t)
  {
   int p=StringFind(t,":");
   if(p<5 || p>15)
      return false;
   for(int i=0; i<p; i++)
     {
      ushort c=StringGetCharacter(t,i);
      if(c<'0' || c>'9')
         return false;
     }
   int n=StringLen(t);
   if(n-p-1<30)
      return false;
   for(int i=p+1; i<n; i++)
     {
      ushort c=StringGetCharacter(t,i);
      bool ok=((c>='0' && c<='9') || (c>='a' && c<='z') || (c>='A' && c<='Z') || c=='_' || c=='-');
      if(!ok)
         return false;
     }
   return true;
  }

//--- authorisation rule: message chat must be the configured chat AND the presser must be allow-listed
bool LLB_TgAuthorized(const long chatId,const long fromId,const long cfgChatId,const long &allowed[])
  {
   if(cfgChatId==0 || chatId!=cfgChatId)
      return false;
   return LLB_IdInList(fromId,allowed);
  }

//--- parses a getUpdates response. Returns number of callbacks, -1 on error.
//--- maxUpdateId = highest update_id seen (-1 when none).
int LLB_ParseUpdates(const string json,long &maxUpdateId,LLBTelegramCallback &out[],string &err)
  {
   maxUpdateId=-1;
   ArrayResize(out,0);
   CLLBJson root;
   if(!root.Parse(json,err))
      return -1;
   if(!root.GetBoolean("ok",false))
     {
      err="ok=false "+root.GetStr("description","");
      return -1;
     }
   CLLBJson *res=root.Get("result");
   if(res==NULL || res.type!=LLB_JSON_ARRAY)
     {
      err="result missing";
      return -1;
     }
   int n=res.Count();
   for(int i=0; i<n; i++)
     {
      CLLBJson *u=res.At(i);
      if(u==NULL || u.type!=LLB_JSON_OBJECT)
         continue;
      long uid=u.GetLong("update_id",-1);
      if(uid>maxUpdateId)
         maxUpdateId=uid;
      CLLBJson *cq=u.Get("callback_query");
      if(cq==NULL || cq.type!=LLB_JSON_OBJECT)
         continue;
      LLBTelegramCallback cb;
      cb.Reset();
      cb.updateId=uid;
      cb.queryId=cq.GetStr("id","");
      cb.data=cq.GetStr("data","");
      CLLBJson *from=cq.Get("from");
      if(from!=NULL)
         cb.fromId=from.GetLong("id",0);
      CLLBJson *msg=cq.Get("message");
      if(msg!=NULL)
        {
         cb.messageId=msg.GetLong("message_id",0);
         CLLBJson *chat=msg.Get("chat");
         if(chat!=NULL)
            cb.chatId=chat.GetLong("id",0);
        }
      int k=ArraySize(out);
      ArrayResize(out,k+1);
      out[k]=cb;
     }
   return ArraySize(out);
  }

//+------------------------------------------------------------------+
class CLLBTelegramGateway
  {
private:
   bool              m_enabled;
   string            m_token;
   long              m_chatId;
   long              m_allowed[];
   int               m_status;
   string            m_statusText;
   long              m_offset;
   bool              m_offsetDirty;
   int               m_pollMs;
   int               m_timeoutMs;
   long              m_nextPollMs;
   long              m_backoffUntilMs;
   int               m_backoffSec;
   bool              m_meOk;
   long              m_nextMeMs;
   string            m_botName;
   LLBTgOut          m_out[];
   LLBTelegramCallback m_in[];
   string            m_sentIds[];
   long              m_sentMsgIds[];

   long              NowMs(void) { return (long)GetTickCount64(); }

   bool              LoadToken(const string tokenInput,string &err)
     {
      string t=LLB_Trim(tokenInput);
      if(t=="")
        {
         if(!FileIsExist(LLB_TOKEN_FILE))
           {
            err="Telegram bot token not configured: create MQL5\\Files\\"+LLB_TOKEN_FILE+" (recommended) or set InpTgBotToken";
            return false;
           }
         int h=FileOpen(LLB_TOKEN_FILE,FILE_READ|FILE_TXT|FILE_ANSI|FILE_SHARE_READ);
         if(h==INVALID_HANDLE)
           {
            err="cannot open token file err="+(string)GetLastError();
            return false;
           }
         while(!FileIsEnding(h))
           {
            string l=LLB_SanitizeToken(FileReadString(h));
            if(l!="")
              {
               t=l;
               break;
              }
           }
         FileClose(h);
        }
      else
         t=LLB_SanitizeToken(t);
      if(!LLB_IsTokenFormat(t))
        {
         err="Telegram bot token format invalid (expected <digits>:<secret> as given by @BotFather)";
         return false;
        }
      m_token=t;
      return true;
     }

   int               Http(const string method,const string body,string &response,int &err)
     {
      //--- the URL contains the token: it is never printed or logged
      string url="https://api.telegram.org/bot"+m_token+"/"+method;
      string headers="Content-Type: application/json\r\n";
      uchar ub[];
      int n=StringToCharArray(body,ub,0,-1,CP_UTF8);
      if(n>0 && ub[n-1]==0)
         n--;
      char data[];
      ArrayResize(data,n);
      for(int i=0; i<n; i++)
         data[i]=(char)ub[i];
      char result[];
      string resHeaders;
      ResetLastError();
      int code=WebRequest("POST",url,headers,m_timeoutMs,data,result,resHeaders);
      err=GetLastError();
      int rn=ArraySize(result);
      uchar ur[];
      ArrayResize(ur,rn);
      for(int i=0; i<rn; i++)
         ur[i]=(uchar)result[i];
      response=(rn>0) ? CharArrayToString(ur,0,rn,CP_UTF8) : "";
      return code;
     }

   string            Description(const string resp,int &retryAfter)
     {
      retryAfter=0;
      CLLBJson root;
      string perr;
      if(!root.Parse(resp,perr))
         return LLB_Truncate(resp,120);
      CLLBJson *par=root.Get("parameters");
      if(par!=NULL)
         retryAfter=(int)par.GetLong("retry_after",0);
      return root.GetStr("description","");
     }

   void              Backoff(const int minSec,const int maxSec)
     {
      m_backoffSec=(m_backoffSec<=0) ? minSec : MathMin(m_backoffSec*2,maxSec);
      if(m_backoffSec<minSec)
         m_backoffSec=minSec;
      m_backoffUntilMs=NowMs()+(long)m_backoffSec*1000;
     }

   void              OnSuccess(void)
     {
      m_backoffSec=0;
      m_backoffUntilMs=0;
      if(m_status!=LLB_TG_OK)
        {
         m_status=LLB_TG_OK;
         m_statusText="OK"+((m_botName!="") ? " @"+m_botName : "");
         g_llbLog.Info("TGW","Telegram connection OK");
        }
     }

   //--- global (connection level) failures; true when handled as such
   bool              OnFailure(const int code,const int err,const string resp,const string method)
     {
      int ra=0;
      string desc=Description(resp,ra);
      if(code==-1)
        {
         if(err==4014)
           {
            m_status=LLB_TG_NOT_ALLOWED;
            m_statusText="WebRequest not allowed: add https://api.telegram.org in Tools > Options > Expert Advisors";
            Backoff(30,60);
           }
         else
           {
            m_status=LLB_TG_DEGRADED;
            m_statusText="network error "+(string)err+" (check internet and the WebRequest allow-list: https://api.telegram.org)";
            Backoff(2,60);
           }
         g_llbLog.Warn("TGW",method+" failed: "+m_statusText);
         return true;
        }
      if(code==401 || code==404)
        {
         m_status=LLB_TG_AUTH_ERROR;
         m_statusText="token rejected by Telegram (HTTP "+(string)code+")";
         m_meOk=false;
         Backoff(300,300);
         g_llbLog.Error("TGW",method+": "+m_statusText);
         return true;
        }
      if(code==409)
        {
         m_status=LLB_TG_CONFLICT;
         m_statusText="conflict: webhook set or another instance polls this bot - "+LLB_Truncate(desc,80);
         Backoff(60,60);
         g_llbLog.Error("TGW",method+": "+m_statusText);
         return true;
        }
      if(code==429)
        {
         m_status=LLB_TG_DEGRADED;
         m_statusText="rate limited";
         m_backoffSec=MathMax(ra,1);
         m_backoffUntilMs=NowMs()+(long)m_backoffSec*1000;
         g_llbLog.Warn("TGW",method+": rate limited, retry after "+(string)m_backoffSec+" s");
         return true;
        }
      if(code>=500)
        {
         m_status=LLB_TG_DEGRADED;
         m_statusText="Telegram server error "+(string)code;
         Backoff(5,60);
         g_llbLog.Warn("TGW",method+": "+m_statusText);
         return true;
        }
      return false;
     }

   void              Push(const int kind,const string method,const string body,const string signalId)
     {
      int n=ArraySize(m_out);
      if(n>=LLB_TG_MAX_QUEUE)
        {
         //--- drop the oldest non-proposal, non-answer item first
         int drop=-1;
         for(int i=0; i<n; i++)
            if(m_out[i].kind==LLB_TGK_TEXT || m_out[i].kind==LLB_TGK_EDIT)
              {
               drop=i;
               break;
              }
         if(drop<0)
            drop=0;
         RemoveOut(drop);
         n=ArraySize(m_out);
         g_llbLog.Warn("TGW","outbox full - oldest message dropped");
        }
      ArrayResize(m_out,n+1);
      m_out[n].kind=kind;
      m_out[n].method=method;
      m_out[n].body=body;
      m_out[n].signalId=signalId;
      m_out[n].attempts=0;
      m_out[n].notBeforeMs=0;
     }

   void              RemoveOut(const int idx)
     {
      int n=ArraySize(m_out);
      if(idx<0 || idx>=n)
         return;
      for(int k=idx; k<n-1; k++)
         m_out[k]=m_out[k+1];
      ArrayResize(m_out,n-1);
     }

   //--- 0 = done, 1 = keep (retry later), 2 = drop
   int               SendItem(const int i)
     {
      string resp;
      int err=0;
      int code=Http(m_out[i].method,m_out[i].body,resp,err);
      if(code==200)
        {
         OnSuccess();
         if(m_out[i].kind==LLB_TGK_PROPOSAL)
           {
            CLLBJson root;
            string perr;
            long mid=0;
            if(root.Parse(resp,perr))
              {
               CLLBJson *res=root.Get("result");
               if(res!=NULL)
                  mid=res.GetLong("message_id",0);
              }
            int k=ArraySize(m_sentIds);
            ArrayResize(m_sentIds,k+1);
            ArrayResize(m_sentMsgIds,k+1);
            m_sentIds[k]=m_out[i].signalId;
            m_sentMsgIds[k]=mid;
           }
         return 0;
        }
      if(OnFailure(code,err,resp,m_out[i].method))
         return 1;
      int ra=0;
      string desc=Description(resp,ra);
      if(m_out[i].kind==LLB_TGK_EDIT && StringFind(desc,"not modified")>=0)
         return 0;
      if(m_out[i].kind==LLB_TGK_ANSWER)
        {
         g_llbLog.Debug("TGW","answerCallbackQuery HTTP "+(string)code+": "+desc);
         return 2;                                      // answers are best effort (query may be too old)
        }
      m_out[i].attempts++;
      g_llbLog.Warn("TGW",StringFormat("%s HTTP %d: %s (attempt %d)",m_out[i].method,code,desc,m_out[i].attempts));
      m_out[i].notBeforeMs=NowMs()+5000;
      return (m_out[i].attempts>=3) ? 2 : 1;
     }

   void              CheckMe(void)
     {
      string resp;
      int err=0;
      int code=Http("getMe","{}",resp,err);
      if(code!=200)
        {
         if(!OnFailure(code,err,resp,"getMe"))
           {
            g_llbLog.Warn("TGW","getMe HTTP "+(string)code);
            Backoff(5,60);
           }
         //--- token rejected: retry every 5 minutes; other failures follow the backoff
         m_nextMeMs=(m_status==LLB_TG_AUTH_ERROR) ? NowMs()+300000 : 0;
         return;
        }
      CLLBJson root;
      string perr;
      if(root.Parse(resp,perr))
        {
         CLLBJson *res=root.Get("result");
         if(res!=NULL)
            m_botName=res.GetStr("username","");
        }
      m_meOk=true;
      m_status=LLB_TG_CONNECTING;
      OnSuccess();
      g_llbLog.Info("TGW","bot verified: @"+m_botName);
     }

public:
                     CLLBTelegramGateway(void)
     {
      m_enabled=false;
      m_token="";
      m_chatId=0;
      m_status=LLB_TG_DISABLED;
      m_statusText="disabled";
      m_offset=0;
      m_offsetDirty=false;
      m_pollMs=1500;
      m_timeoutMs=5000;
      m_nextPollMs=0;
      m_backoffUntilMs=0;
      m_backoffSec=0;
      m_meOk=false;
      m_nextMeMs=0;
      m_botName="";
     }

   bool              Init(const bool enabled,const string tokenInput,const long chatId,const string allowedCsv,const int pollMs,
                          const int timeoutMs,string &err)
     {
      m_enabled=false;
      m_status=LLB_TG_DISABLED;
      m_statusText="disabled";
      if(!enabled)
         return true;
      if(chatId==0)
        {
         err="InpTgChatId must be set to your Telegram chat id";
         return false;
        }
      if(!LoadToken(tokenInput,err))
         return false;
      g_llbLog.AddSecret(m_token);
      m_chatId=chatId;
      int n=LLB_ParseIdList(allowedCsv,m_allowed);
      if(n<0)
        {
         err="InpTgAllowedUserIds invalid: use comma separated numeric Telegram user ids";
         return false;
        }
      if(n==0)
        {
         ArrayResize(m_allowed,1);
         m_allowed[0]=chatId;
         if(chatId<0)
            g_llbLog.Warn("TGW","InpTgChatId is a group/channel id and InpTgAllowedUserIds is empty: nobody will be able to approve - add your personal user id");
        }
      m_pollMs=MathMax(pollMs,1000);
      m_timeoutMs=MathMax(MathMin(timeoutMs,15000),1000);
      m_enabled=true;
      m_status=LLB_TG_CONNECTING;
      m_statusText="connecting";
      return true;
     }

   void              Deinit(void) { ArrayResize(m_out,0); }

   void              Disable(const string why)
     {
      m_enabled=false;
      m_status=LLB_TG_DISABLED;
      m_statusText=why;
     }

   bool              Enabled(void) { return m_enabled; }
   int               Status(void) { return m_status; }
   string            StatusText(void) { return m_statusText; }
   long              ChatId(void) { return m_chatId; }
   string            TokenKey(void) { return LLB_Hex32(LLB_Fnv1a(m_token)); }
   long              Offset(void) { return m_offset; }
   void              SetOffset(const long off) { if(off>m_offset) m_offset=off; }
   bool              OffsetDirty(void) { return m_offsetDirty; }
   void              ClearOffsetDirty(void) { m_offsetDirty=false; }
   int               QueueSize(void) { return ArraySize(m_out); }

   bool              IsAuthorized(const long chatId,const long fromId) { return LLB_TgAuthorized(chatId,fromId,m_chatId,m_allowed); }

   //--- queueing ------------------------------------------------------
   void              QueueAnswer(const string queryId,const string text,const bool alert)
     {
      if(!m_enabled || queryId=="")
         return;
      string body="{\"callback_query_id\":"+LLB_JsonStr(queryId)+",\"text\":"+LLB_JsonStr(LLB_Truncate(text,190))
                  +",\"show_alert\":"+(alert ? "true" : "false")+"}";
      Push(LLB_TGK_ANSWER,"answerCallbackQuery",body,"");
     }

   void              QueueProposal(const string signalId,const string text)
     {
      if(!m_enabled)
         return;
      string kb="{\"inline_keyboard\":[[{\"text\":"+LLB_JsonStr(LLB_IconOk()+" ACCEPT")+",\"callback_data\":"+LLB_JsonStr("ACCEPT|"+signalId)
                +"},{\"text\":"+LLB_JsonStr(LLB_IconNo()+" REJECT")+",\"callback_data\":"+LLB_JsonStr("REJECT|"+signalId)+"}]]}";
      string body="{\"chat_id\":"+IntegerToString(m_chatId)+",\"text\":"+LLB_JsonStr(LLB_Truncate(text,LLB_TG_MAX_TEXT))
                  +",\"disable_web_page_preview\":true,\"reply_markup\":"+kb+"}";
      Push(LLB_TGK_PROPOSAL,"sendMessage",body,signalId);
     }

   void              QueueText(const string text)
     {
      if(!m_enabled)
         return;
      string body="{\"chat_id\":"+IntegerToString(m_chatId)+",\"text\":"+LLB_JsonStr(LLB_Truncate(text,LLB_TG_MAX_TEXT))
                  +",\"disable_web_page_preview\":true}";
      Push(LLB_TGK_TEXT,"sendMessage",body,"");
     }

   //--- replaces the proposal message text and removes the inline keyboard
   void              QueueEdit(const long messageId,const string text,const string signalId)
     {
      if(!m_enabled || messageId<=0)
         return;
      string body="{\"chat_id\":"+IntegerToString(m_chatId)+",\"message_id\":"+IntegerToString(messageId)
                  +",\"text\":"+LLB_JsonStr(LLB_Truncate(text,LLB_TG_MAX_TEXT))
                  +",\"disable_web_page_preview\":true,\"reply_markup\":{\"inline_keyboard\":[]}}";
      for(int i=0; i<ArraySize(m_out); i++)
         if(m_out[i].kind==LLB_TGK_EDIT && m_out[i].signalId==signalId)
           {
            m_out[i].body=body;                          // newest status wins
            return;
           }
      Push(LLB_TGK_EDIT,"editMessageText",body,signalId);
     }

   //--- drop a not-yet-sent proposal (it became terminal first)
   bool              CancelProposal(const string signalId)
     {
      for(int i=ArraySize(m_out)-1; i>=0; i--)
         if(m_out[i].kind==LLB_TGK_PROPOSAL && m_out[i].signalId==signalId)
           {
            RemoveOut(i);
            return true;
           }
      return false;
     }

   //--- network -------------------------------------------------------
   void              PollIfDue(void)
     {
      if(!m_enabled)
         return;
      long now=NowMs();
      if(now<m_backoffUntilMs)
         return;
      if(!m_meOk)
        {
         if(now>=m_nextMeMs)
            CheckMe();
         if(!m_meOk)
            return;
        }
      if(now<m_nextPollMs)
         return;
      m_nextPollMs=now+m_pollMs;
      string body=StringFormat("{\"offset\":%I64d,\"timeout\":0,\"limit\":20,\"allowed_updates\":[\"callback_query\"]}",m_offset);
      string resp;
      int err=0;
      int code=Http("getUpdates",body,resp,err);
      if(code!=200)
        {
         if(!OnFailure(code,err,resp,"getUpdates"))
           {
            int ra=0;
            g_llbLog.Warn("TGW","getUpdates HTTP "+(string)code+": "+Description(resp,ra));
            Backoff(5,60);
           }
         return;
        }
      OnSuccess();
      long maxId=-1;
      LLBTelegramCallback cbs[];
      string perr;
      int n=LLB_ParseUpdates(resp,maxId,cbs,perr);
      if(n<0)
        {
         g_llbLog.Warn("TGW","getUpdates parse error: "+perr);
         return;
        }
      if(maxId>=m_offset)
        {
         m_offset=maxId+1;
         m_offsetDirty=true;
        }
      for(int i=0; i<n; i++)
        {
         int k=ArraySize(m_in);
         ArrayResize(m_in,k+1);
         m_in[k]=cbs[i];
        }
     }

   //--- sends due outbox items, callback answers first
   void              Flush(const int maxItems)
     {
      if(!m_enabled || !m_meOk)
         return;
      int sent=0;
      for(int pass=0; pass<4; pass++)
        {
         for(int i=0; i<ArraySize(m_out); i++)
           {
            if(m_out[i].kind!=pass)
               continue;
            if(NowMs()<m_backoffUntilMs)
               return;
            if(m_out[i].notBeforeMs>NowMs())
               continue;
            int r=SendItem(i);
            if(r==0 || r==2)
              {
               RemoveOut(i);
               i--;
              }
            sent++;
            if(sent>=maxItems)
               return;
           }
        }
     }

   int               TakeCallbacks(LLBTelegramCallback &out[])
     {
      int n=ArraySize(m_in);
      ArrayResize(out,n);
      for(int i=0; i<n; i++)
         out[i]=m_in[i];
      ArrayResize(m_in,0);
      return n;
     }

   int               TakeSentProposals(string &ids[],long &msgIds[])
     {
      int n=ArraySize(m_sentIds);
      ArrayResize(ids,n);
      ArrayResize(msgIds,n);
      for(int i=0; i<n; i++)
        {
         ids[i]=m_sentIds[i];
         msgIds[i]=m_sentMsgIds[i];
        }
      ArrayResize(m_sentIds,0);
      ArrayResize(m_sentMsgIds,0);
      return n;
     }
  };

#endif
//+------------------------------------------------------------------+
