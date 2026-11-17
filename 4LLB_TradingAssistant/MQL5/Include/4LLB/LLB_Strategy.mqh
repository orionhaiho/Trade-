//+------------------------------------------------------------------+
//| LLB_Strategy.mqh                                                 |
//| StrategyEngine - pure detection on CLOSED M15 bars (series).     |
//| Sweep and Breakout are independent; neither sends any order.     |
//|                                                                  |
//| Interpretations (Phase 0): A-01 depth = wick extreme to level,   |
//| A-02 single-candle sweep, A-03 breakout/retest, A-20 outer level |
//| first, D-01 reference swing (setup extreme or confirmed pivot).  |
//+------------------------------------------------------------------+
#ifndef LLB_STRATEGY_MQH
#define LLB_STRATEGY_MQH

#include "LLB_Defines.mqh"
#include "LLB_Utils.mqh"
#include "LLB_Levels.mqh"

//--- single-candle sweep of one level (SRS 4.3 steps 1-4)
bool LLB_SweepAtLevel(const MqlRates &bar,const int dir,const double level,const double atr,const double tick,double &depth)
  {
   depth=0.0;
   if(level<=0.0 || atr<=0.0)
      return false;
   if(dir==LLB_DIR_SELL)
     {
      if(!LLB_PriceAbove(bar.high,level,tick))      // 1. pierced above the level
         return false;
      if(!LLB_PriceBelow(bar.close,level,tick))     // 3. closed back below the level
         return false;
      if(!(bar.close<bar.open))                     // 4. bearish candle
         return false;
      depth=bar.high-level;
     }
   else
     {
      if(!LLB_PriceBelow(bar.low,level,tick))
         return false;
      if(!LLB_PriceAbove(bar.close,level,tick))
         return false;
      if(!(bar.close>bar.open))
         return false;
      depth=level-bar.low;
     }
//--- 2. depth inside [0.05, 0.50] ATR (inclusive)
   return (depth>=LLB_SWEEP_MIN_ATR*atr-1e-10 && depth<=LLB_SWEEP_MAX_ATR*atr+1e-10);
  }

//--- reference swing for SL / invalidation
bool LLB_ReferenceSwing(const MqlRates &r[],const int n,const int t,const int dir,const double setupExtreme,const datetime extremeTime,
                        const int swingRefMode,const int nearestMode,const int lookback,double &refPrice,datetime &refTime,string &why)
  {
   refPrice=0.0;
   refTime=0;
   if(swingRefMode==LLB_SWINGREF_SETUP_EXTREME)
     {
      refPrice=setupExtreme;
      refTime=extremeTime;
      return (refPrice>0.0);
     }
//--- confirmed Pivot 3-3 (as of t) at or beyond the setup extreme
   LLBSwingPoint sp;
   bool high=(dir==LLB_DIR_SELL);
   if(!LLB_FindSwingBeyond(r,n,t,high,setupExtreme,true,lookback,nearestMode,sp))
     {
      why="NO_CONFIRMED_PIVOT_BEYOND_SETUP_EXTREME";
      return false;
     }
   refPrice=sp.price;
   refTime=sp.time;
   return true;
  }

//+------------------------------------------------------------------+
//| Liquidity Sweep on closed bar t (normally t = 1)                 |
//+------------------------------------------------------------------+
bool LLB_DetectSweep(const MqlRates &r[],const int n,const int t,const LLBLevels &lv,const double atr,const double tick,const int digits,
                     const int swingRefMode,const int nearestMode,const int lookback,const string sym,LLBSignalCandidate &c,string &why)
  {
   c.Reset();
   why="";
   if(!lv.valid || t<1 || t>=n || atr<=0.0 || tick<=0.0)
     {
      why="SWEEP_INPUT_INVALID";
      return false;
     }
   double dep4=0.0,dep1=0.0,dep3=0.0,dep2=0.0;
   bool s4=LLB_SweepAtLevel(r[t],LLB_DIR_SELL,lv.p4,atr,tick,dep4);
   bool s1=LLB_SweepAtLevel(r[t],LLB_DIR_SELL,lv.pdh,atr,tick,dep1);
   bool b3=LLB_SweepAtLevel(r[t],LLB_DIR_BUY,lv.p3,atr,tick,dep3);
   bool b2=LLB_SweepAtLevel(r[t],LLB_DIR_BUY,lv.pdl,atr,tick,dep2);
   int dir=-1;
   int level=LLB_LVL_NONE;
   double lvlPrice=0.0,depth=0.0;
   string also="";
   if(s4 || s1)
     {
      dir=LLB_DIR_SELL;
      if(s4)
        {
         level=LLB_LVL_P4;
         lvlPrice=lv.p4;
         depth=dep4;
         if(s1)
            also=StringFormat("; also swept P1(PDH) depth=%.2fATR",dep1/atr);
        }
      else
        {
         level=LLB_LVL_P1;
         lvlPrice=lv.pdh;
         depth=dep1;
        }
     }
   else
      if(b3 || b2)
        {
         dir=LLB_DIR_BUY;
         if(b3)
           {
            level=LLB_LVL_P3;
            lvlPrice=lv.p3;
            depth=dep3;
            if(b2)
               also=StringFormat("; also swept P2(PDL) depth=%.2fATR",dep2/atr);
           }
         else
           {
            level=LLB_LVL_P2;
            lvlPrice=lv.pdl;
            depth=dep2;
           }
        }
   if(dir<0)
      return false;
//--- 5. entry 1 tick beyond the signal candle
   double entry=(dir==LLB_DIR_BUY) ? LLB_NormPrice(r[t].high+tick,tick,digits,0) : LLB_NormPrice(r[t].low-tick,tick,digits,0);
//--- 6. reference swing (D-01)
   double extreme=(dir==LLB_DIR_BUY) ? r[t].low : r[t].high;
   double ref=0.0;
   datetime refT=0;
   if(!LLB_ReferenceSwing(r,n,t,dir,extreme,r[t].time,swingRefMode,nearestMode,lookback,ref,refT,why))
      return false;
   c.symbol=sym;
   c.strategy=LLB_STRAT_SWEEP;
   c.direction=dir;
   c.level=level;
   c.levelPrice=lvlPrice;
   c.signalBarTime=r[t].time;
   c.atr=atr;
   c.entry=entry;
   c.refSwingPrice=ref;
   c.refSwingTime=refT;
   c.reason=StringFormat("SWEEP %s at %s=%s depth=%.2fATR; candle O=%s H=%s L=%s C=%s closed back %s level, %s%s",
                         LLB_DirName(dir),LLB_LevelName(level),DoubleToString(lvlPrice,digits),depth/atr,
                         DoubleToString(r[t].open,digits),DoubleToString(r[t].high,digits),DoubleToString(r[t].low,digits),
                         DoubleToString(r[t].close,digits),(dir==LLB_DIR_SELL) ? "below" : "above",
                         (dir==LLB_DIR_SELL) ? "bearish" : "bullish",also);
   c.valid=true;
   return true;
  }

//--- breakout close beyond level +/- 0.10 ATR
bool LLB_BreakoutClose(const MqlRates &bar,const int dir,const double level,const double atr)
  {
   if(level<=0.0 || atr<=0.0)
      return false;
   if(dir==LLB_DIR_BUY)
      return (bar.close>level+LLB_BREAKOUT_ATR*atr);
   return (bar.close<level-LLB_BREAKOUT_ATR*atr);
  }

//--- retest within 0.15 ATR of the level + confirmation colour (A-03 b,c)
bool LLB_RetestConfirm(const MqlRates &bar,const int dir,const double level,const double atr)
  {
   if(level<=0.0 || atr<=0.0)
      return false;
   if(dir==LLB_DIR_BUY)
      return (MathAbs(bar.low-level)<=LLB_RETEST_ATR*atr+1e-10 && bar.close>bar.open);
   return (MathAbs(bar.high-level)<=LLB_RETEST_ATR*atr+1e-10 && bar.close<bar.open);
  }

//+------------------------------------------------------------------+
//| Breakout + retest for one direction, confirmation candle t.      |
//| lvAt[i]  : levels as of bar i (needed for i in t+1..t+4)         |
//| atrAt[i] : ATR as of bar i   (needed for i in t..t+5)            |
//+------------------------------------------------------------------+
bool LLB_DetectBreakoutDir(const MqlRates &r[],const int n,const int t,const LLBLevels &lvAt[],const double &atrAt[],const double tick,
                           const int digits,const int dir,const int swingRefMode,const int nearestMode,const int lookback,
                           const string sym,LLBSignalCandidate &c,string &why)
  {
   c.Reset();
   if(t<1 || t>=n || ArraySize(atrAt)<=t || atrAt[t]<=0.0)
      return false;
   for(int b=t+1; b<=t+LLB_RETEST_MAX_BARS; b++)          // most recent breakout candle first
     {
      if(b+1>=n || b>=ArraySize(lvAt) || b+1>=ArraySize(atrAt))
         break;
      if(!lvAt[b].valid || atrAt[b]<=0.0 || atrAt[b+1]<=0.0)
         continue;
      double level=(dir==LLB_DIR_BUY) ? lvAt[b].p4 : lvAt[b].p3;     // level snapshot at the breakout candle (A-28)
      if(!LLB_BreakoutClose(r[b],dir,level,atrAt[b]))
         continue;
      if(LLB_BreakoutClose(r[b+1],dir,level,atrAt[b+1]))
         continue;                                        // not the first close beyond the threshold (A-03a)
      bool consumed=false;
      for(int j=b-1; j>t; j--)
         if(atrAt[j]>0.0 && LLB_RetestConfirm(r[j],dir,level,atrAt[j]))
           {
            consumed=true;                                // an earlier candle already confirmed this setup (A-03d)
            break;
           }
      if(consumed)
         continue;
      if(!LLB_RetestConfirm(r[t],dir,level,atrAt[t]))
         continue;
      //--- signal: entry beyond the confirmation candle
      double entry=(dir==LLB_DIR_BUY) ? LLB_NormPrice(r[t].high+tick,tick,digits,0) : LLB_NormPrice(r[t].low-tick,tick,digits,0);
      //--- retest structure extreme: bars t..b-1
      double extreme=(dir==LLB_DIR_BUY) ? r[t].low : r[t].high;
      datetime extremeT=r[t].time;
      for(int k=t+1; k<=b-1; k++)
        {
         if(dir==LLB_DIR_BUY && r[k].low<extreme)
           {
            extreme=r[k].low;
            extremeT=r[k].time;
           }
         if(dir==LLB_DIR_SELL && r[k].high>extreme)
           {
            extreme=r[k].high;
            extremeT=r[k].time;
           }
        }
      double ref=0.0;
      datetime refT=0;
      if(!LLB_ReferenceSwing(r,n,t,dir,extreme,extremeT,swingRefMode,nearestMode,lookback,ref,refT,why))
         return false;
      c.symbol=sym;
      c.strategy=LLB_STRAT_BREAKOUT;
      c.direction=dir;
      c.level=(dir==LLB_DIR_BUY) ? LLB_LVL_P4 : LLB_LVL_P3;
      c.levelPrice=level;
      c.signalBarTime=r[t].time;
      c.atr=atrAt[t];
      c.entry=entry;
      c.refSwingPrice=ref;
      c.refSwingTime=refT;
      double dist=(dir==LLB_DIR_BUY) ? MathAbs(r[t].low-level) : MathAbs(r[t].high-level);
      c.reason=StringFormat("BREAKOUT %s at %s=%s: breakout candle %s closed %s (threshold %s), retest after %d candle(s) %s=%s (%.2fATR from level), %s confirmation",
                            LLB_DirName(dir),LLB_LevelName(c.level),DoubleToString(level,digits),TimeToString(r[b].time,TIME_DATE|TIME_MINUTES),
                            DoubleToString(r[b].close,digits),
                            DoubleToString((dir==LLB_DIR_BUY) ? level+LLB_BREAKOUT_ATR*atrAt[b] : level-LLB_BREAKOUT_ATR*atrAt[b],digits),
                            b-t,(dir==LLB_DIR_BUY) ? "low" : "high",
                            DoubleToString((dir==LLB_DIR_BUY) ? r[t].low : r[t].high,digits),dist/atrAt[t],
                            (dir==LLB_DIR_BUY) ? "bullish" : "bearish");
      c.valid=true;
      return true;
     }
   return false;
  }

bool LLB_DetectBreakout(const MqlRates &r[],const int n,const int t,const LLBLevels &lvAt[],const double &atrAt[],const double tick,
                        const int digits,const int swingRefMode,const int nearestMode,const int lookback,const string sym,
                        LLBSignalCandidate &c,string &why)
  {
   why="";
   if(LLB_DetectBreakoutDir(r,n,t,lvAt,atrAt,tick,digits,LLB_DIR_BUY,swingRefMode,nearestMode,lookback,sym,c,why))
      return true;
   if(why!="")
      return false;
   return LLB_DetectBreakoutDir(r,n,t,lvAt,atrAt,tick,digits,LLB_DIR_SELL,swingRefMode,nearestMode,lookback,sym,c,why);
  }

#endif
//+------------------------------------------------------------------+
