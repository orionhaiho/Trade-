# Phase 1 — Rev 3: Quyết định Daily Loss, Equity DD, Lock và Grid Execution

**Nguồn:** chỉ thị bổ sung của người dùng (sau Addendum V2.0), trả lời Q1–Q3 của Rev 2.
**Thứ tự ưu tiên:** Master prompt > Chỉ thị Rev 3 này > Addendum V2.0 > Đặc tả gốc v1.0.
**Trạng thái:** Phân tích/quyết định thiết kế. Chưa có code.

---

## 1. Quyết định đã chốt

| ID | Nội dung | Quyết định |
|---|---|---|
| D-01 | EA Daily Loss (Q1) | EA-scope (symbol + MagicBuy/MagicSell). `EADailyPL = RealizedToday + FloatingNetNow − FloatingNetAtDayStart`. Realized = profit + swap + commission + fee của deal OUT trong ngày + commission/fee của deal IN trong ngày. FloatingNet = profit + swap của position mở + phí entry đã trả của chúng. Snapshot `FloatingNetAtDayStart` (đã chứa phí entry của position qua đêm) → không đếm trùng. Mất snapshot trong ngày → dùng 0 (chặt hơn). |
| D-02 | Account Equity Protection | Lớp thứ hai, theo **equity toàn tài khoản**, không lọc magic. Xem P3-01 cho mốc/ngưỡng. |
| D-03 | Daily Lock reset | Tự reset khi `ServerDate > LockDate` **và** không có SAFE MODE **và** không có Account Protection / Equity DD / Combined Lock. Nếu bị chặn reset, Daily Lock giữ nguyên và được xét lại ở mỗi chu kỳ (khi lock cao hơn được reset thủ công và ngày đã qua, Daily Lock tự hết theo điều kiện riêng của nó — không phải "vì lock khác đã reset"). |
| D-04 | Equity DD (Q2) | Account-wide. `AdjustedEquity = ACCOUNT_EQUITY − NetExternalFlow`; `HWM = max(AdjustedEquity đã ghi nhận)`; `DD = HWM − AdjustedEquityNow`; `Limit = HWM × MaxEquityDDPercent / 100` (mặc định 5.0 → 25 USC tại 500). Lock khi `DD ≥ Limit`. Không tự mở khi sang ngày. HWM persist, không reset khi restart. |
| D-05 | Combined Loss Lock | `CombinedNet = NetFloating(BUY) + NetFloating(SELL)` (position đang mở của EA, gồm phí entry đã trả). Lock khi `CombinedNet ≤ −MaxCombinedLoss_AccountCurrency`. (Risk Gate dùng *projected*; Lock dùng *hiện tại* — không trộn.) Chỉ reset thủ công. |
| D-06 | Lock priority | 1 Account Protection > 2 Equity DD > 3 Combined Loss > 4 Daily Loss > 5 SAFE MODE > 6 Filters. Mọi lock đều chặn lệnh mới như nhau; thứ tự quyết định hiển thị, log và điều kiện reset. Reset một lock **không** reset lock khác. |
| D-07 | Grid add (Q3) | Entry: chỉ tick đầu nến M1 mới. Add: xét **mọi tick**, ≤ 1 lệnh/phía/nến, cooldown ≥ 60 s từ fill được broker xác nhận, spread hợp lệ, `ADX[1] < MaxADX`, không lock, không request chờ reconcile, Risk Gate qua. Trigger chạm nhưng gate từ chối → log `REJECT_*`, không nới budget, không tăng lot. Log bị throttle: tối đa 1 dòng `REJECT` cùng lý do / phía / nến để tránh spam mỗi tick. |
| D-08 | `UseNewBarOnly` | Bỏ input: hành vi giờ đã cố định (entry = new bar, add = mọi tick). Giữ input sẽ cho phép cấu hình trái chỉ thị. |
| D-09 | `MaxEquityDD_AccountCurrency` | Thay bằng `MaxEquityDDPercent = 5.0` theo D-04. |

## 2. Xử lý nạp/rút (NetExternalFlow)

- Quét deal history từ `LastFlowScanTime` (persist) tới hiện tại; lọc `DEAL_TYPE_BALANCE`, `DEAL_TYPE_CREDIT`, `DEAL_TYPE_BONUS` → cộng `DEAL_PROFIT` vào `NetExternalFlow` (nạp dương, rút âm). Ghi nhớ ticket deal cuối đã xử lý để không cộng lặp.
- `DEAL_TYPE_CHARGE`, `DEAL_TYPE_CORRECTION`, `DEAL_TYPE_COMMISSION*`, `DEAL_TYPE_INTEREST` **không** coi là dòng tiền ngoài → được tính như lãi/lỗ (bảo thủ).
- `ACCOUNT_EQUITY` có chứa credit → credit xử lý như dòng tiền ngoài để nhất quán.
- Lần đầu: `NetExternalFlow = 0`, `HWM = ACCOUNT_EQUITY`, ghi `LastFlowScanTime = now`.
- Không đọc được history khi cần quét → giữ giá trị cũ, đánh dấu `FLOW_SCAN_INCOMPLETE`, chặn lệnh mới (không SAFE MODE vì đóng/quản lý vẫn an toàn) cho tới khi quét thành công.

## 3. Điểm mới cần xác nhận (có mặc định an toàn — không chặn Phase 2)

| ID | Vấn đề | Mặc định đề xuất (đã đưa vào thiết kế Phase 2 dưới dạng input) |
|---|---|---|
| P3-01 | Account Protection Lock chưa có **mốc và ngưỡng**. Nếu dùng chung HWM với Equity DD thì hai lock trùng nhau. Vì nó nằm trong mục Daily Loss, cách hiểu hợp lý là *lỗ ngày toàn tài khoản*. | Mốc = `AdjustedEquity` lúc bắt đầu ngày server (persist). Lock khi `AccountDayStartAdjEquity − AdjustedEquityNow ≥ AccountProtectionDailyLossPercent% × AccountDayStartAdjEquity`; mặc định **3.0%** (≈15 USC tại 500, lớn hơn EA Daily 10 USC để lớp này chỉ bắt lỗ ngoài EA hoặc lỗ vượt thiết kế). Reset: **thủ công** (ưu tiên cao nhất). |
| P3-02 | Reset thủ công Equity DD Lock khi equity chưa hồi: nếu giữ HWM cũ, lock sẽ kích hoạt lại ngay (EA không có lệnh để hồi equity). | Reset Equity DD Lock = **rebase HWM về AdjustedEquity hiện tại** (log giá trị cũ/mới). Tương tự Account Protection reset = rebase mốc đầu ngày về hiện tại. Combined Loss reset không cần rebase (lỗ đã được đóng). |
| P3-03 | Cơ chế reset thủ công | Hai input: `ResetLockTarget` (enum: NONE, ACCOUNT_PROTECTION, EQUITY_DD, COMBINED_LOSS, DAILY_LOSS, SAFE_MODE) và `ResetLockToken` (int). Chỉ thực hiện khi token ≠ token đã dùng (persist) → không lặp lại sau restart. Mỗi lần reset **một** mục; sau đó bước `RESET_VERIFY` (xem Phase 2 §4.3). |

Nếu người dùng không phản đối, các mặc định P3-01..P3-03 được dùng trong Phase 4.
