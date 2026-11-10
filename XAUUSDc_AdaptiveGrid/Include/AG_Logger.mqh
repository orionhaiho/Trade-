//+------------------------------------------------------------------+
//| AG_Logger.mqh                                                    |
//| CSV event log + journal. Reject lines throttled per side/bar.    |
//+------------------------------------------------------------------+
#ifndef AG_LOGGER_MQH
#define AG_LOGGER_MQH

#include "AG_Types.mqh"

class CAGLogger
  {
private:
   int               m_handle;
   bool              m_csv;
   bool              m_journal;
   bool              m_tester;
   string            m_symbol;
   double            m_point;
   int               m_digits;
   datetime          m_rejBar[AG_SIDES];
   string            m_rejKeys[AG_SIDES];

   string            Clean(string s)
     {
      StringReplace(s,","," ");
      StringReplace(s,"\r"," ");
      StringReplace(s,"\n"," ");
      return s;
     }
   string            D(const double v,const int digits)
     {
      if(!MathIsValidNumber(v))
         return "NaN";
      return DoubleToString(v,digits);
     }

public:
   double            ctxBid;
   double            ctxAsk;
   double            ctxATR;
   double            ctxADX;
   double            ctxRSI;
   double            ctxBBUp;
   double            ctxBBLo;
   double            ctxGrid;
   datetime          ctxBar;

                     CAGLogger()
     {
      m_handle=INVALID_HANDLE;
      m_csv=false;
      m_journal=true;
      m_tester=false;
      m_point=0.0;
      m_digits=2;
      ctxBid=0;
      ctxAsk=0;
      ctxATR=0;
      ctxADX=0;
      ctxRSI=0;
      ctxBBUp=0;
      ctxBBLo=0;
      ctxGrid=0;
      ctxBar=0;
      for(int i=0; i<AG_SIDES; i++)
        {
         m_rejBar[i]=0;
         m_rejKeys[i]="|";
        }
     }

   bool              Init(const string symbol,const double point,const int digits,const bool csv,const bool journal,const bool tester)
     {
      m_symbol=symbol;
      m_point=point;
      m_digits=digits;
      m_csv=csv;
      m_journal=journal;
      m_tester=tester;
      if(!m_csv)
         return true;
      string name="AdaptiveGrid\\AG_Log_"+symbol+"_"+(string)AccountInfoInteger(ACCOUNT_LOGIN)+(tester ? "_TESTER" : "")+".csv";
      if(tester && FileIsExist(name))
         FileDelete(name);
      m_handle=FileOpen(name,FILE_READ|FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_SHARE_READ);
      if(m_handle==INVALID_HANDLE)
        {
         Print("[AG] CSV log open failed: ",name," err=",GetLastError());
         m_csv=false;
         return false;
        }
      if(FileSize(m_handle)==0)
         FileWriteString(m_handle,"server_time,event,symbol,magic,basket_id,side,bar_time,bid,ask,spread,spread_points,atr,adx,rsi,bb_upper,bb_lower,layers,volume,grid_distance,basket_pl,risk_budget,stress_risk,retcode,reason\r\n");
      FileSeek(m_handle,0,SEEK_END);
      return true;
     }

   void              Deinit()
     {
      if(m_handle!=INVALID_HANDLE)
        {
         FileFlush(m_handle);
         FileClose(m_handle);
         m_handle=INVALID_HANDLE;
        }
     }

   void              Event(const string event,const int side,const long magic,const long basketId,
                           const int layers,const double volume,const double basketPL,const double budget,
                           const double stress,const uint retcode,const string reason)
     {
      double spread=(ctxAsk>0 && ctxBid>0) ? ctxAsk-ctxBid : 0.0;
      double sprPts=(m_point>0) ? spread/m_point : 0.0;
      if(m_journal || StringFind(event,"LOCK")>=0 || StringFind(event,"SAFE")>=0 || StringFind(event,"FAIL")>=0
         || StringFind(event,"OPEN")>=0 || StringFind(event,"CLOSE")>=0 || StringFind(event,"INIT")>=0)
         PrintFormat("[AG] %s side=%s magic=%I64d basket=%I64d layers=%d vol=%s pl=%s budget=%s stress=%s rc=%u | %s",
                     event,SideText(side),magic,basketId,layers,D(volume,2),D(basketPL,2),D(budget,4),D(stress,4),retcode,reason);
      if(!m_csv || m_handle==INVALID_HANDLE)
         return;
      string line=TimeToString(TimeTradeServer(),TIME_DATE|TIME_SECONDS)+","+Clean(event)+","+m_symbol+","+(string)magic+","
                  +(string)basketId+","+SideText(side)+","+(ctxBar>0 ? TimeToString(ctxBar,TIME_DATE|TIME_MINUTES) : "")+","
                  +D(ctxBid,m_digits)+","+D(ctxAsk,m_digits)+","+D(spread,m_digits)+","+D(sprPts,0)+","
                  +D(ctxATR,m_digits)+","+D(ctxADX,2)+","+D(ctxRSI,2)+","+D(ctxBBUp,m_digits)+","+D(ctxBBLo,m_digits)+","
                  +(string)layers+","+D(volume,2)+","+D(ctxGrid,m_digits)+","+D(basketPL,4)+","+D(budget,4)+","+D(stress,4)+","
                  +(string)retcode+","+Clean(reason);
      FileWriteString(m_handle,line+"\r\n");
      if(!m_tester)
         FileFlush(m_handle);
     }

   //--- throttle: one line per (side, reason) per M1 bar
   bool              ShouldLogReject(const int side,const string reason,const datetime bar)
     {
      if(side<0 || side>=AG_SIDES)
         return true;
      if(bar!=m_rejBar[side])
        {
         m_rejBar[side]=bar;
         m_rejKeys[side]="|";
        }
      string key="|"+reason+"|";
      if(StringFind(m_rejKeys[side],key)>=0)
         return false;
      m_rejKeys[side]+=reason+"|";
      return true;
     }

   void              Info(const string msg)
     {
      if(m_journal)
         Print("[AG] ",msg);
     }

   void              Warn(const string msg)
     {
      Print("[AG][WARN] ",msg);
     }
  };

CAGLogger g_log;

#endif
//+------------------------------------------------------------------+
