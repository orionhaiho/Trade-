# MarketReplay — Báo cáo kỹ thuật và kiểm thử

**Phiên bản:** 1.00  **Ngày:** 2026-11-15
**Trạng thái tổng:** Source đã viết và rà soát tĩnh. **Chưa compile, chưa chạy runtime** (môi trường phát triển là Linux container, không có MetaTrader 5/MetaEditor; tải MT5 bị chặn mạng).

---

## 1. Tóm tắt giải pháp

Kiến trúc **1 file**: `MarketReplay.mq5`.

- Strategy Tester (Visual Mode) chịu trách nhiệm phát lại, Play/Pause, tốc độ, symbol, timeframe, dữ liệu.
- `OnInit`: `CheckEnvironment` → `CheckSymbol` → `CheckTimeframe` → `ApplyChartColors` → `CreateRSI`.
- `OnDeinit`: `ReleaseRSI`.
- `OnTick`: rỗng (không xử lý theo tick). Không có `OnTimer`.
- RSI: `iRSI(_Symbol, _Period, 14, PRICE_CLOSE)`. Không gọi `ChartIndicatorAdd`, vì Tester tự hiển thị indicator do EA tạo, gọi thêm sẽ có nguy cơ tạo RSI thứ hai.

Quyết định người dùng (2026-11-15):
1. RSI: **built-in**, chấp nhận chỉ có mức 30/70 (thiếu 50 là ngoại lệ được chấp thuận). Không có custom indicator.
2. Symbol khác `XAUUSDm`: **ghi WARNING, vẫn chạy**, không tự đổi symbol.

## 2. Xác minh tài liệu (MQL5 Reference / MT5 Help, đọc ngày 2026-11-15)

| Điểm | Kết quả | Trích dẫn / nguồn |
|---|---|---|
| Indicator do EA tạo hiển thị trên chart Visual | **Đã xác minh** | `TesterHideIndicators`: *"By default, all indicators created in a tested EA are displayed on the visual testing chart."* |
| Template trùng tên EA | **Đã xác minh** | MT5 Help, Testing Visualization: *"For a template to be applied, its name must match the name of the tested Expert Advisor."* `TesterHideIndicators`: nếu có `<EA_name>.tpl`, *"only the indicators from this template are displayed … no indicators applied in the tested EA are displayed."* |
| Đổi timeframe chart Tester | **Đã xác minh: không được** | MT5 Help: *"The chart timeframe cannot be changed."* |
| `ChartSetInteger` bất đồng bộ | **Đã xác minh** | *"Returns true if the command has been added to chart queue"*. Vì vậy EA đọc lại bằng `ChartGetInteger` (*"synchronous … waits for the execution of all the commands"*) |
| 13 hằng `CHART_COLOR_*` | **Đã xác minh** tên trong `ENUM_CHART_PROPERTY_INTEGER` | BACKGROUND, FOREGROUND, GRID, CHART_UP, CHART_DOWN, CANDLE_BULL, CANDLE_BEAR, CHART_LINE, VOLUME, BID, ASK, LAST, STOP_LEVEL |
| Màu web | **Đã xác minh** | `clrBlack`, `clrWhite`, `clrDimGray`, `clrMediumTurquoise`, `clrTomato`, `clrRed` |
| `iRSI` chữ ký, trả `INVALID_HANDLE` khi lỗi | **Đã xác minh** | `int iRSI(string, ENUM_TIMEFRAMES, int, ENUM_APPLIED_PRICE)` |
| `IndicatorRelease` trong Tester | **Đã xác minh: không thực thi** | *"When working in the strategy tester, the IndicatorRelease() function is not executed."* |
| `MQL_TESTER`, `MQL_VISUAL_MODE`, `MQL_OPTIMIZATION` | **Đã xác minh** | `ENUM_MQL_INFO_INTEGER` |
| EA không bắt buộc có `OnTick` | **Đã xác minh** | *"this does not mean that Expert Advisors required the OnTick() function"*. Vẫn giữ `OnTick` rỗng để phòng ngừa, không tốn tài nguyên |
| `#property strict` | **Không có** trong danh sách `#property` của MQL5 → **không dùng** | Trang Program Properties |
| RSI built-in mặc định chỉ có level 30/70 | **Suy luận, chưa có trích dẫn** | Cần quan sát ở T08 |
| `ChartSetInteger` có tác dụng trên chart Visual Testing | **Suy luận kỹ thuật** | Kiểm chứng bằng log `Mau OK` và quan sát ở T06 |

## 3. Đánh giá khả thi

| Yêu cầu | Trạng thái | Ghi chú |
|---|---|---|
| Chạy trong Strategy Tester Visual Mode | Khả thi có điều kiện | Cần compile + chạy thử |
| Phát lại `XAUUSDm` | Khả thi có điều kiện | Phụ thuộc broker có symbol và dữ liệu |
| M1/M5/M15/M30/H1/H4 | Khả thi | Người dùng chọn trong Tester; EA kiểm tra |
| Màu chart | Khả thi có điều kiện | Áp + xác nhận từng thuộc tính |
| Duy trì màu qua các lần chạy | Không thể bảo đảm từ EA | EA áp lại mỗi lần chạy |
| RSI 14 Close, subwindow, duy nhất | Khả thi | Auto-display, không `ChartIndicatorAdd` |
| Levels 70/50/30 | Không khả thi với built-in (mức 50) | Ngoại lệ được chấp thuận; thêm 50 thủ công |
| Không giao dịch | Khả thi, đã bảo đảm trong source | Xem §6 |

## 4. Kiểm tra biên dịch

| Hạng mục | Trạng thái |
|---|---|
| Compile bằng MetaEditor | **NOT TESTED**: không có MetaEditor trong môi trường phát triển |
| `MarketReplay.ex5` | **Chưa tạo** |

Đã rà soát tĩnh (không phải compile test):
- Chữ ký `ChartSetInteger(long, ENUM_CHART_PROPERTY_INTEGER, long)`, `ChartGetInteger(long, ENUM_CHART_PROPERTY_INTEGER, int, long&)`, `iRSI`, `IndicatorRelease`, `MQLInfoInteger`, `ColorToString`, `EnumToString`, `StringFormat` khớp tài liệu.
- Mảng hằng toàn cục dùng kiểu enum/color/string (không dùng struct initializer chứa string, để tránh rủi ro compile).
- Hàm được định nghĩa trước khi gọi.
- Không đọc buffer RSI, nên không cần `BarsCalculated`.
- Chống trùng: `CreateRSI` giải phóng handle cũ nếu `g_rsi_handle != INVALID_HANDLE`; `OnDeinit` giải phóng và đặt lại `INVALID_HANDLE`.
- Mọi API quan trọng đều kiểm tra giá trị trả về và log `GetLastError()`.

## 5. Test plan

Mọi ca dưới đây **NOT TESTED**: chưa có MT5. Người dùng chạy và điền cột "Thực tế".

| ID | Kiểm thử | Bước | Kỳ vọng | Thực tế | Trạng thái |
|---|---|---|---|---|---|
| T01 | Khởi chạy Visual Mode | Tester: Expert=MarketReplay, Visual on, Start | Journal có `Environment: tester=yes, visual=yes` và `San sang`; không có `ERROR` | | NOT TESTED |
| T02 | Symbol `XAUUSDm` | Chạy với XAUUSDm; chạy thêm 1 lần với symbol khác | XAUUSDm: `Symbol: XAUUSDm (dung symbol muc tieu)`. Symbol khác: `WARNING`, chart vẫn là symbol đã chọn | | NOT TESTED (BLOCKED nếu server không có XAUUSDm) |
| T03 | 6 timeframe | Chạy lần lượt M1, M5, M15, M30, H1, H4 | Mỗi lần: `Timeframe: PERIOD_xx (nam trong ...)`, chart đúng TF | | NOT TESTED |
| T04 | Phát lại lịch sử | Quan sát vài phút | Nến hình thành theo thời gian | | NOT TESTED |
| T05 | Play/Pause/tốc độ | Dùng nút Pause, kéo thanh tốc độ | Phản hồi theo UI Tester | | NOT TESTED |
| T06 | Màu chart | Đọc dòng `Chart colours: x/13`; so sánh trực quan với bảng | `13/13 xac nhan`; màu hiển thị khớp. Ghi rõ thuộc tính không áp được | | NOT TESTED |
| T07 | RSI | Quan sát subwindow; mở Properties RSI | Đúng 1 subwindow RSI, Period 14, Apply to Close | | NOT TESTED |
| T08 | RSI levels | Properties → Levels | Có 30, 70. **Không có 50 (ngoại lệ đã chấp thuận)**; thêm thủ công theo README §6 | | NOT TESTED |
| T09 | Indicator thừa | Chuột phải chart → Indicators List | Chỉ có RSI(14) | | NOT TESTED |
| T10 | Không giao dịch | Sau test: tab Backtest/History, Results | 0 deal, 0 order, 0 position | | NOT TESTED |
| T11 | Khởi tạo lại | Chạy Start nhiều lần liên tiếp | Mỗi lần vẫn chỉ 1 RSI; không có WARNING `RSI handle da ton tai` (hoặc nếu có thì vẫn chỉ 1 RSI) | | NOT TESTED |
| T12 | Độ ổn định | Chạy ≥ 1 tháng dữ liệu M1, tốc độ cao | Không lỗi, không treo; CPU không tăng do EA (`OnTick` rỗng) | | NOT TESTED |

Bằng chứng cần gửi lại: kết quả tab Errors khi compile, đoạn Journal `[MarketReplay]`, ảnh chụp cửa sổ Visual Testing, ảnh Indicators List, ảnh tab Results (0 trades).

## 6. Safety audit: không giao dịch

Lệnh grep đã chạy trên `MarketReplay.mq5`:

```
OrderSend|OrderSendAsync|CTrade|Trade\.mqh|PositionOpen|PositionClose|PositionModify|OrderModify|
OrderDelete|OrderOpen|\bBuy\b|\bSell\b|ChartIndicatorAdd\(|ChartSetSymbolPeriod\(|EventSetTimer|
#import|\.dll|SendNotification|Alert\(|PlaySound|FileOpen|WebRequest
```

Kết quả: chỉ có 1 dòng khớp, là dòng chú thích 7 (*"does not include Trade.mqh"*). Không có lời gọi nào.

- Không `#include`, không `#import`, không DLL.
- Side effect duy nhất: đặt thuộc tính màu chart, tạo handle RSI, ghi `Print`.
- Không tạo tín hiệu, alert, file hay request mạng.

## 7. Requirement traceability

| Yêu cầu (đặc tả §) | Cách triển khai | File/hàm | Kiểm thử | Trạng thái | Giới hạn |
|---|---|---|---|---|---|
| 5.1 Chạy Tester Visual | Kiểm tra `MQL_TESTER`/`MQL_VISUAL_MODE`; ngoài Tester → `INIT_FAILED` | `CheckEnvironment` | T01 | Source xong, chưa chạy | — |
| 5.1 Symbol XAUUSDm | So sánh `_Symbol`, WARNING nếu khác, không tự đổi | `CheckSymbol` | T02 | Source xong | Phụ thuộc broker |
| 5.1 TF M1…H4 | Kiểm tra `_Period` trong danh sách | `CheckTimeframe` | T03 | Source xong | Người dùng chọn |
| 5.1 Dữ liệu broker, không sửa dữ liệu | Không đọc/ghi dữ liệu lịch sử | — | T04 | Đạt trong source | — |
| 5.1 Dùng Play/Pause Tester, không replay engine | Không có engine; `OnTick` rỗng | `OnTick` | T05 | Đạt trong source | — |
| 5.1 Không gửi lệnh | Không có API giao dịch | toàn file | T10, §6 | Đạt trong source | — |
| 5.2 13 màu | `ChartSetInteger` + xác nhận `ChartGetInteger` | `ApplyChartColors` | T06 | Source xong | Visual chart chưa kiểm chứng |
| 5.2 Duy trì màu | Áp lại mỗi `OnInit` | `ApplyChartColors` | T06, T11 | Có điều kiện | Không ép MT5 giữ màu |
| 5.3 RSI 14 Close | `iRSI(_Symbol,_Period,14,PRICE_CLOSE)` | `CreateRSI` | T07 | Source xong | — |
| 5.3 Levels 70/50/30 | RSI built-in mặc định | — | T08 | **Ngoại lệ đã chấp thuận** | Thiếu 50 |
| 5.3 Subwindow | Tester auto-display | — | T07 | Đã xác minh tài liệu | — |
| 5.3 Không signal/indicator khác | Chỉ 1 handle | `CreateRSI` | T09 | Đạt trong source | Template `MarketReplay.tpl` sẽ thay đổi việc hiển thị indicator |
| 5.3 Không nhân bản RSI | Guard handle; không `ChartIndicatorAdd` | `CreateRSI`, `ReleaseRSI` | T11 | Source xong | `IndicatorRelease` không thực thi trong Tester |
| 5.4 Hành vi cấm | Không có | toàn file | §6 | Đạt trong source | — |
| 5.5 Chất lượng, log, CPU | Hàm tách nhỏ, log từng bước, không xử lý theo tick | toàn file | T12 | Source xong | — |

## 8. Tự đánh giá (0–2)

| Tiêu chí | Điểm | Lý do |
|---|---|---|
| Đúng yêu cầu | 1 | Thiếu mức 50 (ngoại lệ được chấp thuận); chưa chạy |
| Tính khả thi | 2 | Các điểm cốt lõi được xác minh bằng tài liệu chính thức |
| An toàn không giao dịch | 2 | Grep + rà soát: không có đường code giao dịch |
| Tính đúng MQL5 | 1 | Rà soát tĩnh theo tài liệu; chưa có kết quả compiler |
| Độ ổn định | 1 | Thiết kế tối giản; chưa chạy |
| Khả năng cài đặt | 1 | Có hướng dẫn; chưa có người dùng xác nhận |
| Minh bạch kiểm thử | 2 | Mọi ca ghi NOT TESTED, có danh sách bằng chứng cần thu |

## 9. Kết luận nghiệm thu

**Đạt về mặt rà soát source / Chưa xác minh runtime.**

Lý do: chưa compile và chưa chạy trong MT5; mức RSI 50 là ngoại lệ đã được người dùng chấp thuận. Để nghiệm thu đầy đủ: compile (0 errors), chạy T01–T12 và cập nhật bảng §5 kèm bằng chứng.
