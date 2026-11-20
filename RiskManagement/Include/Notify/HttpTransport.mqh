//+------------------------------------------------------------------+
//|                                                HttpTransport.mqh |
//|          EA Risk Management - Telegram notification add-on       |
//|                                                                  |
//| CHttpTransport        abstract HTTPS POST (test doubles inject   |
//|                       through CTelegramNotifier::SetTransport)   |
//| CWebRequestTransport  the ONLY class that calls WebRequest().    |
//|                                                                  |
//| WebRequest() is synchronous: the call blocks this EA's own event |
//| thread for at most timeout_ms. CTelegramNotifier therefore sends |
//| at most one request per timer cycle, after the account refresh.  |
//| The URL must be allowed in MT5: Tools > Options > Expert         |
//| Advisors > "Allow WebRequest for listed URL" ->                  |
//| https://api.telegram.org                                         |
//|                                                                  |
//| Outbound notification only: no trading function is used and     |
//| nothing received from the network is ever executed.             |
//+------------------------------------------------------------------+
#ifndef RISKMANAGEMENT_NOTIFY_HTTPTRANSPORT_MQH
#define RISKMANAGEMENT_NOTIFY_HTTPTRANSPORT_MQH

class CHttpTransport
  {
public:
   virtual          ~CHttpTransport()
     {
     }
   //--- returns the HTTP status code, or -1 with error_code=GetLastError()
   virtual int       PostJson(const string url,const string json_body,const int timeout_ms,
                              string &response_body,int &error_code)=0;
  };

class CWebRequestTransport : public CHttpTransport
  {
public:
   virtual int       PostJson(const string url,const string json_body,const int timeout_ms,
                              string &response_body,int &error_code)
     {
      response_body="";
      error_code=0;

      //--- UTF-8 body without the terminating zero copied by StringToCharArray
      char body[];
      int copied=StringToCharArray(json_body,body,0,WHOLE_ARRAY,CP_UTF8);
      if(copied<1)
        {
         error_code=GetLastError();
         return(-1);
        }
      ArrayResize(body,copied-1);

      char response_data[];
      string response_headers="";
      string headers="Content-Type: application/json\r\n";
      ResetLastError();
      int status=WebRequest("POST",url,headers,timeout_ms,body,response_data,response_headers);
      if(status==-1)
        {
         error_code=GetLastError();
         return(-1);
        }
      response_body=CharArrayToString(response_data,0,WHOLE_ARRAY,CP_UTF8);
      return(status);
     }
  };

#endif // RISKMANAGEMENT_NOTIFY_HTTPTRANSPORT_MQH
//+------------------------------------------------------------------+
