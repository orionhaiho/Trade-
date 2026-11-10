//+------------------------------------------------------------------+
//| AG_Environment.mqh                                               |
//| Symbol/account validation, symbol spec cache, trading permission,|
//| trade sessions, OrderCalcProfit sanity check.                    |
//+------------------------------------------------------------------+
#ifndef AG_ENVIRONMENT_MQH
#define AG_ENVIRONMENT_MQH

#include "AG_Types.mqh"
#include "AG_Math.mqh"
#include "AG_Logger.mqh"

struct AGSymbolSpec
  {
   string            name;
   double            volMin;
   double            volMax;
   double            volStep;
   double            contract;
   double            tickSize;
   double            tickValue;
   double            point;
   int               digits;
   long              stopsLevel;
   long              freezeLevel;
   string            profitCcy;
   string            marginCcy;
  };

AGSymbolSpec            g_spec;
ENUM_ORDER_TYPE_FILLING g_filling=ORDER_FILLING_FOK;
ENUM_ENV_STATUS         g_envSymbol=ENV_UNKNOWN;
ENUM_ENV_STATUS         g_envHedging=ENV_UNKNOWN;
ENUM_ENV_STATUS         g_envCurrency=ENV_UNKNOWN;
ENUM_ENV_STATUS         g_envSpecs=ENV_UNKNOWN;
ENUM_ENV_STATUS         g_envCalc=ENV_UNKNOWN;
double                  g_calcProfitPerUnitMove=0.0;   // OrderCalcProfit for +1.00 price move, min volume

//+------------------------------------------------------------------+
bool LoadSymbolSpec(const string sym,string &err)
  {
   g_spec.name       =sym;
   g_spec.volMin     =SymbolInfoDouble(sym,SYMBOL_VOLUME_MIN);
   g_spec.volMax     =SymbolInfoDouble(sym,SYMBOL_VOLUME_MAX);
   g_spec.volStep    =SymbolInfoDouble(sym,SYMBOL_VOLUME_STEP);
   g_spec.contract   =SymbolInfoDouble(sym,SYMBOL_TRADE_CONTRACT_SIZE);
   g_spec.tickSize   =SymbolInfoDouble(sym,SYMBOL_TRADE_TICK_SIZE);
   g_spec.tickValue  =SymbolInfoDouble(sym,SYMBOL_TRADE_TICK_VALUE);
   g_spec.point      =SymbolInfoDouble(sym,SYMBOL_POINT);
   g_spec.digits     =(int)SymbolInfoInteger(sym,SYMBOL_DIGITS);
   g_spec.stopsLevel =SymbolInfoInteger(sym,SYMBOL_TRADE_STOPS_LEVEL);
   g_spec.freezeLevel=SymbolInfoInteger(sym,SYMBOL_TRADE_FREEZE_LEVEL);
   g_spec.profitCcy  =SymbolInfoString(sym,SYMBOL_CURRENCY_PROFIT);
   g_spec.marginCcy  =SymbolInfoString(sym,SYMBOL_CURRENCY_MARGIN);

   PrintFormat("[AG] SPEC %s volMin=%s volMax=%s volStep=%s contract=%s tickSize=%s tickValue=%s point=%s digits=%d stops=%I64d freeze=%I64d profitCcy=%s marginCcy=%s",
               sym,DoubleToString(g_spec.volMin,4),DoubleToString(g_spec.volMax,2),DoubleToString(g_spec.volStep,4),
               DoubleToString(g_spec.contract,4),DoubleToString(g_spec.tickSize,8),DoubleToString(g_spec.tickValue,8),
               DoubleToString(g_spec.point,8),g_spec.digits,g_spec.stopsLevel,g_spec.freezeLevel,g_spec.profitCcy,g_spec.marginCcy);

   if(g_spec.volMin<=0.0 || g_spec.volMax<g_spec.volMin || g_spec.volStep<=0.0 || g_spec.contract<=0.0
      || g_spec.tickSize<=0.0 || g_spec.point<=0.0 || g_spec.digits<0)
     {
      err="Invalid symbol specification (volume/contract/tick/point <= 0)";
      g_envSpecs=ENV_INVALID;
      return false;
     }
   g_envSpecs=ENV_VALID;
   return true;
  }

//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING DetectFilling(const string sym)
  {
   long fm=SymbolInfoInteger(sym,SYMBOL_FILLING_MODE);
   if((fm&SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK)
      return ORDER_FILLING_FOK;
   if((fm&SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC)
      return ORDER_FILLING_IOC;
   return ORDER_FILLING_RETURN;
  }

//+------------------------------------------------------------------+
//| OrderCalcProfit sanity: +1.00 price move with minimum volume.    |
//| Returns true only when VALID. Sets g_envCalc.                    |
//+------------------------------------------------------------------+
bool VerifyProfitCalc(string &err)
  {
   MqlTick t;
   if(!SymbolInfoTick(g_spec.name,t) || t.bid<=0.0)
     {
      g_envCalc=ENV_UNKNOWN;
      err="no tick available yet";
      return false;
     }
   double p1=0.0,p2=0.0;
   ResetLastError();
   bool ok1=OrderCalcProfit(ORDER_TYPE_BUY,g_spec.name,g_spec.volMin,t.bid,t.bid+1.0,p1);
   bool ok2=OrderCalcProfit(ORDER_TYPE_SELL,g_spec.name,g_spec.volMin,t.bid,t.bid+1.0,p2);
   if(!ok1 || !ok2)
     {
      g_envCalc=ENV_UNKNOWN;     // may succeed later (e.g. before first tick in tester)
      err="OrderCalcProfit failed err="+(string)GetLastError();
      return false;
     }
   if(!MathIsValidNumber(p1) || !MathIsValidNumber(p2) || p1<=0.0 || p2>=0.0)
     {
      g_envCalc=ENV_INVALID;
      err="OrderCalcProfit returned implausible values buy="+DoubleToString(p1,6)+" sell="+DoubleToString(p2,6);
      return false;
     }
   g_calcProfitPerUnitMove=p1;
   g_envCalc=ENV_VALID;
   PrintFormat("[AG] CALC_CHECK OrderCalcProfit(+1.00 price, %s lots) = %s %s (reference only; verify on demo)",
               DoubleToString(g_spec.volMin,2),DoubleToString(p1,6),AccountInfoString(ACCOUNT_CURRENCY));
   return true;
  }

//+------------------------------------------------------------------+
//| Init-time validation. Any failure => INIT_FAILED.                |
//+------------------------------------------------------------------+
bool ValidateEnvironment(string &err)
  {
//--- input sanity
   if(g_cfg.tf!=PERIOD_M1)
     { err="InpTF must be M1"; return false; }
   if(g_cfg.lotMultiplier!=1.0)
     { err="LotMultiplier must be exactly 1.0 (martingale/lot escalation is prohibited)"; return false; }
   if(g_cfg.maxLayers<1)
     { err="MaxLayers must be >= 1"; return false; }
   if(g_cfg.minGrid<=0.0 || g_cfg.maxGrid<g_cfg.minGrid || g_cfg.atrMultiplier<=0.0 || g_cfg.maxATR<=0.0)
     { err="Grid inputs invalid (MinGridUSD>0, MaxGridUSD>=MinGridUSD, ATRMultiplier>0, MaxATR_USD>0)"; return false; }
   if(g_cfg.atrPeriod<1 || g_cfg.rsiPeriod<1 || g_cfg.bbPeriod<2 || g_cfg.adxPeriod<1 || g_cfg.bbDev<=0.0)
     { err="Indicator periods invalid"; return false; }
   if(g_cfg.basketRiskPct<=0.0 || g_cfg.basketTP<=0.0 || (!g_cfg.useSLFromBudget && g_cfg.basketSL<=0.0))
     { err="Basket risk/TP/SL inputs must be > 0"; return false; }
   if(g_cfg.maxCombinedLoss<=0.0 || g_cfg.dailyLoss<=0.0 || g_cfg.maxEquityDDPct<=0.0 || g_cfg.accountProtPct<=0.0)
     { err="Account protection limits must be > 0"; return false; }
   if(g_cfg.stressMoveATR<0.0 || g_cfg.slippageStressPts<0.0 || g_cfg.spreadStressMult<1.0 || g_cfg.commissionPerLotEst<0.0)
     { err="Stress inputs invalid (StressMoveATR>=0, SlippageStressPoints>=0, SpreadStressMultiplier>=1, CommissionPerLotEstimate>=0)"; return false; }
   if(g_cfg.maxMarginUsage<=0.0 || g_cfg.maxMarginUsage>1.0)
     { err="MaxMarginUsage must be in (0,1]"; return false; }
   if(g_cfg.maxSpread<=0.0 || g_cfg.maxSlippagePts<0 || g_cfg.cooldownSec<0 || g_cfg.maxCloseRetries<1
      || g_cfg.closeRetryDelayMs<0 || g_cfg.pendingTimeoutMs<1000 || g_cfg.reconcileTimeoutSec<1 || g_cfg.sessionEdgeMin<0)
     { err="Execution inputs invalid"; return false; }
   if(g_cfg.magicBuy==g_cfg.magicSell || g_cfg.magicBuy<=0 || g_cfg.magicSell<=0)
     { err="MagicBuy and MagicSell must be positive and different"; return false; }
   if(!g_cfg.enablePersistentState && !(bool)MQLInfoInteger(MQL_TESTER))
     { err="EnablePersistentState=false is only allowed in the Strategy Tester"; return false; }

//--- symbol (never substituted)
   if(!SymbolSelect(g_cfg.symbol,true) || !(bool)SymbolInfoInteger(g_cfg.symbol,SYMBOL_EXIST))
     { g_envSymbol=ENV_INVALID; err="Symbol '"+g_cfg.symbol+"' does not exist on this account"; return false; }
   if(_Symbol!=g_cfg.symbol)
     { g_envSymbol=ENV_INVALID; err="Chart symbol '"+_Symbol+"' differs from InpSymbol '"+g_cfg.symbol+"'"; return false; }
   g_envSymbol=ENV_VALID;

//--- account
   ENUM_ACCOUNT_MARGIN_MODE mm=(ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
   if(mm!=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
     { g_envHedging=ENV_INVALID; err="Account is not Retail Hedging (margin mode="+EnumToString(mm)+")"; return false; }
   g_envHedging=ENV_VALID;

   string ccy=AccountInfoString(ACCOUNT_CURRENCY);
   if(ccy!=g_cfg.requiredCurrency)
     { g_envCurrency=ENV_INVALID; err="Account currency '"+ccy+"' differs from RequiredAccountCurrency '"+g_cfg.requiredCurrency+"'"; return false; }
   g_envCurrency=ENV_VALID;

//--- specification
   if(!LoadSymbolSpec(g_cfg.symbol,err))
      return false;
   if(!AG_IsValidVolume(g_cfg.initialLot,g_spec.volMin,g_spec.volMax,g_spec.volStep))
     { err="InitialLot "+DoubleToString(g_cfg.initialLot,4)+" is not a valid volume for this symbol (no automatic rounding)"; return false; }
   if(!AG_IsValidVolume(g_cfg.maxSideLots,g_spec.volMin,1e12,g_spec.volStep))
     { err="MaxSideLots is not a multiple of the volume step"; return false; }
   if(AG_VolumeToSteps(g_cfg.maxSideLots,g_spec.volStep)<AG_VolumeToSteps(g_cfg.initialLot,g_spec.volStep))
     { err="MaxSideLots < InitialLot"; return false; }

   g_filling=DetectFilling(g_cfg.symbol);

//--- profit calc: INVALID blocks init; UNKNOWN is re-checked before first order
   string e2;
   if(!VerifyProfitCalc(e2))
     {
      if(g_envCalc==ENV_INVALID)
        { err=e2; return false; }
      g_log.Warn("Profit calc check deferred: "+e2);
     }
   return true;
  }

//+------------------------------------------------------------------+
bool IsTradingAllowedNow(string &reason)
  {
   if(!(bool)TerminalInfoInteger(TERMINAL_CONNECTED))      { reason="NO_CONNECTION";            return false; }
   if(!(bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))  { reason="TERMINAL_TRADE_DISABLED";  return false; }
   if(!(bool)MQLInfoInteger(MQL_TRADE_ALLOWED))            { reason="EA_TRADE_DISABLED";        return false; }
   if(!(bool)AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))    { reason="ACCOUNT_TRADE_DISABLED";   return false; }
   if(!(bool)AccountInfoInteger(ACCOUNT_TRADE_EXPERT))     { reason="ACCOUNT_EXPERT_DISABLED";  return false; }
   ENUM_SYMBOL_TRADE_MODE tm=(ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(g_spec.name,SYMBOL_TRADE_MODE);
   if(tm!=SYMBOL_TRADE_MODE_FULL)                          { reason="SYMBOL_TRADE_MODE_"+EnumToString(tm); return false; }
   return true;
  }

//+------------------------------------------------------------------+
//| True when serverNow is inside a broker trade session, at least   |
//| edgeMin minutes away from the session start and end.             |
//+------------------------------------------------------------------+
bool IsWithinTradeSession(const datetime serverNow,const int edgeMin)
  {
   MqlDateTime dt;
   TimeToStruct(serverNow,dt);
   long sod=(long)dt.hour*3600+(long)dt.min*60+(long)dt.sec;
   long edge=(long)edgeMin*60;
   datetime from=0,to=0;
   for(uint i=0; i<16; i++)
     {
      if(!SymbolInfoSessionTrade(g_spec.name,(ENUM_DAY_OF_WEEK)dt.day_of_week,i,from,to))
         break;
      long f=(long)from;
      long tt=(long)to;
      if(sod>=f+edge && sod<tt-edge)
         return true;
     }
   return false;
  }

#endif
//+------------------------------------------------------------------+
