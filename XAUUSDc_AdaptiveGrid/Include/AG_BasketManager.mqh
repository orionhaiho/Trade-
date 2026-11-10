//+------------------------------------------------------------------+
//| AG_BasketManager.mqh                                             |
//| One CBasket per side. Filters symbol + magic + position type.    |
//| Fee attribution from deal history by POSITION_IDENTIFIER.        |
//+------------------------------------------------------------------+
#ifndef AG_BASKETMANAGER_MQH
#define AG_BASKETMANAGER_MQH

#include "AG_Types.mqh"
#include "AG_Math.mqh"
#include "AG_Logger.mqh"
#include "AG_Environment.mqh"

//--- fee cache: pid -> entry commission+fee (<=0), volume at time of read
long   g_feePid[];
double g_feeVal[];
double g_feeVol[];
//--- ownership cache: pid -> magic of the entry deal
long   g_ownPid[];
long   g_ownMagic[];
//--- observed fee rate per lot per side (<=0)
double g_feeRatePerLot=0.0;
bool   g_feeRateVerified=false;
long   g_feeRateTimeMsc=0;

int AG_FindLong(const long &arr[],const long v)
  {
   for(int i=ArraySize(arr)-1; i>=0; i--)
      if(arr[i]==v)
         return i;
   return -1;
  }

//+------------------------------------------------------------------+
//| Reads every deal of one position.                                |
//| feeIn    = sum(commission+fee) of IN deals                       |
//| finalNet = sum(profit+swap+commission+fee) of all deals          |
//+------------------------------------------------------------------+
bool ReadPositionHistory(const long pid,double &feeIn,double &finalNet,bool &hasOut,long &inMagic,long &inTimeMsc)
  {
   feeIn=0.0;
   finalNet=0.0;
   hasOut=false;
   inMagic=-1;
   inTimeMsc=0;
   if(!HistorySelectByPosition(pid))
      return false;
   int n=HistoryDealsTotal();
   if(n<=0)
      return false;
   for(int i=0; i<n; i++)
     {
      ulong dt=HistoryDealGetTicket(i);
      if(dt==0)
         continue;
      long   entry=HistoryDealGetInteger(dt,DEAL_ENTRY);
      double comm =HistoryDealGetDouble(dt,DEAL_COMMISSION);
      double fee  =HistoryDealGetDouble(dt,DEAL_FEE);
      double prof =HistoryDealGetDouble(dt,DEAL_PROFIT);
      double swp  =HistoryDealGetDouble(dt,DEAL_SWAP);
      finalNet+=prof+swp+comm+fee;
      if(entry==DEAL_ENTRY_IN)
        {
         feeIn+=comm+fee;
         long tm=HistoryDealGetInteger(dt,DEAL_TIME_MSC);
         if(inMagic<0 || tm<inTimeMsc)
           {
            inMagic=HistoryDealGetInteger(dt,DEAL_MAGIC);
            inTimeMsc=tm;
           }
         double v=HistoryDealGetDouble(dt,DEAL_VOLUME);
         if(v>0.0 && tm>=g_feeRateTimeMsc)
           {
            g_feeRatePerLot=(comm+fee)/v;
            g_feeRateTimeMsc=tm;
            g_feeRateVerified=true;
           }
        }
      else
         if(entry==DEAL_ENTRY_OUT || entry==DEAL_ENTRY_OUT_BY)
            hasOut=true;
     }
   return true;
  }

bool GetFeeIn(const long pid,const double curVolume,double &fee)
  {
   int i=AG_FindLong(g_feePid,pid);
   if(i>=0 && MathAbs(g_feeVol[i]-curVolume)<1e-9)
     {
      fee=g_feeVal[i];
      return true;
     }
   double fin;
   bool out;
   long mg,tm;
   if(!ReadPositionHistory(pid,fee,fin,out,mg,tm))
      return false;
   if(i<0)
     {
      i=ArraySize(g_feePid);
      ArrayResize(g_feePid,i+1);
      ArrayResize(g_feeVal,i+1);
      ArrayResize(g_feeVol,i+1);
      g_feePid[i]=pid;
     }
   g_feeVal[i]=fee;
   g_feeVol[i]=curVolume;
   return true;
  }

bool GetOwnerMagic(const long pid,long &magic)
  {
   int i=AG_FindLong(g_ownPid,pid);
   if(i>=0)
     {
      magic=g_ownMagic[i];
      return true;
     }
   double fee,fin;
   bool out;
   long tm;
   if(!ReadPositionHistory(pid,fee,fin,out,magic,tm) || magic<0)
      return false;
   i=ArraySize(g_ownPid);
   ArrayResize(g_ownPid,i+1);
   ArrayResize(g_ownMagic,i+1);
   g_ownPid[i]=pid;
   g_ownMagic[i]=magic;
   return true;
  }

//--- fee rate per lot (<=0): observed, else input estimate (positive input => negative cost)
double FeeRatePerLot()
  {
   if(g_feeRateVerified)
      return g_feeRatePerLot;
   return -MathAbs(g_cfg.commissionPerLotEst);
  }

//+------------------------------------------------------------------+
class CBasket
  {
public:
   int                side;
   long               magic;
   ENUM_POSITION_TYPE ptype;
   ENUM_ORDER_TYPE    otype;
   //--- persisted
   int                state;
   long               basketId;
   datetime           startTime;
   double             equityAtStart;
   double             budget;
   double             effSL;
   bool               budgetVerified;
   long               lastFillTimeMsc;
   datetime           lastOrderBar;
   datetime           lastProcessedBar;
   int                closeReason;
   bool               safeMode;
   string             safeReason;
   long               pids[AG_MAX_PIDS];
   int                pidCount;
   AGIntent           intent;
   //--- runtime (rebuilt every cycle)
   AGPosInfo          pos[];
   int                count;
   double             totalVol;
   double             netOpen;
   double             lastFillPrice;
   long               lastOpenMsc;
   bool               wrongType;
   bool               historyOk;
   //--- closing trackers
   ulong              clTicket[];
   int                clAttempts[];
   long               clLastMs[];

                     CBasket() { side=AG_BUY; magic=0; ResetAll(); }

   void              Setup(const int s,const long m)
     {
      side=s;
      magic=m;
      ptype=(s==AG_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
      otype=(s==AG_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
     }

   void              ClearIntent()
     {
      intent.kind=INTENT_NONE;
      intent.status=INTENT_ST_NONE;
      intent.magic=0;
      intent.volume=0.0;
      intent.requestTimeMsc=0;
      intent.orderTicket=0;
      intent.dealTicket=0;
      intent.retcode=0;
      intent.layer=0;
     }

   void              ResetAll()
     {
      state=BS_IDLE;
      basketId=0;
      startTime=0;
      equityAtStart=0.0;
      budget=0.0;
      effSL=0.0;
      budgetVerified=false;
      lastFillTimeMsc=0;
      lastOrderBar=0;
      lastProcessedBar=0;
      closeReason=CR_NONE;
      safeMode=false;
      safeReason="";
      pidCount=0;
      for(int i=0; i<AG_MAX_PIDS; i++)
         pids[i]=0;
      ClearIntent();
      count=0;
      totalVol=0.0;
      netOpen=0.0;
      lastFillPrice=0.0;
      lastOpenMsc=0;
      wrongType=false;
      historyOk=true;
      ArrayResize(pos,0);
      ClearCloseTrackers();
     }

   //--- back to IDLE after a completed basket; keeps rate-limit memory and safe flag
   void              ClearBasket()
     {
      basketId=0;
      startTime=0;
      equityAtStart=0.0;
      budget=0.0;
      effSL=0.0;
      budgetVerified=false;
      closeReason=CR_NONE;
      pidCount=0;
      for(int i=0; i<AG_MAX_PIDS; i++)
         pids[i]=0;
      ClearCloseTrackers();
      state=safeMode ? BS_SAFE_MODE : BS_IDLE;
     }

   void              ClearCloseTrackers()
     {
      ArrayResize(clTicket,0);
      ArrayResize(clAttempts,0);
      ArrayResize(clLastMs,0);
     }

   bool              HasPid(const long pid)
     {
      for(int i=0; i<pidCount; i++)
         if(pids[i]==pid)
            return true;
      return false;
     }

   bool              AddPid(const long pid)
     {
      if(HasPid(pid))
         return true;
      if(pidCount>=AG_MAX_PIDS)
         return false;
      pids[pidCount++]=pid;
      return true;
     }

   string            PidList()
     {
      string s="";
      for(int i=0; i<pidCount; i++)
         s+=(i>0 ? ";" : "")+(string)pids[i];
      return s;
     }

   void              SetPidList(const string s)
     {
      pidCount=0;
      if(StringLen(s)==0)
         return;
      string parts[];
      int n=StringSplit(s,';',parts);
      for(int i=0; i<n && pidCount<AG_MAX_PIDS; i++)
        {
         long v=StringToInteger(parts[i]);
         if(v>0)
            pids[pidCount++]=v;
        }
     }

   //--- positions of this basket present in the terminal but not in the pid list
   int               UnlistedCount()
     {
      int c=0;
      for(int i=0; i<count; i++)
         if(!HasPid(pos[i].pid))
            c++;
      return c;
     }

   //+---------------------------------------------------------------+
   //| Rebuilds runtime view. Only symbol + magic + correct type.     |
   //| Same symbol + magic but wrong type => wrongType (never touched)|
   //+---------------------------------------------------------------+
   bool              Scan()
     {
      ArrayResize(pos,0);
      count=0;
      totalVol=0.0;
      netOpen=0.0;
      lastFillPrice=0.0;
      lastOpenMsc=0;
      wrongType=false;
      historyOk=true;
      int total=PositionsTotal();
      for(int i=0; i<total; i++)
        {
         ulong tk=PositionGetTicket(i);
         if(tk==0)
            continue;
         if(PositionGetString(POSITION_SYMBOL)!=g_spec.name)
            continue;
         if(PositionGetInteger(POSITION_MAGIC)!=magic)
            continue;
         if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)!=ptype)
           {
            wrongType=true;
            continue;
           }
         AGPosInfo p;
         p.ticket   =tk;
         p.pid      =PositionGetInteger(POSITION_IDENTIFIER);
         p.volume   =PositionGetDouble(POSITION_VOLUME);
         p.openPrice=PositionGetDouble(POSITION_PRICE_OPEN);
         p.timeMsc  =PositionGetInteger(POSITION_TIME_MSC);
         p.profit   =PositionGetDouble(POSITION_PROFIT);
         p.swap     =PositionGetDouble(POSITION_SWAP);
         p.feeIn    =0.0;
         int n=ArraySize(pos);
         ArrayResize(pos,n+1);
         pos[n]=p;
        }
      count=ArraySize(pos);
      //--- history reads after the position loop (separate selection)
      for(int k=0; k<count; k++)
        {
         double f=0.0;
         if(!GetFeeIn(pos[k].pid,pos[k].volume,f))
           {
            historyOk=false;
            f=0.0;
           }
         pos[k].feeIn=f;
         netOpen+=pos[k].profit+pos[k].swap+f;
         totalVol+=pos[k].volume;
         if(pos[k].timeMsc>lastOpenMsc)
           {
            lastOpenMsc=pos[k].timeMsc;
            lastFillPrice=pos[k].openPrice;
           }
        }
      if(lastOpenMsc>lastFillTimeMsc)
         lastFillTimeMsc=lastOpenMsc;
      return historyOk;
     }

   double            FeeOutEstimate(const double vol) { return FeeRatePerLot()*vol; }
   double            NetAfterExit()                    { return netOpen+FeeOutEstimate(totalVol); }

   void              SetState(const int st,const string why)
     {
      if(st==state)
         return;
      g_log.Event("STATE_"+BasketStateText(state)+"_TO_"+BasketStateText(st),side,magic,basketId,count,totalVol,netOpen,budget,0.0,0,why);
      state=st;
     }

   void              EnterSafe(const string why)
     {
      if(!safeMode)
         g_log.Event("SAFE_MODE_ENTER",side,magic,basketId,count,totalVol,netOpen,budget,0.0,0,why);
      safeMode=true;
      safeReason=why;
      if(state!=BS_CLOSING)
         SetState(BS_SAFE_MODE,why);
     }

   bool              HasIntent() { return intent.kind!=INTENT_NONE; }

   //--- close tracker index for a ticket (creates when missing)
   int               TrackerIndex(const ulong tk)
     {
      int n=ArraySize(clTicket);
      for(int i=0; i<n; i++)
         if(clTicket[i]==tk)
            return i;
      ArrayResize(clTicket,n+1);
      ArrayResize(clAttempts,n+1);
      ArrayResize(clLastMs,n+1);
      clTicket[n]=tk;
      clAttempts[n]=0;
      clLastMs[n]=0;
      return n;
     }
  };

CBasket g_basket[AG_SIDES];

#endif
//+------------------------------------------------------------------+
