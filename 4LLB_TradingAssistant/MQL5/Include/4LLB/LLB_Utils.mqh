//+------------------------------------------------------------------+
//| LLB_Utils.mqh                                                    |
//| Pure helper functions (no globals that hold trading state, no    |
//| trade calls). Unit tested by Scripts/4LLB/4LLB_UnitTests.mq5.    |
//+------------------------------------------------------------------+
#ifndef LLB_UTILS_MQH
#define LLB_UTILS_MQH

#include "LLB_Defines.mqh"

//+------------------------------------------------------------------+
//| Price normalisation by TICK SIZE (not only digits).              |
//| mode: -1 = down, 0 = nearest, +1 = up                            |
//+------------------------------------------------------------------+
double LLB_RoundToTick(const double price,const double tick,const int mode)
  {
   if(tick<=0.0 || !MathIsValidNumber(price))
      return price;
   double q=price/tick;
   double r=0.0;
   if(mode<0)
      r=MathFloor(q+1e-7);
   else
      if(mode>0)
         r=MathCeil(q-1e-7);
      else
         r=MathRound(q);
   return r*tick;
  }

double LLB_NormPrice(const double price,const double tick,const int digits,const int mode)
  {
   return NormalizeDouble(LLB_RoundToTick(price,tick,mode),digits);
  }

//--- grid-price comparisons (tolerance = half a tick)
bool LLB_PriceAbove(const double a,const double b,const double tick)     { return (a-b)>tick*0.5; }
bool LLB_PriceBelow(const double a,const double b,const double tick)     { return (b-a)>tick*0.5; }
bool LLB_PriceEq(const double a,const double b,const double tick)        { return MathAbs(a-b)<=tick*0.5; }
bool LLB_PriceAtOrBelow(const double a,const double b,const double tick) { return a<=b+tick*0.5; }
bool LLB_PriceAtOrAbove(const double a,const double b,const double tick) { return a>=b-tick*0.5; }

//+------------------------------------------------------------------+
//| Volume helpers                                                   |
//+------------------------------------------------------------------+
int LLB_StepDigits(const double step)
  {
   int d=0;
   double s=step;
   while(d<8 && MathAbs(s-MathRound(s))>1e-9)
     {
      s*=10.0;
      d++;
     }
   return d;
  }

double LLB_VolumeDown(const double v,const double step)
  {
   if(step<=0.0 || !MathIsValidNumber(v) || v<=0.0)
      return 0.0;
   double n=MathFloor(v/step+1e-9);
   return NormalizeDouble(n*step,LLB_StepDigits(step));
  }

//--- true only when volume is an exact multiple of step inside [vmin,vmax]; never rounds
bool LLB_IsValidVolume(const double volume,const double vmin,const double vmax,const double step)
  {
   if(step<=0.0 || vmin<=0.0 || vmax<vmin)
      return false;
   if(!MathIsValidNumber(volume) || volume<=0.0)
      return false;
   double steps=MathRound(volume/step);
   if(MathAbs(steps*step-volume)>step*1e-6)
      return false;
   if(volume<vmin-step*1e-6)
      return false;
   if(volume>vmax+step*1e-6)
      return false;
   return true;
  }

//--- RiskPercent volume: rounds DOWN, never above the risk budget; 0 => refuse
double LLB_CalcRiskLots(const double riskMoney,const double lossPerLot,const double vmin,const double vmax,const double step,string &why)
  {
   why="";
   if(!MathIsValidNumber(riskMoney) || riskMoney<=0.0)
     { why="RISK_MONEY_INVALID"; return 0.0; }
   if(!MathIsValidNumber(lossPerLot) || lossPerLot<=0.0)
     { why="LOSS_PER_LOT_INVALID"; return 0.0; }
   if(step<=0.0 || vmin<=0.0 || vmax<vmin)
     { why="SYMBOL_VOLUME_SPEC_INVALID"; return 0.0; }
   double raw=riskMoney/lossPerLot;
   double lots=LLB_VolumeDown(raw,step);
   if(lots>vmax)
      lots=LLB_VolumeDown(vmax,step);
   if(lots<vmin-step*1e-6)
     {
      why=StringFormat("RISK_LOTS_BELOW_MIN raw=%.4f min=%.4f",raw,vmin);
      return 0.0;
     }
   return lots;
  }

//+------------------------------------------------------------------+
//| String helpers                                                   |
//+------------------------------------------------------------------+
string LLB_Trim(string s)
  {
   StringTrimLeft(s);
   StringTrimRight(s);
   return s;
  }

//--- CSV field: ';' is the separator, CR/LF break lines
string LLB_CsvClean(string s)
  {
   StringReplace(s,";",",");
   StringReplace(s,"\r"," ");
   StringReplace(s,"\n"," ");
   return s;
  }

string LLB_D(const double v,const int digits)
  {
   if(!MathIsValidNumber(v))
      return "0";
   return DoubleToString(v,digits);
  }

bool LLB_IsIntegerString(const string s)
  {
   int n=StringLen(s);
   if(n==0 || n>20)
      return false;
   for(int i=0; i<n; i++)
     {
      ushort c=StringGetCharacter(s,i);
      if(i==0 && c=='-' && n>1)
         continue;
      if(c<'0' || c>'9')
         return false;
     }
   return true;
  }

string LLB_Truncate(const string s,const int maxLen)
  {
   if(StringLen(s)<=maxLen)
      return s;
   return StringSubstr(s,0,maxLen);
  }

//+------------------------------------------------------------------+
//| Hashes                                                           |
//+------------------------------------------------------------------+
uint g_llbCrcTable[256];
bool g_llbCrcReady=false;

void LLB_CrcInit(void)
  {
   for(uint i=0; i<256; i++)
     {
      uint c=i;
      for(int k=0; k<8; k++)
         c=((c&1)!=0) ? (0xEDB88320^(c>>1)) : (c>>1);
      g_llbCrcTable[i]=c;
     }
   g_llbCrcReady=true;
  }

uint LLB_Crc32(const string s)
  {
   if(!g_llbCrcReady)
      LLB_CrcInit();
   uint crc=0xFFFFFFFF;
   int n=StringLen(s);
   for(int i=0; i<n; i++)
     {
      ushort ch=StringGetCharacter(s,i);
      crc=g_llbCrcTable[(crc^(uint)(ch&0xFF))&0xFF]^(crc>>8);
      crc=g_llbCrcTable[(crc^(uint)(ch>>8))&0xFF]^(crc>>8);
     }
   return crc^0xFFFFFFFF;
  }

uint LLB_Fnv1a(const string s)
  {
   uint h=0x811C9DC5;
   int n=StringLen(s);
   for(int i=0; i<n; i++)
     {
      ushort c=StringGetCharacter(s,i);
      h^=(uint)(c&0xFF);
      h*=0x01000193;
      h^=(uint)(c>>8);
      h*=0x01000193;
     }
   return h;
  }

string LLB_Hex32(const uint v) { return StringFormat("%08X",v); }

//+------------------------------------------------------------------+
//| Time helpers (broker server time everywhere)                     |
//+------------------------------------------------------------------+
string LLB_TimeStr(const datetime t)
  {
   if(t<=0)
      return "-";
   return TimeToString(t,TIME_DATE|TIME_SECONDS);
  }

string LLB_HMS(const datetime t)
  {
   if(t<=0)
      return "-";
   return TimeToString(t,TIME_SECONDS);
  }

int LLB_Date8(const datetime t)
  {
   MqlDateTime d;
   TimeToStruct(t,d);
   return d.year*10000+d.mon*100+d.day;
  }

datetime LLB_DayStart(const datetime t)
  {
   return (datetime)(((long)t/86400)*86400);
  }

//--- monotonic milliseconds for throttling: real time live, simulated time in the Strategy Tester
long LLB_NowMs(void)
  {
   if((bool)MQLInfoInteger(MQL_TESTER))
      return (long)TimeCurrent()*1000;
   return (long)GetTickCount64();
  }

//+------------------------------------------------------------------+
//| Names <-> codes                                                  |
//+------------------------------------------------------------------+
string LLB_StrategyName(const int s)
  {
   if(s==LLB_STRAT_SWEEP)
      return "SWEEP";
   if(s==LLB_STRAT_BREAKOUT)
      return "BREAKOUT";
   return "UNKNOWN";
  }

int LLB_StrategyFromName(const string n)
  {
   if(n=="SWEEP")
      return LLB_STRAT_SWEEP;
   if(n=="BREAKOUT")
      return LLB_STRAT_BREAKOUT;
   return -1;
  }

string LLB_DirName(const int d)
  {
   if(d==LLB_DIR_BUY)
      return "BUY";
   if(d==LLB_DIR_SELL)
      return "SELL";
   return "NONE";
  }

int LLB_DirFromName(const string n)
  {
   if(n=="BUY")
      return LLB_DIR_BUY;
   if(n=="SELL")
      return LLB_DIR_SELL;
   return -1;
  }

string LLB_LevelName(const int l)
  {
   switch(l)
     {
      case LLB_LVL_P1:
         return "P1";
      case LLB_LVL_P2:
         return "P2";
      case LLB_LVL_P3:
         return "P3";
      case LLB_LVL_P4:
         return "P4";
     }
   return "NONE";
  }

string LLB_LevelLabel(const int l)
  {
   switch(l)
     {
      case LLB_LVL_P1:
         return "P1 (PDH)";
      case LLB_LVL_P2:
         return "P2 (PDL)";
      case LLB_LVL_P3:
         return "P3 (swing low < PDL)";
      case LLB_LVL_P4:
         return "P4 (swing high > PDH)";
     }
   return "NONE";
  }

int LLB_LevelFromName(const string n)
  {
   for(int i=LLB_LVL_P1; i<=LLB_LVL_P4; i++)
      if(LLB_LevelName(i)==n)
         return i;
   return LLB_LVL_NONE;
  }

string LLB_ProposalStateName(const int s)
  {
   switch(s)
     {
      case LLB_PS_ACTIVE:
         return "ACTIVE";
      case LLB_PS_ACCEPTED:
         return "ACCEPTED";
      case LLB_PS_REJECTED:
         return "REJECTED";
      case LLB_PS_EXPIRED:
         return "EXPIRED";
      case LLB_PS_INVALIDATED:
         return "INVALIDATED";
      case LLB_PS_EXECUTING:
         return "EXECUTING";
      case LLB_PS_EXECUTED:
         return "EXECUTED";
      case LLB_PS_EXECUTION_FAILED:
         return "EXECUTION_FAILED";
     }
   return "UNKNOWN";
  }

int LLB_ProposalStateFromName(const string n)
  {
   for(int i=0; i<LLB_PS_COUNT; i++)
      if(LLB_ProposalStateName(i)==n)
         return i;
   return -1;
  }

string LLB_ExecStateName(const int s)
  {
   switch(s)
     {
      case LLB_EX_NONE:
         return "NONE";
      case LLB_EX_PRECHECK_FAILED:
         return "PRECHECK_FAILED";
      case LLB_EX_SUBMITTING:
         return "SUBMITTING";
      case LLB_EX_PLACED:
         return "PLACED";
      case LLB_EX_REJECTED:
         return "REJECTED";
      case LLB_EX_UNKNOWN:
         return "UNKNOWN";
      case LLB_EX_NOT_FOUND:
         return "NOT_FOUND";
     }
   return "INVALID";
  }

int LLB_ExecStateFromName(const string n)
  {
   for(int i=0; i<LLB_EX_COUNT; i++)
      if(LLB_ExecStateName(i)==n)
         return i;
   return -1;
  }

string LLB_OrderStateName(const int s)
  {
   switch(s)
     {
      case LLB_OS_NONE:
         return "NONE";
      case LLB_OS_PENDING:
         return "PENDING";
      case LLB_OS_PARTIAL:
         return "PARTIAL";
      case LLB_OS_FILLED:
         return "FILLED";
      case LLB_OS_EXPIRED:
         return "EXPIRED";
      case LLB_OS_CANCELLED_EA:
         return "CANCELLED_EA";
      case LLB_OS_CANCELLED_EXT:
         return "CANCELLED_EXT";
      case LLB_OS_REJECTED:
         return "REJECTED";
     }
   return "INVALID";
  }

int LLB_OrderStateFromName(const string n)
  {
   for(int i=0; i<LLB_OS_COUNT; i++)
      if(LLB_OrderStateName(i)==n)
         return i;
   return -1;
  }

string LLB_PosStateName(const int s)
  {
   switch(s)
     {
      case LLB_POS_OPEN:
         return "OPEN";
      case LLB_POS_CLOSING:
         return "CLOSING";
      case LLB_POS_CLOSED:
         return "CLOSED";
     }
   return "INVALID";
  }

int LLB_PosStateFromName(const string n)
  {
   for(int i=0; i<LLB_POS_COUNT; i++)
      if(LLB_PosStateName(i)==n)
         return i;
   return -1;
  }

string LLB_StructStateName(const int s) { return (s==LLB_ST_INVALIDATED) ? "INVALIDATED" : "INTACT"; }
int    LLB_StructStateFromName(const string n) { return (n=="INVALIDATED") ? LLB_ST_INVALIDATED : LLB_ST_INTACT; }
string LLB_OwnershipName(const int s) { return (s==LLB_OWN_CONFLICT) ? "CONFLICT" : "OK"; }
int    LLB_OwnershipFromName(const string n) { return (n=="CONFLICT") ? LLB_OWN_CONFLICT : LLB_OWN_OK; }

string LLB_CloseReasonName(const int r)
  {
   switch(r)
     {
      case LLB_CR_NONE:
         return "NONE";
      case LLB_CR_SL:
         return "SL";
      case LLB_CR_TP:
         return "TP";
      case LLB_CR_INVALIDATION:
         return "INVALIDATION";
      case LLB_CR_MANUAL:
         return "MANUAL";
      case LLB_CR_STOP_OUT:
         return "STOP_OUT";
      case LLB_CR_EA_OTHER:
         return "EA_OTHER";
      case LLB_CR_SLTP_UNSETTABLE:
         return "SLTP_UNSETTABLE";
      case LLB_CR_OTHER:
         return "OTHER";
     }
   return "INVALID";
  }

int LLB_CloseReasonFromName(const string n)
  {
   for(int i=0; i<LLB_CR_COUNT; i++)
      if(LLB_CloseReasonName(i)==n)
         return i;
   return LLB_CR_NONE;
  }

string LLB_DecisionName(const int d)
  {
   if(d==LLB_DEC_ACCEPT)
      return "ACCEPT";
   if(d==LLB_DEC_REJECT)
      return "REJECT";
   return "NONE";
  }

int LLB_DecisionFromName(const string n)
  {
   if(n=="ACCEPT")
      return LLB_DEC_ACCEPT;
   if(n=="REJECT")
      return LLB_DEC_REJECT;
   return LLB_DEC_NONE;
  }

string LLB_OrderTypeName(const int t)
  {
   if(t==ORDER_TYPE_BUY_STOP)
      return "BUY_STOP";
   if(t==ORDER_TYPE_SELL_STOP)
      return "SELL_STOP";
   if(t==ORDER_TYPE_BUY)
      return "BUY";
   if(t==ORDER_TYPE_SELL)
      return "SELL";
   return "OTHER";
  }

int LLB_OrderTypeFromName(const string n)
  {
   if(n=="BUY_STOP")
      return ORDER_TYPE_BUY_STOP;
   if(n=="SELL_STOP")
      return ORDER_TYPE_SELL_STOP;
   if(n=="BUY")
      return ORDER_TYPE_BUY;
   if(n=="SELL")
      return ORDER_TYPE_SELL;
   return -1;
  }

//+------------------------------------------------------------------+
//| Signal / execution identity                                      |
//| Signal ID: 4LLB-<SYMBOL>-<STRATEGY>-<DIR>-<YYYYMMDD>-<NNNN>      |
//| Execution ID (1-1): E<YYMMDD><NNNN>; order comment 4LLB|<ExecID> |
//+------------------------------------------------------------------+
string LLB_MakeSignalId(const string sym,const int strategy,const int dir,const int date8,const int seq)
  {
   return StringFormat("4LLB-%s-%s-%s-%08d-%04d",sym,LLB_StrategyName(strategy),LLB_DirName(dir),date8,seq);
  }

bool LLB_ParseSignalId(const string id,string &sym,int &strategy,int &dir,int &date8,int &seq)
  {
   sym="";
   strategy=-1;
   dir=-1;
   date8=0;
   seq=0;
   string parts[];
   int n=StringSplit(id,(ushort)'-',parts);
   if(n<6 || parts[0]!="4LLB")
      return false;
   string sSeq=parts[n-1];
   string sDate=parts[n-2];
   if(StringLen(sSeq)<4 || !LLB_IsIntegerString(sSeq) || StringLen(sDate)!=8 || !LLB_IsIntegerString(sDate))
      return false;
   seq=(int)StringToInteger(sSeq);
   date8=(int)StringToInteger(sDate);
   dir=LLB_DirFromName(parts[n-3]);
   strategy=LLB_StrategyFromName(parts[n-4]);
   if(seq<=0 || dir<0 || strategy<0 || date8<19700101)
      return false;
   sym=parts[1];
   for(int i=2; i<=n-5; i++)
      sym+="-"+parts[i];
   return (StringLen(sym)>0);
  }

string LLB_ExecIdFromSignalId(const string id)
  {
   string sym;
   int st,dir,d8,seq;
   if(!LLB_ParseSignalId(id,sym,st,dir,d8,seq))
      return "";
   return StringFormat("E%06d%04d",d8%1000000,seq);
  }

bool LLB_ParseExecId(const string execId,int &date6,int &seq)
  {
   date6=0;
   seq=0;
   int n=StringLen(execId);
   if(n<11 || n>16 || StringGetCharacter(execId,0)!='E')
      return false;
   string d=StringSubstr(execId,1,6);
   string s=StringSubstr(execId,7);
   if(!LLB_IsIntegerString(d) || !LLB_IsIntegerString(s) || StringGetCharacter(s,0)=='-')
      return false;
   date6=(int)StringToInteger(d);
   seq=(int)StringToInteger(s);
   return (seq>0);
  }

//--- extracts the execution id from an entry order comment "4LLB|E2611170001"
bool LLB_ExecIdFromComment(const string comment,string &execId)
  {
   execId="";
   if(StringFind(comment,LLB_COMMENT_PREFIX)!=0)
      return false;
   string rest=StringSubstr(comment,StringLen(LLB_COMMENT_PREFIX));
   int q=StringFind(rest,"|");
   if(q>=0)
      rest=StringSubstr(rest,0,q);
   q=StringFind(rest," ");
   if(q>=0)
      rest=StringSubstr(rest,0,q);
   int d6,seq;
   if(!LLB_ParseExecId(rest,d6,seq))
      return false;
   execId=rest;
   return true;
  }

string LLB_EntryComment(const string execId) { return LLB_COMMENT_PREFIX+execId; }
string LLB_CloseComment(const string execId) { return LLB_COMMENT_PREFIX+"C"+StringSubstr(execId,1); }

//--- callback data "ACCEPT|<SignalID>" / "REJECT|<SignalID>" (Telegram limit 64 bytes)
bool LLB_ParseCallbackData(const string data,int &decision,string &signalId)
  {
   decision=LLB_DEC_NONE;
   signalId="";
   if(StringLen(data)<8 || StringLen(data)>64)
      return false;
   int p=StringFind(data,"|");
   if(p<=0)
      return false;
   string a=StringSubstr(data,0,p);
   string id=StringSubstr(data,p+1);
   if(StringFind(id,"|")>=0)
      return false;
   if(a=="ACCEPT")
      decision=LLB_DEC_ACCEPT;
   else
      if(a=="REJECT")
         decision=LLB_DEC_REJECT;
      else
         return false;
   string sym;
   int st,dir,d8,seq;
   if(!LLB_ParseSignalId(id,sym,st,dir,d8,seq))
     {
      decision=LLB_DEC_NONE;
      return false;
     }
   signalId=id;
   return true;
  }

//--- "123, -100456" -> ids. Returns count, or -1 when any entry is invalid.
int LLB_ParseIdList(const string csv,long &ids[])
  {
   ArrayResize(ids,0);
   string parts[];
   int n=StringSplit(csv,(ushort)',',parts);
   for(int i=0; i<n; i++)
     {
      string s=LLB_Trim(parts[i]);
      if(s=="")
         continue;
      if(!LLB_IsIntegerString(s))
         return -1;
      long v=StringToInteger(s);
      if(v==0)
         return -1;
      int k=ArraySize(ids);
      ArrayResize(ids,k+1);
      ids[k]=v;
     }
   return ArraySize(ids);
  }

bool LLB_IdInList(const long id,const long &ids[])
  {
   if(id==0)
      return false;
   for(int i=0; i<ArraySize(ids); i++)
      if(ids[i]==id)
         return true;
   return false;
  }

//+------------------------------------------------------------------+
//| Proposal state machine (Phase 2 §3.1)                            |
//+------------------------------------------------------------------+
bool LLB_CanTransition(const int from,const int to)
  {
   switch(from)
     {
      case LLB_PS_ACTIVE:
         return (to==LLB_PS_ACCEPTED || to==LLB_PS_REJECTED || to==LLB_PS_EXPIRED || to==LLB_PS_INVALIDATED);
      case LLB_PS_ACCEPTED:
         return (to==LLB_PS_EXECUTING || to==LLB_PS_EXECUTED || to==LLB_PS_EXECUTION_FAILED);
      case LLB_PS_EXECUTING:
         return (to==LLB_PS_EXECUTED || to==LLB_PS_EXECUTION_FAILED);
      case LLB_PS_EXECUTION_FAILED:
         return (to==LLB_PS_EXECUTED);   // late reconciliation correction only
     }
   return false;
  }

bool LLB_IsTerminalProposal(const int s)
  {
   return (s==LLB_PS_REJECTED || s==LLB_PS_EXPIRED || s==LLB_PS_INVALIDATED || s==LLB_PS_EXECUTED || s==LLB_PS_EXECUTION_FAILED);
  }

bool LLB_IsInFlightProposal(const int s)
  {
   return (s==LLB_PS_ACCEPTED || s==LLB_PS_EXECUTING);
  }

//+------------------------------------------------------------------+
//| Trade return codes                                               |
//+------------------------------------------------------------------+
bool LLB_IsRetcodeAccepted(const uint rc)
  {
   return (rc==TRADE_RETCODE_PLACED || rc==TRADE_RETCODE_DONE || rc==TRADE_RETCODE_DONE_PARTIAL);
  }

//--- request definitely NOT executed by the server
bool LLB_IsRetcodeClearReject(const uint rc)
  {
   switch(rc)
     {
      case TRADE_RETCODE_REQUOTE:
      case TRADE_RETCODE_REJECT:
      case TRADE_RETCODE_CANCEL:
      case TRADE_RETCODE_INVALID:
      case TRADE_RETCODE_INVALID_VOLUME:
      case TRADE_RETCODE_INVALID_PRICE:
      case TRADE_RETCODE_INVALID_STOPS:
      case TRADE_RETCODE_TRADE_DISABLED:
      case TRADE_RETCODE_MARKET_CLOSED:
      case TRADE_RETCODE_NO_MONEY:
      case TRADE_RETCODE_PRICE_CHANGED:
      case TRADE_RETCODE_PRICE_OFF:
      case TRADE_RETCODE_INVALID_EXPIRATION:
      case TRADE_RETCODE_ORDER_CHANGED:
      case TRADE_RETCODE_TOO_MANY_REQUESTS:
      case TRADE_RETCODE_NO_CHANGES:
      case TRADE_RETCODE_SERVER_DISABLES_AT:
      case TRADE_RETCODE_CLIENT_DISABLES_AT:
      case TRADE_RETCODE_LOCKED:
      case TRADE_RETCODE_FROZEN:
      case TRADE_RETCODE_INVALID_FILL:
      case TRADE_RETCODE_ONLY_REAL:
      case TRADE_RETCODE_LIMIT_ORDERS:
      case TRADE_RETCODE_LIMIT_VOLUME:
      case TRADE_RETCODE_INVALID_ORDER:
      case TRADE_RETCODE_POSITION_CLOSED:
         return true;
     }
//--- 10038..10046 (INVALID_CLOSE_VOLUME .. HEDGE_PROHIBITED) by value for older builds
   if(rc>=10038 && rc<=10046)
      return true;
   return false;
  }

string LLB_RetcodeText(const uint rc)
  {
   switch(rc)
     {
      case 0:
         return "NO_RESULT";
      case TRADE_RETCODE_REQUOTE:
         return "REQUOTE";
      case TRADE_RETCODE_REJECT:
         return "REJECT";
      case TRADE_RETCODE_CANCEL:
         return "CANCEL";
      case TRADE_RETCODE_PLACED:
         return "PLACED";
      case TRADE_RETCODE_DONE:
         return "DONE";
      case TRADE_RETCODE_DONE_PARTIAL:
         return "DONE_PARTIAL";
      case TRADE_RETCODE_ERROR:
         return "ERROR";
      case TRADE_RETCODE_TIMEOUT:
         return "TIMEOUT";
      case TRADE_RETCODE_INVALID:
         return "INVALID";
      case TRADE_RETCODE_INVALID_VOLUME:
         return "INVALID_VOLUME";
      case TRADE_RETCODE_INVALID_PRICE:
         return "INVALID_PRICE";
      case TRADE_RETCODE_INVALID_STOPS:
         return "INVALID_STOPS";
      case TRADE_RETCODE_TRADE_DISABLED:
         return "TRADE_DISABLED";
      case TRADE_RETCODE_MARKET_CLOSED:
         return "MARKET_CLOSED";
      case TRADE_RETCODE_NO_MONEY:
         return "NO_MONEY";
      case TRADE_RETCODE_PRICE_CHANGED:
         return "PRICE_CHANGED";
      case TRADE_RETCODE_PRICE_OFF:
         return "PRICE_OFF";
      case TRADE_RETCODE_INVALID_EXPIRATION:
         return "INVALID_EXPIRATION";
      case TRADE_RETCODE_ORDER_CHANGED:
         return "ORDER_CHANGED";
      case TRADE_RETCODE_TOO_MANY_REQUESTS:
         return "TOO_MANY_REQUESTS";
      case TRADE_RETCODE_NO_CHANGES:
         return "NO_CHANGES";
      case TRADE_RETCODE_SERVER_DISABLES_AT:
         return "SERVER_DISABLES_AT";
      case TRADE_RETCODE_CLIENT_DISABLES_AT:
         return "CLIENT_DISABLES_AT";
      case TRADE_RETCODE_LOCKED:
         return "LOCKED";
      case TRADE_RETCODE_FROZEN:
         return "FROZEN";
      case TRADE_RETCODE_INVALID_FILL:
         return "INVALID_FILL";
      case TRADE_RETCODE_CONNECTION:
         return "CONNECTION";
      case TRADE_RETCODE_ONLY_REAL:
         return "ONLY_REAL";
      case TRADE_RETCODE_LIMIT_ORDERS:
         return "LIMIT_ORDERS";
      case TRADE_RETCODE_LIMIT_VOLUME:
         return "LIMIT_VOLUME";
      case TRADE_RETCODE_INVALID_ORDER:
         return "INVALID_ORDER";
      case TRADE_RETCODE_POSITION_CLOSED:
         return "POSITION_CLOSED";
      case 10038:
         return "INVALID_CLOSE_VOLUME";
      case 10039:
         return "CLOSE_ORDER_EXIST";
      case 10040:
         return "LIMIT_POSITIONS";
      case 10041:
         return "REJECT_CANCEL";
      case 10042:
         return "LONG_ONLY";
      case 10043:
         return "SHORT_ONLY";
      case 10044:
         return "CLOSE_ONLY";
      case 10045:
         return "FIFO_CLOSE";
      case 10046:
         return "HEDGE_PROHIBITED";
     }
   return "RC_"+(string)rc;
  }

//+------------------------------------------------------------------+
//| Touch-based structure invalidation (SRS 4.5)                     |
//| BUY: Bid <= swing low ; SELL: Ask >= swing high.                 |
//| Ticks older than fromMsc are only used to carry bid/ask forward. |
//+------------------------------------------------------------------+
bool LLB_FindTouch(const MqlTick &ticks[],const int count,const int dir,const double level,const long fromMsc,
                   const double tick,long &touchMsc,double &touchPrice)
  {
   touchMsc=0;
   touchPrice=0.0;
   if(level<=0.0)
      return false;
   double tol=(tick>0.0) ? tick*0.5 : 0.0;
   double lastBid=0.0,lastAsk=0.0;
   int n=MathMin(count,ArraySize(ticks));
   for(int i=0; i<n; i++)
     {
      if(ticks[i].bid>0.0)
         lastBid=ticks[i].bid;
      if(ticks[i].ask>0.0)
         lastAsk=ticks[i].ask;
      if(ticks[i].time_msc<fromMsc)
         continue;
      if(dir==LLB_DIR_BUY)
        {
         if(lastBid>0.0 && lastBid<=level+tol)
           {
            touchMsc=ticks[i].time_msc;
            touchPrice=lastBid;
            return true;
           }
        }
      else
        {
         if(lastAsk>0.0 && lastAsk>=level-tol)
           {
            touchMsc=ticks[i].time_msc;
            touchPrice=lastAsk;
            return true;
           }
        }
     }
   return false;
  }

//--- broker SL present and not WIDER than the approved SL (BUY: sl >= approved, SELL: sl <= approved)
bool LLB_SlWithinApproved(const int dir,const double curSl,const double approvedSl,const double tick)
  {
   if(curSl<=0.0 || approvedSl<=0.0)
      return false;
   if(dir==LLB_DIR_BUY)
      return LLB_PriceAtOrAbove(curSl,approvedSl,tick);
   return LLB_PriceAtOrBelow(curSl,approvedSl,tick);
  }

//--- single quote check (backstop between tick scans)
bool LLB_QuoteTouches(const int dir,const double level,const double bid,const double ask,const double tick)
  {
   if(level<=0.0)
      return false;
   double tol=(tick>0.0) ? tick*0.5 : 0.0;
   if(dir==LLB_DIR_BUY)
      return (bid>0.0 && bid<=level+tol);
   return (ask>0.0 && ask>=level-tol);
  }

//+------------------------------------------------------------------+
//| Icons (BMP code points; source stays ASCII)                      |
//+------------------------------------------------------------------+
string LLB_IconNew(void)     { return ShortToString(0x26A1); }  // high voltage
string LLB_IconOk(void)      { return ShortToString(0x2705); }  // check mark button
string LLB_IconNo(void)      { return ShortToString(0x274C); }  // cross mark
string LLB_IconWarn(void)    { return ShortToString(0x26A0); }  // warning sign
string LLB_IconStop(void)    { return ShortToString(0x26D4); }  // no entry
string LLB_IconClock(void)   { return ShortToString(0x23F0); }  // alarm clock
string LLB_IconInfo(void)    { return ShortToString(0x2139); }  // information source

#endif
//+------------------------------------------------------------------+
