# Backtest Log

Mỗi lần chạy được ghi nguyên trạng, kể cả kết quả âm. Không chỉnh sửa số liệu.

## Run 1 — 2026-09-01 → 2026-09-26 (sau bản sửa ReadSnapshot)

| Thiết lập | Giá trị |
|---|---|
| EA | XAUUSDc_AdaptiveGrid v1.00 (commit sửa ReadSnapshot) |
| Symbol / TF | XAUUSDc / M1 |
| Model | Every tick based on real ticks |
| Deposit | 500 USC, leverage 1:2000 |
| Delays | Zero latency |
| Inputs | Mặc định (`Presets/XAUUSDc_AdaptiveGrid_Default.set`) |
| History Quality | **0%** (tester báo; chưa rõ nguyên nhân — cần kiểm tra cảnh báo tick XAUUSDc) |
| Ticks / Bars | 5,711,085 / 25,904 |

| Chỉ số | Giá trị |
|---|---|
| Total Net Profit | **−23.60 USC** |
| Gross Profit / Gross Loss | 6.00 / −29.60 |
| Profit Factor | **0.20** |
| Expected Payoff | −2.36 / lệnh |
| Total Trades / Deals | 10 / 20 |
| Win rate (lệnh) | 40% (4/10) — hòa vốn lý thuyết 76.92% |
| Short / Long | 7 (28.57% thắng) / 3 (66.67% thắng) |
| Largest / Avg win | +1.50 / +1.50 |
| Largest / Avg loss | −5.00 / −4.93 |
| Max consecutive losses | 3 (−14.90) |
| Max Equity DD | 23.70 (4.74%) — sát ngưỡng Equity DD Lock 5% |
| Recovery Factor | −1.00 |

**Nhận định (mẫu 10 lệnh — không đủ ý nghĩa thống kê):**

- Cơ chế TP/SL hoạt động đúng ngưỡng: thắng đúng +1.50, thua ≈ −5.00.
- Khớp với dự báo Phase 3/Run smoke: ATR M1 cao ⇒ Risk Gate chỉ cho 1 tầng ⇒ chiến lược thực tế là một lệnh TP 1.5 / SL 5, cần win rate ≥ 77%. Quan sát 40%.
- Kết luận tạm: **NOT READY**. Cần chạy giai đoạn dài hơn để có đủ mẫu trước khi xem xét thay đổi chiến lược.
