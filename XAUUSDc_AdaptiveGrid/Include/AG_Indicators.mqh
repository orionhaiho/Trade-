//+------------------------------------------------------------------+
//| AG_Indicators.mqh                                                |
//| Indicator handles on M1 and snapshot of CLOSED bars (shift 1,2). |
//+------------------------------------------------------------------+
#ifndef AG_INDICATORS_MQH
#define AG_INDICATORS_MQH

#include "AG_Types.mqh"
#include "AG_Environment.mqh"

int           g_hBB  = INVALID_HANDLE;
int           g_hRSI = INVALID_HANDLE;
int           g_hADX = INVALID_HANDLE;
int           g_hATR = INVALID_HANDLE;
AGIndSnapshot g_snap;

//+------------------------------------------------------------------+
bool InitIndicators(string &err)
  {
   string s=g_cfg.symbol;
   g_hBB =iBands(s,PERIOD_M1,g_cfg.bbPeriod,0,g_cfg.bbDev,PRICE_CLOSE);
   g_hRSI=iRSI(s,PERIOD_M1,g_cfg.rsiPeriod,PRICE_CLOSE);
   g_hADX=iADX(s,PERIOD_M1,g_cfg.adxPeriod);
   g_hATR=iATR(s,PERIOD_M1,g_cfg.atrPeriod);
   if(g_hBB==INVALID_HANDLE || g_hRSI==INVALID_HANDLE || g_hADX==INVALID_HANDLE || g_hATR==INVALID_HANDLE)
     {
      err="Indicator handle creation failed err="+(string)GetLastError();
      return false;
     }
   g_snap.valid=false;
   g_snap.bar1Time=0;
   return true;
  }

void ReleaseIndicators()
  {
   if(g_hBB!=INVALID_HANDLE)  { IndicatorRelease(g_hBB);  g_hBB=INVALID_HANDLE; }
   if(g_hRSI!=INVALID_HANDLE) { IndicatorRelease(g_hRSI); g_hRSI=INVALID_HANDLE; }
   if(g_hADX!=INVALID_HANDLE) { IndicatorRelease(g_hADX); g_hADX=INVALID_HANDLE; }
   if(g_hATR!=INVALID_HANDLE) { IndicatorRelease(g_hATR); g_hATR=INVALID_HANDLE; }
  }

bool AG_ValueOk(const double v)
  {
   return (MathIsValidNumber(v) && v!=EMPTY_VALUE);
  }

bool AG_Copy2(const int handle,const int buffer,double &out[])
  {
   ArraySetAsSeries(out,true);
   return (CopyBuffer(handle,buffer,1,2,out)==2);   // out[0]=shift1, out[1]=shift2
  }

//+------------------------------------------------------------------+
//| Reads shift 1 and shift 2 (closed bars only). Never shift 0.     |
//+------------------------------------------------------------------+
bool ReadSnapshot(AGIndSnapshot &s)
  {
   s.valid=false;
   s.err="";
   string sym=g_cfg.symbol;
   int bars=Bars(sym,PERIOD_M1);
   int need=MathMax(MathMax(g_cfg.bbPeriod,g_cfg.rsiPeriod),MathMax(g_cfg.adxPeriod*2,g_cfg.atrPeriod))+5;
   if(bars<need)
     { s.err="NOT_ENOUGH_BARS"; return false; }
   //--- CopyBuffer first: in the non-visual tester indicators are calculated lazily on request,
   //--- so BarsCalculated() can lag Bars() until data is requested. Comparing it to Bars()
   //--- before copying rejected every first tick of a bar (0 trades in non-visual runs).
   double up[],lo[],rsi[],adx[],atr[];
   if(!AG_Copy2(g_hBB,1,up) || !AG_Copy2(g_hBB,2,lo) || !AG_Copy2(g_hRSI,0,rsi)
      || !AG_Copy2(g_hADX,0,adx) || !AG_Copy2(g_hATR,0,atr))
     { s.err="COPYBUFFER_FAILED"; return false; }
   if(BarsCalculated(g_hBB)<need || BarsCalculated(g_hRSI)<need || BarsCalculated(g_hADX)<need || BarsCalculated(g_hATR)<need)
     { s.err="INDICATOR_NOT_CALCULATED"; return false; }

   MqlRates r[];
   ArraySetAsSeries(r,true);
   if(CopyRates(sym,PERIOD_M1,1,2,r)!=2)
     { s.err="COPYRATES_FAILED"; return false; }
   datetime t1=iTime(sym,PERIOD_M1,1);
   if(t1==0 || r[0].time!=t1)
     { s.err="BAR_TIME_MISMATCH"; return false; }

   s.bar1Time=r[0].time;
   s.close1=r[0].close;
   s.close2=r[1].close;
   s.low1  =r[0].low;
   s.high1 =r[0].high;
   s.bbUp1=up[0];  s.bbUp2=up[1];
   s.bbLo1=lo[0];  s.bbLo2=lo[1];
   s.rsi1 =rsi[0]; s.rsi2 =rsi[1];
   s.adx1 =adx[0];
   s.atr1 =atr[0];

   if(!AG_ValueOk(s.bbUp1) || !AG_ValueOk(s.bbUp2) || !AG_ValueOk(s.bbLo1) || !AG_ValueOk(s.bbLo2)
      || !AG_ValueOk(s.rsi1) || !AG_ValueOk(s.rsi2) || !AG_ValueOk(s.adx1) || !AG_ValueOk(s.atr1)
      || s.close1<=0.0 || s.close2<=0.0)
     { s.err="INVALID_INDICATOR_VALUE"; return false; }

   s.valid=true;
   return true;
  }

#endif
//+------------------------------------------------------------------+
