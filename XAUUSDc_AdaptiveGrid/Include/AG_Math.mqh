//+------------------------------------------------------------------+
//| AG_Math.mqh                                                      |
//| Pure functions (no globals, no terminal calls) - unit testable.  |
//| Formulas: Documentation/Phase3_Quantitative_Formulas.md          |
//+------------------------------------------------------------------+
#ifndef AG_MATH_MQH
#define AG_MATH_MQH

//--- §1.1 volume as integer number of steps (avoids float drift)
long AG_VolumeToSteps(const double volume,const double step)
  {
   if(step<=0.0 || !MathIsValidNumber(volume))
      return -1;
   return (long)MathRound(volume/step);
  }

bool AG_IsValidVolume(const double volume,const double vmin,const double vmax,const double step)
  {
   if(step<=0.0 || vmin<=0.0 || vmax<vmin)
      return false;
   if(!MathIsValidNumber(volume) || volume<=0.0)
      return false;
   long steps=AG_VolumeToSteps(volume,step);
   double norm=steps*step;
   if(MathAbs(norm-volume)>step*1e-6)
      return false;                       // not a multiple of step: refuse, never round
   if(volume<vmin-step*1e-6)
      return false;
   if(volume>vmax+step*1e-6)
      return false;
   return true;
  }

//--- §1.2 prices
double AG_NormalizeToTick(const double price,const double tick)
  {
   if(tick<=0.0)
      return price;
   return MathRound(price/tick)*tick;
  }

double AG_CeilToTick(const double x,const double tick)
  {
   if(tick<=0.0)
      return x;
   return MathCeil(x/tick-1e-7)*tick;
  }

double AG_Clamp(const double v,const double lo,const double hi)
  {
   return MathMax(lo,MathMin(hi,v));
  }

//--- §2 grid distance; returns -1 when inputs are invalid
double AG_CalcGridDistance(const double atr,const double mult,const double minG,const double maxG,const double tick)
  {
   if(!MathIsValidNumber(atr) || atr<=0.0 || mult<=0.0 || minG<=0.0 || maxG<minG)
      return -1.0;
   return AG_CeilToTick(AG_Clamp(atr*mult,minG,maxG),tick);
  }

bool AG_BuyGridTrigger(const double bid,const double lastFill,const double gd)
  {
   if(gd<=0.0 || lastFill<=0.0 || bid<=0.0)
      return false;
   return (bid<=lastFill-gd+1e-9);
  }

bool AG_SellGridTrigger(const double ask,const double lastFill,const double gd)
  {
   if(gd<=0.0 || lastFill<=0.0 || ask<=0.0)
      return false;
   return (ask>=lastFill+gd-1e-9);
  }

//--- §3 signals
bool AG_SignalBuyTwoCandle(const double c2,const double lo2,const double rsi2,
                           const double c1,const double lo1,const double up1,const double adx1,
                           const double rsiBuy,const double maxAdx)
  {
   return (c2<lo2 && rsi2<=rsiBuy && c1>lo1 && c1<up1 && adx1<maxAdx);
  }

bool AG_SignalSellTwoCandle(const double c2,const double up2,const double rsi2,
                            const double c1,const double lo1,const double up1,const double adx1,
                            const double rsiSell,const double maxAdx)
  {
   return (c2>up2 && rsi2>=rsiSell && c1<up1 && c1>lo1 && adx1<maxAdx);
  }

bool AG_SignalBuyOneCandle(const double low1,const double c1,const double lo1,const double up1,
                           const double rsi1,const double adx1,const double rsiBuy,const double maxAdx)
  {
   return (low1<lo1 && c1>lo1 && c1<up1 && rsi1<=rsiBuy && adx1<maxAdx);
  }

bool AG_SignalSellOneCandle(const double high1,const double c1,const double lo1,const double up1,
                            const double rsi1,const double adx1,const double rsiSell,const double maxAdx)
  {
   return (high1>up1 && c1<up1 && c1>lo1 && rsi1>=rsiSell && adx1<maxAdx);
  }

//--- §5.1 budget and effective SL (return -1 when invalid)
double AG_CalcBudget(const double base,const double pct)
  {
   if(!MathIsValidNumber(base) || base<=0.0 || pct<=0.0)
      return -1.0;
   return base*pct/100.0;
  }

double AG_CalcEffectiveSL(const bool useBudget,const double slInput,const double budget)
  {
   if(budget<=0.0)
      return -1.0;
   if(useBudget)
      return budget;
   if(slInput<=0.0)
      return -1.0;
   return MathMin(slInput,budget);
  }

//--- §6 additional loss over the current loss of the same side
double AG_CalcAddLoss(const double projLoss,const double netBasket)
  {
   double cur=MathMax(0.0,-netBasket);
   return MathMax(0.0,projLoss-cur);
  }

//--- §8 EA daily P/L
double AG_CalcDailyPL(const double realizedOut,const double closedFeeIn,const double openNow,const double snap)
  {
   return realizedOut+closedFeeIn+openNow-snap;
  }

//--- §9/§10 drawdown vs a base (HWM or day-start base). Fail-closed when limit <= 0.
bool AG_DrawdownBreached(const double base,const double equity,const double pct,double &loss,double &limit)
  {
   loss=MathMax(0.0,base-equity);
   limit=base*pct/100.0;
   if(limit<=0.0)
      return true;
   return (loss>=limit-AG_EPS_MONEY);
  }

//--- §12 order rate
bool AG_CooldownOK(const long nowMsc,const long lastFillMsc,const int cooldownSec)
  {
   if(lastFillMsc<=0)
      return true;
   return ((nowMsc-lastFillMsc)>=(long)cooldownSec*1000);
  }

bool AG_OnePerBarOK(const datetime currentBar,const datetime lastOrderBar)
  {
   return (currentBar>lastOrderBar);
  }

datetime AG_DayStart(const datetime t)
  {
   return (datetime)(((long)t/86400)*86400);
  }

datetime AG_MinuteStart(const long timeMsc)
  {
   return (datetime)(((timeMsc/1000)/60)*60);
  }

//--- CRC32 for the state file
uint g_agCrcTable[256];
bool g_agCrcReady=false;

void AG_CrcInit()
  {
   for(uint i=0; i<256; i++)
     {
      uint c=i;
      for(int k=0; k<8; k++)
         c=((c&1)!=0) ? (0xEDB88320^(c>>1)) : (c>>1);
      g_agCrcTable[i]=c;
     }
   g_agCrcReady=true;
  }

uint AG_Crc32(const string s)
  {
   if(!g_agCrcReady)
      AG_CrcInit();
   uint crc=0xFFFFFFFF;
   int n=StringLen(s);
   for(int i=0; i<n; i++)
     {
      ushort ch=StringGetCharacter(s,i);
      crc=g_agCrcTable[(crc^(uint)(ch&0xFF))&0xFF]^(crc>>8);
      crc=g_agCrcTable[(crc^(uint)(ch>>8))&0xFF]^(crc>>8);
     }
   return crc^0xFFFFFFFF;
  }

#endif
//+------------------------------------------------------------------+
