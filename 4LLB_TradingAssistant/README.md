# 4LLB Human-Approved Trading Assistant v2.0 (MT5 / MQL5)

EA cho MetaTrader 5 (Exness) theo dõi **XAUUSD / XAUUSDc**, xác định **4 mức thanh khoản** (PDH, PDL, P3, P4) trên D1 + M15 bằng Pivot 3-3, phát hiện **Liquidity Sweep** và **Breakout**, gửi đề xuất lên **Telegram** với nút **ACCEPT / REJECT**, và chỉ đặt **lệnh chờ Buy Stop / Sell Stop** (SL theo swing, TP RR 1:2) **sau khi bạn ACCEPT hợp lệ**.

> Không có ACCEPT hợp lệ → không có giao dịch. EA không tự quyết định thay bạn, không market order, không trailing/BE/grid/martingale.

## Trạng thái (2026-11-17)

| Mốc | Trạng thái | Bằng chứng |
|---|---|---|
| Designed (Phase 0–2) | ✅ | `Documentation/Phase0…`, `Phase1…`, `Phase2…` |
| Implemented (Phase 3) | ✅ | `MQL5/` (~9.000 dòng) |
| Static-reviewed | ✅ | `Tools/mql5_static_check.py` → 0 lỗi; `Tools/reference_model_test.py` → 50/50 |
| Compiled | ✅ 2026-11-17 | Người dùng compile bằng MetaEditor (MT5 Exness): EA + script unit test **0 errors, 0 warnings** |
| Unit-tested trên MT5 | ⏳ chờ bạn | `4LLB_UnitTests.mq5` (139 assert) |
| Backtested / Demo-verified / Production-ready | ❌ chưa | `Installation_Guide.md` §9 (Release Gate) |

## Quyết định đã chốt với người dùng

| ID | Quyết định |
|---|---|
| D-01 | Swing tham chiếu SL & invalidation = **cực trị cấu trúc setup** (đỉnh/đáy nến sweep; đáy/đỉnh vùng retest). Có input chuyển sang Pivot 3-3 đã xác nhận |
| D-02 | P3/P4 "gần nhất" = **theo giá** |
| D-03 | ATR(14) khung **M15** |
| D-04 | Khối lượng mặc định **LotSize cố định**; có RiskPercent (Balance/Equity) làm tuỳ chọn |

Mọi giả định kỹ thuật khác (A-01…A-35) và rủi ro đã biết nằm ở `Documentation/Phase0_SRS_Audit_and_Ambiguity_Register.md`.

## Bắt đầu nhanh

1. `Documentation/Installation_Guide.md` — copy file, compile, chạy unit test, cấu hình MT5.
2. `Documentation/Telegram_Bot_Setup_Guide.md` — tạo bot, lấy Chat ID, lưu token an toàn.
3. Gắn EA vào **một** chart trên tài khoản **Demo**, kiểm tra theo `Installation_Guide.md` §8.
4. Chạy checklist Release Gate (§9) trước khi nghĩ tới tài khoản thật.

## Cấu trúc

```text
4LLB_TradingAssistant/
├─ MQL5/Experts/4LLB/4LLB_TradingAssistant.mq5   EA
├─ MQL5/Include/4LLB/LLB_*.mqh                   19 module
├─ MQL5/Scripts/4LLB/4LLB_UnitTests.mq5          unit test
├─ Tools/                                        kiểm tra tĩnh + mô hình tham chiếu (Python 3)
└─ Documentation/
   ├─ Source/                                    master prompt gốc
   ├─ Phase0_SRS_Audit_and_Ambiguity_Register.md
   ├─ Phase1_Architecture.md
   ├─ Phase2_Detailed_Design.md
   ├─ Phase3_Implementation_Report.md
   ├─ Phase4_Test_Plan.md
   ├─ Installation_Guide.md                      (gồm Phase 5 Release Gate)
   └─ Telegram_Bot_Setup_Guide.md
```

## Kiểm tra lại trong repo

```bash
python3 Tools/mql5_static_check.py MQL5     # 0 error(s)
python3 Tools/reference_model_test.py       # REFERENCE MODEL: 50 passed, 0 failed
```

## Rủi ro đã biết (tóm tắt)

- **A-24:** XAUUSD và XAUUSDc thường ở hai loại tài khoản Exness khác nhau → hai terminal cần **hai bot Telegram**.
- **A-23:** Exness dùng giờ server GMT+0 nên có thể có nến D1 Chủ nhật ngắn; theo đúng SRS, PDH/PDL thứ Hai lấy từ nến đó (đề xuất cải tiến E-01, chưa triển khai).
- **A-11:** Khoá chống chạy trùng chỉ thấy được instance trên **cùng máy**.
- **A-30:** Bản SRS đầy đủ (định nghĩa test F-001…POS-006) chưa được đính kèm; mã test hiện được suy ra từ baseline.
