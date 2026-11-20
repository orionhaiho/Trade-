# M1 — Báo cáo audit read-only

**Ngày:** 2026-11-19 · **Rev2 2026-11-20** (Telegram add-on) · **Kết luận: PASS — không tồn tại đường gọi nào có thể tạo, sửa, hủy hoặc đóng lệnh/position.** Kết nối mạng duy nhất là HTTPS một chiều tới `api.telegram.org`, chỉ khi bật Telegram.

## 1. Phạm vi

| Nhóm | File |
|---|---|
| Production | `RiskManagement.mq5`, `Include/Core/CoreEngine.mqh`, `Include/Core/AccountEngine.mqh`, `Include/Models/AccountModel.mqh`, `Include/Models/RiskEvent.mqh`, `Include/Validation/DataValidator.mqh`, `Include/Utils/Logger.mqh`, `Include/Notify/HttpTransport.mqh`, `Include/Notify/TelegramNotifier.mqh`, `Include/Notify/TelegramMessagesVi.mqh` |
| Test harness | `Tests/RiskManagement_M1_Tests.mq5` (chỉ dữ liệu giả lập) |

Không file nào include thư viện chuẩn MQL5 (`<...>`); mọi `#include` đều là đường dẫn tương đối tới chính các file trên → không có dependency ẩn.

## 2. Phương pháp

| Bước | Cách làm | Kết quả |
|---|---|---|
| A | Quét 119 định danh bị cấm (trade function, `CTrade` và các class Trade, `MqlTradeRequest`, `OnTrade*`, file, network, notification, chart object/UI, `Sleep`, global variable, DLL…) **sau khi bỏ comment và chuỗi** | 0 vi phạm |
| B | Include: chỉ include trong ngoặc kép, resolve được, nằm trong `Include/`; không `<...>`, không `#import` | 0 vi phạm |
| C | Tiền xử lý: chỉ cho phép `#ifndef ..._MQH` (include guard); không macro dạng hàm; không macro chứa tên bị cấm hoặc lời gọi hàm | 0 vi phạm |
| D | Whitelist lời gọi: mọi định danh được gọi phải do dự án định nghĩa hoặc nằm trong danh sách API chỉ-đọc (§3) | 0 vi phạm |
| E | `AccountInfo*`, `TerminalInfoInteger`, `TimeTradeServer` chỉ được gọi trong `CTerminalAccountDataSource` | Đúng (bảng §4) |
| F | Không `new`/`delete`; vòng `while` được review thủ công | 0 `new`/`delete`; 1 `while` (§5) |
| G | Tự kiểm tra audit: cài lần lượt 20 vi phạm vào bản sao tạm | **20/20 bị phát hiện** |
| G2 | (Rev2) `WebRequest` chỉ được gọi trong `CWebRequestTransport`; mọi URL trong chuỗi phải là `https://api.telegram.org` | 0 vi phạm |
| H | Build host: `mql5_shim.h` cố ý không định nghĩa bất kỳ API giao dịch nào → nếu source tham chiếu tới, build sẽ lỗi | Build 0 lỗi, 0 cảnh báo |
| I | Review thủ công: event handler chỉ có `OnInit`, `OnTimer`, `OnDeinit` (không `OnTick`, `OnTrade`, `OnTradeTransaction`, `OnChartEvent`); không nhánh chết, không code bị tắt bằng macro | Đạt |

Công cụ: `Tools/readonly_audit.py`, `Tools/readonly_audit_selftest.py`. Output gốc: `Tests/host/results/readonly_audit_output.md`, `Tests/host/results/readonly_audit_selftest_output.txt`.

## 3. API MQL5 được dùng và lý do chỉ-đọc

| API | Dùng ở | Mục đích | Vì sao không thay đổi trạng thái tài khoản |
|---|---|---|---|
| `AccountInfoInteger` / `AccountInfoDouble` / `AccountInfoString` | `CTerminalAccountDataSource` | Đọc login, server, company, currency, 7 giá trị tài chính, leverage, margin mode, cờ quyền | Hàm truy vấn thuộc tính, chỉ trả giá trị |
| `TerminalInfoInteger(TERMINAL_CONNECTED)` | `CTerminalAccountDataSource` | Kiểm tra kết nối | Truy vấn trạng thái terminal |
| `TimeTradeServer`, `TimeLocal` | `CTerminalAccountDataSource`, `CLogger` | Giờ server / giờ local, timestamp log | Truy vấn thời gian |
| `EventSetTimer`, `EventKillTimer` | `RiskManagement.mq5` | Lịch làm mới | Chỉ điều khiển sự kiện timer của chính EA |
| `Print` | `CLogger` | Ghi tab Experts/Journal | Không ghi file, không network |
| `ResetLastError`, `GetLastError` | data source, `OnInit` | Phát hiện lỗi API | Biến lỗi nội bộ của chương trình |
| `MathIsValidNumber`, `MathSqrt` | validator, model | Kiểm tra NaN/Inf; tạo sentinel NaN | Hàm toán thuần |
| `StringLen`, `StringFind`, `StringSubstr`, `StringGetCharacter`, `IntegerToString`, `DoubleToString`, `TimeToString`, `EnumToString` | toàn bộ | Định dạng chuỗi | Hàm thuần |
| `CheckPointer`, `GetPointer` | engine | Kiểm tra / lấy con trỏ đối tượng tự động | Không cấp phát động |
| `WebRequest` | `CWebRequestTransport` (Telegram, tùy chọn) | POST `sendMessage` tới `https://api.telegram.org` | Chỉ gửi tin nhắn; phản hồi chỉ được đọc để biết gửi thành công hay chưa, không thực thi gì |
| `StringToCharArray`, `CharArrayToString`, `ArrayResize`, `StringReplace`, `StringToInteger` | Telegram add-on | Mã hóa UTF-8, JSON, đọc `retry_after` | Hàm thuần |
| `MQLInfoInteger(MQL_TESTER)` | `RiskManagement.mq5` | Tắt Telegram trong Strategy Tester | Truy vấn môi trường |
| `MathExp`, `ExpertRemove` | **chỉ test harness** | Tạo ±Inf; harness tự gỡ sau khi chạy | Không chạm tài khoản |

## 4. Vị trí gọi API terminal / tài khoản (do audit sinh ra)

| File | API | Class bao quanh |
|---|---|---|
| `RiskManagement.mq5` | `EventSetTimer`, `EventKillTimer` | (entry point) |
| `Include/Utils/Logger.mqh` | `TimeLocal` | `CLogger` |
| `Include/Core/AccountEngine.mqh` | `TerminalInfoInteger`, `AccountInfoInteger`, `AccountInfoDouble`, `AccountInfoString`, `TimeTradeServer`, `TimeLocal` | `CTerminalAccountDataSource` |

## 5. Mục review thủ công

| File | Mục | Kết luận |
|---|---|---|
| `Include/Models/AccountModel.mqh` — `AccountModelFormatDouble()` | Vòng `while` cắt số 0 thừa khi hiển thị | Có giới hạn: `keep` giảm mỗi vòng và dừng tại `dot+3`; chỉ xử lý chuỗi cục bộ; **không phải vòng chờ** |
| `Include/Notify/TelegramNotifier.mqh` — `BuildBatch()` | Vòng `while` gộp tin trong hàng đợi | Có giới hạn: tối đa số tin trong hàng đợi (≤ 50), `used` tăng mỗi vòng hoặc `break`; **không phải vòng chờ** |

## 6. Kết quả self-test của audit (17 vi phạm cài thử)

`OrderSend` trực tiếp · `OrderSendAsync` · `#include <Trade\Trade.mqh>` · đối tượng `CTrade` · `PositionClose` qua member · macro che `OrderSend` · macro dạng hàm · nhánh `#ifdef` · `AccountInfoDouble` ngoài data source · `Sleep` · `FileOpen` · `Comment` · hàm ngoài whitelist · `#import` DLL · `new` · `PositionModify` trong helper không dùng · `WebRequest` ngoài transport · URL tới host khác · `WebRequest` trong notifier thay vì transport · `SendNotification` → **tất cả bị phát hiện (missed: 0 of 20)**.

## 7. Kết luận

- Không có `OrderSend`, `OrderSendAsync`, `CTrade` hay bất kỳ hàm/class giao dịch nào, kể cả gián tiếp, trong macro, trong nhánh compile có điều kiện hay trong hàm không được gọi.
- Account engine chỉ có quyền đọc; các cờ `trade_allowed` / `expert_allowed` chỉ được đọc để mô tả, không dùng để quyết định hành động.
- M1 đạt bất biến **strict read-only**. Audit cần chạy lại sau mỗi lần sửa source (`python3 -I Tools/readonly_audit.py .`).
