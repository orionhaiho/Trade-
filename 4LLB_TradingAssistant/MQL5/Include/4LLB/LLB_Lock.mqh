//+------------------------------------------------------------------+
//| LLB_Lock.mqh                                                     |
//| Single-instance locks (A-11, A-13) in Terminal\Common\Files so   |
//| they are shared by every chart AND every terminal of the machine.|
//| A lock file holds "<instanceId>|<GMT heartbeat>|<info>".         |
//| Fresh heartbeat from another id (< LLB_LOCK_STALE_SEC) => busy.  |
//| Acquire -> short wait -> Verify closes the start-up race window. |
//| Locks on other machines/VPS cannot be seen (documented risk).    |
//+------------------------------------------------------------------+
#ifndef LLB_LOCK_MQH
#define LLB_LOCK_MQH

#include "LLB_Defines.mqh"
#include "LLB_Utils.mqh"

class CLLBFileLock
  {
private:
   string            m_file;
   string            m_id;
   string            m_info;
   bool              m_held;

   bool              ReadLock(string &id,long &beat)
     {
      id="";
      beat=0;
      if(m_file=="" || !FileIsExist(m_file,FILE_COMMON))
         return false;
      int h=FileOpen(m_file,FILE_READ|FILE_TXT|FILE_ANSI|FILE_COMMON|FILE_SHARE_READ|FILE_SHARE_WRITE);
      if(h==INVALID_HANDLE)
         return false;
      string l=FileReadString(h);
      FileClose(h);
      string parts[];
      int n=StringSplit(l,(ushort)'|',parts);
      if(n<2)
         return false;
      id=parts[0];
      beat=StringToInteger(parts[1]);
      return (id!="");
     }

   bool              WriteLock(void)
     {
      int h=FileOpen(m_file,FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON|FILE_SHARE_READ);
      if(h==INVALID_HANDLE)
         return false;
      FileWriteString(h,m_id+"|"+IntegerToString((long)TimeGMT())+"|"+m_info+"\r\n");
      FileClose(h);
      return true;
     }

public:
                     CLLBFileLock(void)
     {
      m_file="";
      m_id="";
      m_info="";
      m_held=false;
     }

   bool              Acquire(const string name,const string instanceId,const string info,string &why)
     {
      m_file=LLB_FILE_ROOT+"\\locks\\"+name+".lock";
      m_id=instanceId;
      m_info=LLB_CsvClean(info);
      m_held=false;
      FolderCreate(LLB_FILE_ROOT,FILE_COMMON);
      FolderCreate(LLB_FILE_ROOT+"\\locks",FILE_COMMON);
      string other;
      long beat=0;
      if(ReadLock(other,beat) && other!=m_id && (long)TimeGMT()-beat<LLB_LOCK_STALE_SEC)
        {
         why="lock '"+name+"' is held by another running 4LLB instance (heartbeat "+IntegerToString((long)TimeGMT()-beat)+" s ago)";
         return false;
        }
      if(!WriteLock())
        {
         why="cannot write lock file Common\\Files\\"+m_file+" err="+(string)GetLastError();
         return false;
        }
      m_held=true;
      return true;
     }

   //--- after a short wait: the file must still carry our id
   bool              Verify(string &why)
     {
      string other;
      long beat=0;
      if(!ReadLock(other,beat))
        {
         why="lock file disappeared";
         m_held=false;
         return false;
        }
      if(other!=m_id)
        {
         why="another 4LLB instance started at the same time and owns the lock";
         m_held=false;
         return false;
        }
      return true;
     }

   //--- false when another instance took the lock (=> stop trading/polling)
   bool              Heartbeat(string &why)
     {
      if(!m_held)
        {
         why="lock not held";
         return false;
        }
      string other;
      long beat=0;
      if(ReadLock(other,beat) && other!=m_id && (long)TimeGMT()-beat<LLB_LOCK_STALE_SEC)
        {
         why="lock taken over by another instance";
         m_held=false;
         return false;
        }
      if(!WriteLock())
        {
         why="lock heartbeat write failed";
         return true;                                  // keep running; retried on the next heartbeat
        }
      return true;
     }

   void              Release(void)
     {
      if(!m_held)
         return;
      string other;
      long beat=0;
      if(ReadLock(other,beat) && other==m_id)
         FileDelete(m_file,FILE_COMMON);
      m_held=false;
     }

   bool              Held(void) { return m_held; }
  };

#endif
//+------------------------------------------------------------------+
