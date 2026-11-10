# Phase 1 — Rev 2: Đối chiếu Addendum V2.0

**Nguồn:** `Source/EA_XAUUSDc_Adaptive_Grid_M1_Addendum_V2.md` (ưu tiên hơn đặc tả gốc khi xung đột).
**Trạng thái:** Phân tích. Chưa có code, chưa compile, chưa backtest.
**Thứ tự ưu tiên áp dụng:** Master prompt (an toàn/cấm) > Addendum V2.0 > Đặc tả gốc v1.0 > Giả định đã được chấp thuận > Giả định đề xuất.

Tài liệu này cập nhật `Phase0_1_Requirements_and_Ambiguity_Review.md`. Các điểm không nêu ở đây giữ nguyên như Rev 1.

---

## 1. Các điểm Rev 1 đã được Addendum chốt

| Rev 1 | Addendum | Quyết định cuối |
|---|---|---|
| P1-01 shift nến | §2 | TWO_CANDLE mặc định. BUY: `Close[2] < LowerBB[2]`, `RSI[2] ≤ RSI_Buy`; `LowerBB[1] < Close[1] < UpperBB[1]`, `ADX[1] < MaxADX`. SELL đối xứng. **Mới so với Rev 1:** nến xác nhận phải nằm *trong cả hai band* (thêm `Close[1] < UpperBB[1]` cho BUY, `Close[1] > LowerBB[1]` cho SELL). `SIGNAL_ONE_CANDLE` = `Low[1] < LowerBB[1] && LowerBB[1] < Close[1] < UpperBB[1]`, RSI/ADX tại shift 1 (SELL đối xứng với High); chỉ thử nghiệm, báo cáo backtest tách riêng. |
| P1-02 ADX | §3, §11 | Chốt: ADX chỉ chặn entry/add; không `return` sớm trước risk/TP/SL. |
| P1-03 Basket SL | §4 | Chốt: input `BasketSL_AccountCurrency`; `EffectiveSL = UseFromBudget ? Budget : min(BasketSL, Budget)`; SL ≤ 0 hoặc currency chưa xác minh → không mở Basket. |
| P1-04 Stress | §5 | Chốt: `ProjectedBasketLoss = max(0, −PL_stress)`; `StressMove = ATR[1] × StressMoveATR`; input mới `SlippageStressPoints = 30` (tách khỏi `MaxSlippagePoints` dùng làm `deviation` khi gửi lệnh). |
| P1-05 Min lot | §5.3 | Chốt; mã log `REJECT_MIN_VOLUME_EXCEEDS_RISK_BUDGET`. |
| P1-06 Currency | §6 | Chốt: `RequiredAccountCurrency = "USC"`, khác → INIT_FAILED; đổi tên input tiền sang hậu tố `_AccountCurrency`. |
| P1-14 Risk gate kép | §5 | Chốt: Basket budget + combined + daily headroom + margin/volume + equity. |
| P1-15 Cooldown | §8 | Chốt: theo phía, cho cả entry/add, ≤1 lệnh/nến, cooldown tính **từ deal fill time** (không phải lúc gửi), khôi phục từ history. |
| P1-19 Hedging | §7 | Chốt: bỏ input `RequireHedgingAccount` (không giữ bản deprecated → tránh `.set` cũ gây hiểu nhầm; input lạ trong `.set` bị MT5 bỏ qua). |
| P1-20 Execution | §10 | Chốt + mở rộng: Order Reconciliation, không dựa duy nhất vào comment. |
| A-11 State | §9.3 | Chốt: file state versioned + checksum, ghi atomic (tmp → `FileMove`), danh sách trường §9.3. |

## 2. Thay đổi so với đề xuất Rev 1 (Addendum ghi đè)

| Rev 1 đề xuất | Addendum yêu cầu | Áp dụng |
|---|---|---|
| P1-12: mất state → SL dự phòng `min(1% EquityNow, BasketSL)` | §9.2: **không tạo budget mới cho Basket cũ**; không có mức bảo vệ tin cậy → đóng khẩn cấp + giữ khóa (`SafeModeCloseIfRiskStateUnknown = true`) | **Bỏ fallback budget.** Mất budget khi có position → đóng khẩn cấp các position EA (đúng symbol + magic + type), giữ khóa. Xem N-02 cho trường hợp input = false. |
| P1-11/P1-12: lock không khôi phục được → coi như locked | §9.1–9.2: ngoài locked còn phải vào **SAFE MODE**, thoát chỉ khi xác minh đầy đủ hoặc reset có log | Áp dụng; thoát qua `ResetLockToken` (cơ chế reset có log). |
| P1-20: timeout → chặn gửi lại cho tới khi đối chiếu | §9.1/§10: request chưa rõ kết quả → **SAFE MODE** | Áp dụng: trạng thái `PENDING_RECONCILIATION` kéo theo SAFE MODE cho phía đó (và chặn phía kia nếu chưa xác định được side của intent — luôn xác định được vì intent có side). |

## 3. Điểm mới phát sinh / còn mâu thuẫn sau Addendum

| ID | Vấn đề | Rủi ro | Đề xuất | Phân loại |
|---|---|---|---|---|
| N-01 | **Thời điểm xét thêm tầng.** Đặc tả gốc §5.3: thêm khi `Bid ≤ Last − GD`, ≤1 lần/nến (ngụ ý xét mọi tick). Addendum §11 bước 8–10: không có nến mới → bỏ qua "Signal Logic". Chưa rõ grid add có thuộc "Signal Logic" không. | (a) Chỉ xét ở tick đầu nến: bỏ lỡ chạm grid giữa nến, giá vào là giá đầu nến kế tiếp (có thể đã đi xa hơn GD). (b) Xét mọi tick: khớp sát mức grid hơn nhưng nhiều lần gọi risk gate hơn. Cả hai đều qua risk gate nên không vượt budget. | Mặc định **(a)** khi `UseNewBarOnly = true` (bám chữ của Addendum §11, bảo thủ hơn); `UseNewBarOnly = false` → (b), vẫn ≤1 lệnh/nến. | **BLOCKER — Q3** |
| N-02 | `SafeModeCloseIfRiskStateUnknown = false` không được định nghĩa | Position tồn tại không có Basket SL | Khi false: không đóng khẩn cấp; giữ SAFE MODE + lock; không có Basket SL; **Combined Loss, Daily Loss, Equity DD vẫn hoạt động** (không phụ thuộc budget Basket) và sẽ đóng nếu chạm. Log cảnh báo mỗi phút. | SAFE DEFAULT |
| N-03 | Phân biệt **lần chạy đầu** với **mất state**. Addendum: không khôi phục được lock → locked + SAFE MODE. Nhưng lần cài đầu tiên cũng không có state. | Lần đầu sẽ bị khóa vĩnh viễn, hoặc mất state bị coi là lần đầu → xóa khóa | Lần đầu = **không có state file VÀ không có position EA VÀ không có deal EA (symbol + 2 magic) trong lịch sử 90 ngày gần nhất** → khởi tạo sạch, log `FRESH_INIT`. Ngược lại thiếu/hỏng state → SAFE MODE + locked, cần reset thủ công. Hệ quả: chuyển EA sang VPS mới (không mang theo file state) sẽ phải reset thủ công 1 lần — chủ ý, an toàn. Tester luôn khởi tạo sạch (file riêng `_TESTER`). | SAFE DEFAULT |
| N-04 | Cooldown 60 s tính từ fill + ≤1 lệnh/nến + xét ở tick đầu nến: fill xảy ra vài trăm ms sau mở nến T, nến T+1 mở sau < 60 s kể từ fill → **cooldown chặn**, lệnh kế tiếp sớm nhất ở nến T+2. | Không phải rủi ro vốn; giảm tần suất thêm tầng xuống ~1 lệnh / 2 nến. | Giữ đúng đặc tả (60 s), ghi rõ hành vi này trong Parameters.md. Người dùng có thể đặt 50–55 s nếu muốn 1 lệnh/nến; không tự đổi. | NON-BLOCKING (thông báo) |
| N-05 | Addendum §8: "không xác định được thời điểm fill cuối → SAFE MODE" | Lần đầu không có fill nào → SAFE MODE nhầm | Không có deal EA nào trong history = không có ràng buộc cooldown (hợp lệ, không SAFE MODE). Chỉ SAFE MODE khi có position EA đang mở mà không đọc được deal IN tương ứng. | SAFE DEFAULT |
| N-06 | Daily Loss: Addendum tự nêu chưa rõ phạm vi | Đếm thiếu/trùng | Giữ đề xuất Rev 1: EA-scope, `DailyPL = RealizedToday(profit+swap+comm+fee) + FloatingNetNow − FloatingNetAtDayStart`; mất snapshot → dùng 0 (chặt hơn). Floating net = profit + swap + phí entry đã trả của position đang mở → khi position đóng trong ngày, phí entry đã nằm trong RealizedToday chỉ nếu deal IN thuộc hôm nay; xử lý: RealizedToday chỉ gồm deal OUT (profit+swap+comm+fee của deal OUT) + comm/fee của deal IN thuộc hôm nay; FloatingNet tính phí entry của mọi position đang mở → không đếm trùng nhờ snapshot đầu ngày đã chứa phí entry của position qua đêm. | **BLOCKER — Q1** (phạm vi) |
| N-07 | Equity DD "so với mốc equity tham chiếu được xác định trước" — gợi ý mốc cố định, khác HWM | Lock sai thời điểm | Input `EquityDDReference` = {HIGH_WATER_MARK, INITIAL_EQUITY, FIXED_VALUE}; giá trị chờ Q2. | **BLOCKER — Q2** |
| N-08 | Đóng khẩn cấp trong SAFE MODE (§9.2) — phạm vi | Đóng nhầm | Chỉ symbol + magic + type đúng. Position magic EA nhưng sai type: không đóng, log, giữ SAFE MODE (Rev 1 Q4). | SAFE DEFAULT (trước là Q4) |
| N-09 | Bộ lọc thời gian / ATR bất thường (đặc tả gốc §8) — Addendum không đề cập | — | Giữ Rev 1: chặn 15 phút đầu/cuối mỗi phiên trade theo `SymbolInfoSessionTrade()`; `MaxATR_USD = 3.0`; `UseNewsFilter = false` (bật mà không có Calendar → không giao dịch). | SAFE DEFAULT (trước là Q3) |
| N-10 | Danh sách input Addendum §12 bỏ một số input gốc (AllowBuy/Sell, MagicBuy/Sell, grid, entry filter, diagnostics…) | Mất cấu hình | Addendum ghi rõ là "định hướng" → **hợp nhất**: giữ toàn bộ input gốc + thêm/đổi tên theo Addendum. | NON-BLOCKING |

## 4. Mô hình Projected Risk & chống đếm trùng phí (theo yêu cầu Addendum §14)

Ký hiệu cho một phía (BUY; SELL đối xứng bằng cách đổi Bid↔Ask và dấu):

- `ATR1` = ATR(14) tại shift 1; `pt` = `SYMBOL_POINT`.
- Giá khớp giả định lệnh mới: `P_new = Ask + SlippageStressPoints × pt`.
- Giá đóng stress (BUY đóng ở Bid): `P_stress = Bid − ATR1 × StressMoveATR − SlippageStressPoints × pt`.
  - Spread hiện tại đã nằm trong khoảng cách Ask→Bid; nếu bật `SpreadStressMultiplier > 1` thì trừ thêm `(mult − 1) × (Ask − Bid)`. Mặc định 1.0 (không cộng trùng).
- Với mỗi position i đang mở: `PL_i = OrderCalcProfit(ORDER_TYPE_BUY, vol_i, open_i, P_stress)` + `POSITION_SWAP_i` (swap hiện tại, không dự phóng).
- Lệnh mới: `PL_new = OrderCalcProfit(ORDER_TYPE_BUY, vol_new, P_new, P_stress)`.
- Phí **đã phát sinh**: `Fee_paid = Σ (DEAL_COMMISSION + DEAL_FEE)` của các deal thuộc `POSITION_IDENTIFIER` của các position đang mở (`HistorySelectByPosition`). `POSITION_PROFIT` không chứa commission → không trùng.
- Phí **dự kiến chưa phát sinh**: phí entry của lệnh mới + phí exit của mọi position + lệnh mới. Ước tính = phí entry thực tế trên mỗi lot quan sát được gần nhất (lấy từ deal IN của Basket); nếu chưa có quan sát → `CommissionPerLotEstimate` (input, mặc định 0 **và** log `COMMISSION_UNVERIFIED` cho tới khi quan sát được deal đầu tiên).
- `PL_stress = Σ PL_i + PL_new + Fee_paid + Fee_expected` (phí mang dấu âm).
- `ProjectedBasketLoss = max(0, −PL_stress)`.

Điều kiện gửi lệnh (tất cả):

1. `ProjectedBasketLoss ≤ EffectiveBasketSL` (budget của Basket; lệnh đầu dùng budget tính từ equity hiện tại).
2. `ProjectedBasketLoss + LossOther ≤ MaxCombinedLoss`, với `LossOther = max(0, −NetFloating(phía kia))` (dùng loss hiện tại của phía kia; stress của phía kia đã được gate khi nó thêm tầng).
3. Đặt `AddLoss = max(0, ProjectedBasketLoss − max(0, −NetFloating(phía này)))` (phần lỗ tăng thêm so với hiện tại, vì DailyPL và Equity đã chứa lỗ hiện tại). Điều kiện: `max(0, −DailyPL) + AddLoss ≤ DailyLoss`.
4. `max(0, EquityRef − EquityNow) + AddLoss ≤ MaxEquityDD`.
5. `OrderCalcMargin` cho lệnh mới ≤ `ACCOUNT_MARGIN_FREE` × `MarginSafetyFactor` (mặc định 0.5) và `OrderCheck()` trả OK.
6. Layers + 1 ≤ MaxLayers; ΣVol + vol_new ≤ MaxSideLots.

`OrderCalcProfit()` trả về false hoặc giá trị không hữu hạn → từ chối (`REJECT_RISK_CALC_FAILED`).

## 5. Câu hỏi còn lại

- **Q1 — Phạm vi Daily Loss:** chỉ lệnh của EA (đề xuất) hay toàn tài khoản? Tài khoản có dành riêng cho EA không?
- **Q2 — Mốc Equity DD & mở khóa:** HWM (đề xuất) / equity lúc gắn EA lần đầu / giá trị cố định nhập tay? Global Lock mở thủ công (đề xuất) hay tự mở sang ngày mới?
- **Q3 — Thêm tầng:** chỉ xét ở tick đầu mỗi nến M1 (đề xuất, bám Addendum §11) hay xét mọi tick, tối đa 1 lần/nến?

Các SAFE DEFAULT N-02, N-03, N-05, N-08, N-09 sẽ áp dụng nếu không có phản đối.
