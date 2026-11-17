//+------------------------------------------------------------------+
//| LLB_Risk.mqh                                                     |
//| Volume (R-RSK-01/04/05) and optional Daily Loss Limit (A-10).    |
//| FIXED: the configured lot exactly, validated, never adjusted.    |
//| RISK_PERCENT: money at risk from Entry->SL via OrderCalcProfit   |
//| (handles currency conversion), rounded DOWN to the volume step;  |
//| below the minimum volume => refuse (never round up).             |
//| No portfolio / dynamic / scaling risk logic (R-RSK-03).          |
//+------------------------------------------------------------------+
#ifndef LLB_RISK_MQH
#define LLB_RISK_MQH

#include "LLB_Defines.mqh"
#include "LLB_Utils.mqh"
#include "LLB_Logger.mqh"

class CLLBRisk
  {
private:
   int               m_mode;
   double            m_lot;
   double            m_pct;
   int               m_base;
   double            m_dailyLimit;
   ulong             m_magic;

public:
                     CLLBRisk(void)
     {
      m_mode=LLB_LOT_FIXED;
      m_lot=0.0;
      m_pct=0.0;
      m_base=LLB_RISK_BALANCE;
      m_dailyLimit=0.0;
      m_magic=0;
     }

   void              Init(const int mode,const double lot,const double pct,const int base,const double dailyLimit,const ulong magic)
     {
      m_mode=mode;
      m_lot=lot;
      m_pct=pct;
      m_base=base;
      m_dailyLimit=dailyLimit;
      m_magic=magic;
     }

   bool              ValidateConfig(string &err)
     {
      if(m_mode==LLB_LOT_FIXED)
        {
         if(!MathIsValidNumber(m_lot) || m_lot<=0.0)
           {
            err="InpLotSize must be > 0 when InpLotMode = Fixed LotSize";
            return false;
           }
        }
      else
         if(m_mode==LLB_LOT_RISK_PERCENT)
           {
            if(!MathIsValidNumber(m_pct) || m_pct<=0.0 || m_pct>100.0)
              {
               err="InpRiskPercent must be in (0,100] when InpLotMode = RiskPercent";
               return false;
              }
           }
         else
           {
            err="InpLotMode invalid";
            return false;
           }
      if(!MathIsValidNumber(m_dailyLimit) || m_dailyLimit<0.0)
        {
         err="InpDailyLossLimit must be >= 0 (0 = disabled)";
         return false;
        }
      return true;
     }

   string            Describe(void)
     {
      string s=(m_mode==LLB_LOT_FIXED) ? "FIXED lot="+DoubleToString(m_lot,2)
               : "RISK_PERCENT "+DoubleToString(m_pct,2)+"% of "+((m_base==LLB_RISK_EQUITY) ? "Equity" : "Balance");
      s+=(m_dailyLimit>0.0) ? " | DailyLossLimit="+DoubleToString(m_dailyLimit,2)+" "+AccountInfoString(ACCOUNT_CURRENCY) : " | DailyLossLimit=off";
      return s;
     }

   bool              ComputeVolume(const LLBSymbolSpec &spec,const int dir,const double entry,const double sl,double &vol,string &why)
     {
      vol=0.0;
      why="";
      if(m_mode==LLB_LOT_FIXED)
        {
         if(!LLB_IsValidVolume(m_lot,spec.volMin,spec.volMax,spec.volStep))
           {
            why=StringFormat("LOT_INVALID lot=%s (min=%s max=%s step=%s) - not rounded",DoubleToString(m_lot,4),
                             DoubleToString(spec.volMin,4),DoubleToString(spec.volMax,2),DoubleToString(spec.volStep,4));
            return false;
           }
         vol=m_lot;
         return true;
        }
      double base=(m_base==LLB_RISK_EQUITY) ? AccountInfoDouble(ACCOUNT_EQUITY) : AccountInfoDouble(ACCOUNT_BALANCE);
      double riskMoney=base*m_pct/100.0;
      double profit=0.0;
      ENUM_ORDER_TYPE t=(dir==LLB_DIR_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      ResetLastError();
      if(!OrderCalcProfit(t,spec.name,1.0,entry,sl,profit))
        {
         why="ORDERCALCPROFIT_FAILED err="+(string)GetLastError();
         return false;
        }
      if(!MathIsValidNumber(profit) || profit>=0.0)
        {
         why="ORDERCALCPROFIT_IMPLAUSIBLE "+DoubleToString(profit,4);
         return false;
        }
      double lossPerLot=-profit;
      vol=LLB_CalcRiskLots(riskMoney,lossPerLot,spec.volMin,spec.volMax,spec.volStep,why);
      if(vol<=0.0)
         return false;
      if(!LLB_IsValidVolume(vol,spec.volMin,spec.volMax,spec.volStep))
        {
         why="RISK_VOLUME_INVALID "+DoubleToString(vol,4);
         vol=0.0;
         return false;
        }
      return true;
     }

   //--- realized P/L today (broker server day) of EA positions; blocks new executions when the loss limit is reached
   bool              DailyLossBlocked(const datetime now,const long &ourPositionIds[],double &realized,string &why)
     {
      realized=0.0;
      why="";
      if(m_dailyLimit<=0.0)
         return false;
      datetime dayStart=LLB_DayStart(now);
      if(!HistorySelect(dayStart,now+86400))
        {
         why="DAILY_LOSS_HISTORY_UNAVAILABLE";
         return true;                                    // fail-safe: cannot verify the limit
        }
      int n=HistoryDealsTotal();
      for(int i=0; i<n; i++)
        {
         ulong tk=HistoryDealGetTicket(i);
         if(tk==0)
            continue;
         long type=HistoryDealGetInteger(tk,DEAL_TYPE);
         if(type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL)
            continue;
         bool ours=((ulong)HistoryDealGetInteger(tk,DEAL_MAGIC)==m_magic);
         if(!ours)
            ours=LLB_IdInList(HistoryDealGetInteger(tk,DEAL_POSITION_ID),ourPositionIds);
         if(!ours)
            continue;
         realized+=HistoryDealGetDouble(tk,DEAL_PROFIT)+HistoryDealGetDouble(tk,DEAL_COMMISSION)
                   +HistoryDealGetDouble(tk,DEAL_SWAP)+HistoryDealGetDouble(tk,DEAL_FEE);
        }
      if(realized<=-m_dailyLimit)
        {
         why=StringFormat("DAILY_LOSS_LIMIT_REACHED realized=%s limit=%s",DoubleToString(realized,2),DoubleToString(m_dailyLimit,2));
         return true;
        }
      return false;
     }
  };

#endif
//+------------------------------------------------------------------+
