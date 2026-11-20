//+------------------------------------------------------------------+
//|                                      RiskManagement_M1_Tests.mq5 |
//|                    EA Risk Management - M1 Core & Account Engine |
//|                                                                  |
//| Test harness (Expert Advisor form).                              |
//| All tests use CFakeAccountDataSource, a controlled test double:  |
//| the harness NEVER reads the real account and performs NO trading |
//| operation. It can be attached to any chart (demo or real).       |
//|                                                                  |
//| Usage: copy the whole RiskManagement folder to MQL5/Experts,     |
//| compile this file, attach "RiskManagement_M1_Tests" to a chart.  |
//| Results are printed to the Experts tab as "[RM-TEST] ..." lines; |
//| the harness then removes itself (ExpertRemove).                  |
//|                                                                  |
//| N01-N14 test the Telegram add-on with a fake HTTP transport (no  |
//| network request is made).                                        |
//| Not covered here: F026 (EventSetTimer failure cannot be forced   |
//| inside MT5) and F030 (static read-only audit, see Tools/).       |
//+------------------------------------------------------------------+
#property copyright "EA Risk Management"
#property version   "1.00"
#property description "M1 test harness - simulated data only, no account reads, no trading."

#include "../Include/Models/AccountModel.mqh"
#include "../Include/Utils/Logger.mqh"
#include "../Include/Validation/DataValidator.mqh"
#include "../Include/Core/AccountEngine.mqh"
#include "../Include/Core/CoreEngine.mqh"
#include "../Include/Notify/TelegramNotifier.mqh"

#define RM_TEST_SERVER_TIME  ((datetime)1795082400)   // 2026.11.19 10:00:00 simulated trade server time
#define RM_TEST_LOCAL_TIME   ((datetime)1795107600)   // 2026.11.19 17:00:00 simulated local time (differs on purpose)
#define RM_TEST_API_ERROR    4001                     // simulated GetLastError() code
#define RM_TEST_UNSUPPORTED  4003                     // property not served by the test double

//+------------------------------------------------------------------+
//| Controlled test double                                           |
//+------------------------------------------------------------------+
class CFakeAccountDataSource : public CAccountDataSource
  {
public:
   bool              connected;
   int               connected_error;
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
   long              trade_allowed;
   long              trade_expert;
   datetime          server_time;
   int               server_time_error;
   datetime          local_time;
   string            fail_property;      // EnumToString() name of a property whose read fails
   int               fail_error;
   int               collection_count;   // number of collections started (connection reads)
   int               account_reads;      // number of AccountInfo* reads

                     CFakeAccountDataSource()
     {
      SetHealthyAccount();
     }

   //--- values are deliberately NOT internally consistent:
   //--- equity != balance + profit, free margin != equity - margin,
   //--- margin level != equity / margin * 100 (proves nothing is derived)
   void              SetHealthyAccount()
     {
      connected=true;
      connected_error=0;
      login=12345678;
      server="Exness-MT5Real8";
      company="Exness Technologies Ltd";
      currency="USD";
      balance=1000.00;
      equity=1013.75;
      profit=12.50;
      credit=25.00;
      margin=50.00;
      free_margin=960.00;
      margin_level=2027.25;
      leverage=500;
      margin_mode=(long)ACCOUNT_MARGIN_MODE_RETAIL_HEDGING;
      trade_allowed=1;
      trade_expert=1;
      server_time=RM_TEST_SERVER_TIME;
      server_time_error=0;
      local_time=RM_TEST_LOCAL_TIME;
      fail_property="";
      fail_error=0;
      collection_count=0;
      account_reads=0;
     }

   virtual bool      ReadTerminalConnected(bool &value,int &error_code)
     {
      collection_count++;
      value=connected;
      error_code=connected_error;
      return(connected_error==0);
     }

   virtual bool      ReadInteger(const ENUM_ACCOUNT_INFO_INTEGER property_id,long &value,int &error_code)
     {
      account_reads++;
      value=0;
      error_code=0;
      if(fail_property==EnumToString(property_id))
        {
         error_code=fail_error;
         return(false);
        }
      if(property_id==ACCOUNT_LOGIN)
        {
         value=login;
         return(true);
        }
      if(property_id==ACCOUNT_LEVERAGE)
        {
         value=leverage;
         return(true);
        }
      if(property_id==ACCOUNT_MARGIN_MODE)
        {
         value=margin_mode;
         return(true);
        }
      if(property_id==ACCOUNT_TRADE_ALLOWED)
        {
         value=trade_allowed;
         return(true);
        }
      if(property_id==ACCOUNT_TRADE_EXPERT)
        {
         value=trade_expert;
         return(true);
        }
      error_code=RM_TEST_UNSUPPORTED;
      return(false);
     }

   virtual bool      ReadDouble(const ENUM_ACCOUNT_INFO_DOUBLE property_id,double &value,int &error_code)
     {
      account_reads++;
      value=0.0;
      error_code=0;
      if(fail_property==EnumToString(property_id))
        {
         error_code=fail_error;
         return(false);
        }
      if(property_id==ACCOUNT_BALANCE)
        {
         value=balance;
         return(true);
        }
      if(property_id==ACCOUNT_EQUITY)
        {
         value=equity;
         return(true);
        }
      if(property_id==ACCOUNT_PROFIT)
        {
         value=profit;
         return(true);
        }
      if(property_id==ACCOUNT_CREDIT)
        {
         value=credit;
         return(true);
        }
      if(property_id==ACCOUNT_MARGIN)
        {
         value=margin;
         return(true);
        }
      if(property_id==ACCOUNT_MARGIN_FREE)
        {
         value=free_margin;
         return(true);
        }
      if(property_id==ACCOUNT_MARGIN_LEVEL)
        {
         value=margin_level;
         return(true);
        }
      error_code=RM_TEST_UNSUPPORTED;
      return(false);
     }

   virtual bool      ReadString(const ENUM_ACCOUNT_INFO_STRING property_id,string &value,int &error_code)
     {
      account_reads++;
      value="";
      error_code=0;
      if(fail_property==EnumToString(property_id))
        {
         error_code=fail_error;
         return(false);
        }
      if(property_id==ACCOUNT_SERVER)
        {
         value=server;
         return(true);
        }
      if(property_id==ACCOUNT_COMPANY)
        {
         value=company;
         return(true);
        }
      if(property_id==ACCOUNT_CURRENCY)
        {
         value=currency;
         return(true);
        }
      error_code=RM_TEST_UNSUPPORTED;
      return(false);
     }

   virtual bool      ReadTradeServerTime(datetime &value,int &error_code)
     {
      value=server_time;
      error_code=server_time_error;
      return(server_time_error==0 && server_time>0);
     }

   virtual bool      ReadLocalTime(datetime &value,int &error_code)
     {
      value=local_time;
      error_code=0;
      return(local_time>0);
     }
  };

//+------------------------------------------------------------------+
//| Controlled HTTP test double (no network)                         |
//+------------------------------------------------------------------+
class CFakeHttpTransport : public CHttpTransport
  {
public:
   int               status_to_return;
   int               error_to_return;
   string            response_to_return;
   int               calls;
   string            last_url;
   string            last_body;
   int               last_timeout;

                     CFakeHttpTransport()
     {
      SetOk();
      calls=0;
      last_url="";
      last_body="";
      last_timeout=0;
     }

   void              SetOk()
     {
      status_to_return=200;
      error_to_return=0;
      response_to_return="{\"ok\":true,\"result\":{\"message_id\":1}}";
     }

   void              SetResult(const int status,const int error_code,const string response)
     {
      status_to_return=status;
      error_to_return=error_code;
      response_to_return=response;
     }

   virtual int       PostJson(const string url,const string json_body,const int timeout_ms,
                              string &response_body,int &error_code)
     {
      calls++;
      last_url=url;
      last_body=json_body;
      last_timeout=timeout_ms;
      response_body=response_to_return;
      error_code=error_to_return;
      return(status_to_return);
     }
  };

#define RM_TEST_TOKEN   "123456789:TESTtokenTESTtokenTESTtoken_-0123"
#define RM_TEST_CHAT_ID "123456789"

//+------------------------------------------------------------------+
//| Core engine wired to the test double and a silent logger         |
//+------------------------------------------------------------------+
class CTestFixture
  {
public:
   CFakeAccountDataSource source;
   CLogger           logger;
   CCoreEngine       core;

   bool              Setup(const bool require_connected_terminal,const bool enable_logging,const bool enable_debug_logging)
     {
      RiskManagementConfig config;
      config.account_refresh_seconds=1;
      config.enable_logging=enable_logging;
      config.enable_debug_logging=enable_debug_logging;
      config.require_connected_terminal=require_connected_terminal;
      logger.Configure(enable_logging,enable_debug_logging);
      logger.SetSilent(true);
      logger.ResetCounters();
      core.SetDataSource(GetPointer(source));
      if(!core.Configure(config,GetPointer(logger)))
         return(false);
      return(core.Initialize());
     }

   int               Count(const ENUM_RM_LOG_EVENT event_id)
     {
      return(logger.GetEventCount(event_id));
     }

   void              RefreshTimes(const int cycles)
     {
      for(int i=0; i<cycles; i++)
         core.Refresh();
     }
  };

//+------------------------------------------------------------------+
//| Telegram notifier wired to the fake transport (optionally to a   |
//| core engine fixture)                                             |
//+------------------------------------------------------------------+
class CTelegramFixture
  {
public:
   CFakeHttpTransport transport;
   CLogger           logger;
   CTelegramNotifier notifier;

   bool              Setup()
     {
      logger.Configure(true,false);
      logger.SetSilent(true);
      logger.ResetCounters();
      notifier.SetTransport(GetPointer(transport));
      if(!notifier.Configure(true,RM_TEST_TOKEN,RM_TEST_CHAT_ID,4000,GetPointer(logger)))
         return(false);
      return(notifier.Initialize());
     }
  };

//+------------------------------------------------------------------+
//| Minimal test framework                                           |
//+------------------------------------------------------------------+
int    g_tests_total=0;
int    g_tests_passed=0;
int    g_tests_failed=0;
int    g_tests_not_run=0;
string g_test_id="";
string g_test_title="";
int    g_test_checks=0;
int    g_test_check_failures=0;

void TestBegin(const string test_id,const string title)
  {
   g_test_id=test_id;
   g_test_title=title;
   g_test_checks=0;
   g_test_check_failures=0;
  }

void Check(const bool condition,const string description)
  {
   g_test_checks++;
   if(condition)
      return;
   g_test_check_failures++;
   Print("[RM-TEST]   check failed in "+g_test_id+": "+description);
  }

void TestEnd()
  {
   g_tests_total++;
   if(g_test_check_failures==0 && g_test_checks>0)
     {
      g_tests_passed++;
      Print("[RM-TEST] PASS "+g_test_id+" - "+g_test_title+" ("+IntegerToString(g_test_checks)+" checks)");
      return;
     }
   g_tests_failed++;
   Print("[RM-TEST] FAIL "+g_test_id+" - "+g_test_title+" ("+IntegerToString(g_test_check_failures)
         +" of "+IntegerToString(g_test_checks)+" checks failed)");
  }

void TestNotRun(const string test_id,const string title,const string reason)
  {
   g_tests_total++;
   g_tests_not_run++;
   Print("[RM-TEST] NOT RUN "+test_id+" - "+title+": "+reason);
  }

bool Contains(const string text,const string part)
  {
   return(StringFind(text,part)>=0);
  }

//--- MQL5 documentation: MathExp overflow returns INF
double TestPositiveInfinity()
  {
   double large_exponent=1000.0;
   return(MathExp(large_exponent));
  }

double TestNegativeInfinity()
  {
   return(-TestPositiveInfinity());
  }

bool SameDouble(const double a,const double b)
  {
   if(a==b)
      return(true);
   return(!MathIsValidNumber(a) && !MathIsValidNumber(b));
  }

bool SameSnapshot(const AccountSnapshot &a,const AccountSnapshot &b)
  {
   return(a.login==b.login && a.server==b.server && a.company==b.company && a.currency==b.currency
          && SameDouble(a.balance,b.balance) && SameDouble(a.equity,b.equity) && SameDouble(a.profit,b.profit)
          && SameDouble(a.credit,b.credit) && SameDouble(a.margin,b.margin)
          && SameDouble(a.free_margin,b.free_margin) && SameDouble(a.margin_level,b.margin_level)
          && a.leverage==b.leverage && a.margin_mode==b.margin_mode
          && a.trade_allowed==b.trade_allowed && a.expert_allowed==b.expert_allowed
          && a.server_time==b.server_time && a.collection_time==b.collection_time
          && a.data_status==b.data_status && a.error_message==b.error_message);
  }

//--- a snapshot that passes every validation rule
void MakeValidSnapshot(AccountSnapshot &snapshot)
  {
   AccountSnapshotReset(snapshot);
   snapshot.login=12345678;
   snapshot.server="Exness-MT5Real8";
   snapshot.company="Exness Technologies Ltd";
   snapshot.currency="USD";
   snapshot.balance=1000.00;
   snapshot.equity=1013.75;
   snapshot.profit=12.50;
   snapshot.credit=25.00;
   snapshot.margin=50.00;
   snapshot.free_margin=960.00;
   snapshot.margin_level=2027.25;
   snapshot.leverage=500;
   snapshot.margin_mode=(long)ACCOUNT_MARGIN_MODE_RETAIL_HEDGING;
   snapshot.trade_allowed=true;
   snapshot.expert_allowed=true;
   snapshot.server_time=RM_TEST_SERVER_TIME;
   snapshot.collection_time=RM_TEST_LOCAL_TIME;
  }

//--- one refresh, then read the snapshot (true only when current and VALID)
bool RefreshAndGet(CTestFixture &fx,AccountSnapshot &snapshot)
  {
   fx.core.Refresh();
   return(fx.core.GetLatestSnapshot(snapshot));
  }

//--- index helpers for the 7 financial values
string DoublePropertyName(const int index)
  {
   if(index==0)
      return("ACCOUNT_BALANCE");
   if(index==1)
      return("ACCOUNT_EQUITY");
   if(index==2)
      return("ACCOUNT_PROFIT");
   if(index==3)
      return("ACCOUNT_CREDIT");
   if(index==4)
      return("ACCOUNT_MARGIN");
   if(index==5)
      return("ACCOUNT_MARGIN_FREE");
   return("ACCOUNT_MARGIN_LEVEL");
  }

void SetSourceDouble(CFakeAccountDataSource &source,const int index,const double value)
  {
   if(index==0)
      source.balance=value;
   if(index==1)
      source.equity=value;
   if(index==2)
      source.profit=value;
   if(index==3)
      source.credit=value;
   if(index==4)
      source.margin=value;
   if(index==5)
      source.free_margin=value;
   if(index==6)
      source.margin_level=value;
  }

//+------------------------------------------------------------------+
//| F001 - F030                                                      |
//+------------------------------------------------------------------+
void Test_F001()
  {
   TestBegin("F001","Valid account initialization");
   CTestFixture fx;
   Check(fx.Setup(true,true,false),"core configured and initialized");
   AccountSnapshot snapshot;
   bool current=RefreshAndGet(fx,snapshot);
   Check(fx.core.GetCurrentStatus()==DATA_STATUS_VALID,"current status is VALID");
   Check(current,"GetLatestSnapshot returns true");
   Check(snapshot.data_status==DATA_STATUS_VALID,"snapshot status is VALID");
   Check(snapshot.error_message=="","no error message on a VALID snapshot");
   Check(fx.core.GetLastSuccessfulCollectionTime()==RM_TEST_LOCAL_TIME,"last successful collection time = TimeLocal() of the cycle");
   Check(fx.Count(RM_EVENT_ACCOUNT_COLLECTION_SUCCESS)==1,"exactly one ACCOUNT_COLLECTION_SUCCESS line");
   Check(fx.Count(RM_EVENT_ACCOUNT_COLLECTION_FAILED)==0,"no ACCOUNT_COLLECTION_FAILED line");
   Check(Contains(fx.logger.GetLastLine(),"identity baseline locked"),"identity baseline is logged");
   Check(Contains(fx.logger.GetLastLine(),"login=12345678"),"logged identity contains the login");
   TestEnd();
  }

void Test_F002()
  {
   TestBegin("F002","Login collected exactly (ACCOUNT_LOGIN > 0)");
   CTestFixture fx;
   fx.source.login=87654321;
   Check(fx.Setup(true,true,false),"setup");
   AccountSnapshot snapshot;
   Check(RefreshAndGet(fx,snapshot),"snapshot is current");
   Check(snapshot.login==87654321,"login equals the terminal value");

   CTestFixture bad;
   bad.source.login=0;
   Check(bad.Setup(true,true,false),"setup (login 0)");
   AccountSnapshot rejected;
   Check(!RefreshAndGet(bad,rejected),"login 0 is never published as current");
   Check(bad.core.GetCurrentStatus()==DATA_STATUS_INVALID,"login 0 -> INVALID");
   Check(Contains(rejected.error_message,"ACCOUNT_LOGIN"),"error names ACCOUNT_LOGIN");
   TestEnd();
  }

void Test_F003()
  {
   TestBegin("F003","Server collected exactly (not empty)");
   CTestFixture fx;
   fx.source.server="Exness-MT5Real17";
   Check(fx.Setup(true,true,false),"setup");
   AccountSnapshot snapshot;
   Check(RefreshAndGet(fx,snapshot),"snapshot is current");
   Check(snapshot.server=="Exness-MT5Real17","server equals the terminal value");

   CTestFixture empty;
   empty.source.server="";
   Check(empty.Setup(true,true,false),"setup (empty server)");
   AccountSnapshot rejected;
   Check(!RefreshAndGet(empty,rejected),"empty server is never published as current");
   Check(empty.core.GetCurrentStatus()==DATA_STATUS_INVALID,"empty server -> INVALID");
   Check(Contains(rejected.error_message,"ACCOUNT_SERVER"),"error names ACCOUNT_SERVER");

   CTestFixture blank;
   blank.source.server="   ";
   Check(blank.Setup(true,true,false),"setup (blank server)");
   blank.core.Refresh();
   Check(blank.core.GetCurrentStatus()==DATA_STATUS_INVALID,"whitespace-only server -> INVALID");
   TestEnd();
  }

void Test_F004()
  {
   TestBegin("F004","Currency collected exactly (not empty; company may be empty)");
   CTestFixture fx;
   fx.source.currency="USC";
   fx.source.company="";
   Check(fx.Setup(true,true,false),"setup");
   AccountSnapshot snapshot;
   Check(RefreshAndGet(fx,snapshot),"snapshot is current (empty company allowed)");
   Check(snapshot.currency=="USC","currency equals the terminal value");
   Check(snapshot.company=="","empty company kept as collected");

   CTestFixture empty;
   empty.source.currency="";
   Check(empty.Setup(true,true,false),"setup (empty currency)");
   AccountSnapshot rejected;
   Check(!RefreshAndGet(empty,rejected),"empty currency is never published as current");
   Check(empty.core.GetCurrentStatus()==DATA_STATUS_INVALID,"empty currency -> INVALID");
   Check(Contains(rejected.error_message,"ACCOUNT_CURRENCY"),"error names ACCOUNT_CURRENCY");
   TestEnd();
  }

void Test_F005()
  {
   TestBegin("F005","Balance collected exactly");
   CTestFixture fx;
   fx.source.balance=1234.56789;
   Check(fx.Setup(true,true,false),"setup");
   AccountSnapshot snapshot;
   Check(RefreshAndGet(fx,snapshot),"snapshot is current");
   Check(snapshot.balance==1234.56789,"balance equals the terminal value (no rounding)");
   TestEnd();
  }

void Test_F006()
  {
   TestBegin("F006","Equity collected exactly, never derived from balance + profit");
   CTestFixture fx;
   Check(fx.Setup(true,true,false),"setup");
   AccountSnapshot snapshot;
   Check(RefreshAndGet(fx,snapshot),"snapshot is current");
   Check(snapshot.equity==1013.75,"equity equals the terminal value");
   Check(snapshot.equity!=snapshot.balance+snapshot.profit,"equity is not balance + profit");
   TestEnd();
  }

void Test_F007()
  {
   TestBegin("F007","Floating profit collected exactly");
   CTestFixture fx;
   fx.source.profit=-37.25;
   Check(fx.Setup(true,true,false),"setup");
   AccountSnapshot snapshot;
   Check(RefreshAndGet(fx,snapshot),"snapshot is current");
   Check(snapshot.profit==-37.25,"profit equals the terminal value");
   TestEnd();
  }

void Test_F008()
  {
   TestBegin("F008","Credit collected exactly (any sign)");
   CTestFixture fx;
   fx.source.credit=25.00;
   Check(fx.Setup(true,true,false),"setup");
   AccountSnapshot snapshot;
   Check(RefreshAndGet(fx,snapshot),"snapshot is current");
   Check(snapshot.credit==25.00,"credit equals the terminal value");

   CTestFixture negative;
   negative.source.credit=-5.00;
   Check(negative.Setup(true,true,false),"setup (negative credit)");
   AccountSnapshot accepted;
   Check(RefreshAndGet(negative,accepted),"negative credit is accepted");
   Check(accepted.credit==-5.00,"negative credit kept as collected");
   TestEnd();
  }

void Test_F009()
  {
   TestBegin("F009","Margin collected exactly");
   CTestFixture fx;
   fx.source.margin=75.125;
   Check(fx.Setup(true,true,false),"setup");
   AccountSnapshot snapshot;
   Check(RefreshAndGet(fx,snapshot),"snapshot is current");
   Check(snapshot.margin==75.125,"margin equals the terminal value");
   TestEnd();
  }

void Test_F010()
  {
   TestBegin("F010","Free margin collected exactly, never derived from equity - margin");
   CTestFixture fx;
   Check(fx.Setup(true,true,false),"setup");
   AccountSnapshot snapshot;
   Check(RefreshAndGet(fx,snapshot),"snapshot is current");
   Check(snapshot.free_margin==960.00,"free margin equals the terminal value");
   Check(snapshot.free_margin!=snapshot.equity-snapshot.margin,"free margin is not equity - margin");
   TestEnd();
  }

void Test_F011()
  {
   TestBegin("F011","Margin level collected exactly, never derived");
   CTestFixture fx;
   Check(fx.Setup(true,true,false),"setup");
   AccountSnapshot snapshot;
   Check(RefreshAndGet(fx,snapshot),"snapshot is current");
   Check(snapshot.margin_level==2027.25,"margin level equals the terminal value");
   Check(snapshot.margin_level!=snapshot.equity/snapshot.margin*100.0,"margin level is not equity / margin * 100");
   TestEnd();
  }

void Test_F012()
  {
   TestBegin("F012","Leverage collected exactly (must be > 0)");
   CTestFixture fx;
   fx.source.leverage=2000;
   Check(fx.Setup(true,true,false),"setup");
   AccountSnapshot snapshot;
   Check(RefreshAndGet(fx,snapshot),"snapshot is current");
   Check(snapshot.leverage==2000,"leverage equals the terminal value");

   CTestFixture zero;
   zero.source.leverage=0;
   Check(zero.Setup(true,true,false),"setup (leverage 0)");
   AccountSnapshot rejected;
   Check(!RefreshAndGet(zero,rejected),"leverage 0 is never published as current");
   Check(zero.core.GetCurrentStatus()==DATA_STATUS_INVALID,"leverage 0 -> INVALID");
   Check(Contains(rejected.error_message,"ACCOUNT_LEVERAGE"),"error names ACCOUNT_LEVERAGE");

   CTestFixture negative;
   negative.source.leverage=-1;
   Check(negative.Setup(true,true,false),"setup (leverage -1)");
   negative.core.Refresh();
   Check(negative.core.GetCurrentStatus()==DATA_STATUS_INVALID,"negative leverage -> INVALID");

   CTestFixture large;
   large.source.leverage=2000000000;
   Check(large.Setup(true,true,false),"setup (very large leverage)");
   AccountSnapshot accepted;
   Check(RefreshAndGet(large,accepted),"very large positive leverage is accepted");
   TestEnd();
  }

void Test_F013()
  {
   TestBegin("F013","Margin mode collected exactly (supported ENUM_ACCOUNT_MARGIN_MODE only)");
   CTestFixture hedging;
   hedging.source.margin_mode=(long)ACCOUNT_MARGIN_MODE_RETAIL_HEDGING;
   Check(hedging.Setup(true,true,false),"setup (hedging)");
   AccountSnapshot snapshot;
   Check(RefreshAndGet(hedging,snapshot),"hedging accepted");
   Check(snapshot.margin_mode==(long)ACCOUNT_MARGIN_MODE_RETAIL_HEDGING,"hedging mode equals the terminal value");

   CTestFixture netting;
   netting.source.margin_mode=(long)ACCOUNT_MARGIN_MODE_RETAIL_NETTING;
   Check(netting.Setup(true,true,false),"setup (netting)");
   AccountSnapshot netting_snapshot;
   Check(RefreshAndGet(netting,netting_snapshot),"netting accepted");
   Check(netting_snapshot.margin_mode==(long)ACCOUNT_MARGIN_MODE_RETAIL_NETTING,"netting mode equals the terminal value");

   CTestFixture exchange;
   exchange.source.margin_mode=(long)ACCOUNT_MARGIN_MODE_EXCHANGE;
   Check(exchange.Setup(true,true,false),"setup (exchange)");
   AccountSnapshot exchange_snapshot;
   Check(RefreshAndGet(exchange,exchange_snapshot),"exchange accepted");

   CTestFixture unknown;
   unknown.source.margin_mode=77;
   Check(unknown.Setup(true,true,false),"setup (unknown mode)");
   AccountSnapshot rejected;
   Check(!RefreshAndGet(unknown,rejected),"unknown margin mode is never published as current");
   Check(unknown.core.GetCurrentStatus()==DATA_STATUS_INVALID,"unknown margin mode -> INVALID");
   Check(Contains(rejected.error_message,"ACCOUNT_MARGIN_MODE"),"error names ACCOUNT_MARGIN_MODE");
   TestEnd();
  }

void Test_F014()
  {
   TestBegin("F014","Permission flags collected exactly (descriptive only)");
   CTestFixture fx;
   fx.source.trade_allowed=1;
   fx.source.trade_expert=0;
   Check(fx.Setup(true,true,false),"setup");
   AccountSnapshot snapshot;
   Check(RefreshAndGet(fx,snapshot),"snapshot is current with expert trading disabled");
   Check(snapshot.trade_allowed,"trade_allowed = true");
   Check(!snapshot.expert_allowed,"expert_allowed = false");

   CTestFixture other;
   other.source.trade_allowed=0;
   other.source.trade_expert=1;
   Check(other.Setup(true,true,false),"setup (account trading disabled)");
   AccountSnapshot other_snapshot;
   Check(RefreshAndGet(other,other_snapshot),"snapshot is current with account trading disabled");
   Check(!other_snapshot.trade_allowed,"trade_allowed = false");
   Check(other_snapshot.expert_allowed,"expert_allowed = true");
   TestEnd();
  }

void Test_F015()
  {
   TestBegin("F015","Refresh interval accepted and exactly one collection per refresh (timer cadence: MT5 manual)");
   RiskManagementConfig config;
   config.enable_logging=true;
   config.enable_debug_logging=false;
   config.require_connected_terminal=true;
   string error_message="";
   config.account_refresh_seconds=1;
   Check(RMValidateConfig(config,error_message),"1 s accepted");
   config.account_refresh_seconds=5;
   Check(RMValidateConfig(config,error_message),"5 s accepted");
   config.account_refresh_seconds=3600;
   Check(RMValidateConfig(config,error_message),"3600 s accepted");

   CTestFixture fx;
   Check(fx.Setup(true,true,false),"setup");
   fx.RefreshTimes(3);
   Check(fx.source.collection_count==3,"three refreshes -> exactly three collections");
   TestEnd();
  }

void Test_F016()
  {
   TestBegin("F016","Invalid refresh interval rejected (no silent default)");
   RiskManagementConfig config;
   config.enable_logging=true;
   config.enable_debug_logging=false;
   config.require_connected_terminal=true;
   string error_message="";
   config.account_refresh_seconds=0;
   Check(!RMValidateConfig(config,error_message),"0 s rejected");
   Check(Contains(error_message,"InpAccountRefreshSeconds"),"message names InpAccountRefreshSeconds");
   config.account_refresh_seconds=-5;
   Check(!RMValidateConfig(config,error_message),"-5 s rejected");

   CLogger logger;
   logger.SetSilent(true);
   CCoreEngine core;
   config.account_refresh_seconds=0;
   Check(!core.Configure(config,GetPointer(logger)),"core refuses the invalid configuration");
   Check(!core.Initialize(),"core cannot be initialized after a rejected configuration");
   TestEnd();
  }

void Test_F017()
  {
   TestBegin("F017","Terminal disconnect -> UNAVAILABLE, logged once, no account reads");
   CTestFixture fx;
   Check(fx.Setup(true,true,false),"setup");
   fx.core.Refresh();
   Check(fx.core.GetCurrentStatus()==DATA_STATUS_VALID,"VALID before the disconnect");
   fx.source.connected=false;
   int reads_before=fx.source.account_reads;
   fx.RefreshTimes(5);
   Check(fx.core.GetCurrentStatus()==DATA_STATUS_UNAVAILABLE,"UNAVAILABLE while disconnected");
   Check(fx.source.account_reads==reads_before,"no AccountInfo* read while the required connection is missing");
   Check(fx.Count(RM_EVENT_TERMINAL_DISCONNECTED)==1,"TERMINAL_DISCONNECTED logged once for 5 cycles");
   Check(fx.Count(RM_EVENT_ACCOUNT_COLLECTION_FAILED)==1,"ACCOUNT_COLLECTION_FAILED logged once for 5 cycles");
   Check(fx.logger.GetLevelCount(RM_LOG_ERROR)==0,"a disconnect is a WARNING, not an ERROR");
   AccountSnapshot snapshot;
   Check(!fx.core.GetLatestSnapshot(snapshot),"old snapshot not returned as current");
   Check(snapshot.data_status==DATA_STATUS_STALE,"returned copy is marked STALE");
   Check(Contains(snapshot.error_message,"TERMINAL_DISCONNECTED"),"reason names the disconnect");
   TestEnd();
  }

void Test_F018()
  {
   TestBegin("F018","Terminal reconnect -> VALID again, logged once");
   CTestFixture fx;
   Check(fx.Setup(true,true,false),"setup");
   fx.core.Refresh();
   fx.source.connected=false;
   fx.RefreshTimes(3);
   fx.source.connected=true;
   fx.RefreshTimes(4);
   Check(fx.core.GetCurrentStatus()==DATA_STATUS_VALID,"VALID after the reconnect");
   Check(fx.Count(RM_EVENT_TERMINAL_RECONNECTED)==1,"TERMINAL_RECONNECTED logged once");
   Check(fx.Count(RM_EVENT_ACCOUNT_COLLECTION_SUCCESS)==2,"success logged twice: first snapshot + recovery");
   Check(Contains(fx.logger.GetLastLine(),"recovered after 3 failed cycle(s)"),"recovery line reports the failed cycles");
   AccountSnapshot snapshot;
   Check(fx.core.GetLatestSnapshot(snapshot),"current snapshot available again");
   TestEnd();
  }

void Test_F019()
  {
   TestBegin("F019","Account identity change -> UNAVAILABLE, latched, logged once, no mixing");
   CTestFixture fx;
   Check(fx.Setup(true,true,false),"setup");
   fx.core.Refresh();
   Check(fx.core.GetCurrentStatus()==DATA_STATUS_VALID,"VALID before the change");
   fx.source.login=11112222;
   fx.core.Refresh();
   Check(fx.core.GetCurrentStatus()==DATA_STATUS_UNAVAILABLE,"identity change -> UNAVAILABLE");
   Check(fx.Count(RM_EVENT_ACCOUNT_IDENTITY_CHANGED)==1,"ACCOUNT_IDENTITY_CHANGED logged");
   int reads_after_latch=fx.source.account_reads;
   int collections_after_latch=fx.source.collection_count;
   fx.RefreshTimes(3);
   Check(fx.source.account_reads==reads_after_latch,"no account read after the latch");
   Check(fx.source.collection_count==collections_after_latch,"no collection after the latch");
   fx.source.login=12345678;
   fx.core.Refresh();
   Check(fx.core.GetCurrentStatus()==DATA_STATUS_UNAVAILABLE,"still UNAVAILABLE even if the original login returns");
   Check(fx.Count(RM_EVENT_ACCOUNT_IDENTITY_CHANGED)==1,"identity change logged only once");
   AccountSnapshot snapshot;
   Check(!fx.core.GetLatestSnapshot(snapshot),"no current snapshot after the change");
   Check(snapshot.login==12345678,"historical copy belongs to the original account");
   Check(snapshot.data_status==DATA_STATUS_STALE,"historical copy marked STALE");
   Check(Contains(snapshot.error_message,"ACCOUNT_IDENTITY_CHANGED"),"reason names the identity change");

   CTestFixture server_change;
   Check(server_change.Setup(true,true,false),"setup (server change)");
   server_change.core.Refresh();
   server_change.source.server="Exness-MT5Trial";
   server_change.core.Refresh();
   Check(server_change.core.GetCurrentStatus()==DATA_STATUS_UNAVAILABLE,"server change -> UNAVAILABLE");
   Check(server_change.Count(RM_EVENT_ACCOUNT_IDENTITY_CHANGED)==1,"server change logged");

   CTestFixture currency_change;
   Check(currency_change.Setup(true,true,false),"setup (currency change)");
   currency_change.core.Refresh();
   currency_change.source.currency="USC";
   currency_change.core.Refresh();
   Check(currency_change.core.GetCurrentStatus()==DATA_STATUS_UNAVAILABLE,"currency change -> UNAVAILABLE");
   Check(currency_change.Count(RM_EVENT_ACCOUNT_IDENTITY_CHANGED)==1,"currency change logged");
   TestEnd();
  }

void Test_F020()
  {
   TestBegin("F020","Invalid financial values rejected (negative margin, negative margin level)");
   CTestFixture negative_margin;
   negative_margin.source.margin=-1.0;
   Check(negative_margin.Setup(true,true,false),"setup (negative margin)");
   AccountSnapshot rejected;
   Check(!RefreshAndGet(negative_margin,rejected),"negative margin never published as current");
   Check(negative_margin.core.GetCurrentStatus()==DATA_STATUS_INVALID,"negative margin -> INVALID");
   Check(Contains(rejected.error_message,"ACCOUNT_MARGIN must be >= 0"),"error names ACCOUNT_MARGIN");

   CTestFixture negative_level;
   negative_level.source.margin_level=-5.0;
   Check(negative_level.Setup(true,true,false),"setup (negative margin level, equity >= 0)");
   AccountSnapshot rejected_level;
   Check(!RefreshAndGet(negative_level,rejected_level),"negative margin level never published as current");
   Check(negative_level.core.GetCurrentStatus()==DATA_STATUS_INVALID,"negative margin level with margin > 0 and equity >= 0 -> INVALID");
   Check(Contains(rejected_level.error_message,"ACCOUNT_MARGIN_LEVEL"),"error names ACCOUNT_MARGIN_LEVEL");
   TestEnd();
  }

void Test_F021()
  {
   TestBegin("F021","NaN and infinity rejected for every financial value");
   for(int index=0; index<7; index++)
     {
      CTestFixture nan_case;
      SetSourceDouble(nan_case.source,index,AccountModelNaN());
      Check(nan_case.Setup(true,true,false),"setup (NaN)");
      AccountSnapshot rejected;
      Check(!RefreshAndGet(nan_case,rejected),"NaN never published as current: "+DoublePropertyName(index));
      Check(nan_case.core.GetCurrentStatus()==DATA_STATUS_INVALID,"NaN -> INVALID: "+DoublePropertyName(index));
      Check(Contains(rejected.error_message,DoublePropertyName(index)+" is not a finite number"),"error names "+DoublePropertyName(index));

      CTestFixture inf_case;
      SetSourceDouble(inf_case.source,index,TestPositiveInfinity());
      Check(inf_case.Setup(true,true,false),"setup (+Inf)");
      inf_case.core.Refresh();
      Check(inf_case.core.GetCurrentStatus()==DATA_STATUS_INVALID,"+Inf -> INVALID: "+DoublePropertyName(index));

      CTestFixture minus_inf_case;
      SetSourceDouble(minus_inf_case.source,index,TestNegativeInfinity());
      Check(minus_inf_case.Setup(true,true,false),"setup (-Inf)");
      minus_inf_case.core.Refresh();
      Check(minus_inf_case.core.GetCurrentStatus()==DATA_STATUS_INVALID,"-Inf -> INVALID: "+DoublePropertyName(index));
     }
   TestEnd();
  }

void Test_F022()
  {
   TestBegin("F022","Zero margin handled correctly (margin 0, margin level 0 -> VALID)");
   CTestFixture fx;
   fx.source.margin=0.0;
   fx.source.margin_level=0.0;
   fx.source.profit=0.0;
   fx.source.equity=1000.0;
   fx.source.free_margin=1000.0;
   Check(fx.Setup(true,true,false),"setup");
   AccountSnapshot snapshot;
   Check(RefreshAndGet(fx,snapshot),"zero margin snapshot is current");
   Check(snapshot.margin==0.0,"margin 0 kept");
   Check(snapshot.margin_level==0.0,"margin level 0 kept");
   TestEnd();
  }

void Test_F023()
  {
   TestBegin("F023","Negative floating profit accepted (no equity >= balance rule)");
   CTestFixture fx;
   fx.source.profit=-250.75;
   fx.source.equity=749.25;
   fx.source.free_margin=699.25;
   Check(fx.Setup(true,true,false),"setup");
   AccountSnapshot snapshot;
   Check(RefreshAndGet(fx,snapshot),"negative profit snapshot is current");
   Check(snapshot.profit==-250.75,"negative profit kept");
   Check(snapshot.equity<snapshot.balance,"equity below balance accepted");
   TestEnd();
  }

void Test_F024()
  {
   TestBegin("F024","Positive floating profit accepted");
   CTestFixture fx;
   fx.source.profit=310.40;
   fx.source.equity=1310.40;
   Check(fx.Setup(true,true,false),"setup");
   AccountSnapshot snapshot;
   Check(RefreshAndGet(fx,snapshot),"positive profit snapshot is current");
   Check(snapshot.profit==310.40,"positive profit kept");
   TestEnd();
  }

void Test_F025()
  {
   TestBegin("F025","Initialization failure handled (no configuration, invalid configuration)");
   CCoreEngine core;
   Check(!core.Initialize(),"Initialize() fails without Configure()");
   Check(Contains(core.GetInitializationErrorMessage(),"NOT_CONFIGURED"),"reason reported");
   core.Refresh();
   Check(core.GetCurrentStatus()==DATA_STATUS_UNAVAILABLE,"Refresh() on an uninitialized core -> UNAVAILABLE");
   AccountSnapshot snapshot;
   Check(!core.GetLatestSnapshot(snapshot),"no snapshot from an uninitialized core");
   Check(snapshot.data_status==DATA_STATUS_UNAVAILABLE,"empty snapshot is UNAVAILABLE");

   CLogger logger;
   logger.SetSilent(true);
   RiskManagementConfig config;
   config.account_refresh_seconds=0;
   config.enable_logging=true;
   config.enable_debug_logging=false;
   config.require_connected_terminal=true;
   Check(!core.Configure(config,GetPointer(logger)),"invalid configuration rejected");
   Check(Contains(core.GetInitializationErrorMessage(),"CONFIG_INVALID"),"configuration reason reported");
   TestEnd();
  }

void Test_F027()
  {
   TestBegin("F027","Safe shutdown (idempotent, nothing served afterwards)");
   CTestFixture fx;
   Check(fx.Setup(true,true,false),"setup");
   fx.core.Refresh();
   Check(fx.core.GetCurrentStatus()==DATA_STATUS_VALID,"VALID before shutdown");
   fx.core.Shutdown();
   Check(fx.core.GetCurrentStatus()==DATA_STATUS_UNAVAILABLE,"UNAVAILABLE after shutdown");
   AccountSnapshot snapshot;
   Check(!fx.core.GetLatestSnapshot(snapshot),"no snapshot after shutdown");
   Check(fx.core.GetLastSuccessfulCollectionTime()==0,"no last successful time after shutdown");
   fx.core.Shutdown();
   int collections=fx.source.collection_count;
   fx.core.Refresh();
   Check(fx.source.collection_count==collections,"Refresh() after shutdown reads nothing");
   Check(fx.core.GetCurrentStatus()==DATA_STATUS_UNAVAILABLE,"still UNAVAILABLE");
   TestEnd();
  }

void Test_F028()
  {
   TestBegin("F028","Old snapshot never presented as current after a failed collection");
   CTestFixture fx;
   Check(fx.Setup(true,true,false),"setup");
   fx.core.Refresh();
   datetime first_success=fx.core.GetLastSuccessfulCollectionTime();
   fx.source.equity=AccountModelNaN();
   fx.source.local_time=RM_TEST_LOCAL_TIME+60;
   fx.core.Refresh();
   Check(fx.core.GetCurrentStatus()==DATA_STATUS_INVALID,"latest status reports the failure (INVALID)");
   AccountSnapshot snapshot;
   Check(!fx.core.GetLatestSnapshot(snapshot),"GetLatestSnapshot returns false");
   Check(snapshot.data_status==DATA_STATUS_STALE,"returned copy is STALE");
   Check(snapshot.equity==1013.75,"last successful values are not overwritten by the failed cycle");
   Check(snapshot.collection_time==first_success,"historical copy keeps its own collection time");
   Check(fx.core.GetLastSuccessfulCollectionTime()==first_success,"last successful time unchanged");
   Check(Contains(snapshot.error_message,"HISTORICAL_SNAPSHOT"),"copy is labelled historical");
   Check(Contains(snapshot.error_message,"status=INVALID"),"copy carries the latest status");
   TestEnd();
  }

void Test_F029()
  {
   TestBegin("F029","Repeated errors do not spam the log");
   CTestFixture fx;
   Check(fx.Setup(true,true,false),"setup");
   fx.core.Refresh();
   fx.source.connected=false;
   fx.RefreshTimes(50);
   Check(fx.Count(RM_EVENT_TERMINAL_DISCONNECTED)==1,"50 disconnected cycles -> 1 TERMINAL_DISCONNECTED");
   Check(fx.Count(RM_EVENT_ACCOUNT_COLLECTION_FAILED)==1,"50 disconnected cycles -> 1 ACCOUNT_COLLECTION_FAILED");
   fx.source.connected=true;
   fx.source.equity=AccountModelNaN();
   fx.RefreshTimes(20);
   Check(fx.Count(RM_EVENT_TERMINAL_RECONNECTED)==1,"reconnect logged once");
   Check(fx.Count(RM_EVENT_ACCOUNT_COLLECTION_FAILED)==2,"a new failure reason is logged once");
   fx.RefreshTimes(30);
   Check(fx.Count(RM_EVENT_ACCOUNT_COLLECTION_FAILED)==2,"30 more identical failures -> no new line");
   fx.source.equity=1013.75;
   fx.RefreshTimes(10);
   Check(fx.Count(RM_EVENT_ACCOUNT_COLLECTION_SUCCESS)==2,"first valid + one recovery line");
   Check(fx.logger.GetTotalCount()==6,"111 cycles produced exactly 6 log lines");

   CTestFixture quiet;
   Check(quiet.Setup(true,false,false),"setup (InpEnableLogging=false)");
   quiet.source.connected=false;
   quiet.RefreshTimes(10);
   Check(quiet.logger.GetTotalCount()==0,"logging disabled: disconnect warnings suppressed");
   quiet.source.connected=true;
   quiet.source.balance=AccountModelNaN();
   quiet.RefreshTimes(10);
   Check(quiet.logger.GetTotalCount()==1,"logging disabled: the ERROR is still emitted once (Q-03)");
   Check(quiet.logger.GetLevelCount(RM_LOG_ERROR)==1,"the emitted line is an ERROR");
   TestEnd();
  }

//+------------------------------------------------------------------+
//| Additional tests T01 - T18                                       |
//+------------------------------------------------------------------+
void Test_T01()
  {
   TestBegin("T01","Snapshot reset writes the documented sentinels (never 0 for numbers)");
   AccountSnapshot snapshot;
   MakeValidSnapshot(snapshot);
   AccountSnapshotReset(snapshot);
   Check(snapshot.login==-1,"login = -1");
   Check(snapshot.server=="" && snapshot.company=="" && snapshot.currency=="","strings empty");
   Check(!MathIsValidNumber(snapshot.balance) && !MathIsValidNumber(snapshot.equity)
         && !MathIsValidNumber(snapshot.profit) && !MathIsValidNumber(snapshot.credit)
         && !MathIsValidNumber(snapshot.margin) && !MathIsValidNumber(snapshot.free_margin)
         && !MathIsValidNumber(snapshot.margin_level),"every double is NaN");
   Check(snapshot.leverage==-1 && snapshot.margin_mode==-1,"leverage and margin mode = -1");
   Check(!snapshot.trade_allowed && !snapshot.expert_allowed,"flags false");
   Check(snapshot.server_time==0 && snapshot.collection_time==0,"times 0");
   Check(snapshot.data_status==DATA_STATUS_UNAVAILABLE,"status UNAVAILABLE");
   Check(snapshot.error_message==RM_MSG_NOT_COLLECTED,"message NOT_COLLECTED");
   CDataValidator validator;
   string errors="";
   Check(!validator.ValidateSnapshot(snapshot,errors),"a reset snapshot can never validate");
   TestEnd();
  }

void Test_T02()
  {
   TestBegin("T02","Failed collection never reuses previous data (same output variable)");
   CFakeAccountDataSource source;
   CAccountEngine engine;
   engine.SetDataSource(GetPointer(source));
   engine.Configure(true);
   Check(engine.Initialize(),"account engine initialized");
   AccountSnapshot snapshot;
   Check(engine.Collect(snapshot),"first collection succeeds");
   Check(snapshot.balance==1000.00,"first collection has data");
   source.fail_property="ACCOUNT_EQUITY";
   source.fail_error=RM_TEST_API_ERROR;
   Check(!engine.Collect(snapshot),"second collection fails");
   Check(snapshot.login==-1,"login reset");
   Check(!MathIsValidNumber(snapshot.balance),"balance reset (not the previous 1000.00)");
   Check(snapshot.server=="","server reset");
   Check(snapshot.data_status==DATA_STATUS_UNAVAILABLE,"status UNAVAILABLE");
   Check(snapshot.collection_time==RM_TEST_LOCAL_TIME,"attempt time recorded");
   Check(Contains(snapshot.error_message,"AccountInfoDouble(ACCOUNT_EQUITY)"),"error names the failing property");
   Check(Contains(snapshot.error_message,"GetLastError=4001"),"error carries the error code");
   Check(engine.GetLastErrorMessage()==snapshot.error_message,"GetLastErrorMessage matches");
   Check(engine.GetLastCollectResult()==RM_COLLECT_API_ERROR,"typed result API_ERROR");
   TestEnd();
  }

void Test_T03()
  {
   TestBegin("T03","API error in each property group -> UNAVAILABLE naming the property");
   CTestFixture identity;
   identity.source.fail_property="ACCOUNT_SERVER";
   identity.source.fail_error=RM_TEST_API_ERROR;
   Check(identity.Setup(true,true,false),"setup (identity)");
   AccountSnapshot snapshot;
   Check(!RefreshAndGet(identity,snapshot),"identity read error -> no current snapshot");
   Check(identity.core.GetCurrentStatus()==DATA_STATUS_UNAVAILABLE,"identity read error -> UNAVAILABLE");
   Check(Contains(snapshot.error_message,"AccountInfoString(ACCOUNT_SERVER)"),"error names ACCOUNT_SERVER");

   CTestFixture configuration;
   configuration.source.fail_property="ACCOUNT_LEVERAGE";
   configuration.source.fail_error=RM_TEST_API_ERROR;
   Check(configuration.Setup(true,true,false),"setup (configuration)");
   AccountSnapshot configuration_snapshot;
   Check(!RefreshAndGet(configuration,configuration_snapshot),"configuration read error -> no current snapshot");
   Check(Contains(configuration_snapshot.error_message,"AccountInfoInteger(ACCOUNT_LEVERAGE)"),"error names ACCOUNT_LEVERAGE");

   CTestFixture financial;
   financial.source.fail_property="ACCOUNT_MARGIN_FREE";
   financial.source.fail_error=RM_TEST_API_ERROR;
   Check(financial.Setup(true,true,false),"setup (financial)");
   financial.core.Refresh();
   Check(financial.core.GetCurrentStatus()==DATA_STATUS_UNAVAILABLE,"financial read error -> UNAVAILABLE");
   Check(financial.logger.GetLevelCount(RM_LOG_ERROR)==1,"an API error is logged as ERROR");
   TestEnd();
  }

void Test_T04()
  {
   TestBegin("T04","Server time unavailable -> UNAVAILABLE, server_time 0, local time never substituted");
   CFakeAccountDataSource source;
   source.server_time=0;
   CAccountEngine engine;
   engine.SetDataSource(GetPointer(source));
   engine.Configure(true);
   Check(engine.Initialize(),"account engine initialized");
   AccountSnapshot snapshot;
   Check(!engine.Collect(snapshot),"collection fails");
   Check(snapshot.server_time==0,"server_time stays 0");
   Check(snapshot.server_time!=snapshot.collection_time,"server_time is not the local time");
   Check(snapshot.collection_time==RM_TEST_LOCAL_TIME,"collection_time = TimeLocal()");
   Check(Contains(snapshot.error_message,"SERVER_TIME_UNAVAILABLE"),"diagnostic SERVER_TIME_UNAVAILABLE");
   Check(engine.GetLastCollectResult()==RM_COLLECT_SERVER_TIME_UNAVAILABLE,"typed result SERVER_TIME_UNAVAILABLE");

   source.server_time=RM_TEST_SERVER_TIME;
   source.server_time_error=RM_TEST_API_ERROR;
   Check(!engine.Collect(snapshot),"an error reported with the time also fails");

   CTestFixture fx;
   fx.source.server_time=0;
   Check(fx.Setup(true,true,false),"setup");
   fx.core.Refresh();
   Check(fx.core.GetCurrentStatus()==DATA_STATUS_UNAVAILABLE,"core status UNAVAILABLE");

   CTestFixture valid;
   Check(valid.Setup(true,true,false),"setup (valid)");
   AccountSnapshot current;
   Check(RefreshAndGet(valid,current),"valid snapshot");
   Check(current.server_time==RM_TEST_SERVER_TIME,"server_time = TimeTradeServer()");
   Check(current.collection_time==RM_TEST_LOCAL_TIME,"collection_time = TimeLocal()");
   TestEnd();
  }

void Test_T05()
  {
   TestBegin("T05","CAccountEngine::Collect() never marks a snapshot VALID");
   CFakeAccountDataSource source;
   CAccountEngine engine;
   engine.SetDataSource(GetPointer(source));
   engine.Configure(true);
   Check(engine.Initialize(),"account engine initialized");
   AccountSnapshot snapshot;
   Check(engine.Collect(snapshot),"raw collection succeeds");
   Check(snapshot.data_status==DATA_STATUS_UNAVAILABLE,"status is not VALID before validation");
   Check(snapshot.error_message==RM_MSG_PENDING_VALIDATION,"message COLLECTED_PENDING_VALIDATION");
   CAccountEngine uninitialized;
   Check(!uninitialized.Collect(snapshot),"Collect() before Initialize() fails");
   Check(uninitialized.GetLastCollectResult()==RM_COLLECT_NOT_INITIALIZED,"typed result NOT_INITIALIZED");
   TestEnd();
  }

void Test_T06()
  {
   TestBegin("T06","Validator is deterministic (same input -> same result and message)");
   CDataValidator validator;
   AccountSnapshot snapshot;
   MakeValidSnapshot(snapshot);
   snapshot.login=0;
   snapshot.equity=AccountModelNaN();
   snapshot.leverage=0;
   string first="";
   string second="";
   bool first_result=validator.ValidateSnapshot(snapshot,first);
   bool second_result=validator.ValidateSnapshot(snapshot,second);
   Check(!first_result && !second_result,"both runs reject");
   Check(first==second,"identical messages");
   Check(first=="ACCOUNT_LOGIN must be > 0; ACCOUNT_EQUITY is not a finite number (NaN or Inf); ACCOUNT_LEVERAGE must be > 0",
         "all errors listed in a fixed order");
   MakeValidSnapshot(snapshot);
   Check(validator.ValidateSnapshot(snapshot,first) && first=="","valid snapshot -> true with empty message");
   Check(validator.ValidateAccountIdentity(snapshot),"identity group valid");
   Check(validator.ValidateAccountFinancials(snapshot),"financial group valid");
   Check(validator.ValidateAccountConfiguration(snapshot),"configuration group valid");
   TestEnd();
  }

void Test_T07()
  {
   TestBegin("T07","Identity rules (login > 0, server/currency not empty, company optional)");
   CDataValidator validator;
   AccountSnapshot snapshot;
   MakeValidSnapshot(snapshot);
   snapshot.company="";
   Check(validator.ValidateAccountIdentity(snapshot),"empty company accepted");
   snapshot.login=-7;
   Check(!validator.ValidateAccountIdentity(snapshot),"negative login rejected");
   MakeValidSnapshot(snapshot);
   snapshot.server=" \t ";
   Check(!validator.ValidateAccountIdentity(snapshot),"whitespace-only server rejected");
   MakeValidSnapshot(snapshot);
   snapshot.currency="";
   Check(!validator.ValidateAccountIdentity(snapshot),"empty currency rejected");
   TestEnd();
  }

void Test_T08()
  {
   TestBegin("T08","Q-02: negative balance / equity / free margin accepted; margin rules kept");
   CDataValidator validator;
   AccountSnapshot snapshot;
   string errors="";
   MakeValidSnapshot(snapshot);
   snapshot.free_margin=-40.0;
   Check(validator.ValidateSnapshot(snapshot,errors),"negative free margin accepted (margin call zone)");
   MakeValidSnapshot(snapshot);
   snapshot.balance=-12.0;
   Check(validator.ValidateSnapshot(snapshot,errors),"negative balance accepted");
   MakeValidSnapshot(snapshot);
   snapshot.equity=-30.0;
   snapshot.margin_level=-60.0;
   Check(validator.ValidateSnapshot(snapshot,errors),"negative equity with negative margin level accepted");
   MakeValidSnapshot(snapshot);
   snapshot.margin_level=-60.0;
   Check(!validator.ValidateSnapshot(snapshot,errors),"negative margin level with equity >= 0 and margin > 0 rejected");
   MakeValidSnapshot(snapshot);
   snapshot.margin=0.0;
   snapshot.margin_level=0.0;
   Check(validator.ValidateSnapshot(snapshot,errors),"margin 0 with margin level 0 accepted");
   MakeValidSnapshot(snapshot);
   snapshot.margin=-0.01;
   Check(!validator.ValidateSnapshot(snapshot,errors),"negative margin rejected");
   TestEnd();
  }

void Test_T09()
  {
   TestBegin("T09","Validator never modifies, clamps or rounds its input");
   CDataValidator validator;
   AccountSnapshot snapshot;
   MakeValidSnapshot(snapshot);
   snapshot.balance=1000.123456789;
   snapshot.margin=-3.0;
   snapshot.server="  Exness-MT5Real8  ";
   snapshot.equity=AccountModelNaN();
   AccountSnapshot original;
   AccountSnapshotCopy(snapshot,original);
   string errors="";
   validator.ValidateSnapshot(snapshot,errors);
   validator.ValidateAccountIdentity(snapshot);
   validator.ValidateAccountFinancials(snapshot);
   validator.ValidateAccountConfiguration(snapshot);
   Check(SameSnapshot(snapshot,original),"snapshot unchanged after validation");
   TestEnd();
  }

void Test_T10()
  {
   TestBegin("T10","InpRequireConnectedTerminal=false + disconnected -> STALE, never VALID or stored");
   CTestFixture fx;
   Check(fx.Setup(false,true,false),"setup (connection not required)");
   fx.core.Refresh();
   Check(fx.core.GetCurrentStatus()==DATA_STATUS_VALID,"VALID while connected");
   datetime first_success=fx.core.GetLastSuccessfulCollectionTime();
   fx.source.connected=false;
   fx.source.balance=999.0;
   fx.source.local_time=RM_TEST_LOCAL_TIME+30;
   fx.RefreshTimes(3);
   Check(fx.core.GetCurrentStatus()==DATA_STATUS_STALE,"disconnected data -> STALE");
   Check(fx.core.GetLastSuccessfulCollectionTime()==first_success,"STALE data is not stored as a success");
   AccountSnapshot snapshot;
   Check(!fx.core.GetLatestSnapshot(snapshot),"STALE is not current");
   Check(snapshot.balance==1000.00,"returned copy is the last successful snapshot");
   Check(fx.Count(RM_EVENT_ACCOUNT_COLLECTION_FAILED)==1,"STALE logged once");
   Check(fx.logger.GetLevelCount(RM_LOG_ERROR)==0,"STALE is a WARNING");
   fx.source.connected=true;
   fx.core.Refresh();
   Check(fx.core.GetCurrentStatus()==DATA_STATUS_VALID,"VALID after reconnect");
   TestEnd();
  }

void Test_T11()
  {
   TestBegin("T11","Invalid identity reading (login 0) is INVALID, not an identity change");
   CTestFixture fx;
   Check(fx.Setup(true,true,false),"setup");
   fx.core.Refresh();
   fx.source.login=0;
   fx.core.Refresh();
   Check(fx.core.GetCurrentStatus()==DATA_STATUS_INVALID,"login 0 -> INVALID");
   Check(fx.Count(RM_EVENT_ACCOUNT_IDENTITY_CHANGED)==0,"no identity change latched");
   fx.source.login=12345678;
   fx.core.Refresh();
   Check(fx.core.GetCurrentStatus()==DATA_STATUS_VALID,"same login again -> VALID");
   TestEnd();
  }

void Test_T12()
  {
   TestBegin("T12","Logger level policy and exact event codes");
   CLogger logger;
   logger.SetSilent(true);
   logger.Configure(false,true);
   logger.Debug(RM_EVENT_ACCOUNT_COLLECTION_SUCCESS,"debug");
   logger.Info(RM_EVENT_EA_INITIALIZED,"info");
   logger.Warning(RM_EVENT_TERMINAL_DISCONNECTED,"warning");
   logger.Error(RM_EVENT_EA_INITIALIZATION_FAILED,"error");
   Check(logger.GetTotalCount()==1,"logging disabled: only the ERROR is emitted");
   Check(logger.GetLevelCount(RM_LOG_ERROR)==1,"the emitted line is the ERROR");
   logger.ResetCounters();
   logger.Configure(true,false);
   logger.Debug(RM_EVENT_ACCOUNT_COLLECTION_SUCCESS,"debug");
   logger.Info(RM_EVENT_EA_INITIALIZED,"info");
   Check(logger.GetTotalCount()==1,"debug disabled: DEBUG suppressed, INFO emitted");
   logger.ResetCounters();
   logger.Configure(true,true);
   logger.Debug(RM_EVENT_ACCOUNT_COLLECTION_SUCCESS,"debug");
   Check(logger.GetLevelCount(RM_LOG_DEBUG)==1,"debug enabled: DEBUG emitted");
   Check(RMLogEventCode(RM_EVENT_EA_INITIALIZED)=="EA_INITIALIZED","EA_INITIALIZED");
   Check(RMLogEventCode(RM_EVENT_EA_INITIALIZATION_FAILED)=="EA_INITIALIZATION_FAILED","EA_INITIALIZATION_FAILED");
   Check(RMLogEventCode(RM_EVENT_ACCOUNT_COLLECTION_SUCCESS)=="ACCOUNT_COLLECTION_SUCCESS","ACCOUNT_COLLECTION_SUCCESS");
   Check(RMLogEventCode(RM_EVENT_ACCOUNT_COLLECTION_FAILED)=="ACCOUNT_COLLECTION_FAILED","ACCOUNT_COLLECTION_FAILED");
   Check(RMLogEventCode(RM_EVENT_ACCOUNT_IDENTITY_CHANGED)=="ACCOUNT_IDENTITY_CHANGED","ACCOUNT_IDENTITY_CHANGED");
   Check(RMLogEventCode(RM_EVENT_TERMINAL_DISCONNECTED)=="TERMINAL_DISCONNECTED","TERMINAL_DISCONNECTED");
   Check(RMLogEventCode(RM_EVENT_TERMINAL_RECONNECTED)=="TERMINAL_RECONNECTED","TERMINAL_RECONNECTED");
   Check(RMLogEventCode(RM_EVENT_EA_SHUTDOWN)=="EA_SHUTDOWN","EA_SHUTDOWN");
   Check(RMLogEventCode(RM_EVENT_TELEGRAM_SEND_FAILED)=="TELEGRAM_SEND_FAILED","TELEGRAM_SEND_FAILED");
   Check(RMLogEventCode(RM_EVENT_TELEGRAM_SEND_RECOVERED)=="TELEGRAM_SEND_RECOVERED","TELEGRAM_SEND_RECOVERED");
   TestEnd();
  }

void Test_T13()
  {
   TestBegin("T13","Log line format: source, timestamp, level, event code");
   CLogger logger;
   logger.SetSilent(true);
   logger.Configure(true,false);
   logger.Error(RM_EVENT_ACCOUNT_IDENTITY_CHANGED,"message text");
   string line=logger.GetLastLine();
   Check(StringFind(line,"[RiskManagement][")==0,"line starts with the source tag");
   Check(Contains(line,"][ERROR][ACCOUNT_IDENTITY_CHANGED] message text"),"level, event code and message present");
   Check(StringLen(line)>StringLen("[RiskManagement][yyyy.mm.dd hh:mi:ss]"),"timestamp present");
   TestEnd();
  }

void Test_T14()
  {
   TestBegin("T14","Re-initialization is a restart: state discarded, new baseline, no latch");
   CTestFixture fx;
   Check(fx.Setup(true,true,false),"setup");
   fx.core.Refresh();
   fx.core.Shutdown();
   fx.source.login=55556666;
   Check(fx.Setup(true,true,false),"setup again (restart)");
   AccountSnapshot snapshot;
   Check(RefreshAndGet(fx,snapshot),"VALID after restart");
   Check(snapshot.login==55556666,"new account monitored after restart");
   Check(fx.Count(RM_EVENT_ACCOUNT_IDENTITY_CHANGED)==0,"no identity change after a restart");
   TestEnd();
  }

void Test_T15()
  {
   TestBegin("T15","Q-01: baseline deferred until the first VALID snapshot");
   CTestFixture fx;
   fx.source.connected=false;
   fx.source.login=0;
   Check(fx.Setup(true,true,false),"setup while disconnected");
   fx.RefreshTimes(3);
   Check(fx.core.GetCurrentStatus()==DATA_STATUS_UNAVAILABLE,"UNAVAILABLE while disconnected");
   fx.source.connected=true;
   fx.source.login=12345678;
   fx.core.Refresh();
   Check(fx.core.GetCurrentStatus()==DATA_STATUS_VALID,"first VALID snapshot after connecting");
   Check(Contains(fx.logger.GetLastLine(),"after 3 failed cycle(s)"),"first valid line reports the failed cycles");
   fx.source.login=99990000;
   fx.core.Refresh();
   Check(fx.Count(RM_EVENT_ACCOUNT_IDENTITY_CHANGED)==1,"later identity change is detected");
   TestEnd();
  }

void Test_T16()
  {
   TestBegin("T16","Debug logging: one detail line per successful cycle only when enabled");
   CTestFixture debug_on;
   Check(debug_on.Setup(true,true,true),"setup (debug on)");
   debug_on.RefreshTimes(3);
   Check(debug_on.logger.GetLevelCount(RM_LOG_DEBUG)==3,"3 successful cycles -> 3 DEBUG lines");
   Check(Contains(debug_on.logger.GetLastLine(),"equity=1013.75"),"DEBUG line carries the values");
   debug_on.source.connected=false;
   debug_on.RefreshTimes(5);
   Check(debug_on.logger.GetLevelCount(RM_LOG_DEBUG)==3,"failed cycles add no repeated DEBUG lines");

   CTestFixture debug_off;
   Check(debug_off.Setup(true,true,false),"setup (debug off)");
   debug_off.RefreshTimes(3);
   Check(debug_off.logger.GetLevelCount(RM_LOG_DEBUG)==0,"debug off -> no DEBUG line");
   Check(debug_off.logger.GetTotalCount()==1,"debug off -> account values are not printed every cycle");
   TestEnd();
  }

void Test_T17()
  {
   TestBegin("T17","Connection check error is treated as disconnected (fail-safe)");
   CTestFixture fx;
   fx.source.connected_error=RM_TEST_API_ERROR;
   Check(fx.Setup(true,true,false),"setup");
   AccountSnapshot snapshot;
   Check(!RefreshAndGet(fx,snapshot),"no current snapshot");
   Check(fx.core.GetCurrentStatus()==DATA_STATUS_UNAVAILABLE,"UNAVAILABLE");
   Check(Contains(snapshot.error_message,"TerminalInfoInteger(TERMINAL_CONNECTED) failed"),"reason names the failing check");
   TestEnd();
  }

void Test_T18()
  {
   TestBegin("T18","No successful snapshot yet -> false, empty UNAVAILABLE snapshot");
   CTestFixture fx;
   fx.source.connected=false;
   Check(fx.Setup(true,true,false),"setup");
   fx.core.Refresh();
   AccountSnapshot snapshot;
   Check(!fx.core.GetLatestSnapshot(snapshot),"returns false");
   Check(snapshot.data_status==DATA_STATUS_UNAVAILABLE,"status UNAVAILABLE");
   Check(!MathIsValidNumber(snapshot.balance) && snapshot.login==-1,"fields hold sentinels, not data");
   Check(Contains(snapshot.error_message,"NO_SUCCESSFUL_SNAPSHOT"),"reason NO_SUCCESSFUL_SNAPSHOT");
   Check(fx.core.GetLastSuccessfulCollectionTime()==0,"no last successful time");
   TestEnd();
  }


//+------------------------------------------------------------------+
//| Telegram add-on N01 - N14 (fake transport, no network)           |
//+------------------------------------------------------------------+
void Test_N01()
  {
   TestBegin("N01","Vietnamese text file decoded as UTF-8 (encoding probe U+1EA1)");
   string probe=RMViEncodingProbe();
   Check(StringLen(probe)==1,"probe is one character (file read as UTF-8)");
   Check(StringGetCharacter(probe,0)==0x1EA1,"probe is U+1EA1");
   TestEnd();
  }

void Test_N02()
  {
   TestBegin("N02","Telegram input validation (rejects, never substitutes)");
   string error_message="";
   Check(RMValidateTelegramInputs(false,"","",0,0,error_message),"disabled: other Telegram inputs ignored");
   Check(RMValidateTelegramInputs(true,RM_TEST_TOKEN,RM_TEST_CHAT_ID,0,5000,error_message),"valid token + numeric chat id");
   Check(RMValidateTelegramInputs(true,RM_TEST_TOKEN,"-1001234567890",60,5000,error_message),"group chat id accepted");
   Check(RMValidateTelegramInputs(true,RM_TEST_TOKEN,"@my_channel",60,5000,error_message),"channel username accepted");
   Check(!RMValidateTelegramInputs(true,"",RM_TEST_CHAT_ID,0,5000,error_message),"empty token rejected");
   Check(StringFind(error_message,"InpTelegramBotToken")>=0,"message names InpTelegramBotToken");
   Check(!RMValidateTelegramInputs(true,"123:short",RM_TEST_CHAT_ID,0,5000,error_message),"short token rejected");
   Check(!RMValidateTelegramInputs(true,"123456789:TESTtoken TESTtokenTESTtoken_-0123",RM_TEST_CHAT_ID,0,5000,error_message),"token with a space rejected");
   Check(!RMValidateTelegramInputs(true,"abc:TESTtokenTESTtokenTESTtoken_-0123",RM_TEST_CHAT_ID,0,5000,error_message),"non-numeric bot id rejected");
   Check(!RMValidateTelegramInputs(true,RM_TEST_TOKEN,"",0,5000,error_message),"empty chat id rejected");
   Check(!RMValidateTelegramInputs(true,RM_TEST_TOKEN,"12a",0,5000,error_message),"malformed chat id rejected");
   Check(!RMValidateTelegramInputs(true,RM_TEST_TOKEN,"@ab",0,5000,error_message),"too short channel name rejected");
   Check(!RMValidateTelegramInputs(true,RM_TEST_TOKEN,RM_TEST_CHAT_ID,-1,5000,error_message),"negative summary interval rejected");
   Check(!RMValidateTelegramInputs(true,RM_TEST_TOKEN,RM_TEST_CHAT_ID,0,500,error_message),"timeout below 1000 ms rejected");
   Check(!RMValidateTelegramInputs(true,RM_TEST_TOKEN,RM_TEST_CHAT_ID,0,20000,error_message),"timeout above 15000 ms rejected");
   Check(StringFind(error_message,RM_TEST_TOKEN)<0,"validation messages never contain the token");
   TestEnd();
  }

void Test_N03()
  {
   TestBegin("N03","Core event -> one Vietnamese Telegram message (URL, chat id, JSON)");
   CTestFixture fx;
   CTelegramFixture tg;
   Check(tg.Setup(),"notifier initialized");
   Check(fx.Setup(true,true,false),"core setup");
   fx.core.SetEventListener(GetPointer(tg.notifier));
   fx.core.Refresh();
   tg.notifier.Process(RM_TEST_LOCAL_TIME);
   Check(tg.transport.calls==1,"first valid snapshot sent");
   string expected_url="https://api.telegram.org/bot";
   expected_url=expected_url+RM_TEST_TOKEN+"/sendMessage";
   Check(tg.transport.last_url==expected_url,"sendMessage URL");
   Check(StringFind(tg.transport.last_body,"\"chat_id\":\"123456789\"")>=0,"chat_id in the JSON body");
   Check(StringFind(tg.transport.last_body,"Balance: 1000.00 USD")>=0,"account values in the message");
   Check(tg.transport.last_timeout==4000,"configured timeout used");
   fx.source.connected=false;
   fx.core.Refresh();
   tg.notifier.Process(RM_TEST_LOCAL_TIME);
   Check(tg.transport.calls==2,"disconnect notification sent");
   RiskEvent expected;
   RiskEventReset(expected,RM_EVENT_TERMINAL_DISCONNECTED,RM_LOG_WARNING,RM_TEST_LOCAL_TIME);
   string expected_text=RMJsonEscape(RMTelegramFormatEventVi(expected,"12345678 (Exness-MT5Real8, USD)"));
   Check(StringFind(tg.transport.last_body,expected_text)>=0,"Vietnamese disconnect message with the account label");
   Check(tg.notifier.GetQueueSize()==0,"queue empty after success");
   TestEnd();
  }

void Test_N04()
  {
   TestBegin("N04","Only state transitions are sent (30 identical failed cycles -> 1 message)");
   CTestFixture fx;
   CTelegramFixture tg;
   Check(tg.Setup(),"notifier initialized");
   Check(fx.Setup(true,true,false),"core setup");
   fx.core.SetEventListener(GetPointer(tg.notifier));
   fx.core.Refresh();
   tg.notifier.Process(RM_TEST_LOCAL_TIME);
   int calls_before=tg.transport.calls;
   fx.source.connected=false;
   for(int i=0; i<30; i++)
     {
      fx.core.Refresh();
      tg.notifier.Process(RM_TEST_LOCAL_TIME+i);
     }
   Check(tg.transport.calls==calls_before+1,"one request for 30 disconnected cycles");
   Check(StringFind(tg.transport.last_body,"\\n\\n")<0,"a single message (the failure caused by the disconnect is not repeated)");
   fx.source.connected=true;
   fx.source.margin=-1.0;
   fx.core.Refresh();
   tg.notifier.Process(RM_TEST_LOCAL_TIME+100);
   Check(StringFind(tg.transport.last_body,RMViValidationErrors("ACCOUNT_MARGIN must be >= 0"))>=0,"a data failure is still sent");
   TestEnd();
  }

void Test_N05()
  {
   TestBegin("N05","Queued messages are batched into one request");
   CTelegramFixture tg;
   Check(tg.Setup(),"notifier initialized");
   tg.notifier.Enqueue("first");
   tg.notifier.Enqueue("second");
   tg.notifier.Enqueue("third");
   tg.notifier.Process(RM_TEST_LOCAL_TIME);
   Check(tg.transport.calls==1,"one request");
   Check(StringFind(tg.transport.last_body,"first\\n\\nsecond\\n\\nthird")>=0,"all three messages, in order");
   Check(tg.notifier.GetQueueSize()==0,"queue empty");
   TestEnd();
  }

void Test_N06()
  {
   TestBegin("N06","Network failure: messages kept, exponential back-off, logged once, recovery logged");
   CTelegramFixture tg;
   Check(tg.Setup(),"notifier initialized");
   tg.transport.SetResult(-1,5202,"");
   tg.notifier.Enqueue("message");
   datetime now=RM_TEST_LOCAL_TIME;
   tg.notifier.Process(now);
   Check(tg.notifier.GetQueueSize()==1,"message kept after the failure");
   Check(tg.notifier.GetNextAttemptTime()==now+10,"first retry after 10 s");
   tg.notifier.Process(now+5);
   Check(tg.transport.calls==1,"no request during the back-off");
   tg.notifier.Process(now+10);
   Check(tg.transport.calls==2,"retry after the back-off");
   Check(tg.notifier.GetNextAttemptTime()==now+30,"second back-off doubled to 20 s");
   Check(tg.logger.GetEventCount(RM_EVENT_TELEGRAM_SEND_FAILED)==1,"same failure logged once");
   tg.transport.SetOk();
   tg.notifier.Process(now+30);
   Check(tg.notifier.GetQueueSize()==0,"delivered after recovery");
   Check(tg.logger.GetEventCount(RM_EVENT_TELEGRAM_SEND_RECOVERED)==1,"recovery logged once");
   TestEnd();
  }

void Test_N07()
  {
   TestBegin("N07","HTTP 429 honours retry_after");
   CTelegramFixture tg;
   Check(tg.Setup(),"notifier initialized");
   tg.transport.SetResult(429,0,"{\"ok\":false,\"error_code\":429,\"description\":\"Too Many Requests: retry after 7\",\"parameters\":{\"retry_after\":7}}");
   tg.notifier.Enqueue("message");
   tg.notifier.Process(RM_TEST_LOCAL_TIME);
   Check(tg.notifier.GetNextAttemptTime()==RM_TEST_LOCAL_TIME+7,"next attempt after retry_after");
   Check(tg.notifier.GetQueueSize()==1,"message kept");
   Check(!tg.notifier.IsDisabled(),"not disabled");
   TestEnd();
  }

void Test_N08()
  {
   TestBegin("N08","HTTP 401 (wrong token) disables Telegram; the token never appears in the log");
   CTelegramFixture tg;
   Check(tg.Setup(),"notifier initialized");
   tg.transport.SetResult(401,0,"{\"ok\":false,\"error_code\":401,\"description\":\"Unauthorized\"}");
   tg.notifier.Enqueue("message");
   tg.notifier.Process(RM_TEST_LOCAL_TIME);
   Check(tg.notifier.IsDisabled(),"disabled");
   Check(!tg.notifier.IsActive(),"inactive");
   Check(tg.logger.GetLevelCount(RM_LOG_ERROR)==1,"one ERROR line");
   Check(StringFind(tg.logger.GetLastLine(),"InpTelegramBotToken")>=0,"hint names InpTelegramBotToken");
   Check(StringFind(tg.logger.GetLastLine(),RM_TEST_TOKEN)<0,"token not logged");
   tg.notifier.Process(RM_TEST_LOCAL_TIME+600);
   Check(tg.transport.calls==1,"no further request");
   TestEnd();
  }

void Test_N09()
  {
   TestBegin("N09","WebRequest not allowed (4014): ERROR with the fix, keeps retrying");
   CTelegramFixture tg;
   Check(tg.Setup(),"notifier initialized");
   tg.transport.SetResult(-1,4014,"");
   tg.notifier.Enqueue("message");
   tg.notifier.Process(RM_TEST_LOCAL_TIME);
   Check(tg.logger.GetLevelCount(RM_LOG_ERROR)==1,"ERROR logged");
   Check(StringFind(tg.logger.GetLastLine(),"https://api.telegram.org")>=0,"log explains which URL to allow");
   Check(StringFind(tg.logger.GetLastLine(),RM_TEST_TOKEN)<0,"token not logged");
   Check(!tg.notifier.IsDisabled(),"not disabled (the user can add the URL)");
   tg.notifier.Process(RM_TEST_LOCAL_TIME+10);
   Check(tg.transport.calls==2,"retried after the back-off");
   Check(tg.logger.GetLevelCount(RM_LOG_ERROR)==1,"still one ERROR line");
   TestEnd();
  }

void Test_N10()
  {
   TestBegin("N10","Bounded queue: oldest messages dropped and reported");
   CTelegramFixture tg;
   Check(tg.Setup(),"notifier initialized");
   for(int i=0; i<RM_TG_QUEUE_CAPACITY+5; i++)
      tg.notifier.Enqueue("message "+IntegerToString(i));
   Check(tg.notifier.GetQueueSize()==RM_TG_QUEUE_CAPACITY,"queue capped");
   Check(tg.notifier.GetDroppedCount()==5,"5 dropped");
   tg.notifier.Process(RM_TEST_LOCAL_TIME);
   Check(StringFind(tg.transport.last_body,RMViDroppedNotice(5))>=0,"drop notice sent");
   Check(StringFind(tg.transport.last_body,"message 5")>=0 && StringFind(tg.transport.last_body,"message 4\\n")<0,"oldest messages were the ones dropped");
   TestEnd();
  }

void Test_N11()
  {
   TestBegin("N11","JSON escaping of quotes, backslashes and line breaks");
   Check(RMJsonEscape("a\"b\\c\nd\te")=="a\\\"b\\\\c\\nd\\te","escaped");
   TestEnd();
  }

void Test_N12()
  {
   TestBegin("N12","Startup mode: core events skipped, lifecycle events kept");
   CTelegramFixture tg;
   Check(tg.Setup(),"notifier initialized");
   tg.notifier.SetStartupMode(true);
   RiskEvent risk_event;
   RiskEventReset(risk_event,RM_EVENT_TERMINAL_DISCONNECTED,RM_LOG_WARNING,RM_TEST_LOCAL_TIME);
   tg.notifier.OnRiskEvent(risk_event);
   Check(tg.notifier.GetQueueSize()==0,"core event skipped during startup");
   RiskEventReset(risk_event,RM_EVENT_EA_INITIALIZED,RM_LOG_INFO,RM_TEST_LOCAL_TIME);
   tg.notifier.OnRiskEvent(risk_event);
   Check(tg.notifier.GetQueueSize()==1,"EA_INITIALIZED queued");
   tg.notifier.SetStartupMode(false);
   RiskEventReset(risk_event,RM_EVENT_TERMINAL_DISCONNECTED,RM_LOG_WARNING,RM_TEST_LOCAL_TIME);
   tg.notifier.OnRiskEvent(risk_event);
   Check(tg.notifier.GetQueueSize()==2,"core events queued after startup");
   TestEnd();
  }

void Test_N13()
  {
   TestBegin("N13","Every event type produces a message; identity change names both accounts");
   RiskEvent risk_event;
   int empty_messages=0;
   for(int id=0; id<8; id++)
     {
      RiskEventReset(risk_event,(ENUM_RM_LOG_EVENT)id,RM_LOG_INFO,RM_TEST_LOCAL_TIME);
      if(StringLen(RMTelegramFormatEventVi(risk_event,""))==0)
         empty_messages++;
     }
   Check(empty_messages==0,"all 8 events have a Vietnamese message");
   RiskEventReset(risk_event,RM_EVENT_ACCOUNT_IDENTITY_CHANGED,RM_LOG_ERROR,RM_TEST_LOCAL_TIME);
   MakeValidSnapshot(risk_event.snapshot);
   risk_event.has_snapshot=true;
   risk_event.observed_login=87654321;
   risk_event.observed_server="Exness-MT5Trial";
   risk_event.observed_currency="USD";
   string text=RMTelegramFormatEventVi(risk_event,"");
   Check(StringFind(text,"12345678 (Exness-MT5Real8, USD)")>=0,"original account named");
   Check(StringFind(text,"87654321 (Exness-MT5Trial, USD)")>=0,"new account named");
   RiskEventReset(risk_event,RM_EVENT_TELEGRAM_SEND_FAILED,RM_LOG_ERROR,RM_TEST_LOCAL_TIME);
   Check(StringLen(RMTelegramFormatEventVi(risk_event,""))==0,"Telegram's own events are never sent to Telegram");
   TestEnd();
  }

void Test_N14()
  {
   TestBegin("N14","Periodic summary: current values, or clearly marked old values");
   AccountSnapshot snapshot;
   MakeValidSnapshot(snapshot);
   string current=RMTelegramFormatSummaryVi(snapshot,true,DATA_STATUS_VALID,"","12345678 (Exness-MT5Real8, USD)",RM_TEST_LOCAL_TIME);
   Check(StringFind(current,"Equity: 1013.75 USD")>=0,"current values listed");
   snapshot.data_status=DATA_STATUS_STALE;
   string stale=RMTelegramFormatSummaryVi(snapshot,false,DATA_STATUS_UNAVAILABLE,"TERMINAL_DISCONNECTED: x","",RM_TEST_LOCAL_TIME+600);
   Check(StringFind(stale,RMViStatus(DATA_STATUS_UNAVAILABLE))>=0,"current status shown");
   Check(StringFind(stale,AccountModelFormatTime(RM_TEST_LOCAL_TIME))>=0,"time of the old values shown");
   TestEnd();
  }

//+------------------------------------------------------------------+
//| Runner                                                           |
//+------------------------------------------------------------------+
void RunAllTests()
  {
   Test_F001();
   Test_F002();
   Test_F003();
   Test_F004();
   Test_F005();
   Test_F006();
   Test_F007();
   Test_F008();
   Test_F009();
   Test_F010();
   Test_F011();
   Test_F012();
   Test_F013();
   Test_F014();
   Test_F015();
   Test_F016();
   Test_F017();
   Test_F018();
   Test_F019();
   Test_F020();
   Test_F021();
   Test_F022();
   Test_F023();
   Test_F024();
   Test_F025();
   TestNotRun("F026","Timer creation failure","EventSetTimer() failure cannot be forced inside MT5; covered by the host-simulated entry-point test and static review");
   Test_F027();
   Test_F028();
   Test_F029();
   TestNotRun("F030","No trading API","static read-only audit (Tools/readonly_audit.py), not a runtime test");
   Test_T01();
   Test_T02();
   Test_T03();
   Test_T04();
   Test_T05();
   Test_T06();
   Test_T07();
   Test_T08();
   Test_T09();
   Test_T10();
   Test_T11();
   Test_T12();
   Test_T13();
   Test_T14();
   Test_T15();
   Test_T16();
   Test_T17();
   Test_T18();
   Test_N01();
   Test_N02();
   Test_N03();
   Test_N04();
   Test_N05();
   Test_N06();
   Test_N07();
   Test_N08();
   Test_N09();
   Test_N10();
   Test_N11();
   Test_N12();
   Test_N13();
   Test_N14();
  }

int OnInit()
  {
   Print("[RM-TEST] EA Risk Management M1 test harness - simulated data only (no account reads, no trading)");
   RunAllTests();
   Print("[RM-TEST] SUMMARY total="+IntegerToString(g_tests_total)
         +" passed="+IntegerToString(g_tests_passed)
         +" failed="+IntegerToString(g_tests_failed)
         +" not_run="+IntegerToString(g_tests_not_run));
   if(g_tests_failed==0)
      Print("[RM-TEST] RESULT: all executed tests passed");
   else
      Print("[RM-TEST] RESULT: FAILURES PRESENT");
   ExpertRemove();
   return(INIT_SUCCEEDED);
  }

//--- present only so the harness is unambiguously an Expert Advisor; does nothing
void OnTick()
  {
  }

void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
