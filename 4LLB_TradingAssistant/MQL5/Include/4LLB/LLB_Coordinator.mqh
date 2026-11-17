//+------------------------------------------------------------------+
//| LLB_Coordinator.mqh                                              |
//| Coordinator: one instance drives every configured symbol         |
//| (R-CRD-01), schedules the timer cycle, owns the managers, runs   |
//| startup recovery (Phase 2 §8) and implements the services used   |
//| by the ApprovalManager.                                          |
//+------------------------------------------------------------------+
#ifndef LLB_COORDINATOR_MQH
#define LLB_COORDINATOR_MQH

#include "LLB_Defines.mqh"
#include "LLB_Utils.mqh"
#include "LLB_Logger.mqh"
#include "LLB_Json.mqh"
#include "LLB_MarketData.mqh"
#include "LLB_Levels.mqh"
#include "LLB_StopLoss.mqh"
#include "LLB_Strategy.mqh"
#include "LLB_Persistence.mqh"
#include "LLB_Proposals.mqh"
#include "LLB_Risk.mqh"
#include "LLB_Execution.mqh"
#include "LLB_Positions.mqh"
#include "LLB_Telegram.mqh"
#include "LLB_Approval.mqh"
#include "LLB_Dashboard.mqh"
#include "LLB_Lock.mqh"
#include "LLB_Messages.mqh"

struct LLBConfig
  {
   string            symbols;
   ENUM_TIMEFRAMES   atrTf;
   int               nearestMode;
   int               swingRefMode;
   int               lookback;
   bool              enableSweep;
   bool              enableBreakout;
   int               maxStartupBarAgeSec;
   int               lotMode;
   double            lotSize;
   double            riskPct;
   int               riskBase;
   double            dailyLossLimit;
   long              magic;
   int               closeDeviation;
   bool              allowEaExpiry;
   bool              tgEnabled;
   string            tgToken;
   long              tgChatId;
   string            tgAllowed;
   int               tgPollMs;
   int               tgTimeoutMs;
   bool              showDashboard;
   int               dashPos;
   bool              dashCollapsed;
   int               logLevel;
   bool              logToFile;
   bool              testerAutoApprove;
  };

struct LLBSymbolContext
  {
   string            name;
   bool              enabled;
   string            status;
   LLBSymbolSpec     spec;
   int               atrHandle;
   datetime          lastBarOpen;
   datetime          lastEvaluatedBar;
   datetime          pendingBar;
   long              pendingSinceMs;
   long              lastScanMsc;
   long              savedScanMsc;
   long              restartFloorMsc;
   bool              lastScanFailed;
   bool              scanWarned;
   LLBLevels         levels;
   double            atr;
   string            dataStatus;
   double            bid;
   double            ask;
   int               spreadPts;
   void              Reset(void)
     {
      name="";
      enabled=false;
      status="";
      spec.Reset();
      atrHandle=INVALID_HANDLE;
      lastBarOpen=0;
      lastEvaluatedBar=0;
      pendingBar=0;
      pendingSinceMs=0;
      lastScanMsc=0;
      savedScanMsc=0;
      restartFloorMsc=0;
      lastScanFailed=false;
      scanWarned=false;
      levels.Reset();
      atr=0.0;
      dataStatus="waiting for data";
      bid=0.0;
      ask=0.0;
      spreadPts=0;
     }
  };

//+------------------------------------------------------------------+
class CLLBCoordinator : public CLLBApprovalServices
  {
private:
   LLBConfig            m_cfg;
   bool                 m_tester;
   bool                 m_netting;
   bool                 m_initOk;
   string               m_dataDir;
   string               m_instanceId;
   LLBSymbolContext     m_sym[];
   CLLBMarketData       m_md;
   CLLBPersistence      m_per;
   CLLBProposalManager  m_pm;
   CLLBRisk             m_risk;
   CLLBExecutionManager m_em;
   CLLBPositionManager  m_pos;
   CLLBTelegramGateway  m_tg;
   CLLBApprovalManager  m_apr;
   CLLBDashboard        m_dash;
   CLLBFileLock         m_lockCoord;
   CLLBFileLock         m_lockTg;
   bool                 m_lockLost;
   bool                 m_recoveryDone;
   bool                 m_wasConnected;
   long                 m_connectedSinceMs;
   long                 m_disconnectedSinceMs;
   bool                 m_reconcileFlag;
   long                 m_lastReconcileMs;
   long                 m_lastDashMs;
   long                 m_lastStateSaveMs;
   long                 m_lastHeartbeatMs;
   bool                 m_stateDirty;
   int                  m_lastDay;
   long                 m_loadedOffset;

   long              NowMs(void) { return LLB_NowMs(); }

   bool              IsConnected(void)
     {
      if(m_tester)
         return true;
      return (bool)TerminalInfoInteger(TERMINAL_CONNECTED);
     }

   int               SymIndex(const string name)
     {
      for(int i=0; i<ArraySize(m_sym); i++)
         if(m_sym[i].name==name)
            return i;
      return -1;
     }

   void              Fatal(const string msg)
     {
      g_llbLog.Error("INIT",msg);
      if(!m_tester)
         Alert("4LLB: "+msg);
     }

   bool              ValidateInputs(string &err)
     {
      if(LLB_Trim(m_cfg.symbols)=="")
        { err="InpSymbols is empty"; return false; }
      if(m_cfg.atrTf==PERIOD_CURRENT)
        { err="InpAtrTimeframe must be an explicit timeframe (decision D-03: M15)"; return false; }
      if(m_cfg.lookback<20 || m_cfg.lookback>10000)
        { err="InpSwingLookbackBars must be within [20,10000]"; return false; }
      if(m_cfg.magic<=0)
        { err="InpMagicNumber must be > 0"; return false; }
      if(m_cfg.closeDeviation<0)
        { err="InpCloseDeviationPoints must be >= 0"; return false; }
      if(m_cfg.maxStartupBarAgeSec<0 || m_cfg.maxStartupBarAgeSec>LLB_M15_SECONDS)
        { err="InpMaxStartupBarAgeSec must be within [0,900]"; return false; }
      if(!m_cfg.enableSweep && !m_cfg.enableBreakout)
        { err="Both strategies are disabled"; return false; }
      if(m_cfg.testerAutoApprove && !m_tester)
        { err="InpTesterAutoApprove=true is only allowed in the Strategy Tester (live trading needs a Telegram ACCEPT)"; return false; }
      if(!m_risk.ValidateConfig(err))
         return false;
      return true;
     }

   bool              InitSymbols(string &err)
     {
      ArrayResize(m_sym,0);
      string parts[];
      int n=StringSplit(m_cfg.symbols,(ushort)',',parts);
      int enabled=0;
      for(int i=0; i<n; i++)
        {
         string name=LLB_Trim(parts[i]);
         if(name=="" || SymIndex(name)>=0)
            continue;
         if(ArraySize(m_sym)>=LLB_MAX_SYMBOLS)
           {
            g_llbLog.Warn("CRD","more than "+(string)LLB_MAX_SYMBOLS+" symbols - '"+name+"' ignored");
            continue;
           }
         int k=ArraySize(m_sym);
         ArrayResize(m_sym,k+1);
         m_sym[k].Reset();
         m_sym[k].name=name;
         string e2;
         if(!m_md.LoadSpec(name,m_sym[k].spec,e2))
           {
            m_sym[k].status="DISABLED: "+e2;
            g_llbLog.Warn("CRD",name+" disabled - "+e2+" (XAUUSD and XAUUSDc usually belong to different Exness account types)");
            continue;
           }
         m_sym[k].atrHandle=iATR(name,m_cfg.atrTf,LLB_ATR_PERIOD);
         if(m_sym[k].atrHandle==INVALID_HANDLE)
           {
            m_sym[k].status="DISABLED: iATR handle failed err="+(string)GetLastError();
            g_llbLog.Warn("CRD",name+" "+m_sym[k].status);
            continue;
           }
         m_sym[k].enabled=true;
         m_sym[k].status="OK";
         enabled++;
         g_llbLog.Info("CRD","SYMBOL "+m_md.SpecText(m_sym[k].spec));
        }
      if(enabled==0)
        {
         err="none of the symbols in InpSymbols ("+m_cfg.symbols+") is available on this account";
         return false;
        }
      return true;
     }

   //--- state file + journals
   void              LoadAll(void)
     {
      datetime now=TimeTradeServer();
      string keys[],vals[],why;
      int rc=m_per.LoadState(keys,vals,why);
      m_loadedOffset=0;
      if(rc==LLB_LOAD_OK)
        {
         string login=LLB_KV(keys,vals,"login","");
         string magic=LLB_KV(keys,vals,"magic","");
         string schema=LLB_KV(keys,vals,"schema","");
         bool ident=(schema==IntegerToString(LLB_STATE_SCHEMA) && magic==IntegerToString(m_cfg.magic)
                     && (m_tester || login==IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN))));
         if(!ident)
            g_llbLog.Warn("PER","system_state.dat identity mismatch (schema/login/magic) - ignored");
         else
           {
            m_loadedOffset=StringToInteger(LLB_KV(keys,vals,"tg_offset","0"));
            m_pm.SetSequence((int)StringToInteger(LLB_KV(keys,vals,"seq_date","0")),(int)StringToInteger(LLB_KV(keys,vals,"seq_value","0")));
            int cnt=(int)StringToInteger(LLB_KV(keys,vals,"sym_count","0"));
            for(int i=0; i<cnt; i++)
              {
               string p="sym"+IntegerToString(i)+"_";
               int s=SymIndex(LLB_KV(keys,vals,p+"name",""));
               if(s<0)
                  continue;
               m_sym[s].lastEvaluatedBar=(datetime)StringToInteger(LLB_KV(keys,vals,p+"last_eval_bar","0"));
               m_sym[s].lastScanMsc=StringToInteger(LLB_KV(keys,vals,p+"last_scan_msc","0"));
               m_sym[s].savedScanMsc=m_sym[s].lastScanMsc;
              }
            g_llbLog.Info("PER","state loaded (saved "+LLB_KV(keys,vals,"saved","?")+")");
           }
        }
      else
         if(rc==LLB_LOAD_MISSING)
            g_llbLog.Info("PER","no system_state.dat - fresh start");
         else
            g_llbLog.Warn("PER","system_state.dat unusable: "+why+" - rebuilding from journals and broker history");
      int c1=0,c2=0,c3=0;
      string e;
      m_pm.Load(now,c1,e);
      m_em.Load(now,c2,e);
      m_pos.Load(now,c3,e);
      g_llbLog.Info("PER",StringFormat("journals loaded: %d proposals, %d executions, %d positions in memory",m_pm.Count(),m_em.Count(),m_pos.Count()));
      if(c1+c2+c3>0)
         g_llbLog.Warn("PER",StringFormat("corrupt/partial journal lines skipped: signals=%d executions=%d positions=%d (broker reconciliation will repair states)",c1,c2,c3));
     }

   void              SaveState(void)
     {
      string c="";
      c+="schema="+IntegerToString(LLB_STATE_SCHEMA)+"\n";
      c+="version="+LLB_VERSION+"\n";
      c+="login="+IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN))+"\n";
      c+="server="+LLB_CsvClean(AccountInfoString(ACCOUNT_SERVER))+"\n";
      c+="magic="+IntegerToString(m_cfg.magic)+"\n";
      c+="saved="+LLB_TS(TimeTradeServer())+"\n";
      c+="tg_offset="+IntegerToString(MathMax(m_tg.Offset(),m_loadedOffset))+"\n";
      c+="seq_date="+IntegerToString(m_pm.SeqDate())+"\n";
      c+="seq_value="+IntegerToString(m_pm.SeqValue())+"\n";
      c+="sym_count="+IntegerToString(ArraySize(m_sym))+"\n";
      for(int s=0; s<ArraySize(m_sym); s++)
        {
         string p="sym"+IntegerToString(s)+"_";
         c+=p+"name="+m_sym[s].name+"\n";
         c+=p+"last_eval_bar="+IntegerToString((long)m_sym[s].lastEvaluatedBar)+"\n";
         c+=p+"last_scan_msc="+IntegerToString(m_sym[s].lastScanMsc)+"\n";
        }
      if(m_per.SaveState(c))
        {
         m_stateDirty=false;
         m_lastStateSaveMs=NowMs();
         for(int s=0; s<ArraySize(m_sym); s++)
            m_sym[s].savedScanMsc=m_sym[s].lastScanMsc;
        }
     }

   void              RefreshQuote(const int s)
     {
      MqlTick t;
      if(!m_md.GetTick(m_sym[s].name,t))
         return;
      m_sym[s].bid=t.bid;
      m_sym[s].ask=t.ask;
      m_sym[s].spreadPts=(m_sym[s].spec.point>0.0) ? (int)MathRound((t.ask-t.bid)/m_sym[s].spec.point) : 0;
     }

   long              ItemFrom(const long checked,const long monitorFrom,const long floorMsc)
     {
      if(checked>0)
         return checked;
      return MathMax(monitorFrom,floorMsc);
     }

   string            TouchText(const int dir,const double px,const double ref,const long msc,const int digits)
     {
      return StringFormat("TOUCH %s %s %s swing %s at %s.%03d (server)",(dir==LLB_DIR_BUY) ? "Bid" : "Ask",DoubleToString(px,digits),
                          (dir==LLB_DIR_BUY) ? "<=" : ">=",DoubleToString(ref,digits),
                          TimeToString((datetime)(msc/1000),TIME_DATE|TIME_SECONDS),(int)(msc%1000));
     }

   //+------------------------------------------------------------------+
   //| Touch invalidation scan of one symbol (SRS 4.5, A-06, A-21)      |
   //| Proposals ACTIVE -> INVALIDATED; live pending order -> delete;   |
   //| open position -> close. Each item is checked from its own        |
   //| watermark so no tick between two scans is ever skipped.          |
   //+------------------------------------------------------------------+
   void              ScanSymbol(const int s,const bool startup)
     {
      string sym=m_sym[s].name;
      double tick=m_sym[s].spec.tickSize;
      int digits=m_sym[s].spec.digits;
      long floorMsc=m_sym[s].restartFloorMsc;
      long from=0;
      bool any=false;
      for(int i=0; i<m_pm.Count(); i++)
        {
         if(m_pm.items[i].symbol!=sym || m_pm.items[i].state!=LLB_PS_ACTIVE || m_pm.items[i].refSwingPrice<=0.0)
            continue;
         long f=(m_pm.items[i].checkedMsc>0) ? m_pm.items[i].checkedMsc : m_pm.items[i].monitorFromMsc;
         if(!any || f<from)
            from=f;
         any=true;
        }
      for(int i=0; i<m_em.Count(); i++)
        {
         if(m_em.items[i].symbol!=sym || !m_em.IsLivePending(i) || m_em.items[i].structState!=LLB_ST_INTACT || m_em.items[i].refSwingPrice<=0.0)
            continue;
         long f=ItemFrom(m_em.items[i].checkedMsc,m_em.items[i].monitorFromMsc,floorMsc);
         if(!any || f<from)
            from=f;
         any=true;
        }
      for(int i=0; i<m_pos.Count(); i++)
        {
         if(m_pos.items[i].symbol!=sym || m_pos.items[i].state!=LLB_POS_OPEN || m_pos.items[i].structState!=LLB_ST_INTACT
            || m_pos.items[i].ownership!=LLB_OWN_OK || m_pos.items[i].refSwingPrice<=0.0)
            continue;
         long f=ItemFrom(m_pos.items[i].checkedMsc,m_pos.items[i].monitorFromMsc,floorMsc);
         if(!any || f<from)
            from=f;
         any=true;
        }
      MqlTick cur;
      bool curOk=m_md.GetTick(sym,cur);
      if(!any)
        {
         if(curOk && cur.time_msc>m_sym[s].lastScanMsc)
            m_sym[s].lastScanMsc=cur.time_msc;
         m_sym[s].lastScanFailed=false;
         return;
        }
      long nowMsc=(long)TimeTradeServer()*1000;
      if(from<nowMsc-LLB_MAX_DOWNTIME_SCAN_MS)
         from=nowMsc-LLB_MAX_DOWNTIME_SCAN_MS;
      MqlTick ticks[];
      int err=0;
      int n=m_md.TicksFrom(sym,from,ticks,err);
      bool failed=(n<0);
      m_sym[s].lastScanFailed=failed;
      if(failed)
        {
         if(!m_sym[s].scanWarned)
           {
            g_llbLog.Warn("CRD",sym+" CopyTicksRange failed err="+(string)err+" - falling back to the current quote");
            m_sym[s].scanWarned=true;
           }
         n=0;
        }
      long lastMsc=(n>0) ? ticks[n-1].time_msc : 0;
      long tMsc=0;
      double tPx=0.0;
      //--- proposals
      for(int i=0; i<m_pm.Count(); i++)
        {
         if(m_pm.items[i].symbol!=sym || m_pm.items[i].state!=LLB_PS_ACTIVE || m_pm.items[i].refSwingPrice<=0.0)
            continue;
         int dir=m_pm.items[i].direction;
         double ref=m_pm.items[i].refSwingPrice;
         long f=(m_pm.items[i].checkedMsc>0) ? m_pm.items[i].checkedMsc : m_pm.items[i].monitorFromMsc;
         bool touched=LLB_FindTouch(ticks,n,dir,ref,f,tick,tMsc,tPx);
         if(!touched && curOk && cur.time_msc>=f && LLB_QuoteTouches(dir,ref,cur.bid,cur.ask,tick))
           {
            touched=true;
            tMsc=cur.time_msc;
            tPx=(dir==LLB_DIR_BUY) ? cur.bid : cur.ask;
           }
         if(touched)
           {
            m_pm.Transition(i,LLB_PS_INVALIDATED,TouchText(dir,tPx,ref,tMsc,digits));
            continue;
           }
         if(failed && startup)
           {
            m_pm.Transition(i,LLB_PS_INVALIDATED,"DOWNTIME_UNVERIFIABLE: tick history unavailable after restart (fail-safe)");
            continue;
           }
         if(lastMsc>f)
            m_pm.SetChecked(i,lastMsc);
        }
      //--- live pending orders (accepted, not filled yet)
      for(int i=0; i<m_em.Count(); i++)
        {
         if(m_em.items[i].symbol!=sym || !m_em.IsLivePending(i) || m_em.items[i].structState!=LLB_ST_INTACT || m_em.items[i].refSwingPrice<=0.0)
            continue;
         int dir=m_em.items[i].direction;
         double ref=m_em.items[i].refSwingPrice;
         long f=ItemFrom(m_em.items[i].checkedMsc,m_em.items[i].monitorFromMsc,floorMsc);
         bool touched=LLB_FindTouch(ticks,n,dir,ref,f,tick,tMsc,tPx);
         if(!touched && curOk && cur.time_msc>=f && LLB_QuoteTouches(dir,ref,cur.bid,cur.ask,tick))
           {
            touched=true;
            tMsc=cur.time_msc;
            tPx=(dir==LLB_DIR_BUY) ? cur.bid : cur.ask;
           }
         if(touched)
           {
            string why=TouchText(dir,tPx,ref,tMsc,digits);
            m_em.SetStructInvalid(i,why);
            string msg;
            bool ok=m_em.DeleteOrder(i,"STRUCTURE_INVALIDATION",m_sym[s].spec,msg);
            Notify(LLB_IconStop()+" STRUCTURE INVALIDATED before fill "+m_em.items[i].signalId+"\n"+why+"\n"
                   +(ok ? "Pending order delete requested." : "Delete not done yet ("+msg+") - retrying; if it fills it will be closed."));
            continue;
           }
         if(lastMsc>f)
            m_em.items[i].checkedMsc=lastMsc;
        }
      //--- open positions
      for(int i=0; i<m_pos.Count(); i++)
        {
         if(m_pos.items[i].symbol!=sym || m_pos.items[i].state!=LLB_POS_OPEN || m_pos.items[i].structState!=LLB_ST_INTACT
            || m_pos.items[i].ownership!=LLB_OWN_OK || m_pos.items[i].refSwingPrice<=0.0)
            continue;
         int dir=m_pos.items[i].direction;
         double ref=m_pos.items[i].refSwingPrice;
         long f=ItemFrom(m_pos.items[i].checkedMsc,m_pos.items[i].monitorFromMsc,floorMsc);
         bool touched=LLB_FindTouch(ticks,n,dir,ref,f,tick,tMsc,tPx);
         if(!touched && curOk && cur.time_msc>=f && LLB_QuoteTouches(dir,ref,cur.bid,cur.ask,tick))
           {
            touched=true;
            tMsc=cur.time_msc;
            tPx=(dir==LLB_DIR_BUY) ? cur.bid : cur.ask;
           }
         if(touched)
           {
            string why=TouchText(dir,tPx,ref,tMsc,digits);
            m_pos.MarkStructureInvalid(i,why);
            Notify(LLB_IconStop()+" STRUCTURE INVALIDATED after fill "+m_pos.items[i].signalId+" position #"+IntegerToString(m_pos.items[i].positionId)
                   +"\n"+why+"\nRequesting close (broker SL stays active).");
            if(IsConnected() && !m_lockLost)
              {
               LLBExecEvent ev[];
               m_pos.ProcessActions(i,m_sym[s].spec,ev);
               for(int k=0; k<ArraySize(ev); k++)
                  Notify(LLB_IconInfo()+" "+ev[k].text);
              }
            continue;
           }
         if(lastMsc>f)
            m_pos.items[i].checkedMsc=lastMsc;
        }
      long newest=lastMsc;
      if(curOk && cur.time_msc>newest)
         newest=cur.time_msc;
      if(newest>m_sym[s].lastScanMsc)
         m_sym[s].lastScanMsc=newest;
      if(m_sym[s].lastScanMsc-m_sym[s].savedScanMsc>=10000)
         m_stateDirty=true;
     }

   //+------------------------------------------------------------------+
   //| Strategy evaluation of the last closed M15 bar.                  |
   //| Returns 1 when evaluated, 0 when data is not ready (retry).      |
   //+------------------------------------------------------------------+
   int               EvaluateBar(const int s,const datetime now,const bool allowSignals,const datetime expectedBar)
     {
      string sym=m_sym[s].name;
      int need=m_cfg.lookback+LLB_PIVOT_LEFT+LLB_PIVOT_RIGHT+LLB_RETEST_MAX_BARS+12;
      MqlRates r[];
      int n=m_md.CopyM15(sym,need,r);
      int minBars=LLB_RETEST_MAX_BARS+LLB_PIVOT_LEFT+LLB_PIVOT_RIGHT+10;
      if(n<minBars)
        {
         m_sym[s].dataStatus="M15 history not ready ("+IntegerToString(n)+" bars)";
         return 0;
        }
      if(expectedBar>0 && r[1].time!=expectedBar)
        {
         m_sym[s].dataStatus="bar series moved during evaluation - retry";
         return 0;                                       // a new bar opened between iTime() and CopyRates()
        }
      int maxIdx=LLB_RETEST_MAX_BARS+2;
      double atrAt[];
      ArrayResize(atrAt,maxIdx+1);
      ArrayInitialize(atrAt,0.0);
      string why="";
      for(int i=1; i<=maxIdx && i<n; i++)
        {
         double a=0.0;
         if(m_md.AtrAt(m_sym[s].atrHandle,sym,m_cfg.atrTf,r[i].time,i,a,why))
            atrAt[i]=a;
         else
            if(i==1)
              {
               m_sym[s].dataStatus=why;
               return 0;
              }
        }
      LLBLevels lvAt[];
      ArrayResize(lvAt,maxIdx+1);
      for(int i=0; i<=maxIdx; i++)
         lvAt[i].Reset();
      for(int i=1; i<=LLB_RETEST_MAX_BARS+1 && i<n; i++)
        {
         double pdh=0.0,pdl=0.0;
         datetime d1t=0;
         if(!m_md.PrevDayHL(sym,r[i].time,pdh,pdl,d1t,why))
           {
            if(i==1)
              {
               m_sym[s].dataStatus=why;
               return 0;
              }
            continue;
           }
         LLB_ComputeLevels(r,n,i,pdh,pdl,d1t,m_cfg.lookback,m_cfg.nearestMode,lvAt[i]);
        }
      m_sym[s].levels=lvAt[1];
      m_sym[s].atr=atrAt[1];
      m_sym[s].dataStatus=lvAt[1].valid ? "OK" : "levels "+lvAt[1].why;
      if(!allowSignals)
         return 1;
      double tick=m_sym[s].spec.tickSize;
      int digits=m_sym[s].spec.digits;
      if(m_cfg.enableSweep)
        {
         LLBSignalCandidate c;
         why="";
         if(LLB_DetectSweep(r,n,1,lvAt[1],atrAt[1],tick,digits,m_cfg.swingRefMode,m_cfg.nearestMode,m_cfg.lookback,sym,c,why))
            HandleCandidate(s,c,now);
         else
            if(why!="")
               g_llbLog.Info("STR",sym+" sweep setup without usable reference swing: "+why);
        }
      if(m_cfg.enableBreakout)
        {
         LLBSignalCandidate c2;
         why="";
         if(LLB_DetectBreakout(r,n,1,lvAt,atrAt,tick,digits,m_cfg.swingRefMode,m_cfg.nearestMode,m_cfg.lookback,sym,c2,why))
            HandleCandidate(s,c2,now);
         else
            if(why!="")
               g_llbLog.Info("STR",sym+" breakout setup without usable reference swing: "+why);
        }
      g_llbLog.Debug("STR",StringFormat("%s bar %s evaluated: ATR=%s P1=%s P2=%s P3=%s P4=%s (%s)",sym,TimeToString(r[1].time),
                                       DoubleToString(atrAt[1],digits),DoubleToString(lvAt[1].pdh,digits),DoubleToString(lvAt[1].pdl,digits),
                                       DoubleToString(lvAt[1].p3,digits),DoubleToString(lvAt[1].p4,digits),lvAt[1].why));
      return 1;
     }

   void              HandleCandidate(const int s,const LLBSignalCandidate &c,const datetime now)
     {
      double sl=0.0,tp=0.0,rr=0.0,buf=0.0;
      string why;
      LLBSymbolSpec spec=m_sym[s].spec;
      if(!LLB_ComputeStops(c.direction,c.entry,c.refSwingPrice,c.atr,spec.tickSize,spec.digits,sl,tp,rr,buf,why))
        {
         g_llbLog.Info("SLC","candidate discarded "+c.symbol+" "+LLB_StrategyName(c.strategy)+" "+LLB_DirName(c.direction)+": "+why);
         return;
        }
      MqlTick tk;
      ZeroMemory(tk);
      m_md.GetTick(c.symbol,tk);
      int pidx=m_pm.Create(c,sl,tp,rr,tk,spec.point,spec.digits,now,why);
      if(pidx<0)
        {
         g_llbLog.Info("PRP","no proposal for "+c.symbol+" "+LLB_StrategyName(c.strategy)+" "+LLB_DirName(c.direction)+": "+why);
         return;
        }
      m_stateDirty=true;
      LLBTradeProposal p=m_pm.items[pidx];
      g_llbLog.Info("PRP",StringFormat("PROPOSAL_CREATED %s entry=%s sl=%s tp=%s rr=%.2f ref=%s expires=%s | %s",p.signalId,
                                       DoubleToString(p.entry,p.digits),DoubleToString(p.sl,p.digits),DoubleToString(p.tp,p.digits),p.rr,
                                       DoubleToString(p.refSwingPrice,p.digits),LLB_TimeStr(p.expiresTime),p.reason));
      if(m_tg.Enabled())
         m_tg.QueueProposal(p.signalId,LLB_FormatProposal(p,m_cfg.atrTf));
      if(m_tester && m_cfg.testerAutoApprove)
        {
         bool alert=false;
         string ans=m_apr.ProcessDecision(pidx,LLB_DEC_ACCEPT,0,now,alert);
         g_llbLog.Info("APR","TESTER_AUTO_APPROVE "+p.signalId+": "+ans);
        }
     }

   void              CheckNewBar(const int s,const datetime now)
     {
      string sym=m_sym[s].name;
      datetime t0=iTime(sym,PERIOD_M15,0);
      if(t0<=0 || t0==m_sym[s].lastBarOpen)
         return;
      datetime closed=iTime(sym,PERIOD_M15,1);
      if(closed<=0)
         return;
      if(closed<=m_sym[s].lastEvaluatedBar)
        {
         if(m_sym[s].lastBarOpen==0)
            EvaluateBar(s,now,false,0);              // dashboard levels after a restart
         m_sym[s].lastBarOpen=t0;
         return;
        }
      //--- first bar seen after start-up: only a bar that closed moments ago may create signals (A-22)
      if(m_sym[s].lastBarOpen==0)
        {
         long age=(long)now-((long)closed+LLB_M15_SECONDS);
         if(age>m_cfg.maxStartupBarAgeSec)
           {
            g_llbLog.Info("CRD",StringFormat("%s start-up: bar %s closed %I64d s ago - not evaluated for signals (no stale proposals)",
                                             sym,TimeToString(closed),age));
            EvaluateBar(s,now,false,0);
            m_sym[s].lastEvaluatedBar=closed;
            m_sym[s].lastBarOpen=t0;
            m_stateDirty=true;
            return;
           }
        }
      if(m_sym[s].pendingBar!=closed)
        {
         m_sym[s].pendingBar=closed;
         m_sym[s].pendingSinceMs=NowMs();
        }
      int r=EvaluateBar(s,now,true,closed);
      if(r==0)
        {
         if(NowMs()-m_sym[s].pendingSinceMs<LLB_DATA_RETRY_LIMIT_MS)
            return;                                      // data not ready: retry next cycle
         g_llbLog.Warn("CRD",sym+" bar "+TimeToString(closed)+" skipped: data not ready for 60 s ("+m_sym[s].dataStatus+")");
        }
      m_sym[s].lastEvaluatedBar=closed;
      m_sym[s].lastBarOpen=t0;
      m_stateDirty=true;
     }

   string            ExecEventText(const LLBExecEvent &ev)
     {
      string sid=(ev.index>=0 && ev.index<m_em.Count()) ? m_em.items[ev.index].signalId : "?";
      switch(ev.type)
        {
         case LLB_EV_PLACED:
            return LLB_IconOk()+" ORDER CONFIRMED "+sid+": "+ev.text;
         case LLB_EV_FAILED:
            return LLB_IconNo()+" EXECUTION FAILED "+sid+": "+ev.text;
         case LLB_EV_EXPIRED:
            return LLB_IconClock()+" PENDING ORDER EXPIRED (not filled) "+sid+": "+ev.text;
         case LLB_EV_CANCELLED:
            return LLB_IconStop()+" PENDING ORDER CANCELLED "+sid+": "+ev.text;
         case LLB_EV_REJECTED:
            return LLB_IconNo()+" PENDING ORDER REJECTED BY SERVER "+sid+": "+ev.text;
         case LLB_EV_ORPHAN:
            return LLB_IconWarn()+" RECONCILIATION "+sid+": "+ev.text;
        }
      return LLB_IconInfo()+" "+sid+": "+ev.text;
     }

   void              ReconcileCycle(const datetime now,const bool stable,const bool startup)
     {
      LLBExecEvent ev[];
      m_em.Reconcile(GetPointer(m_pm),now,stable,startup,ev);
      if(stable)
         m_em.AdoptOrphans(GetPointer(m_pm),now,startup,ev);
      for(int i=0; i<ArraySize(ev); i++)
        {
         if(ev[i].type==LLB_EV_FILLED && ev[i].positionId>0 && ev[i].index>=0 && ev[i].index<m_em.Count())
           {
            int s=SymIndex(m_em.items[ev[i].index].symbol);
            double step=(s>=0) ? m_sym[s].spec.volStep : 0.01;
            string msg;
            m_pos.Track(m_em.items[ev[i].index],ev[i].positionId,step,msg);
            Notify(LLB_IconOk()+" "+msg+((ev[i].text!="order filled") ? " ("+ev[i].text+")" : ""));
            continue;
           }
         Notify(ExecEventText(ev[i]));
        }
      int ns=ArraySize(m_sym);
      string syms[];
      double steps[],ticks[];
      ArrayResize(syms,ns);
      ArrayResize(steps,ns);
      ArrayResize(ticks,ns);
      for(int s=0; s<ns; s++)
        {
         syms[s]=m_sym[s].name;
         steps[s]=(m_sym[s].spec.volStep>0.0) ? m_sym[s].spec.volStep : 0.01;
         ticks[s]=m_sym[s].spec.tickSize;
        }
      LLBExecEvent pev[];
      m_pos.Reconcile(now,syms,steps,ticks,pev);
      for(int i=0; i<ArraySize(pev); i++)
         Notify(((pev[i].type==LLB_EV_POS_CLOSED) ? LLB_IconInfo() : LLB_IconWarn())+" "+pev[i].text);
     }

   //--- throttled retries: pending-order deletions and position actions
   void              ProcessActions(const datetime now)
     {
      long nowMs=NowMs();
      for(int i=0; i<m_em.Count(); i++)
        {
         if(!m_em.IsLivePending(i))
            continue;
         bool inval=(m_em.items[i].structState==LLB_ST_INVALIDATED);
         bool expired=m_em.NeedsEaExpiry(i,now);
         if(!inval && !expired)
            continue;
         if(m_em.items[i].actionAttempts>=LLB_MAX_DELETE_ATTEMPTS)
            continue;
         if(m_em.items[i].lastActionMs>0 && nowMs-m_em.items[i].lastActionMs<LLB_DELETE_RETRY_MS)
            continue;
         int s=SymIndex(m_em.items[i].symbol);
         if(s<0)
            continue;
         string msg;
         bool ok=m_em.DeleteOrder(i,inval ? "STRUCTURE_INVALIDATION" : "EA_MANAGED_EXPIRY",m_sym[s].spec,msg);
         m_em.items[i].lastActionMs=nowMs;
         if(ok && expired && !inval)
            Notify(LLB_IconClock()+" "+m_em.items[i].signalId+": proposal expiration reached - "+msg);
        }
      for(int i=0; i<m_pos.Count(); i++)
        {
         if(m_pos.items[i].state!=LLB_POS_OPEN)
            continue;
         int s=SymIndex(m_pos.items[i].symbol);
         if(s<0)
            continue;
         LLBExecEvent ev[];
         m_pos.ProcessActions(i,m_sym[s].spec,ev);
         for(int k=0; k<ArraySize(ev); k++)
            Notify(LLB_IconWarn()+" "+ev[k].text);
        }
     }

   //--- Telegram message maintenance for proposals whose state changed
   void              ProcessProposalChanges(void)
     {
      string ids[];
      int n=m_pm.TakeChanged(ids);
      if(!m_tg.Enabled())
         return;
      for(int i=0; i<n; i++)
        {
         int pidx=m_pm.Find(ids[i]);
         if(pidx<0)
            continue;
         if(m_pm.items[pidx].tgMessageId>0)
            m_tg.QueueEdit(m_pm.items[pidx].tgMessageId,LLB_FormatProposalStatus(m_pm.items[pidx],m_cfg.atrTf),ids[i]);
         else
            if(m_pm.items[pidx].state!=LLB_PS_ACTIVE && m_tg.CancelProposal(ids[i]))
               g_llbLog.Info("TGW",ids[i]+" became "+LLB_ProposalStateName(m_pm.items[pidx].state)+" before its message was sent - message cancelled");
        }
     }

   void              ProcessSentProposals(void)
     {
      string ids[];
      long mids[];
      int n=m_tg.TakeSentProposals(ids,mids);
      for(int i=0; i<n; i++)
        {
         int pidx=m_pm.Find(ids[i]);
         if(pidx<0 || mids[i]<=0)
            continue;
         m_pm.SetMessageId(pidx,mids[i]);
         if(m_pm.items[pidx].state!=LLB_PS_ACTIVE)
            m_tg.QueueEdit(mids[i],LLB_FormatProposalStatus(m_pm.items[pidx],m_cfg.atrTf),ids[i]);
        }
     }

   //+------------------------------------------------------------------+
   //| Startup recovery (Phase 2 §8) - runs once, when connected.       |
   //+------------------------------------------------------------------+
   void              RunStartupRecovery(const datetime now)
     {
      g_llbLog.Info("CRD","startup recovery: reconciling proposals, orders, deals and positions");
      //--- 1. ACCEPTED proposals without any submission => never traded after a restart (invariant 11)
      for(int i=0; i<m_pm.Count(); i++)
        {
         if(m_pm.items[i].state!=LLB_PS_ACCEPTED)
            continue;
         if(m_em.FindBySignal(m_pm.items[i].signalId)>=0)
            continue;
         ulong tk=0;
         string where;
         if(m_em.BrokerHasExec(m_pm.items[i].execId,now,tk,where))
            continue;                                     // orphan adoption below links it
         m_pm.Transition(i,LLB_PS_EXECUTION_FAILED,"RESTART_BEFORE_SUBMIT: no order was sent; the signal is not traded after a restart");
        }
      //--- 2. expiry
      m_pm.ProcessExpiry(now);
      //--- 3. orders / deals / positions (SUBMITTING not found => EXECUTION_FAILED, never re-sent)
      ReconcileCycle(now,true,true);
      //--- 4. daily sequence must also exceed every Execution ID seen on the broker today
      int d8=LLB_Date8(now);
      m_pm.EnsureSequenceAtLeast(d8,m_em.MaxBrokerSeq(d8%1000000,now));
      //--- 5. downtime touch scan (fail-safe for ACTIVE proposals)
      for(int s=0; s<ArraySize(m_sym); s++)
        {
         if(!m_sym[s].enabled)
            continue;
         m_sym[s].restartFloorMsc=(m_sym[s].lastScanMsc>0) ? m_sym[s].lastScanMsc-LLB_RESTART_OVERLAP_MS : 0;
         RefreshQuote(s);
         ScanSymbol(s,true);
        }
      //--- 6. summary
      int active=0,live=0,open=0;
      for(int i=0; i<m_pm.Count(); i++)
         if(m_pm.items[i].state==LLB_PS_ACTIVE)
            active++;
      for(int i=0; i<m_em.Count(); i++)
         if(m_em.IsLivePending(i))
            live++;
      for(int i=0; i<m_pos.Count(); i++)
         if(m_pos.items[i].state!=LLB_POS_CLOSED)
            open++;
      string symList="";
      for(int s=0; s<ArraySize(m_sym); s++)
         symList+=((symList=="") ? "" : ", ")+m_sym[s].name+(m_sym[s].enabled ? "" : " (DISABLED)");
      m_recoveryDone=true;
      m_stateDirty=true;
      string msg=LLB_IconInfo()+" 4LLB Trading Assistant v"+LLB_VERSION+" started on account "+IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN))
                 +" ("+(m_netting ? "NETTING" : "HEDGING")+")\nSymbols: "+symList
                 +"\nVolume: "+m_risk.Describe()
                 +StringFormat("\nRecovered: %d active proposal(s), %d pending order(s), %d open position(s)",active,live,open)
                 +"\nEvery trade still needs your ACCEPT.";
      Notify(msg);
     }

   void              DailyMaintenance(const datetime now)
     {
      int d=LLB_Date8(now);
      if(m_lastDay==0)
        {
         m_lastDay=d;
         return;
        }
      if(d==m_lastDay)
         return;
      m_lastDay=d;
      m_pm.Prune(now);
      m_em.Prune(now);
      m_pos.Prune(now);
      g_llbLog.Info("CRD","new broker server day "+IntegerToString(d));
     }

   //--- dashboard -------------------------------------------------------
   void              DL(string &lines[],int &cols[],color &clrs[],const int col,const string text,const color c)
     {
      int n=ArraySize(lines);
      ArrayResize(lines,n+1);
      ArrayResize(cols,n+1);
      ArrayResize(clrs,n+1);
      lines[n]=text;
      cols[n]=col;
      clrs[n]=c;
     }

   color             StateColor(const int st)
     {
      if(st==LLB_PS_ACTIVE)
         return clrDeepSkyBlue;
      if(st==LLB_PS_EXECUTED)
         return clrLime;
      if(st==LLB_PS_ACCEPTED || st==LLB_PS_EXECUTING)
         return clrYellow;
      if(st==LLB_PS_INVALIDATED || st==LLB_PS_EXECUTION_FAILED)
         return clrTomato;
      return clrSilver;
     }

   void              UpdateDashboard(const datetime now)
     {
      string lines[];
      int cols[];
      color clrs[];
      string tg=m_tg.Enabled() ? "TG "+m_tg.StatusText() : (m_tester ? "TG off (tester)" : "TG DISABLED");
      string hdr=StringFormat("4LLB v%s | %s | %s | %s | %s",LLB_VERSION,IsConnected() ? "Broker OK" : "Broker OFFLINE",
                              m_netting ? "NETTING" : "HEDGING",LLB_HMS(now),tg);
      if(!m_recoveryDone)
         hdr+=" | SYNCING";
      if(m_lockLost)
         hdr+=" | LOCK LOST";
      int col=-1;
      for(int s=0; s<ArraySize(m_sym); s++)
        {
         int d=m_sym[s].spec.digits;
         if(!m_sym[s].enabled)
           {
            hdr+=" | "+m_sym[s].name+" off";            // unavailable symbol: one word in the header, no column
            continue;
           }
         col++;
         DL(lines,cols,clrs,col,StringFormat("[%s] Bid %s Ask %s Spr %d",m_sym[s].name,DoubleToString(m_sym[s].bid,d),
                                           DoubleToString(m_sym[s].ask,d),m_sym[s].spreadPts),clrWhite);
         DL(lines,cols,clrs,col,"ATR(14,"+LLB_TfName(m_cfg.atrTf)+") "+DoubleToString(m_sym[s].atr,d)+" | "+m_sym[s].dataStatus,
            (m_sym[s].dataStatus=="OK") ? clrWhite : clrOrange);
         LLBLevels lv=m_sym[s].levels;
         DL(lines,cols,clrs,col,"P4 "+DoubleToString(lv.p4,d)+" | P1(PDH) "+DoubleToString(lv.pdh,d),clrKhaki);
         DL(lines,cols,clrs,col,"P2(PDL) "+DoubleToString(lv.pdl,d)+" | P3 "+DoubleToString(lv.p3,d),clrKhaki);
         int pidx=m_pm.LatestForSymbol(m_sym[s].name);
         if(pidx<0)
            DL(lines,cols,clrs,col,"Signal: -",clrSilver);
         else
           {
            LLBTradeProposal p=m_pm.items[pidx];
            long left=(long)p.expiresTime-(long)now;
            DL(lines,cols,clrs,col,"Signal: "+p.signalId,StateColor(p.state));
            DL(lines,cols,clrs,col,"  "+LLB_StrategyName(p.strategy)+" "+LLB_DirName(p.direction)+" @"+LLB_LevelName(p.level)+" "
               +LLB_ProposalStateName(p.state)+((p.state==LLB_PS_ACTIVE) ? " left "+LLB_Countdown(left) : "")+" exp "+LLB_HMS(p.expiresTime),StateColor(p.state));
            DL(lines,cols,clrs,col,"  E "+DoubleToString(p.entry,d)+" SL "+DoubleToString(p.sl,d)+" TP "+DoubleToString(p.tp,d)+" RR "+DoubleToString(p.rr,2),clrWhite);
            DL(lines,cols,clrs,col,"  Ref swing "+DoubleToString(p.refSwingPrice,d),clrWhite);
            int e=m_em.FindBySignal(p.signalId);
            if(e>=0)
               DL(lines,cols,clrs,col,"Exec "+m_em.items[e].execId+" "+LLB_ExecStateName(m_em.items[e].state)+"/"+LLB_OrderStateName(m_em.items[e].orderState)
                  +" #"+IntegerToString((long)m_em.items[e].orderTicket)+" "+DoubleToString(m_em.items[e].volume,2),clrWhite);
            else
               DL(lines,cols,clrs,col,"Exec: -",clrSilver);
           }
         int q=-1;
         for(int i=m_pos.Count()-1; i>=0; i--)
            if(m_pos.items[i].symbol==m_sym[s].name)
              {
               if(m_pos.items[i].state!=LLB_POS_CLOSED)
                 {
                  q=i;
                  break;
                 }
               if(q<0)
                  q=i;
              }
         if(q<0)
            DL(lines,cols,clrs,col,"Pos: -",clrSilver);
         else
           {
            LLBManagedPosition m=m_pos.items[q];
            if(m.state!=LLB_POS_CLOSED)
              {
               DL(lines,cols,clrs,col,StringFormat("Pos #%I64d %s %s @%s P/L %s",m.positionId,LLB_DirName(m.direction),DoubleToString(m.volume,2),
                                                 DoubleToString(m.openPrice,d),DoubleToString(m.floating,2)),(m.floating>=0.0) ? clrLime : clrTomato);
               DL(lines,cols,clrs,col,"  SL "+DoubleToString(m.sl,d)+" TP "+DoubleToString(m.tp,d)+(m.sltpVerified ? " [ok]" : " [CHECK]")
                  +" "+LLB_StructStateName(m.structState)+((m.ownership==LLB_OWN_CONFLICT) ? " CONFLICT" : "")+" "+LLB_PosStateName(m.state),
                  (m.structState==LLB_ST_INTACT && m.sltpVerified) ? clrWhite : clrOrange);
              }
            else
               DL(lines,cols,clrs,col,StringFormat("Last pos #%I64d closed %s P/L %s",m.positionId,LLB_CloseReasonName(m.closeReason),
                                                 DoubleToString(m.profit+m.commission+m.swap+m.fee,2)),clrSilver);
           }
        }
      m_dash.Render(hdr,lines,cols,clrs);
     }

public:
                     CLLBCoordinator(void)
     {
      m_tester=false;
      m_netting=false;
      m_initOk=false;
      m_dataDir="";
      m_instanceId="";
      m_lockLost=false;
      m_recoveryDone=false;
      m_wasConnected=false;
      m_connectedSinceMs=0;
      m_disconnectedSinceMs=0;
      m_reconcileFlag=false;
      m_lastReconcileMs=0;
      m_lastDashMs=0;
      m_lastStateSaveMs=0;
      m_lastHeartbeatMs=0;
      m_stateDirty=false;
      m_lastDay=0;
      m_loadedOffset=0;
     }

   //--- services for the ApprovalManager -----------------------------
   virtual bool      ServicesReady(string &why)
     {
      if(!m_recoveryDone)
        { why="startup reconciliation in progress"; return false; }
      if(m_lockLost)
        { why="instance lock lost"; return false; }
      if(!IsConnected())
        { why="no broker connection"; return false; }
      return true;
     }

   virtual bool      FreshTouchCheck(const int pidx,string &why)
     {
      if(pidx<0 || pidx>=m_pm.Count())
        { why="unknown proposal"; return false; }
      int s=SymIndex(m_pm.items[pidx].symbol);
      if(s<0 || !m_sym[s].enabled)
        { why="symbol not managed"; return false; }
      ScanSymbol(s,false);
      if(m_pm.items[pidx].state==LLB_PS_INVALIDATED)
        {
         why="structure invalidated - "+m_pm.items[pidx].stateReason;
         return false;
        }
      if(m_sym[s].lastScanFailed)
        {
         why="cannot verify the structure (tick history unavailable) - try again";
         return false;
        }
      return true;
     }

   virtual bool      SpecFor(const string sym,LLBSymbolSpec &spec)
     {
      int s=SymIndex(sym);
      if(s<0 || !m_sym[s].enabled)
         return false;
      string err;
      if(!m_md.LoadSpec(sym,spec,err))                 // fresh broker values at decision time
        {
         g_llbLog.Warn("CRD","spec reload failed for "+sym+": "+err);
         return false;
        }
      m_sym[s].spec=spec;
      return true;
     }

   virtual void      OurPositionIds(long &ids[]) { m_pos.CollectIds(ids); }

   virtual void      Notify(const string text)
     {
      g_llbLog.Info("NOTIFY",text);
      m_tg.QueueText(text);
     }

   //--- lifecycle ------------------------------------------------------
   int               OnInitEA(const LLBConfig &cfg)
     {
      m_cfg=cfg;
      m_tester=(bool)MQLInfoInteger(MQL_TESTER);
      MathSrand((uint)GetTickCount());
      m_instanceId=StringFormat("%I64d-%I64u-%d",ChartID(),GetTickCount64(),MathRand());
      string err="";
      m_risk.Init(m_cfg.lotMode,m_cfg.lotSize,m_cfg.riskPct,m_cfg.riskBase,m_cfg.dailyLossLimit,(ulong)m_cfg.magic);
      if(!ValidateInputs(err))
        {
         Fatal(err);
         return INIT_PARAMETERS_INCORRECT;
        }
      ENUM_ACCOUNT_MARGIN_MODE mm=(ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
      m_netting=(mm!=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
      long login=AccountInfoInteger(ACCOUNT_LOGIN);
      m_dataDir=m_tester ? LLB_FILE_ROOT+"\\tester_"+IntegerToString(m_cfg.magic)
                : LLB_FILE_ROOT+"\\"+IntegerToString(login)+"_"+IntegerToString(m_cfg.magic);
      if(!m_per.Init(m_dataDir,m_tester,err))
        {
         Fatal(err);
         return INIT_FAILED;
        }
      g_llbLog.Init(m_cfg.logLevel,m_cfg.logToFile,m_dataDir,m_tester);
      g_llbLog.Info("CRD",StringFormat("%s v%s init | account %I64d %s | %s | data MQL5\\Files\\%s",LLB_EA_NAME,LLB_VERSION,login,
                                       AccountInfoString(ACCOUNT_SERVER),m_netting ? "NETTING" : "HEDGING",m_dataDir));
      string info=IntegerToString(login)+" "+TerminalInfoString(TERMINAL_PATH);
      if(!m_tester && !m_lockCoord.Acquire("coord_"+IntegerToString(login)+"_"+IntegerToString(m_cfg.magic),m_instanceId,info,err))
        {
         Fatal("another 4LLB Coordinator already runs for this account/magic on this computer: "+err);
         return INIT_FAILED;
        }
      if(!InitSymbols(err))
        {
         Fatal(err);
         m_lockCoord.Release();
         return INIT_FAILED;
        }
      m_pm.Init(GetPointer(m_per));
      m_em.Init(GetPointer(m_per),GetPointer(m_risk),GetPointer(m_md),(ulong)m_cfg.magic,m_cfg.closeDeviation,m_cfg.allowEaExpiry,m_netting,m_tester);
      m_pos.Init(GetPointer(m_per),GetPointer(m_em),(ulong)m_cfg.magic,m_netting);
      LoadAll();
      bool tgOn=(m_cfg.tgEnabled && !m_tester);
      if(!m_tg.Init(tgOn,m_cfg.tgToken,m_cfg.tgChatId,m_cfg.tgAllowed,m_cfg.tgPollMs,m_cfg.tgTimeoutMs,err))
        {
         Fatal("Telegram configuration: "+err);
         m_lockCoord.Release();
         return INIT_FAILED;
        }
      m_tg.SetOffset(m_loadedOffset);
      if(tgOn && !m_lockTg.Acquire("tg_"+m_tg.TokenKey(),m_instanceId,info,err))
        {
         Fatal("Telegram gateway: "+err+" - only ONE EA instance may poll a bot token (use another bot for another terminal)");
         m_lockCoord.Release();
         return INIT_FAILED;
        }
      if(!m_tester)
        {
         Sleep(LLB_LOCK_VERIFY_MS);
         if(!m_lockCoord.Verify(err) || (tgOn && !m_lockTg.Verify(err)))
           {
            Fatal("instance lock: "+err);
            m_lockTg.Release();
            m_lockCoord.Release();
            return INIT_FAILED;
           }
        }
      m_apr.Init(GetPointer(m_pm),GetPointer(m_em),GetPointer(m_tg),GetPointer(this));
      bool dashOn=(m_cfg.showDashboard && (!m_tester || (bool)MQLInfoInteger(MQL_VISUAL_MODE)));
      m_dash.Init(dashOn,"4LLB_DASH_",m_cfg.dashPos,m_cfg.dashCollapsed);
      if(!EventSetMillisecondTimer(LLB_TIMER_MS))
        {
         Fatal("EventSetMillisecondTimer failed");
         m_lockTg.Release();
         m_lockCoord.Release();
         return INIT_FAILED;
        }
      m_initOk=true;
      m_lastHeartbeatMs=NowMs();
      g_llbLog.Info("CRD","volume: "+m_risk.Describe()+" | swing ref: "+((m_cfg.swingRefMode==LLB_SWINGREF_SETUP_EXTREME) ? "setup extreme" : "confirmed pivot")
                    +" | P3/P4 nearest by "+((m_cfg.nearestMode==LLB_NEAREST_PRICE) ? "price" : "time")+" | ATR(14,"+LLB_TfName(m_cfg.atrTf)+")");
      if(!tgOn && !(m_tester && m_cfg.testerAutoApprove))
         g_llbLog.Warn("CRD","Telegram disabled: proposals are only logged - nothing can be approved, so NO trade will be placed");
      if(!m_tester && !(bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
         g_llbLog.Warn("CRD","Algo Trading is OFF in the terminal: approved proposals will be refused until it is enabled");
      return INIT_SUCCEEDED;
     }

   void              OnDeinitEA(const int reason)
     {
      EventKillTimer();
      if(m_initOk)
         SaveState();
      for(int s=0; s<ArraySize(m_sym); s++)
         if(m_sym[s].atrHandle!=INVALID_HANDLE)
           {
            IndicatorRelease(m_sym[s].atrHandle);
            m_sym[s].atrHandle=INVALID_HANDLE;
           }
      m_lockTg.Release();
      m_lockCoord.Release();
      m_dash.Deinit();
      m_tg.Deinit();
      g_llbLog.Info("CRD","deinit reason="+IntegerToString(reason));
      g_llbLog.Deinit();
      m_initOk=false;
     }

   void              OnTimerEA(void)
     {
      if(!m_initOk)
         return;
      datetime now=TimeTradeServer();
      long nowMs=NowMs();
      //--- broker connection tracking (R-POS-06)
      bool conn=IsConnected();
      if(conn && !m_wasConnected)
        {
         m_connectedSinceMs=nowMs;
         if(m_disconnectedSinceMs>0 && m_recoveryDone)
           {
            Notify(LLB_IconInfo()+" Broker connection restored after "+IntegerToString((nowMs-m_disconnectedSinceMs)/1000)+" s - reconciling orders and positions.");
            m_reconcileFlag=true;
           }
         m_disconnectedSinceMs=0;
        }
      if(!conn && m_wasConnected)
        {
         m_disconnectedSinceMs=nowMs;
         g_llbLog.Warn("CRD","broker connection lost - no new orders; broker-side SL/TP keep protecting open positions");
         if(m_recoveryDone)
            Notify(LLB_IconWarn()+" Broker connection lost. No new orders until reconnection; broker SL/TP remain active.");
        }
      m_wasConnected=conn;
      bool stable=m_tester ? true : (conn && nowMs-m_connectedSinceMs>=(long)LLB_CONNECT_SETTLE_SEC*1000);
      //--- single-instance locks
      if(!m_tester && !m_lockLost && nowMs-m_lastHeartbeatMs>=LLB_LOCK_HEARTBEAT_MS)
        {
         m_lastHeartbeatMs=nowMs;
         string why;
         bool ok=m_lockCoord.Heartbeat(why);
         if(ok && m_tg.Enabled())
            ok=m_lockTg.Heartbeat(why);
         if(!ok)
           {
            m_lockLost=true;
            g_llbLog.Error("CRD","INSTANCE LOCK LOST ("+why+") - Telegram polling, executions and position actions stopped");
            Alert("4LLB: instance lock lost ("+why+"). Remove the duplicate EA instance and restart.");
           }
        }
      //--- startup recovery first
      if(!m_recoveryDone)
        {
         if(stable)
            RunStartupRecovery(now);
         if(!m_recoveryDone)
           {
            if(nowMs-m_lastDashMs>=LLB_DASHBOARD_MS)
              {
               m_lastDashMs=nowMs;
               UpdateDashboard(now);
              }
            return;
           }
        }
      //--- proposals: expiry, invalidation, new bars (analysis never waits for Telegram)
      m_pm.ProcessExpiry(now);
      for(int s=0; s<ArraySize(m_sym); s++)
        {
         if(!m_sym[s].enabled)
            continue;
         RefreshQuote(s);
         ScanSymbol(s,false);
         CheckNewBar(s,now);
        }
      //--- Telegram approvals
      if(m_tg.Enabled() && !m_lockLost)
        {
         m_tg.PollIfDue();
         LLBTelegramCallback cbs[];
         int n=m_tg.TakeCallbacks(cbs);
         for(int i=0; i<n; i++)
            m_apr.HandleCallback(cbs[i],TimeTradeServer());
         if(m_tg.OffsetDirty())
           {
            m_tg.ClearOffsetDirty();
            SaveState();
           }
        }
      ProcessProposalChanges();
      //--- reconciliation and position actions
      if(conn && (m_reconcileFlag || nowMs-m_lastReconcileMs>=LLB_RECONCILE_MS))
        {
         ReconcileCycle(now,stable,false);
         m_reconcileFlag=false;
         m_lastReconcileMs=nowMs;
        }
      if(conn && !m_lockLost)
         ProcessActions(now);
      ProcessProposalChanges();
      if(m_tg.Enabled() && !m_lockLost)
        {
         m_tg.Flush(3);
         ProcessSentProposals();
        }
      DailyMaintenance(now);
      long saveEvery=m_tester ? 60000 : LLB_STATE_SAVE_MS;
      if(m_stateDirty && nowMs-m_lastStateSaveMs>=saveEvery)
         SaveState();
      if(nowMs-m_lastDashMs>=LLB_DASHBOARD_MS)
        {
         m_lastDashMs=nowMs;
         UpdateDashboard(now);
        }
     }

   //--- chart-symbol ticks only shorten the invalidation latency
   void              OnTickEA(void)
     {
      if(!m_initOk || !m_recoveryDone)
         return;
      int s=SymIndex(_Symbol);
      if(s>=0 && m_sym[s].enabled)
         ScanSymbol(s,false);
     }

   //--- dashboard click: collapse / expand only (display, never trading)
   void              OnChartEventEA(const int id,const long lparam,const double dparam)
     {
      if(!m_initOk || id!=CHARTEVENT_CLICK)
         return;
      if(m_dash.OnChartClick((int)lparam,(int)dparam))
         UpdateDashboard(TimeTradeServer());
     }

   //--- trade events only trigger an early reconciliation (not a source of truth)
   void              OnTradeTransactionEA(void) { m_reconcileFlag=true; }
  };

#endif
//+------------------------------------------------------------------+
