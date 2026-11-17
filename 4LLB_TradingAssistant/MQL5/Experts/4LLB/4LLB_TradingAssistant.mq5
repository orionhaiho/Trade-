//+------------------------------------------------------------------+
//| 4LLB_TradingAssistant.mq5                                        |
//| 4LLB Human-Approved Trading Assistant v2.0 (MT5 / MQL5)          |
//|                                                                  |
//| - Analyses XAUUSD / XAUUSDc on D1 + M15 (4 liquidity levels,     |
//|   Pivot 3-3, Liquidity Sweep + Breakout)                         |
//| - Sends every proposal to Telegram with ACCEPT / REJECT buttons  |
//| - Places a pending Buy Stop / Sell Stop ONLY after a valid       |
//|   ACCEPT; never trades on its own; never converts to market      |
//|                                                                  |
//| Install: copy MQL5\Include\4LLB\*.mqh and this file into the     |
//| terminal data folder (see Documentation/Installation_Guide.md).  |
//| STATUS: written without MetaEditor in this environment - compile |
//| on your terminal (F7) and report the Errors tab.                 |
//+------------------------------------------------------------------+
#property copyright   "4LLB Trading Assistant"
#property version     "2.00"
#property description "4LLB Human-Approved Trading Assistant v2.0 - D1 + M15 liquidity levels, Sweep + Breakout."
#property description "Every proposal goes to Telegram: NO trade is placed without your ACCEPT."
#property description "Pending Buy Stop / Sell Stop only, swing-based SL, TP at RR 1:2, touch-based invalidation."

#include <4LLB\LLB_Coordinator.mqh>

//+------------------------------------------------------------------+
//| Inputs                                                           |
//| SRS strategy constants (ATR multiples, RR, buffer, expiry, Pivot |
//| 3-3) are NOT inputs - see LLB_Defines.mqh.                       |
//+------------------------------------------------------------------+
input group "=== 1. Symbols & analysis ==="
input string             InpSymbols              = "XAUUSD,XAUUSDc";            // Symbols (comma separated; unavailable ones are disabled)
input ENUM_TIMEFRAMES    InpAtrTimeframe         = PERIOD_M15;                  // ATR(14) timeframe [decision D-03]
input ENUM_LLB_NEAREST   InpLevelNearestMode     = LLB_NEAREST_PRICE;           // P3/P4 "nearest" [decision D-02]
input ENUM_LLB_SWING_REF InpSwingRefMode         = LLB_SWINGREF_SETUP_EXTREME;  // Swing for SL / invalidation [decision D-01]
input int                InpSwingLookbackBars    = 672;                         // P3/P4 search window in M15 bars (672 = 7 days)
input bool               InpEnableSweep          = true;                        // Liquidity Sweep strategy
input bool               InpEnableBreakout       = true;                        // Breakout strategy
input int                InpMaxStartupBarAgeSec  = 60;                          // Start-up: evaluate the last bar only if closed <= N s ago

input group "=== 2. Volume & risk (your decision) ==="
input ENUM_LLB_LOT_MODE  InpLotMode              = LLB_LOT_FIXED;               // Volume mode [decision D-04]
input double             InpLotSize              = 0.01;                        // Fixed LotSize (exact; invalid => order refused)
input double             InpRiskPercent          = 0.50;                        // RiskPercent per trade (RiskPercent mode only)
input ENUM_LLB_RISK_BASE InpRiskBase             = LLB_RISK_BALANCE;            // RiskPercent base
input double             InpDailyLossLimit       = 0.0;                         // Daily loss limit, account currency (0 = off)

input group "=== 3. Execution ==="
input long               InpMagicNumber          = 4112026;                     // Magic number (identifies EA orders/positions)
input int                InpCloseDeviationPoints = 50;                          // Max slippage (points) when closing on invalidation
input bool               InpAllowEaManagedExpiry = false;                       // Broker without SPECIFIED expiry: GTC + EA deletes (EA must stay online)

input group "=== 4. Telegram approval ==="
input bool               InpTelegramEnabled      = true;                        // Telegram approval (required to trade live)
input string             InpTgBotToken           = "";                          // Bot token - leave EMPTY to read MQL5\Files\4LLB\telegram_token.txt
input long               InpTgChatId             = 0;                           // Your Telegram chat id
input string             InpTgAllowedUserIds     = "";                          // User ids allowed to press ACCEPT/REJECT (comma separated; empty = chat id)
input int                InpTgPollIntervalMs     = 1500;                        // getUpdates interval (ms, >= 1000)
input int                InpTgHttpTimeoutMs      = 5000;                        // HTTP timeout (ms, 1000..15000)

input group "=== 5. Dashboard & logs ==="
input bool               InpShowDashboard        = true;                        // Show the chart dashboard
input ENUM_LLB_LOG_LEVEL InpLogLevel             = LLB_LOG_INFO;                // Log level
input bool               InpLogToFile            = true;                        // Also write daily log files

input group "=== 6. Strategy Tester only ==="
input bool               InpTesterAutoApprove    = false;                       // Tester: simulate ACCEPT for each proposal (refused on live charts)

CLLBCoordinator g_llbCoordinator;

//+------------------------------------------------------------------+
int OnInit(void)
  {
   LLBConfig cfg;
   cfg.symbols            =InpSymbols;
   cfg.atrTf              =InpAtrTimeframe;
   cfg.nearestMode        =(int)InpLevelNearestMode;
   cfg.swingRefMode       =(int)InpSwingRefMode;
   cfg.lookback           =InpSwingLookbackBars;
   cfg.enableSweep        =InpEnableSweep;
   cfg.enableBreakout     =InpEnableBreakout;
   cfg.maxStartupBarAgeSec=InpMaxStartupBarAgeSec;
   cfg.lotMode            =(int)InpLotMode;
   cfg.lotSize            =InpLotSize;
   cfg.riskPct            =InpRiskPercent;
   cfg.riskBase           =(int)InpRiskBase;
   cfg.dailyLossLimit     =InpDailyLossLimit;
   cfg.magic              =InpMagicNumber;
   cfg.closeDeviation     =InpCloseDeviationPoints;
   cfg.allowEaExpiry      =InpAllowEaManagedExpiry;
   cfg.tgEnabled          =InpTelegramEnabled;
   cfg.tgToken            =InpTgBotToken;
   cfg.tgChatId           =InpTgChatId;
   cfg.tgAllowed          =InpTgAllowedUserIds;
   cfg.tgPollMs           =InpTgPollIntervalMs;
   cfg.tgTimeoutMs        =InpTgHttpTimeoutMs;
   cfg.showDashboard      =InpShowDashboard;
   cfg.logLevel           =(int)InpLogLevel;
   cfg.logToFile          =InpLogToFile;
   cfg.testerAutoApprove  =InpTesterAutoApprove;
   return g_llbCoordinator.OnInitEA(cfg);
  }

void OnDeinit(const int reason)
  {
   g_llbCoordinator.OnDeinitEA(reason);
  }

void OnTimer(void)
  {
   g_llbCoordinator.OnTimerEA();
  }

void OnTick(void)
  {
   g_llbCoordinator.OnTickEA();
  }

void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result)
  {
   g_llbCoordinator.OnTradeTransactionEA();
  }
//+------------------------------------------------------------------+
