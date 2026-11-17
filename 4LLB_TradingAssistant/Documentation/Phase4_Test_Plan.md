# Phase 4 — Test Plan & Verification

**Nguyên tắc:** cột *Actual* chỉ được điền sau khi test thật sự chạy. Trạng thái:

- `PASS (static)` — đã chứng minh bằng kiểm tra tĩnh trong repo (`Tools/mql5_static_check.py`).
- `PASS (ref-model)` — thuật toán đúng trên mô hình tham chiếu Python (`Tools/reference_model_test.py`), **chưa** chạy bằng MQL5.
- `READY (unit)` — đã có trong `4LLB_UnitTests.mq5`, chờ người dùng chạy trên MT5.
- `NOT RUN (tester)` / `NOT RUN (demo)` — cần Strategy Tester hoặc tài khoản Demo.
- `BLOCKED` — chờ điều kiện khác.

> Mã test SRS (F-, SL-, SI-, TG-, EX-, POS-) được **suy ra** từ baseline vì SRS gốc chưa được đính kèm (A-30). Hãy đối chiếu với SRS gốc; nếu nội dung khác, báo lại để chỉnh.

## 1. Chuẩn bị (người dùng thực hiện)

1. Copy `MQL5/` vào Data Folder (xem `Installation_Guide.md`).
2. MetaEditor → mở `Experts/4LLB/4LLB_TradingAssistant.mq5` → **F7**. Ghi lại số *errors/warnings*.
3. MetaEditor → mở `Scripts/4LLB/4LLB_UnitTests.mq5` → **F7** → MT5: kéo script vào một chart bất kỳ → tab *Experts* phải có `4LLB UNIT TESTS: N passed, 0 failed` và `ALL PASSED`.
4. Gửi lại: tab *Errors* (nếu có), toàn bộ dòng `FAIL …` (nếu có).

## 2. Ma trận test SRS

### 2.1 Strategy (F-001 … F-007)

| ID | Mục tiêu | Fixture / precondition | Bước | Expected | Actual | Status | Evidence |
|---|---|---|---|---|---|---|---|
| F-001 | P1–P4 đúng D1 broker + Pivot 3-3 đã xác nhận, "gần nhất" theo giá (D-02) | Bars tổng hợp 40 nến (U-LVL-01…07); chart thật XAUUSD | Unit test; trên demo so dashboard với chart (D1 trước, pivot thấy được) | P4=106, P3=94 (giá); 108/92 (thời gian); dashboard khớp chart | Ref-model khớp | PASS (ref-model) · READY (unit) · NOT RUN (demo) | log `bar … evaluated` (log level Debug) + ảnh chụp dashboard |
| F-002 | Sweep SELL tại P1/P4 | Nến (103.5,104.8,102.9,103.2), PDH 104, ATR 4 | Unit test | SELL P1, Entry 102.89, swing 104.8 | Ref-model khớp | PASS (ref-model) · READY (unit) | output script |
| F-003 | Sweep BUY tại P2/P3 | Nến (96.3,97.1,95.2,96.8), PDL 96 | Unit test | BUY P2, Entry 97.11, swing 95.2; P3 được ưu tiên khi quét cả hai | Ref-model khớp | PASS (ref-model) · READY (unit) | |
| F-004 | Breakout BUY P4 + retest + nến tăng | close 107.0 > 106.4; low retest 106.3 | Unit test | BUY P4, Entry 107.41, swing 106.3 | Ref-model khớp | PASS (ref-model) · READY (unit) | |
| F-005 | Breakout SELL P3 | close 93.0 < 93.6; high retest 93.8 | Unit test | SELL P3, Entry 92.59, swing 93.8 | Ref-model khớp | PASS (ref-model) · READY (unit) | |
| F-006 | Không retest trong 4 nến → hết hiệu lực | Retest ở nến thứ 5 | Unit test | Không tín hiệu | Ref-model khớp | PASS (ref-model) · READY (unit) | |
| F-007 | Thiếu mức / sai thứ tự → không tín hiệu | PDH 110 (không có P4) | Unit test U-LVL-04/06 | `P4_MISSING`, không Proposal | Ref-model khớp | PASS (ref-model) · READY (unit) | |

### 2.2 Stop Loss (SL-001 … SL-004)

| ID | Mục tiêu | Fixture | Expected | Status |
|---|---|---|---|---|
| SL-001 | BUY SL = SwingLow − Buffer, TP = 2R | Entry 97.11, swing 95.2, ATR 4 | SL 95.00, TP 101.33, RR 2.00 | PASS (ref-model) · READY (unit) |
| SL-002 | SELL SL = SwingHigh + Buffer | Entry 102.89, swing 104.8 | SL 105.00, TP 98.67 | PASS (ref-model) · READY (unit) |
| SL-003 | Buffer = max(2 tick, 0.05 ATR) | ATR 0.2 → buffer 0.02 | SL 95.18 | PASS (ref-model) · READY (unit) |
| SL-004 | Làm tròn tick: BUY xuống, SELL lên; tick 0.001 (XAUUSDc) | 95.175→95.17; 104.825→104.83 | đúng chiều | PASS (ref-model) · READY (unit) |

### 2.3 Structure Invalidation (SI-001 … SI-005)

| ID | Mục tiêu | Precondition | Bước | Expected | Status | Evidence |
|---|---|---|---|---|---|---|
| SI-001 | BUY: `Bid ≤ swing low` → invalidated | Chuỗi tick tổng hợp | Unit test | touch tại tick 3000 ms | PASS (ref-model) · READY (unit) | |
| SI-002 | SELL: `Ask ≥ swing high` | như trên | Unit test | touch tại 1000 ms | PASS (ref-model) · READY (unit) | |
| SI-003 | Touch-based, không chờ nến đóng; không bỏ sót tick giữa 2 lần timer | Demo: Proposal ACTIVE, giá chạm swing trong nến | Quan sát log `TOUCH … at hh:mm:ss.mmm` | thời điểm touch < thời điểm đóng nến; Proposal INVALIDATED ngay | READY (unit) · NOT RUN (demo) | log + tin Telegram đã sửa |
| SI-004 | Trước ACCEPT: INVALIDATED/EXPIRED, ACCEPT cũ mất hiệu lực | Demo: để Proposal bị chạm rồi bấm ACCEPT | Bấm ACCEPT sau khi touch | Trả lời `Already INVALIDATED`, không lệnh | READY (unit, U-SM/PRP) · NOT RUN (demo) | Telegram + `signals.csv` |
| SI-005 | Sau khi khớp: touch → yêu cầu đóng; SL broker vẫn còn | Demo: vị thế mở, giá chạm swing | Quan sát | `STRUCTURE INVALIDATED - closing`, deal đóng do EA, close reason `INVALIDATION`; nếu đóng thất bại SL broker vẫn giữ | NOT RUN (demo) | `positions.csv`, lịch sử deal |

### 2.4 Telegram (TG-001 … TG-006)

| ID | Mục tiêu | Bước | Expected | Status |
|---|---|---|---|---|
| TG-001 | Tin Proposal đủ trường + 2 nút | Unit test `TestMessages`; demo: nhận tin thật | Đủ Signal ID, Symbol, Strategy, Direction, Level, Entry, SL, TP, RR, Expiration, Reason (+ATR, Bid/Ask, Spread, Created, Swing) | READY (unit) · NOT RUN (demo) |
| TG-002 | ACCEPT hợp lệ → Buy/Sell Stop | Demo: bấm ACCEPT khi Proposal ACTIVE, giá chưa vượt Entry | Trả lời `ACCEPTED - pending order placed`, lệnh chờ đúng giá/SL/TP/expiration, `EXECUTED` | NOT RUN (demo) |
| TG-003 | REJECT → REJECTED, không lệnh | Demo: bấm REJECT | `REJECTED`, không có lệnh, quyết định + user id trong `signals.csv` | NOT RUN (demo) |
| TG-004 | Callback lạ/không thuộc allowlist bị từ chối | Unit test U-AUTH; demo: người khác trong group bấm | `Not authorized.`, không đổi trạng thái, log `UNAUTHORIZED_CALLBACK` | READY (unit) · NOT RUN (demo) |
| TG-005 | ACCEPT sau hết hạn / sau invalidation bị từ chối, không gia hạn | Unit test PRP; demo: chờ quá 15 phút rồi bấm | `Refused: proposal EXPIRED`; expiration lệnh = expiration Proposal | READY (unit) · NOT RUN (demo) |
| TG-006 | Idempotent: bấm ACCEPT 2 lần / update lặp | Demo: bấm nhanh 2 lần; restart EA (offset) | Lần 2: `Already EXECUTED - nothing changed`; đúng 1 lệnh | NOT RUN (demo) |

### 2.5 Execution (EX-001 … EX-007)

| ID | Mục tiêu | Bước | Expected | Status |
|---|---|---|---|---|
| EX-001 | Chỉ lệnh chờ đúng loại | Demo ACCEPT BUY & SELL | `BUY_STOP` / `SELL_STOP`, magic, comment `4LLB|E…` | PASS (static: chỉ `TRADE_ACTION_PENDING` để mở lệnh) · NOT RUN (demo) |
| EX-002 | Precheck: trade mode, phiên, stops level, volume, margin | Demo: lot không hợp lệ (vd 0.015), AutoTrading tắt | ACCEPT bị từ chối với lý do, Proposal vẫn ACTIVE | READY (unit volume) · NOT RUN (demo) |
| EX-003 | Expiration lệnh = expiration Proposal | Demo: không khớp trong 15 phút | Broker tự huỷ lúc hết hạn → `PENDING ORDER EXPIRED` | NOT RUN (demo) |
| EX-004 | Giá đã vượt Entry → không market order | Demo: ACCEPT khi Ask ≥ Entry (BUY) | `Refused … PRICE_ALREADY_AT_OR_ABOVE_ENTRY (no market order)` | PASS (static: không có lệnh market mở vị thế) · NOT RUN (demo) |
| EX-005 | 1 Signal ID → tối đa 1 lần thực thi, kể cả restart | Restart ngay sau ACCEPT; bấm ACCEPT lại | Không lệnh thứ hai (`EXECUTION_RECORD_ALREADY_EXISTS` / `ALREADY_ON_BROKER`) | READY (unit U-SM-12, U-ID-04) · NOT RUN (demo) |
| EX-006 | Kết quả không xác định → không gửi lại, reconcile | Ngắt mạng đúng lúc gửi (khó tái tạo; có thể giả lập bằng tắt Internet khi bấm ACCEPT) | `RESULT UNKNOWN … NOT re-sent`; sau reconcile: EXECUTED (thấy lệnh) hoặc EXECUTION_FAILED (không thấy, sau 120 s) | READY (unit U-RC-02) · NOT RUN (demo) |
| EX-007 | Broker reject → EXECUTION_FAILED + retcode + Telegram | Demo: InpLotSize lớn hơn margin (dùng RiskPercent lớn hoặc lot lớn trên demo nhỏ) | Precheck báo `NOT_ENOUGH_MARGIN` hoặc broker reject có retcode | NOT RUN (demo) |

### 2.6 Position (POS-001 … POS-006)

| ID | Mục tiêu | Bước | Expected | Status |
|---|---|---|---|---|
| POS-001 | Chỉ quản lý vị thế của EA | Demo hedging: mở tay 1 lệnh XAUUSD | EA không đọc/đóng/sửa lệnh tay | NOT RUN (demo) |
| POS-002 | SL/TP thực tế được xác minh/gắn | Demo: sau khi khớp, xoá SL bằng tay | EA đặt lại SL đã duyệt; SL tay chặt hơn được giữ nguyên | READY (unit POS-002a/b) · NOT RUN (demo) |
| POS-003 | Đóng do invalidation | = SI-005 | close reason `INVALIDATION` | NOT RUN (demo) |
| POS-004 | Không nới SL, không trailing/BE | Unit + review | `LLB_SlWithinApproved`, `ModifyPositionStops` từ chối nới | PASS (static/review) · READY (unit) |
| POS-005 | Ghi nhận đóng SL/TP/thủ công + commission/swap/profit | Demo: để chạm TP; đóng tay một vị thế | `positions.csv`: `TP` / `MANUAL`, profit, commission, swap, fee | NOT RUN (demo) |
| POS-006 | Không partial close, martingale, grid, scaling | Review mã | Không có đường code nào tăng/giảm volume vị thế ngoài đóng toàn bộ | PASS (static/review) |

## 3. Test mở rộng (XT-)

| ID | Tình huống | Expected | Status |
|---|---|---|---|
| XT-INIT-01 | Gắn EA với input hợp lệ | Log `init`, dashboard, Telegram "started" | NOT RUN |
| XT-INIT-02 | Tài khoản chỉ có XAUUSDc | XAUUSD `DISABLED` trên dashboard, XAUUSDc chạy | NOT RUN |
| XT-DATA-01 | Lịch sử thiếu (symbol mới thêm) | `data not ready`, không đánh dấu nến, thử lại; quá 60 s thì bỏ qua nến đó có log | NOT RUN |
| XT-MKT-01 | Thị trường đóng (cuối tuần) | ACCEPT bị từ chối `MARKET_CLOSED` | NOT RUN |
| XT-MKT-02 | Spread bất thường | Proposal vẫn tạo, spread hiển thị (SRS không có ngưỡng, A-27) | NOT RUN |
| XT-MKT-03 | Symbol trade mode DISABLED/CLOSEONLY | ACCEPT bị từ chối `SYMBOL_TRADE_MODE_…` | NOT RUN |
| XT-TICK-01 | Tick size ≠ point | Làm tròn theo tick size | PASS (ref-model) · READY (unit U-NORM-08/09) |
| XT-BRK-01 | Stops level / freeze level | Entry/SL/TP trong stops level → từ chối; xoá lệnh trong freeze level → thử lại | NOT RUN |
| XT-BRK-02 | Volume min/max/step | Lot không hợp lệ → từ chối, không làm tròn | READY (unit U-VOL) |
| XT-BRK-03 | Khớp một phần | `PARTIAL`, vị thế được theo dõi với volume thực | NOT RUN |
| XT-BRK-04 | Requote / price changed | Reject rõ ràng → EXECUTION_FAILED, không gửi lại | READY (unit U-RC-03) |
| XT-TG-01 | Telegram timeout / mất Internet | Dashboard `TG network error`, backoff; phân tích & hết hạn vẫn chạy | NOT RUN |
| XT-TG-02 | Update lặp / restart mất offset | Xử lý idempotent | NOT RUN |
| XT-TG-03 | Callback sai thứ tự (REJECT sau ACCEPT) | `Already EXECUTED - nothing changed` | READY (unit U-SM) |
| XT-TG-04 | Chat ID lạ | `Not authorized.` | READY (unit U-AUTH) |
| XT-RST-01 | Restart khi Proposal ACTIVE | Còn hạn → vẫn ACTIVE (đã quét tick lúc tắt); bị chạm lúc tắt → INVALIDATED | NOT RUN |
| XT-RST-02 | Restart sau ACCEPT, trước khi gửi | `RESTART_BEFORE_SUBMIT` → EXECUTION_FAILED, không lệnh | NOT RUN |
| XT-RST-03 | Restart khi bản ghi SUBMITTING | Thấy lệnh → EXECUTED; không thấy → EXECUTION_FAILED; không gửi lại | NOT RUN |
| XT-RST-04 | Restart khi lệnh chờ đang sống | Lệnh được theo dõi tiếp, expiration broker vẫn chạy | NOT RUN |
| XT-RST-05 | Restart sau khi khớp | Vị thế được theo dõi tiếp, quét touch khoảng downtime | NOT RUN |
| XT-RST-06 | Mất kết nối broker rồi có lại | Thông báo + reconcile | NOT RUN |
| XT-MULTI-01 | Hai symbol cùng ra tín hiệu | Hai Proposal độc lập, ID khác nhau | NOT RUN (cần tài khoản có cả hai symbol) |
| XT-MULTI-02 | Gắn EA lên chart thứ hai cùng tài khoản/magic | Instance thứ hai `INIT_FAILED` (lock) | NOT RUN |
| XT-MULTI-03 | Hai terminal cùng máy dùng chung bot token | Terminal thứ hai `INIT_FAILED` (lock Telegram) | NOT RUN |
| XT-NET-01 | Tài khoản netting | Chỉ thực thi khi symbol không có vị thế/lệnh khác | NOT RUN (cần tài khoản netting) |
| XT-NET-02 | Netting: mở tay cùng symbol sau khi EA khớp | `OWNERSHIP CONFLICT`, EA không đóng/sửa | NOT RUN |
| XT-NET-03 | Hedging: vị thế tay cùng symbol | Không bị ảnh hưởng | NOT RUN |
| XT-NET-04 | Tắt EA khi có vị thế | SL/TP broker vẫn còn trên lệnh | NOT RUN |
| XT-PER-01 | Xoá `system_state.dat` | Khởi động lại từ journal + comment broker, không trùng Signal ID | NOT RUN |
| XT-PER-02 | Sửa tay 1 dòng `signals.csv` | Dòng sai CRC bị bỏ qua + cảnh báo | READY (unit U-CSV-04) |
| XT-PER-03 | Dòng ghi dở (cắt cuối file) | Bị bỏ qua | READY (unit U-CSV-05) |
| XT-EXP-01 | Broker không có SPECIFIED expiration | ACCEPT bị từ chối (mặc định) hoặc GTC + EA xoá (`InpAllowEaManagedExpiry=true`) | NOT RUN |
| XT-DLL-01 | Daily Loss Limit | Đạt ngưỡng → ACCEPT bị từ chối đến ngày server sau | NOT RUN |
| XT-DUP-01/02 | Chống trùng | Không tạo lại cho cùng nến / khi Proposal trước còn hiệu lực | READY (unit) |
| XT-INV-01 | Touch khi lệnh chờ đang sống | Lệnh chờ bị xoá (`CANCELLED_EA`) | NOT RUN |
| XT-DSH-01 | Dashboard đủ 6 nhóm thông tin, không có nút | Quan sát | NOT RUN |
| XT-STATIC-01 | `OrderSend` chỉ ở ExecutionManager | | PASS (static) |
| XT-STATIC-02 | Không hardcode token | | PASS (static) |
| XT-STATIC-03 | Token không đi vào log | | PASS (static) + `Redact` |

## 4. Backtest (Strategy Tester) — sau khi compile

| Thiết lập | Giá trị |
|---|---|
| Expert | `4LLB\4LLB_TradingAssistant` |
| Symbol | `XAUUSD` hoặc `XAUUSDc` (symbol của tài khoản) — đặt `InpSymbols` chỉ symbol đó |
| Model | *Every tick based on real ticks* |
| Inputs | `InpTesterAutoApprove=true` (giả lập ACCEPT mọi Proposal — chỉ có hiệu lực trong tester) |

Ghi kết quả vào `Backtest_Log.md` như dự án trước (kể cả kết quả âm). Backtest với auto-approve **không** đại diện cho kết quả thực tế vì người dùng có thể REJECT.

## 5. Bằng chứng hiện có (2026-11-17)

```text
$ python3 Tools/mql5_static_check.py MQL5
0 error(s), 0 warning(s)
$ python3 Tools/reference_model_test.py
REFERENCE MODEL: 50 passed, 0 failed
```

## PHASE 4 REPORT

```text
PHASE: 4 — Testing & Verification
STATUS: BLOCKED (chờ compile + chạy unit test trên MT5 của người dùng)
1. Deliverables: test plan (SRS + XT), script 4LLB_UnitTests.mq5 (139 assert), 2 công cụ kiểm tra.
2. Requirements covered: mọi requirement có ít nhất một test (bảng trên).
3. Technical decisions: test SRS được suy ra từ baseline (A-30).
4. Tests executed: static 0 lỗi; reference model 50/50. Chưa chạy MQL5.
5. Open issues: toàn bộ test demo NOT RUN.
6. User decisions required: không; cần người dùng compile/chạy và gửi kết quả.
7. Next: Phase 5 (backtest → demo). Entry: 0 compile error + unit test ALL PASSED.
```
