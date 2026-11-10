//+------------------------------------------------------------------+
//| AG_GridManager.mqh                                               |
//| Grid spacing (ATR, clamp, tick) and add-on trigger.              |
//+------------------------------------------------------------------+
#ifndef AG_GRIDMANAGER_MQH
#define AG_GRIDMANAGER_MQH

#include "AG_Types.mqh"
#include "AG_Math.mqh"
#include "AG_Environment.mqh"

//--- price units of the symbol; -1 when ATR invalid
double CalculateGridDistance(const double atr1)
  {
   double gd=AG_CalcGridDistance(atr1,g_cfg.atrMultiplier,g_cfg.minGrid,g_cfg.maxGrid,g_spec.tickSize);
   if(gd<=0.0)
      return -1.0;
   return NormalizeDouble(gd,g_spec.digits);
  }

//--- lastFill = POSITION_PRICE_OPEN of the most recent layer (actual fill price)
bool GridTriggerHit(const int side,const MqlTick &t,const double lastFill,const double gd)
  {
   if(side==AG_BUY)
      return AG_BuyGridTrigger(t.bid,lastFill,gd);
   return AG_SellGridTrigger(t.ask,lastFill,gd);
  }

bool IsValidSymbolVolume(const double v)
  {
   return AG_IsValidVolume(v,g_spec.volMin,g_spec.volMax,g_spec.volStep);
  }

long VolSteps(const double v)
  {
   return AG_VolumeToSteps(v,g_spec.volStep);
  }

#endif
//+------------------------------------------------------------------+
