//+------------------------------------------------------------------+
//| LLB_Logger.mqh                                                   |
//| Levelled log to the Experts journal + daily file.                |
//| Every registered secret (Telegram bot token) is replaced by ***  |
//| before anything is printed or written (R-SEC-02).                |
//+------------------------------------------------------------------+
#ifndef LLB_LOGGER_MQH
#define LLB_LOGGER_MQH

#include "LLB_Defines.mqh"
#include "LLB_Utils.mqh"

class CLLBLogger
  {
private:
   int               m_level;
   bool              m_toFile;
   bool              m_tester;
   string            m_folder;
   int               m_handle;
   int               m_fileDate;
   string            m_secrets[];

   void              OpenFile(const datetime now)
     {
      int d=LLB_Date8(now);
      if(m_handle!=INVALID_HANDLE && d==m_fileDate)
         return;
      if(m_handle!=INVALID_HANDLE)
        {
         FileClose(m_handle);
         m_handle=INVALID_HANDLE;
        }
      string name=m_folder+"\\logs\\4LLB_"+IntegerToString(d)+".log";
      m_handle=FileOpen(name,FILE_READ|FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_SHARE_READ);
      if(m_handle==INVALID_HANDLE)
        {
         Print("[4LLB][WARN] log file open failed err=",GetLastError());
         m_toFile=false;
         return;
        }
      FileSeek(m_handle,0,SEEK_END);
      m_fileDate=d;
     }

public:
                     CLLBLogger(void)
     {
      m_level=LLB_LOG_INFO;
      m_toFile=false;
      m_tester=false;
      m_folder="";
      m_handle=INVALID_HANDLE;
      m_fileDate=0;
     }

   void              Init(const int level,const bool toFile,const string folder,const bool tester)
     {
      m_level=level;
      m_tester=tester;
      m_folder=folder;
      m_toFile=(toFile && folder!="");
      if(m_toFile)
        {
         FolderCreate(m_folder+"\\logs",0);
         OpenFile(TimeTradeServer());
        }
     }

   void              Deinit(void)
     {
      if(m_handle!=INVALID_HANDLE)
        {
         FileFlush(m_handle);
         FileClose(m_handle);
         m_handle=INVALID_HANDLE;
        }
     }

   void              SetLevel(const int level) { m_level=level; }

   void              AddSecret(const string s)
     {
      if(StringLen(s)<6)
         return;
      int n=ArraySize(m_secrets);
      ArrayResize(m_secrets,n+1);
      m_secrets[n]=s;
     }

   string            Redact(string s)
     {
      for(int i=0; i<ArraySize(m_secrets); i++)
         StringReplace(s,m_secrets[i],"***");
      return s;
     }

   void              Write(const int level,const string module,const string msg)
     {
      if(level>m_level)
         return;
      string tag="INFO";
      if(level==LLB_LOG_ERROR)
         tag="ERROR";
      else
         if(level==LLB_LOG_WARN)
            tag="WARN";
         else
            if(level==LLB_LOG_DEBUG)
               tag="DEBUG";
      string line=Redact("[4LLB]["+tag+"]["+module+"] "+msg);
      Print(line);
      if(!m_toFile)
         return;
      datetime now=TimeTradeServer();
      OpenFile(now);
      if(m_handle==INVALID_HANDLE)
         return;
      FileWriteString(m_handle,LLB_TimeStr(now)+" "+line+"\r\n");
      if(!m_tester)
         FileFlush(m_handle);
     }

   void              Error(const string module,const string msg) { Write(LLB_LOG_ERROR,module,msg); }
   void              Warn(const string module,const string msg)  { Write(LLB_LOG_WARN,module,msg); }
   void              Info(const string module,const string msg)  { Write(LLB_LOG_INFO,module,msg); }
   void              Debug(const string module,const string msg) { Write(LLB_LOG_DEBUG,module,msg); }
  };

CLLBLogger g_llbLog;

#endif
//+------------------------------------------------------------------+
