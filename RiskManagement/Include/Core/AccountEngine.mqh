//+------------------------------------------------------------------+
//|                                                AccountEngine.mqh |
//|                    EA Risk Management - M1 Core & Account Engine |
//|                                                                  |
//| Raw, read-only collection of the connected account's data.       |
//|                                                                  |
//| CAccountDataSource          abstract read-only data source       |
//| CTerminalAccountDataSource  the ONLY class in M1 that calls      |
//|                             terminal/account APIs:               |
//|                             TerminalInfoInteger, TimeLocal,      |
//|                             AccountInfoInteger/String/Double,    |
//|                             TimeTradeServer                      |
//| CAccountEngine              Initialize / Collect / Shutdown /    |
//|                             GetLastErrorMessage (spec v1.0)      |
//|                                                                  |
//| Collect() order (fixed):                                         |
//|   reset snapshot -> TERMINAL_CONNECTED -> TimeLocal (attempt     |
//|   time) -> connection rule -> identity -> financials ->          |
//|   configuration -> TimeTradeServer                               |
//| Any API error: every data field is reset again (no partial data  |
//| is ever returned), status UNAVAILABLE, message names the         |
//| property and the GetLastError() code.                            |
//| Collect() never marks a snapshot VALID: CCoreEngine validates it |
//| with CDataValidator before publishing.                           |
//|                                                                  |
//| READ-ONLY: no order, position, deal or history function, no      |
//| trade class, no file, no network.                                |
//+------------------------------------------------------------------+
#ifndef RISKMANAGEMENT_CORE_ACCOUNTENGINE_MQH
#define RISKMANAGEMENT_CORE_ACCOUNTENGINE_MQH

#include "../Models/AccountModel.mqh"

//--- typed outcome of the last Collect() call
enum ENUM_RM_COLLECT_RESULT
  {
   RM_COLLECT_OK,
   RM_COLLECT_NOT_INITIALIZED,
   RM_COLLECT_TERMINAL_DISCONNECTED,
   RM_COLLECT_API_ERROR,
   RM_COLLECT_SERVER_TIME_UNAVAILABLE
  };

#define RM_MSG_PENDING_VALIDATION "COLLECTED_PENDING_VALIDATION"

//+------------------------------------------------------------------+
//| Read-only account data source.                                   |
//| Every method returns true only when the value was obtained       |
//| without error; error_code carries GetLastError() (0 = none).     |
//| Production uses CTerminalAccountDataSource; tests inject a       |
//| controlled test double through CAccountEngine::SetDataSource().  |
//+------------------------------------------------------------------+
class CAccountDataSource
  {
public:
   virtual          ~CAccountDataSource()
     {
     }
   virtual bool      ReadTerminalConnected(bool &connected,int &error_code)=0;
   virtual bool      ReadInteger(const ENUM_ACCOUNT_INFO_INTEGER property_id,long &value,int &error_code)=0;
   virtual bool      ReadDouble(const ENUM_ACCOUNT_INFO_DOUBLE property_id,double &value,int &error_code)=0;
   virtual bool      ReadString(const ENUM_ACCOUNT_INFO_STRING property_id,string &value,int &error_code)=0;
   virtual bool      ReadTradeServerTime(datetime &value,int &error_code)=0;
   virtual bool      ReadLocalTime(datetime &value,int &error_code)=0;
  };

//+------------------------------------------------------------------+
//| Terminal-backed data source.                                     |
//| The MQL5 documentation defines no dedicated error output for     |
//| these functions, so the generic runtime mechanism is used:       |
//| ResetLastError() -> call -> GetLastError(). The returned value   |
//| itself is judged later by CDataValidator.                        |
//+------------------------------------------------------------------+
class CTerminalAccountDataSource : public CAccountDataSource
  {
public:
   virtual bool      ReadTerminalConnected(bool &connected,int &error_code)
     {
      ResetLastError();
      int raw_value=TerminalInfoInteger(TERMINAL_CONNECTED);
      error_code=GetLastError();
      connected=(raw_value!=0);
      return(error_code==0);
     }

   virtual bool      ReadInteger(const ENUM_ACCOUNT_INFO_INTEGER property_id,long &value,int &error_code)
     {
      ResetLastError();
      value=AccountInfoInteger(property_id);
      error_code=GetLastError();
      return(error_code==0);
     }

   virtual bool      ReadDouble(const ENUM_ACCOUNT_INFO_DOUBLE property_id,double &value,int &error_code)
     {
      ResetLastError();
      value=AccountInfoDouble(property_id);
      error_code=GetLastError();
      return(error_code==0);
     }

   virtual bool      ReadString(const ENUM_ACCOUNT_INFO_STRING property_id,string &value,int &error_code)
     {
      ResetLastError();
      value=AccountInfoString(property_id);
      error_code=GetLastError();
      return(error_code==0);
     }

   //--- 0 (or an error) means "server time not available"; local time is never substituted
   virtual bool      ReadTradeServerTime(datetime &value,int &error_code)
     {
      ResetLastError();
      value=TimeTradeServer();
      error_code=GetLastError();
      return(error_code==0 && value>0);
     }

   virtual bool      ReadLocalTime(datetime &value,int &error_code)
     {
      ResetLastError();
      value=TimeLocal();
      error_code=GetLastError();
      return(error_code==0 && value>0);
     }
  };

//+------------------------------------------------------------------+
//| Account engine                                                   |
//+------------------------------------------------------------------+
class CAccountEngine
  {
private:
   CTerminalAccountDataSource m_terminal_source;
   CAccountDataSource *m_injected_source;
   CAccountDataSource *m_source;
   bool              m_initialized;
   bool              m_require_connected_terminal;
   bool              m_terminal_connected;
   ENUM_RM_COLLECT_RESULT m_last_result;
   string            m_last_error_message;

   //--- error / status handling -----------------------------------
   bool              Fail(AccountSnapshot &snapshot,const ENUM_RM_COLLECT_RESULT result,const string message)
     {
      datetime attempt_time=snapshot.collection_time;
      AccountSnapshotReset(snapshot);
      snapshot.collection_time=attempt_time;
      snapshot.data_status=DATA_STATUS_UNAVAILABLE;
      snapshot.error_message=message;
      m_last_result=result;
      m_last_error_message=message;
      return(false);
     }

   string            ApiErrorMessage(const string function_name,const string property_name,const int error_code)
     {
      return("API_ERROR: "+function_name+"("+property_name+") failed, GetLastError="+IntegerToString(error_code));
     }

   bool              ReadIntegerValue(const ENUM_ACCOUNT_INFO_INTEGER property_id,long &value,AccountSnapshot &snapshot)
     {
      long raw_value=0;
      int error_code=0;
      if(!m_source.ReadInteger(property_id,raw_value,error_code))
         return(Fail(snapshot,RM_COLLECT_API_ERROR,ApiErrorMessage("AccountInfoInteger",EnumToString(property_id),error_code)));
      value=raw_value;
      return(true);
     }

   bool              ReadDoubleValue(const ENUM_ACCOUNT_INFO_DOUBLE property_id,double &value,AccountSnapshot &snapshot)
     {
      double raw_value=AccountModelNaN();
      int error_code=0;
      if(!m_source.ReadDouble(property_id,raw_value,error_code))
         return(Fail(snapshot,RM_COLLECT_API_ERROR,ApiErrorMessage("AccountInfoDouble",EnumToString(property_id),error_code)));
      value=raw_value;
      return(true);
     }

   bool              ReadStringValue(const ENUM_ACCOUNT_INFO_STRING property_id,string &value,AccountSnapshot &snapshot)
     {
      string raw_value="";
      int error_code=0;
      if(!m_source.ReadString(property_id,raw_value,error_code))
         return(Fail(snapshot,RM_COLLECT_API_ERROR,ApiErrorMessage("AccountInfoString",EnumToString(property_id),error_code)));
      value=raw_value;
      return(true);
     }

   //--- terminal connection + time of this attempt -----------------
   bool              CollectConnectionAndAttemptTime(AccountSnapshot &snapshot)
     {
      bool connected=false;
      int connection_error=0;
      if(!m_source.ReadTerminalConnected(connected,connection_error))
         connected=false;                       // unknown connection state is treated as disconnected
      m_terminal_connected=connected;

      datetime local_time=0;
      int time_error=0;
      if(!m_source.ReadLocalTime(local_time,time_error))
         return(Fail(snapshot,RM_COLLECT_API_ERROR,"API_ERROR: TimeLocal() returned no valid time, GetLastError="+IntegerToString(time_error)));
      snapshot.collection_time=local_time;

      if(!connected && m_require_connected_terminal)
        {
         if(connection_error!=0)
            return(Fail(snapshot,RM_COLLECT_TERMINAL_DISCONNECTED,
                        "TERMINAL_DISCONNECTED: TerminalInfoInteger(TERMINAL_CONNECTED) failed, GetLastError="
                        +IntegerToString(connection_error)+"; treated as disconnected"));
         return(Fail(snapshot,RM_COLLECT_TERMINAL_DISCONNECTED,
                     "TERMINAL_DISCONNECTED: terminal is not connected to the trade server (InpRequireConnectedTerminal=true)"));
        }
      return(true);
     }

   //--- account identity --------------------------------------------
   bool              CollectIdentity(AccountSnapshot &snapshot)
     {
      long   login=RM_SENTINEL_LOGIN;
      string server="";
      string company="";
      string currency="";
      if(!ReadIntegerValue(ACCOUNT_LOGIN,login,snapshot))
         return(false);
      if(!ReadStringValue(ACCOUNT_SERVER,server,snapshot))
         return(false);
      if(!ReadStringValue(ACCOUNT_COMPANY,company,snapshot))
         return(false);
      if(!ReadStringValue(ACCOUNT_CURRENCY,currency,snapshot))
         return(false);
      snapshot.login=login;
      snapshot.server=server;
      snapshot.company=company;
      snapshot.currency=currency;
      return(true);
     }

   //--- financial information: every value read directly, nothing derived
   bool              CollectFinancials(AccountSnapshot &snapshot)
     {
      double balance=AccountModelNaN();
      double equity=AccountModelNaN();
      double profit=AccountModelNaN();
      double credit=AccountModelNaN();
      double margin=AccountModelNaN();
      double free_margin=AccountModelNaN();
      double margin_level=AccountModelNaN();
      if(!ReadDoubleValue(ACCOUNT_BALANCE,balance,snapshot))
         return(false);
      if(!ReadDoubleValue(ACCOUNT_EQUITY,equity,snapshot))
         return(false);
      if(!ReadDoubleValue(ACCOUNT_PROFIT,profit,snapshot))
         return(false);
      if(!ReadDoubleValue(ACCOUNT_CREDIT,credit,snapshot))
         return(false);
      if(!ReadDoubleValue(ACCOUNT_MARGIN,margin,snapshot))
         return(false);
      if(!ReadDoubleValue(ACCOUNT_MARGIN_FREE,free_margin,snapshot))
         return(false);
      if(!ReadDoubleValue(ACCOUNT_MARGIN_LEVEL,margin_level,snapshot))
         return(false);
      snapshot.balance=balance;
      snapshot.equity=equity;
      snapshot.profit=profit;
      snapshot.credit=credit;
      snapshot.margin=margin;
      snapshot.free_margin=free_margin;
      snapshot.margin_level=margin_level;
      return(true);
     }

   //--- account configuration (permission flags are descriptive only) ---
   bool              CollectConfiguration(AccountSnapshot &snapshot)
     {
      long leverage=RM_SENTINEL_LEVERAGE;
      long margin_mode=RM_SENTINEL_MARGIN_MODE;
      long trade_allowed=0;
      long trade_expert=0;
      if(!ReadIntegerValue(ACCOUNT_LEVERAGE,leverage,snapshot))
         return(false);
      if(!ReadIntegerValue(ACCOUNT_MARGIN_MODE,margin_mode,snapshot))
         return(false);
      if(!ReadIntegerValue(ACCOUNT_TRADE_ALLOWED,trade_allowed,snapshot))
         return(false);
      if(!ReadIntegerValue(ACCOUNT_TRADE_EXPERT,trade_expert,snapshot))
         return(false);
      snapshot.leverage=leverage;
      snapshot.margin_mode=margin_mode;
      snapshot.trade_allowed=(trade_allowed!=0);
      snapshot.expert_allowed=(trade_expert!=0);
      return(true);
     }

   //--- trade server time (never replaced by local time) -------------
   bool              CollectServerTime(AccountSnapshot &snapshot)
     {
      datetime server_time=0;
      int error_code=0;
      if(!m_source.ReadTradeServerTime(server_time,error_code))
         return(Fail(snapshot,RM_COLLECT_SERVER_TIME_UNAVAILABLE,
                     "SERVER_TIME_UNAVAILABLE: TimeTradeServer() returned no valid time, GetLastError="
                     +IntegerToString(error_code)+"; server_time stays 0, local time is never substituted"));
      snapshot.server_time=server_time;
      return(true);
     }

public:
                     CAccountEngine()
     {
      m_injected_source=NULL;
      m_source=NULL;
      m_initialized=false;
      m_require_connected_terminal=true;
      m_terminal_connected=false;
      m_last_result=RM_COLLECT_NOT_INITIALIZED;
      m_last_error_message="";
     }

   //--- configuration (call before Initialize)
   void              Configure(const bool require_connected_terminal)
     {
      m_require_connected_terminal=require_connected_terminal;
     }

   //--- TEST SUPPORT ONLY: inject a controlled data source (NULL = terminal).
   //--- Production code never calls this. Takes effect at the next Initialize().
   void              SetDataSource(CAccountDataSource *source)
     {
      m_injected_source=source;
     }

   //--- spec v1.0 ----------------------------------------------------
   bool              Initialize()
     {
      m_initialized=false;
      m_terminal_connected=false;
      m_last_result=RM_COLLECT_NOT_INITIALIZED;
      m_last_error_message="";
      if(CheckPointer(m_injected_source)!=POINTER_INVALID)
         m_source=m_injected_source;
      else
         m_source=GetPointer(m_terminal_source);
      if(CheckPointer(m_source)==POINTER_INVALID)
        {
         m_last_error_message="ACCOUNT_ENGINE_INIT_FAILED: no account data source available";
         return(false);
        }
      m_initialized=true;
      return(true);
     }

   bool              Collect(AccountSnapshot &snapshot)
     {
      AccountSnapshotReset(snapshot);
      m_terminal_connected=false;
      m_last_result=RM_COLLECT_OK;
      m_last_error_message="";
      if(!m_initialized || CheckPointer(m_source)==POINTER_INVALID)
         return(Fail(snapshot,RM_COLLECT_NOT_INITIALIZED,"ACCOUNT_ENGINE_NOT_INITIALIZED: Initialize() has not succeeded"));
      if(!CollectConnectionAndAttemptTime(snapshot))
         return(false);
      if(!CollectIdentity(snapshot))
         return(false);
      if(!CollectFinancials(snapshot))
         return(false);
      if(!CollectConfiguration(snapshot))
         return(false);
      if(!CollectServerTime(snapshot))
         return(false);
      //--- every field read without API error; NOT valid until CCoreEngine validates it
      snapshot.data_status=DATA_STATUS_UNAVAILABLE;
      snapshot.error_message=RM_MSG_PENDING_VALIDATION;
      return(true);
     }

   void              Shutdown()
     {
      m_initialized=false;
      m_source=NULL;
      m_terminal_connected=false;
      m_last_result=RM_COLLECT_NOT_INITIALIZED;
      m_last_error_message="";
     }

   string            GetLastErrorMessage()
     {
      return(m_last_error_message);
     }

   //--- additive helpers used by CCoreEngine -------------------------
   //--- connection state observed by the last Collect() (false if unknown)
   bool              IsTerminalConnected()
     {
      return(m_terminal_connected);
     }

   ENUM_RM_COLLECT_RESULT GetLastCollectResult()
     {
      return(m_last_result);
     }
  };

#endif // RISKMANAGEMENT_CORE_ACCOUNTENGINE_MQH
//+------------------------------------------------------------------+
