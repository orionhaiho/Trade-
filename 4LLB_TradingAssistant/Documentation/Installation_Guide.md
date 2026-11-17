# Hướng dẫn cài đặt, compile, kiểm thử và Release Gate — 4LLB Trading Assistant v2.0

> EA này là công cụ kỹ thuật hỗ trợ ra quyết định, **không** phải lời khuyên tài chính và **không** cam kết lợi nhuận. Chỉ chạy tài khoản thật sau khi hoàn tất toàn bộ checklist Demo ở §9.

## 1. Yêu cầu

- MetaTrader 5 của **Exness** (Windows hoặc VPS Windows), bản cập nhật mới.
- Tài khoản **Demo** trước. Lưu ý: `XAUUSD` (Pro/Raw/Zero) và `XAUUSDc` (Standard Cent) thường thuộc **hai loại tài khoản khác nhau** — một terminal chỉ đăng nhập một tài khoản, EA sẽ tự tắt symbol không tồn tại (dashboard ghi `DISABLED`).
- Telegram (xem `Telegram_Bot_Setup_Guide.md`).
- Máy/VPS chạy liên tục nếu muốn nhận đề xuất suốt phiên.

## 2. Cài file

1. MT5 → **File → Open Data Folder**.
2. Copy **nội dung** thư mục `4LLB_TradingAssistant/MQL5/` của repo vào thư mục `MQL5` vừa mở, giữ nguyên cấu trúc:

   ```text
   MQL5\Experts\4LLB\4LLB_TradingAssistant.mq5
   MQL5\Include\4LLB\LLB_*.mqh            (19 file)
   MQL5\Scripts\4LLB\4LLB_UnitTests.mq5
   ```

## 3. Compile

1. Mở **MetaEditor** (F4 trong MT5).
2. Mở `MQL5\Experts\4LLB\4LLB_TradingAssistant.mq5` → bấm **Compile (F7)**.
3. Kết quả mong đợi: `0 errors, 0 warnings`.
4. Làm tương tự với `MQL5\Scripts\4LLB\4LLB_UnitTests.mq5`.

**Nếu có lỗi:** chụp/copy toàn bộ tab **Errors** (tên file, dòng, nội dung) và gửi lại — mã nguồn được viết trong môi trường không có MetaEditor nên lần build đầu cần bạn xác nhận.

## 4. Chạy unit test (khuyến nghị trước khi gắn EA)

1. MT5 → Navigator → **Scripts → 4LLB → 4LLB_UnitTests** → kéo vào một chart bất kỳ.
2. Tab **Experts** phải có: `4LLB UNIT TESTS: 139 passed, 0 failed` và `4LLB UNIT TESTS: ALL PASSED`.
3. Có dòng `FAIL …` → gửi lại các dòng đó.

Script chỉ kiểm tra logic thuần (không đặt lệnh, không gọi mạng).

## 5. Cấu hình MT5

**Tools → Options → Expert Advisors:**

- Tích **Allow algorithmic trading**.
- Tích **Allow WebRequest for listed URL** và thêm `https://api.telegram.org`.

Bật nút **Algo Trading** trên thanh công cụ.

## 6. Cấu hình Telegram

Làm theo `Telegram_Bot_Setup_Guide.md` (tạo bot, lấy Chat ID, file `MQL5\Files\4LLB\telegram_token.txt`).

## 7. Gắn EA

Gắn EA vào **một chart duy nhất** (ví dụ XAUUSD M15 — khung chart không ảnh hưởng, EA tự đọc D1/M15 của mọi symbol). Gắn thêm chart thứ hai cùng tài khoản sẽ bị từ chối (khoá instance).

### Bảng inputs

| Nhóm | Input | Mặc định | Ý nghĩa |
|---|---|---|---|
| 1 | `InpSymbols` | `XAUUSD,XAUUSDc` | Symbol theo dõi; symbol không có trên tài khoản bị tắt |
| 1 | `InpAtrTimeframe` | `M15` | Khung ATR(14) — quyết định **D-03** |
| 1 | `InpLevelNearestMode` | `Nearest by price` | "Gần nhất" khi chọn P3/P4 — **D-02** |
| 1 | `InpSwingRefMode` | `Setup extreme` | Swing tham chiếu SL/invalidation — **D-01** |
| 1 | `InpSwingLookbackBars` | `672` | Cửa sổ tìm P3/P4 (672 nến M15 ≈ 7 ngày) |
| 1 | `InpEnableSweep` / `InpEnableBreakout` | `true` | Bật/tắt từng chiến lược |
| 1 | `InpMaxStartupBarAgeSec` | `60` | Lúc khởi động chỉ đánh giá nến vừa đóng ≤ 60 s (không tạo tín hiệu cũ) |
| 2 | `InpLotMode` | `Fixed LotSize` | **D-04**; đổi sang `RiskPercent` nếu muốn |
| 2 | `InpLotSize` | `0.01` | Lot cố định — sai bước volume/min/max ⇒ lệnh bị từ chối, **không** tự làm tròn |
| 2 | `InpRiskPercent` / `InpRiskBase` | `0.50` / `Balance` | Chỉ dùng ở chế độ RiskPercent (làm tròn xuống; < min lot ⇒ từ chối) |
| 2 | `InpDailyLossLimit` | `0` | Tiền tài khoản; `0` = tắt. Khi đạt: từ chối ACCEPT mới tới ngày server kế tiếp |
| 3 | `InpMagicNumber` | `4112026` | Nhận diện lệnh/vị thế của EA |
| 3 | `InpCloseDeviationPoints` | `50` | Trượt giá tối đa khi đóng do invalidation |
| 3 | `InpAllowEaManagedExpiry` | `false` | Chỉ bật nếu broker không hỗ trợ expiration "Specified" (EA phải online để xoá lệnh) |
| 4 | Telegram | — | Xem hướng dẫn Telegram |
| 5 | `InpShowDashboard`, `InpLogLevel`, `InpLogToFile` | `true`, `Info`, `true` | Hiển thị & log |
| 6 | `InpTesterAutoApprove` | `false` | **Chỉ trong Strategy Tester**; bật trên chart thật ⇒ EA từ chối khởi động |

Các tham số chiến lược của SRS (0.05–0.50 ATR, 0.10 ATR, 0.15 ATR, 4 nến, buffer, RR 1:2, 15/30 phút, Pivot 3-3) **không** phải input — nằm trong `LLB_Defines.mqh` để không bị đổi nhầm.

## 8. Sau khi gắn EA — tự kiểm tra

| Kiểm tra | Mong đợi |
|---|---|
| Tab Experts | `init`, `SYMBOL …` (thông số symbol), `startup recovery`, `bot verified`, không có `ERROR` |
| Dashboard | `Broker OK`, `HEDGING`/`NETTING`, `TG OK @bot`; mỗi symbol có Bid/Ask, ATR, P1–P4 sau nến M15 đầu tiên |
| Telegram | Tin `started on account …` |
| File | `MQL5\Files\4LLB\<login>_<magic>\` có `system_state.dat`, sau tín hiệu đầu có `signals.csv` |

### Dữ liệu lưu trữ (`MQL5\Files\4LLB\<login>_<magic>\`)

| File | Nội dung |
|---|---|
| `signals.csv` | Mỗi lần Proposal đổi trạng thái thêm một dòng: Signal ID, Entry/SL/TP, created/expiration, quyết định Telegram + user, Execution ID, lý do |
| `executions.csv` | Ghi `SUBMITTING` **trước** khi gửi lệnh; retcode, ticket, position, volume, giá khớp |
| `positions.csv` | Vị thế: SL/TP, trạng thái cấu trúc, đóng lúc nào, lý do (SL/TP/INVALIDATION/MANUAL…), profit/commission/swap/fee |
| `system_state.dat` | Offset Telegram, số thứ tự Signal ID trong ngày, nến đã đánh giá |
| `logs\4LLB_YYYYMMDD.log` | Log chi tiết (token luôn hiện `***`) |

Có thể mở CSV bằng Excel (dấu phân cách `;`). **Không sửa tay** khi EA đang chạy — mỗi dòng có CRC, dòng bị sửa sẽ bị bỏ qua.

## 9. Phase 5 — Release Gate (bắt buộc theo thứ tự)

### 9.1 Static review + compile

- [ ] Compile EA và script: 0 error.
- [ ] Unit test: `ALL PASSED`.

### 9.2 Backtest (Strategy Tester)

1. Strategy Tester: Expert `4LLB\4LLB_TradingAssistant`, symbol của tài khoản, model **Every tick based on real ticks**.
2. Inputs: `InpSymbols` = đúng symbol đó; `InpTesterAutoApprove = true` (giả lập bạn ACCEPT mọi đề xuất); Telegram tự tắt trong tester (MT5 không cho WebRequest trong tester).
3. Kiểm tra trong tab Journal: Proposal được tạo, lệnh chờ Buy/Sell Stop, hết hạn sau 15/30 phút nếu không khớp, SL/TP đúng, đóng do invalidation.
4. Ghi kết quả (kể cả âm) vào một file log backtest. Backtest auto-approve **không** phản ánh kết quả thật vì bạn có thể REJECT.

### 9.3 Demo forward test (tối thiểu 2–4 tuần, khuyến nghị)

Thực hiện và đánh dấu từng mục trong `Phase4_Test_Plan.md`, tối thiểu:

- [ ] TG-001…TG-006 (ACCEPT, REJECT, bấm 2 lần, bấm sau hết hạn, người không có quyền).
- [ ] EX-001, EX-003, EX-004, EX-007; POS-001, POS-002, POS-005; SI-003…SI-005.
- [ ] Restart: XT-RST-01…05 (tắt/mở EA ở từng thời điểm, xác nhận **không có lệnh trùng**).
- [ ] Mất mạng/Telegram: XT-TG-01, XT-RST-06, XT-NET-04.
- [ ] Hai instance: XT-MULTI-02/03 bị từ chối.
- [ ] Đọc `signals.csv`/`executions.csv`/`positions.csv` khớp với lịch sử MT5.

### 9.4 Điều kiện được chạy Real

- Toàn bộ mục Critical/High ở trên **PASS** có bằng chứng (log, CSV, ảnh chụp).
- Không có lệnh trùng, không có lệnh không qua ACCEPT trong suốt thời gian demo.
- Bạn hiểu rằng hiệu quả chiến lược chưa được chứng minh; bắt đầu với khối lượng nhỏ nhất.

## 10. Dừng EA an toàn

- Gỡ EA khỏi chart: lệnh chờ đang có vẫn tự hết hạn đúng giờ trên server (expiration "Specified"); vị thế mở vẫn giữ SL/TP ở broker.
- Khi gắn lại, EA tự đối soát và theo dõi tiếp; Proposal cũ đã hết hạn không bao giờ được giao dịch.

## 11. Nâng cấp / đổi máy

- Copy cả thư mục `MQL5\Files\4LLB\` sang máy mới để giữ lịch sử và trạng thái.
- Không chạy cùng lúc trên hai máy với cùng bot token (Telegram chỉ cho một nơi đọc tin).
