//+------------------------------------------------------------------+
//|                                                    RiskEvent.mqh |
//|                    EA Risk Management - M1 Core & Account Engine |
//|                                                                  |
//| Structured state-transition events for notification channels    |
//| (Telegram add-on). Events are raised exactly where the matching  |
//| log line is written, so they inherit the "transitions only"      |
//| de-duplication of CCoreEngine.                                   |
//|                                                                  |
//| READ-ONLY: data only; no terminal, account or trading API.       |
//+------------------------------------------------------------------+
#ifndef RISKMANAGEMENT_MODELS_RISKEVENT_MQH
#define RISKMANAGEMENT_MODELS_RISKEVENT_MQH

#include "AccountModel.mqh"
#include "../Utils/Logger.mqh"

//+------------------------------------------------------------------+
//| Field meaning per event                                          |
//|  EA_INITIALIZED          code=refresh seconds, flag=require      |
//|                          connected terminal, has_snapshot when   |
//|                          the initial collection is VALID, else   |
//|                          status + reason of the initial attempt  |
//|  EA_INITIALIZATION_FAILED reason                                 |
//|  ACCOUNT_COLLECTION_SUCCESS flag=true first valid snapshot,      |
//|                          false recovery; count=failed cycles     |
//|  ACCOUNT_COLLECTION_FAILED status, reason, count=consecutive     |
//|                          failed cycles, has_snapshot=last        |
//|                          successful snapshot exists              |
//|  ACCOUNT_IDENTITY_CHANGED snapshot=original account,             |
//|                          observed_*=identity now reported        |
//|  TERMINAL_DISCONNECTED   flag=true detected at start             |
//|  TERMINAL_RECONNECTED    flag=true was disconnected at start,    |
//|                          seconds=outage (-1 unknown)             |
//|  EA_SHUTDOWN             code=uninitialization reason            |
//+------------------------------------------------------------------+
struct RiskEvent
  {
   ENUM_RM_LOG_EVENT event_id;
   ENUM_RM_LOG_LEVEL level;
   datetime          event_time;
   ENUM_DATA_STATUS  status;
   string            reason;
   long              count;
   long              seconds;
   bool              flag;
   int               code;
   bool              has_snapshot;
   AccountSnapshot   snapshot;
   long              observed_login;
   string            observed_server;
   string            observed_currency;
  };

void RiskEventReset(RiskEvent &risk_event,const ENUM_RM_LOG_EVENT event_id,const ENUM_RM_LOG_LEVEL level,const datetime event_time)
  {
   risk_event.event_id=event_id;
   risk_event.level=level;
   risk_event.event_time=event_time;
   risk_event.status=DATA_STATUS_UNAVAILABLE;
   risk_event.reason="";
   risk_event.count=0;
   risk_event.seconds=-1;
   risk_event.flag=false;
   risk_event.code=0;
   risk_event.has_snapshot=false;
   AccountSnapshotReset(risk_event.snapshot);
   risk_event.observed_login=RM_SENTINEL_LOGIN;
   risk_event.observed_server="";
   risk_event.observed_currency="";
  }

//+------------------------------------------------------------------+
//| Receiver of events (implemented by CTelegramNotifier)            |
//+------------------------------------------------------------------+
class CRiskEventListener
  {
public:
   virtual          ~CRiskEventListener()
     {
     }
   virtual void      OnRiskEvent(const RiskEvent &risk_event)=0;
  };

#endif // RISKMANAGEMENT_MODELS_RISKEVENT_MQH
//+------------------------------------------------------------------+
