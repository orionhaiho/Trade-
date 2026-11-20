//+------------------------------------------------------------------+
//|                                           TelegramMessagesVi.mqh |
//|          EA Risk Management - Telegram notification add-on       |
//|                                                                  |
//| Vietnamese text of every Telegram notification.                  |
//| ENCODING: this file MUST stay UTF-8 with BOM (it contains        |
//| Vietnamese characters). Test N01 of the harness checks that      |
//| MetaEditor decoded it correctly (RMViEncodingProbe).             |
//|                                                                  |
//| Pure formatting: no terminal, account, network or trading API.   |
//+------------------------------------------------------------------+
#ifndef RISKMANAGEMENT_NOTIFY_TELEGRAMMESSAGESVI_MQH
#define RISKMANAGEMENT_NOTIFY_TELEGRAMMESSAGESVI_MQH

#include "../Models/AccountModel.mqh"
#include "../Models/RiskEvent.mqh"

//--- must return one character, U+1EA1 (latin small letter a with dot below)
string RMViEncodingProbe()
  {
   return("ạ");
  }

string RMViStatus(const ENUM_DATA_STATUS status)
  {
   switch(status)
     {
      case DATA_STATUS_VALID:
         return("Hợp lệ");
      case DATA_STATUS_UNAVAILABLE:
         return("Không khả dụng");
      case DATA_STATUS_INVALID:
         return("Không hợp lệ");
      case DATA_STATUS_STALE:
         return("Dữ liệu cũ (không phải dữ liệu hiện tại)");
     }
   return("Không rõ");
  }

string RMViUninitReason(const int reason)
  {
   switch(reason)
     {
      case REASON_PROGRAM:
         return("EA tự dừng");
      case REASON_REMOVE:
         return("EA bị gỡ khỏi chart");
      case REASON_RECOMPILE:
         return("EA được biên dịch lại");
      case REASON_CHARTCHANGE:
         return("Đổi symbol hoặc khung thời gian của chart");
      case REASON_CHARTCLOSE:
         return("Chart bị đóng");
      case REASON_PARAMETERS:
         return("Tham số đầu vào thay đổi");
      case REASON_ACCOUNT:
         return("Đổi tài khoản hoặc kết nối lại do cài đặt tài khoản thay đổi");
      case REASON_TEMPLATE:
         return("Áp dụng template khác cho chart");
      case REASON_INITFAILED:
         return("EA khởi động thất bại");
      case REASON_CLOSE:
         return("Terminal MT5 đóng");
     }
   return("Không rõ (mã "+IntegerToString(reason)+")");
  }

string RMViTime(const datetime value)
  {
   if(value<=0)
      return("không rõ");
   return(TimeToString(value,TIME_DATE|TIME_SECONDS));
  }

string RMViDuration(const long seconds)
  {
   if(seconds<60)
      return(IntegerToString(seconds)+" giây");
   if(seconds<3600)
      return(IntegerToString(seconds/60)+" phút "+IntegerToString(seconds%60)+" giây");
   return(IntegerToString(seconds/3600)+" giờ "+IntegerToString((seconds%3600)/60)+" phút");
  }

//--- validation messages of CDataValidator (fixed English text) -> Vietnamese
string RMViValidationErrors(string errors)
  {
   StringReplace(errors,"ACCOUNT_MARGIN_LEVEL must be >= 0 when ACCOUNT_MARGIN > 0 and ACCOUNT_EQUITY >= 0",
                 "Margin Level phải ≥ 0 khi Margin > 0 và Equity ≥ 0");
   StringReplace(errors,"ACCOUNT_LOGIN must be > 0","Số tài khoản (login) phải lớn hơn 0");
   StringReplace(errors,"ACCOUNT_SERVER must not be empty","Tên máy chủ (server) bị trống");
   StringReplace(errors,"ACCOUNT_CURRENCY must not be empty","Đơn vị tiền tệ bị trống");
   StringReplace(errors,"ACCOUNT_MARGIN must be >= 0","Margin bị âm");
   StringReplace(errors,"ACCOUNT_LEVERAGE must be > 0","Đòn bẩy phải lớn hơn 0");
   StringReplace(errors,"ACCOUNT_MARGIN_MODE is not a supported ENUM_ACCOUNT_MARGIN_MODE value","Chế độ ký quỹ (margin mode) không được hỗ trợ");
   StringReplace(errors,"SERVER_TIME must be > 0 (TimeTradeServer)","Không có giờ máy chủ");
   StringReplace(errors,"COLLECTION_TIME must be > 0 (TimeLocal)","Không có giờ máy tính");
   StringReplace(errors," is not a finite number (NaN or Inf)"," không phải là số hợp lệ (NaN/Inf)");
   StringReplace(errors,"ACCOUNT_MARGIN_FREE","Free Margin");
   StringReplace(errors,"ACCOUNT_MARGIN_LEVEL","Margin Level");
   StringReplace(errors,"ACCOUNT_BALANCE","Balance");
   StringReplace(errors,"ACCOUNT_EQUITY","Equity");
   StringReplace(errors,"ACCOUNT_PROFIT","Lãi/lỗ đang mở");
   StringReplace(errors,"ACCOUNT_CREDIT","Credit");
   StringReplace(errors,"ACCOUNT_MARGIN","Margin");
   return(errors);
  }

//--- reason text produced by CAccountEngine / CCoreEngine -> Vietnamese
string RMViReason(const string reason)
  {
   if(StringFind(reason,"TERMINAL_DISCONNECTED: data passed validation")==0)
      return("Terminal đang mất kết nối; số liệu chỉ là dữ liệu cũ terminal còn lưu");
   if(StringFind(reason,"TERMINAL_DISCONNECTED: TerminalInfoInteger")==0)
      return("Không kiểm tra được trạng thái kết nối của terminal (coi như mất kết nối)");
   if(StringFind(reason,"TERMINAL_DISCONNECTED")==0)
      return("Terminal chưa kết nối tới máy chủ giao dịch");
   if(StringFind(reason,"API_ERROR: ")==0)
      return("Lỗi khi đọc dữ liệu từ terminal ("+StringSubstr(reason,11)+")");
   if(StringFind(reason,"SERVER_TIME_UNAVAILABLE")==0)
      return("Không lấy được giờ máy chủ giao dịch");
   if(StringFind(reason,"DATA_INVALID: ")==0)
      return("Dữ liệu không hợp lệ: "+RMViValidationErrors(StringSubstr(reason,14)));
   if(StringFind(reason,"ACCOUNT_IDENTITY_CHANGED")==0)
      return("Tài khoản đã thay đổi, cần khởi động lại EA");
   if(StringFind(reason,"CORE_ENGINE_NOT_INITIALIZED")==0)
      return("Bộ thu thập dữ liệu chưa được khởi tạo");
   return(reason);
  }

string RMViDroppedNotice(const int dropped)
  {
   return("(Đã bỏ qua "+IntegerToString(dropped)+" thông báo cũ vì hàng đợi đầy)");
  }

string RMViIdentity(const long login,const string server,const string currency)
  {
   return(IntegerToString(login)+" ("+server+", "+currency+")");
  }

string RMViHeader(const string title,const string account_label,const datetime event_time)
  {
   string text="[RiskManagement] ";
   text=text+title;
   if(StringLen(account_label)>0)
      text=text+"\nTài khoản: "+account_label;
   if(event_time>0)
      text=text+"\nThời gian: "+RMViTime(event_time);
   return(text);
  }

//--- account values (display only: values are never rounded in the data)
string RMViAccountValues(const AccountSnapshot &snapshot)
  {
   string currency=" "+snapshot.currency;
   string text="Balance: ";
   text=text+AccountModelFormatDouble(snapshot.balance)+currency;
   text=text+"\nEquity: "+AccountModelFormatDouble(snapshot.equity)+currency;
   text=text+"\nLãi/lỗ đang mở: "+AccountModelFormatDouble(snapshot.profit)+currency;
   if(MathIsValidNumber(snapshot.credit) && snapshot.credit!=0.0)
      text=text+"\nCredit: "+AccountModelFormatDouble(snapshot.credit)+currency;
   text=text+"\nMargin đang dùng: "+AccountModelFormatDouble(snapshot.margin)+currency;
   text=text+"\nFree Margin: "+AccountModelFormatDouble(snapshot.free_margin)+currency;
   if(MathIsValidNumber(snapshot.margin) && snapshot.margin>0.0)
      text=text+"\nMargin Level: "+AccountModelFormatDouble(snapshot.margin_level)+"%";
   else
      text=text+"\nMargin Level: không có (chưa dùng margin)";
   text=text+"\nĐòn bẩy: 1:"+IntegerToString(snapshot.leverage);
   return(text);
  }

//+------------------------------------------------------------------+
//| One Telegram message per state-transition event                  |
//+------------------------------------------------------------------+
string RMTelegramFormatEventVi(const RiskEvent &risk_event,const string account_label)
  {
   string text="";
   switch(risk_event.event_id)
     {
      case RM_EVENT_EA_INITIALIZED:
         text=RMViHeader("✅ EA đã khởi động (chỉ đọc, không giao dịch)",account_label,risk_event.event_time);
         text=text+"\nChu kỳ làm mới: "+IntegerToString(risk_event.code)+" giây";
         if(risk_event.has_snapshot)
            text=text+"\n"+RMViAccountValues(risk_event.snapshot);
         else
            text=text+"\nChưa có dữ liệu tài khoản hợp lệ: "+RMViReason(risk_event.reason)
                 +"\nEA sẽ tự thử lại mỗi chu kỳ và báo khi có dữ liệu.";
         return(text);

      case RM_EVENT_EA_INITIALIZATION_FAILED:
         text=RMViHeader("❌ EA khởi động thất bại",account_label,risk_event.event_time);
         text=text+"\nLý do: "+risk_event.reason+"\nHãy kiểm tra lại tham số đầu vào của EA.";
         return(text);

      case RM_EVENT_ACCOUNT_COLLECTION_SUCCESS:
         if(risk_event.flag)
           {
            text=RMViHeader("✅ Đã nhận dữ liệu tài khoản hợp lệ",account_label,risk_event.event_time);
            if(risk_event.count>0)
               text=text+"\n(sau "+IntegerToString(risk_event.count)+" chu kỳ chưa có dữ liệu)";
           }
         else
           {
            text=RMViHeader("✅ Dữ liệu tài khoản đã hoạt động lại",account_label,risk_event.event_time);
            text=text+"\nSau "+IntegerToString(risk_event.count)+" chu kỳ không có dữ liệu hợp lệ.";
           }
         if(risk_event.has_snapshot)
            text=text+"\n"+RMViAccountValues(risk_event.snapshot);
         return(text);

      case RM_EVENT_ACCOUNT_COLLECTION_FAILED:
         if(risk_event.level==RM_LOG_ERROR)
            text=RMViHeader("❌ Dữ liệu tài khoản có vấn đề",account_label,risk_event.event_time);
         else
            text=RMViHeader("⚠️ Tạm thời không có dữ liệu tài khoản",account_label,risk_event.event_time);
         text=text+"\nTrạng thái: "+RMViStatus(risk_event.status);
         text=text+"\nLý do: "+RMViReason(risk_event.reason);
         if(risk_event.has_snapshot)
            text=text+"\nLần có dữ liệu hợp lệ gần nhất: "+RMViTime(risk_event.snapshot.collection_time);
         else
            text=text+"\nChưa có lần thu thập hợp lệ nào.";
         text=text+"\nEA vẫn tiếp tục thử lại và sẽ báo khi dữ liệu hoạt động lại.";
         return(text);

      case RM_EVENT_ACCOUNT_IDENTITY_CHANGED:
         text=RMViHeader("❌ Phát hiện tài khoản đã thay đổi",account_label,risk_event.event_time);
         if(risk_event.has_snapshot)
            text=text+"\nTài khoản ban đầu: "+RMViIdentity(risk_event.snapshot.login,risk_event.snapshot.server,risk_event.snapshot.currency);
         text=text+"\nTerminal hiện báo: "+RMViIdentity(risk_event.observed_login,risk_event.observed_server,risk_event.observed_currency);
         text=text+"\nEA đã ngừng thu thập dữ liệu để không trộn lẫn hai tài khoản."
              +"\nHãy gỡ EA khỏi chart và gắn lại để theo dõi tài khoản mới.";
         return(text);

      case RM_EVENT_TERMINAL_DISCONNECTED:
         if(risk_event.flag)
            text=RMViHeader("⚠️ Terminal chưa kết nối tới máy chủ giao dịch (lúc EA khởi động)",account_label,risk_event.event_time);
         else
            text=RMViHeader("⚠️ Terminal mất kết nối tới máy chủ giao dịch",account_label,risk_event.event_time);
         text=text+"\nDữ liệu tài khoản tạm thời không cập nhật được.";
         return(text);

      case RM_EVENT_TERMINAL_RECONNECTED:
         if(risk_event.flag)
            text=RMViHeader("✅ Terminal đã kết nối tới máy chủ giao dịch",account_label,risk_event.event_time);
         else
            text=RMViHeader("✅ Terminal đã kết nối lại",account_label,risk_event.event_time);
         if(risk_event.seconds>=0)
            text=text+"\nThời gian mất kết nối: khoảng "+RMViDuration(risk_event.seconds);
         return(text);

      case RM_EVENT_EA_SHUTDOWN:
         text=RMViHeader("ℹ️ EA đã dừng",account_label,risk_event.event_time);
         text=text+"\nLý do: "+RMViUninitReason(risk_event.code);
         return(text);

      default:
         break;
     }
   return("");
  }

//+------------------------------------------------------------------+
//| Periodic summary (InpTelegramSummaryMinutes > 0)                 |
//| snapshot: result of CCoreEngine::GetLatestSnapshot()             |
//+------------------------------------------------------------------+
string RMTelegramFormatSummaryVi(const AccountSnapshot &snapshot,const bool is_current,
                                 const ENUM_DATA_STATUS current_status,const string current_reason,
                                 const string account_label,const datetime now)
  {
   string text=RMViHeader("ℹ️ Tóm tắt tài khoản",account_label,now);
   if(is_current)
      return(text+"\n"+RMViAccountValues(snapshot));
   text=text+"\nTrạng thái hiện tại: "+RMViStatus(current_status);
   if(StringLen(current_reason)>0)
      text=text+"\nLý do: "+RMViReason(current_reason);
   if(snapshot.data_status==DATA_STATUS_STALE)
      text=text+"\nSố liệu dưới đây là dữ liệu CŨ lúc "+RMViTime(snapshot.collection_time)
           +", không phải hiện tại:\n"+RMViAccountValues(snapshot);
   return(text);
  }

#endif // RISKMANAGEMENT_NOTIFY_TELEGRAMMESSAGESVI_MQH
//+------------------------------------------------------------------+
