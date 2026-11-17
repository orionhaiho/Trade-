//+------------------------------------------------------------------+
//| LLB_Json.mqh                                                     |
//| Minimal, strict JSON reader for Telegram Bot API responses and   |
//| a string escaper for request bodies.                             |
//| Numbers keep their raw text so 64-bit ids (chat/user/update id)  |
//| are read with StringToInteger without double precision loss.     |
//+------------------------------------------------------------------+
#ifndef LLB_JSON_MQH
#define LLB_JSON_MQH

#include "LLB_Defines.mqh"

#define LLB_JSON_MAX_DEPTH 32

enum ENUM_LLB_JSON_TYPE
  {
   LLB_JSON_NULL   = 0,
   LLB_JSON_BOOL   = 1,
   LLB_JSON_NUMBER = 2,
   LLB_JSON_STRING = 3,
   LLB_JSON_ARRAY  = 4,
   LLB_JSON_OBJECT = 5
  };

//+------------------------------------------------------------------+
class CLLBJson
  {
public:
   int               type;
   string            key;
   string            str;     // string value, or raw number text
   bool              bval;
   CLLBJson         *items[];

                     CLLBJson(void)
     {
      type=LLB_JSON_NULL;
      key="";
      str="";
      bval=false;
     }
                    ~CLLBJson(void) { Clear(); }

   void              Clear(void)
     {
      int n=ArraySize(items);
      for(int i=0; i<n; i++)
         if(CheckPointer(items[i])==POINTER_DYNAMIC)
            delete items[i];
      ArrayResize(items,0);
      type=LLB_JSON_NULL;
      str="";
      bval=false;
     }

   void              Add(CLLBJson *child)
     {
      int n=ArraySize(items);
      ArrayResize(items,n+1);
      items[n]=child;
     }

   int               Count(void) { return ArraySize(items); }

   CLLBJson         *At(const int i)
     {
      if(i<0 || i>=ArraySize(items))
         return NULL;
      return items[i];
     }

   CLLBJson         *Get(const string k)
     {
      if(type!=LLB_JSON_OBJECT)
         return NULL;
      int n=ArraySize(items);
      for(int i=0; i<n; i++)
         if(items[i].key==k)
            return items[i];
      return NULL;
     }

   string            GetStr(const string k,const string def="")
     {
      CLLBJson *c=Get(k);
      if(c==NULL)
         return def;
      if(c.type==LLB_JSON_STRING || c.type==LLB_JSON_NUMBER)
         return c.str;
      return def;
     }

   long              GetLong(const string k,const long def=0)
     {
      CLLBJson *c=Get(k);
      if(c==NULL || c.type!=LLB_JSON_NUMBER)
         return def;
      return StringToInteger(c.str);
     }

   double            GetDouble(const string k,const double def=0.0)
     {
      CLLBJson *c=Get(k);
      if(c==NULL || c.type!=LLB_JSON_NUMBER)
         return def;
      return StringToDouble(c.str);
     }

   bool              GetBoolean(const string k,const bool def=false)
     {
      CLLBJson *c=Get(k);
      if(c==NULL || c.type!=LLB_JSON_BOOL)
         return def;
      return c.bval;
     }

   bool              Parse(const string text,string &err);
  };

//+------------------------------------------------------------------+
class CLLBJsonParser
  {
private:
   string            m_s;
   int               m_n;
   int               m_p;
   string            m_err;

   ushort            Peek(void) { return (m_p<m_n) ? StringGetCharacter(m_s,m_p) : 0; }

   void              SkipWs(void)
     {
      while(m_p<m_n)
        {
         ushort c=StringGetCharacter(m_s,m_p);
         if(c==' ' || c=='\t' || c=='\r' || c=='\n')
            m_p++;
         else
            break;
        }
     }

   bool              Fail(const string why)
     {
      if(m_err=="")
         m_err=why+" at "+IntegerToString(m_p);
      return false;
     }

   int               HexVal(const ushort c)
     {
      if(c>='0' && c<='9')
         return (int)(c-'0');
      if(c>='a' && c<='f')
         return (int)(c-'a')+10;
      if(c>='A' && c<='F')
         return (int)(c-'A')+10;
      return -1;
     }

   bool              ParseString(string &out)
     {
      out="";
      if(Peek()!='"')
         return Fail("expected string");
      m_p++;
      int runStart=m_p;
      while(m_p<m_n)
        {
         ushort c=StringGetCharacter(m_s,m_p);
         if(c=='"')
           {
            if(m_p>runStart)
               out+=StringSubstr(m_s,runStart,m_p-runStart);
            m_p++;
            return true;
           }
         if(c=='\\')
           {
            if(m_p>runStart)
               out+=StringSubstr(m_s,runStart,m_p-runStart);
            m_p++;
            if(m_p>=m_n)
               return Fail("bad escape");
            ushort e=StringGetCharacter(m_s,m_p);
            if(e=='"' || e=='\\' || e=='/')
               out+=ShortToString(e);
            else
               if(e=='b')
                  out+=ShortToString(8);
               else
                  if(e=='f')
                     out+=ShortToString(12);
                  else
                     if(e=='n')
                        out+=ShortToString(10);
                     else
                        if(e=='r')
                           out+=ShortToString(13);
                        else
                           if(e=='t')
                              out+=ShortToString(9);
                           else
                              if(e=='u')
                                {
                                 if(m_p+4>=m_n)
                                    return Fail("bad unicode escape");
                                 int code=0;
                                 for(int k=1; k<=4; k++)
                                   {
                                    int hv=HexVal(StringGetCharacter(m_s,m_p+k));
                                    if(hv<0)
                                       return Fail("bad hex digit");
                                    code=code*16+hv;
                                   }
                                 out+=ShortToString((ushort)code);
                                 m_p+=4;
                                }
                              else
                                 return Fail("unknown escape");
            m_p++;
            runStart=m_p;
            continue;
           }
         m_p++;
        }
      return Fail("unterminated string");
     }

   bool              ParseNumber(string &out)
     {
      int start=m_p;
      while(m_p<m_n)
        {
         ushort c=StringGetCharacter(m_s,m_p);
         if((c>='0' && c<='9') || c=='-' || c=='+' || c=='.' || c=='e' || c=='E')
            m_p++;
         else
            break;
        }
      if(m_p==start)
         return Fail("expected number");
      out=StringSubstr(m_s,start,m_p-start);
      return true;
     }

   bool              ParseLiteral(const string lit)
     {
      int len=StringLen(lit);
      if(m_p+len>m_n || StringSubstr(m_s,m_p,len)!=lit)
         return Fail("bad literal");
      m_p+=len;
      return true;
     }

   bool              ParseValue(CLLBJson *node,const int depth)
     {
      if(depth>LLB_JSON_MAX_DEPTH)
         return Fail("too deep");
      SkipWs();
      ushort c=Peek();
      if(c=='{')
        {
         node.type=LLB_JSON_OBJECT;
         m_p++;
         SkipWs();
         if(Peek()=='}')
           {
            m_p++;
            return true;
           }
         while(true)
           {
            SkipWs();
            string k;
            if(!ParseString(k))
               return false;
            SkipWs();
            if(Peek()!=':')
               return Fail("expected ':'");
            m_p++;
            CLLBJson *child=new CLLBJson();
            child.key=k;
            node.Add(child);
            if(!ParseValue(child,depth+1))
               return false;
            SkipWs();
            ushort d=Peek();
            if(d==',')
              {
               m_p++;
               continue;
              }
            if(d=='}')
              {
               m_p++;
               return true;
              }
            return Fail("expected ',' or '}'");
           }
        }
      if(c=='[')
        {
         node.type=LLB_JSON_ARRAY;
         m_p++;
         SkipWs();
         if(Peek()==']')
           {
            m_p++;
            return true;
           }
         while(true)
           {
            CLLBJson *child=new CLLBJson();
            node.Add(child);
            if(!ParseValue(child,depth+1))
               return false;
            SkipWs();
            ushort d=Peek();
            if(d==',')
              {
               m_p++;
               continue;
              }
            if(d==']')
              {
               m_p++;
               return true;
              }
            return Fail("expected ',' or ']'");
           }
        }
      if(c=='"')
        {
         node.type=LLB_JSON_STRING;
         string s;
         if(!ParseString(s))
            return false;
         node.str=s;
         return true;
        }
      if(c=='t')
        {
         node.type=LLB_JSON_BOOL;
         node.bval=true;
         return ParseLiteral("true");
        }
      if(c=='f')
        {
         node.type=LLB_JSON_BOOL;
         node.bval=false;
         return ParseLiteral("false");
        }
      if(c=='n')
        {
         node.type=LLB_JSON_NULL;
         return ParseLiteral("null");
        }
      if(c=='-' || (c>='0' && c<='9'))
        {
         node.type=LLB_JSON_NUMBER;
         string num;
         if(!ParseNumber(num))
            return false;
         node.str=num;
         return true;
        }
      return Fail("unexpected character");
     }

public:
   bool              Run(const string text,CLLBJson *root,string &err)
     {
      m_s=text;
      m_n=StringLen(text);
      m_p=0;
      m_err="";
      root.Clear();
      bool ok=ParseValue(root,0);
      if(ok)
        {
         SkipWs();
         if(m_p<m_n)
            ok=Fail("trailing characters");
        }
      err=m_err;
      if(!ok)
         root.Clear();
      return ok;
     }
  };

bool CLLBJson::Parse(const string text,string &err)
  {
   CLLBJsonParser parser;
   return parser.Run(text,GetPointer(this),err);
  }

//+------------------------------------------------------------------+
//| JSON string escaping for request bodies                          |
//+------------------------------------------------------------------+
string LLB_JsonEscape(const string s)
  {
   string out="";
   int n=StringLen(s);
   int runStart=0;
   for(int i=0; i<n; i++)
     {
      ushort c=StringGetCharacter(s,i);
      string rep="";
      if(c=='"')
         rep="\\\"";
      else
         if(c=='\\')
            rep="\\\\";
         else
            if(c=='\n')
               rep="\\n";
            else
               if(c=='\r')
                  rep="\\r";
               else
                  if(c=='\t')
                     rep="\\t";
                  else
                     if(c<0x20)
                        rep=StringFormat("\\u%04X",(int)c);
      if(rep!="")
        {
         if(i>runStart)
            out+=StringSubstr(s,runStart,i-runStart);
         out+=rep;
         runStart=i+1;
        }
     }
   if(n>runStart)
      out+=StringSubstr(s,runStart,n-runStart);
   return out;
  }

string LLB_JsonStr(const string s) { return "\""+LLB_JsonEscape(s)+"\""; }

#endif
//+------------------------------------------------------------------+
