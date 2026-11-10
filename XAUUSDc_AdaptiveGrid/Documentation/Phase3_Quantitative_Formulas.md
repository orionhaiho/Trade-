# Phase 3 — Công thức định lượng, đơn vị và ví dụ kiểm thử

**Căn cứ:** Đặc tả v1.0, Addendum V2.0, Phase 1 Rev 1–3, Phase 2.
**Trạng thái:** Đặc tả công thức. Chưa có code. Mọi ví dụ số là **tính tay** trên giả định ở §0.3, **không phải** thông số broker đã xác minh.

---

## 0. Quy ước

### 0.1. Đơn vị

| Ký hiệu | Đơn vị | Ví dụ |
|---|---|---|
| `[P]` | Đơn vị giá của symbol (USD/oz cho XAUUSDc) | Bid = 2650.000 |
| `[AC]` | Tiền tài khoản (`ACCOUNT_CURRENCY`, kỳ vọng `USC`) | Equity = 500.00 |
| `[V]` | Volume MT5 của XAUUSDc (đúng con số hiển thị trong terminal) | 0.01 |
| `[pt]` | Point = `SYMBOL_POINT` `[P]` | 30 pt × 0.001 = 0.030 `[P]` |
| `[%]` | Phần trăm | 1.0 |
| `[ms]`, `[s]` | Thời gian server | |

### 0.2. Dấu

- **P/L, NetValue**: dương = lãi, âm = lỗ `[AC]`.
- **Loss, DD, AddLoss**: luôn ≥ 0 `[AC]` (độ lớn của lỗ).
- **Commission, Fee** đọc từ deal: theo dấu MT5 (chi phí là số âm). Không đảo dấu.
- **Ngưỡng input** (TP, SL, Limit): luôn dương.
- Mọi lock/SL kích hoạt **khi chạm** (≤ hoặc ≥ có dấu bằng). Risk Gate cho phép khi kết quả stress **≤** ngưỡng (kịch bản stress chạm đúng ngưỡng là trường hợp xấu nhất được thiết kế chấp nhận).

### 0.3. Giả định chỉ dùng cho ví dụ

| Ký hiệu | Giá trị ví dụ | Runtime thực tế |
|---|---|---|
| `K` | `OrderCalcProfit(BUY, V, open, close) = (close − open) × V × 100` `[AC]` (≈ 1 USC cho 1.00 `[P]` với 0.01 `[V]`) | **Luôn gọi `OrderCalcProfit()`**, không dùng K |
| Point | 0.001 | `SYMBOL_POINT` |
| Tick size | 0.001 | `SYMBOL_TRADE_TICK_SIZE` |
| Volume min/step/max | 0.01 / 0.01 / 200 | `SYMBOL_VOLUME_*` |
| Commission | 0, trừ ví dụ có ghi rõ (−0.02 `[AC]`/0.01 `[V]`/chiều, giả định) | Deal history |

---

## 1. Chuẩn hóa

### 1.1. Volume (đếm theo số step nguyên để tránh lỗi số thực)

```text
steps(V)       = (long)MathRound(V / Step)
NormalizeVol(V)= steps(V) × Step                       // không làm tròn lên
Valid(V)       ⇔ |NormalizeVol(V) − V| ≤ Step × 1e-6  ∧  V ≥ VolMin  ∧  V ≤ VolMax
```

Không hợp lệ → **từ chối** (`REJECT_INVALID_VOLUME`); không tự sửa thành giá trị khác.

| Test | Input | Kết quả |
|---|---|---|
| F-VOL-01 | V = 0.01 | hợp lệ, 0.01 |
| F-VOL-02 | V = 0.015 | `steps` = 2 → 0.02 ≠ 0.015 → **REJECT** |
| F-VOL-03 | V = 0.005 (< min) | **REJECT** |
| F-VOL-04 | Σ hiện tại 0.04 + 0.01 vs MaxSideLots 0.05 | `steps`: 4 + 1 = 5 ≤ 5 → OK |
| F-VOL-05 | Σ 0.05 + 0.01 | 6 > 5 → **REJECT_MAX_SIDE_LOTS** |

### 1.2. Giá

```text
NormalizePrice(p) = MathRound(p / TickSize) × TickSize      // cho giá gửi lệnh
CeilTick(x)       = MathCeil(x / TickSize − 1e-9) × TickSize // cho khoảng cách grid (không thu hẹp)
```

### 1.3. Spread

```text
SpreadPrice [P]  = Ask − Bid
SpreadPoints[pt] = SpreadPrice / Point                     // chỉ để log
SpreadOK         ⇔ SpreadPrice ≤ MaxSpreadUSD
```

| Test | Bid / Ask | Kết quả |
|---|---|---|
| F-SPR-01 | 2650.000 / 2650.250 | 0.250 [P] = 250 pt ≤ 0.30 → OK |
| F-SPR-02 | 2650.000 / 2650.310 | 0.310 > 0.30 → **REJECT_SPREAD** |

---

## 2. Grid spacing và trigger

```text
ATR1 [P]   = ATR(14) tại shift 1
ATRValid   ⇔ ATR1 hữu hạn ∧ ATR1 > 0 ∧ ATR1 ≤ MaxATR_USD
Raw  [P]   = ATR1 × ATRMultiplier
GD   [P]   = CeilTick( clamp(Raw, MinGridUSD, MaxGridUSD) )

BUY add trigger : Bid ≤ LastBuyFill − GD      (LastBuyFill = POSITION_PRICE_OPEN của tầng BUY mới nhất)
SELL add trigger: Ask ≥ LastSellFill + GD
```

GD được tính lại **mỗi lần** xét trigger từ ATR shift 1 hiện tại (không cố định theo lúc mở Basket) — đúng chữ "Adaptive" của đặc tả.

| Test | ATR1 | Raw | GD | Ghi chú |
|---|---|---|---|---|
| F-GRD-01 | 0.800 | 0.640 | **0.640** | Ví dụ đặc tả §5.2 |
| F-GRD-02 | 0.400 | 0.320 | **0.500** | Clamp min |
| F-GRD-03 | 2.500 | 2.000 | **1.500** | Clamp max |
| F-GRD-04 | 0.8123 | 0.64984 | **0.650** | Làm tròn lên tick |
| F-GRD-05 | 0 hoặc NaN | — | — | **REJECT_ATR_INVALID** |
| F-GRD-06 | 3.200 | — | — | > MaxATR_USD 3.0 → **REJECT_ATR_ABNORMAL** |
| F-GRD-07 | LastBuyFill 2650.200, GD 0.640 | — | trigger | Bid ≤ **2649.560** |
| F-GRD-08 | LastSellFill 2650.000, GD 0.640 | — | trigger | Ask ≥ **2650.640** |

---

## 3. Tín hiệu (TWO_CANDLE)

```text
BUY  ⇔ Close[2] < LowerBB[2] ∧ RSI[2] ≤ RSI_Buy  ∧ LowerBB[1] < Close[1] < UpperBB[1] ∧ ADX[1] < MaxADX
SELL ⇔ Close[2] > UpperBB[2] ∧ RSI[2] ≥ RSI_Sell ∧ LowerBB[1] < Close[1] < UpperBB[1] ∧ ADX[1] < MaxADX
```

| Test | Dữ liệu | Kết quả |
|---|---|---|
| F-SIG-01 | C2 = 2648.10, LB2 = 2648.50, RSI2 = 22.4; C1 = 2648.90, LB1 = 2648.40, UB1 = 2652.30; ADX1 = 18.5 | **BUY** |
| F-SIG-02 | Như trên nhưng RSI2 = 26.0 | Không |
| F-SIG-03 | Như F-SIG-01 nhưng ADX1 = 22.0 | Không (22 không < 22) |
| F-SIG-04 | C2 = 2648.60 (≥ LB2), chỉ nến 1 có Low xuyên band | Không (TWO_CANDLE) |
| F-SIG-05 | Đối xứng SELL: C2 = 2653.00 > UB2 = 2652.50, RSI2 = 78; C1 = 2652.00 < UB1 = 2652.40 và > LB1; ADX1 = 15 | **SELL** |

---

## 4. Phí và giá trị ròng của position

Với position có định danh `pid` (`POSITION_IDENTIFIER`):

```text
FeeIn(pid)   [AC] = Σ (DEAL_COMMISSION + DEAL_FEE) các deal ENTRY_IN của pid          (≤ 0)
V(pid)       [AC] = POSITION_PROFIT + POSITION_SWAP + FeeIn(pid)                      // position đang mở
Final(pid)   [AC] = Σ (DEAL_PROFIT + DEAL_SWAP + DEAL_COMMISSION + DEAL_FEE) các deal OUT của pid + FeeIn(pid)  // đã đóng hẳn
FeeRate      [AC/V] = FeeIn của deal IN gần nhất / volume của deal đó   (nếu chưa có quan sát: CommissionPerLotEstimate, log COMMISSION_UNVERIFIED)
FeeOutEst(V) [AC] = V × FeeRate                                                      (≤ 0)
```

**Chống đếm trùng:** `POSITION_PROFIT` không chứa commission; swap đang tích lũy nằm ở `POSITION_SWAP` khi mở và chuyển sang `DEAL_SWAP` của deal OUT khi đóng — mỗi khoản thuộc đúng một trong `V` hoặc `Final`, không bao giờ cả hai.

---

## 5. Basket

### 5.1. Ngân sách và SL

```text
EquityAtStart [AC] = ACCOUNT_EQUITY tại thời điểm gửi lệnh đầu (BasketBudgetBase = EQUITY mặc định; tùy chọn BALANCE)
Budget        [AC] = EquityAtStart × BasketRiskPercent / 100       (lưu đầy đủ độ chính xác double, không làm tròn)
EffSL         [AC] = UseBasketSLFromRiskBudget ? Budget : min(BasketSL_AccountCurrency, Budget)
Hợp lệ        ⇔ EffSL > 0 ∧ hữu hạn ∧ currency đã xác minh      (ngược lại: không mở Basket)
```

Budget/EffSL **bất biến** suốt vòng đời Basket; không tạo lại sau restart (Addendum §9.2).

| Test | Equity | Cấu hình | Budget | EffSL |
|---|---|---|---|---|
| F-BUD-01 | 500.00 | UseFromBudget = true | 5.00 | **5.00** |
| F-BUD-02 | 512.34 | true | 5.1234 | **5.1234** |
| F-BUD-03 | 500.00 | false, BasketSL = 4.00 | 5.00 | **4.00** |
| F-BUD-04 | 500.00 | false, BasketSL = 8.00 | 5.00 | **5.00** (không rộng hơn budget) |
| F-BUD-05 | 500.00 | false, BasketSL = 0 | — | **REJECT_INVALID_SL** |

### 5.2. Net P/L Basket và TP/SL

```text
NetBasket [AC] = Σ_{pid đang mở của Basket} V(pid) + Σ_{pid đã đóng hẳn của Basket} Final(pid)   // số hạng 2 ≠ 0 chỉ khi CLOSING dở dang
NetBasketAfterExit [AC] = NetBasket + FeeOutEst(Σ volume đang mở)

TP  ⇔ NetBasketAfterExit ≥ BasketTP_AccountCurrency
SL  ⇔ NetBasketAfterExit ≤ −EffSL
```

Ví dụ BUY 3 tầng (fills 2650.200 / 2649.760 / 2649.320, mỗi tầng 0.01, swap 0, commission 0):

```text
NetBasket(Bid) = (3·Bid − 7949.280) × 0.01 × 100 = 3·Bid − 7949.280
```

| Test | Bid | NetBasket | Kết quả |
|---|---|---|---|
| F-BSK-01a | 2648.100 | −4.980 | Không (ngưỡng chính xác Bid ≈ 2648.0933) |
| F-BSK-01b | 2648.090 | −5.010 | ≤ −5.00 → **SL** |
| F-BSK-02 | 2650.260 | +1.500 | ≥ 1.50 → **TP** |
| F-BSK-03 | 2649.500 | −0.780 | Không |
| F-BSK-04 | 2650.260, commission −0.02/0.01/chiều: FeeIn = −0.06, FeeOutEst = −0.06 | 1.500 − 0.06 − 0.06 = 1.380 | **Chưa TP** (cần Bid ≥ 2650.300) |

Nhận xét định lượng: với 3 tầng, TP chỉ đạt khi Bid hồi về trên giá khớp tầng 1 (+0.060); với 1 tầng cần +1.50 `[P]` từ giá khớp. TP cố định 1.50 `[AC]` không co giãn theo số tầng — đúng đặc tả, ghi nhận để nghiên cứu.

---

## 6. Projected risk (stress)

Cho phía BUY (SELL: đổi Bid↔Ask, `+` ↔ `−`, `ORDER_TYPE_SELL`):

```text
Slip   [P] = SlippageStressPoints × Point
SprAdd [P] = (SpreadStressMultiplier − 1) × (Ask − Bid)          // mặc định multiplier 1.0 → 0
P_new  [P] = Ask + Slip                                           // giá khớp giả định lệnh mới
P_str  [P] = Bid − ATR1 × StressMoveATR − Slip − SprAdd           // giá đóng stress cho mọi tầng

PL_i   [AC] = OrderCalcProfit(BUY, V_i, open_i, P_str) + POSITION_SWAP_i + FeeIn_i      // position hiện có
PL_new [AC] = OrderCalcProfit(BUY, V_new, P_new, P_str) + FeeRate × V_new              // + phí vào lệnh mới
FeeOut [AC] = FeeRate × (Σ V_i + V_new)                                                  // phí đóng toàn Basket
PL_str [AC] = Σ PL_i + PL_new + FeeOut
ProjLoss[AC]= max(0, −PL_str)
CurLoss [AC]= max(0, −NetBasket)                    // lỗ hiện tại của phía này
AddLoss [AC]= max(0, ProjLoss − CurLoss)            // phần lỗ tăng thêm nếu lệnh mới khớp và stress xảy ra
```

`OrderCalcProfit()` trả `false`/không hữu hạn → **REJECT_RISK_CALC_FAILED**. Swap tương lai không dự phóng.

### 6.1. Ví dụ chuỗi tầng BUY (ATR1 = 0.800, GD = 0.640, spread 0.200, Slip = 0.030, StressMoveATR = 1.0, EffSL = 5.00, commission 0)

Fill thực tế giả định = Ask lúc gửi (không trượt).

| Test | Tầng | Bid / Ask lúc xét | P_new | P_str | PL từng tầng | PL_str | ProjLoss | Gate G1 (≤ 5.00) |
|---|---|---|---|---|---|---|---|---|
| F-RSK-01 | 1 (entry) | 2650.000 / 2650.200 | 2650.230 | 2649.170 | new −1.060 | −1.060 | 1.060 | **PASS** |
| F-RSK-02 | 2 | 2649.560 / 2649.760 | 2649.790 | 2648.730 | −1.470, new −1.060 | −2.530 | 2.530 | **PASS** |
| F-RSK-03 | 3 | 2649.120 / 2649.320 | 2649.350 | 2648.290 | −1.910, −1.470, new −1.060 | −4.440 | 4.440 | **PASS** |
| F-RSK-04 | 4 | 2648.680 / 2648.880 | 2648.910 | 2647.850 | −2.350, −1.910, −1.470, new −1.060 | −6.790 | 6.790 | **REJECT_BASKET_BUDGET** |

Kết luận: với các giả định ví dụ, risk gate giới hạn Basket ở **3 tầng**; MaxLayers = 5 không bao giờ đạt. Đây là hành vi đúng theo đặc tả.

| Test | Biến thể | Kết quả |
|---|---|---|
| F-RSK-05 | F-RSK-03 + commission −0.02/0.01/chiều: FeeIn paid = −0.04, PL_new thêm −0.02, FeeOut = −0.06 | PL_str = −4.440 − 0.04 − 0.02 − 0.06 = −4.560 → **PASS** |
| F-RSK-06 | Entry với EffSL giả sử = 1.00 (ví dụ budget rất nhỏ): ProjLoss của 1 lệnh min volume = 1.060 | 1.060 > 1.00 → **REJECT_MIN_VOLUME_EXCEEDS_RISK_BUDGET** (không nâng/giảm lot) |
| F-RSK-07 | `OrderCalcProfit` trả false | **REJECT_RISK_CALC_FAILED** |

---

## 7. Risk Gate (chạy ngay trước mọi lệnh mới)

Tất cả phải đúng; điều kiện đầu tiên thất bại quyết định reason code (vẫn log toàn bộ giá trị):

| # | Điều kiện | Reason khi sai |
|---|---|---|
| G0 | Không lock, không SAFE MODE, không intent chờ reconcile, Basket ở IDLE (entry) / ACTIVE (add), state file ghi được | `REJECT_LOCKED` / `REJECT_SAFE_MODE` / `REJECT_PENDING_RECONCILE` / `REJECT_STATE` |
| G1 | `ProjLoss ≤ EffSL` (entry: EffSL dự kiến từ equity hiện tại) | `REJECT_BASKET_BUDGET` hoặc `REJECT_MIN_VOLUME_EXCEEDS_RISK_BUDGET` khi là lệnh đầu với min volume |
| G2 | `ProjLoss + max(0, −NetBasket_other) ≤ MaxCombinedLoss_AccountCurrency` | `REJECT_COMBINED_LOSS` |
| G3 | `max(0, −EADailyPL) + AddLoss ≤ DailyLoss_AccountCurrency` | `REJECT_DAILY_HEADROOM` |
| G4 | `EqDD + AddLoss ≤ EqDDLimit` (§10) | `REJECT_EQUITY_DD_HEADROOM` |
| G5 | `APLoss + AddLoss ≤ APLimit` (§9) | `REJECT_ACCOUNT_PROTECTION_HEADROOM` |
| G6 | `OrderCalcMargin(V_new, P_new) ≤ ACCOUNT_MARGIN_FREE × MaxMarginUsage` (mặc định 0.50) ∧ `OrderCheck()` retcode = 0 | `REJECT_MARGIN` |
| G7 | Volume hợp lệ (§1.1), `Layers + 1 ≤ MaxLayers`, `steps(ΣV) + steps(V_new) ≤ steps(MaxSideLots)` | `REJECT_INVALID_VOLUME` / `REJECT_MAX_LAYERS` / `REJECT_MAX_SIDE_LOTS` |

Ví dụ cho tầng 3 BUY (F-RSK-03: ProjLoss = 4.440; CurLoss tại Bid 2649.120 = (2649.120 − 2650.200) + (2649.120 − 2649.760) = −1.080 − 0.640 → 1.720; **AddLoss = 2.720**):

| Test | Trạng thái khác | Tính | Kết quả |
|---|---|---|---|
| F-GATE-01 | SELL NetBasket = −3.20 | G2: 4.440 + 3.20 = 7.640 ≤ 10 | PASS |
| F-GATE-02 | SELL NetBasket = −6.00 | G2: 4.440 + 6.00 = 10.440 > 10 | **REJECT_COMBINED_LOSS** |
| F-GATE-03 | EADailyPL = −6.00 | G3: 6.00 + 2.720 = 8.720 ≤ 10 | PASS |
| F-GATE-04 | EADailyPL = −7.50 | G3: 7.50 + 2.720 = 10.220 > 10 | **REJECT_DAILY_HEADROOM** |
| F-GATE-05 | HWM = 520.00, Equity = 503.00 (limit 26.00) | G4: 17.00 + 2.720 = 19.720 ≤ 26.00 | PASS |
| F-GATE-06 | HWM = 520.00, Equity = 495.00 | G4: 25.00 + 2.720 = 27.720 > 26.00 | **REJECT_EQUITY_DD_HEADROOM** |
| F-GATE-07 | DayStartAdj = 510.00 (limit 3% = 15.30), Equity = 501.00 | G5: 9.00 + 2.720 = 11.720 ≤ 15.30 | PASS |
| F-GATE-08 | Margin cần 2.65, Free 480.00 | G6: 2.65 ≤ 240.00 | PASS (số margin là giả định) |

Ghi chú G2: phía kia dùng lỗ **hiện tại**, vì stress của nó đã được gate khi nó thêm tầng; dùng stress đồng thời hai phía ngược chiều là không nhất quán về giá (BUY stress = giá giảm, SELL stress = giá tăng).

---

## 8. EA Daily Loss

`ServerDate` = phần ngày của `TimeTradeServer()`. Tại chu kỳ đầu tiên của ngày mới:

```text
Snap [AC] = Σ_{position EA đang mở lúc đó} V(pid)          // persist cùng ServerDate
```

Trong ngày:

```text
RealizedOut [AC] = Σ_{deal OUT của EA (symbol + 2 magic), DEAL_TIME ≥ 00:00 ServerDate} (PROFIT + SWAP + COMMISSION + FEE)
ClosedFeeIn [AC] = Σ_{pid đóng hẳn trong ngày} FeeIn(pid)
OpenNow     [AC] = Σ_{position EA đang mở} V(pid)
EADailyPL   [AC] = RealizedOut + ClosedFeeIn + OpenNow − Snap
DailyLock   ⇔ EADailyPL ≤ −DailyLoss_AccountCurrency
```

Kiểm chứng tính đúng: với mỗi position, phần đóng góp vào ngày = (giá trị cuối hoặc hiện tại) − (giá trị lúc đầu ngày, 0 nếu mở trong ngày). Phí vào được tính đúng một lần trong cả vòng đời; position qua đêm có FeeIn nằm cả trong `Snap` lẫn `OpenNow`/`ClosedFeeIn` nên triệt tiêu đúng.

Mất `Snap` trong ngày (state hỏng) → `Snap = 0` → EADailyPL nhỏ hơn hoặc bằng giá trị thật khi position qua đêm đang lỗ → bảo thủ.

| Test | Kịch bản | Tính | EADailyPL |
|---|---|---|---|
| F-DAY-01 | Đầu ngày: BUY qua đêm 2 tầng, profit −1.00, swap −0.10, FeeIn −0.04 → Snap = −1.14. Trong ngày BUY đóng: OUT profit +2.80, swap −0.10, commission −0.04 → RealizedOut = 2.66, ClosedFeeIn = −0.04. SELL mở trong ngày: profit −0.50, FeeIn −0.02 → OpenNow = −0.52 | 2.66 − 0.04 − 0.52 + 1.14 | **+3.24** |
| | Kiểm tay | BUY: giá trị cuối 2.80 − 0.10 − 0.04 − 0.04 = 2.62, đầu ngày −1.14 → +3.76; SELL −0.52 → +3.24 | ✓ |
| F-DAY-02 | Snap = 0, Basket SL đóng lúc 10:00 (RealizedOut + ClosedFeeIn = −5.06), SELL đang mở OpenNow = −4.95 | −5.06 − 4.95 | −10.01 ≤ −10 → **DAILY LOCK** |
| F-DAY-03 | Restart lúc 14:00 cùng ngày, state OK | Snap đọc lại từ state; Realized đọc lại từ history | Không đổi, lock giữ nguyên |
| F-DAY-04 | Sang ngày mới, Daily Lock đang bật, không lock khác, không SAFE MODE | `ServerDate > LockDate` | **Auto reset**, Snap mới |
| F-DAY-05 | Như F-DAY-04 nhưng Equity DD Lock đang bật | Điều kiện reset sai | Daily Lock **giữ nguyên** |

---

## 9. Account Equity Protection

### 9.1. Dòng tiền ngoài

```text
Flow_k [AC] = DEAL_PROFIT của deal loại BALANCE / CREDIT / BONUS (nạp > 0, rút < 0), mỗi deal xử lý đúng một lần (theo ticket)
```

### 9.2. Công thức

Mốc được **dịch theo dòng tiền** thay vì lưu "equity đã trừ dòng tiền" (xem §10.2 về lý do):

```text
Đầu ngày server:   APBase [AC] = ACCOUNT_EQUITY
Khi có Flow_k:     APBase      = APBase + Flow_k
APLoss  [AC] = max(0, APBase − ACCOUNT_EQUITY)
APLimit [AC] = APBase × AccountProtectionDailyLossPercent / 100      (mặc định 3.0)
APLock      ⇔ APLoss ≥ APLimit
```

| Test | Kịch bản | Tính | Kết quả |
|---|---|---|---|
| F-AP-01 | APBase 510.00, Equity 501.00 | Loss 9.00, Limit 15.30 | Không |
| F-AP-02 | APBase 510.00, Equity 494.70 | Loss 15.30 ≥ 15.30 | **AP LOCK** |
| F-AP-03 | APBase 510.00; nạp 100 → APBase 610.00; Equity 596.00 | Loss 14.00, Limit 18.30 | Không (nạp tiền không bị coi là lãi, cũng không che lỗ) |
| F-AP-04 | APBase 510.00; rút 100 → APBase 410.00; Equity 405.00 | Loss 5.00, Limit 12.30 | Không (rút tiền không bị coi là lỗ) |

---

## 10. Equity Drawdown (High Watermark có điều chỉnh nạp/rút)

### 10.1. Công thức triển khai

```text
Khởi tạo lần đầu:  HWM [AC] = ACCOUNT_EQUITY
Khi có Flow_k:     HWM = HWM + Flow_k                 (trước khi so sánh max)
Mỗi chu kỳ:        HWM = max(HWM, ACCOUNT_EQUITY)
EqDD      [AC] = max(0, HWM − ACCOUNT_EQUITY)
EqDDLimit [AC] = HWM × MaxEquityDDPercent / 100       (mặc định 5.0)
EqLock        ⇔ EqDD ≥ EqDDLimit
```

### 10.2. Tương đương và điểm khác với công thức người dùng

Công thức người dùng: `AdjEq = Equity − NetFlow`, `HWM_adj = max(AdjEq)`, `DD = HWM_adj − AdjEq`, `Limit = HWM_adj × %`.

- **DD tuyệt đối giống hệt** công thức §10.1 (cùng trừ/cộng NetFlow hai vế).
- **Limit khác khi có rút tiền lớn**: ví dụ HWM_adj = 530, rút 400 → equity thật 130 nhưng Limit = 5% × 530 = 26.50 = **20% equity thật**. Công thức §10.1 cho Limit = 5% × 130 = 6.50, đúng tinh thần "5%". Khi không có nạp/rút hai công thức trùng nhau hoàn toàn.
- **Đề xuất dùng §10.1.** Đây là điểm cần người dùng xác nhận (P3-Q1).

| Test | Kịch bản | HWM | EqDD | Limit | Kết quả |
|---|---|---|---|---|---|
| F-EQ-01 | Equity 500 → 530 | 530.00 | 0 | 26.50 | Không |
| F-EQ-02 | Từ 530 giảm còn 504.00 | 530.00 | 26.00 | 26.50 | Không |
| F-EQ-03 | Giảm còn 503.50 | 530.00 | 26.50 | 26.50 | **EQ LOCK** |
| F-EQ-04 | HWM 530, rút 100 → Equity 430 | 430.00 | 0 | 21.50 | Không (rút không bị coi là DD) |
| F-EQ-05 | HWM 530, nạp 100 → Equity 630, sau đó giảm còn 605 | 630.00 | 25.00 | 31.50 | Không |
| F-EQ-06 | Restart: state có HWM 530.00, Equity hiện 520.00 | 530.00 | 10.00 | 26.50 | HWM **không** reset |
| F-EQ-07 | State mất HWM (không đủ điều kiện FRESH_INIT) | — | — | — | **SAFE MODE + mọi lock = LOCKED** |

---

## 11. Combined Loss

```text
CombinedNet [AC] = NetBasket(BUY) + NetBasket(SELL)          // §5.2, chỉ position EA
CombinedLock    ⇔ CombinedNet ≤ −MaxCombinedLoss_AccountCurrency
```

| Test | BUY | SELL | CombinedNet | Kết quả |
|---|---|---|---|---|
| F-CMB-01 | −3.80 | −6.30 | −10.10 | **COMBINED LOCK** |
| F-CMB-02 | −4.90 | +1.20 | −3.70 | Không (lãi phía kia bù trừ — đúng định nghĩa "net") |
| F-CMB-03 | −4.99 | −4.99 | −9.98 | Không lock; nhưng gate G2 chặn mọi tầng mới có ProjLoss làm tổng > 10 |

Lưu ý thiết kế: hai Basket mỗi bên chạm SL −5.00 trước khi tổng chạm −10.00, nên Combined Lock thường chỉ kích hoạt khi trượt giá/gap đẩy một bên vượt SL hoặc cả hai cùng lỗ trong một tick.

---

## 12. Tần suất lệnh

```text
BarTime(t)       = iTime(Symbol, M1, 0) tại t
OneOrderPerBar   ⇔ BarTime(now) > LastOrderBar[side]
CooldownOK       ⇔ now_ms − LastFillTimeMsc[side] ≥ CooldownSeconds × 1000
LastFillTimeMsc  = DEAL_TIME_MSC của deal IN mới nhất của phía đó (khôi phục từ history; không có deal nào → ràng buộc không áp dụng)
```

| Test | Kịch bản | Kết quả |
|---|---|---|
| F-RATE-01 | Fill 10:05:00.350; trigger 10:05:40 | Cùng nến → **REJECT_ONE_PER_BAR** |
| F-RATE-02 | Trigger 10:06:00.100 | Nến mới nhưng 59.75 s < 60 → **REJECT_COOLDOWN** |
| F-RATE-03 | Trigger 10:06:00.400 | 60.05 s, nến mới → OK (add xét mọi tick) |
| F-RATE-04 | Entry (chỉ tick đầu nến) lúc 10:06:00.100, fill gần nhất cùng phía 10:05:00.350 | **REJECT_COOLDOWN**; entry kế tiếp sớm nhất ở nến 10:07 |

---

## 13. Reset Lock

### 13.1. Token

```text
ResetRequested ⇔ ResetLockTarget ≠ NONE ∧ ResetLockToken ≠ LastResetToken (persist)
Khi ResetRequested: LastResetToken = ResetLockToken (persist ngay, kể cả khi verify thất bại) → mỗi token chỉ dùng một lần
```

### 13.2. Hành động theo mục tiêu

| Target | Điều kiện được thử | Rebase | Verify (tất cả phải đúng) |
|---|---|---|---|
| ACCOUNT_PROTECTION | Lock đang bật | `APBase = ACCOUNT_EQUITY` | APLoss = 0 < APLimit; không intent chờ; mọi Basket IDLE hoặc ACTIVE có budget xác minh; state ghi được |
| EQUITY_DD | Lock đang bật | `HWM = ACCOUNT_EQUITY` | EqDD = 0; như trên |
| COMBINED_LOSS | Lock đang bật | Không | CombinedNet > −MaxCombinedLoss; như trên |
| SAFE_MODE | SAFE MODE đang bật | Không | 0 position EA mỗi phía, 0 intent, state ghi được |
| DAILY_LOSS | **Không hỗ trợ reset thủ công** | — | Daily chỉ tự hết khi sang ngày (§8). Nếu cho phép reset tay thì phải rebase Snap, tức xóa hạn mức ngày — trái mục đích lock. |

Verify thất bại → lock **giữ nguyên**, log từng điều kiện sai. Reset một mục không thay đổi mục khác.

| Test | Kịch bản | Kết quả |
|---|---|---|
| F-RST-01 | LastResetToken = 0; Target = EQUITY_DD, Token = 1; Equity 503.50, HWM 530 | HWM → 503.50, verify OK → **EQ unlock**; LastResetToken = 1 |
| F-RST-02 | Restart với cùng Target/Token = 1 | `Token = LastResetToken` → không làm gì, log `RESET_TOKEN_ALREADY_USED` |
| F-RST-03 | Target = COMBINED_LOSS, Token = 2, nhưng Equity DD Lock vẫn bật | Combined unlock; **EQ Lock vẫn bật** → vẫn không giao dịch |
| F-RST-04 | Target = SAFE_MODE, Token = 3, còn 1 position BUY | Verify thất bại → SAFE MODE giữ nguyên |
| F-RST-05 | Target = DAILY_LOSS | Log `RESET_TARGET_NOT_ALLOWED`, token vẫn bị tiêu |
| F-RST-06 | Daily Lock + ngày mới + Combined Lock đang bật | Daily giữ; sau khi Combined reset thủ công thành công (F-RST-03 kiểu), Daily tự hết ở chu kỳ kế tiếp vì điều kiện ngày đã thỏa |

---

## 14. Danh sách input mới / đổi tên phát sinh ở Phase 3

| Input | Mặc định | Nguồn |
|---|---|---|
| `SlippageStressPoints` | 30 | Addendum §12 |
| `SpreadStressMultiplier` | 1.0 | Phase 3 §6 (stress test spread ×1.5/×2.0 của đặc tả) |
| `CommissionPerLotEstimate` | 0.0 (log `COMMISSION_UNVERIFIED` tới khi có deal thật) | Phase 3 §4 |
| `MaxMarginUsage` | 0.50 | Phase 3 §7 G6 |
| `MaxATR_USD` | 3.0 | Rev 2 N-09 |
| `AccountProtectionDailyLossPercent` | 3.0 | Rev 3 P3-01 |
| `MaxEquityDDPercent` | 5.0 | Rev 3 D-04 |
| `BasketBudgetBase` | EQUITY | Đặc tả §6.2 |
| `ResetLockTarget` / `ResetLockToken` | NONE / 0 | Rev 3 P3-03 (bỏ DAILY_LOSS khỏi danh sách hợp lệ) |

## 15. Câu hỏi xác nhận

- **P3-Q1:** Equity DD dùng công thức §10.1 (dịch HWM theo dòng tiền, limit theo % HWM thực) thay cho `HWM_adj × %` — để rút tiền lớn không làm hạn mức 5% phình thành % lớn hơn của equity thật?
- **P3-Q2:** Daily Loss Lock **không** cho reset thủ công (chỉ tự hết khi sang ngày)?
- **P3-Q3:** TP/SL Basket tính **sau** phí đóng ước tính (`NetBasketAfterExit`) — tức TP 1.50 là lãi ròng sau mọi phí dự kiến?

Toàn bộ test vector F-* ở trên sẽ được chuyển thành unit test (script MQL5 chạy trong terminal) ở Phase 8.
