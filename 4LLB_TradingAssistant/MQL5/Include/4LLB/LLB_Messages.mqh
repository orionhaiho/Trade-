//+------------------------------------------------------------------+
//| LLB_Messages.mqh                                                 |
//| Telegram / dashboard text formatting (pure, ASCII source).       |
//| Message content per SRS 4.7: Symbol, Strategy, Direction, Level, |
//| Entry, SL, TP, RR, Expiration, Signal ID, Reason (+ extra fields |
//| of SRS 4.6: ATR, Bid/Ask, Spread, Created, Reference Swing).     |
//+------------------------------------------------------------------+
#ifndef LLB_MESSAGES_MQH
#define LLB_MESSAGES_MQH

#include "LLB_Defines.mqh"
#include "LLB_Utils.mqh"

string LLB_TfName(const ENUM_TIMEFRAMES tf)
  {
   string s=EnumToString(tf);
   StringReplace(s,"PERIOD_","");
   return s;
  }

string LLB_StateIcon(const int state)
  {
   switch(state)
     {
      case LLB_PS_ACTIVE:
         return LLB_IconNew();
      case LLB_PS_ACCEPTED:
      case LLB_PS_EXECUTING:
         return LLB_IconInfo();
      case LLB_PS_EXECUTED:
         return LLB_IconOk();
      case LLB_PS_REJECTED:
         return LLB_IconNo();
      case LLB_PS_EXPIRED:
         return LLB_IconClock();
      case LLB_PS_INVALIDATED:
         return LLB_IconStop();
      case LLB_PS_EXECUTION_FAILED:
         return LLB_IconWarn();
     }
   return "";
  }

string LLB_FormatProposal(const LLBTradeProposal &p,const ENUM_TIMEFRAMES atrTf)
  {
   int d=p.digits;
   bool buy=(p.direction==LLB_DIR_BUY);
   string s=LLB_IconNew()+" 4LLB PROPOSAL - "+LLB_DirName(p.direction)+" "+p.symbol+"\n";
   s+="Signal ID: "+p.signalId+"\n";
   s+="Symbol: "+p.symbol+"\n";
   s+="Strategy: "+LLB_StrategyName(p.strategy)+"\n";
   s+="Direction: "+LLB_DirName(p.direction)+" ("+(buy ? "Buy Stop" : "Sell Stop")+" pending order)\n";
   s+="Level: "+LLB_LevelLabel(p.level)+" = "+DoubleToString(p.levelPrice,d)+"\n";
   s+="Entry: "+DoubleToString(p.entry,d)+"\n";
   s+="SL: "+DoubleToString(p.sl,d)+"\n";
   s+="TP: "+DoubleToString(p.tp,d)+"\n";
   s+="RR: 1:"+DoubleToString(p.rr,2)+"\n";
   s+="ATR(14,"+LLB_TfName(atrTf)+"): "+DoubleToString(p.atr,d)+"\n";
   s+="Bid/Ask: "+DoubleToString(p.bid,d)+" / "+DoubleToString(p.ask,d)+" | Spread: "+IntegerToString(p.spreadPoints)+" pts\n";
   s+="Reference swing: "+DoubleToString(p.refSwingPrice,d)+" ("+(buy ? "low" : "high")+" @ "+LLB_TimeStr(p.refSwingTime)+")\n";
   s+="Invalidation: "+(buy ? "Bid <= " : "Ask >= ")+DoubleToString(p.refSwingPrice,d)+" (touch)\n";
   s+="Created: "+LLB_TimeStr(p.createdTime)+" (server)\n";
   s+="Expiration: "+LLB_TimeStr(p.expiresTime)+" (server, "+IntegerToString((int)(((long)p.expiresTime-(long)p.createdTime)/60))+" min)\n";
   s+="Reason: "+p.reason;
   if((buy && p.ask>0.0 && p.ask>=p.entry) || (!buy && p.bid>0.0 && p.bid<=p.entry))
      s+="\n"+LLB_IconWarn()+" Price is already beyond Entry: ACCEPT will be refused unless price returns (no market orders).";
   return s;
  }

string LLB_FormatProposalStatus(const LLBTradeProposal &p,const ENUM_TIMEFRAMES atrTf)
  {
   string s=LLB_FormatProposal(p,atrTf);
   s+="\n\n"+LLB_StateIcon(p.state)+" STATUS: "+LLB_ProposalStateName(p.state);
   if(p.decision!=LLB_DEC_NONE)
      s+=" | decision "+LLB_DecisionName(p.decision)+" by "+IntegerToString(p.decisionUser)+" at "+LLB_TimeStr(p.decisionTime);
   if(p.stateReason!="")
      s+="\n"+p.stateReason;
   return s;
  }

string LLB_Countdown(const long seconds)
  {
   if(seconds<=0)
      return "0:00";
   int m=(int)(seconds/60);
   int s=(int)(seconds%60);
   return StringFormat("%d:%02d",m,s);
  }

#endif
//+------------------------------------------------------------------+
