//+------------------------------------------------------------------+
//| LLB_Levels.mqh                                                   |
//| LiquidityLevelEngine - pure functions on SERIES arrays           |
//| (index 0 = forming bar, larger index = older bar).               |
//|                                                                  |
//| Pivot 3-3 at index i is CONFIRMED as of closed bar t only when   |
//| its 3 right-hand bars (i-1..i-3) are all closed, i.e. i-3 >= t,  |
//| and its 3 left-hand bars exist (i+3 < n). Strict inequalities.   |
//| No bar newer than t is ever read => no repaint, no future data.  |
//+------------------------------------------------------------------+
#ifndef LLB_LEVELS_MQH
#define LLB_LEVELS_MQH

#include "LLB_Defines.mqh"
#include "LLB_Utils.mqh"

bool LLB_IsPivotHigh(const MqlRates &r[],const int n,const int i)
  {
   if(i-LLB_PIVOT_RIGHT<0 || i+LLB_PIVOT_LEFT>=n)
      return false;
   double h=r[i].high;
   for(int k=1; k<=LLB_PIVOT_LEFT; k++)
      if(!(h>r[i+k].high))
         return false;
   for(int k=1; k<=LLB_PIVOT_RIGHT; k++)
      if(!(h>r[i-k].high))
         return false;
   return true;
  }

bool LLB_IsPivotLow(const MqlRates &r[],const int n,const int i)
  {
   if(i-LLB_PIVOT_RIGHT<0 || i+LLB_PIVOT_LEFT>=n)
      return false;
   double l=r[i].low;
   for(int k=1; k<=LLB_PIVOT_LEFT; k++)
      if(!(l<r[i+k].low))
         return false;
   for(int k=1; k<=LLB_PIVOT_RIGHT; k++)
      if(!(l<r[i-k].low))
         return false;
   return true;
  }

//+------------------------------------------------------------------+
//| Nearest confirmed pivot (as of closed bar asOf) beyond threshold |
//| high=true : pivot highs with price > threshold (>= if inclusive) |
//|             nearest by price = LOWEST such high                  |
//| high=false: pivot lows  with price < threshold (<= if inclusive) |
//|             nearest by price = HIGHEST such low                  |
//| nearest by time = most recent (smallest index).                  |
//| Ties keep the most recent pivot.                                 |
//+------------------------------------------------------------------+
bool LLB_FindSwingBeyond(const MqlRates &r[],const int n,const int asOf,const bool high,const double threshold,
                         const bool inclusive,const int lookback,const int nearestMode,LLBSwingPoint &out)
  {
   out.Reset();
   if(asOf<1 || lookback<1 || threshold<=0.0)
      return false;
   int start=asOf+LLB_PIVOT_RIGHT;
   int last=start+lookback-1;
   if(last>n-1-LLB_PIVOT_LEFT)
      last=n-1-LLB_PIVOT_LEFT;
   for(int i=start; i<=last; i++)
     {
      bool piv=high ? LLB_IsPivotHigh(r,n,i) : LLB_IsPivotLow(r,n,i);
      if(!piv)
         continue;
      double p=high ? r[i].high : r[i].low;
      bool beyond=false;
      if(high)
         beyond=inclusive ? (p>=threshold) : (p>threshold);
      else
         beyond=inclusive ? (p<=threshold) : (p<threshold);
      if(!beyond)
         continue;
      if(!out.valid)
        {
         out.price=p;
         out.time=r[i].time;
         out.shift=i;
         out.valid=true;
         if(nearestMode==LLB_NEAREST_TIME)
            return true;
         continue;
        }
      if((high && p<out.price) || (!high && p>out.price))
        {
         out.price=p;
         out.time=r[i].time;
         out.shift=i;
        }
     }
   return out.valid;
  }

//+------------------------------------------------------------------+
//| Four liquidity levels as of closed bar asOf.                     |
//| pdh/pdl come from the last CLOSED broker D1 bar (MarketData).    |
//| Partially found levels are kept for the dashboard; valid=false.  |
//+------------------------------------------------------------------+
bool LLB_ComputeLevels(const MqlRates &r[],const int n,const int asOf,const double pdh,const double pdl,const datetime d1Time,
                       const int lookback,const int nearestMode,LLBLevels &lv)
  {
   lv.Reset();
   lv.pdh=pdh;
   lv.pdl=pdl;
   lv.d1Time=d1Time;
   if(pdh<=0.0 || pdl<=0.0 || !(pdl<pdh))
     {
      lv.why="PDH_PDL_INVALID";
      return false;
     }
   LLBSwingPoint s3,s4;
   bool ok3=LLB_FindSwingBeyond(r,n,asOf,false,pdl,false,lookback,nearestMode,s3);
   bool ok4=LLB_FindSwingBeyond(r,n,asOf,true,pdh,false,lookback,nearestMode,s4);
   if(ok3)
     {
      lv.p3=s3.price;
      lv.p3Time=s3.time;
     }
   if(ok4)
     {
      lv.p4=s4.price;
      lv.p4Time=s4.time;
     }
   if(!ok3)
     {
      lv.why="P3_MISSING";
      return false;
     }
   if(!ok4)
     {
      lv.why="P4_MISSING";
      return false;
     }
   if(!(lv.p3<lv.pdl && lv.pdl<lv.pdh && lv.pdh<lv.p4))
     {
      lv.why="ORDER_P3<PDL<PDH<P4_VIOLATED";
      return false;
     }
   lv.valid=true;
   lv.why="OK";
   return true;
  }

#endif
//+------------------------------------------------------------------+
