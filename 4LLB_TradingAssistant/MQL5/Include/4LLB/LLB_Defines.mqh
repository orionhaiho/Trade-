//+------------------------------------------------------------------+
//| LLB_Defines.mqh                                                  |
//| 4LLB Trading Assistant v2.0 - constants, enums, data structures. |
//| SRS strategy constants are #define on purpose: the SRS baseline  |
//| (levels, thresholds, RR, buffer, expiry) must not be changed     |
//| from the inputs dialog.                                          |
//| Source strings are ASCII only (MetaEditor encoding safety).      |
//+------------------------------------------------------------------+
#ifndef LLB_DEFINES_MQH
#define LLB_DEFINES_MQH

#define LLB_VERSION              "2.00"
#define LLB_EA_NAME              "4LLB Trading Assistant"
#define LLB_STATE_SCHEMA         1
#define LLB_FILE_ROOT            "4LLB"
#define LLB_COMMENT_PREFIX       "4LLB|"
#define LLB_TOKEN_FILE           "4LLB\\telegram_token.txt"

//--- SRS strategy constants (baseline - do not change)
#define LLB_PIVOT_LEFT           3
#define LLB_PIVOT_RIGHT          3
#define LLB_ATR_PERIOD           14
#define LLB_SWEEP_MIN_ATR        0.05
#define LLB_SWEEP_MAX_ATR        0.50
#define LLB_BREAKOUT_ATR         0.10
#define LLB_RETEST_ATR           0.15
#define LLB_RETEST_MAX_BARS      4
#define LLB_SL_BUFFER_TICKS      2
#define LLB_SL_BUFFER_ATR        0.05
#define LLB_RR                   2.0
#define LLB_SWEEP_EXPIRY_SEC     900
#define LLB_BREAKOUT_EXPIRY_SEC  1800
#define LLB_M15_SECONDS          900

//--- technical constants (design decisions, Phase 1/2)
#define LLB_MAX_SYMBOLS          8
#define LLB_TIMER_MS             250
#define LLB_RECONCILE_MS         2000
#define LLB_DASHBOARD_MS         1000
#define LLB_STATE_SAVE_MS        1000
#define LLB_LOCK_HEARTBEAT_MS    10000
#define LLB_LOCK_STALE_SEC       45
#define LLB_LOCK_VERIFY_MS       1200
#define LLB_UNKNOWN_RESOLVE_SEC  120
#define LLB_CONNECT_SETTLE_SEC   3
#define LLB_CLOSE_RETRY_MS       5000
#define LLB_MAX_CLOSE_ATTEMPTS   20
#define LLB_SLTP_RETRY_MS        5000
#define LLB_MAX_SLTP_ATTEMPTS    3
#define LLB_DELETE_RETRY_MS      3000
#define LLB_MAX_DELETE_ATTEMPTS  20
#define LLB_MIN_EXPIRY_LEFT_SEC  10
#define LLB_DATA_RETRY_LIMIT_MS  60000
#define LLB_JOURNAL_MAX_BYTES    5242880
#define LLB_KEEP_DAYS            14
#define LLB_RESTART_OVERLAP_MS   60000
#define LLB_MAX_DOWNTIME_SCAN_MS 259200000   // 3 days of ticks at most on restart

//+------------------------------------------------------------------+
//| Input enums                                                      |
//+------------------------------------------------------------------+
enum ENUM_LLB_LOT_MODE
  {
   LLB_LOT_FIXED        = 0,  // Fixed LotSize (D-04 default)
   LLB_LOT_RISK_PERCENT = 1   // RiskPercent of Balance/Equity
  };

enum ENUM_LLB_RISK_BASE
  {
   LLB_RISK_BALANCE = 0,      // Balance
   LLB_RISK_EQUITY  = 1       // Equity
  };

enum ENUM_LLB_SWING_REF
  {
   LLB_SWINGREF_SETUP_EXTREME   = 0, // Setup extreme: sweep candle / retest structure (D-01)
   LLB_SWINGREF_CONFIRMED_PIVOT = 1  // Nearest confirmed Pivot 3-3 beyond the setup extreme
  };

enum ENUM_LLB_NEAREST
  {
   LLB_NEAREST_PRICE = 0,     // Nearest by price (D-02)
   LLB_NEAREST_TIME  = 1      // Nearest by time (most recent)
  };

enum ENUM_LLB_LOG_LEVEL
  {
   LLB_LOG_ERROR = 0,         // Errors only
   LLB_LOG_WARN  = 1,         // Warnings
   LLB_LOG_INFO  = 2,         // Info (recommended)
   LLB_LOG_DEBUG = 3          // Debug (verbose)
  };

//+------------------------------------------------------------------+
//| Business enums (stored as int in structs)                        |
//+------------------------------------------------------------------+
enum ENUM_LLB_STRATEGY
  {
   LLB_STRAT_SWEEP    = 0,
   LLB_STRAT_BREAKOUT = 1
  };

enum ENUM_LLB_DIR
  {
   LLB_DIR_BUY  = 0,
   LLB_DIR_SELL = 1
  };

enum ENUM_LLB_LEVEL
  {
   LLB_LVL_NONE = 0,
   LLB_LVL_P1   = 1,          // PDH
   LLB_LVL_P2   = 2,          // PDL
   LLB_LVL_P3   = 3,          // swing low below PDL
   LLB_LVL_P4   = 4           // swing high above PDH
  };

//--- SRS proposal states
enum ENUM_LLB_PROPOSAL_STATE
  {
   LLB_PS_ACTIVE           = 0,
   LLB_PS_ACCEPTED         = 1,
   LLB_PS_REJECTED         = 2,
   LLB_PS_EXPIRED          = 3,
   LLB_PS_INVALIDATED      = 4,
   LLB_PS_EXECUTING        = 5,
   LLB_PS_EXECUTED         = 6,
   LLB_PS_EXECUTION_FAILED = 7
  };
#define LLB_PS_COUNT 8

//--- technical execution record states
enum ENUM_LLB_EXEC_STATE
  {
   LLB_EX_NONE            = 0,
   LLB_EX_PRECHECK_FAILED = 1,   // nothing was sent
   LLB_EX_SUBMITTING      = 2,   // persisted before OrderSend
   LLB_EX_PLACED          = 3,   // broker confirmed (ticket known)
   LLB_EX_REJECTED        = 4,   // clear broker reject
   LLB_EX_UNKNOWN         = 5,   // ambiguous result - reconcile, never resend
   LLB_EX_NOT_FOUND       = 6    // reconciliation proved nothing was placed
  };
#define LLB_EX_COUNT 7

enum ENUM_LLB_ORDER_STATE
  {
   LLB_OS_NONE          = 0,
   LLB_OS_PENDING       = 1,
   LLB_OS_PARTIAL       = 2,
   LLB_OS_FILLED        = 3,
   LLB_OS_EXPIRED       = 4,
   LLB_OS_CANCELLED_EA  = 5,
   LLB_OS_CANCELLED_EXT = 6,
   LLB_OS_REJECTED      = 7
  };
#define LLB_OS_COUNT 8

enum ENUM_LLB_POS_STATE
  {
   LLB_POS_OPEN    = 0,
   LLB_POS_CLOSING = 1,
   LLB_POS_CLOSED  = 2
  };
#define LLB_POS_COUNT 3

enum ENUM_LLB_STRUCT_STATE
  {
   LLB_ST_INTACT      = 0,
   LLB_ST_INVALIDATED = 1
  };

enum ENUM_LLB_OWNERSHIP
  {
   LLB_OWN_OK       = 0,
   LLB_OWN_CONFLICT = 1
  };

enum ENUM_LLB_CLOSE_REASON
  {
   LLB_CR_NONE            = 0,
   LLB_CR_SL              = 1,
   LLB_CR_TP              = 2,
   LLB_CR_INVALIDATION    = 3,
   LLB_CR_MANUAL          = 4,
   LLB_CR_STOP_OUT        = 5,
   LLB_CR_EA_OTHER        = 6,
   LLB_CR_SLTP_UNSETTABLE = 7,
   LLB_CR_OTHER           = 8
  };
#define LLB_CR_COUNT 9

enum ENUM_LLB_DECISION
  {
   LLB_DEC_NONE   = 0,
   LLB_DEC_ACCEPT = 1,
   LLB_DEC_REJECT = 2
  };

enum ENUM_LLB_TG_STATUS
  {
   LLB_TG_DISABLED    = 0,
   LLB_TG_CONNECTING  = 1,
   LLB_TG_OK          = 2,
   LLB_TG_DEGRADED    = 3,
   LLB_TG_AUTH_ERROR  = 4,
   LLB_TG_CONFLICT    = 5,
   LLB_TG_NOT_ALLOWED = 6
  };

enum ENUM_LLB_EVENT
  {
   LLB_EV_NONE        = 0,
   LLB_EV_PLACED      = 1,
   LLB_EV_FAILED      = 2,
   LLB_EV_FILLED      = 3,
   LLB_EV_EXPIRED     = 4,
   LLB_EV_CANCELLED   = 5,
   LLB_EV_REJECTED    = 6,
   LLB_EV_ORPHAN      = 7,
   LLB_EV_POS_CLOSED  = 8,
   LLB_EV_POS_INFO    = 9
  };

//+------------------------------------------------------------------+
//| Data structures                                                  |
//+------------------------------------------------------------------+
struct LLBSymbolSpec
  {
   string            name;
   int               digits;
   double            point;
   double            tickSize;
   double            tickValue;
   double            volMin;
   double            volMax;
   double            volStep;
   double            volLimit;
   double            contract;
   long              stopsLevel;
   long              freezeLevel;
   long              expirationMode;
   long              fillingMode;
   long              orderMode;
   long              tradeMode;
   long              execMode;
   bool              valid;
   void              Reset(void)
     {
      name="";
      digits=0;
      point=0.0;
      tickSize=0.0;
      tickValue=0.0;
      volMin=0.0;
      volMax=0.0;
      volStep=0.0;
      volLimit=0.0;
      contract=0.0;
      stopsLevel=0;
      freezeLevel=0;
      expirationMode=0;
      fillingMode=0;
      orderMode=0;
      tradeMode=0;
      execMode=0;
      valid=false;
     }
  };

struct LLBSwingPoint
  {
   double            price;
   datetime          time;
   int               shift;
   bool              valid;
   void              Reset(void) { price=0.0; time=0; shift=-1; valid=false; }
  };

struct LLBLevels
  {
   double            pdh;       // P1
   double            pdl;       // P2
   double            p3;
   double            p4;
   datetime          p3Time;
   datetime          p4Time;
   datetime          d1Time;    // open time of the D1 bar used for PDH/PDL
   bool              valid;
   string            why;
   void              Reset(void)
     {
      pdh=0.0;
      pdl=0.0;
      p3=0.0;
      p4=0.0;
      p3Time=0;
      p4Time=0;
      d1Time=0;
      valid=false;
      why="";
     }
  };

struct LLBSignalCandidate
  {
   string            symbol;
   int               strategy;
   int               direction;
   int               level;
   double            levelPrice;
   datetime          signalBarTime;   // open time of the closed signal (confirmation) candle
   double            atr;
   double            entry;
   double            refSwingPrice;
   datetime          refSwingTime;
   string            reason;
   bool              valid;
   void              Reset(void)
     {
      symbol="";
      strategy=-1;
      direction=-1;
      level=LLB_LVL_NONE;
      levelPrice=0.0;
      signalBarTime=0;
      atr=0.0;
      entry=0.0;
      refSwingPrice=0.0;
      refSwingTime=0;
      reason="";
      valid=false;
     }
  };

struct LLBTradeProposal
  {
   string            signalId;
   string            symbol;
   int               strategy;
   int               direction;
   int               level;
   double            levelPrice;
   double            entry;
   double            sl;
   double            tp;
   double            rr;
   double            atr;
   double            bid;
   double            ask;
   int               spreadPoints;
   int               digits;
   datetime          createdTime;
   datetime          expiresTime;
   datetime          signalBarTime;
   double            refSwingPrice;
   datetime          refSwingTime;
   long              monitorFromMsc;   // invalidation monitored from the signal candle close
   int               state;
   string            stateReason;
   int               decision;
   long              decisionUser;
   datetime          decisionTime;
   long              tgMessageId;
   string            execId;
   string            reason;
   //--- runtime only (not persisted)
   long              checkedMsc;
   void              Reset(void)
     {
      signalId="";
      symbol="";
      strategy=-1;
      direction=-1;
      level=LLB_LVL_NONE;
      levelPrice=0.0;
      entry=0.0;
      sl=0.0;
      tp=0.0;
      rr=0.0;
      atr=0.0;
      bid=0.0;
      ask=0.0;
      spreadPoints=0;
      digits=2;
      createdTime=0;
      expiresTime=0;
      signalBarTime=0;
      refSwingPrice=0.0;
      refSwingTime=0;
      monitorFromMsc=0;
      state=LLB_PS_ACTIVE;
      stateReason="";
      decision=LLB_DEC_NONE;
      decisionUser=0;
      decisionTime=0;
      tgMessageId=0;
      execId="";
      reason="";
      checkedMsc=0;
     }
  };

struct LLBExecutionRecord
  {
   string            execId;
   string            signalId;
   string            symbol;
   int               direction;
   int               orderType;        // ENUM_ORDER_TYPE as int
   int               state;            // ENUM_LLB_EXEC_STATE
   int               orderState;       // ENUM_LLB_ORDER_STATE
   double            volume;
   double            entry;
   double            sl;
   double            tp;
   datetime          expiration;
   int               typeTime;         // ENUM_ORDER_TYPE_TIME as int
   int               filling;          // ENUM_ORDER_TYPE_FILLING as int
   long              submitMsc;
   uint              retcode;
   string            retComment;
   ulong             orderTicket;
   ulong             dealTicket;
   long              positionId;
   double            fillPrice;
   double            fillVolume;
   double            refSwingPrice;
   long              monitorFromMsc;
   int               structState;
   string            cancelReason;     // non-empty => EA requested the deletion
   string            note;
   //--- runtime only
   long              checkedMsc;
   long              lastActionMs;
   int               actionAttempts;
   bool              historyWarned;
   void              Reset(void)
     {
      execId="";
      signalId="";
      symbol="";
      direction=-1;
      orderType=-1;
      state=LLB_EX_NONE;
      orderState=LLB_OS_NONE;
      volume=0.0;
      entry=0.0;
      sl=0.0;
      tp=0.0;
      expiration=0;
      typeTime=0;
      filling=0;
      submitMsc=0;
      retcode=0;
      retComment="";
      orderTicket=0;
      dealTicket=0;
      positionId=0;
      fillPrice=0.0;
      fillVolume=0.0;
      refSwingPrice=0.0;
      monitorFromMsc=0;
      structState=LLB_ST_INTACT;
      cancelReason="";
      note="";
      checkedMsc=0;
      lastActionMs=0;
      actionAttempts=0;
      historyWarned=false;
     }
  };

struct LLBManagedPosition
  {
   long              positionId;
   string            execId;
   string            signalId;
   string            symbol;
   int               direction;
   double            volume;
   double            openPrice;
   double            sl;
   double            tp;
   double            expectedSl;
   double            expectedTp;
   datetime          openTime;
   int               state;            // ENUM_LLB_POS_STATE
   int               structState;
   int               ownership;
   bool              sltpVerified;
   double            refSwingPrice;
   long              monitorFromMsc;
   datetime          closeTime;
   double            closePrice;
   double            profit;
   double            commission;
   double            swap;
   double            fee;
   int               closeReason;
   string            closeNote;
   //--- runtime only
   double            floating;
   long              checkedMsc;
   long              lastCloseMs;
   int               closeAttempts;
   long              lastSltpMs;
   int               sltpAttempts;
   bool              closeRequested;
   bool              conflictNotified;
   bool              exhaustedNotified;
   void              Reset(void)
     {
      positionId=0;
      execId="";
      signalId="";
      symbol="";
      direction=-1;
      volume=0.0;
      openPrice=0.0;
      sl=0.0;
      tp=0.0;
      expectedSl=0.0;
      expectedTp=0.0;
      openTime=0;
      state=LLB_POS_OPEN;
      structState=LLB_ST_INTACT;
      ownership=LLB_OWN_OK;
      sltpVerified=false;
      refSwingPrice=0.0;
      monitorFromMsc=0;
      closeTime=0;
      closePrice=0.0;
      profit=0.0;
      commission=0.0;
      swap=0.0;
      fee=0.0;
      closeReason=LLB_CR_NONE;
      closeNote="";
      floating=0.0;
      checkedMsc=0;
      lastCloseMs=0;
      closeAttempts=0;
      lastSltpMs=0;
      sltpAttempts=0;
      closeRequested=false;
      conflictNotified=false;
      exhaustedNotified=false;
     }
  };

struct LLBTelegramCallback
  {
   long              updateId;
   string            queryId;
   long              fromId;
   long              chatId;
   long              messageId;
   string            data;
   void              Reset(void) { updateId=0; queryId=""; fromId=0; chatId=0; messageId=0; data=""; }
  };

struct LLBExecEvent
  {
   int               type;      // ENUM_LLB_EVENT
   int               index;     // execution or position index
   long              positionId;
   string            text;
  };

#endif
//+------------------------------------------------------------------+
