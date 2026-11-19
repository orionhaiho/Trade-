//+------------------------------------------------------------------+
//|                                                       Logger.mqh |
//|                    EA Risk Management - M1 Core & Account Engine |
//|                                                                  |
//| Controlled logging to the Experts/Journal tab (Print only).      |
//|   - levels: DEBUG, INFO, WARNING, ERROR                          |
//|   - the 8 mandatory event codes, as a closed enum                |
//|   - every line carries a local timestamp, level and event code   |
//|                                                                  |
//| Level policy (user decision Q-03):                               |
//|   ERROR    always printed, also with InpEnableLogging=false      |
//|   WARNING  printed only with InpEnableLogging=true               |
//|   INFO     printed only with InpEnableLogging=true               |
//|   DEBUG    printed only with InpEnableLogging=true AND           |
//|            InpEnableDebugLogging=true                            |
//| Repetition control (state transitions only) is done by the       |
//| caller (CCoreEngine); this class never writes files.             |
//|                                                                  |
//| READ-ONLY: no account, trading, file or network API is used.     |
//+------------------------------------------------------------------+
#ifndef RISKMANAGEMENT_UTILS_LOGGER_MQH
#define RISKMANAGEMENT_UTILS_LOGGER_MQH

enum ENUM_RM_LOG_LEVEL
  {
   RM_LOG_DEBUG,
   RM_LOG_INFO,
   RM_LOG_WARNING,
   RM_LOG_ERROR
  };

#define RM_LOG_LEVEL_COUNT 4

//--- mandatory event codes (master prompt, Phase 8)
enum ENUM_RM_LOG_EVENT
  {
   RM_EVENT_EA_INITIALIZED,
   RM_EVENT_EA_INITIALIZATION_FAILED,
   RM_EVENT_ACCOUNT_COLLECTION_SUCCESS,
   RM_EVENT_ACCOUNT_COLLECTION_FAILED,
   RM_EVENT_ACCOUNT_IDENTITY_CHANGED,
   RM_EVENT_TERMINAL_DISCONNECTED,
   RM_EVENT_TERMINAL_RECONNECTED,
   RM_EVENT_EA_SHUTDOWN
  };

#define RM_LOG_EVENT_COUNT 8

//--- exact event code text written to the log
string RMLogEventCode(const ENUM_RM_LOG_EVENT event_id)
  {
   switch(event_id)
     {
      case RM_EVENT_EA_INITIALIZED:
         return("EA_INITIALIZED");
      case RM_EVENT_EA_INITIALIZATION_FAILED:
         return("EA_INITIALIZATION_FAILED");
      case RM_EVENT_ACCOUNT_COLLECTION_SUCCESS:
         return("ACCOUNT_COLLECTION_SUCCESS");
      case RM_EVENT_ACCOUNT_COLLECTION_FAILED:
         return("ACCOUNT_COLLECTION_FAILED");
      case RM_EVENT_ACCOUNT_IDENTITY_CHANGED:
         return("ACCOUNT_IDENTITY_CHANGED");
      case RM_EVENT_TERMINAL_DISCONNECTED:
         return("TERMINAL_DISCONNECTED");
      case RM_EVENT_TERMINAL_RECONNECTED:
         return("TERMINAL_RECONNECTED");
      case RM_EVENT_EA_SHUTDOWN:
         return("EA_SHUTDOWN");
     }
   return("UNKNOWN_EVENT");
  }

string RMLogLevelName(const ENUM_RM_LOG_LEVEL level)
  {
   switch(level)
     {
      case RM_LOG_DEBUG:
         return("DEBUG");
      case RM_LOG_INFO:
         return("INFO");
      case RM_LOG_WARNING:
         return("WARNING");
      case RM_LOG_ERROR:
         return("ERROR");
     }
   return("UNKNOWN_LEVEL");
  }

//+------------------------------------------------------------------+
//| Logger                                                           |
//| Line format:                                                     |
//| [RiskManagement][yyyy.mm.dd hh:mi:ss][LEVEL][EVENT_CODE] message |
//+------------------------------------------------------------------+
class CLogger
  {
private:
   bool              m_enabled;
   bool              m_debug_enabled;
   bool              m_silent;
   int               m_event_counts[RM_LOG_EVENT_COUNT];
   int               m_level_counts[RM_LOG_LEVEL_COUNT];
   int               m_total_count;
   string            m_last_line;

public:
                     CLogger()
     {
      m_enabled=true;
      m_debug_enabled=false;
      m_silent=false;
      ResetCounters();
     }

   //--- InpEnableLogging / InpEnableDebugLogging
   void              Configure(const bool enable_logging,const bool enable_debug_logging)
     {
      m_enabled=enable_logging;
      m_debug_enabled=enable_debug_logging;
     }

   //--- test support only: lines are still formatted and counted, but not printed
   void              SetSilent(const bool silent)
     {
      m_silent=silent;
     }

   void              ResetCounters()
     {
      for(int i=0; i<RM_LOG_EVENT_COUNT; i++)
         m_event_counts[i]=0;
      for(int j=0; j<RM_LOG_LEVEL_COUNT; j++)
         m_level_counts[j]=0;
      m_total_count=0;
      m_last_line="";
     }

   bool              IsLevelEnabled(const ENUM_RM_LOG_LEVEL level) const
     {
      if(level==RM_LOG_ERROR)
         return(true);
      if(!m_enabled)
         return(false);
      if(level==RM_LOG_DEBUG)
         return(m_debug_enabled);
      return(true);
     }

   bool              IsDebugEnabled() const
     {
      return(IsLevelEnabled(RM_LOG_DEBUG));
     }

   void              Log(const ENUM_RM_LOG_LEVEL level,const ENUM_RM_LOG_EVENT event_id,const string message)
     {
      if(!IsLevelEnabled(level))
         return;

      string line="[RiskManagement][";
      line=line+TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS)
           +"]["+RMLogLevelName(level)
           +"]["+RMLogEventCode(event_id)
           +"] "+message;

      int event_index=(int)event_id;
      if(event_index>=0 && event_index<RM_LOG_EVENT_COUNT)
         m_event_counts[event_index]++;
      int level_index=(int)level;
      if(level_index>=0 && level_index<RM_LOG_LEVEL_COUNT)
         m_level_counts[level_index]++;
      m_total_count++;
      m_last_line=line;

      if(!m_silent)
         Print(line);
     }

   void              Debug(const ENUM_RM_LOG_EVENT event_id,const string message)
     {
      Log(RM_LOG_DEBUG,event_id,message);
     }

   void              Info(const ENUM_RM_LOG_EVENT event_id,const string message)
     {
      Log(RM_LOG_INFO,event_id,message);
     }

   void              Warning(const ENUM_RM_LOG_EVENT event_id,const string message)
     {
      Log(RM_LOG_WARNING,event_id,message);
     }

   void              Error(const ENUM_RM_LOG_EVENT event_id,const string message)
     {
      Log(RM_LOG_ERROR,event_id,message);
     }

   //--- counters of emitted lines (used by tests to prove there is no log spam)
   int               GetEventCount(const ENUM_RM_LOG_EVENT event_id) const
     {
      int index=(int)event_id;
      if(index<0 || index>=RM_LOG_EVENT_COUNT)
         return(0);
      return(m_event_counts[index]);
     }

   int               GetLevelCount(const ENUM_RM_LOG_LEVEL level) const
     {
      int index=(int)level;
      if(index<0 || index>=RM_LOG_LEVEL_COUNT)
         return(0);
      return(m_level_counts[index]);
     }

   int               GetTotalCount() const
     {
      return(m_total_count);
     }

   string            GetLastLine() const
     {
      return(m_last_line);
     }
  };

#endif // RISKMANAGEMENT_UTILS_LOGGER_MQH
//+------------------------------------------------------------------+
