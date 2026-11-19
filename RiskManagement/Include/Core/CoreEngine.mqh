//+------------------------------------------------------------------+
//|                                                   CoreEngine.mqh |
//|                    EA Risk Management - M1 Core & Account Engine |
//|                                                                  |
//| Orchestrates the M1 data cycle:                                  |
//|   - owns CAccountEngine and CDataValidator                       |
//|   - decides the status of every collection (VALID / INVALID /    |
//|     UNAVAILABLE / STALE)                                         |
//|   - keeps the LATEST collection status (every cycle) separate    |
//|     from the LAST SUCCESSFUL snapshot (VALID cycles only)        |
//|   - locks the account identity and detects identity changes      |
//|   - tracks terminal connect / disconnect transitions             |
//|   - logs state transitions only (no repeated lines)              |
//|                                                                  |
//| Invariants                                                       |
//|   I1 a failed cycle never overwrites the last successful         |
//|      snapshot                                                    |
//|   I2 GetCurrentStatus() always reports the latest cycle          |
//|   I3 GetLatestSnapshot() returns true only for current VALID     |
//|      data; otherwise it returns false and, if one exists, the    |
//|      last successful snapshot marked DATA_STATUS_STALE with the  |
//|      reason (user decision Q-04)                                 |
//|   I4 after an identity change every cycle is UNAVAILABLE until   |
//|      the EA is restarted; no account data is read any more       |
//|                                                                  |
//| READ-ONLY: no order, position, deal, history or trade-class      |
//| function is used; account data is read only through              |
//| CAccountEngine.                                                  |
//+------------------------------------------------------------------+
#ifndef RISKMANAGEMENT_CORE_COREENGINE_MQH
#define RISKMANAGEMENT_CORE_COREENGINE_MQH

#include "../Models/AccountModel.mqh"
#include "../Validation/DataValidator.mqh"
#include "../Utils/Logger.mqh"
#include "AccountEngine.mqh"

//+------------------------------------------------------------------+
//| Central configuration (filled once from the EA inputs)           |
//+------------------------------------------------------------------+
#define RM_MIN_REFRESH_SECONDS 1

struct RiskManagementConfig
  {
   int               account_refresh_seconds;     // InpAccountRefreshSeconds
   bool              enable_logging;              // InpEnableLogging
   bool              enable_debug_logging;        // InpEnableDebugLogging
   bool              require_connected_terminal;  // InpRequireConnectedTerminal
  };

//--- invalid values are rejected, never replaced by a default
bool RMValidateConfig(const RiskManagementConfig &config,string &error_message)
  {
   error_message="";
   if(config.account_refresh_seconds<RM_MIN_REFRESH_SECONDS)
     {
      error_message="InpAccountRefreshSeconds must be >= "+IntegerToString(RM_MIN_REFRESH_SECONDS)
                    +" second(s) (got "+IntegerToString(config.account_refresh_seconds)
                    +"); no default value is substituted";
      return(false);
     }
   return(true);
  }

enum ENUM_RM_CONNECTION_STATE
  {
   RM_CONNECTION_UNKNOWN,
   RM_CONNECTION_CONNECTED,
   RM_CONNECTION_DISCONNECTED
  };

//+------------------------------------------------------------------+
//| Core engine                                                      |
//+------------------------------------------------------------------+
class CCoreEngine
  {
private:
   CAccountEngine    m_account_engine;
   CDataValidator    m_validator;
   CLogger          *m_logger;
   RiskManagementConfig m_config;
   bool              m_configured;
   bool              m_initialized;
   bool              m_refresh_in_progress;
   string            m_init_error;

   //--- latest collection: updated by EVERY cycle
   ENUM_DATA_STATUS  m_current_status;
   string            m_current_error;
   long              m_cycle_count;

   //--- last successful snapshot: updated ONLY by VALID cycles
   bool              m_has_last_success;
   AccountSnapshot   m_last_success;

   //--- account identity baseline (identity of the first VALID snapshot)
   bool              m_has_baseline;
   long              m_baseline_login;
   string            m_baseline_server;
   string            m_baseline_currency;
   bool              m_identity_changed;
   string            m_identity_change_message;

   //--- terminal connection tracking
   ENUM_RM_CONNECTION_STATE m_connection_state;
   datetime          m_disconnected_since;
   bool              m_disconnected_at_start;

   //--- log de-duplication (state transitions only)
   bool              m_in_failure;
   string            m_failure_key;
   long              m_consecutive_failures;

   //--- logging -----------------------------------------------------
   void              Log(const ENUM_RM_LOG_LEVEL level,const ENUM_RM_LOG_EVENT event_id,const string message)
     {
      if(CheckPointer(m_logger)==POINTER_INVALID)
         return;
      m_logger.Log(level,event_id,message);
     }

   bool              IsDebugLogging()
     {
      if(CheckPointer(m_logger)==POINTER_INVALID)
         return(false);
      return(m_logger.IsDebugEnabled());
     }

   //--- state ---------------------------------------------------------
   void              ResetState()
     {
      m_refresh_in_progress=false;
      m_init_error="";

      m_current_status=DATA_STATUS_UNAVAILABLE;
      m_current_error=RM_MSG_NOT_COLLECTED;
      m_cycle_count=0;

      m_has_last_success=false;
      AccountSnapshotReset(m_last_success);

      m_has_baseline=false;
      m_baseline_login=RM_SENTINEL_LOGIN;
      m_baseline_server="";
      m_baseline_currency="";
      m_identity_changed=false;
      m_identity_change_message="";

      m_connection_state=RM_CONNECTION_UNKNOWN;
      m_disconnected_since=0;
      m_disconnected_at_start=false;

      m_in_failure=false;
      m_failure_key="";
      m_consecutive_failures=0;
     }

   void              SetCurrent(const ENUM_DATA_STATUS status,const string message)
     {
      m_current_status=status;
      m_current_error=message;
     }

   string            LastSuccessText()
     {
      if(!m_has_last_success)
         return("none");
      return(AccountModelFormatTime(m_last_success.collection_time));
     }

   string            BaselineText()
     {
      return("login="+IntegerToString(m_baseline_login)
             +" server=\""+m_baseline_server+"\""
             +" currency=\""+m_baseline_currency+"\"");
     }

   //--- connection transitions (logged once per transition) -----------
   void              UpdateConnectionState(const bool connected,const datetime observed_at)
     {
      if(connected)
        {
         if(m_connection_state==RM_CONNECTION_DISCONNECTED)
           {
            string outage="";
            if(m_disconnected_since>0 && observed_at>=m_disconnected_since)
               outage=" after about "+IntegerToString((long)observed_at-(long)m_disconnected_since)+" s";
            if(m_disconnected_at_start)
               Log(RM_LOG_INFO,RM_EVENT_TERMINAL_RECONNECTED,"Terminal connected to the trade server (it was not connected when the EA started)"+outage);
            else
               Log(RM_LOG_INFO,RM_EVENT_TERMINAL_RECONNECTED,"Terminal reconnected to the trade server"+outage);
           }
         m_connection_state=RM_CONNECTION_CONNECTED;
         m_disconnected_since=0;
         m_disconnected_at_start=false;
         return;
        }
      if(m_connection_state!=RM_CONNECTION_DISCONNECTED)
        {
         m_disconnected_at_start=(m_connection_state==RM_CONNECTION_UNKNOWN);
         if(m_disconnected_at_start)
            Log(RM_LOG_WARNING,RM_EVENT_TERMINAL_DISCONNECTED,"Terminal is not connected to the trade server (first check after start)");
         else
            Log(RM_LOG_WARNING,RM_EVENT_TERMINAL_DISCONNECTED,"Terminal lost the connection to the trade server");
         m_disconnected_since=observed_at;
        }
      m_connection_state=RM_CONNECTION_DISCONNECTED;
     }

   //--- identity ----------------------------------------------------
   bool              IdentityDiffersFromBaseline(const AccountSnapshot &snapshot)
     {
      if(snapshot.login!=m_baseline_login)
         return(true);
      if(snapshot.server!=m_baseline_server)
         return(true);
      if(snapshot.currency!=m_baseline_currency)
         return(true);
      return(false);
     }

   void              LatchIdentityChange(const AccountSnapshot &snapshot)
     {
      m_identity_changed=true;
      m_identity_change_message="ACCOUNT_IDENTITY_CHANGED: baseline "+BaselineText()
                                +" but the terminal now reports login="+IntegerToString(snapshot.login)
                                +" server=\""+snapshot.server+"\""
                                +" currency=\""+snapshot.currency+"\""
                                +". Account context locked: no further collection; restart the EA to monitor the new account";
      SetCurrent(DATA_STATUS_UNAVAILABLE,m_identity_change_message);
      m_consecutive_failures++;
      m_in_failure=true;
      m_failure_key="ACCOUNT_IDENTITY_CHANGED";
      Log(RM_LOG_ERROR,RM_EVENT_ACCOUNT_IDENTITY_CHANGED,m_identity_change_message);
     }

   //--- cycle outcomes ----------------------------------------------
   void              HandleFailure(const ENUM_DATA_STATUS status,const string reason,const bool environmental)
     {
      SetCurrent(status,reason);
      m_consecutive_failures++;
      string key=DataStatusToString(status)+"|"+reason;
      if(m_in_failure && key==m_failure_key)
         return;                                // same failure as the previous cycle: no new log line
      m_in_failure=true;
      m_failure_key=key;
      string text="No valid account snapshot: status="+DataStatusToString(status)
                  +" reason="+reason
                  +" consecutive_failed_cycles="+IntegerToString(m_consecutive_failures)
                  +" last_successful_collection="+LastSuccessText();
      if(environmental)
         Log(RM_LOG_WARNING,RM_EVENT_ACCOUNT_COLLECTION_FAILED,text);
      else
         Log(RM_LOG_ERROR,RM_EVENT_ACCOUNT_COLLECTION_FAILED,text);
     }

   void              HandleSuccess(AccountSnapshot &snapshot)
     {
      snapshot.data_status=DATA_STATUS_VALID;
      snapshot.error_message="";

      bool first_valid=!m_has_baseline;
      if(first_valid)
        {
         m_has_baseline=true;
         m_baseline_login=snapshot.login;
         m_baseline_server=snapshot.server;
         m_baseline_currency=snapshot.currency;
        }

      AccountSnapshotCopy(snapshot,m_last_success);
      m_has_last_success=true;
      SetCurrent(DATA_STATUS_VALID,"");

      long failed_before=m_consecutive_failures;
      bool recovered=m_in_failure;
      m_in_failure=false;
      m_failure_key="";
      m_consecutive_failures=0;

      if(first_valid)
        {
         string text="First valid account snapshot; identity baseline locked: "+AccountSnapshotIdentityToString(snapshot);
         if(failed_before>0)
            text=text+" (after "+IntegerToString(failed_before)+" failed cycle(s))";
         Log(RM_LOG_INFO,RM_EVENT_ACCOUNT_COLLECTION_SUCCESS,text);
        }
      else
         if(recovered)
            Log(RM_LOG_INFO,RM_EVENT_ACCOUNT_COLLECTION_SUCCESS,
                "Account collection recovered after "+IntegerToString(failed_before)+" failed cycle(s)");

      if(IsDebugLogging())
         Log(RM_LOG_DEBUG,RM_EVENT_ACCOUNT_COLLECTION_SUCCESS,
             "cycle="+IntegerToString(m_cycle_count)+" "+AccountSnapshotToString(snapshot));
     }

   //--- one refresh cycle, fixed order --------------------------------
   void              RunCycle()
     {
      m_cycle_count++;

      if(!m_initialized)
        {
         SetCurrent(DATA_STATUS_UNAVAILABLE,"CORE_ENGINE_NOT_INITIALIZED: Initialize() has not succeeded");
         return;
        }

      //--- identity change is latched: never read the account again
      if(m_identity_changed)
        {
         SetCurrent(DATA_STATUS_UNAVAILABLE,m_identity_change_message);
         return;
        }

      //--- 1. raw collection (resets the snapshot first)
      AccountSnapshot snapshot;
      bool collected=m_account_engine.Collect(snapshot);

      //--- 2. connection transitions
      if(m_account_engine.GetLastCollectResult()!=RM_COLLECT_NOT_INITIALIZED)
         UpdateConnectionState(m_account_engine.IsTerminalConnected(),snapshot.collection_time);

      if(!collected)
        {
         HandleFailure(DATA_STATUS_UNAVAILABLE,snapshot.error_message,
                       m_account_engine.GetLastCollectResult()==RM_COLLECT_TERMINAL_DISCONNECTED);
         return;
        }

      //--- 3. identity change (checked before anything is stored)
      if(m_has_baseline && m_validator.ValidateAccountIdentity(snapshot) && IdentityDiffersFromBaseline(snapshot))
        {
         LatchIdentityChange(snapshot);
         return;
        }

      //--- 4. validation
      string validation_errors="";
      if(!m_validator.ValidateSnapshot(snapshot,validation_errors))
        {
         HandleFailure(DATA_STATUS_INVALID,"DATA_INVALID: "+validation_errors,false);
         return;
        }

      //--- 5. data read while disconnected (only when the connection is not required)
      if(!m_account_engine.IsTerminalConnected())
        {
         HandleFailure(DATA_STATUS_STALE,
                       "TERMINAL_DISCONNECTED: data passed validation but the terminal is not connected, so the values are the terminal's last known data (InpRequireConnectedTerminal=false)",
                       true);
         return;
        }

      //--- 6. publish
      HandleSuccess(snapshot);
     }

public:
                     CCoreEngine()
     {
      m_logger=NULL;
      m_config.account_refresh_seconds=0;
      m_config.enable_logging=false;
      m_config.enable_debug_logging=false;
      m_config.require_connected_terminal=true;
      m_configured=false;
      m_initialized=false;
      ResetState();
     }

   //--- additive: configuration + logger, must succeed before Initialize()
   bool              Configure(const RiskManagementConfig &config,CLogger *logger)
     {
      m_configured=false;
      m_init_error="";
      string config_error="";
      if(!RMValidateConfig(config,config_error))
        {
         m_init_error="CONFIG_INVALID: "+config_error;
         return(false);
        }
      if(CheckPointer(logger)==POINTER_INVALID)
        {
         m_init_error="CONFIG_INVALID: no logger available";
         return(false);
        }
      m_config=config;
      m_logger=logger;
      m_configured=true;
      return(true);
     }

   //--- TEST SUPPORT ONLY: forwards a controlled data source to the account engine
   void              SetDataSource(CAccountDataSource *source)
     {
      m_account_engine.SetDataSource(source);
     }

   //--- additive: reason of the last Configure()/Initialize() failure
   string            GetInitializationErrorMessage()
     {
      return(m_init_error);
     }

   //--- spec v1.0 ----------------------------------------------------
   bool              Initialize()
     {
      m_initialized=false;
      ResetState();
      if(!m_configured)
        {
         m_init_error="CORE_ENGINE_NOT_CONFIGURED: Configure() must succeed before Initialize()";
         return(false);
        }
      m_account_engine.Configure(m_config.require_connected_terminal);
      if(!m_account_engine.Initialize())
        {
         m_init_error="ACCOUNT_ENGINE_INIT_FAILED: "+m_account_engine.GetLastErrorMessage();
         return(false);
        }
      m_initialized=true;
      return(true);
     }

   void              Refresh()
     {
      if(m_refresh_in_progress)
         return;                                // never two collections at the same time
      m_refresh_in_progress=true;
      RunCycle();
      m_refresh_in_progress=false;
     }

   void              Shutdown()
     {
      m_account_engine.Shutdown();             // account engine first; the validator holds no state
      m_initialized=false;
      ResetState();
      m_configured=false;
      m_logger=NULL;
     }

   //--- true ONLY for current VALID data (see invariant I3)
   bool              GetLatestSnapshot(AccountSnapshot &snapshot)
     {
      if(m_initialized && m_has_last_success && m_current_status==DATA_STATUS_VALID)
        {
         AccountSnapshotCopy(m_last_success,snapshot);
         return(true);
        }
      if(m_has_last_success)
        {
         AccountSnapshotCopy(m_last_success,snapshot);
         snapshot.data_status=DATA_STATUS_STALE;
         snapshot.error_message="HISTORICAL_SNAPSHOT (not current data): latest collection status="
                                +DataStatusToString(m_current_status)
                                +" reason="+m_current_error
                                +"; these values were collected at "+AccountModelFormatTime(m_last_success.collection_time);
         return(false);
        }
      AccountSnapshotReset(snapshot);
      snapshot.data_status=DATA_STATUS_UNAVAILABLE;
      snapshot.error_message="NO_SUCCESSFUL_SNAPSHOT: latest collection status="
                             +DataStatusToString(m_current_status)
                             +" reason="+m_current_error;
      return(false);
     }

   ENUM_DATA_STATUS  GetCurrentStatus()
     {
      return(m_current_status);
     }

   //--- 0 when no successful collection exists since Initialize()
   datetime          GetLastSuccessfulCollectionTime()
     {
      if(!m_has_last_success)
         return(0);
      return(m_last_success.collection_time);
     }
  };

#endif // RISKMANAGEMENT_CORE_COREENGINE_MQH
//+------------------------------------------------------------------+
