//+------------------------------------------------------------------+
//| AG_Persistence.mqh                                               |
//| Versioned key=value state file with CRC32, atomic write          |
//| (tmp -> verify -> move). Corrupt/mismatch => LOAD_CORRUPT.       |
//+------------------------------------------------------------------+
#ifndef AG_PERSISTENCE_MQH
#define AG_PERSISTENCE_MQH

#include "AG_Types.mqh"
#include "AG_Math.mqh"
#include "AG_Logger.mqh"
#include "AG_Environment.mqh"
#include "AG_BasketManager.mqh"
#include "AG_RiskManager.mqh"

bool   g_stateWriteOk=true;
long   g_lastSaveMsc=0;
string g_kvKeys[];
string g_kvVals[];

string AG_SanitizeName(string s)
  {
   string out="";
   int n=StringLen(s);
   for(int i=0; i<n; i++)
     {
      ushort c=StringGetCharacter(s,i);
      bool ok=((c>='0' && c<='9') || (c>='a' && c<='z') || (c>='A' && c<='Z') || c=='.' || c=='-');
      out+=ok ? ShortToString(c) : "_";
     }
   return out;
  }

string StateBaseName()
  {
   string n="AdaptiveGrid\\AG_"+(string)AccountInfoInteger(ACCOUNT_LOGIN)+"_"+AG_SanitizeName(AccountInfoString(ACCOUNT_SERVER))
            +"_"+AG_SanitizeName(g_spec.name)+"_"+(string)g_cfg.magicBuy+"_"+(string)g_cfg.magicSell;
   if((bool)MQLInfoInteger(MQL_TESTER))
      n+="_TESTER";
   return n;
  }
string StateFileMain() { return StateBaseName()+".state"; }
string StateFileTmp()  { return StateBaseName()+".tmp"; }
string StateFileBak()  { return StateBaseName()+".bak"; }

string AG_CleanVal(string v)
  {
   StringReplace(v,"\r"," ");
   StringReplace(v,"\n"," ");
   return v;
  }

void KV(string &c,const string k,const string v) { c+=k+"="+AG_CleanVal(v)+"\n"; }
string DS(const double v) { return DoubleToString(v,8); }
string BS(const bool v)   { return v ? "1" : "0"; }

//+------------------------------------------------------------------+
string BuildStateContent()
  {
   string c="";
   KV(c,"schema",(string)AG_STATE_SCHEMA);
   KV(c,"version",AG_VERSION);
   KV(c,"symbol",g_spec.name);
   KV(c,"magicBuy",(string)g_cfg.magicBuy);
   KV(c,"magicSell",(string)g_cfg.magicSell);
   KV(c,"login",(string)AccountInfoInteger(ACCOUNT_LOGIN));
   KV(c,"writeTime",(string)(long)TimeTradeServer());
   KV(c,"hwm",DS(g_hwm));
   KV(c,"apBase",DS(g_apBase));
   KV(c,"netFlow",DS(g_netFlow));
   KV(c,"flowScanTime",(string)(long)g_flowScanTime);
   KV(c,"flowTickets",g_flowTickets);
   KV(c,"dayStart",(string)(long)g_dayStart);
   KV(c,"dailySnap",DS(g_dailySnap));
   KV(c,"lastResetToken",(string)g_lastResetToken);
   KV(c,"globalSafe",BS(g_globalSafe));
   KV(c,"globalSafeReason",g_globalSafeReason);
   KV(c,"nextBasketId",(string)g_nextBasketId);
   for(int i=0; i<AG_LOCK_COUNT; i++)
     {
      string p="l"+(string)i+"_";
      KV(c,p+"active",BS(g_locks[i].active));
      KV(c,p+"time",(string)(long)g_locks[i].triggerTime);
      KV(c,p+"value",DS(g_locks[i].triggerValue));
      KV(c,p+"threshold",DS(g_locks[i].threshold));
      KV(c,p+"date",(string)(long)g_locks[i].lockDate);
      KV(c,p+"reason",g_locks[i].reason);
     }
   for(int s=0; s<AG_SIDES; s++)
     {
      string p="b"+(string)s+"_";
      KV(c,p+"state",(string)g_basket[s].state);
      KV(c,p+"basketId",(string)g_basket[s].basketId);
      KV(c,p+"startTime",(string)(long)g_basket[s].startTime);
      KV(c,p+"equityAtStart",DS(g_basket[s].equityAtStart));
      KV(c,p+"budget",DS(g_basket[s].budget));
      KV(c,p+"effSL",DS(g_basket[s].effSL));
      KV(c,p+"budgetVerified",BS(g_basket[s].budgetVerified));
      KV(c,p+"lastFillTimeMsc",(string)g_basket[s].lastFillTimeMsc);
      KV(c,p+"lastOrderBar",(string)(long)g_basket[s].lastOrderBar);
      KV(c,p+"lastProcessedBar",(string)(long)g_basket[s].lastProcessedBar);
      KV(c,p+"closeReason",(string)g_basket[s].closeReason);
      KV(c,p+"safeMode",BS(g_basket[s].safeMode));
      KV(c,p+"safeReason",g_basket[s].safeReason);
      KV(c,p+"pids",g_basket[s].PidList());
      KV(c,p+"i_kind",(string)g_basket[s].intent.kind);
      KV(c,p+"i_status",(string)g_basket[s].intent.status);
      KV(c,p+"i_magic",(string)g_basket[s].intent.magic);
      KV(c,p+"i_volume",DS(g_basket[s].intent.volume));
      KV(c,p+"i_reqMsc",(string)g_basket[s].intent.requestTimeMsc);
      KV(c,p+"i_order",(string)g_basket[s].intent.orderTicket);
      KV(c,p+"i_deal",(string)g_basket[s].intent.dealTicket);
      KV(c,p+"i_retcode",(string)g_basket[s].intent.retcode);
      KV(c,p+"i_layer",(string)g_basket[s].intent.layer);
     }
   return c;
  }

//--- reads a text file into lines; false when missing/unreadable
bool ReadLines(const string name,string &lines[])
  {
   ArrayResize(lines,0);
   if(!FileIsExist(name))
      return false;
   int h=FileOpen(name,FILE_READ|FILE_TXT|FILE_ANSI|FILE_SHARE_READ);
   if(h==INVALID_HANDLE)
      return false;
   while(!FileIsEnding(h))
     {
      string l=FileReadString(h);
      int n=ArraySize(lines);
      ArrayResize(lines,n+1);
      lines[n]=l;
     }
   FileClose(h);
   return true;
  }

//--- verifies CRC of lines; returns content (without crc line)
bool VerifyLines(const string &lines[],string &content)
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
   string expected=StringSubstr(lines[crcLine],6);
   string actual=StringFormat("%08X",AG_Crc32(content));
   return (expected==actual);
  }

//+------------------------------------------------------------------+
//| Atomic save. Returns false (and blocks new orders) on failure.   |
//+------------------------------------------------------------------+
bool SaveState()
  {
   if(!g_cfg.enablePersistentState)
     {
      g_stateDirty=false;
      g_stateSoftDirty=false;
      return true;
     }
   string content=BuildStateContent();
   string crc=StringFormat("%08X",AG_Crc32(content));
   string tmp=StateFileTmp(),main=StateFileMain(),bak=StateFileBak();
   int h=FileOpen(tmp,FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(h==INVALID_HANDLE)
     {
      g_stateWriteOk=false;
      g_log.Warn("STATE_WRITE_FAILED open tmp err="+(string)GetLastError());
      return false;
     }
   FileWriteString(h,content);
   FileWriteString(h,"crc32="+crc+"\n");
   FileFlush(h);
   FileClose(h);
//--- verify what was written before replacing the main file
   string lines[],back;
   if(!ReadLines(tmp,lines) || !VerifyLines(lines,back))
     {
      g_stateWriteOk=false;
      g_log.Warn("STATE_WRITE_FAILED verify tmp");
      return false;
     }
   if(FileIsExist(main))
      FileCopy(main,0,bak,FILE_REWRITE);
   if(!FileMove(tmp,0,main,FILE_REWRITE))
     {
      g_stateWriteOk=false;
      g_log.Warn("STATE_WRITE_FAILED move err="+(string)GetLastError());
      return false;
     }
   g_stateWriteOk=true;
   g_stateDirty=false;
   g_stateSoftDirty=false;
   g_lastSaveMsc=(long)TimeTradeServer()*1000;
   return true;
  }

//--- critical changes immediately, soft changes (HWM rise, processed bar) throttled 5 s
void PersistIfDirty()
  {
   if(g_stateDirty)
     {
      SaveState();
      return;
     }
   if(g_stateSoftDirty && ((long)TimeTradeServer()*1000-g_lastSaveMsc)>=5000)
      SaveState();
   if(!g_stateWriteOk && !g_stateDirty)
      SaveState();     // keep retrying after a failure
  }

//--- key/value lookup
string KVGet(const string key,bool &found)
  {
   for(int i=0; i<ArraySize(g_kvKeys); i++)
      if(g_kvKeys[i]==key)
        {
         found=true;
         return g_kvVals[i];
        }
   found=false;
   return "";
  }

bool KVStr(const string k,string &v)   { bool f; v=KVGet(k,f); return f; }
bool KVLong(const string k,long &v)    { bool f; string s=KVGet(k,f); if(f) v=StringToInteger(s); return f; }
bool KVDbl(const string k,double &v)   { bool f; string s=KVGet(k,f); if(f) v=StringToDouble(s); return f; }
bool KVBool(const string k,bool &v)    { bool f; string s=KVGet(k,f); if(f) v=(s=="1"); return f; }
bool KVInt(const string k,int &v)      { long t=0; bool f=KVLong(k,t); if(f) v=(int)t; return f; }
bool KVTime(const string k,datetime &v){ long t=0; bool f=KVLong(k,t); if(f) v=(datetime)t; return f; }
bool KVUlong(const string k,ulong &v)  { long t=0; bool f=KVLong(k,t); if(f) v=(ulong)t; return f; }
bool KVUint(const string k,uint &v)    { long t=0; bool f=KVLong(k,t); if(f) v=(uint)t; return f; }

//+------------------------------------------------------------------+
//| Loads state into globals/baskets. Any missing key => CORRUPT.    |
//+------------------------------------------------------------------+
ENUM_LOAD_RESULT LoadState(string &why)
  {
   string main=StateFileMain();
   if(!FileIsExist(main))
     { why="state file missing"; return LOAD_MISSING; }
   string lines[],content;
   if(!ReadLines(main,lines))
     { why="state file unreadable"; return LOAD_CORRUPT; }
   if(!VerifyLines(lines,content))
     { why="state file checksum invalid"; return LOAD_CORRUPT; }
   ArrayResize(g_kvKeys,0);
   ArrayResize(g_kvVals,0);
   for(int i=0; i<ArraySize(lines); i++)
     {
      int p=StringFind(lines[i],"=");
      if(p<=0)
         continue;
      int n=ArraySize(g_kvKeys);
      ArrayResize(g_kvKeys,n+1);
      ArrayResize(g_kvVals,n+1);
      g_kvKeys[n]=StringSubstr(lines[i],0,p);
      g_kvVals[n]=StringSubstr(lines[i],p+1);
     }
   long schema=0,mb=0,ms=0;
   string sym;
   if(!KVLong("schema",schema) || schema!=AG_STATE_SCHEMA)
     { why="state schema mismatch"; return LOAD_CORRUPT; }
   if(!KVStr("symbol",sym) || sym!=g_spec.name || !KVLong("magicBuy",mb) || mb!=g_cfg.magicBuy || !KVLong("magicSell",ms) || ms!=g_cfg.magicSell)
     { why="state identity mismatch (symbol/magic)"; return LOAD_CORRUPT; }

   bool ok=true;
   if(!KVDbl("hwm",g_hwm)) ok=false;
   if(!KVDbl("apBase",g_apBase)) ok=false;
   if(!KVDbl("netFlow",g_netFlow)) ok=false;
   if(!KVTime("flowScanTime",g_flowScanTime)) ok=false;
   if(!KVStr("flowTickets",g_flowTickets)) ok=false;
   if(!KVTime("dayStart",g_dayStart)) ok=false;
   if(!KVDbl("dailySnap",g_dailySnap)) ok=false;
   if(!KVLong("lastResetToken",g_lastResetToken)) ok=false;
   if(!KVBool("globalSafe",g_globalSafe)) ok=false;
   if(!KVStr("globalSafeReason",g_globalSafeReason)) ok=false;
   if(!KVLong("nextBasketId",g_nextBasketId)) ok=false;
   for(int i=0; i<AG_LOCK_COUNT; i++)
     {
      string p="l"+(string)i+"_";
      if(!KVBool(p+"active",g_locks[i].active)) ok=false;
      if(!KVTime(p+"time",g_locks[i].triggerTime)) ok=false;
      if(!KVDbl(p+"value",g_locks[i].triggerValue)) ok=false;
      if(!KVDbl(p+"threshold",g_locks[i].threshold)) ok=false;
      if(!KVTime(p+"date",g_locks[i].lockDate)) ok=false;
      if(!KVStr(p+"reason",g_locks[i].reason)) ok=false;
     }
   for(int s=0; s<AG_SIDES; s++)
     {
      string p="b"+(string)s+"_";
      string pl;
      if(!KVInt(p+"state",g_basket[s].state)) ok=false;
      if(!KVLong(p+"basketId",g_basket[s].basketId)) ok=false;
      if(!KVTime(p+"startTime",g_basket[s].startTime)) ok=false;
      if(!KVDbl(p+"equityAtStart",g_basket[s].equityAtStart)) ok=false;
      if(!KVDbl(p+"budget",g_basket[s].budget)) ok=false;
      if(!KVDbl(p+"effSL",g_basket[s].effSL)) ok=false;
      if(!KVBool(p+"budgetVerified",g_basket[s].budgetVerified)) ok=false;
      if(!KVLong(p+"lastFillTimeMsc",g_basket[s].lastFillTimeMsc)) ok=false;
      if(!KVTime(p+"lastOrderBar",g_basket[s].lastOrderBar)) ok=false;
      if(!KVTime(p+"lastProcessedBar",g_basket[s].lastProcessedBar)) ok=false;
      if(!KVInt(p+"closeReason",g_basket[s].closeReason)) ok=false;
      if(!KVBool(p+"safeMode",g_basket[s].safeMode)) ok=false;
      if(!KVStr(p+"safeReason",g_basket[s].safeReason)) ok=false;
      if(!KVStr(p+"pids",pl)) ok=false;
      g_basket[s].SetPidList(pl);
      if(!KVInt(p+"i_kind",g_basket[s].intent.kind)) ok=false;
      if(!KVInt(p+"i_status",g_basket[s].intent.status)) ok=false;
      if(!KVLong(p+"i_magic",g_basket[s].intent.magic)) ok=false;
      if(!KVDbl(p+"i_volume",g_basket[s].intent.volume)) ok=false;
      if(!KVLong(p+"i_reqMsc",g_basket[s].intent.requestTimeMsc)) ok=false;
      if(!KVUlong(p+"i_order",g_basket[s].intent.orderTicket)) ok=false;
      if(!KVUlong(p+"i_deal",g_basket[s].intent.dealTicket)) ok=false;
      if(!KVUint(p+"i_retcode",g_basket[s].intent.retcode)) ok=false;
      if(!KVInt(p+"i_layer",g_basket[s].intent.layer)) ok=false;
      if(g_basket[s].state<BS_IDLE || g_basket[s].state>BS_SAFE_MODE)
         ok=false;
     }
   if(!ok)
     { why="state file missing keys or invalid values"; return LOAD_CORRUPT; }
   return LOAD_OK;
  }

#endif
//+------------------------------------------------------------------+
