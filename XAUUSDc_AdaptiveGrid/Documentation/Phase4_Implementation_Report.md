# Phase 4 — Báo cáo triển khai MQL5

**Trạng thái:** `Implemented` + `Static-reviewed` + **`Compiled`** (người dùng compile bằng MetaEditor trên máy Windows của họ ngày 2026-11-10, báo **0 errors, 0 warnings**; build MetaEditor chưa ghi nhận). Chưa chạy unit test, chưa backtest, chưa chạy trên Demo.

---

## 1. Cấu trúc file

| File | Dòng (≈) | Trách nhiệm |
|---|---|---|
| `Experts/XAUUSDc_AdaptiveGrid.mq5` | 630 | Inputs, OnInit/OnDeinit/OnTick/OnTimer/OnTradeTransaction, chu kỳ `RunCycle`, entry/add, TP/SL, reset thủ công, dashboard |
| `Include/AG_Types.mqh` | 290 | Enum, struct, `AGConfig g_cfg` |
| `Include/AG_Math.mqh` | 200 | Hàm thuần (không gọi terminal) theo Phase 3 — dùng cho unit test Phase 8 |
| `Include/AG_Logger.mqh` | 165 | CSV + journal, throttle log REJECT theo phía/lý do/nến |
| `Include/AG_Environment.mqh` | 230 | Validate symbol/account/Hedging/USC/spec, filling mode, `OrderCalcProfit` sanity, phiên giao dịch |
| `Include/AG_Indicators.mqh` | 105 | Handle BB/RSI/ADX/ATR, snapshot shift 1 & 2 |
| `Include/AG_Signals.mqh` | 50 | Tín hiệu TWO/ONE_CANDLE, ADX regime, ATR sanity |
| `Include/AG_GridManager.mqh` | 40 | Grid distance, trigger, volume helpers |
| `Include/AG_BasketManager.mqh` | 415 | `CBasket` ×2, quét position theo symbol+magic+type, fee attribution, cache |
| `Include/AG_RiskManager.mqh` | 500 | Dòng tiền ngoài, EA daily, AP, HWM, combined, locks, stress risk, Risk Gate |
| `Include/AG_Persistence.mqh` | 340 | State file key=value + CRC32, ghi atomic, load nghiêm ngặt |
| `Include/AG_Execution.mqh` | 270 | Module duy nhất gửi lệnh: open (intent trước send), close theo ticket, retry |
| `Include/AG_Recovery.mqh` | 310 | Fresh init / state lost, reconcile intent, consistency, emergency close |
| `Presets/XAUUSDc_AdaptiveGrid_Default.set` | — | Bộ input mặc định |

## 2. Truy vết công thức Phase 3 → code

| Phase 3 | Hàm |
|---|---|
| §1.1 Volume | `AG_VolumeToSteps`, `AG_IsValidVolume` (AG_Math) |
| §1.2 Giá | `AG_NormalizeToTick`, `AG_CeilToTick` |
| §1.3 Spread | `CommonOrderFilters` (.mq5) |
| §2 Grid | `AG_CalcGridDistance`, `AG_BuyGridTrigger`, `AG_SellGridTrigger`, `CalculateGridDistance` |
| §3 Tín hiệu | `AG_Signal*`, `CheckBuySignal`, `CheckSellSignal` |
| §4 Phí | `ReadPositionHistory`, `GetFeeIn`, `FeeRatePerLot`, `CBasket::NetAfterExit` |
| §5 Budget/TP/SL | `AG_CalcBudget`, `AG_CalcEffectiveSL`, `EvaluateBasketExit` |
| §6 Stress | `EstimateWorstCaseRisk` |
| §7 Risk Gate G1–G7 | `RiskGate` (+ `OrderCheck` trong `ExecuteOrderSafely`) |
| §8 EA Daily | `ComputeEADailyPL`, `NewServerDayCheck`, `AG_CalcDailyPL` |
| §9 AP | `ComputeAccountMetrics`, `EvaluateRiskLocks`, `UpdateExternalFlows` |
| §10 HWM | như trên, `AG_DrawdownBreached` |
| §11 Combined | `ComputeAccountMetrics`, `EvaluateRiskLocks` |
| §12 Tần suất | `AG_CooldownOK`, `AG_OnePerBarOK`, `CommonOrderFilters` |
| §13 Reset | `ProcessManualReset`, `VerifyBeforeUnlock`, `DailyAutoReset` |

## 3. Rà soát tĩnh (đã thực hiện)

| Kiểm tra | Kết quả |
|---|---|
| Cân bằng `{}`, `()`, `[]` mọi file (script đếm sau khi bỏ chuỗi/chú thích) | 0 lệch ở cả 13 file |
| `OrderSend` chỉ xuất hiện trong `AG_Execution.mqh` | Đúng (2 chỗ: open, close) |
| Mọi lời gọi `ExecuteOrderSafely` có `RiskGate` ngay trước trong cùng hàm | Đúng (`TryInitialEntry`, `TryGridAdd`) |
| Không hằng số broker (contract/tick value/point/digits/volume step) | Không có; mọi giá trị đọc từ `SymbolInfo*` |
| Đóng lệnh kiểm symbol + magic + type trước khi gửi | `ClosePositionByTicket` |
| Không đọc shift 0 cho tín hiệu | `CopyBuffer(...,1,2,...)`, `CopyRates(...,1,2,...)` |
| Lot cố định, không multiplier | `LotMultiplier≠1.0` → INIT_FAILED; mọi lệnh dùng `InitialLot` |
| Netting / sai currency / sai symbol / chart khác symbol → INIT_FAILED | `ValidateEnvironment` |
| Bước 1–9 của chu kỳ không phụ thuộc ADX/nến mới/indicator | `RunCycle` |
| Intent được lưu file trước `OrderSend`; timeout không gửi lại | `ExecuteOrderSafely`, `ReconcileIntent` |

## 4. Quyết định triển khai bổ sung (công khai)

| ID | Nội dung | Lý do |
|---|---|---|
| I-01 | `OnTimer` 1 s chạy toàn bộ quản lý rủi ro/đóng lệnh; lệnh mới chỉ phát sinh từ `OnTick` | Đóng/retry/persist vẫn chạy khi không có tick |
| I-02 | `OnTradeTransaction` chỉ kích hoạt một chu kỳ, không dùng làm nguồn sự thật | Phase 2 §2 |
| I-03 | Quét nạp/rút chỉ chạy khi balance/credit đổi, mỗi 60 s, hoặc bắt buộc ngay trước khi kích hoạt AP/EQ lock | Tránh `HistorySelect` toàn lịch sử mỗi tick trong tester; vẫn tránh khóa nhầm do rút tiền |
| I-04 | Đóng lệnh gặp MARKET_CLOSED/TRADE_DISABLED/CONNECTION: không tính vào số lần retry, thử lại sau 30 s | Tránh spam cuối tuần, không bỏ trạng thái CLOSING |
| I-05 | Sau lệnh đóng được chấp nhận: chờ ≥ 1 s trước khi được gửi lại cho cùng ticket | Chống đóng trùng |
| I-06 | `UseNewsFilter=true` → chặn giao dịch, log `NEWS_FILTER_UNAVAILABLE` | Chưa tích hợp Economic Calendar; fail-closed theo đặc tả §8 |
| I-07 | Daily: nếu ranh giới ngày không được quan sát liên tục (EA offline qua nửa đêm) → `Snap = 0`, log `NEW_SERVER_DAY_LATE_SNAPSHOT` | Phase 3 §8 (bảo thủ) |
| I-08 | Token reset đang có trong input lúc FRESH_INIT/STATE_LOST bị coi là đã dùng | Không để input cũ vô tình mở khóa |
| I-09 | Quyền sở hữu deal OUT xác định qua magic của deal IN cùng position (không dựa magic của deal OUT) | Deal đóng bởi SL server/đóng tay có thể mang magic khác |
| I-10 | Thứ tự reset khi STATE_LOST: SAFE_MODE trước (cần 0 position), sau đó AP / EQUITY_DD / COMBINED; DAILY tự hết sang ngày | `VerifyBeforeUnlock` yêu cầu Basket IDLE/ACTIVE-có-budget |

## 5. Rủi ro compile cần kiểm tra khi build lần đầu

Code viết theo API MQL5 chuẩn nhưng chưa qua compiler. Các điểm có khả năng sinh lỗi/cảnh báo, nếu có thì sửa ở vòng sau:

1. Truyền trường của phần tử mảng đối tượng toàn cục theo tham chiếu (`KVInt(..., g_basket[s].state)`).
2. Hằng `TRADE_RETCODE_*` ít gặp (`ONLY_REAL`, `LIMIT_ORDERS`, `INVALID_ORDER`, `POSITION_CLOSED`) — có trong build MT5 hiện hành; build rất cũ có thể thiếu.
3. `DEAL_FEE` — có từ build 2000+.
4. Cảnh báo chuyển kiểu ngầm định (long ↔ datetime, enum ↔ int) — không ảnh hưởng logic nhưng cần đọc kỹ.

## 6. Hướng dẫn compile (người dùng tự thực hiện)

1. MT5 → File → Open Data Folder.
2. Copy `Include/*.mqh` vào `MQL5/Include/AdaptiveGrid/` (đúng tên thư mục, vì file `.mq5` dùng `#include <AdaptiveGrid\...>`).
3. Copy `Experts/XAUUSDc_AdaptiveGrid.mq5` vào `MQL5/Experts/`.
4. Mở MetaEditor, mở file `.mq5`, nhấn **Compile (F7)**.
5. Gửi lại toàn bộ tab **Errors** (số error/warning và nội dung) — tôi sẽ sửa và cập nhật trạng thái thành `Compiled` chỉ khi có bằng chứng 0 error.

## 7. Chưa thực hiện

- Compile, unit test (script MQL5 dùng `AG_Math.mqh` + test vector Phase 3) — Phase 8.
- Strategy Tester, stress test, Monte Carlo, walk-forward — Phase 8 (người dùng chạy, hoặc cung cấp kết quả).
- Tài liệu cài đặt/backtest/tham số đầy đủ, test plan, CSV mẫu — Phase 7–9.

## 8. Kết quả compile

| Ngày | Môi trường | Kết quả | Bằng chứng |
|---|---|---|---|
| 2026-11-10 | MetaEditor (MT5 Exness) trên Windows của người dùng; build chưa ghi nhận | 0 errors, 0 warnings | Người dùng báo lại trong phiên làm việc |
