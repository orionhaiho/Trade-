//+------------------------------------------------------------------+
//| 4LLB_UnitTests.mq5                                               |
//| Unit tests of the pure 4LLB logic (no trading, no network).      |
//| Run: drag onto any chart (Navigator > Scripts > 4LLB).           |
//| Result: Experts tab -> "4LLB UNIT TESTS: N passed, M failed".    |
//| Every failure prints "FAIL <test name>".                         |
//+------------------------------------------------------------------+
#property copyright "4LLB Trading Assistant"
#property version   "2.00"
#property description "Unit tests for 4LLB Trading Assistant v2.0 (pure functions only)."

#include <4LLB\LLB_Defines.mqh>
#include <4LLB\LLB_Utils.mqh>
#include <4LLB\LLB_Logger.mqh>
#include <4LLB\LLB_Json.mqh>
#include <4LLB\LLB_Levels.mqh>
#include <4LLB\LLB_StopLoss.mqh>
#include <4LLB\LLB_Strategy.mqh>
#include <4LLB\LLB_Persistence.mqh>
#include <4LLB\LLB_Proposals.mqh>
#include <4LLB\LLB_Telegram.mqh>
#include <4LLB\LLB_Messages.mqh>

int g_pass=0;
int g_fail=0;

void T(const bool cond,const string name)
  {
   if(cond)
      g_pass++;
   else
     {
      g_fail++;
      Print("FAIL  ",name);
     }
  }

bool Eq(const double a,const double b,const double eps=1e-9) { return MathAbs(a-b)<=eps; }

//+------------------------------------------------------------------+
//| Synthetic bars: built oldest-first, returned as a SERIES array   |
//| (index 0 = newest / forming bar)                                 |
//+------------------------------------------------------------------+
MqlRates g_chrono[];

void BarsFlat(const int count)
  {
   ArrayResize(g_chrono,count);
   for(int i=0; i<count; i++)
     {
      g_chrono[i].time=(datetime)((long)D'2026.11.16 00:00'+(long)i*900);
      g_chrono[i].open=100.0;
      g_chrono[i].high=101.0;
      g_chrono[i].low=99.0;
      g_chrono[i].close=100.0;
      g_chrono[i].tick_volume=1;
      g_chrono[i].spread=0;
      g_chrono[i].real_volume=0;
     }
  }

//--- set a bar by SERIES index (0 = newest)
void BarS(const int s,const double o,const double h,const double l,const double c)
  {
   int n=ArraySize(g_chrono);
   int i=n-1-s;
   g_chrono[i].open=o;
   g_chrono[i].high=h;
   g_chrono[i].low=l;
   g_chrono[i].close=c;
  }

int Series(MqlRates &r[])
  {
   int n=ArraySize(g_chrono);
   ArrayResize(r,n);
   for(int i=0; i<n; i++)
      r[i]=g_chrono[n-1-i];
   return n;
  }

void BaseLevels(LLBLevels &lv)
  {
   lv.Reset();
   lv.pdh=104.0;
   lv.pdl=96.0;
   lv.p3=94.0;
   lv.p4=106.0;
   lv.valid=true;
   lv.why="OK";
  }

//+------------------------------------------------------------------+
void TestNormalisation(void)
  {
   T(Eq(LLB_RoundToTick(2650.374,0.01,-1),2650.37,1e-9),"U-NORM-01 round down 0.01");
   T(Eq(LLB_RoundToTick(2650.374,0.01,1),2650.38,1e-9),"U-NORM-02 round up 0.01");
   T(Eq(LLB_RoundToTick(2650.374,0.01,0),2650.37,1e-9),"U-NORM-03 round nearest 0.01");
   T(Eq(LLB_NormPrice(2650.37,0.01,2,-1),2650.37),"U-NORM-04 on-grid value stays (down)");
   T(Eq(LLB_NormPrice(2650.37,0.01,2,1),2650.37),"U-NORM-05 on-grid value stays (up)");
   T(Eq(LLB_NormPrice(4000.0005,0.001,3,-1),4000.000),"U-NORM-06 tick 0.001 down");
   T(Eq(LLB_NormPrice(4000.0005,0.001,3,1),4000.001),"U-NORM-07 tick 0.001 up");
   T(Eq(LLB_NormPrice(1.234,0.05,2,-1),1.20),"U-NORM-08 tick 0.05 (tick != point) down");
   T(Eq(LLB_NormPrice(1.234,0.05,2,1),1.25),"U-NORM-09 tick 0.05 up");
   T(LLB_PriceAbove(104.01,104.0,0.01) && !LLB_PriceAbove(104.0,104.0,0.01),"U-NORM-10 strict grid comparison");
  }

void TestVolume(void)
  {
   string why;
   T(LLB_IsValidVolume(0.01,0.01,100,0.01),"U-VOL-01 0.01 valid");
   T(!LLB_IsValidVolume(0.015,0.01,100,0.01),"U-VOL-02 0.015 not a step multiple -> refused (no rounding)");
   T(!LLB_IsValidVolume(0.005,0.01,100,0.01),"U-VOL-02b below min refused");
   T(!LLB_IsValidVolume(101,0.01,100,0.01),"U-VOL-02c above max refused");
   T(Eq(LLB_VolumeDown(0.0199,0.01),0.01),"U-VOL-03 volume rounded DOWN");
   T(Eq(LLB_VolumeDown(0.03,0.01),0.03),"U-VOL-03b exact multiple kept");
   T(Eq(LLB_CalcRiskLots(10.0,650.0,0.01,100,0.01,why),0.01),"U-VOL-04 risk 10 / loss 650 per lot -> 0.01");
   double v=LLB_CalcRiskLots(5.0,650.0,0.01,100,0.01,why);
   T(v==0.0 && StringFind(why,"BELOW_MIN")>=0,"U-VOL-05 below min lot -> refuse (never round up)");
   T(Eq(LLB_CalcRiskLots(1e6,1.0,0.01,50,0.01,why),50.0),"U-VOL-06 capped at max volume");
  }

void TestPivots(void)
  {
   MqlRates r[];
   LLBSwingPoint sp;
   BarsFlat(14);
   BarS(3,100,110,99,100);                              // peak with only 3 newer bars (0..2)
   int n=Series(r);
   T(LLB_IsPivotHigh(r,n,3),"U-PIV-01 shape is a pivot high");
   T(!LLB_FindSwingBeyond(r,n,1,true,105,false,100,LLB_NEAREST_PRICE,sp),"U-PIV-02 NOT confirmed as of bar 1 (3rd right bar still forming)");
   BarsFlat(15);
   BarS(4,100,110,99,100);                              // same peak, one more closed bar
   n=Series(r);
   T(LLB_FindSwingBeyond(r,n,1,true,105,false,100,LLB_NEAREST_PRICE,sp) && Eq(sp.price,110),"U-PIV-03 confirmed after 3 closed right bars");
   BarsFlat(15);
   BarS(4,100,110,99,100);
   BarS(5,100,110,99,100);                              // equal highs
   n=Series(r);
   T(!LLB_FindSwingBeyond(r,n,1,true,105,false,100,LLB_NEAREST_PRICE,sp),"U-PIV-04 equal highs are not a pivot (strict)");
   BarsFlat(15);
   BarS(4,100,101,90,100);
   n=Series(r);
   T(LLB_IsPivotLow(r,n,4) && LLB_FindSwingBeyond(r,n,1,false,95,false,100,LLB_NEAREST_PRICE,sp) && Eq(sp.price,90),"U-PIV-05 pivot low confirmed");
  }

void TestLevels(void)
  {
   MqlRates r[];
   LLBLevels lv;
   BarsFlat(40);
   BarS(34,100,106,99,100);   // A: older pivot high 106
   BarS(27,100,101,94,100);   // C: older pivot low 94
   BarS(19,100,108,99,100);   // B: newer pivot high 108
   BarS(12,100,101,92,100);   // D: newer pivot low 92
   int n=Series(r);
   T(LLB_ComputeLevels(r,n,1,104,96,0,100,LLB_NEAREST_PRICE,lv) && lv.valid,"U-LVL-01 levels valid");
   T(Eq(lv.p4,106) && Eq(lv.p3,94),"U-LVL-02 nearest by PRICE: P4=106 P3=94 (D-02)");
   T(LLB_ComputeLevels(r,n,1,104,96,0,100,LLB_NEAREST_TIME,lv) && Eq(lv.p4,108) && Eq(lv.p3,92),"U-LVL-03 nearest by TIME: P4=108 P3=92");
   T(!LLB_ComputeLevels(r,n,1,110,96,0,100,LLB_NEAREST_PRICE,lv) && lv.why=="P4_MISSING","U-LVL-04 missing P4 -> no levels");
   T(!LLB_ComputeLevels(r,n,1,104,96,0,10,LLB_NEAREST_PRICE,lv) && Eq(lv.p3,92) && lv.why=="P4_MISSING","U-LVL-05 lookback window respected");
   T(!LLB_ComputeLevels(r,n,1,96,104,0,100,LLB_NEAREST_PRICE,lv),"U-LVL-06 PDL >= PDH rejected");
   T(lv.p3<lv.pdl || !lv.valid,"U-LVL-07 order P3 < PDL < PDH < P4 enforced");
  }

void TestSweep(void)
  {
   MqlRates r[];
   LLBLevels lv;
   LLBSignalCandidate c;
   string why;
   BaseLevels(lv);
   BarsFlat(30);
   BarS(1,103.5,104.8,102.9,103.2);
   int n=Series(r);
   T(LLB_DetectSweep(r,n,1,lv,4.0,0.01,2,LLB_SWINGREF_SETUP_EXTREME,LLB_NEAREST_PRICE,100,"XAUUSD",c,why),"F-002 SELL sweep of P1 detected");
   T(c.direction==LLB_DIR_SELL && c.level==LLB_LVL_P1 && Eq(c.entry,102.89) && Eq(c.refSwingPrice,104.8),"F-002b entry = low - 1 tick, ref = sweep high");
   BarS(1,103.5,104.1,102.9,103.2);
   n=Series(r);
   T(!LLB_DetectSweep(r,n,1,lv,4.0,0.01,2,LLB_SWINGREF_SETUP_EXTREME,LLB_NEAREST_PRICE,100,"XAUUSD",c,why),"U-SWP-02 depth 0.1 < 0.05 ATR(4) -> none");
   BarS(1,103.5,104.8,102.9,103.2);
   n=Series(r);
   T(!LLB_DetectSweep(r,n,1,lv,1.0,0.01,2,LLB_SWINGREF_SETUP_EXTREME,LLB_NEAREST_PRICE,100,"XAUUSD",c,why),"U-SWP-03 depth 0.8 > 0.50 ATR(1) -> none");
   BarS(1,104.5,104.8,104.0,104.2);
   n=Series(r);
   T(!LLB_DetectSweep(r,n,1,lv,4.0,0.01,2,LLB_SWINGREF_SETUP_EXTREME,LLB_NEAREST_PRICE,100,"XAUUSD",c,why),"U-SWP-04 close not back below level -> none");
   BarS(1,103.0,104.8,102.9,103.4);
   n=Series(r);
   T(!LLB_DetectSweep(r,n,1,lv,4.0,0.01,2,LLB_SWINGREF_SETUP_EXTREME,LLB_NEAREST_PRICE,100,"XAUUSD",c,why),"U-SWP-05 bullish candle -> no SELL");
   BarS(1,103.8,106.6,103.0,103.5);
   n=Series(r);
   T(LLB_DetectSweep(r,n,1,lv,8.0,0.01,2,LLB_SWINGREF_SETUP_EXTREME,LLB_NEAREST_PRICE,100,"XAUUSD",c,why)
     && c.level==LLB_LVL_P4 && StringFind(c.reason,"also swept P1")>=0,"U-SWP-06 two levels swept -> outer level P4, one proposal");
   BarS(1,96.3,97.1,95.2,96.8);
   n=Series(r);
   T(LLB_DetectSweep(r,n,1,lv,4.0,0.01,2,LLB_SWINGREF_SETUP_EXTREME,LLB_NEAREST_PRICE,100,"XAUUSD",c,why)
     && c.direction==LLB_DIR_BUY && c.level==LLB_LVL_P2 && Eq(c.entry,97.11) && Eq(c.refSwingPrice,95.2),"F-003 BUY sweep of P2, entry = high + 1 tick");
   BarS(1,96.2,96.9,93.4,96.5);
   n=Series(r);
   T(LLB_DetectSweep(r,n,1,lv,8.0,0.01,2,LLB_SWINGREF_SETUP_EXTREME,LLB_NEAREST_PRICE,100,"XAUUSD",c,why) && c.level==LLB_LVL_P3,"U-SWP-07 BUY sweep P3 preferred over P2");
   //--- confirmed-pivot reference mode (input alternative to D-01)
   BarS(1,103.5,104.8,102.9,103.2);
   n=Series(r);
   T(!LLB_DetectSweep(r,n,1,lv,4.0,0.01,2,LLB_SWINGREF_CONFIRMED_PIVOT,LLB_NEAREST_PRICE,100,"XAUUSD",c,why) && why!="","U-SWP-08 pivot mode without pivot -> no proposal");
   BarS(10,100,106.0,99,100);
   n=Series(r);
   T(LLB_DetectSweep(r,n,1,lv,4.0,0.01,2,LLB_SWINGREF_CONFIRMED_PIVOT,LLB_NEAREST_PRICE,100,"XAUUSD",c,why) && Eq(c.refSwingPrice,106.0),"U-SWP-09 pivot mode uses confirmed pivot >= sweep high");
  }

void FillLv(LLBLevels &lvAt[],double &atrAt[],const double atr)
  {
   LLBLevels lv;
   BaseLevels(lv);
   ArrayResize(lvAt,8);
   ArrayResize(atrAt,8);
   for(int i=0; i<8; i++)
     {
      lvAt[i]=lv;
      atrAt[i]=atr;
     }
  }

void TestBreakout(void)
  {
   MqlRates r[];
   LLBLevels lvAt[];
   double atrAt[];
   LLBSignalCandidate c;
   string why;
   FillLv(lvAt,atrAt,4.0);
   //--- immediate retest (b = t+1)
   BarsFlat(30);
   BarS(3,105.0,105.8,104.8,105.5);
   BarS(2,105.5,107.3,105.4,107.0);
   BarS(1,106.5,107.4,106.3,107.2);
   int n=Series(r);
   T(LLB_DetectBreakout(r,n,1,lvAt,atrAt,0.01,2,LLB_SWINGREF_SETUP_EXTREME,LLB_NEAREST_PRICE,100,"XAUUSD",c,why)
     && c.direction==LLB_DIR_BUY && c.level==LLB_LVL_P4 && Eq(c.entry,107.41) && Eq(c.refSwingPrice,106.3),"F-004 BUY breakout P4 + retest + bullish confirm");
   //--- retest on the 4th candle after the breakout
   BarsFlat(30);
   BarS(6,105.0,105.8,104.8,105.5);
   BarS(5,105.5,107.3,105.4,107.0);
   BarS(4,107.5,108.0,107.0,107.8);
   BarS(3,107.5,108.0,107.0,107.8);
   BarS(2,107.5,108.0,107.0,107.8);
   BarS(1,106.8,107.6,106.4,107.3);
   n=Series(r);
   T(LLB_DetectBreakout(r,n,1,lvAt,atrAt,0.01,2,LLB_SWINGREF_SETUP_EXTREME,LLB_NEAREST_PRICE,100,"XAUUSD",c,why)
     && Eq(c.refSwingPrice,106.4),"U-BRK-03 retest within 4 candles accepted");
   //--- 5th candle: setup expired
   BarsFlat(30);
   BarS(7,105.0,105.8,104.8,105.5);
   BarS(6,105.5,107.3,105.4,107.0);
   BarS(5,107.5,108.0,107.0,107.8);
   BarS(4,107.5,108.0,107.0,107.8);
   BarS(3,107.5,108.0,107.0,107.8);
   BarS(2,107.5,108.0,107.0,107.8);
   BarS(1,106.8,107.6,106.4,107.3);
   n=Series(r);
   T(!LLB_DetectBreakout(r,n,1,lvAt,atrAt,0.01,2,LLB_SWINGREF_SETUP_EXTREME,LLB_NEAREST_PRICE,100,"XAUUSD",c,why),"F-006 no retest within 4 candles -> setup expired");
   //--- consumed by an earlier retest confirmation
   BarsFlat(30);
   BarS(4,105.0,105.8,104.8,105.5);
   BarS(3,105.5,107.3,105.4,107.0);
   BarS(2,106.5,107.2,106.2,107.0);
   BarS(1,106.6,107.4,106.3,107.2);
   n=Series(r);
   T(!LLB_DetectBreakout(r,n,1,lvAt,atrAt,0.01,2,LLB_SWINGREF_SETUP_EXTREME,LLB_NEAREST_PRICE,100,"XAUUSD",c,why),"U-BRK-07 only the first retest confirmation signals");
   //--- retest too deep
   BarsFlat(30);
   BarS(3,105.0,105.8,104.8,105.5);
   BarS(2,105.5,107.3,105.4,107.0);
   BarS(1,105.6,107.4,105.2,107.2);
   n=Series(r);
   T(!LLB_DetectBreakout(r,n,1,lvAt,atrAt,0.01,2,LLB_SWINGREF_SETUP_EXTREME,LLB_NEAREST_PRICE,100,"XAUUSD",c,why),"U-BRK-05 retest deeper than 0.15 ATR -> none");
   //--- bearish confirmation candle
   BarsFlat(30);
   BarS(3,105.0,105.8,104.8,105.5);
   BarS(2,105.5,107.3,105.4,107.0);
   BarS(1,107.2,107.4,106.3,106.5);
   n=Series(r);
   T(!LLB_DetectBreakout(r,n,1,lvAt,atrAt,0.01,2,LLB_SWINGREF_SETUP_EXTREME,LLB_NEAREST_PRICE,100,"XAUUSD",c,why),"U-BRK-06 bearish candle does not confirm a BUY");
   //--- close not beyond P4 + 0.10 ATR
   BarsFlat(30);
   BarS(3,105.0,105.8,104.8,105.5);
   BarS(2,105.5,106.6,105.4,106.3);
   BarS(1,106.5,107.4,106.3,107.2);
   n=Series(r);
   T(!LLB_DetectBreakout(r,n,1,lvAt,atrAt,0.01,2,LLB_SWINGREF_SETUP_EXTREME,LLB_NEAREST_PRICE,100,"XAUUSD",c,why),"U-BRK-02 close 106.3 <= P4+0.10ATR -> no breakout");
   //--- SELL breakout at P3
   BarsFlat(30);
   BarS(3,95.0,95.2,94.2,94.5);
   BarS(2,94.5,94.6,92.7,93.0);
   BarS(1,93.5,93.8,92.6,92.8);
   n=Series(r);
   T(LLB_DetectBreakout(r,n,1,lvAt,atrAt,0.01,2,LLB_SWINGREF_SETUP_EXTREME,LLB_NEAREST_PRICE,100,"XAUUSD",c,why)
     && c.direction==LLB_DIR_SELL && c.level==LLB_LVL_P3 && Eq(c.entry,92.59) && Eq(c.refSwingPrice,93.8),"F-005 SELL breakout P3 + retest + bearish confirm");
  }

void TestStops(void)
  {
   double sl,tp,rr,buf;
   string why;
   T(LLB_ComputeStops(LLB_DIR_BUY,97.11,95.2,4.0,0.01,2,sl,tp,rr,buf,why) && Eq(buf,0.2) && Eq(sl,95.00) && Eq(tp,101.33) && Eq(rr,2.0,1e-6),
     "SL-001 BUY: SL = swing low - buffer, TP = 2R");
   T(LLB_ComputeStops(LLB_DIR_SELL,102.89,104.8,4.0,0.01,2,sl,tp,rr,buf,why) && Eq(sl,105.00) && Eq(tp,98.67) && Eq(rr,2.0,1e-6),
     "SL-002 SELL: SL = swing high + buffer, TP = 2R");
   T(LLB_ComputeStops(LLB_DIR_BUY,97.11,95.2,0.2,0.01,2,sl,tp,rr,buf,why) && Eq(buf,0.02) && Eq(sl,95.18),"SL-003 buffer = max(2 ticks, 0.05 ATR) (tick part)");
   T(LLB_ComputeStops(LLB_DIR_BUY,97.11,95.2,0.5,0.01,2,sl,tp,rr,buf,why) && Eq(sl,95.17),"SL-004a BUY SL rounded DOWN to tick (95.175 -> 95.17)");
   T(LLB_ComputeStops(LLB_DIR_SELL,102.89,104.8,0.5,0.01,2,sl,tp,rr,buf,why) && Eq(sl,104.83),"SL-004b SELL SL rounded UP to tick (104.825 -> 104.83)");
   T(!LLB_ComputeStops(LLB_DIR_BUY,97.11,97.2,4.0,0.01,2,sl,tp,rr,buf,why) && StringFind(why,"GEOMETRY_INVALID")>=0,"U-SL-05 invalid geometry rejected, not fixed");
   T(!LLB_ComputeStops(LLB_DIR_BUY,97.11,95.2,0.0,0.01,2,sl,tp,rr,buf,why),"U-SL-06 ATR 0 rejected");
   T(LLB_SlWithinApproved(LLB_DIR_BUY,95.00,95.00,0.01) && LLB_SlWithinApproved(LLB_DIR_BUY,95.50,95.00,0.01),"POS-002a BUY SL attached (equal or tighter) is accepted");
   T(!LLB_SlWithinApproved(LLB_DIR_BUY,94.50,95.00,0.01) && !LLB_SlWithinApproved(LLB_DIR_BUY,0.0,95.00,0.01),"POS-002b BUY SL wider or missing is not accepted");
   T(LLB_SlWithinApproved(LLB_DIR_SELL,104.50,105.00,0.01) && !LLB_SlWithinApproved(LLB_DIR_SELL,105.50,105.00,0.01),"POS-004 SELL SL never accepted wider (no widening)");
   T(LLB_ComputeStops(LLB_DIR_BUY,4000.501,3998.2,5.0,0.001,3,sl,tp,rr,buf,why) && Eq(sl,3997.950,1e-9) && Eq(tp,4005.603,1e-9),"U-SL-07 XAUUSDc tick 0.001");
  }

void TestIds(void)
  {
   string id=LLB_MakeSignalId("XAUUSD",LLB_STRAT_SWEEP,LLB_DIR_BUY,20261117,1);
   T(id=="4LLB-XAUUSD-SWEEP-BUY-20261117-0001","U-ID-01 Signal ID format (SRS example)");
   string sym;
   int st,dir,d8,seq;
   T(LLB_ParseSignalId(id,sym,st,dir,d8,seq) && sym=="XAUUSD" && st==LLB_STRAT_SWEEP && dir==LLB_DIR_BUY && d8==20261117 && seq==1,"U-ID-02 Signal ID parse");
   string id2=LLB_MakeSignalId("XAU-USD.c",LLB_STRAT_BREAKOUT,LLB_DIR_SELL,20261117,12);
   T(LLB_ParseSignalId(id2,sym,st,dir,d8,seq) && sym=="XAU-USD.c" && seq==12,"U-ID-02b symbol containing '-'");
   string ex=LLB_ExecIdFromSignalId(id);
   T(ex=="E2611170001","U-ID-04 Execution ID derived 1-1 from Signal ID");
   string c=LLB_EntryComment(ex);
   T(StringLen(c)<=31,"U-ID-05 order comment fits 31 chars");
   string got;
   T(LLB_ExecIdFromComment(c,got) && got==ex,"U-ID-06 exec id from entry comment");
   T(LLB_ExecIdFromComment(c+" [sl 2650.00]",got) && got==ex,"U-ID-06b broker suffix tolerated");
   T(!LLB_ExecIdFromComment(LLB_CloseComment(ex),got),"U-ID-07 close comment is not an entry");
   T(!LLB_ExecIdFromComment("manual trade",got),"U-ID-07b foreign comment ignored");
   int dec;
   string sid;
   string longest="4LLB-XAUUSDc-BREAKOUT-SELL-20261117-0001";
   T(LLB_ParseCallbackData("ACCEPT|"+longest,dec,sid) && dec==LLB_DEC_ACCEPT && sid==longest,"U-ID-03 ACCEPT callback parsed");
   T(StringLen("ACCEPT|"+longest)<=64,"U-ID-03b callback data <= 64 bytes");
   T(LLB_ParseCallbackData("REJECT|"+id,dec,sid) && dec==LLB_DEC_REJECT,"U-ID-03c REJECT callback parsed");
   T(!LLB_ParseCallbackData("DELETE|"+id,dec,sid),"U-ID-03d unknown action refused");
   T(!LLB_ParseCallbackData("ACCEPT|garbage-id",dec,sid),"U-ID-03e malformed signal id refused");
   T(!LLB_ParseCallbackData("ACCEPT|"+id+"|x",dec,sid),"U-ID-03f extra field refused");
  }

void TestJson(void)
  {
   string js="{\"ok\":true,\"result\":[{\"update_id\":987654321,\"callback_query\":{\"id\":\"4382bfdwdsb323b2d9\",";
   js+="\"from\":{\"id\":7123456789,\"is_bot\":false,\"first_name\":\"Ng\\u01b0\\u1eddi d\\u00f9ng\",\"username\":\"trader\"},";
   js+="\"message\":{\"message_id\":512,\"from\":{\"id\":8000000001,\"is_bot\":true},\"chat\":{\"id\":7123456789,\"type\":\"private\"},";
   js+="\"date\":1763366400,\"text\":\"4LLB PROPOSAL\"},\"chat_instance\":\"-1234\",\"data\":\"ACCEPT|4LLB-XAUUSD-SWEEP-BUY-20261117-0001\"}},";
   js+="{\"update_id\":987654322,\"message\":{\"message_id\":513,\"chat\":{\"id\":-1001234567890,\"type\":\"supergroup\"},";
   js+="\"text\":\"hi \\\"quoted\\\" \\\\ back\",\"entities\":null}}]}";
   long maxId=0;
   LLBTelegramCallback cbs[];
   string err;
   int n=LLB_ParseUpdates(js,maxId,cbs,err);
   T(n==1,"TG-JSON-01 one callback extracted ("+err+")");
   T(maxId==987654322,"TG-JSON-02 max update_id (offset source)");
   if(n==1)
     {
      T(cbs[0].queryId=="4382bfdwdsb323b2d9" && cbs[0].fromId==7123456789 && cbs[0].chatId==7123456789 && cbs[0].messageId==512,"TG-JSON-03 callback ids (64-bit safe)");
      T(cbs[0].data=="ACCEPT|4LLB-XAUUSD-SWEEP-BUY-20261117-0001","TG-JSON-04 callback data");
     }
   CLLBJson root;
   T(root.Parse(js,err),"TG-JSON-05 full parse");
   CLLBJson *res=root.Get("result");
   CLLBJson *u1=NULL;
   CLLBJson *msg=NULL;
   CLLBJson *chat=NULL;
   if(res!=NULL)
      u1=res.At(1);
   if(u1!=NULL)
      msg=u1.Get("message");
   if(msg!=NULL)
      chat=msg.Get("chat");
   T(chat!=NULL && chat.GetLong("id")==-1001234567890,"TG-JSON-06 negative 64-bit chat id");
   T(msg!=NULL && msg.GetStr("text")=="hi \"quoted\" \\ back","TG-JSON-07 string escapes decoded");
   CLLBJson *u0=NULL;
   CLLBJson *cq=NULL;
   CLLBJson *from=NULL;
   if(res!=NULL)
      u0=res.At(0);
   if(u0!=NULL)
      cq=u0.Get("callback_query");
   if(cq!=NULL)
      from=cq.Get("from");
   string expect="Ng"+ShortToString(0x01B0)+ShortToString(0x1EDD)+"i d"+ShortToString(0x00F9)+"ng";
   T(from!=NULL && from.GetStr("first_name")==expect,"TG-JSON-08 unicode escapes decoded");
   T(LLB_ParseUpdates("{\"ok\":true,\"result\":[",maxId,cbs,err)<0,"TG-JSON-09 truncated response rejected");
   T(LLB_ParseUpdates("{\"ok\":false,\"error_code\":401,\"description\":\"Unauthorized\"}",maxId,cbs,err)<0 && StringFind(err,"Unauthorized")>=0,"TG-JSON-10 ok=false reported");
   T(LLB_JsonEscape("a\"b\\c\nd")=="a\\\"b\\\\c\\nd","TG-JSON-11 escaping for request bodies");
  }

void TestStateMachine(void)
  {
   T(LLB_CanTransition(LLB_PS_ACTIVE,LLB_PS_ACCEPTED),"U-SM-01 ACTIVE->ACCEPTED");
   T(LLB_CanTransition(LLB_PS_ACTIVE,LLB_PS_REJECTED),"U-SM-02 ACTIVE->REJECTED");
   T(LLB_CanTransition(LLB_PS_ACTIVE,LLB_PS_EXPIRED),"U-SM-03 ACTIVE->EXPIRED");
   T(LLB_CanTransition(LLB_PS_ACTIVE,LLB_PS_INVALIDATED),"U-SM-04 ACTIVE->INVALIDATED");
   T(LLB_CanTransition(LLB_PS_ACCEPTED,LLB_PS_EXECUTING),"U-SM-05 ACCEPTED->EXECUTING");
   T(LLB_CanTransition(LLB_PS_EXECUTING,LLB_PS_EXECUTED),"U-SM-06 EXECUTING->EXECUTED");
   T(LLB_CanTransition(LLB_PS_EXECUTING,LLB_PS_EXECUTION_FAILED),"U-SM-07 EXECUTING->EXECUTION_FAILED");
   T(!LLB_CanTransition(LLB_PS_ACTIVE,LLB_PS_EXECUTING),"U-SM-08 no execution without ACCEPTED");
   T(!LLB_CanTransition(LLB_PS_REJECTED,LLB_PS_ACCEPTED),"U-SM-09 REJECTED is terminal");
   T(!LLB_CanTransition(LLB_PS_EXPIRED,LLB_PS_ACCEPTED),"U-SM-10 EXPIRED cannot be revived by a late ACCEPT");
   T(!LLB_CanTransition(LLB_PS_INVALIDATED,LLB_PS_ACCEPTED),"U-SM-11 INVALIDATED cannot be revived");
   T(!LLB_CanTransition(LLB_PS_EXECUTED,LLB_PS_EXECUTING),"U-SM-12 EXECUTED never re-executes");
   T(!LLB_CanTransition(LLB_PS_ACCEPTED,LLB_PS_ACTIVE),"U-SM-13 no way back to ACTIVE");
   T(LLB_IsRetcodeAccepted(10009) && LLB_IsRetcodeAccepted(10008),"U-RC-01 DONE/PLACED accepted");
   T(!LLB_IsRetcodeClearReject(10012) && !LLB_IsRetcodeClearReject(10031) && !LLB_IsRetcodeClearReject(10011),"U-RC-02 TIMEOUT/CONNECTION/ERROR are UNKNOWN (never resent)");
   T(LLB_IsRetcodeClearReject(10016) && LLB_IsRetcodeClearReject(10046) && LLB_IsRetcodeClearReject(10018),"U-RC-03 clear broker rejects");
  }

void SampleProposal(LLBTradeProposal &p)
  {
   p.Reset();
   p.signalId="4LLB-XAUUSD-SWEEP-BUY-20261117-0001";
   p.symbol="XAUUSD";
   p.strategy=LLB_STRAT_SWEEP;
   p.direction=LLB_DIR_BUY;
   p.level=LLB_LVL_P2;
   p.levelPrice=96.0;
   p.entry=97.11;
   p.sl=95.0;
   p.tp=101.33;
   p.rr=2.0;
   p.atr=4.0;
   p.bid=96.9;
   p.ask=97.0;
   p.spreadPoints=10;
   p.digits=2;
   p.createdTime=D'2026.11.17 08:15:02';
   p.expiresTime=D'2026.11.17 08:30:02';
   p.signalBarTime=D'2026.11.17 08:00';
   p.refSwingPrice=95.2;
   p.refSwingTime=D'2026.11.17 08:00';
   p.monitorFromMsc=((long)D'2026.11.17 08:15')*1000;
   p.state=LLB_PS_ACTIVE;
   p.stateReason="CREATED; with semicolon";
   p.decision=LLB_DEC_NONE;
   p.tgMessageId=512;
   p.execId="E2611170001";
   p.reason="SWEEP BUY at P2";
  }

void TestCsv(void)
  {
   LLBTradeProposal p,q;
   SampleProposal(p);
   string line=LLB_SignalToCsv(p,D'2026.11.17 08:15:03');
   T(LLB_SignalFromCsv(line,q),"U-CSV-01 signal round trip parses");
   T(q.signalId==p.signalId && q.state==p.state && Eq(q.entry,p.entry) && Eq(q.sl,p.sl) && Eq(q.tp,p.tp) && q.expiresTime==p.expiresTime
     && q.monitorFromMsc==p.monitorFromMsc && q.tgMessageId==512 && q.execId==p.execId,"U-CSV-02 signal fields preserved");
   T(StringFind(q.stateReason,";")<0,"U-CSV-03 separator removed from text fields");
   string bad=line;
   StringReplace(bad,"97.110000","97.120000");
   T(!LLB_SignalFromCsv(bad,q),"U-CSV-04 corrupted line detected by CRC");
   T(!LLB_SignalFromCsv(StringSubstr(line,0,StringLen(line)-5),q),"U-CSV-05 partially written line rejected");
   LLBExecutionRecord e,f;
   e.Reset();
   e.execId="E2611170001";
   e.signalId=p.signalId;
   e.symbol="XAUUSD";
   e.direction=LLB_DIR_BUY;
   e.orderType=ORDER_TYPE_BUY_STOP;
   e.state=LLB_EX_SUBMITTING;
   e.orderState=LLB_OS_NONE;
   e.volume=0.01;
   e.entry=97.11;
   e.submitMsc=1763367302123;
   e.orderTicket=123456789;
   line=LLB_ExecToCsv(e,D'2026.11.17 08:15:03');
   T(LLB_ExecFromCsv(line,f) && f.state==LLB_EX_SUBMITTING && f.orderTicket==123456789 && f.submitMsc==1763367302123 && f.orderType==ORDER_TYPE_BUY_STOP,
     "U-CSV-06 execution round trip (SUBMITTING persisted)");
   LLBManagedPosition m,k;
   m.Reset();
   m.positionId=987654321;
   m.execId=e.execId;
   m.signalId=p.signalId;
   m.symbol="XAUUSD";
   m.direction=LLB_DIR_BUY;
   m.volume=0.01;
   m.state=LLB_POS_CLOSED;
   m.closeReason=LLB_CR_TP;
   m.profit=4.22;
   m.commission=-0.07;
   line=LLB_PosToCsv(m,D'2026.11.17 10:00');
   T(LLB_PosFromCsv(line,k) && k.positionId==987654321 && k.closeReason==LLB_CR_TP && Eq(k.profit,4.22,1e-6) && Eq(k.commission,-0.07,1e-6),
     "U-CSV-07 position round trip (close reason, commission)");
  }

void TestTouch(void)
  {
   MqlTick t[];
   ArrayResize(t,4);
   double bids[4]= {100.5,100.2,99.99,100.3};
   for(int i=0; i<4; i++)
     {
      t[i].time_msc=(long)(i+1)*1000;
      t[i].bid=bids[i];
      t[i].ask=bids[i]+0.2;
     }
   long ms;
   double px;
   T(LLB_FindTouch(t,4,LLB_DIR_BUY,100.0,0,0.01,ms,px) && ms==3000 && Eq(px,99.99),"SI-001 BUY invalidated when Bid <= swing low (touch)");
   T(!LLB_FindTouch(t,4,LLB_DIR_BUY,100.0,3500,0.01,ms,px),"SI-003 ticks before the monitoring start are ignored");
   T(LLB_FindTouch(t,4,LLB_DIR_BUY,100.2,0,0.01,ms,px) && ms==2000,"U-TCH-02 equality counts as touch");
   T(LLB_FindTouch(t,4,LLB_DIR_SELL,100.7,0,0.01,ms,px) && ms==1000 && Eq(px,100.7),"SI-002 SELL invalidated when Ask >= swing high");
   T(!LLB_FindTouch(t,4,LLB_DIR_SELL,100.71,0,0.01,ms,px),"U-TCH-03 no touch below the level");
   T(LLB_QuoteTouches(LLB_DIR_BUY,100.0,99.99,100.19,0.01) && !LLB_QuoteTouches(LLB_DIR_BUY,100.0,100.01,100.2,0.01),"U-TCH-04 single quote check");
  }

void TestAuth(void)
  {
   long allowed[];
   T(LLB_ParseIdList("111, -1001234567890",allowed)==2 && allowed[1]==-1001234567890,"U-AUTH-01 allow-list parse");
   T(LLB_ParseIdList("abc",allowed)<0,"U-AUTH-02 invalid allow-list rejected");
   T(LLB_ParseIdList("",allowed)==0,"U-AUTH-03 empty allow-list");
   long one[];
   ArrayResize(one,1);
   one[0]=111;
   T(LLB_TgAuthorized(111,111,111,one),"TG-002a private chat owner authorised");
   T(!LLB_TgAuthorized(222,222,111,one),"TG-004a other chat refused");
   T(!LLB_TgAuthorized(111,333,111,one),"TG-004b other user in the chat refused");
   T(LLB_TgAuthorized(-100,111,-100,one) && !LLB_TgAuthorized(-100,222,-100,one),"TG-004c group: only allow-listed users");
   string tok=IntegerToString(123456789)+":"+"FAKE"+"bcdefghijklmnopqrstuvwxyz01234";   // fake token built at runtime
   T(LLB_IsTokenFormat(tok),"U-SEC-01 token format accepted");
   T(!LLB_IsTokenFormat("12345:short"),"U-SEC-02 bad token refused");
   string bom=ShortToString(0x00EF)+ShortToString(0x00BB)+ShortToString(0x00BF)+tok+" \r";
   T(LLB_SanitizeToken(bom)==tok,"U-SEC-03 BOM/whitespace stripped from token file");
  }

void TestProposalManager(void)
  {
   CLLBProposalManager pm;
   pm.Init(NULL);                                    // no files: pure in-memory behaviour
   LLBSignalCandidate c;
   c.Reset();
   c.symbol="XAUUSD";
   c.strategy=LLB_STRAT_SWEEP;
   c.direction=LLB_DIR_BUY;
   c.level=LLB_LVL_P2;
   c.levelPrice=96.0;
   c.signalBarTime=D'2026.11.17 08:00';
   c.atr=4.0;
   c.entry=97.11;
   c.refSwingPrice=95.2;
   c.refSwingTime=D'2026.11.17 08:00';
   c.reason="test";
   c.valid=true;
   MqlTick tk;
   ZeroMemory(tk);
   tk.bid=96.9;
   tk.ask=97.0;
   string why;
   datetime now=D'2026.11.17 08:15:02';
   int i0=pm.Create(c,95.0,101.33,2.0,tk,0.01,2,now,why);
   T(i0==0 && pm.items[0].signalId=="4LLB-XAUUSD-SWEEP-BUY-20261117-0001","PRP-01 first proposal id #0001");
   T(pm.items[0].expiresTime==now+900,"SI-004a sweep expires 15 minutes after creation");
   T(pm.items[0].execId=="E2611170001" && pm.items[0].monitorFromMsc==((long)D'2026.11.17 08:15')*1000,"PRP-02 exec id + monitoring from signal candle close");
   T(pm.Create(c,95.0,101.33,2.0,tk,0.01,2,now,why)<0 && StringFind(why,"DUPLICATE")>=0,"XT-DUP-01 same opportunity never duplicated");
   LLBSignalCandidate c2=c;
   c2.signalBarTime=D'2026.11.17 08:15';
   T(pm.Create(c2,95.0,101.33,2.0,tk,0.01,2,now+900,why)<0 && StringFind(why,"STILL_VALID")>=0,"XT-DUP-02 no new proposal while the previous one is ACTIVE");
   T(pm.ProcessExpiry(now+899)==0 && pm.items[0].state==LLB_PS_ACTIVE,"SI-004b not expired 1 s before");
   T(pm.ProcessExpiry(now+900)==1 && pm.items[0].state==LLB_PS_EXPIRED,"SI-004c EXPIRED at expiration time");
   T(!pm.Transition(0,LLB_PS_ACCEPTED,"late accept") && pm.items[0].state==LLB_PS_EXPIRED,"TG-005 late ACCEPT cannot revive EXPIRED");
   int i1=pm.Create(c2,95.0,101.33,2.0,tk,0.01,2,now+900,why);
   T(i1==1 && StringFind(pm.items[1].signalId,"-0002")>0,"PRP-03 sequence increments");
   LLBSignalCandidate c3=c;
   c3.strategy=LLB_STRAT_BREAKOUT;
   c3.signalBarTime=D'2026.11.18 00:15';
   int i2=pm.Create(c3,95.0,101.33,2.0,tk,0.01,2,D'2026.11.18 00:30:01',why);
   T(i2==2 && pm.items[2].signalId=="4LLB-XAUUSD-BREAKOUT-BUY-20261118-0001","PRP-04 sequence restarts on a new server day");
   T(pm.items[2].expiresTime==D'2026.11.18 00:30:01'+1800,"SI-004d breakout expires 30 minutes after creation");
   string changed[];
   T(pm.TakeChanged(changed)>=1,"PRP-05 state changes are queued for Telegram edits");
  }

void TestMessages(void)
  {
   LLBTradeProposal p;
   SampleProposal(p);
   string m=LLB_FormatProposal(p,PERIOD_M15);
   string req[]= {"Signal ID: ","Symbol: ","Strategy: ","Direction: ","Level: ","Entry: ","SL: ","TP: ","RR: 1:","Expiration: ","Reason: ","ATR(14,M15)","Bid/Ask: ","Spread: ","Created: ","Reference swing: "};
   bool all=true;
   for(int i=0; i<ArraySize(req); i++)
      if(StringFind(m,req[i])<0)
        {
         all=false;
         Print("missing field in proposal message: ",req[i]);
        }
   T(all,"TG-001 proposal message contains every SRS field");
  }

//+------------------------------------------------------------------+
void OnStart(void)
  {
   g_pass=0;
   g_fail=0;
   TestNormalisation();
   TestVolume();
   TestPivots();
   TestLevels();
   TestSweep();
   TestBreakout();
   TestStops();
   TestIds();
   TestJson();
   TestStateMachine();
   TestCsv();
   TestTouch();
   TestAuth();
   TestProposalManager();
   TestMessages();
   PrintFormat("4LLB UNIT TESTS: %d passed, %d failed",g_pass,g_fail);
   if(g_fail==0)
      Print("4LLB UNIT TESTS: ALL PASSED");
  }
//+------------------------------------------------------------------+
