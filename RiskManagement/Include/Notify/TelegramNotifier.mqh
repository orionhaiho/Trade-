//+------------------------------------------------------------------+
//|                                             TelegramNotifier.mqh |
//|          EA Risk Management - Telegram notification add-on       |
//|                                                                  |
//| Sends the core's state-transition events (and an optional        |
//| periodic summary) to one Telegram chat, in Vietnamese.           |
//|                                                                  |
//| Design                                                           |
//|  - opt-in (InpTelegramEnable=false by default)                   |
//|  - bounded queue (RM_TG_QUEUE_CAPACITY); oldest dropped and      |
//|    counted when full                                             |
//|  - at most ONE HTTPS request per timer cycle, after the account  |
//|    refresh; queued messages are batched into one Telegram message|
//|  - failures: exponential back-off 10 s .. 300 s; HTTP 429 obeys  |
//|    retry_after; HTTP 400/401/403/404 (wrong token / chat id /    |
//|    bot blocked) disable sending until the EA is restarted        |
//|  - send problems are logged once per transition                  |
//|    (TELEGRAM_SEND_FAILED / TELEGRAM_SEND_RECOVERED)              |
//|  - the bot token is never written to any log line                |
//|  - outbound only: nothing received from Telegram is executed;    |
//|    no trading function is used                                   |
//+------------------------------------------------------------------+
#ifndef RISKMANAGEMENT_NOTIFY_TELEGRAMNOTIFIER_MQH
#define RISKMANAGEMENT_NOTIFY_TELEGRAMNOTIFIER_MQH

#include "../Models/AccountModel.mqh"
#include "../Models/RiskEvent.mqh"
#include "../Utils/Logger.mqh"
#include "HttpTransport.mqh"
#include "TelegramMessagesVi.mqh"

#define RM_TG_API_URL            "https://api.telegram.org/bot"
#define RM_TG_QUEUE_CAPACITY     50
#define RM_TG_MAX_TEXT           3500
#define RM_TG_MIN_TIMEOUT_MS     1000
#define RM_TG_MAX_TIMEOUT_MS     15000
#define RM_TG_MAX_SUMMARY_MIN    10080
#define RM_TG_BACKOFF_FIRST_S    10
#define RM_TG_BACKOFF_MAX_S      300
#define RM_TG_DEFAULT_RETRY_S    30

//+------------------------------------------------------------------+
//| Input validation (no value is ever substituted)                  |
//+------------------------------------------------------------------+
bool RMIsDigit(const ushort character)
  {
   return(character>='0' && character<='9');
  }

//--- "<digits>:<secret>" as issued by @BotFather, no blanks
bool RMIsValidTelegramToken(const string token)
  {
   int length=StringLen(token);
   int colon=StringFind(token,":");
   if(colon<1 || length-colon-1<20)
      return(false);
   for(int i=0; i<length; i++)
     {
      ushort character=StringGetCharacter(token,i);
      if(i<colon)
        {
         if(!RMIsDigit(character))
            return(false);
         continue;
        }
      if(i==colon)
         continue;
      bool allowed=RMIsDigit(character) || (character>='a' && character<='z') || (character>='A' && character<='Z')
                   || character=='_' || character=='-';
      if(!allowed)
         return(false);
     }
   return(true);
  }

//--- numeric id (private chat, or negative group id) or @channelusername
bool RMIsValidTelegramChatId(const string chat_id)
  {
   int length=StringLen(chat_id);
   if(length<1)
      return(false);
   ushort first=StringGetCharacter(chat_id,0);
   if(first=='@')
     {
      if(length<6)
         return(false);
      for(int i=1; i<length; i++)
        {
         ushort character=StringGetCharacter(chat_id,i);
         if(!(RMIsDigit(character) || (character>='a' && character<='z') || (character>='A' && character<='Z') || character=='_'))
            return(false);
        }
      return(true);
     }
   int start=0;
   if(first=='-')
      start=1;
   if(length-start<1)
      return(false);
   for(int j=start; j<length; j++)
      if(!RMIsDigit(StringGetCharacter(chat_id,j)))
         return(false);
   return(true);
  }

bool RMValidateTelegramInputs(const bool enabled,const string token,const string chat_id,
                              const int summary_minutes,const int timeout_ms,string &error_message)
  {
   error_message="";
   if(!enabled)
      return(true);
   if(!RMIsValidTelegramToken(token))
     {
      error_message="InpTelegramBotToken is empty or malformed (expected <digits>:<secret> from @BotFather, no spaces)";
      return(false);
     }
   if(!RMIsValidTelegramChatId(chat_id))
     {
      error_message="InpTelegramChatId is empty or malformed (expected a numeric id such as 123456789 or -1001234567890, or @channelname)";
      return(false);
     }
   if(summary_minutes<0 || summary_minutes>RM_TG_MAX_SUMMARY_MIN)
     {
      error_message="InpTelegramSummaryMinutes must be between 0 (off) and "+IntegerToString(RM_TG_MAX_SUMMARY_MIN)
                    +" (got "+IntegerToString(summary_minutes)+")";
      return(false);
     }
   if(timeout_ms<RM_TG_MIN_TIMEOUT_MS || timeout_ms>RM_TG_MAX_TIMEOUT_MS)
     {
      error_message="InpTelegramTimeoutMs must be between "+IntegerToString(RM_TG_MIN_TIMEOUT_MS)+" and "
                    +IntegerToString(RM_TG_MAX_TIMEOUT_MS)+" (got "+IntegerToString(timeout_ms)+")";
      return(false);
     }
   return(true);
  }

//--- JSON string escaping for the text we generate (quotes, backslash, control characters)
string RMJsonEscape(string text)
  {
   StringReplace(text,"\\","\\\\");
   StringReplace(text,"\"","\\\"");
   StringReplace(text,"\r","\\r");
   StringReplace(text,"\n","\\n");
   StringReplace(text,"\t","\\t");
   return(text);
  }

//+------------------------------------------------------------------+
//| Notifier                                                         |
//+------------------------------------------------------------------+
class CTelegramNotifier : public CRiskEventListener
  {
private:
   CWebRequestTransport m_web_transport;
   CHttpTransport   *m_injected_transport;
   CHttpTransport   *m_transport;
   CLogger          *m_logger;
   bool              m_configured;
   bool              m_initialized;
   bool              m_disabled;
   bool              m_startup_mode;
   string            m_token;
   string            m_chat_id;
   int               m_timeout_ms;
   string            m_queue[RM_TG_QUEUE_CAPACITY];
   int               m_queue_head;
   int               m_queue_count;
   int               m_dropped;
   datetime          m_next_attempt;
   int               m_backoff_seconds;
   bool              m_in_error;
   string            m_error_key;
   int               m_requests_ok;
   int               m_requests_failed;
   string            m_account_label;
   string            m_last_error;

   void              Log(const ENUM_RM_LOG_LEVEL level,const ENUM_RM_LOG_EVENT event_id,const string message)
     {
      if(CheckPointer(m_logger)==POINTER_INVALID)
         return;
      m_logger.Log(level,event_id,message);
     }

   void              ResetQueue()
     {
      for(int i=0; i<RM_TG_QUEUE_CAPACITY; i++)
         m_queue[i]="";
      m_queue_head=0;
      m_queue_count=0;
      m_dropped=0;
     }

   void              ResetState()
     {
      ResetQueue();
      m_initialized=false;
      m_disabled=false;
      m_startup_mode=false;
      m_next_attempt=0;
      m_backoff_seconds=0;
      m_in_error=false;
      m_error_key="";
      m_requests_ok=0;
      m_requests_failed=0;
      m_account_label="";
      m_last_error="";
     }

   string            ExtractDescription(const string response)
     {
      string marker="\"description\":\"";
      int start=StringFind(response,marker);
      if(start<0)
         return("");
      start+=StringLen(marker);
      int end=StringFind(response,"\"",start);
      if(end<0)
         return("");
      return(StringSubstr(response,start,end-start));
     }

   int               ExtractRetryAfter(const string response)
     {
      string marker="\"retry_after\":";
      int start=StringFind(response,marker);
      if(start<0)
         return(RM_TG_DEFAULT_RETRY_S);
      long value=StringToInteger(StringSubstr(response,start+StringLen(marker),10));
      if(value<1 || value>3600)
         return(RM_TG_DEFAULT_RETRY_S);
      return((int)value);
     }

   //--- logs a send problem once per distinct cause
   void              ReportFailure(const ENUM_RM_LOG_LEVEL level,const string key,const string message)
     {
      m_last_error=message;
      if(m_in_error && key==m_error_key)
         return;
      m_in_error=true;
      m_error_key=key;
      Log(level,RM_EVENT_TELEGRAM_SEND_FAILED,message);
     }

   //--- builds one Telegram text from the oldest queued messages; returns how many were used
   int               BuildBatch(string &text)
     {
      text="";
      int used=0;
      if(m_dropped>0)
         text=RMViDroppedNotice(m_dropped);
      while(used<m_queue_count)
        {
         string message=m_queue[(m_queue_head+used)%RM_TG_QUEUE_CAPACITY];
         int separator=0;
         if(StringLen(text)>0)
            separator=2;
         if(used>0 && StringLen(text)+separator+StringLen(message)>RM_TG_MAX_TEXT)
            break;
         if(StringLen(message)>RM_TG_MAX_TEXT)
            message=StringSubstr(message,0,RM_TG_MAX_TEXT)+"...";
         if(separator>0)
            text=text+"\n\n";
         text=text+message;
         used++;
        }
      return(used);
     }

   void              RemoveFromQueue(const int count)
     {
      for(int i=0; i<count && m_queue_count>0; i++)
        {
         m_queue[m_queue_head]="";
         m_queue_head=(m_queue_head+1)%RM_TG_QUEUE_CAPACITY;
         m_queue_count--;
        }
     }

   void              SendBatch(const datetime now,const int timeout_ms)
     {
      string text="";
      int used=BuildBatch(text);
      if(used<1)
         return;
      string body="{\"chat_id\":\"";
      body=body+RMJsonEscape(m_chat_id)+"\",\"text\":\""+RMJsonEscape(text)+"\",\"disable_web_page_preview\":true}";
      string url=RM_TG_API_URL;
      url=url+m_token+"/sendMessage";

      string response="";
      int error_code=0;
      int status=m_transport.PostJson(url,body,timeout_ms,response,error_code);

      if(status==200 && StringFind(response,"\"ok\":true")>=0)
        {
         RemoveFromQueue(used);
         m_dropped=0;
         m_requests_ok++;
         m_backoff_seconds=0;
         m_next_attempt=0;
         m_last_error="";
         if(m_in_error)
            Log(RM_LOG_INFO,RM_EVENT_TELEGRAM_SEND_RECOVERED,"Telegram notifications are being delivered again");
         m_in_error=false;
         m_error_key="";
         return;
        }

      m_requests_failed++;
      if(status==429)
        {
         int wait=ExtractRetryAfter(response);
         m_next_attempt=now+wait;
         ReportFailure(RM_LOG_WARNING,"HTTP_429","Telegram rate limit (HTTP 429): retrying after "+IntegerToString(wait)+" s");
         return;
        }
      if(status==400 || status==401 || status==403 || status==404)
        {
         m_disabled=true;
         string hint="check InpTelegramChatId and press Start in the chat with the bot";
         if(status==401 || status==404)
            hint="check InpTelegramBotToken";
         if(status==403)
            hint="the bot was blocked by the user or is not a member of the group/channel";
         ReportFailure(RM_LOG_ERROR,"DISABLED","Telegram rejected the request (HTTP "+IntegerToString(status)+": "
                       +ExtractDescription(response)+"); "+hint+". Telegram notifications are disabled until the EA is restarted");
         return;
        }

      if(m_backoff_seconds<=0)
         m_backoff_seconds=RM_TG_BACKOFF_FIRST_S;
      else
         m_backoff_seconds=m_backoff_seconds*2;
      if(m_backoff_seconds>RM_TG_BACKOFF_MAX_S)
         m_backoff_seconds=RM_TG_BACKOFF_MAX_S;
      m_next_attempt=now+m_backoff_seconds;
      if(status==-1 && error_code==4014)
        {
         ReportFailure(RM_LOG_ERROR,"URL_NOT_ALLOWED",
                       "WebRequest is not allowed (error 4014): add https://api.telegram.org in Tools > Options > Expert Advisors > Allow WebRequest for listed URL");
         return;
        }
      if(status==-1)
        {
         ReportFailure(RM_LOG_WARNING,"NETWORK_"+IntegerToString(error_code),
                       "Telegram request failed (WebRequest error "+IntegerToString(error_code)+"); messages stay queued and are retried with back-off");
         return;
        }
      ReportFailure(RM_LOG_WARNING,"HTTP_"+IntegerToString(status),
                    "Telegram request failed (HTTP "+IntegerToString(status)+"); messages stay queued and are retried with back-off");
     }

public:
                     CTelegramNotifier()
     {
      m_injected_transport=NULL;
      m_transport=NULL;
      m_logger=NULL;
      m_configured=false;
      m_token="";
      m_chat_id="";
      m_timeout_ms=5000;
      ResetState();
     }

   //--- enabled=false leaves the notifier inactive (every call becomes a no-op)
   bool              Configure(const bool enabled,const string token,const string chat_id,const int timeout_ms,CLogger *logger)
     {
      m_configured=false;
      m_logger=logger;
      string error_message="";
      if(!RMValidateTelegramInputs(enabled,token,chat_id,0,timeout_ms,error_message))
        {
         m_last_error=error_message;
         return(false);
        }
      m_token=token;
      m_chat_id=chat_id;
      m_timeout_ms=timeout_ms;
      m_configured=enabled;
      return(true);
     }

   //--- TEST SUPPORT ONLY: inject a controlled HTTP transport (NULL = WebRequest)
   void              SetTransport(CHttpTransport *transport)
     {
      m_injected_transport=transport;
     }

   bool              Initialize()
     {
      ResetState();
      if(!m_configured)
         return(false);
      if(CheckPointer(m_injected_transport)!=POINTER_INVALID)
         m_transport=m_injected_transport;
      else
         m_transport=GetPointer(m_web_transport);
      m_initialized=(CheckPointer(m_transport)!=POINTER_INVALID);
      return(m_initialized);
     }

   void              Shutdown()
     {
      ResetState();
      m_transport=NULL;
      m_configured=false;
      m_token="";
      m_chat_id="";
      m_logger=NULL;
     }

   bool              IsActive()
     {
      return(m_initialized && !m_disabled);
     }

   //--- while true, core events are not sent: EA_INITIALIZED summarises the start
   void              SetStartupMode(const bool startup_mode)
     {
      m_startup_mode=startup_mode;
     }

   void              Enqueue(const string text)
     {
      if(!IsActive() || StringLen(text)==0)
         return;
      if(m_queue_count>=RM_TG_QUEUE_CAPACITY)
        {
         RemoveFromQueue(1);
         m_dropped++;
        }
      m_queue[(m_queue_head+m_queue_count)%RM_TG_QUEUE_CAPACITY]=text;
      m_queue_count++;
     }

   virtual void      OnRiskEvent(const RiskEvent &risk_event)
     {
      if(!IsActive())
         return;
      bool lifecycle=(risk_event.event_id==RM_EVENT_EA_INITIALIZED || risk_event.event_id==RM_EVENT_EA_INITIALIZATION_FAILED
                      || risk_event.event_id==RM_EVENT_EA_SHUTDOWN);
      if(m_startup_mode && !lifecycle)
         return;
      //--- a failure caused only by the missing connection is already announced by TERMINAL_DISCONNECTED
      if(risk_event.event_id==RM_EVENT_ACCOUNT_COLLECTION_FAILED && risk_event.status==DATA_STATUS_UNAVAILABLE
         && StringFind(risk_event.reason,"TERMINAL_DISCONNECTED")==0)
         return;
      if(risk_event.has_snapshot && risk_event.snapshot.login>0
         && (risk_event.event_id==RM_EVENT_EA_INITIALIZED || risk_event.event_id==RM_EVENT_ACCOUNT_COLLECTION_SUCCESS))
         m_account_label=RMViIdentity(risk_event.snapshot.login,risk_event.snapshot.server,risk_event.snapshot.currency);
      Enqueue(RMTelegramFormatEventVi(risk_event,m_account_label));
     }

   void              EnqueueSummary(const AccountSnapshot &snapshot,const bool is_current,const ENUM_DATA_STATUS current_status,
                                    const string current_reason,const datetime now)
     {
      Enqueue(RMTelegramFormatSummaryVi(snapshot,is_current,current_status,current_reason,m_account_label,now));
     }

   //--- called once per timer cycle: at most one HTTPS request
   void              Process(const datetime now)
     {
      if(!IsActive() || m_queue_count==0)
         return;
      if(m_next_attempt>0 && now<m_next_attempt)
         return;
      SendBatch(now,m_timeout_ms);
     }

   //--- best effort at shutdown: one request, ignores the back-off
   void              Flush(const datetime now,const int timeout_ms)
     {
      if(!IsActive() || m_queue_count==0)
         return;
      SendBatch(now,timeout_ms);
     }

   //--- diagnostics / tests
   int               GetQueueSize()           { return(m_queue_count); }
   int               GetDroppedCount()        { return(m_dropped); }
   int               GetSuccessfulRequests()  { return(m_requests_ok); }
   int               GetFailedRequests()      { return(m_requests_failed); }
   bool              IsDisabled()             { return(m_disabled); }
   datetime          GetNextAttemptTime()     { return(m_next_attempt); }
   string            GetLastErrorText()       { return(m_last_error); }
   int               GetTimeoutMs()           { return(m_timeout_ms); }
  };

#endif // RISKMANAGEMENT_NOTIFY_TELEGRAMNOTIFIER_MQH
//+------------------------------------------------------------------+
