# Phase 0 — SRS Audit, Requirement Traceability & Ambiguity Register

**Dự án:** 4LLB Human-Approved Trading Assistant EA v2.0 (MT5 / MQL5)
**Nguồn chuẩn:** `Source/4LLB_Trading_Assistant_Claude_Master_Prompt.md` — mục §4 "SRS Baseline" (bản SRS đầy đủ `4LLB HUMAN-APPROVED TRADING ASSISTANT – VERSION 2.0` **không được đính kèm**, xem A-30).
**Ngày:** 2026-11-17
**Môi trường thực hiện:** Linux container, **không có MetaTrader 5 / MetaEditor / kết nối broker**. API MQL5 được đối chiếu với tài liệu chính thức `www.mql5.com/en/docs` (đọc ngày 2026-11-17).

Nhãn trạng thái dùng trong tài liệu: `Designed` → `Implemented` → `Compiled` → `Tested` → `Backtested` → `Demo-verified` → `Production-ready`. Chỉ gắn nhãn khi có bằng chứng.

---

## 1. Quyết định của người dùng (đã chốt ngày 2026-11-17)

| ID | Câu hỏi Critical | Quyết định | Hệ quả triển khai |
|---|---|---|---|
| **D-01** | Swing tham chiếu cho SL & touch-invalidation (SRS mâu thuẫn: "swing của cú sweep/retest" vs "phải là Pivot 3-3 đã xác nhận") | **Cực trị cấu trúc setup** | Sweep: High (SELL) / Low (BUY) của nến sweep. Breakout: Low thấp nhất (BUY) / High cao nhất (SELL) từ nến ngay sau nến breakout đến nến xác nhận. Input `InpSwingRefMode` cho phép chuyển sang "Pivot 3-3 đã xác nhận". |
| **D-02** | Nghĩa của "gần nhất" khi chọn P3/P4 | **Gần nhất theo giá** | P3 = Pivot Low đã xác nhận có giá **cao nhất** nhưng < PDL; P4 = Pivot High đã xác nhận có giá **thấp nhất** nhưng > PDH, trong cửa sổ `InpSwingLookbackBars`. Input `InpLevelNearestMode` cho phép đổi sang "theo thời gian". |
| **D-03** | Khung ATR | **ATR(14) M15** đọc tại nến đã đóng | Input `InpAtrTimeframe` (mặc định M15). Chu kỳ 14 là hằng số SRS. |
| **D-04** | Chế độ khối lượng | **LotSize cố định** (mặc định) | Có input `InpLotMode` = `FIXED_LOT` / `RISK_PERCENT` (+ `InpRiskBase` = Balance/Equity). RiskPercent làm tròn xuống, < min lot → từ chối. |

---

## 2. Requirement IDs và Traceability (Requirement → Module → Test)

Loại: **S** = SRS bắt buộc · **D** = quyết định người dùng · **A** = giả định kỹ thuật (xem §3) · **T** = thành phần kỹ thuật tối thiểu để thực hiện an toàn.

Module (Phase 1): `CRD` Coordinator · `MKT` MarketData · `LVL` LevelEngine · `STR` StrategyEngine · `SLC` StopLossCalculator · `PRP` ProposalManager · `TGW` TelegramGateway · `APR` ApprovalManager · `RSK` Risk/Volume · `EXE` ExecutionManager · `POS` PositionManager · `PER` PersistenceManager · `DSH` Dashboard · `LOG` Logger.

Mã test SRS (F-, SL-, SI-, TG-, EX-, POS-) được **suy ra** từ baseline vì SRS gốc không đính kèm (A-30). Test mở rộng dùng tiền tố `XT-`, unit test dùng `U-`.

### 2.1 Cấu hình nền tảng

| ID | Yêu cầu | Loại | Module | Test |
|---|---|---|---|---|
| R-CFG-01 | EA "4LLB Trading Assistant" v2.0, MT5/MQL5 | S | CRD | XT-INIT-01 |
| R-CFG-02 | Symbols `XAUUSD`, `XAUUSDc` (broker Exness); symbol không tồn tại → vô hiệu hoá riêng symbol đó, cảnh báo | S+A-24 | CRD, MKT | XT-INIT-02 |
| R-CFG-03 | Phân tích D1 + M15 | S | LVL, STR | F-001 |
| R-CFG-04 | Swing = Pivot 3-3 | S | LVL | U-PIV-*, F-001 |
| R-CFG-05 | Hai chiến lược Sweep + Breakout độc lập | S | STR | F-002…F-006 |
| R-CFG-06 | Phê duyệt qua Telegram Inline Keyboard | S | TGW, APR | TG-001 |
| R-CFG-07 | Thực thi tự động **chỉ** sau ACCEPT hợp lệ | S | APR, EXE | TG-002, EX-001 |
| R-CFG-08 | Không trailing, BE, grid, martingale, hedging strategy; tương thích account mode | S | EXE, POS | POS-006, XT-NET-* |
| R-CRD-01 | Một Coordinator duy nhất theo dõi cả hai symbol | S | CRD | XT-MULTI-01 |
| R-CRD-02 | Chống hai Coordinator chạy cùng tài khoản/magic | T | CRD | XT-MULTI-02 |

### 2.2 Bốn mức thanh khoản

| ID | Yêu cầu | Loại | Module | Test |
|---|---|---|---|---|
| R-LVL-01 | P1 = PDH, P2 = PDL từ nến D1 **đã đóng gần nhất** của broker | S | LVL | F-001, U-LVL-01 |
| R-LVL-02 | Ngày giao dịch theo lịch broker (server time), không theo UTC/Windows | S | LVL, MKT | U-LVL-05 |
| R-LVL-03 | P3 = Swing Low đã xác nhận gần nhất dưới PDL | S+D-02 | LVL | U-LVL-02 |
| R-LVL-04 | P4 = Swing High đã xác nhận gần nhất trên PDH | S+D-02 | LVL | U-LVL-03 |
| R-LVL-05 | Bắt buộc `P3 < PDL < PDH < P4`; thiếu mức nào → không tạo tín hiệu | S | LVL, STR | U-LVL-04, F-007 |
| R-LVL-06 | Pivot 3-3 chỉ xác nhận khi đủ 3 nến phải **đã đóng**; không repaint, không dữ liệu tương lai | S | LVL | U-PIV-01…04 |

### 2.3 Liquidity Sweep

| ID | Yêu cầu | Loại | Module | Test |
|---|---|---|---|---|
| R-SWP-01 | SELL tại P1/P4: High xuyên lên trên level | S | STR | F-002 |
| R-SWP-02 | Độ sâu sweep ∈ [0.05, 0.50] ATR (đo theo A-01) | S+A-01 | STR | U-SWP-02/03 |
| R-SWP-03 | Nến M15 đóng lại dưới level (SELL) / trên level (BUY) | S | STR | U-SWP-04 |
| R-SWP-04 | Nến xác nhận giảm `Close<Open` (SELL) / tăng `Close>Open` (BUY) | S | STR | U-SWP-05 |
| R-SWP-05 | Entry = Low − 1 tick (SELL) / High + 1 tick (BUY) | S | STR | U-SWP-01 |
| R-SWP-06 | SL ngoài Swing của cú sweep (D-01) | S+D-01 | STR, SLC | SL-001 |
| R-SWP-07 | TP theo RR 1:2 | S | SLC | SL-003 |
| R-SWP-08 | BUY tại P2/P3 đối xứng R-SWP-01…07 | S | STR | F-003 |
| R-SWP-09 | Sweep Proposal hết hạn sau 15 phút kể từ lúc tạo | S | PRP | SI-004 |

### 2.4 Breakout

| ID | Yêu cầu | Loại | Module | Test |
|---|---|---|---|---|
| R-BRK-01 | BUY P4: nến M15 đóng trên `P4 + 0.10 ATR` | S+A-03 | STR | F-004 |
| R-BRK-02 | Retest P4 trong tối đa 4 nến M15 tiếp theo | S+A-03 | STR | U-BRK-03/04 |
| R-BRK-03 | Retest nằm trong phạm vi 0.15 ATR | S+A-03 | STR | U-BRK-05 |
| R-BRK-04 | Nến xác nhận đóng tăng (BUY) / giảm (SELL) | S | STR | U-BRK-06 |
| R-BRK-05 | Entry = High + 1 tick (BUY) / Low − 1 tick (SELL) của nến xác nhận | S | STR | U-BRK-01 |
| R-BRK-06 | SL ngoài Swing của cấu trúc retest (D-01) | S+D-01 | STR, SLC | SL-002 |
| R-BRK-07 | TP theo RR 1:2 | S | SLC | SL-003 |
| R-BRK-08 | SELL P3 đối xứng (đóng dưới `P3 − 0.10 ATR`) | S | STR | F-005 |
| R-BRK-09 | Không có retest trong 4 nến → setup hết hiệu lực | S | STR | F-006 |
| R-BRK-10 | Breakout Proposal hết hạn sau 30 phút | S | PRP | SI-004 |

### 2.5 Stop Loss & Invalidation

| ID | Yêu cầu | Loại | Module | Test |
|---|---|---|---|---|
| R-SLC-01 | BUY `SL = SwingLow − Buffer`; SELL `SL = SwingHigh + Buffer` | S | SLC | SL-001/002 |
| R-SLC-02 | `Buffer = max(2 × TickSize, 0.05 × ATR14)` | S | SLC | U-SL-01 |
| R-SLC-03 | Chuẩn hoá theo Tick Size: BUY làm tròn SL **xuống**, SELL làm tròn **lên** | S | SLC | U-SL-02, SL-004 |
| R-SLC-04 | Swing cho SL phải là Pivot 3-3 đã xác nhận — **mâu thuẫn**, giải quyết bằng D-01 | S→D-01 | SLC | U-SL-04 |
| R-SLC-05 | Không tự di chuyển SL khi có swing mới | S | SLC, POS | POS-004 |
| R-SLC-06 | Entry/SL/TP sai hướng hoặc khoảng cách ≤ 0 → loại Proposal, không sửa giá | S (prompt) | SLC | U-SL-05 |
| R-INV-01 | BUY invalidation `Bid ≤ SwingLow`; SELL `Ask ≥ SwingHigh` | S | PRP, POS | SI-001/002 |
| R-INV-02 | Touch-based, không chờ nến đóng | S | PRP, MKT | SI-003 |
| R-INV-03 | Trước ACCEPT: Proposal → INVALIDATED, ACCEPT cũ mất hiệu lực | S | PRP, APR | SI-004, TG-004 |
| R-INV-04 | Sau khi khớp: ghi nhận invalidation, yêu cầu đóng vị thế; SL broker vẫn tồn tại | S | POS, EXE | SI-005, POS-003 |
| R-INV-05 | Sau ACCEPT, trước khi khớp (lệnh chờ đang sống): xoá lệnh chờ (suy ra từ bất biến #4, A-21) | A-21 | POS, EXE | XT-INV-01 |

### 2.6 Proposal & State

| ID | Yêu cầu | Loại | Module | Test |
|---|---|---|---|---|
| R-PRP-01 | Trường tối thiểu: Signal ID, Symbol, Strategy, Direction, Liquidity Level, Entry, SL, TP, RR, ATR, Bid/Ask, Spread, Created, Expiration, Reference Swing, Reason | S | PRP | U-ID-*, TG-001 |
| R-PRP-02 | Signal ID duy nhất dạng `4LLB-XAUUSD-SWEEP-BUY-20261117-0001` | S | PRP | U-ID-01/02 |
| R-PRP-03 | Không tạo Proposal trùng cho cùng cơ hội khi Proposal trước còn hiệu lực (A-14) | S+A-14 | PRP | XT-DUP-01/02 |
| R-PRP-04 | ACCEPT không gia hạn expiration | S | APR, EXE | TG-005 |
| R-PRP-05 | Proposal có thể bị invalidated trước khi hết hạn | S | PRP | SI-004 |
| R-PRP-06 | Trạng thái `ACTIVE, ACCEPTED, REJECTED, EXPIRED, INVALIDATED, EXECUTING, EXECUTED, EXECUTION_FAILED` | S | PRP | U-SM-* |

### 2.7 Telegram

| ID | Yêu cầu | Loại | Module | Test |
|---|---|---|---|---|
| R-TGM-01 | Một Gateway duy nhất cho mỗi Bot Token, không polling song song | S | TGW | XT-MULTI-03 |
| R-TGM-02 | Nội dung: Symbol, Strategy, Direction, Level, Entry, SL, TP, RR, Expiration, Signal ID, Reason | S | TGW | TG-001 |
| R-TGM-03 | Inline keyboard ACCEPT / REJECT | S | TGW | TG-001 |
| R-TGM-04 | Callback data `ACCEPT|SignalID`, `REJECT|SignalID` (≤ 64 byte) | S | TGW, APR | U-ID-03 |
| R-TGM-05 | ACCEPT kiểm tra: allowlist, Signal ID, ACTIVE, expiration, invalidation, giá hiện tại, chưa thực thi | S | APR | TG-002…TG-005 |
| R-TGM-06 | Không đạt → từ chối và báo lý do | S | APR, TGW | TG-004 |
| R-TGM-07 | REJECT → REJECTED, không gửi lệnh, ghi quyết định | S | APR | TG-003 |
| R-TGM-08 | ACCEPT/REJECT idempotent | S | APR | TG-006 |

### 2.8 Execution

| ID | Yêu cầu | Loại | Module | Test |
|---|---|---|---|---|
| R-EXE-01 | Chỉ ExecutionManager gửi/sửa/xoá giao dịch | S | EXE | XT-STATIC-01 (grep `OrderSend`) |
| R-EXE-02 | Trước khi gửi: kiểm tra Proposal, giá, trade mode, volume, stop level, margin, volume step, giới hạn broker | S | EXE, RSK | EX-002, XT-BRK-* |
| R-EXE-03 | Chỉ lệnh chờ: BUY → Buy Stop, SELL → Sell Stop | S | EXE | EX-001 |
| R-EXE-04 | Pending order có expiration phù hợp Proposal (A-07) | S+A-07 | EXE | EX-003 |
| R-EXE-05 | Không chuyển thành market order khi giá đã qua Entry | S | EXE, APR | EX-004 |
| R-EXE-06 | Mỗi Signal ID tối đa một lần thực thi; Execution ID duy nhất | S | EXE, PER | EX-005 |
| R-EXE-07 | Ghi `SUBMITTING` trước khi gửi; reconciliation Orders/Deals/Positions | S | EXE, PER | EX-006, XT-RST-* |
| R-EXE-08 | Không retry mù khi kết quả chưa xác định | S | EXE | EX-006 |
| R-EXE-09 | Broker từ chối → lưu retcode, EXECUTION_FAILED, Telegram | S | EXE | EX-007 |
| R-EXE-10 | Sau khi khớp, xác minh SL/TP thực tế | S | POS | POS-002 |

### 2.9 Risk

| ID | Yêu cầu | Loại | Module | Test |
|---|---|---|---|---|
| R-RSK-01 | LotSize hoặc RiskPercent do người dùng chọn (D-04) | S+D-04 | RSK | U-VOL-* |
| R-RSK-02 | Daily Loss Limit tuỳ chọn (A-10) | S+A-10 | RSK | XT-DLL-01 |
| R-RSK-03 | Không Portfolio/Dynamic risk, không tự scale | S | RSK | Review |
| R-RSK-04 | LotSize: dùng đúng giá trị, kiểm tra hợp lệ, không tự tăng/giảm | S | RSK | U-VOL-01/02 |
| R-RSK-05 | RiskPercent: tính từ Entry–SL, làm tròn xuống, không vượt ngân sách | S | RSK | U-VOL-03…05 |

### 2.10 Position Manager

| ID | Yêu cầu | Loại | Module | Test |
|---|---|---|---|---|
| R-POS-01 | Chỉ quản lý vị thế của EA (magic + mã giao dịch trong comment, A-31) | S | POS | POS-001, XT-NET-02 |
| R-POS-02 | Phát hiện vị thế, kiểm SL/TP, theo dõi touch invalidation, yêu cầu đóng | S | POS | POS-002/003 |
| R-POS-03 | Ghi nhận đóng SL/TP/thủ công, commission, swap, profit, close reason | S | POS, PER | POS-005 |
| R-POS-04 | Không trailing/BE/partial close/martingale/grid/scaling | S | POS | POS-006 |
| R-POS-05 | SL/TP broker độc lập kết nối EA | S | EXE | XT-NET-04 |
| R-POS-06 | Khi kết nối lại: thông báo + reconciliation | S | POS, TGW | XT-RST-06 |
| R-POS-07 | Hỗ trợ netting & hedging theo `ACCOUNT_MARGIN_MODE`, không chạm vị thế ngoài EA (A-12) | S+A-12 | POS, EXE | XT-NET-01…03 |

### 2.11 Dashboard, Persistence, Security, Invariants

| ID | Yêu cầu | Loại | Module | Test |
|---|---|---|---|---|
| R-DSH-01…06 | Market, Liquidity, Signal, Proposal, Execution, Position panels | S | DSH | XT-DSH-01 |
| R-DSH-07 | Dashboard chỉ hiển thị, không gửi lệnh | S | DSH | XT-STATIC-01 |
| R-PER-01 | `MQL5/Files/4LLB/`: `signals.csv`, `executions.csv`, `positions.csv`, `system_state.dat` (A-34: thư mục con theo tài khoản) | S+A-34 | PER | XT-PER-01 |
| R-PER-02 | Lưu Signal ID, trạng thái, quyết định Telegram, Execution ID, Order/Deal/Position ID, Entry/SL/TP, Volume, thời gian, Close Reason | S | PER | XT-PER-02 |
| R-PER-03 | Restart: tải state, đối chiếu broker, không gửi lại lệnh đã thực thi | S | PER, EXE | XT-RST-01…05 |
| R-SEC-01 | Không hardcode Bot Token | S | TGW | XT-STATIC-02 |
| R-SEC-02 | Không ghi Token vào log | S | LOG, TGW | XT-STATIC-03 |
| R-SEC-03 | Chỉ Chat ID allowlist được ACCEPT/REJECT | S | APR | TG-004 |
| R-SEC-04 | Từ chối callback không rõ nguồn và callback cũ làm đổi terminal state | S | APR | TG-006 |
| R-SEC-05 | Một Gateway polling mỗi Bot Token | S | TGW | XT-MULTI-03 |
| R-SEC-06 | Telegram lỗi không dừng Market Analysis Engine | S | CRD, TGW | XT-TG-01 |
| R-SAF-01…12 | 12 Safety Invariants (§4.12 baseline) | S | APR, EXE, POS | Bảng §5 |

---

## 3. Ambiguity / Risk Register

Mức: **C** Critical · **I** Important · **M** Minor. Trạng thái: `Resolved-D` (người dùng quyết định), `Default` (giả định an toàn, có thể đổi), `Risk` (rủi ro cần biết), `Open`.

| ID | Vấn đề | Mức | Xử lý | Trạng thái |
|---|---|---|---|---|
| A-01 | Đo độ sâu sweep và ATR | C | Độ sâu = khoảng cách từ **wick cực trị** tới level (SELL: `High − L`; BUY: `L − Low`). ATR(14) khung D-03 tại **nến tín hiệu đã đóng**. | Default + D-03 |
| A-02 | Sweep 1 nến hay nhiều nến? | I | **Một nến**: chính nến đã đóng vừa xuyên level vừa đóng ngược lại và đúng màu. Mô hình nhiều nến (đóng vượt rồi nến sau đóng quay lại) không được tạo tín hiệu. | Default |
| A-03 | Định nghĩa breakout/retest | C | (a) Nến breakout = nến **đầu tiên** đóng vượt ngưỡng (nến trước đó chưa đóng vượt ngưỡng — để quy tắc "hết hiệu lực sau 4 nến" có nghĩa). (b) Retest xét trên **nến đã đóng**, nến retest **chính là** nến xác nhận. (c) Vùng retest hai phía: BUY `|Low − P4| ≤ 0.15 ATR`, SELL `|High − P3| ≤ 0.15 ATR`. (d) Chỉ nến **đầu tiên** thoả (b)+(c)+màu nến trong 4 nến sau breakout tạo tín hiệu. (e) P3/P4 được chụp tại nến breakout. Nến dip quá sâu không huỷ setup (SRS không quy định), chỉ không được tính là retest. | Default |
| A-04 | Swing tham chiếu SL | C | D-01 | Resolved-D |
| A-05 | Hình học Entry/SL sai | I | Loại candidate, log `GEOMETRY_INVALID`, không sửa giá. | Default |
| A-06 | Nguồn giá invalidation, đa symbol | C | Mỗi symbol quét luồng tick riêng bằng `CopyTicksRange(COPY_TICKS_INFO)` từ thời điểm quét trước (bắt cả touch giữa hai lần timer), cộng `SymbolInfoTick` dự phòng. BUY dùng Bid, SELL dùng Ask. Theo dõi từ **thời điểm đóng nến tín hiệu**. Timer 250 ms. | Default |
| A-07 | Expiration lệnh chờ | C | `ORDER_TIME_SPECIFIED`, `expiration` = Expiration Time tuyệt đối của Proposal. Broker không hỗ trợ `SYMBOL_EXPIRATION_SPECIFIED` → **từ chối thực thi** (fail-safe). Chỉ khi `InpAllowEaManagedExpiry=true` mới dùng GTC + EA tự xoá lúc hết hạn (rủi ro: EA offline thì lệnh còn sống). | Default |
| A-08 | "Kiểm tra giá hiện tại" khi ACCEPT | C | Lệnh chờ phải **còn đặt được**: Buy Stop `Entry > Ask + StopsLevel`, Sell Stop `Entry < Bid − StopsLevel`; SL/TP cách Entry ≥ StopsLevel. SRS không định nghĩa ngưỡng lệch tối đa → **không** thêm ngưỡng. Giá đã vượt Entry → từ chối ACCEPT (giữ ACTIVE), không chuyển market order. | Default |
| A-09 | Chế độ khối lượng | C | D-04. RiskPercent: tiền rủi ro = Balance/Equity × %, lỗ/1 lot tại SL tính bằng `OrderCalcProfit` (tự quy đổi tiền tệ). | Resolved-D |
| A-10 | Daily Loss Limit | I | Tuỳ chọn, `InpDailyLossLimit = 0` = tắt. Khi bật: tổng **P/L đã chốt** của deal thuộc EA (profit + commission + swap + fee) trong ngày server hiện tại; lỗ ≥ ngưỡng → từ chối ACCEPT mới đến ngày server kế tiếp. **Không** tự đóng vị thế, không dừng phân tích. | Default |
| A-11 | Sở hữu Telegram Gateway | C | Một instance EA cho mỗi Bot Token. Khoá file trong thư mục **Common** (khoá theo hash của token, có heartbeat 10 s, quá hạn 45 s) + kiểm tra lại sau khi ghi. Instance thứ hai trên **cùng máy** → `INIT_FAILED`. Khác máy/VPS không thể phát hiện cục bộ → tài liệu hoá; HTTP 409 từ Telegram và callback có Signal ID lạ được cảnh báo. | Default |
| A-12 | Netting account | C | Netting: chỉ thực thi khi symbol **không có** vị thế/lệnh chờ nào khác (kể cả của chính EA). Sau khi khớp, nếu volume vị thế ≠ volume EA đã khớp → `OWNERSHIP_CONFLICT`: không tự đóng/sửa, chỉ cảnh báo. Hedging: quản lý theo `POSITION_IDENTIFIER`. | Default |
| A-13 | Chống nhiều Coordinator | I | Khoá file Common theo `login + magic` (cùng cơ chế A-11). | Default |
| A-14 | "Cùng một cơ hội" | I | Khoá cơ hội = `symbol|strategy|direction|level|thời gian nến tín hiệu` (không bao giờ tạo lại, kể cả sau restart). Ngoài ra, khi còn Proposal `ACTIVE/ACCEPTED/EXECUTING` cùng `symbol|strategy|direction|level` thì không tạo Proposal mới. | Default |
| A-15 | Nguồn thời gian | I | Server time broker (`TimeTradeServer()`, thời gian nến, `time_msc` của tick) cho mọi mốc; Telegram hiển thị kèm nhãn "(giờ server)". | Default |
| A-16 | Giới hạn WebRequest | I | `WebRequest` đồng bộ, chặn luồng EA; không chạy trong tester; cần thêm `https://api.telegram.org` vào allowlist. Short polling (`timeout=0`) mỗi 1.5 s, HTTP timeout 5 s, backoff luỹ thừa tới 60 s khi lỗi. Touch-invalidation dùng lịch sử tick nên không bỏ sót dù luồng bị chặn tạm thời. | Default |
| A-17 | Nghĩa "gần nhất" P3/P4 | C | D-02 | Resolved-D |
| A-18 | Khung ATR | C | D-03 | Resolved-D |
| A-19 | Pivot bằng nhau | M | Bất đẳng thức **chặt** hai phía (`High[i] > High[i±k]`, k=1..3). Đỉnh/đáy bằng nhau không tạo pivot. | Default |
| A-20 | Một nến sweep hai level cùng phía | M | Mỗi (symbol, strategy, direction, nến) tối đa một Proposal; ưu tiên level **ngoài** (P4 trước P1, P3 trước P2); Reason ghi cả hai. | Default |
| A-21 | Invalidation khi lệnh chờ đã đặt nhưng chưa khớp | I | Xoá lệnh chờ (bất biến #4). Nếu không xoá kịp và lệnh khớp → vị thế được đánh dấu invalidated và yêu cầu đóng ngay. | Default |
| A-22 | Restart | C | ACTIVE: hết hạn → EXPIRED; quét tick khoảng downtime, có touch → INVALIDATED; không lấy được tick → INVALIDATED (fail-safe). ACCEPTED chưa có bản ghi gửi lệnh → EXECUTION_FAILED. SUBMITTING/UNKNOWN → reconciliation: tìm thấy lệnh → EXECUTED; không thấy (khi terminal đã kết nối ổn định) → EXECUTION_FAILED. Nến đóng **trước** khi EA khởi động chỉ được đánh giá nếu đóng ≤ `InpMaxStartupBarAgeSec` giây trước đó. | Default |
| A-23 | Nến D1 Chủ nhật (Exness dùng GMT+0) | I | SRS ghi rõ "nến D1 đã đóng gần nhất của broker" → giữ nguyên. Hệ quả: thứ Hai có thể lấy PDH/PDL từ nến Chủ nhật ngắn. Đề xuất cải tiến E-01 (chưa triển khai). | Risk |
| A-24 | XAUUSD và XAUUSDc thường thuộc **hai loại tài khoản** Exness khác nhau (Pro/Raw/Zero vs Standard Cent, dữ liệu dự án trước: XAUUSDc trên tài khoản USC) | C | EA tự vô hiệu hoá symbol không tồn tại. Hai tài khoản → hai terminal → **hai Bot Token** (A-11). | Risk |
| A-25 | Strategy Tester | I | Telegram tự tắt trong tester. `InpTesterAutoApprove` (chỉ hoạt động trong tester; bật trên chart thật → `INIT_FAILED`) để backtest luồng thực thi. | Default |
| A-26 | Proposal tạo khi giá đã vượt Entry | M | Vẫn tạo (SRS không có bộ lọc), tin nhắn cảnh báo; ACCEPT sẽ bị từ chối nếu giá vẫn ở phía bên kia Entry. | Default |
| A-27 | Spread bất thường | M | SRS không có ngưỡng → không lọc; hiển thị spread. Đề xuất E-02. | Default |
| A-28 | Level của breakout | M | Dùng P3/P4 tính tại nến breakout (không dùng level cập nhật sau đó). | Default |
| A-29 | Nhiều vị thế EA cùng symbol | I | Hedging: cho phép (mỗi lệnh do người dùng duyệt riêng). Netting: một lệnh/vị thế mỗi symbol (A-12). | Default |
| A-30 | SRS đầy đủ không đính kèm | I | Nội dung test F-001…POS-006 được suy ra từ baseline; **cần đối chiếu** với SRS gốc. | Open |
| A-31 | "Mã giao dịch" nhận diện lệnh EA | M | Comment lệnh `4LLB|E<YYMMDD><NNNN>`; Execution ID suy ra 1-1 từ Signal ID (ngày + số thứ tự); bổ sung khớp tham số (magic, symbol, loại, giá, SL, TP, volume) khi comment bị mất. | Default |
| A-32 | SL/TP thực tế khác dự kiến | I | Thử đặt lại **đúng** giá trị dự kiến (không bao giờ nới SL); nếu giá đã vượt SL dự kiến (không đặt được) → đóng vị thế (giảm rủi ro), thông báo. Lệnh chờ sai SL/TP → xoá lệnh. | Default |
| A-33 | Đóng vị thế do invalidation thất bại | I | Thử lại có giới hạn tốc độ (≥ 5 s), trước mỗi lần gửi xác minh lại vị thế còn mở và thuộc EA; kết quả không xác định → chờ reconciliation trước khi gửi lại. | Default |
| A-34 | Nhiều tài khoản dùng chung một terminal/thư mục dữ liệu | I | Lưu tại `MQL5/Files/4LLB/<login>_<magic>/` để không trộn dữ liệu. Token đọc từ `MQL5/Files/4LLB/telegram_token.txt`. | Default |
| A-35 | Telegram callback không có thời điểm bấm nút | M | Mọi kiểm tra (expiration, invalidation, giá) thực hiện **tại thời điểm xử lý**; callback đến trễ vẫn bị từ chối nếu Proposal không còn hợp lệ. | Default |

### 3.1 Phân loại câu hỏi

- **Critical đã hỏi và chốt:** A-04 (D-01), A-17 (D-02), A-18 (D-03), A-09 (D-04).
- **Critical giải quyết bằng default an toàn (có thể đổi nếu người dùng muốn):** A-01, A-03, A-06, A-07, A-08, A-11, A-12, A-22.
- **Important:** A-02, A-10, A-13, A-14, A-15, A-16, A-21, A-23, A-24, A-25, A-29, A-30, A-32, A-33, A-34.
- **Minor:** A-19, A-20, A-26, A-27, A-28, A-31, A-35.

## 4. Đề xuất cải tiến (KHÔNG có trong baseline, chưa triển khai)

| ID | Đề xuất | Lý do |
|---|---|---|
| E-01 | Bỏ qua nến D1 Chủ nhật khi tính PDH/PDL | A-23 |
| E-02 | Ngưỡng spread tối đa tại thời điểm ACCEPT | A-27 |
| E-03 | Lệnh `/status` trên Telegram (chỉ đọc) | Giám sát từ xa |
| E-04 | Khoá Gateway liên máy (dịch vụ ngoài) | A-11 không phát hiện được instance khác máy |

## 5. Safety Invariants → cơ chế bảo vệ

| # | Bất biến | Cơ chế (đều nằm ở tầng ApprovalManager/ExecutionManager, không phụ thuộc UI) |
|---|---|---|
| 1 | Không ACCEPT hợp lệ → không giao dịch | `ExecutionManager.Execute` chỉ nhận Proposal ở trạng thái `ACCEPTED` có `decision=ACCEPT` từ ID trong allowlist; ExecutionManager tự kiểm tra lại |
| 2 | REJECT → không giao dịch | REJECT là terminal state; `Execute` từ chối mọi state ≠ ACCEPTED |
| 3 | Expired → không giao dịch | Kiểm tra `now < expiresAt` ở ApprovalManager **và** ngay trước `OrderSend` |
| 4 | Invalidated → không giao dịch | Quét touch tươi ngay trước ACCEPT; xoá lệnh chờ khi touch sau ACCEPT |
| 5 | Một Signal ID → tối đa một lần thực thi | Execution ID suy ra 1-1 từ Signal ID; journal + quét comment broker trước khi gửi |
| 6 | SL/TP không hợp lệ → không gửi | Kiểm tra hình học + StopsLevel + `OrderCheck` |
| 7 | Volume không hợp lệ → không gửi | Kiểm tra min/max/step/limit; không làm tròn lên |
| 8 | Broker reject → không retry mù | Retcode phân loại: reject rõ ràng → FAILED; không rõ → UNKNOWN + reconciliation, không gửi lại |
| 9 | Không nới SL | Chỉ một hàm sửa SL/TP, chỉ chấp nhận giá trị bằng đúng SL dự kiến |
| 10 | Không chuyển pending → market | Chỉ dùng `TRADE_ACTION_PENDING` + `ORDER_TYPE_BUY_STOP/SELL_STOP` cho mở lệnh; `TRADE_ACTION_DEAL` chỉ dùng để **đóng** vị thế EA |
| 11 | Không giao dịch tín hiệu cũ sau restart | A-22 |
| 12 | Không chạm vị thế ngoài EA | Mọi thao tác xác minh magic + comment/ID + symbol (+ volume trên netting) |

## 6. Kiến trúc sơ bộ

Xem `Phase1_Architecture.md` (đã được thiết kế sau khi chốt D-01…D-04).

---

## PHASE 0 REPORT

```text
PHASE: 0 — SRS Audit & Ambiguity Register
STATUS: PASS

1. Deliverables completed: Requirement IDs (§2), traceability Requirement→Module→Test (§2),
   ambiguity/risk register 35 mục (§3), phân loại câu hỏi (§3.1), đề xuất cải tiến tách riêng (§4),
   ánh xạ 12 safety invariants (§5).
2. Requirements covered: toàn bộ §4.1–§4.12 của baseline.
3. Technical decisions: A-01…A-35 (Default, có thể đổi); D-01…D-04 do người dùng chốt.
4. Tests executed and evidence: không áp dụng (phase phân tích). API MQL5 đối chiếu tài liệu chính thức.
5. Open issues / risks: A-23 (nến Chủ nhật), A-24 (hai symbol thường ở hai loại tài khoản),
   A-30 (SRS gốc chưa có để đối chiếu mã test), A-11 (không phát hiện instance khác máy).
6. User decisions required: không còn câu Critical chặn thiết kế. Người dùng có thể phản đối bất kỳ Default nào.
7. Next phase: Phase 1 — Architecture. Entry condition: D-01…D-04 đã chốt (đạt).
```
