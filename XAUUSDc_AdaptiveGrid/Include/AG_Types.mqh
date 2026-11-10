//+------------------------------------------------------------------+
//| AG_Types.mqh                                                     |
//| Enums, structs, global configuration. No broker constants here.  |
//+------------------------------------------------------------------+
#ifndef AG_TYPES_MQH
#define AG_TYPES_MQH

#define AG_VERSION          "1.00"
#define AG_STATE_SCHEMA     1
#define AG_MAX_PIDS         16
#define AG_SIDES            2
#define AG_LOCK_COUNT       4
#define AG_EPS_MONEY        1e-8
#define AG_FRESH_LOOKBACK_DAYS 90

//--- user facing enums (used by inputs)
enum ENUM_SIGNAL_MODE
  {
   SIGNAL_TWO_CANDLE = 0,   // Two closed candles: setup shift 2, confirmation shift 1
   SIGNAL_ONE_CANDLE = 1    // Experimental: wick through band + close inside on shift 1
  };

enum ENUM_BUDGET_BASE
  {
   BUDGET_BASE_EQUITY  = 0, // Equity at basket start
   BUDGET_BASE_BALANCE = 1  // Balance at basket start
  };

enum ENUM_RESET_TARGET
  {
   RESET_NONE               = 0,
   RESET_ACCOUNT_PROTECTION = 1,
   RESET_EQUITY_DD          = 2,
   RESET_COMBINED_LOSS      = 3,
   RESET_SAFE_MODE          = 4,
   RESET_DAILY_LOSS         = 5  // Not allowed: logged and refused
  };

//--- internal enums
enum ENUM_AG_SIDE
  {
   AG_BUY  = 0,
   AG_SELL = 1
  };

enum ENUM_BASKET_STATE
  {
   BS_IDLE          = 0,
   BS_ENTRY_PENDING = 1,
   BS_ACTIVE        = 2,
   BS_ADD_PENDING   = 3,
   BS_CLOSING       = 4,
   BS_RECOVERY      = 5,
   BS_SAFE_MODE     = 6
  };

enum ENUM_LOCK_ID
  {
   LOCK_ACCOUNT_PROTECTION = 0,
   LOCK_EQUITY_DD          = 1,
   LOCK_COMBINED_LOSS      = 2,
   LOCK_DAILY_LOSS         = 3
  };

enum ENUM_INTENT_KIND
  {
   INTENT_NONE  = 0,
   INTENT_ENTRY = 1,
   INTENT_ADD   = 2
  };

enum ENUM_INTENT_STATUS
  {
   INTENT_ST_NONE     = 0,
   INTENT_ST_SENT     = 1,  // persisted before OrderSend; result not yet known
   INTENT_ST_ACCEPTED = 2,  // broker returned DONE/PLACED, waiting for the position
   INTENT_ST_UNKNOWN  = 3   // timeout / no connection / ambiguous
  };

enum ENUM_CLOSE_REASON
  {
   CR_NONE            = 0,
   CR_TP              = 1,
   CR_SL              = 2,
   CR_LOCK_ACCOUNT    = 3,
   CR_LOCK_EQUITY     = 4,
   CR_LOCK_COMBINED   = 5,
   CR_LOCK_DAILY      = 6,
   CR_SAFE_EMERGENCY  = 7,
   CR_EXTERNAL        = 8
  };

enum ENUM_ENV_STATUS
  {
   ENV_UNKNOWN = 0,
   ENV_VALID   = 1,
   ENV_INVALID = 2
  };

enum ENUM_LOAD_RESULT
  {
   LOAD_OK      = 0,
   LOAD_MISSING = 1,
   LOAD_CORRUPT = 2
  };

//--- configuration (copied from inputs in OnInit)
struct AGConfig
  {
   string            symbol;
   ENUM_TIMEFRAMES   tf;
   long              magicBuy;
   long              magicSell;
   bool              allowBuy;
   bool              allowSell;
   string            requiredCurrency;
   // grid
   double            initialLot;
   double            lotMultiplier;
   int               maxLayers;
   double            maxSideLots;
   int               atrPeriod;
   double            atrMultiplier;
   double            minGrid;
   double            maxGrid;
   double            maxATR;
   // entry
   ENUM_SIGNAL_MODE  signalMode;
   int               rsiPeriod;
   double            rsiBuy;
   double            rsiSell;
   int               bbPeriod;
   double            bbDev;
   int               adxPeriod;
   double            maxADX;
   // basket
   ENUM_BUDGET_BASE  budgetBase;
   double            basketRiskPct;
   bool              useSLFromBudget;
   double            basketTP;
   double            basketSL;
   // account protection
   double            maxCombinedLoss;
   double            dailyLoss;
   double            maxEquityDDPct;
   double            accountProtPct;
   bool              closeAllOnRiskLimit;
   // stress
   double            stressMoveATR;
   double            slippageStressPts;
   double            spreadStressMult;
   double            commissionPerLotEst;
   double            maxMarginUsage;
   // execution
   double            maxSpread;
   int               maxSlippagePts;
   int               cooldownSec;
   int               maxCloseRetries;
   int               closeRetryDelayMs;
   int               pendingTimeoutMs;
   int               reconcileTimeoutSec;
   int               sessionEdgeMin;
   bool              useNewsFilter;
   // recovery / reset
   bool              enablePersistentState;
   bool              safeModeCloseIfUnknown;
   ENUM_RESET_TARGET resetTarget;
   long              resetToken;
   // diagnostics
   bool              enableCSV;
   bool              detailedJournal;
   bool              showDashboard;
  };

AGConfig g_cfg;

//--- trade intent (persisted BEFORE OrderSend)
struct AGIntent
  {
   int               kind;           // ENUM_INTENT_KIND
   int               status;         // ENUM_INTENT_STATUS
   long              magic;
   double            volume;
   long              requestTimeMsc; // server time (tick time_msc) at request
   ulong             orderTicket;
   ulong             dealTicket;
   uint              retcode;
   int               layer;
  };

//--- one EA position as seen in the terminal
struct AGPosInfo
  {
   ulong             ticket;
   long              pid;            // POSITION_IDENTIFIER
   double            volume;
   double            openPrice;
   long              timeMsc;
   double            profit;
   double            swap;
   double            feeIn;          // commission + fee of entry deals (<= 0)
  };

//--- lock flag
struct AGLock
  {
   bool              active;
   datetime          triggerTime;
   double            triggerValue;
   double            threshold;
   datetime          lockDate;       // server day start when triggered
   string            reason;
  };

//--- indicator snapshot of closed bars
struct AGIndSnapshot
  {
   bool              valid;
   datetime          bar1Time;
   double            close1;
   double            close2;
   double            low1;
   double            high1;
   double            bbUp1;
   double            bbLo1;
   double            bbUp2;
   double            bbLo2;
   double            rsi1;
   double            rsi2;
   double            adx1;
   double            atr1;
   string            err;
  };

//--- small helpers
string SideText(const int side)        { return(side==AG_BUY ? "BUY" : (side==AG_SELL ? "SELL" : "-")); }

string BasketStateText(const int st)
  {
   switch(st)
     {
      case BS_IDLE:          return "IDLE";
      case BS_ENTRY_PENDING: return "ENTRY_PENDING";
      case BS_ACTIVE:        return "ACTIVE";
      case BS_ADD_PENDING:   return "ADD_PENDING";
      case BS_CLOSING:       return "CLOSING";
      case BS_RECOVERY:      return "RECOVERY";
      case BS_SAFE_MODE:     return "SAFE_MODE";
     }
   return "UNKNOWN";
  }

string LockName(const int id)
  {
   switch(id)
     {
      case LOCK_ACCOUNT_PROTECTION: return "ACCOUNT_PROTECTION";
      case LOCK_EQUITY_DD:          return "EQUITY_DD";
      case LOCK_COMBINED_LOSS:      return "COMBINED_LOSS";
      case LOCK_DAILY_LOSS:         return "DAILY_LOSS";
     }
   return "UNKNOWN";
  }

string CloseReasonText(const int cr)
  {
   switch(cr)
     {
      case CR_NONE:           return "NONE";
      case CR_TP:             return "BASKET_TP";
      case CR_SL:             return "BASKET_SL";
      case CR_LOCK_ACCOUNT:   return "LOCK_ACCOUNT_PROTECTION";
      case CR_LOCK_EQUITY:    return "LOCK_EQUITY_DD";
      case CR_LOCK_COMBINED:  return "LOCK_COMBINED_LOSS";
      case CR_LOCK_DAILY:     return "LOCK_DAILY_LOSS";
      case CR_SAFE_EMERGENCY: return "SAFE_MODE_EMERGENCY";
      case CR_EXTERNAL:       return "EXTERNAL_CLOSE";
     }
   return "UNKNOWN";
  }

string EnvStatusText(const ENUM_ENV_STATUS s)
  {
   if(s==ENV_VALID)   return "VALID";
   if(s==ENV_INVALID) return "INVALID";
   return "UNKNOWN";
  }

#endif
//+------------------------------------------------------------------+
