//+------------------------------------------------------------------+
//| LLB_MarketData.mqh                                               |
//| MarketDataProvider: symbol specification, closed M15/D1 bars,    |
//| ATR(14), tick history, trade sessions, server time.              |
//| Every value comes from the terminal at runtime - no broker       |
//| constants are hard-coded (XAUUSD / XAUUSDc differ).              |
//+------------------------------------------------------------------+
#ifndef LLB_MARKETDATA_MQH
#define LLB_MARKETDATA_MQH

#include "LLB_Defines.mqh"
#include "LLB_Utils.mqh"
#include "LLB_Logger.mqh"

class CLLBMarketData
  {
public:
   datetime          Now(void) { return TimeTradeServer(); }

   //--- symbol specification (R-CFG-02, Phase 2 §6)
   bool              LoadSpec(const string sym,LLBSymbolSpec &spec,string &err)
     {
      spec.Reset();
      spec.name=sym;
      if(!SymbolSelect(sym,true))
        {
         err="symbol '"+sym+"' not available on this account (SymbolSelect failed)";
         return false;
        }
      if(!(bool)SymbolInfoInteger(sym,SYMBOL_EXIST))
        {
         err="symbol '"+sym+"' does not exist";
         return false;
        }
      spec.digits        =(int)SymbolInfoInteger(sym,SYMBOL_DIGITS);
      spec.point         =SymbolInfoDouble(sym,SYMBOL_POINT);
      spec.tickSize      =SymbolInfoDouble(sym,SYMBOL_TRADE_TICK_SIZE);
      spec.tickValue     =SymbolInfoDouble(sym,SYMBOL_TRADE_TICK_VALUE);
      spec.volMin        =SymbolInfoDouble(sym,SYMBOL_VOLUME_MIN);
      spec.volMax        =SymbolInfoDouble(sym,SYMBOL_VOLUME_MAX);
      spec.volStep       =SymbolInfoDouble(sym,SYMBOL_VOLUME_STEP);
      spec.volLimit      =SymbolInfoDouble(sym,SYMBOL_VOLUME_LIMIT);
      spec.contract      =SymbolInfoDouble(sym,SYMBOL_TRADE_CONTRACT_SIZE);
      spec.stopsLevel    =SymbolInfoInteger(sym,SYMBOL_TRADE_STOPS_LEVEL);
      spec.freezeLevel   =SymbolInfoInteger(sym,SYMBOL_TRADE_FREEZE_LEVEL);
      spec.expirationMode=SymbolInfoInteger(sym,SYMBOL_EXPIRATION_MODE);
      spec.fillingMode   =SymbolInfoInteger(sym,SYMBOL_FILLING_MODE);
      spec.orderMode     =SymbolInfoInteger(sym,SYMBOL_ORDER_MODE);
      spec.tradeMode     =SymbolInfoInteger(sym,SYMBOL_TRADE_MODE);
      spec.execMode      =SymbolInfoInteger(sym,SYMBOL_TRADE_EXEMODE);
      if(spec.tickSize<=0.0 && spec.point>0.0)
         spec.tickSize=spec.point;
      if(spec.point<=0.0 || spec.tickSize<=0.0 || spec.digits<0 || spec.volMin<=0.0 || spec.volMax<spec.volMin || spec.volStep<=0.0)
        {
         err=StringFormat("invalid specification for %s (point=%s tick=%s volMin=%s volStep=%s)",sym,
                          DoubleToString(spec.point,8),DoubleToString(spec.tickSize,8),DoubleToString(spec.volMin,4),DoubleToString(spec.volStep,4));
         return false;
        }
      spec.valid=true;
      return true;
     }

   string            SpecText(const LLBSymbolSpec &s)
     {
      return StringFormat("%s digits=%d point=%s tickSize=%s tickValue=%s vol[min=%s max=%s step=%s limit=%s] contract=%s stops=%I64d freeze=%I64d expMode=%I64d fillMode=%I64d orderMode=%I64d tradeMode=%I64d execMode=%I64d",
                          s.name,s.digits,DoubleToString(s.point,8),DoubleToString(s.tickSize,8),DoubleToString(s.tickValue,6),
                          DoubleToString(s.volMin,4),DoubleToString(s.volMax,2),DoubleToString(s.volStep,4),DoubleToString(s.volLimit,2),
                          DoubleToString(s.contract,4),s.stopsLevel,s.freezeLevel,s.expirationMode,s.fillingMode,s.orderMode,s.tradeMode,s.execMode);
     }

   bool              GetTick(const string sym,MqlTick &t)
     {
      if(!SymbolInfoTick(sym,t))
         return false;
      return (t.bid>0.0 && t.ask>0.0);
     }

   //--- M15 bars, series order (index 0 = forming bar, NEVER used for signals)
   int               CopyM15(const string sym,const int count,MqlRates &rates[])
     {
      ArraySetAsSeries(rates,true);
      ResetLastError();
      return CopyRates(sym,PERIOD_M15,0,count,rates);
     }

   //--- PDH/PDL as of a closed M15 bar: the last CLOSED D1 bar before the
   //--- broker trading day that contains barTime (R-LVL-01/02).
   bool              PrevDayHL(const string sym,const datetime barTime,double &pdh,double &pdl,datetime &d1Time,string &why)
     {
      pdh=0.0;
      pdl=0.0;
      d1Time=0;
      int d=iBarShift(sym,PERIOD_D1,barTime,false);
      if(d<0)
        {
         why="D1_SHIFT_UNAVAILABLE";
         return false;
        }
      datetime dayOpen=iTime(sym,PERIOD_D1,d);
      if(dayOpen<=0 || LLB_DayStart(barTime)!=LLB_DayStart(dayOpen))
        {
         why="D1_NOT_SYNCHRONISED";
         return false;
        }
      MqlRates r[];
      ArraySetAsSeries(r,true);
      ResetLastError();
      if(CopyRates(sym,PERIOD_D1,d+1,1,r)!=1)
        {
         why="D1_COPY_FAILED err="+(string)GetLastError();
         return false;
        }
      pdh=r[0].high;
      pdl=r[0].low;
      d1Time=r[0].time;
      if(pdh<=0.0 || pdl<=0.0 || pdl>=pdh)
        {
         why="D1_BAR_INVALID";
         return false;
        }
      return true;
     }

   //--- ATR(14) value as of a closed M15 bar.
   //--- tf == M15: the same bar (series shift m15Shift);
   //--- other tf : the last CLOSED bar of that timeframe before barTime.
   bool              AtrAt(const int handle,const string sym,const ENUM_TIMEFRAMES tf,const datetime barTime,const int m15Shift,double &atr,string &why)
     {
      atr=0.0;
      if(handle==INVALID_HANDLE)
        {
         why="ATR_HANDLE_INVALID";
         return false;
        }
      int shift=m15Shift;
      if(tf!=PERIOD_M15)
        {
         int s=iBarShift(sym,tf,barTime,false);
         if(s<0)
           {
            why="ATR_TF_SHIFT_UNAVAILABLE";
            return false;
           }
         shift=s+1;
        }
      double buf[];
      ArraySetAsSeries(buf,true);
      ResetLastError();
      //--- copy first: in the non-visual tester indicators are computed lazily
      if(CopyBuffer(handle,0,shift,1,buf)!=1)
        {
         why="ATR_COPY_FAILED err="+(string)GetLastError();
         return false;
        }
      if(BarsCalculated(handle)<LLB_ATR_PERIOD+shift)
        {
         why="ATR_NOT_CALCULATED";
         return false;
        }
      atr=buf[0];
      if(!MathIsValidNumber(atr) || atr<=0.0 || atr==EMPTY_VALUE)
        {
         why="ATR_VALUE_INVALID";
         atr=0.0;
         return false;
        }
      return true;
     }

   //--- all INFO ticks with time_msc >= fromMsc (up to the end of history). -1 on error.
   int               TicksFrom(const string sym,const long fromMsc,MqlTick &ticks[],int &err)
     {
      ulong from=(ulong)((fromMsc>1) ? fromMsc : 1);
      ResetLastError();
      int n=CopyTicksRange(sym,ticks,COPY_TICKS_INFO,from,0);
      err=GetLastError();
      return n;
     }

   //--- true when serverNow is inside one of the symbol's trade sessions
   bool              IsTradeSessionOpen(const string sym,const datetime serverNow)
     {
      MqlDateTime dt;
      TimeToStruct(serverNow,dt);
      long sod=(long)dt.hour*3600+(long)dt.min*60+(long)dt.sec;
      datetime from=0,to=0;
      for(uint i=0; i<16; i++)
        {
         if(!SymbolInfoSessionTrade(sym,(ENUM_DAY_OF_WEEK)dt.day_of_week,i,from,to))
            break;
         long f=(long)from;
         long tt=(long)to;
         if(sod>=f && sod<tt)
            return true;
        }
      return false;
     }
  };

#endif
//+------------------------------------------------------------------+
