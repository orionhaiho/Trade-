# Phase 0 & Phase 1 — Requirement Traceability và Ambiguity Review

**Dự án:** XAUUSDc Adaptive Mean-Reversion Grid EA (MT5 / MQL5)
**Nguồn chuẩn:** `Source/EA_XAUUSDc_Adaptive_Grid_M1_Specification.md` (v1.0) + `Source/Claude_Master_Prompt_XAUUSDc_Adaptive_Grid.md`
**Trạng thái tài liệu:** Phân tích. **Chưa có code. Chưa compile. Chưa backtest.**
**Môi trường hiện có:** Linux container, **không có MetaTrader 5 / MetaEditor / kết nối broker / tick data** → mọi hạng mục compile/test sau này sẽ ghi `NOT VERIFIED` cho tới khi người dùng tự chạy.

---

## 0. Xác nhận

Đã đọc toàn bộ 17 mục của đặc tả nguồn (bao gồm §16 prompt gốc và §17 nguồn tham khảo) và toàn bộ master prompt. Các tham số trong đặc tả được coi là **tham số nghiên cứu ban đầu**, không phải tham số đã tối ưu hay đã chứng minh có lợi nhuận.

## 1. Tóm tắt chiến lược

| Thành phần | Nội dung |
|---|---|
| Symbol / TF | `XAUUSDc`, tín hiệu M1, chỉ nến đã đóng |
| Chỉ báo | BB(20, 2.0, Close), RSI(7, Close), ADX(14), ATR(14) |
| Vào BUY | ADX < 22; RSI(7) ≤ 25; nến setup Close < Lower BB; nến xác nhận kế tiếp Close > Lower BB |
| Vào SELL | Đối xứng: ADX < 22; RSI ≥ 75; setup Close > Upper BB; xác nhận Close < Upper BB |
| Grid | `GridDistance = clamp(ATR(14)×0.80, 0.50, 1.50)` (đơn vị giá), thêm BUY khi `Bid ≤ LastBuyFill − GD`, thêm SELL khi `Ask ≥ LastSellFill + GD` |
| Volume | 0.01 mỗi tầng, multiplier 1.0, ≤ 5 tầng, ≤ 0.05 lot mỗi phía |
| Basket | BUY magic 10001, SELL magic 10002, độc lập; Hedging bắt buộc |
| Basket TP / SL | TP +1.50 USC net; SL = −(1% Equity lúc mở Basket) ≈ −5 USC |
| Global | Combined floating loss 10 USC; Daily loss 10 USC; Equity DD 25 USC |

**Hệ quả rủi ro quan trọng nhất (tham khảo, chưa xác minh trên broker):**

- TP/SL = 1.5 / 5 → Win rate hòa vốn trước chi phí ≈ **76.92%**. Spread trên mỗi tầng ăn trực tiếp vào TP 1.5 USC.
- Nếu đúng quy ước cent (0.01 lot ≈ 1 USC cho mỗi 1 USD giá), với ATR = 0.80, spread = 0.20, stress = 1×ATR sau khi khớp, ví dụ tính tay cho BUY:

| Tầng | Giá khớp (so với F1) | Stress Bid | Tổng lỗ stress (USC) | So với budget 5 USC |
|---|---|---|---|---|
| 1 | F1 | F1 − 1.00 | 1.00 | OK |
| 2 | F1 − 0.44 | F1 − 1.44 | 1.44 + 1.00 = 2.44 | OK |
| 3 | F1 − 0.88 | F1 − 1.88 | 1.88 + 1.44 + 1.00 = 4.32 | OK (sát) |
| 4 | F1 − 1.32 | F1 − 2.32 | 2.32 + 1.88 + 1.44 + 1.00 = 6.64 | **TỪ CHỐI** |

  (Tầng n được kích hoạt khi Bid ≤ F(n−1) − 0.64, khớp ở Ask = Bid + 0.20 → mỗi tầng cách nhau ~0.44 theo giá khớp.)
  ⇒ Với cấu hình mặc định, **risk gate sẽ là giới hạn thực tế (~3 tầng), không phải MaxLayers = 5**. Đây là hành vi đúng theo đặc tả, không phải lỗi. Con số chỉ minh họa; runtime phải dùng `OrderCalcProfit()`.

---

## 2. Requirement Traceability Matrix (RTM) — khởi tạo

Loại: **B** = bắt buộc, **D** = mặc định (có input), **O** = tùy chọn, **A** = giả định đề xuất. Trạng thái hiện tại của tất cả: `NOT VERIFIED` (chưa có code).

| ID | Yêu cầu | Loại | Module | Cách kiểm chứng |
|---|---|---|---|---|
| ENV-01 | Symbol `XAUUSDc` tồn tại, select được, trade mode cho phép; không tự đổi tên | B | AG_Environment | Init log; test symbol sai → INIT_FAILED |
| ENV-02 | Chart symbol phải = `InpSymbol` | A | AG_Environment | Gắn sai chart → INIT_FAILED |
| ENV-03 | `InpTF` phải = M1 | B | AG_Environment | Input khác → INIT_FAILED |
| ENV-04 | `ACCOUNT_MARGIN_MODE` = Retail Hedging, Netting → INIT_FAILED | B | AG_Environment | Tài khoản netting demo |
| ENV-05 | Đọc runtime: VOLUME_MIN/MAX/STEP, CONTRACT_SIZE, TICK_SIZE, TICK_VALUE, POINT, DIGITS, STOPS_LEVEL, FREEZE_LEVEL, FILLING_MODE, ACCOUNT_CURRENCY; không hard-code | B | AG_Environment | Log specs; grep code không có hằng broker |
| ENV-06 | Xác minh account currency (kỳ vọng `USC`) | B | AG_Environment | Log; currency khác → INIT_FAILED (xem A-06) |
| ENV-07 | Sanity-check `OrderCalcProfit()` (dấu, >0, hữu hạn) cho 1 USD move với min lot | A | AG_Environment | Log giá trị; lỗi → INIT_FAILED |
| ENV-08 | `LotMultiplier` ≠ 1.0 → INIT_FAILED | B | AG_Environment | Input test |
| IND-01 | Tạo handle BB/RSI/ADX/ATR trên M1, kiểm tra INVALID_HANDLE, giải phóng ở OnDeinit | B | AG_Indicators | Code review + log |
| IND-02 | Đọc bằng CopyBuffer từ nến đã đóng; thiếu dữ liệu → không giao dịch | B | AG_Indicators | Test BarsCalculated thấp |
| SIG-01 | BUY/SELL theo mapping shift §3 (P1-01) | B | AG_Signals | Unit test trên chuỗi nến giả |
| SIG-02 | Không dùng cùng một nến vừa xuyên band vừa xác nhận (mặc định) | B | AG_Signals | Unit test |
| SIG-03 | Input chọn cách diễn giải nến | B | AG_Signals | Input test |
| SIG-04 | Chỉ đánh giá entry trên nến mới (UseNewBarOnly) | D | AG_Signals | Log bar time |
| GRD-01 | GridDistance = clamp(ATR×mult, min, max), chuẩn hóa tick size | B | AG_GridManager | Unit test |
| GRD-02 | Mốc grid = giá khớp thực tế (`POSITION_PRICE_OPEN`) của tầng mới nhất | B | AG_GridManager | Test |
| GRD-03 | ≤ MaxLayers, ≤ MaxSideLots, volume cố định | B | AG_GridManager | Unit test |
| GRD-04 | ≤ 1 lệnh mới / nến M1 / phía; cooldown | B | AG_GridManager | Unit test nhiều tick + restart |
| GRD-05 | Không thêm tầng khi ADX ≥ MaxADX, spread cao, risk, margin, volume, pending | B | AG_GridManager | Log reason |
| RSK-01 | Budget snapshot = EquityAtStart × 1% (tùy chọn Balance), bất biến trong Basket | B | AG_RiskManager | Unit test + persist |
| RSK-02 | Stress gate toàn Basket + lệnh mới bằng OrderCalcProfit, có spread/slippage/phí | B | AG_RiskManager | Unit test |
| RSK-03 | Combined risk BUY+SELL trước mọi lệnh mới | B | AG_RiskManager | Unit test |
| RSK-04 | Min volume vượt budget → không giao dịch, không nâng lot | B | AG_RiskManager | Unit test |
| BSK-01 | Lọc symbol + magic + type cho mọi thao tác | B | AG_BasketManager | Test có lệnh manual/EA khác |
| BSK-02 | Net P/L = profit + swap + commission + fee (quy thuộc) | B | AG_BasketManager | Unit test phí |
| BSK-03 | TP/SL → CLOSING, đóng theo ticket, retry giới hạn, xác nhận hết position | B | AG_BasketManager/AG_Execution | Test lỗi đóng |
| BSK-04 | Không mở Basket mới cùng phía khi CLOSING chưa xong | B | AG_BasketManager | Test |
| GLB-01 | Combined floating loss ≥ 10 USC → đóng tất cả + Global Lock | B | AG_RiskManager | Test |
| GLB-02 | Daily loss theo server day → đóng + Daily Lock tới ngày sau | B | AG_RiskManager | Test qua nửa đêm/restart |
| GLB-03 | Equity DD 25 USC từ mốc tham chiếu → đóng + Equity Lock | B | AG_RiskManager | Test |
| GLB-04 | Lock persist qua restart, không tự xóa | B | AG_Recovery | Restart test |
| GLB-05 | Mức tiền có input; tùy chọn theo % | D | Inputs | Input test |
| EXE-01 | Kiểm tra margin (`OrderCalcMargin`/`OrderCheck`), volume, giá, spread trước gửi | B | AG_Execution | Code review |
| EXE-02 | Xử lý retcode: requote, price changed, market closed, no connection, invalid volume/stops, no money, partial | B | AG_Execution | Bảng retcode + test |
| EXE-03 | Không gửi lệnh khi còn request chưa hoàn tất | B | AG_Execution | Test |
| EXE-04 | MaxSpreadUSD là Ask−Bid theo giá; log cả raw và point-equivalent | B | AG_Execution | Log |
| EXE-05 | Không mở khi thị trường đóng / ngoài phiên / rollover được cấu hình | B | AG_Environment | Test session |
| EXE-06 | News filter có input bật/tắt; không giả định hoạt động | O | AG_Signals | Log trạng thái |
| EXE-07 | ATR bất thường / vượt ngưỡng → không mở Basket mới | B | AG_Signals | Unit test |
| REC-01 | Khôi phục Basket từ positions + state file có version | B | AG_Recovery | Restart test |
| REC-02 | Không khôi phục được → SAFE MODE, không mở lệnh mới | B | AG_Recovery | Xóa/hỏng state file |
| REC-03 | Không tạo lệnh trùng sau restart | B | AG_Recovery | Restart giữa ENTRY_PENDING |
| LOG-01 | CSV đủ trường theo master prompt §7 Phase 7 | B | AG_Logger | SampleLog.csv |
| LOG-02 | Dashboard phân biệt VALID / INVALID / UNKNOWN | B | AG_Logger | Visual check |
| DOC-01..10 | Deliverables §15 đặc tả / §9 master prompt | B | Documentation | Checklist |
| PRH-01 | Cấm Martingale, lot tăng, grid vô hạn, đóng lệnh không thuộc EA, bịa kết quả | B | Toàn bộ | Code review |

---

## 3. Điều kiện cấm giao dịch & SAFE MODE

### 3.1. INIT_FAILED (không khởi tạo)

Symbol không tồn tại / không select được; chart symbol ≠ InpSymbol; InpTF ≠ M1; tài khoản Netting/Exchange; account currency không khớp `RequiredAccountCurrency`; volume min/max/step, tick size, contract size ≤ 0; `OrderCalcProfit()` sanity check thất bại; `LotMultiplier ≠ 1.0`; `InitialLot` không chuẩn hóa được về đúng giá trị (sau normalize lệch so với input); handle indicator invalid; input logic sai (min > max grid, MaxLayers < 1, …); không ghi được state file khi `RequirePersistentState = true`.

### 3.2. Chặn lệnh mới (vẫn quản lý Basket đang mở)

Bất kỳ Lock nào đang bật; terminal/EA không được phép trade (`TERMINAL_TRADE_ALLOWED`, `MQL_TRADE_ALLOWED`, `ACCOUNT_TRADE_EXPERT`); không kết nối; ngoài phiên giao dịch / trong cửa sổ rollover; spread > MaxSpreadUSD; dữ liệu indicator thiếu hoặc NaN/0; ATR ≤ 0 hoặc > MaxATRUSD; ADX ≥ MaxADX; đang có request chưa hoàn tất; phía đó đang CLOSING / RECOVERY / SAFE_MODE; risk gate (Basket, combined, daily headroom) không qua; margin không đủ; min volume vượt budget; cùng nến M1 đã có lệnh mới cho phía đó; cooldown chưa hết; tick cũ (quote không cập nhật).

### 3.3. SAFE MODE (theo từng phía hoặc toàn EA)

State file thiếu/hỏng/sai version **trong khi** có position thuộc EA; số position/volume vượt MaxLayers/MaxSideLots (bất thường); position có magic EA nhưng sai type phía; không đọc được deal history cho position đang mở; budget không khôi phục được. Trong SAFE MODE: không mở/thêm lệnh; vẫn tính P/L và áp dụng TP, SL dự phòng (P1-12) và mọi Global/Daily/Equity lock; log + dashboard yêu cầu can thiệp.

## 4. Dữ liệu runtime phải đọc

Symbol: `SYMBOL_EXIST/SELECT`, `SYMBOL_TRADE_MODE`, `SYMBOL_TRADE_EXEMODE`, `SYMBOL_FILLING_MODE`, `SYMBOL_VOLUME_MIN/MAX/STEP/LIMIT`, `SYMBOL_TRADE_CONTRACT_SIZE`, `SYMBOL_TRADE_TICK_SIZE`, `SYMBOL_TRADE_TICK_VALUE(_PROFIT/_LOSS)`, `SYMBOL_POINT`, `SYMBOL_DIGITS`, `SYMBOL_TRADE_STOPS_LEVEL`, `SYMBOL_TRADE_FREEZE_LEVEL`, `SYMBOL_CURRENCY_PROFIT/MARGIN`, `SymbolInfoSessionTrade()`, `SymbolInfoTick()`.
Account: `ACCOUNT_CURRENCY`, `ACCOUNT_MARGIN_MODE`, `ACCOUNT_LEVERAGE`, `ACCOUNT_BALANCE/EQUITY/MARGIN_FREE/MARGIN_LEVEL`, `ACCOUNT_TRADE_ALLOWED/EXPERT`, `ACCOUNT_LOGIN`, `ACCOUNT_SERVER`.
Terminal: `TERMINAL_CONNECTED`, `TERMINAL_TRADE_ALLOWED`, `MQL_TESTER`, `MQL_OPTIMIZATION`, `TimeTradeServer()`.
History: `HistorySelectByPosition()`, `DEAL_COMMISSION`, `DEAL_FEE`, `DEAL_SWAP`, `DEAL_PROFIT`, `DEAL_MAGIC`, `DEAL_ENTRY`, `DEAL_TYPE_BALANCE` (nạp/rút).

Không giá trị nào trong số này được điền sẵn trong code.

---

## 5. Phase 1 — Bảng điểm mơ hồ / mâu thuẫn / rủi ro

Phân loại: **BLOCKER** = cần người dùng xác nhận; **SAFE DEFAULT** = đề xuất mặc định an toàn, tiếp tục sau khi công khai; **NON-BLOCKING** = xử lý trong thiết kế.

| ID | Vấn đề | Cách hiểu có thể | Rủi ro nếu sai | Đề xuất mặc định | Phân loại |
|---|---|---|---|---|---|
| P1-01 | Shift nến setup/confirm, RSI "tại nến trước khi xác nhận", ADX "tại nến tín hiệu" | (a) 2 nến: setup = shift 2, confirm = shift 1; (b) 1 nến: low xuyên band, close quay vào | Look-ahead hoặc tín hiệu sai | `SignalMode = TWO_CANDLE` (mặc định): setup `Close[2] < LowerBB[2]`, confirm `Close[1] > LowerBB[1]`, **RSI tại shift 2 (setup)**, **ADX tại shift 1 (confirm = nến tín hiệu)**. BB so với BB của chính nến đó. Mode `SINGLE_CANDLE_WICK` (Low[1] < LowerBB[1] && Close[1] > LowerBB[1], RSI/ADX shift 1) chỉ là tùy chọn, mặc định OFF. Đối xứng cho SELL. Đánh giá 1 lần tại tick đầu của nến mới. | SAFE DEFAULT |
| P1-02 | ADX ≥ MaxADX khi Basket đang mở | Ngừng quản lý / chỉ ngừng thêm tầng | Ngừng quản lý TP/SL = lỗi nghiêm trọng | ADX (shift 1) chỉ là **gate cho lệnh mới** (entry + add). Quản lý TP/SL/lock luôn chạy mỗi tick, **trước** mọi logic tín hiệu và độc lập dữ liệu indicator. `EmergencyCloseOnRegime = false` (tùy chọn, mặc định OFF). | NON-BLOCKING |
| P1-03 | Budget vs TP/SL cố định; `UseBasketSLFromRiskBudget=false` không có SL input | Không có SL / SL cố định | Basket không có SL | Thêm `BasketSL_USC = 5.00`. Effective SL = `UseBasketSLFromRiskBudget ? Budget : min(BasketSL_USC, Budget)` — **SL không bao giờ rộng hơn budget**. Stress gate luôn dùng Budget. TP = `BasketTP_USC` cố định (không suy ra từ budget). | SAFE DEFAULT |
| P1-04 | Mô hình stress trước lệnh mới | Stress từ giá hiện tại / từ giá khớp / tại SL | Thêm tầng vượt budget | Giá vào dự kiến = Ask (BUY) + slippage buffer (`MaxSlippagePoints × POINT`). Stress exit BUY = `Bid_now − StressMoveATR × ATR[1] − SpreadBuffer` (SELL đối xứng trên Ask). Mỗi position hiện hữu + lệnh mới: `OrderCalcProfit(type, vol, open, stressExit)`. `StressLoss = −Σprofit − Σswap_now − Σ(entry comm+fee đã trả) − Σ(exit comm ước tính)`. Điều kiện: `StressLoss ≤ Budget`. Phí entry đã trả lấy từ deal history; phí exit ước tính = phí entry tương ứng (đối xứng) hoặc `CommissionPerLotEstimate` nếu chưa có lịch sử — mỗi khoản chỉ đếm 1 lần. Swap tương lai không dự phóng. | SAFE DEFAULT |
| P1-05 | Min volume vs budget | Nâng lot / bỏ qua | Vượt rủi ro | Normalize về step; nếu volume yêu cầu < min hoặc normalize làm đổi giá trị → **từ chối, log**. Nếu stress của **1 lệnh min volume** > Budget → không mở Basket (log `MIN_LOT_EXCEEDS_BUDGET`). Không bao giờ round up vượt input. | NON-BLOCKING |
| P1-06 | Currency/cent | `OrderCalcProfit` trả USD hay USC | Sai 100× | Mọi ngưỡng tiền tính theo **đơn vị ACCOUNT_CURRENCY**. Input `RequiredAccountCurrency = "USC"`; khác → INIT_FAILED. Init log kết quả `OrderCalcProfit` cho 1 USD move với min volume, kèm giá trị kỳ vọng tham khảo (~1 USC) dưới dạng **cảnh báo, không tự sửa**. Người dùng xác minh trên demo. | SAFE DEFAULT |
| P1-07 | Commission/fee attribution | Comm trong profit / trong deal | Đếm trùng/bỏ sót | `POSITION_PROFIT` không chứa commission → floating = profit + swap; phí entry = Σ `DEAL_COMMISSION + DEAL_FEE` của các deal thuộc `POSITION_IDENTIFIER` (HistorySelectByPosition). Position đã đóng trong Basket (khi CLOSING một phần) → lấy realized từ deal OUT (profit+swap+comm+fee) và bỏ khỏi floating. Cache theo position ID. Không giả định comm = 0. | NON-BLOCKING |
| P1-08 | Daily loss: công thức & mốc | Account equity / EA-only; floating qua đêm | Reset sai, đếm trùng | **EA-scope**: `DailyPL = RealizedToday + FloatingNow − FloatingAtDayStart`. `RealizedToday` = Σ deal (symbol + 2 magic, time ≥ 00:00 server hôm nay) profit+swap+comm+fee — **tái dựng được từ history**, tự loại nạp/rút. `FloatingAtDayStart` snapshot lúc tick đầu ngày, persist; nếu mất trong ngày → dùng 0 (bảo thủ hơn). Lock khi `DailyPL ≤ −DailyLoss`. Ngày = `TimeTradeServer()`. | BLOCKER (Q1) — liên quan tài khoản dùng chung |
| P1-09 | Equity DD: HWM vs initial vs mốc cấu hình | 3 cách | Lock quá sớm / quá muộn | `EquityDDReference = HIGH_WATER_MARK` (mặc định, chặt nhất), tùy chọn `INITIAL_EQUITY` / `FIXED_VALUE`. Account equity; HWM persist; nạp/rút (`DEAL_TYPE_BALANCE`) điều chỉnh HWM tương ứng. Không trộn cách tính. | BLOCKER (Q2) |
| P1-10 | Global combined loss — phạm vi | Floating / + realized | Trùng với Daily | `Combined = NetFloating(BUY) + NetFloating(SELL)` (floating + swap + phí entry quy thuộc của position **đang mở**). Không gồm realized (thuộc Daily). Lock khi `Combined ≤ −MaxCombinedLoss`. | NON-BLOCKING |
| P1-11 | Lock policy | Tự reset / thủ công | Mở lại giao dịch sai lúc | DAILY_LOCK: tự mở khi sang ngày server mới. GLOBAL_LOCK & EQUITY_LOCK: **reset thủ công** qua input `ResetLockToken` (số nguyên; EA chỉ reset khi token khác token đã dùng lưu trong state → không reset lặp lại khi restart). Tùy chọn `GlobalLockResetOnNewDay = false`. Ưu tiên: EQUITY > GLOBAL > DAILY. Tất cả persist. | BLOCKER (Q2) |
| P1-12 | Restart thiếu state | Đoán budget / SAFE MODE | Mất kiểm soát rủi ro | State file versioned + checksum, ghi atomic (tmp → move). Thiếu/hỏng khi có position → SAFE MODE phía đó; SL dự phòng `FallbackBudget = min(BasketRiskPercent × EquityNow, BasketSL_USC)`; TP vẫn áp dụng; không thêm tầng. Thoát SAFE MODE khi Basket đóng hết (về IDLE) hoặc reset thủ công. Lock không khôi phục được → **mặc định coi là đang khóa** (fail-closed) cho tới khi reset thủ công. | SAFE DEFAULT |
| P1-13 | Đóng Basket nhiều lần | Gửi đóng mỗi tick | Lệnh đóng trùng | State CLOSING; mỗi ticket có `close_attempts`, `last_attempt_time`; đóng theo ticket với volume hiện tại; retry ≤ `MaxCloseRetries`/chu kỳ, cách nhau `CloseRetryDelayMs`; sau khi hết retry vẫn ở CLOSING, giảm tần suất, cảnh báo — **không bao giờ bỏ CLOSING khi còn position**. Partial fill → đóng phần còn lại. | NON-BLOCKING |
| P1-14 | Hai Basket đồng thời | Kiểm tra riêng | Tổng rủi ro vượt | Gate kép trước mọi lệnh: `StressLoss(side) ≤ Budget(side)` **và** `StressLoss(side) + StressLossOrCurrentLoss(other side) ≤ MaxCombinedLoss` **và** `−DailyPL + StressLoss(side) ≤ DailyLoss` (headroom). | SAFE DEFAULT |
| P1-15 | New bar / cooldown | Cooldown cho entry hay add | Lệnh dồn | Áp dụng **theo từng phía, cho cả entry lẫn add**: ≤ 1 lệnh mới / nến M1 / phía (lưu `LastOrderBarTime[side]` persist) và `now − LastOrderTime[side] ≥ CooldownSeconds`. Entry chỉ xét ở tick đầu nến mới; add xét mọi tick nhưng ≤ 1/nến. Sau restart dựng lại từ thời gian position mới nhất. | SAFE DEFAULT |
| P1-16 | ATR & grid | shift 0/1, rounding | Grid sai | ATR shift 1 (nến đóng). `GD = clamp(ATR×mult, Min, Max)` rồi **làm tròn lên** bội số tick size (không thu hẹp grid). ATR ≤ 0, NaN, hoặc > `MaxATRUSD` → không entry/add. | BLOCKER nhẹ (Q3: giá trị MaxATRUSD) |
| P1-17 | Rollover / news filter | Không có giờ trong đặc tả | Vào lệnh lúc spread giãn | Phiên: dùng `SymbolInfoSessionTrade()` (không hard-code giờ); không mở lệnh mới trong `SessionEdgeBlockMinutes = 15` phút đầu/cuối mỗi phiên trade; thêm cửa sổ `BlockWindowStart/End` server time tùy chọn (mặc định OFF). News filter: input `UseNewsFilter = false`; nếu bật mà Calendar không khả dụng (tester) → log `NEWS_FILTER_UNAVAILABLE` và **không giao dịch** (fail-closed). | BLOCKER nhẹ (Q3) |
| P1-18 | MaxSpreadUSD | pip/point | Sai 10–1000× | `spread_price = Ask − Bid` so với `MaxSpreadUSD`; log thêm `spread_points = spread_price / POINT`. `MaxSlippagePoints` dùng cho `deviation` và buffer giá `= pts × POINT`. | NON-BLOCKING |
| P1-19 | Hedging/netting | `RequireHedgingAccount` = false cho phép netting? | Mô phỏng hedging | Netting **luôn** INIT_FAILED bất kể input (master prompt cấm). Input giữ để tương thích nhưng chỉ log; ghi rõ trong Parameters.md. | NON-BLOCKING (lệch nhỏ khỏi input gốc, công khai) |
| P1-20 | Broker execution | — | Lệnh trùng/treo | Market order, filling mode theo `SYMBOL_FILLING_MODE`; `OrderCheck` trước `OrderSend`; phân loại retcode: DONE/DONE_PARTIAL/PLACED → xác minh position; REQUOTE/PRICE_CHANGED/PRICE_OFF → retry giới hạn với giá mới (chỉ cho close; entry không retry ngoài nến đó); MARKET_CLOSED/TRADE_DISABLED/NO_MONEY/INVALID_VOLUME/INVALID_STOPS → hủy + log; TIMEOUT/CONNECTION/không rõ → **không gửi lại** cho tới khi đối chiếu positions/deals (theo magic + comment `AG|<side>|<basketId>|L<n>`) xác nhận. | NON-BLOCKING |
| P1-21 | Đơn vị volume "0.01 cent lot" | Volume MT5 hay standard lot | Sai 100× | `InitialLot`/`MaxSideLots` là **volume MT5 của symbol XAUUSDc** đúng như hiển thị trong terminal. Không quy đổi. | SAFE DEFAULT |
| P1-22 | Phạm vi lệnh của Global Close | Tất cả lệnh trên symbol / chỉ EA | Đóng nhầm | Chỉ position có symbol = InpSymbol **và** magic ∈ {MagicBuy, MagicSell} **và** type khớp magic. Position có magic EA nhưng type sai → log + SAFE MODE, vẫn **không** tự đóng trừ khi Global/Equity lock (khi đó đóng vì nó thuộc magic EA) — xem Q4. | BLOCKER nhẹ (Q4) |
| P1-23 | "Ngân sách Basket còn lại" | Budget − lỗ đã chịu | Mơ hồ | Budget bất biến; "còn lại" được hiện thực bằng việc StressLoss đã bao gồm toàn bộ P/L hiện tại + phí đã trả của Basket. | NON-BLOCKING |
| P1-24 | `CloseAllOnRiskLimit = false` | Chỉ khóa không đóng | Lỗ tiếp tục chạy | Mặc định true. Nếu false: vẫn khóa lệnh mới, Basket SL vẫn hoạt động, log cảnh báo mỗi lần chạm limit. | NON-BLOCKING |
| P1-25 | Strategy Tester vs live state | State file dùng chung | Tester ghi đè state live | Tên file gồm login + server + symbol + magic + hậu tố `_TESTER` khi `MQL_TESTER`. | NON-BLOCKING |
| P1-26 | Win rate hòa vốn 76.92% & spread | — | Kỳ vọng âm | Không đổi chiến lược. Báo cáo backtest phải tách chi phí; tham số TP 2.5/3.0 chỉ là ma trận nghiên cứu. | NON-BLOCKING |

---

## 6. Assumptions Register (đề xuất, chờ chấp thuận)

| ID | Giả định | Nguồn | Trạng thái |
|---|---|---|---|
| A-01 | Mapping shift P1-01 (TWO_CANDLE, RSI@setup, ADX@confirm) | Đề xuất | Chờ chấp thuận |
| A-02 | Stress model P1-04, `StressMoveATR = 1.0`, buffer spread = spread hiện tại | Đặc tả §5.6 + đề xuất | Chờ chấp thuận |
| A-03 | `BasketSL_USC` mới, SL không rộng hơn budget | Đề xuất | Chờ chấp thuận |
| A-04 | Daily loss EA-scope (P1-08) | Đề xuất | **Q1** |
| A-05 | Equity DD = account equity vs HWM persist | Đề xuất | **Q2** |
| A-06 | `RequiredAccountCurrency = "USC"` | Đặc tả §1.1 | Chờ chấp thuận |
| A-07 | Lock reset: Daily tự động; Global/Equity thủ công bằng token | Master prompt Phase 6 | **Q2** |
| A-08 | Session-edge block 15 phút, MaxATRUSD | Đề xuất | **Q3** |
| A-09 | Cooldown + 1 lệnh/nến áp dụng theo phía cho entry và add | Đề xuất | Chờ chấp thuận |
| A-10 | Netting luôn INIT_FAILED bất kể input | Master prompt §7.1 | Chốt |
| A-11 | State: file versioned + checksum trong `MQL5/Files`, fail-closed | Đặc tả §11 | Chờ chấp thuận |
| A-12 | Chart symbol phải = InpSymbol | Đề xuất | Chờ chấp thuận |

## 7. Câu hỏi cần người dùng xác nhận

**Q1 — Tài khoản có dành riêng cho EA này không?**
Nếu có lệnh thủ công hoặc EA khác trên cùng tài khoản: Daily Loss tính theo EA-scope (đề xuất) sẽ không bị ảnh hưởng, nhưng Equity DD theo **account equity** sẽ bị lệnh ngoài kéo xuống và kích hoạt đóng lệnh của EA. Đề xuất: Daily = EA-scope; Equity DD = account equity (đúng chữ "account drawdown" trong đặc tả). Đồng ý?

**Q2 — Equity DD & mở khóa.**
Đề xuất: mốc = High-Water Mark persist (chặt nhất); Global Lock và Equity Lock chỉ mở bằng reset thủ công (`ResetLockToken`); Daily Lock tự mở ở ngày server tiếp theo. Đồng ý, hay muốn Global Lock cũng tự mở khi sang ngày mới?

**Q3 — Bộ lọc thời gian & ATR.**
Đặc tả không nêu giờ cụ thể. Đề xuất: tránh 15 phút đầu/cuối mỗi phiên trade đọc từ broker, không hard-code giờ; `MaxATRUSD = 3.0` (ATR M1 > 3 USD → không mở lệnh mới). Có khung giờ cụ thể (server time) muốn chặn thêm không?

**Q4 — Position có magic EA nhưng sai hướng** (ví dụ SELL mang magic 10001, có thể do người dùng/EA khác dùng trùng magic). Đề xuất: không bao giờ tự đóng trong vận hành bình thường; chuyển SAFE MODE phía đó và yêu cầu can thiệp. Khi Global/Equity lock: **không** đóng position này (chỉ đóng đúng symbol + magic + type). Đồng ý?

Các điểm còn lại được xử lý bằng SAFE DEFAULT / NON-BLOCKING ở trên; nếu không có phản hồi khác, các mặc định đó sẽ được dùng ở Phase 2.

## 8. Verification loop Phase 0–1

- Đã đối chiếu 20 điểm bắt buộc của master prompt Phase 1 → P1-01…P1-20 bao phủ đủ; bổ sung P1-21…P1-26.
- Mọi tham số trong §5.2 master prompt giữ nguyên; chỉ bổ sung input mới (`BasketSL_USC`, `SignalMode`, `MaxATRUSD`, `SessionEdgeBlockMinutes`, `ResetLockToken`, `EquityDDReference`, `RequiredAccountCurrency`, `CommissionPerLotEstimate`, `CloseRetryDelayMs`, `UseNewsFilter`, `EmergencyCloseOnRegime`) — tất cả mặc định an toàn, không đổi chiến lược.
- **Chưa xác minh:** mọi thông số broker (contract size, tick value, volume step, currency, commission, swap, phiên). Phải đọc runtime và người dùng đối chiếu tab Specification.
