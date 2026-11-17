//+------------------------------------------------------------------+
//| LLB_StopLoss.mqh                                                 |
//| StopLossCalculator - pure functions (SRS 4.5).                   |
//| Buffer = max(2 x TickSize, 0.05 x ATR14)                          |
//| BUY  SL = SwingLow  - Buffer, rounded DOWN to the tick grid      |
//| SELL SL = SwingHigh + Buffer, rounded UP   to the tick grid      |
//| TP = Entry +/- 2 x |Entry - SL|  (RR 1:2)                        |
//| Invalid geometry => candidate discarded; prices never "fixed".   |
//+------------------------------------------------------------------+
#ifndef LLB_STOPLOSS_MQH
#define LLB_STOPLOSS_MQH

#include "LLB_Defines.mqh"
#include "LLB_Utils.mqh"

double LLB_SlBuffer(const double atr,const double tick)
  {
   return MathMax(LLB_SL_BUFFER_TICKS*tick,LLB_SL_BUFFER_ATR*atr);
  }

bool LLB_ComputeStops(const int dir,const double entry,const double refSwing,const double atr,const double tick,const int digits,
                      double &sl,double &tp,double &rr,double &buffer,string &why)
  {
   sl=0.0;
   tp=0.0;
   rr=0.0;
   buffer=0.0;
   why="";
   if(tick<=0.0 || entry<=0.0 || refSwing<=0.0 || !MathIsValidNumber(atr) || atr<=0.0)
     {
      why="STOPS_INPUT_INVALID";
      return false;
     }
   buffer=LLB_SlBuffer(atr,tick);
   double risk=0.0;
   if(dir==LLB_DIR_BUY)
     {
      sl=LLB_NormPrice(refSwing-buffer,tick,digits,-1);
      risk=entry-sl;
      tp=LLB_NormPrice(entry+LLB_RR*risk,tick,digits,0);
      if(!(LLB_PriceBelow(sl,refSwing,tick) && LLB_PriceBelow(refSwing,entry,tick) && LLB_PriceBelow(entry,tp,tick)))
        {
         why=StringFormat("GEOMETRY_INVALID BUY sl=%s ref=%s entry=%s tp=%s",DoubleToString(sl,digits),DoubleToString(refSwing,digits),
                          DoubleToString(entry,digits),DoubleToString(tp,digits));
         return false;
        }
     }
   else
      if(dir==LLB_DIR_SELL)
        {
         sl=LLB_NormPrice(refSwing+buffer,tick,digits,1);
         risk=sl-entry;
         tp=LLB_NormPrice(entry-LLB_RR*risk,tick,digits,0);
         if(!(LLB_PriceBelow(tp,entry,tick) && LLB_PriceBelow(entry,refSwing,tick) && LLB_PriceBelow(refSwing,sl,tick)) || tp<=0.0)
           {
            why=StringFormat("GEOMETRY_INVALID SELL tp=%s entry=%s ref=%s sl=%s",DoubleToString(tp,digits),DoubleToString(entry,digits),
                             DoubleToString(refSwing,digits),DoubleToString(sl,digits));
            return false;
           }
        }
      else
        {
         why="DIRECTION_INVALID";
         return false;
        }
   if(risk<tick*0.5)
     {
      why="RISK_DISTANCE_ZERO";
      return false;
     }
   rr=MathAbs(tp-entry)/MathAbs(entry-sl);
   return true;
  }

#endif
//+------------------------------------------------------------------+
