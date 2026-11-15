# MarketReplay — Hướng dẫn sử dụng (MT5 Strategy Tester, Visual Mode)

`MarketReplay` là Expert Advisor **chỉ để xem lại lịch sử giá** (XAUUSDm) như video trong Strategy Tester của MetaTrader 5, phục vụ luyện Price Action. EA:

- áp bảng màu chart theo đặc tả và tự kiểm tra từng màu;
- tạo **một** RSI(14, Close) built-in, hiển thị ở cửa sổ phụ bên dưới chart giá;
- kiểm tra symbol/timeframe và ghi log.

EA **không giao dịch**: không có lệnh, tín hiệu, SL/TP, quản lý vốn; không include thư viện giao dịch.

> **Ngoại lệ đã chấp thuận:** dùng RSI built-in của MT5. Theo mặc định, RSI built-in chỉ có các mức 30/70; EA **không thể** thêm mức 50 cho indicator built-in (API `IndicatorSet*` chỉ dùng được bên trong chính indicator). Cách thêm mức 50 thủ công xem mục 6.

---

## 1. Điều kiện tiên quyết

| Mục | Yêu cầu |
|---|---|
| Nền tảng | MetaTrader 5 trên Windows 10, có MetaEditor (đi kèm MT5) |
| Tài khoản | Đăng nhập được server của broker (demo là đủ; EA không gửi lệnh) |
| Symbol | `XAUUSDm` phải **có trên server bạn dùng**. Hậu tố tuỳ broker/loại tài khoản (ví dụ Exness: `m` = Standard, `c` = Cent). Kiểm tra trong Market Watch (Ctrl+M → chuột phải → Symbols) |
| Dữ liệu | Tester tự tải lịch sử từ broker khi chạy; cần kết nối mạng lần đầu cho khoảng ngày đã chọn |

## 2. Cài đặt

1. Trong MT5: **File → Open Data Folder**.
2. Chép `MarketReplay.mq5` vào `MQL5\Experts\` (có thể đặt trong thư mục con, ví dụ `MQL5\Experts\MarketReplay\`).
3. Không cần file indicator riêng (dùng RSI built-in).

## 3. Biên dịch

1. Mở MetaEditor (F4 trong MT5), mở `MarketReplay.mq5`.
2. Nhấn **Compile** (F7).
3. Tab **Errors** phải báo `0 errors`. Hãy ghi lại số warning (nếu có) vào `TEST_REPORT.md`.
4. File `MarketReplay.ex5` được tạo cạnh file `.mq5`.

> Source này **chưa được biên dịch thực tế** trong môi trường phát triển (không có MetaEditor). Nếu có lỗi compile, gửi lại nguyên văn tab Errors để sửa.

## 4. Thiết lập Strategy Tester

Mở **View → Strategy Tester** (Ctrl+R), tab **Settings**:

| Trường | Giá trị | Ai chịu trách nhiệm |
|---|---|---|
| Expert | `MarketReplay` | Người dùng |
| Symbol | `XAUUSDm` | Người dùng (EA chỉ kiểm tra, không tự đổi) |
| Timeframe | M1, M5, M15, M30, H1 hoặc H4 | Người dùng (chart Tester **không đổi được** timeframe khi đang chạy) |
| Date | Khoảng ngày muốn xem lại | Người dùng |
| Modelling | `Every tick based on real ticks` (mô phỏng sát nhất) hoặc `Every tick`; `1 minute OHLC` nhẹ hơn | Người dùng |
| Visualization / Visual mode | **Bật** | Người dùng |
| Optimization | **Tắt** | Người dùng |
| Deposit/Leverage | Tuỳ ý (không ảnh hưởng, EA không giao dịch) | Người dùng |

Nhấn **Start**. Cửa sổ Visual Testing mở ra.

## 5. Điều khiển phát lại

Hoàn toàn bằng thanh điều khiển của cửa sổ Visual Testing (EA không có replay engine riêng):

- **Play/Pause**: nút Pause/Play (phím Pause cũng dùng được trên nhiều bản MT5).
- **Tốc độ**: thanh trượt tốc độ.
- **Từng bước**: khi đang Pause, phím F12 tiến từng bước (tuỳ phiên bản MT5).
- RSI hiển thị ở cửa sổ phụ bên dưới, cập nhật theo từng tick phát lại.

## 6. Thêm mức 50 cho RSI (thủ công, tuỳ chọn)

RSI built-in không cho EA chỉnh level. Trong cửa sổ Visual Testing:

1. Chuột phải lên RSI → **Properties** (hoặc Indicators List) → tab **Levels**.
2. **Add** → nhập `50`. Kiểm tra còn `30` và `70`.

Thiết lập này **chỉ có hiệu lực cho lần chạy hiện tại**. Không nên lưu template tên `MarketReplay.tpl` chỉ để giữ mức 50, vì khi có template trùng tên EA, Tester **chỉ hiện indicator trong template** và ẩn RSI do EA tạo (theo tài liệu `TesterHideIndicators`). Nếu muốn dùng template, phải đưa RSI vào chính template đó.

## 7. Đọc log

Tab **Journal** của Strategy Tester, các dòng bắt đầu bằng `[MarketReplay]`:

- `Environment: tester=yes, visual=yes, ...`: môi trường.
- `Symbol: ...` / `WARNING: Symbol dang test la ...`: kiểm tra symbol.
- `Mau OK: ...` / `Mau KHONG khop: ...` và dòng tổng `Chart colours: x/13 ...`: kết quả từng màu.
- `Da tao RSI(14, PRICE_CLOSE) built-in, handle=...`: RSI đã tạo.

## 8. Lỗi thường gặp

| Hiện tượng | Nguyên nhân / Cách xử lý |
|---|---|
| Không có `XAUUSDm` trong danh sách symbol của Tester | Server/tài khoản không có symbol này (ví dụ tài khoản Cent chỉ có `XAUUSDc`). Đăng nhập tài khoản có `XAUUSDm`, hoặc chấp nhận chạy symbol khác; EA sẽ ghi WARNING và **không tự đổi** symbol |
| Journal báo thiếu lịch sử / chart trống | Kiểm tra kết nối, thu hẹp khoảng ngày, chạy lại để Tester tải dữ liệu. Với `real ticks`, ngày nào broker không có tick thật thì Tester sẽ dùng tick sinh ra (xem Journal) |
| `ERROR: iRSI(...) that bai` và EA dừng | Thiếu dữ liệu symbol/timeframe; ghi lại `GetLastError()` trong log |
| Không thấy RSI | Kiểm tra có file `MarketReplay.tpl` trong `MQL5\Profiles\Templates` không (nếu có, Tester ẩn indicator của EA) — xoá/đổi tên nó |
| `Mau KHONG khop` hoặc màu không đổi | Ghi lại thuộc tính nào trong log. Có thể đặt màu thủ công bằng F8 (Properties → Colors) trên chart Visual |
| Không thấy đường Ask / Last | EA chỉ đặt **màu**, không bật/tắt hiển thị. Bật trong F8 → Common: "Show Ask line"/"Show Last line". Đường Last chỉ có dữ liệu với symbol có giá Last (thường là sàn tập trung) |
| `ERROR: EA chi danh cho Strategy Tester` | EA được gắn vào chart thực; EA chỉ chạy trong Tester |

## 9. Phân định trách nhiệm

| Thành phần | Trách nhiệm |
|---|---|
| Strategy Tester (người dùng thiết lập) | Symbol, timeframe, khoảng ngày, modelling, Visual Mode, Play/Pause, tốc độ, tải dữ liệu lịch sử |
| EA `MarketReplay` | Kiểm tra môi trường/symbol/timeframe và ghi log; áp + xác nhận 13 màu chart; tạo đúng 1 handle RSI(14, Close) |
| MT5 terminal | Tính và vẽ RSI built-in trong cửa sổ phụ (tự động với indicator do EA tạo trong Tester) |

## 10. Giới hạn

- Màu được EA áp lại ở **mỗi lần chạy** (`OnInit`). EA không thể ghi nhớ hay ép MT5 giữ màu ngoài phạm vi lần chạy đó.
- EA không đổi symbol/timeframe (tài liệu MT5: *"The chart timeframe cannot be changed"* trong Visual Testing).
- RSI built-in: không có mức 50 trừ khi thêm thủ công (mục 6).
- Chưa compile và chưa chạy thực tế; xem `TEST_REPORT.md`.
