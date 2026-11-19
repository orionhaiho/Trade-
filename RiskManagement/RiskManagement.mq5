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
//+------------------------------------------------------------------+
#property copyright "EA Risk Management"
#property version   "1.00"
#property description "M1 Core & Account Engine - strict read-only account snapshot collection."
#property description "Performs no trading operation of any kind."

#include "Include/Utils/Logger.mqh"
#include "Include/Core/CoreEngine.mqh"

//+------------------------------------------------------------------+
//| Inputs (spec v1.0, unchanged)                                    |
//+------------------------------------------------------------------+
input int  InpAccountRefreshSeconds = 1;
input bool InpEnableLogging = true;
input bool InpEnableDebugLogging = false;
input bool InpRequireConnectedTerminal = true;

//+------------------------------------------------------------------+
//| Globals                                                          |
//+------------------------------------------------------------------+
CLogger              g_logger;
CCoreEngine          g_core;
RiskManagementConfig g_config;
bool                 g_timer_created=false;

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

//--- 1. inputs are validated before anything is initialised
   LoadConfigFromInputs(g_config);
   string config_error="";
   if(!RMValidateConfig(g_config,config_error))
     {
      g_logger.Error(RM_EVENT_EA_INITIALIZATION_FAILED,"Invalid input: "+config_error);
      return(INIT_PARAMETERS_INCORRECT);
     }

//--- 2. core engine (account engine + validator)
   if(!g_core.Configure(g_config,GetPointer(g_logger)))
     {
      g_logger.Error(RM_EVENT_EA_INITIALIZATION_FAILED,"Core engine configuration rejected: "+g_core.GetInitializationErrorMessage());
      g_core.Shutdown();
      return(INIT_FAILED);
     }
   if(!g_core.Initialize())
     {
      g_logger.Error(RM_EVENT_EA_INITIALIZATION_FAILED,"Core engine initialization failed: "+g_core.GetInitializationErrorMessage());
      g_core.Shutdown();
      return(INIT_FAILED);
     }

//--- 3. initial collection (its result does not decide initialization, Q-01)
   g_core.Refresh();

//--- 4. refresh timer, created only after the core initialised successfully
   ResetLastError();
   if(!EventSetTimer(g_config.account_refresh_seconds))
     {
      int timer_error=GetLastError();
      g_logger.Error(RM_EVENT_EA_INITIALIZATION_FAILED,
                     "EventSetTimer("+IntegerToString(g_config.account_refresh_seconds)
                     +") failed, GetLastError="+IntegerToString(timer_error));
      g_core.Shutdown();
      return(INIT_FAILED);
     }
   g_timer_created=true;

   g_logger.Info(RM_EVENT_EA_INITIALIZED,BuildInitializedMessage());
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Timer: one refresh cycle (the terminal never queues a second     |
//| Timer event while one is pending or running)                     |
//+------------------------------------------------------------------+
void OnTimer()
  {
   g_core.Refresh();
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
  }
//+------------------------------------------------------------------+
