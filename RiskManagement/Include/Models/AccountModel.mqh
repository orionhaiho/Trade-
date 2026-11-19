//+------------------------------------------------------------------+
//|                                                 AccountModel.mqh |
//|                    EA Risk Management - M1 Core & Account Engine |
//|                                                                  |
//| Data contract shared by every M1 module:                         |
//|   - ENUM_DATA_STATUS and AccountSnapshot (spec v1.0, unchanged)  |
//|   - documented "not collected" sentinels (never 0 for numbers)   |
//|   - pure helpers: reset, copy and text formatting for logs       |
//|                                                                  |
//| READ-ONLY: this file calls no terminal, account or trading API.  |
//+------------------------------------------------------------------+
#ifndef RISKMANAGEMENT_MODELS_ACCOUNTMODEL_MQH
#define RISKMANAGEMENT_MODELS_ACCOUNTMODEL_MQH

//+------------------------------------------------------------------+
//| Status of one account data collection (spec v1.0, unchanged)     |
//|                                                                  |
//| VALID        collected in this cycle, every field read without   |
//|              API error, validation passed, terminal connected    |
//| UNAVAILABLE  data could not be obtained: terminal disconnected,  |
//|              API error, server time missing, account identity    |
//|              changed, engine not initialised, nothing collected  |
//| INVALID      data was read but failed validation                 |
//| STALE        not current data: either the clearly marked         |
//|              historical copy of the last successful snapshot,    |
//|              or data read while the terminal is disconnected     |
//|              (only possible with InpRequireConnectedTerminal=    |
//|              false)                                              |
//+------------------------------------------------------------------+
enum ENUM_DATA_STATUS
  {
   DATA_STATUS_VALID,
   DATA_STATUS_UNAVAILABLE,
   DATA_STATUS_INVALID,
   DATA_STATUS_STALE
  };

//+------------------------------------------------------------------+
//| Self-contained account snapshot (spec v1.0, fields unchanged)    |
//|                                                                  |
//| Sentinels written by AccountSnapshotReset() before every         |
//| collection ("not collected" - never a valid account value):      |
//|   login           -1                                             |
//|   every double    NaN  (always rejected by MathIsValidNumber)    |
//|   leverage        -1                                             |
//|   margin_mode     -1   (not an ENUM_ACCOUNT_MARGIN_MODE value)   |
//|   strings         ""                                             |
//|   flags           false                                          |
//|   server_time     0    (spec: 0 when server time is unavailable) |
//|   collection_time 0    (set to TimeLocal() when an attempt runs) |
//|   data_status     DATA_STATUS_UNAVAILABLE                        |
//|   error_message   "NOT_COLLECTED"                                |
//|                                                                  |
//| Field values are meaningful only when data_status is VALID, or   |
//| STALE for an explicitly marked historical copy.                  |
//+------------------------------------------------------------------+
struct AccountSnapshot
  {
   long              login;
   string            server;
   string            company;
   string            currency;

   double            balance;
   double            equity;
   double            profit;
   double            credit;
   double            margin;
   double            free_margin;
   double            margin_level;

   long              leverage;
   long              margin_mode;

   bool              trade_allowed;
   bool              expert_allowed;

   datetime          server_time;
   datetime          collection_time;

   ENUM_DATA_STATUS  data_status;

   string            error_message;
  };

//--- documented sentinels (see the table above)
#define RM_SENTINEL_LOGIN          (-1)
#define RM_SENTINEL_LEVERAGE       (-1)
#define RM_SENTINEL_MARGIN_MODE    (-1)
#define RM_MSG_NOT_COLLECTED       "NOT_COLLECTED"

//+------------------------------------------------------------------+
//| NaN sentinel for doubles.                                        |
//| MQL5 documentation: MathSqrt of a negative value returns NaN.    |
//+------------------------------------------------------------------+
double AccountModelNaN()
  {
   double negative_one=-1.0;
   return(MathSqrt(negative_one));
  }

//+------------------------------------------------------------------+
//| Reset every field to its documented sentinel.                    |
//| Called at the start of every collection, so no value can ever    |
//| be carried over from a previous snapshot.                        |
//+------------------------------------------------------------------+
void AccountSnapshotReset(AccountSnapshot &snapshot)
  {
   double nan_value=AccountModelNaN();

   snapshot.login=RM_SENTINEL_LOGIN;
   snapshot.server="";
   snapshot.company="";
   snapshot.currency="";

   snapshot.balance=nan_value;
   snapshot.equity=nan_value;
   snapshot.profit=nan_value;
   snapshot.credit=nan_value;
   snapshot.margin=nan_value;
   snapshot.free_margin=nan_value;
   snapshot.margin_level=nan_value;

   snapshot.leverage=RM_SENTINEL_LEVERAGE;
   snapshot.margin_mode=RM_SENTINEL_MARGIN_MODE;

   snapshot.trade_allowed=false;
   snapshot.expert_allowed=false;

   snapshot.server_time=0;
   snapshot.collection_time=0;

   snapshot.data_status=DATA_STATUS_UNAVAILABLE;

   snapshot.error_message=RM_MSG_NOT_COLLECTED;
  }

//+------------------------------------------------------------------+
//| Field-by-field copy (does not rely on assignment semantics of    |
//| structures that contain strings).                                |
//+------------------------------------------------------------------+
void AccountSnapshotCopy(const AccountSnapshot &source,AccountSnapshot &target)
  {
   target.login=source.login;
   target.server=source.server;
   target.company=source.company;
   target.currency=source.currency;

   target.balance=source.balance;
   target.equity=source.equity;
   target.profit=source.profit;
   target.credit=source.credit;
   target.margin=source.margin;
   target.free_margin=source.free_margin;
   target.margin_level=source.margin_level;

   target.leverage=source.leverage;
   target.margin_mode=source.margin_mode;

   target.trade_allowed=source.trade_allowed;
   target.expert_allowed=source.expert_allowed;

   target.server_time=source.server_time;
   target.collection_time=source.collection_time;

   target.data_status=source.data_status;

   target.error_message=source.error_message;
  }

//+------------------------------------------------------------------+
//| Text helpers (display only - stored values are never rounded)    |
//+------------------------------------------------------------------+
string DataStatusToString(const ENUM_DATA_STATUS status)
  {
   switch(status)
     {
      case DATA_STATUS_VALID:
         return("VALID");
      case DATA_STATUS_UNAVAILABLE:
         return("UNAVAILABLE");
      case DATA_STATUS_INVALID:
         return("INVALID");
      case DATA_STATUS_STALE:
         return("STALE");
     }
   return("UNKNOWN");
  }

string AccountModelBoolToString(const bool value)
  {
   if(value)
      return("true");
   return("false");
  }

//--- up to 8 decimals, trailing zeros removed (at least 2 decimals kept)
string AccountModelFormatDouble(const double value)
  {
   if(!MathIsValidNumber(value))
      return("NaN/Inf");
   string text=DoubleToString(value,8);
   int dot=StringFind(text,".");
   if(dot<0)
      return(text);
   int keep=StringLen(text);
   int minimum=dot+3;
   while(keep>minimum && StringGetCharacter(text,keep-1)=='0')
      keep--;
   return(StringSubstr(text,0,keep));
  }

string AccountModelFormatTime(const datetime value)
  {
   if(value<=0)
      return("0");
   return(TimeToString(value,TIME_DATE|TIME_SECONDS));
  }

//--- compared with the named constants: their numeric values are not documented
string AccountModelMarginModeToString(const long margin_mode)
  {
   if(margin_mode==(long)ACCOUNT_MARGIN_MODE_RETAIL_NETTING)
      return("RETAIL_NETTING");
   if(margin_mode==(long)ACCOUNT_MARGIN_MODE_EXCHANGE)
      return("EXCHANGE");
   if(margin_mode==(long)ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
      return("RETAIL_HEDGING");
   return("UNKNOWN("+IntegerToString(margin_mode)+")");
  }

//--- identity only: login, server, currency, company (no credentials exist in the snapshot)
string AccountSnapshotIdentityToString(const AccountSnapshot &snapshot)
  {
   return("login="+IntegerToString(snapshot.login)
          +" server=\""+snapshot.server+"\""
          +" currency=\""+snapshot.currency+"\""
          +" company=\""+snapshot.company+"\"");
  }

//--- every field; used only by DEBUG logging
string AccountSnapshotToString(const AccountSnapshot &snapshot)
  {
   return("status="+DataStatusToString(snapshot.data_status)
          +" "+AccountSnapshotIdentityToString(snapshot)
          +" balance="+AccountModelFormatDouble(snapshot.balance)
          +" equity="+AccountModelFormatDouble(snapshot.equity)
          +" profit="+AccountModelFormatDouble(snapshot.profit)
          +" credit="+AccountModelFormatDouble(snapshot.credit)
          +" margin="+AccountModelFormatDouble(snapshot.margin)
          +" free_margin="+AccountModelFormatDouble(snapshot.free_margin)
          +" margin_level="+AccountModelFormatDouble(snapshot.margin_level)
          +" leverage="+IntegerToString(snapshot.leverage)
          +" margin_mode="+AccountModelMarginModeToString(snapshot.margin_mode)
          +" trade_allowed="+AccountModelBoolToString(snapshot.trade_allowed)
          +" expert_allowed="+AccountModelBoolToString(snapshot.expert_allowed)
          +" server_time="+AccountModelFormatTime(snapshot.server_time)
          +" collection_time="+AccountModelFormatTime(snapshot.collection_time));
  }

#endif // RISKMANAGEMENT_MODELS_ACCOUNTMODEL_MQH
//+------------------------------------------------------------------+
