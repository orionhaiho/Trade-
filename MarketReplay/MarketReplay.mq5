//+------------------------------------------------------------------+
//|                                                 MarketReplay.mq5 |
//|  Market replay helper for MT5 Strategy Tester (Visual Mode).     |
//|                                                                  |
//|  PURPOSE: watch historical XAUUSDm candles form, with one RSI.   |
//|  THIS EA NEVER TRADES. It contains no trade calls, no signals,   |
//|  no position/risk management and does not include Trade.mqh.     |
//|                                                                  |
//|  Responsibilities:                                               |
//|   - check environment (Tester / Visual), symbol and timeframe    |
//|     and log the result (it never changes symbol or timeframe);   |
//|   - apply the chart colour scheme via ChartSetInteger and verify |
//|     each property with ChartGetInteger;                          |
//|   - create exactly one built-in RSI(14, PRICE_CLOSE) handle.     |
//|     The Strategy Tester displays indicators created by the EA    |
//|     on the visual chart automatically, so ChartIndicatorAdd is   |
//|     intentionally NOT called (prevents a duplicate RSI window).  |
//|                                                                  |
//|  Replay (Play/Pause/speed, dates, symbol, timeframe) is handled  |
//|  entirely by the Strategy Tester UI.                             |
//+------------------------------------------------------------------+
#property copyright   "MarketReplay"
#property version     "1.00"
#property description "MarketReplay: xem lai lich su XAUUSDm trong Strategy Tester (Visual Mode)."
#property description "Chi cau hinh mau chart va hien thi mot RSI(14, Close). KHONG giao dich."

//--- Target configuration (from the project specification)
#define MR_TARGET_SYMBOL   "XAUUSDm"
#define MR_RSI_PERIOD      14
#define MR_RSI_PRICE       PRICE_CLOSE
#define MR_LOG_PREFIX      "[MarketReplay] "

//--- Timeframes supported by the specification
const ENUM_TIMEFRAMES MR_ALLOWED_TF[] =
  {
   PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4
  };

//--- Chart colour scheme. Three parallel arrays (same index = same row).
const ENUM_CHART_PROPERTY_INTEGER MR_COLOR_PROP[] =
  {
   CHART_COLOR_BACKGROUND,
   CHART_COLOR_FOREGROUND,
   CHART_COLOR_GRID,
   CHART_COLOR_CHART_UP,
   CHART_COLOR_CHART_DOWN,
   CHART_COLOR_CANDLE_BULL,
   CHART_COLOR_CANDLE_BEAR,
   CHART_COLOR_CHART_LINE,
   CHART_COLOR_VOLUME,
   CHART_COLOR_BID,
   CHART_COLOR_ASK,
   CHART_COLOR_LAST,
   CHART_COLOR_STOP_LEVEL
  };

const color MR_COLOR_VALUE[] =
  {
   clrBlack,            // Background
   clrWhite,            // Foreground
   clrDimGray,          // Grid
   clrMediumTurquoise,  // Bar Up
   clrTomato,           // Bar Down
   clrMediumTurquoise,  // Bull Candle
   clrTomato,           // Bear Candle
   clrMediumTurquoise,  // Line Graph
   clrMediumTurquoise,  // Volumes
   clrDimGray,          // Bid Line
   clrRed,              // Ask Line
   clrMediumTurquoise,  // Last Price Line
   clrRed               // Stop Levels
  };

const string MR_COLOR_NAME[] =
  {
   "CHART_COLOR_BACKGROUND (Background)",
   "CHART_COLOR_FOREGROUND (Foreground)",
   "CHART_COLOR_GRID (Grid)",
   "CHART_COLOR_CHART_UP (Bar Up)",
   "CHART_COLOR_CHART_DOWN (Bar Down)",
   "CHART_COLOR_CANDLE_BULL (Bull Candle)",
   "CHART_COLOR_CANDLE_BEAR (Bear Candle)",
   "CHART_COLOR_CHART_LINE (Line Graph)",
   "CHART_COLOR_VOLUME (Volumes)",
   "CHART_COLOR_BID (Bid Line)",
   "CHART_COLOR_ASK (Ask Line)",
   "CHART_COLOR_LAST (Last Price Line)",
   "CHART_COLOR_STOP_LEVEL (Stop Levels)"
  };

//--- The single RSI handle owned by this EA
int g_rsi_handle = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| Logging helpers                                                  |
//+------------------------------------------------------------------+
void LogInfo(const string msg)  { Print(MR_LOG_PREFIX, "INFO: ",    msg); }
void LogWarn(const string msg)  { Print(MR_LOG_PREFIX, "WARNING: ", msg); }
void LogError(const string msg) { Print(MR_LOG_PREFIX, "ERROR: ",   msg); }

//+------------------------------------------------------------------+
//| Environment check: Strategy Tester / Visual Mode.                |
//| Returns false only when the EA is not running in the Tester.     |
//+------------------------------------------------------------------+
bool CheckEnvironment()
  {
   const bool is_tester  = (bool)MQLInfoInteger(MQL_TESTER);
   const bool is_visual  = (bool)MQLInfoInteger(MQL_VISUAL_MODE);
   const bool is_optimiz = (bool)MQLInfoInteger(MQL_OPTIMIZATION);

   LogInfo(StringFormat("Environment: tester=%s, visual=%s, optimization=%s",
                        (is_tester ? "yes" : "no"),
                        (is_visual ? "yes" : "no"),
                        (is_optimiz ? "yes" : "no")));

   if(!is_tester)
     {
      LogError("EA chi danh cho Strategy Tester (Visual Mode). Khong chay tren chart thuc.");
      return(false);
     }
   if(is_optimiz)
      LogWarn("Dang o che do Optimization: khong co chart de xem. Hay tat Optimization.");
   else
      if(!is_visual)
         LogWarn("Visual Mode dang TAT: se khong co chart de xem. Bat 'Visual mode' trong Strategy Tester.");
   return(true);
  }

//+------------------------------------------------------------------+
//| Symbol check. Only reads and reports; never switches symbol.     |
//+------------------------------------------------------------------+
void CheckSymbol()
  {
   if(_Symbol == MR_TARGET_SYMBOL)
      LogInfo(StringFormat("Symbol: %s (dung symbol muc tieu).", _Symbol));
   else
      LogWarn(StringFormat("Symbol dang test la '%s', KHAC symbol muc tieu '%s'. "
                           "EA van chay tren '%s' va KHONG tu doi symbol. "
                           "Neu broker co %s, hay chon no trong Strategy Tester.",
                           _Symbol, MR_TARGET_SYMBOL, _Symbol, MR_TARGET_SYMBOL));

   LogInfo(StringFormat("Symbol info (doc tu broker, khong hard-code): digits=%d, point=%s",
                        (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS),
                        DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_POINT),
                                       (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS))));
  }

//+------------------------------------------------------------------+
//| Timeframe check. Only reads and reports; never changes period.   |
//+------------------------------------------------------------------+
void CheckTimeframe()
  {
   const ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)_Period;
   bool allowed = false;
   for(int i = 0; i < ArraySize(MR_ALLOWED_TF); i++)
     {
      if(MR_ALLOWED_TF[i] == tf)
        {
         allowed = true;
         break;
        }
     }

   if(allowed)
      LogInfo(StringFormat("Timeframe: %s (nam trong M1/M5/M15/M30/H1/H4).", EnumToString(tf)));
   else
      LogWarn(StringFormat("Timeframe %s khong nam trong danh sach M1/M5/M15/M30/H1/H4. "
                           "EA van chay; hay chon lai timeframe trong Strategy Tester neu can.",
                           EnumToString(tf)));
  }

//+------------------------------------------------------------------+
//| Apply the colour scheme. ChartSetInteger is asynchronous (it only |
//| queues a command), so each property is read back with the        |
//| synchronous ChartGetInteger to confirm it was really applied.     |
//| Returns the number of properties confirmed.                       |
//+------------------------------------------------------------------+
int ApplyChartColors()
  {
   const long chart_id = 0; // current chart (the visual testing chart)
   const int  total    = ArraySize(MR_COLOR_PROP);
   int        queued   = 0;

   //--- Pass 1: queue all changes
   bool queued_ok[];
   ArrayResize(queued_ok, total);
   for(int i = 0; i < total; i++)
     {
      ResetLastError();
      queued_ok[i] = ChartSetInteger(chart_id, MR_COLOR_PROP[i], (long)MR_COLOR_VALUE[i]);
      if(queued_ok[i])
         queued++;
      else
         LogError(StringFormat("ChartSetInteger(%s, %s) that bai, GetLastError()=%d",
                               MR_COLOR_NAME[i], ColorToString(MR_COLOR_VALUE[i], true),
                               GetLastError()));
     }
   ChartRedraw(chart_id);

   //--- Pass 2: verify with the synchronous getter
   int confirmed = 0;
   for(int i = 0; i < total; i++)
     {
      if(!queued_ok[i])
         continue;
      long actual = 0;
      ResetLastError();
      if(!ChartGetInteger(chart_id, MR_COLOR_PROP[i], 0, actual))
        {
         LogError(StringFormat("ChartGetInteger(%s) that bai, GetLastError()=%d",
                               MR_COLOR_NAME[i], GetLastError()));
         continue;
        }
      if((color)actual == MR_COLOR_VALUE[i])
        {
         confirmed++;
         LogInfo(StringFormat("Mau OK: %s = %s", MR_COLOR_NAME[i],
                              ColorToString(MR_COLOR_VALUE[i], true)));
        }
      else
         LogWarn(StringFormat("Mau KHONG khop: %s mong doi %s, thuc te %s",
                              MR_COLOR_NAME[i], ColorToString(MR_COLOR_VALUE[i], true),
                              ColorToString((color)actual, true)));
     }

   LogInfo(StringFormat("Chart colours: %d/%d da xep hang, %d/%d xac nhan bang ChartGetInteger.",
                        queued, total, confirmed, total));
   return(confirmed);
  }

//+------------------------------------------------------------------+
//| Release the RSI handle.                                           |
//| Note (MQL5 Reference): in the Strategy Tester IndicatorRelease()  |
//| is not executed; the call is kept for correct lifecycle.          |
//+------------------------------------------------------------------+
void ReleaseRSI()
  {
   if(g_rsi_handle == INVALID_HANDLE)
      return;
   ResetLastError();
   if(!IndicatorRelease(g_rsi_handle))
      LogWarn(StringFormat("IndicatorRelease(%d) tra ve false, GetLastError()=%d",
                           g_rsi_handle, GetLastError()));
   g_rsi_handle = INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//| Create the single built-in RSI handle.                            |
//| In the Strategy Tester, indicators created by the EA are shown on |
//| the visual chart automatically (TesterHideIndicators default =    |
//| false), RSI in its own subwindow. No ChartIndicatorAdd is needed. |
//+------------------------------------------------------------------+
bool CreateRSI()
  {
   //--- Guard against duplicates on re-initialisation
   if(g_rsi_handle != INVALID_HANDLE)
     {
      LogWarn("RSI handle da ton tai tu lan khoi tao truoc; giai phong truoc khi tao lai.");
      ReleaseRSI();
     }

   ResetLastError();
   g_rsi_handle = iRSI(_Symbol, _Period, MR_RSI_PERIOD, MR_RSI_PRICE);
   if(g_rsi_handle == INVALID_HANDLE)
     {
      LogError(StringFormat("iRSI(%s, %s, %d, PRICE_CLOSE) that bai, GetLastError()=%d",
                            _Symbol, EnumToString((ENUM_TIMEFRAMES)_Period),
                            MR_RSI_PERIOD, GetLastError()));
      return(false);
     }

   LogInfo(StringFormat("Da tao RSI(%d, PRICE_CLOSE) built-in, handle=%d. "
                        "Strategy Tester tu hien thi RSI o subwindow. "
                        "Muc RSI la muc mac dinh cua RSI built-in (khong co muc 50 - ngoai le da duoc chap thuan).",
                        MR_RSI_PERIOD, g_rsi_handle));
   return(true);
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   LogInfo("Khoi tao MarketReplay v1.00 (khong giao dich).");

   if(!CheckEnvironment())
      return(INIT_FAILED);

   CheckSymbol();
   CheckTimeframe();
   ApplyChartColors();   // colour failures are logged, they do not stop the replay

   if(!CreateRSI())
      return(INIT_FAILED);

   LogInfo("San sang. Dieu khien Play/Pause/toc do bang thanh dieu khien cua Strategy Tester.");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ReleaseRSI();
   LogInfo(StringFormat("Ket thuc, deinit reason=%d.", reason));
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//| Intentionally empty: the replay is driven by the Strategy Tester  |
//| and the RSI is drawn by the terminal. No per-tick processing, no |
//| trading. Kept only as a defensive entry point for the Tester.    |
//+------------------------------------------------------------------+
void OnTick()
  {
  }
//+------------------------------------------------------------------+
