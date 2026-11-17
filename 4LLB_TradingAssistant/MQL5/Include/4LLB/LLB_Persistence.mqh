//+------------------------------------------------------------------+
//| LLB_Persistence.mqh                                              |
//| PersistenceManager (R-PER-01..03).                               |
//| - signals.csv / executions.csv / positions.csv: append-only      |
//|   journals; one full snapshot per state change; last valid line  |
//|   per id wins; every line carries a CRC32 (partial/corrupt lines |
//|   are skipped and counted).                                      |
//| - system_state.dat: key=value + crc32 line, atomic write         |
//|   (tmp -> read back + verify -> .bak -> FileMove(FILE_REWRITE)). |
//+------------------------------------------------------------------+
#ifndef LLB_PERSISTENCE_MQH
#define LLB_PERSISTENCE_MQH

#include "LLB_Defines.mqh"
#include "LLB_Utils.mqh"
#include "LLB_Logger.mqh"

#define LLB_FILE_SIGNALS     "signals.csv"
#define LLB_FILE_EXECUTIONS  "executions.csv"
#define LLB_FILE_POSITIONS   "positions.csv"
#define LLB_FILE_STATE       "system_state.dat"

#define LLB_SIGNAL_FIELDS    30
#define LLB_EXEC_FIELDS      28
#define LLB_POS_FIELDS       27

#define LLB_LOAD_OK          0
#define LLB_LOAD_MISSING     1
#define LLB_LOAD_CORRUPT     2

//+------------------------------------------------------------------+
//| Pure CSV helpers                                                 |
//+------------------------------------------------------------------+
string LLB_TS(const datetime t) { return TimeToString(t,TIME_DATE|TIME_SECONDS); }
string LLB_PX(const double v)   { return LLB_D(v,6); }

string LLB_WithCrc(const string body) { return body+";crc="+LLB_Hex32(LLB_Crc32(body)); }

//--- splits a journal line, verifies its CRC and field count
bool LLB_CsvSplitVerified(const string line,string &fields[],const int expected)
  {
   ArrayResize(fields,0);
   if(StringLen(line)<10 || StringGetCharacter(line,0)=='#')
      return false;
   string parts[];
   int n=StringSplit(line,(ushort)';',parts);
   if(n!=expected+1)
      return false;
   string last=parts[n-1];
   if(StringFind(last,"crc=")!=0)
      return false;
   string body=parts[0];
   for(int i=1; i<n-1; i++)
      body+=";"+parts[i];
   if(StringSubstr(last,4)!=LLB_Hex32(LLB_Crc32(body)))
      return false;
   ArrayResize(fields,expected);
   for(int i=0; i<expected; i++)
      fields[i]=parts[i];
   return true;
  }

//--- signals.csv --------------------------------------------------
string LLB_SignalCsvHeader(void)
  {
   return "#rec_time;signal_id;symbol;strategy;direction;level;level_price;entry;sl;tp;rr;atr;bid;ask;spread_pts;digits;created;expires;signal_bar;ref_swing_price;ref_swing_time;monitor_from_msc;state;state_reason;decision;decision_user;decision_time;tg_message_id;exec_id;reason;crc";
  }

string LLB_SignalToCsv(const LLBTradeProposal &p,const datetime recTime)
  {
   string b=LLB_TS(recTime);
   b+=";"+LLB_CsvClean(p.signalId);
   b+=";"+LLB_CsvClean(p.symbol);
   b+=";"+LLB_StrategyName(p.strategy);
   b+=";"+LLB_DirName(p.direction);
   b+=";"+LLB_LevelName(p.level);
   b+=";"+LLB_PX(p.levelPrice);
   b+=";"+LLB_PX(p.entry);
   b+=";"+LLB_PX(p.sl);
   b+=";"+LLB_PX(p.tp);
   b+=";"+LLB_D(p.rr,4);
   b+=";"+LLB_PX(p.atr);
   b+=";"+LLB_PX(p.bid);
   b+=";"+LLB_PX(p.ask);
   b+=";"+IntegerToString(p.spreadPoints);
   b+=";"+IntegerToString(p.digits);
   b+=";"+LLB_TS(p.createdTime);
   b+=";"+LLB_TS(p.expiresTime);
   b+=";"+LLB_TS(p.signalBarTime);
   b+=";"+LLB_PX(p.refSwingPrice);
   b+=";"+LLB_TS(p.refSwingTime);
   b+=";"+IntegerToString(p.monitorFromMsc);
   b+=";"+LLB_ProposalStateName(p.state);
   b+=";"+LLB_CsvClean(p.stateReason);
   b+=";"+LLB_DecisionName(p.decision);
   b+=";"+IntegerToString(p.decisionUser);
   b+=";"+LLB_TS(p.decisionTime);
   b+=";"+IntegerToString(p.tgMessageId);
   b+=";"+LLB_CsvClean(p.execId);
   b+=";"+LLB_CsvClean(p.reason);
   return LLB_WithCrc(b);
  }

bool LLB_SignalFromCsv(const string line,LLBTradeProposal &p)
  {
   string f[];
   if(!LLB_CsvSplitVerified(line,f,LLB_SIGNAL_FIELDS))
      return false;
   p.Reset();
   p.signalId     =f[1];
   p.symbol       =f[2];
   p.strategy     =LLB_StrategyFromName(f[3]);
   p.direction    =LLB_DirFromName(f[4]);
   p.level        =LLB_LevelFromName(f[5]);
   p.levelPrice   =StringToDouble(f[6]);
   p.entry        =StringToDouble(f[7]);
   p.sl           =StringToDouble(f[8]);
   p.tp           =StringToDouble(f[9]);
   p.rr           =StringToDouble(f[10]);
   p.atr          =StringToDouble(f[11]);
   p.bid          =StringToDouble(f[12]);
   p.ask          =StringToDouble(f[13]);
   p.spreadPoints =(int)StringToInteger(f[14]);
   p.digits       =(int)StringToInteger(f[15]);
   p.createdTime  =StringToTime(f[16]);
   p.expiresTime  =StringToTime(f[17]);
   p.signalBarTime=StringToTime(f[18]);
   p.refSwingPrice=StringToDouble(f[19]);
   p.refSwingTime =StringToTime(f[20]);
   p.monitorFromMsc=StringToInteger(f[21]);
   p.state        =LLB_ProposalStateFromName(f[22]);
   p.stateReason  =f[23];
   p.decision     =LLB_DecisionFromName(f[24]);
   p.decisionUser =StringToInteger(f[25]);
   p.decisionTime =StringToTime(f[26]);
   p.tgMessageId  =StringToInteger(f[27]);
   p.execId       =f[28];
   p.reason       =f[29];
   if(p.signalId=="" || p.symbol=="" || p.strategy<0 || p.direction<0 || p.state<0)
      return false;
   return true;
  }

//--- executions.csv -----------------------------------------------
string LLB_ExecCsvHeader(void)
  {
   return "#rec_time;exec_id;signal_id;symbol;direction;order_type;exec_state;order_state;volume;entry;sl;tp;expiration;type_time;filling;submit_msc;retcode;ret_comment;order_ticket;deal_ticket;position_id;fill_price;fill_volume;ref_swing_price;monitor_from_msc;struct_state;cancel_reason;note;crc";
  }

string LLB_ExecToCsv(const LLBExecutionRecord &e,const datetime recTime)
  {
   string b=LLB_TS(recTime);
   b+=";"+LLB_CsvClean(e.execId);
   b+=";"+LLB_CsvClean(e.signalId);
   b+=";"+LLB_CsvClean(e.symbol);
   b+=";"+LLB_DirName(e.direction);
   b+=";"+LLB_OrderTypeName(e.orderType);
   b+=";"+LLB_ExecStateName(e.state);
   b+=";"+LLB_OrderStateName(e.orderState);
   b+=";"+LLB_D(e.volume,4);
   b+=";"+LLB_PX(e.entry);
   b+=";"+LLB_PX(e.sl);
   b+=";"+LLB_PX(e.tp);
   b+=";"+LLB_TS(e.expiration);
   b+=";"+IntegerToString(e.typeTime);
   b+=";"+IntegerToString(e.filling);
   b+=";"+IntegerToString(e.submitMsc);
   b+=";"+IntegerToString((long)e.retcode);
   b+=";"+LLB_CsvClean(e.retComment);
   b+=";"+IntegerToString((long)e.orderTicket);
   b+=";"+IntegerToString((long)e.dealTicket);
   b+=";"+IntegerToString(e.positionId);
   b+=";"+LLB_PX(e.fillPrice);
   b+=";"+LLB_D(e.fillVolume,4);
   b+=";"+LLB_PX(e.refSwingPrice);
   b+=";"+IntegerToString(e.monitorFromMsc);
   b+=";"+LLB_StructStateName(e.structState);
   b+=";"+LLB_CsvClean(e.cancelReason);
   b+=";"+LLB_CsvClean(e.note);
   return LLB_WithCrc(b);
  }

bool LLB_ExecFromCsv(const string line,LLBExecutionRecord &e)
  {
   string f[];
   if(!LLB_CsvSplitVerified(line,f,LLB_EXEC_FIELDS))
      return false;
   e.Reset();
   e.execId        =f[1];
   e.signalId      =f[2];
   e.symbol        =f[3];
   e.direction     =LLB_DirFromName(f[4]);
   e.orderType     =LLB_OrderTypeFromName(f[5]);
   e.state         =LLB_ExecStateFromName(f[6]);
   e.orderState    =LLB_OrderStateFromName(f[7]);
   e.volume        =StringToDouble(f[8]);
   e.entry         =StringToDouble(f[9]);
   e.sl            =StringToDouble(f[10]);
   e.tp            =StringToDouble(f[11]);
   e.expiration    =StringToTime(f[12]);
   e.typeTime      =(int)StringToInteger(f[13]);
   e.filling       =(int)StringToInteger(f[14]);
   e.submitMsc     =StringToInteger(f[15]);
   e.retcode       =(uint)StringToInteger(f[16]);
   e.retComment    =f[17];
   e.orderTicket   =(ulong)StringToInteger(f[18]);
   e.dealTicket    =(ulong)StringToInteger(f[19]);
   e.positionId    =StringToInteger(f[20]);
   e.fillPrice     =StringToDouble(f[21]);
   e.fillVolume    =StringToDouble(f[22]);
   e.refSwingPrice =StringToDouble(f[23]);
   e.monitorFromMsc=StringToInteger(f[24]);
   e.structState   =LLB_StructStateFromName(f[25]);
   e.cancelReason  =f[26];
   e.note          =f[27];
   if(e.execId=="" || e.state<0 || e.orderState<0 || e.direction<0)
      return false;
   return true;
  }

//--- positions.csv ------------------------------------------------
string LLB_PosCsvHeader(void)
  {
   return "#rec_time;position_id;exec_id;signal_id;symbol;direction;volume;open_price;sl;tp;expected_sl;expected_tp;open_time;pos_state;struct_state;ownership;sltp_verified;ref_swing_price;monitor_from_msc;close_time;close_price;profit;commission;swap;fee;close_reason;close_note;crc";
  }

string LLB_PosToCsv(const LLBManagedPosition &m,const datetime recTime)
  {
   string b=LLB_TS(recTime);
   b+=";"+IntegerToString(m.positionId);
   b+=";"+LLB_CsvClean(m.execId);
   b+=";"+LLB_CsvClean(m.signalId);
   b+=";"+LLB_CsvClean(m.symbol);
   b+=";"+LLB_DirName(m.direction);
   b+=";"+LLB_D(m.volume,4);
   b+=";"+LLB_PX(m.openPrice);
   b+=";"+LLB_PX(m.sl);
   b+=";"+LLB_PX(m.tp);
   b+=";"+LLB_PX(m.expectedSl);
   b+=";"+LLB_PX(m.expectedTp);
   b+=";"+LLB_TS(m.openTime);
   b+=";"+LLB_PosStateName(m.state);
   b+=";"+LLB_StructStateName(m.structState);
   b+=";"+LLB_OwnershipName(m.ownership);
   b+=";"+(m.sltpVerified ? "1" : "0");
   b+=";"+LLB_PX(m.refSwingPrice);
   b+=";"+IntegerToString(m.monitorFromMsc);
   b+=";"+LLB_TS(m.closeTime);
   b+=";"+LLB_PX(m.closePrice);
   b+=";"+LLB_D(m.profit,4);
   b+=";"+LLB_D(m.commission,4);
   b+=";"+LLB_D(m.swap,4);
   b+=";"+LLB_D(m.fee,4);
   b+=";"+LLB_CloseReasonName(m.closeReason);
   b+=";"+LLB_CsvClean(m.closeNote);
   return LLB_WithCrc(b);
  }

bool LLB_PosFromCsv(const string line,LLBManagedPosition &m)
  {
   string f[];
   if(!LLB_CsvSplitVerified(line,f,LLB_POS_FIELDS))
      return false;
   m.Reset();
   m.positionId    =StringToInteger(f[1]);
   m.execId        =f[2];
   m.signalId      =f[3];
   m.symbol        =f[4];
   m.direction     =LLB_DirFromName(f[5]);
   m.volume        =StringToDouble(f[6]);
   m.openPrice     =StringToDouble(f[7]);
   m.sl            =StringToDouble(f[8]);
   m.tp            =StringToDouble(f[9]);
   m.expectedSl    =StringToDouble(f[10]);
   m.expectedTp    =StringToDouble(f[11]);
   m.openTime      =StringToTime(f[12]);
   m.state         =LLB_PosStateFromName(f[13]);
   m.structState   =LLB_StructStateFromName(f[14]);
   m.ownership     =LLB_OwnershipFromName(f[15]);
   m.sltpVerified  =(f[16]=="1");
   m.refSwingPrice =StringToDouble(f[17]);
   m.monitorFromMsc=StringToInteger(f[18]);
   m.closeTime     =StringToTime(f[19]);
   m.closePrice    =StringToDouble(f[20]);
   m.profit        =StringToDouble(f[21]);
   m.commission    =StringToDouble(f[22]);
   m.swap          =StringToDouble(f[23]);
   m.fee           =StringToDouble(f[24]);
   m.closeReason   =LLB_CloseReasonFromName(f[25]);
   m.closeNote     =f[26];
   if(m.positionId==0 || m.state<0 || m.direction<0)
      return false;
   return true;
  }

//+------------------------------------------------------------------+
//| File access                                                      |
//+------------------------------------------------------------------+
class CLLBPersistence
  {
private:
   string            m_dir;
   bool              m_ready;

public:
                     CLLBPersistence(void) { m_dir=""; m_ready=false; }

   bool              Init(const string dir,const bool wipe,string &err)
     {
      m_dir=dir;
      FolderCreate(LLB_FILE_ROOT,0);
      FolderCreate(m_dir,0);
      if(wipe)
         FolderClean(m_dir,0);
      //--- probe: the folder must be writable, otherwise nothing can be guaranteed
      string probe=File("write_probe.tmp");
      int h=FileOpen(probe,FILE_WRITE|FILE_TXT|FILE_ANSI);
      if(h==INVALID_HANDLE)
        {
         err="cannot write to MQL5\\Files\\"+m_dir+" err="+(string)GetLastError();
         m_ready=false;
         return false;
        }
      FileWriteString(h,"ok\r\n");
      FileClose(h);
      FileDelete(probe);
      m_ready=true;
      return true;
     }

   bool              Ready(void) const { return m_ready; }
   string            Dir(void) const { return m_dir; }
   string            File(const string name) const { return m_dir+"\\"+name; }

   bool              AppendLine(const string name,const string header,const string line)
     {
      if(!m_ready)
         return false;
      string path=File(name);
      ResetLastError();
      int h=FileOpen(path,FILE_READ|FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_SHARE_READ);
      if(h==INVALID_HANDLE)
        {
         g_llbLog.Error("PER","journal open failed "+path+" err="+(string)GetLastError());
         return false;
        }
      if(FileSize(h)==0)
         FileWriteString(h,header+"\r\n");
      FileSeek(h,0,SEEK_END);
      uint written=FileWriteString(h,line+"\r\n");
      FileFlush(h);
      FileClose(h);
      if(written==0)
        {
         g_llbLog.Error("PER","journal write failed "+path);
         return false;
        }
      return true;
     }

   bool              ReadAll(const string name,string &lines[])
     {
      ArrayResize(lines,0);
      string path=File(name);
      if(!FileIsExist(path))
         return false;
      int h=FileOpen(path,FILE_READ|FILE_TXT|FILE_ANSI|FILE_SHARE_READ|FILE_SHARE_WRITE);
      if(h==INVALID_HANDLE)
        {
         g_llbLog.Error("PER","read open failed "+path+" err="+(string)GetLastError());
         return false;
        }
      while(!FileIsEnding(h))
        {
         string l=FileReadString(h);
         int len=StringLen(l);
         if(len>0 && StringGetCharacter(l,len-1)=='\r')
            l=StringSubstr(l,0,len-1);
         int n=ArraySize(lines);
         ArrayResize(lines,n+1,1024);
         lines[n]=l;
        }
      FileClose(h);
      return true;
     }

   long              SizeOf(const string name)
     {
      string path=File(name);
      if(!FileIsExist(path))
         return 0;
      int h=FileOpen(path,FILE_READ|FILE_TXT|FILE_ANSI|FILE_SHARE_READ|FILE_SHARE_WRITE);
      if(h==INVALID_HANDLE)
         return 0;
      long sz=(long)FileSize(h);
      FileClose(h);
      return sz;
     }

   //--- keeps the full history in an archive file, rewrites the latest snapshots
   bool              ArchiveAndRewrite(const string name,const string header,const string &lines[])
     {
      string path=File(name);
      MqlDateTime d;
      TimeToStruct(TimeTradeServer(),d);
      string arch=File(StringFormat("%s_archive_%04d%02d%02d%02d%02d%02d.csv",StringSubstr(name,0,StringLen(name)-4),
                                    d.year,d.mon,d.day,d.hour,d.min,d.sec));
      if(!FileMove(path,0,arch,0))
        {
         g_llbLog.Warn("PER","archive move failed "+path+" err="+(string)GetLastError());
         return false;
        }
      int h=FileOpen(path,FILE_WRITE|FILE_TXT|FILE_ANSI);
      if(h==INVALID_HANDLE)
        {
         g_llbLog.Error("PER","rewrite open failed "+path+" err="+(string)GetLastError());
         return false;
        }
      FileWriteString(h,header+"\r\n");
      for(int i=0; i<ArraySize(lines); i++)
         FileWriteString(h,lines[i]+"\r\n");
      FileFlush(h);
      FileClose(h);
      g_llbLog.Info("PER","journal archived to "+arch+" and rewritten with "+(string)ArraySize(lines)+" latest records");
      return true;
     }

   //--- state file ---------------------------------------------------
   bool              VerifyStateLines(const string &lines[],string &content)
     {
      content="";
      int n=ArraySize(lines);
      int crcLine=-1;
      for(int i=n-1; i>=0; i--)
        {
         if(StringLen(lines[i])==0)
            continue;
         if(StringFind(lines[i],"crc32=")==0)
            crcLine=i;
         break;
        }
      if(crcLine<0)
         return false;
      for(int i=0; i<crcLine; i++)
         content+=lines[i]+"\n";
      return (StringSubstr(lines[crcLine],6)==LLB_Hex32(LLB_Crc32(content)));
     }

   bool              SaveState(const string content)
     {
      if(!m_ready)
         return false;
      string tmp=File("system_state.tmp");
      string main=File(LLB_FILE_STATE);
      string bak=File("system_state.bak");
      int h=FileOpen(tmp,FILE_WRITE|FILE_TXT|FILE_ANSI);
      if(h==INVALID_HANDLE)
        {
         g_llbLog.Error("PER","state tmp open failed err="+(string)GetLastError());
         return false;
        }
      //--- CRC is computed on LF-joined lines; the file itself uses CRLF line ends
      string onDisk=content;
      StringReplace(onDisk,"\n","\r\n");
      FileWriteString(h,onDisk);
      FileWriteString(h,"crc32="+LLB_Hex32(LLB_Crc32(content))+"\r\n");
      FileFlush(h);
      FileClose(h);
      string lines[],back;
      if(!ReadAll("system_state.tmp",lines) || !VerifyStateLines(lines,back))
        {
         g_llbLog.Error("PER","state tmp verification failed");
         return false;
        }
      if(FileIsExist(main))
         FileCopy(main,0,bak,FILE_REWRITE);
      if(!FileMove(tmp,0,main,FILE_REWRITE))
        {
         g_llbLog.Error("PER","state move failed err="+(string)GetLastError());
         return false;
        }
      return true;
     }

   int               LoadStateFile(const string name,string &keys[],string &vals[],string &why)
     {
      ArrayResize(keys,0);
      ArrayResize(vals,0);
      if(!FileIsExist(File(name)))
        {
         why=name+" missing";
         return LLB_LOAD_MISSING;
        }
      string lines[],content;
      if(!ReadAll(name,lines))
        {
         why=name+" unreadable";
         return LLB_LOAD_CORRUPT;
        }
      if(!VerifyStateLines(lines,content))
        {
         why=name+" checksum invalid";
         return LLB_LOAD_CORRUPT;
        }
      for(int i=0; i<ArraySize(lines); i++)
        {
         int p=StringFind(lines[i],"=");
         if(p<=0 || StringFind(lines[i],"crc32=")==0)
            continue;
         int n=ArraySize(keys);
         ArrayResize(keys,n+1);
         ArrayResize(vals,n+1);
         keys[n]=StringSubstr(lines[i],0,p);
         vals[n]=StringSubstr(lines[i],p+1);
        }
      return LLB_LOAD_OK;
     }

   //--- main file, falling back to the backup copy
   int               LoadState(string &keys[],string &vals[],string &why)
     {
      int rc=LoadStateFile(LLB_FILE_STATE,keys,vals,why);
      if(rc==LLB_LOAD_OK)
         return rc;
      string why2;
      int rc2=LoadStateFile("system_state.bak",keys,vals,why2);
      if(rc2==LLB_LOAD_OK)
        {
         g_llbLog.Warn("PER","system_state.dat unusable ("+why+"), using system_state.bak");
         return LLB_LOAD_OK;
        }
      return rc;
     }
  };

//--- key/value lookup helpers
string LLB_KV(const string &keys[],const string &vals[],const string key,const string def)
  {
   for(int i=0; i<ArraySize(keys); i++)
      if(keys[i]==key)
         return vals[i];
   return def;
  }

#endif
//+------------------------------------------------------------------+
