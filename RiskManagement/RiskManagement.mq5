//+------------------------------------------------------------------+
//|                                               RiskManagement.mq5 |
//|                    EA Risk Management - M1 Core & Account Engine |
//|                                       Specification v1.0 (M1)    |
//|                                                                  |
//| STRICT READ-ONLY EXPERT ADVISOR                                  |
//| It never sends, modifies, cancels or closes any order or         |
//| position. It only reads account information and prints status    |
//| lines to the Experts/Journal tab.                                |
//|                                                                  |
//| Lifecycle                                                        |
//|   OnInit   validate inputs -> configure + initialise core ->     |
//|            initial collection -> EventSetTimer -> EA_INITIALIZED |
//|   OnTimer  one refresh cycle                                     |
//|   OnDeinit EventKillTimer (only if created) -> core shutdown ->  |
//|            EA_SHUTDOWN                                           |
//|                                                                  |
//| Initial collection policy (user decision Q-01): a non-VALID      |
//| first collection (e.g. terminal not yet connected) does NOT fail |
//| OnInit; the status stays UNAVAILABLE/INVALID, the timer keeps    |
//| retrying, and the identity baseline is locked by the first VALID |
//| snapshot.                                                        |
//|                                                                  |
//| Telegram add-on (optional, off by default): state transitions    |
//| and an optional periodic summary are sent in Vietnamese to one   |
//| Telegram chat. Requires https://api.telegram.org in Tools >      |
//| Options > Expert Advisors > Allow WebRequest for listed URL.     |
//+------------------------------------------------------------------+
#property copyright "EA Risk Management"
#property version   "1.00"
#property description "M1 Core & Account Engine - strict read-only account snapshot collection."
#property description "Performs no trading operation of any kind."

#include "Include/Utils/Logger.mqh"
#include "Include/Core/CoreEngine.mqh"
#include "Include/Notify/TelegramNotifier.mqh"

//+------------------------------------------------------------------+
//| Inputs (spec v1.0, unchanged)                                    |
//+------------------------------------------------------------------+
input int  InpAccountRefreshSeconds = 1;
input bool InpEnableLogging = true;
input bool InpEnableDebugLogging = false;
input bool InpRequireConnectedTerminal = true;

//--- Telegram add-on (user-approved extension, not part of spec v1.0)
input bool   InpTelegramEnable = false;          // send notifications to Telegram
input string InpTelegramBotToken = "";           // token from @BotFather (keep secret)
input string InpTelegramChatId = "";             // chat id, e.g. 123456789 or -1001234567890
input int    InpTelegramSummaryMinutes = 0;      // periodic account summary, 0 = off
input int    InpTelegramTimeoutMs = 5000;        // WebRequest timeout (1000..15000 ms)

//+------------------------------------------------------------------+
//| Globals                                                          |
//+------------------------------------------------------------------+
CLogger              g_logger;
CCoreEngine          g_core;
RiskManagementConfig g_config;
bool                 g_timer_created=false;
CTelegramNotifier    g_telegram;
datetime             g_next_summary=0;

//+------------------------------------------------------------------+
//| Inputs are read in exactly one place                             |
//+------------------------------------------------------------------+
void LoadConfigFromInputs(RiskManagementConfig &config)
  {
   config.account_refresh_seconds=InpAccountRefreshSeconds;
   config.enable_logging=InpEnableLogging;
   config.enable_debug_logging=InpEnableDebugLogging;
   config.require_connected_terminal=InpRequireConnectedTerminal;
  }

string UninitReasonText(const int reason)
  {
   switch(reason)
     {
      case REASON_PROGRAM:
         return("PROGRAM");
      case REASON_REMOVE:
         return("REMOVE");
      case REASON_RECOMPILE:
         return("RECOMPILE");
      case REASON_CHARTCHANGE:
         return("CHARTCHANGE");
      case REASON_CHARTCLOSE:
         return("CHARTCLOSE");
      case REASON_PARAMETERS:
         return("PARAMETERS");
      case REASON_ACCOUNT:
         return("ACCOUNT");
      case REASON_TEMPLATE:
         return("TEMPLATE");
      case REASON_INITFAILED:
         return("INITFAILED");
      case REASON_CLOSE:
         return("CLOSE");
     }
   return("UNKNOWN");
  }

string BuildInitializedMessage()
  {
   string text="RiskManagement M1 initialized (strict read-only). refresh_seconds="
               +IntegerToString(g_config.account_refresh_seconds)
               +" logging="+AccountModelBoolToString(g_config.enable_logging)
               +" debug_logging="+AccountModelBoolToString(g_config.enable_debug_logging)
               +" require_connected_terminal="+AccountModelBoolToString(g_config.require_connected_terminal);
   AccountSnapshot snapshot;
   if(g_core.GetLatestSnapshot(snapshot))
      text=text+". Account: "+AccountSnapshotIdentityToString(snapshot);
   else
      text=text+". Account identity pending (no valid snapshot yet): "+snapshot.error_message;
   return(text);
  }

//--- reason part of "...status=X reason=Y" texts produced by CCoreEngine
string ExtractReason(const string text)
  {
   int position=StringFind(text," reason=");
   if(position<0)
      return(text);
   return(StringSubstr(text,position+8));
  }

void NotifyInitializationFailed(const string reason)
  {
   RiskEvent risk_event;
   RiskEventReset(risk_event,RM_EVENT_EA_INITIALIZATION_FAILED,RM_LOG_ERROR,TimeLocal());
   risk_event.reason=reason;
   g_telegram.OnRiskEvent(risk_event);
  }

void NotifyInitialized()
  {
   RiskEvent risk_event;
   RiskEventReset(risk_event,RM_EVENT_EA_INITIALIZED,RM_LOG_INFO,TimeLocal());
   risk_event.code=g_config.account_refresh_seconds;
   risk_event.flag=g_config.require_connected_terminal;
   risk_event.status=g_core.GetCurrentStatus();
   AccountSnapshot snapshot;
   risk_event.has_snapshot=g_core.GetLatestSnapshot(snapshot);
   if(risk_event.has_snapshot)
      AccountSnapshotCopy(snapshot,risk_event.snapshot);
   else
      risk_event.reason=ExtractReason(snapshot.error_message);
   g_telegram.OnRiskEvent(risk_event);
  }

void SendSummaryIfDue(const datetime now)
  {
   if(InpTelegramSummaryMinutes<=0 || !g_telegram.IsActive() || g_next_summary<=0 || now<g_next_summary)
      return;
   g_next_summary=now+InpTelegramSummaryMinutes*60;
   AccountSnapshot snapshot;
   bool is_current=g_core.GetLatestSnapshot(snapshot);
   string reason="";
   if(!is_current)
      reason=ExtractReason(snapshot.error_message);
   g_telegram.EnqueueSummary(snapshot,is_current,g_core.GetCurrentStatus(),reason,now);
  }

//--- Telegram must be configured before the other inputs are checked,
//--- so that an initialization failure can still be reported.
bool SetupTelegram(string &error_message)
  {
   g_telegram.Shutdown();
   g_next_summary=0;
   if(!RMValidateTelegramInputs(InpTelegramEnable,InpTelegramBotToken,InpTelegramChatId,
                                InpTelegramSummaryMinutes,InpTelegramTimeoutMs,error_message))
      return(false);
   if(!InpTelegramEnable)
      return(true);
   if(MQLInfoInteger(MQL_TESTER)!=0)
     {
      g_logger.Warning(RM_EVENT_TELEGRAM_SEND_FAILED,"Telegram is not available in the Strategy Tester (WebRequest); notifications disabled for this run");
      return(true);
     }
   if(!g_telegram.Configure(true,InpTelegramBotToken,InpTelegramChatId,InpTelegramTimeoutMs,GetPointer(g_logger))
      || !g_telegram.Initialize())
     {
      error_message="Telegram notifier could not be initialized: "+g_telegram.GetLastErrorText();
      return(false);
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- OnDeinit/OnInit can run without unloading the EA (symbol or
//--- period change): globals keep their values, so reset everything.
   g_timer_created=false;
   g_core.Shutdown();
   g_logger.Configure(InpEnableLogging,InpEnableDebugLogging);
   g_logger.SetSilent(false);
   g_logger.ResetCounters();

//--- 0. Telegram add-on (inactive unless InpTelegramEnable=true)
   string telegram_error="";
   if(!SetupTelegram(telegram_error))
     {
      g_logger.Error(RM_EVENT_EA_INITIALIZATION_FAILED,"Invalid input: "+telegram_error);
      return(INIT_PARAMETERS_INCORRECT);
     }

//--- 1. inputs are validated before anything is initialised
   LoadConfigFromInputs(g_config);
   string config_error="";
   if(!RMValidateConfig(g_config,config_error))
     {
      g_logger.Error(RM_EVENT_EA_INITIALIZATION_FAILED,"Invalid input: "+config_error);
      NotifyInitializationFailed("Invalid input: "+config_error);
      return(INIT_PARAMETERS_INCORRECT);
     }

//--- 2. core engine (account engine + validator)
   if(!g_core.Configure(g_config,GetPointer(g_logger)))
     {
      g_logger.Error(RM_EVENT_EA_INITIALIZATION_FAILED,"Core engine configuration rejected: "+g_core.GetInitializationErrorMessage());
      NotifyInitializationFailed("Core engine configuration rejected: "+g_core.GetInitializationErrorMessage());
      g_core.Shutdown();
      return(INIT_FAILED);
     }
   if(g_telegram.IsActive())
      g_core.SetEventListener(GetPointer(g_telegram));
   if(!g_core.Initialize())
     {
      g_logger.Error(RM_EVENT_EA_INITIALIZATION_FAILED,"Core engine initialization failed: "+g_core.GetInitializationErrorMessage());
      NotifyInitializationFailed("Core engine initialization failed: "+g_core.GetInitializationErrorMessage());
      g_core.Shutdown();
      return(INIT_FAILED);
     }

//--- 3. initial collection (its result does not decide initialization, Q-01);
//---    its events are summarised by the EA_INITIALIZED notification
   g_telegram.SetStartupMode(true);
   g_core.Refresh();

//--- 4. refresh timer, created only after the core initialised successfully
   ResetLastError();
   if(!EventSetTimer(g_config.account_refresh_seconds))
     {
      int timer_error=GetLastError();
      string timer_message="EventSetTimer("+IntegerToString(g_config.account_refresh_seconds)
                           +") failed, GetLastError="+IntegerToString(timer_error);
      g_logger.Error(RM_EVENT_EA_INITIALIZATION_FAILED,timer_message);
      g_telegram.SetStartupMode(false);
      NotifyInitializationFailed(timer_message);
      g_core.Shutdown();
      return(INIT_FAILED);
     }
   g_timer_created=true;

   g_logger.Info(RM_EVENT_EA_INITIALIZED,BuildInitializedMessage());
   g_telegram.SetStartupMode(false);
   NotifyInitialized();
   if(InpTelegramSummaryMinutes>0)
      g_next_summary=TimeLocal()+InpTelegramSummaryMinutes*60;
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Timer: one refresh cycle (the terminal never queues a second     |
//| Timer event while one is pending or running)                     |
//+------------------------------------------------------------------+
void OnTimer()
  {
   g_core.Refresh();
   datetime now=TimeLocal();
   SendSummaryIfDue(now);
   g_telegram.Process(now);          // at most one HTTPS request per cycle
  }

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(g_timer_created)
     {
      EventKillTimer();
      g_timer_created=false;
     }
   g_core.Shutdown();
   g_logger.Info(RM_EVENT_EA_SHUTDOWN,"RiskManagement M1 stopped, reason="+UninitReasonText(reason)
                 +" ("+IntegerToString(reason)+")");

//--- Telegram: report the stop, best effort (one request, short timeout)
   RiskEvent risk_event;
   RiskEventReset(risk_event,RM_EVENT_EA_SHUTDOWN,RM_LOG_INFO,TimeLocal());
   risk_event.code=reason;
   g_telegram.OnRiskEvent(risk_event);
   int flush_timeout=g_telegram.GetTimeoutMs();
   if(flush_timeout>3000)
      flush_timeout=3000;
   g_telegram.Flush(TimeLocal(),flush_timeout);
   g_telegram.Shutdown();
  }
//+------------------------------------------------------------------+
