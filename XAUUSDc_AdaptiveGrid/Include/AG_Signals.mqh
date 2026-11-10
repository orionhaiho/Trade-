//+------------------------------------------------------------------+
//| AG_Signals.mqh                                                   |
//| Entry signals (closed bars) and market regime / ATR filters.     |
//+------------------------------------------------------------------+
#ifndef AG_SIGNALS_MQH
#define AG_SIGNALS_MQH

#include "AG_Types.mqh"
#include "AG_Math.mqh"
#include "AG_Indicators.mqh"

bool CheckBuySignal(const AGIndSnapshot &s)
  {
   if(!s.valid)
      return false;
   if(g_cfg.signalMode==SIGNAL_ONE_CANDLE)
      return AG_SignalBuyOneCandle(s.low1,s.close1,s.bbLo1,s.bbUp1,s.rsi1,s.adx1,g_cfg.rsiBuy,g_cfg.maxADX);
   return AG_SignalBuyTwoCandle(s.close2,s.bbLo2,s.rsi2,s.close1,s.bbLo1,s.bbUp1,s.adx1,g_cfg.rsiBuy,g_cfg.maxADX);
  }

bool CheckSellSignal(const AGIndSnapshot &s)
  {
   if(!s.valid)
      return false;
   if(g_cfg.signalMode==SIGNAL_ONE_CANDLE)
      return AG_SignalSellOneCandle(s.high1,s.close1,s.bbLo1,s.bbUp1,s.rsi1,s.adx1,g_cfg.rsiSell,g_cfg.maxADX);
   return AG_SignalSellTwoCandle(s.close2,s.bbUp2,s.rsi2,s.close1,s.bbLo1,s.bbUp1,s.adx1,g_cfg.rsiSell,g_cfg.maxADX);
  }

//--- ADX regime on the closed bar (shift 1): true = new orders allowed
bool RegimeAllowsNewOrders(const AGIndSnapshot &s)
  {
   return (s.valid && s.adx1<g_cfg.maxADX);
  }

//--- ATR sanity on the closed bar (shift 1)
bool ATRIsValid(const AGIndSnapshot &s,string &reason)
  {
   if(!s.valid || !MathIsValidNumber(s.atr1) || s.atr1<=0.0)
     { reason="REJECT_ATR_INVALID"; return false; }
   if(s.atr1>g_cfg.maxATR)
     { reason="REJECT_ATR_ABNORMAL"; return false; }
   return true;
  }

#endif
//+------------------------------------------------------------------+
