# Thông số XAUUSDc đã quan sát (Strategy Tester)

**Nguồn:** Journal của Strategy Tester trên terminal Exness (máy chủ `Exness-MT5Real48`, tài khoản Hedge) do người dùng chạy ngày 2026-11-10, EA `XAUUSDc_AdaptiveGrid` v1.00, deposit currency USC.
**Mức độ xác minh:** đọc trực tiếp từ `SymbolInfo*` và `OrderCalcProfit()` **trong tester**. Cần đối chiếu lại trên tài khoản Demo/Real Standard Cent trước khi chạy thật (thông số tester có thể khác live).

| Thuộc tính | Giá trị quan sát | Ghi chú |
|---|---|---|
| `SYMBOL_VOLUME_MIN` | 0.01 | |
| `SYMBOL_VOLUME_MAX` | 200.00 | |
| `SYMBOL_VOLUME_STEP` | 0.01 | |
| `SYMBOL_TRADE_CONTRACT_SIZE` | 1.0 | 1 lot = 1 oz ⇒ 0.01 lot = 0.01 oz |
| `SYMBOL_TRADE_TICK_SIZE` | 0.001 | |
| `SYMBOL_TRADE_TICK_VALUE` | 0.1 | theo tiền tài khoản (USC) cho 1 lot |
| `SYMBOL_POINT` | 0.001 | `MaxSlippagePoints=30` ⇒ 0.030 giá |
| `SYMBOL_DIGITS` | (bị cắt trong ảnh; suy ra 3 từ point) | cần xác nhận |
| `ACCOUNT_CURRENCY` (tester) | USC | gõ tay được trong ô deposit currency |
| `OrderCalcProfit(BUY, 0.01, P, P+1.00)` | **+1.000000 USC** | **Khớp giả định K của Phase 3** (1 USC / 1.00 giá / 0.01 lot) |
| Spread quan sát | 0.160 (160 point) | một thời điểm ngày 2026-01-02, không phải thống kê |

## Hệ quả

- Toàn bộ ví dụ số Phase 3 (§5–§7) đúng đơn vị trên symbol này: 1 tầng 0.01 lot ≈ 1 USC cho mỗi 1.00 USD giá.
- Biến động 2026 cao hơn ví dụ Phase 3 (ATR M1 quan sát 1.1–1.6 thay vì 0.8). Với ATR ≈ 1.4, spread 0.16, budget 5 USC, risk gate dự kiến cho tối đa **2 tầng** (ước tính tay, chưa kiểm chứng).

## Cảnh báo dữ liệu tick

Journal có cảnh báo `USDUSCc: all the real ticks discarded within a day` và `tick prices mismatch` cho các ngày từ 2026-09-27 trở đi. Cần kiểm tra cảnh báo tương tự cho `XAUUSDc` trước khi dùng giai đoạn đó để đánh giá; những ngày bị loại real ticks sẽ chạy bằng tick sinh ra, làm sai lệch spread và thứ tự khớp lệnh.

## Lần chạy đầu tiên (smoke run) — không dùng để đánh giá hiệu suất

- Deposit **10000 USC** (không phải 500) ⇒ budget Basket = 100 USC, trong khi Combined/Daily = 10 USC.
- SELL Basket mở 3 tầng, lỗ −10.20 USC ⇒ `LOCK_COMBINED_LOSS` + `LOCK_DAILY_LOSS`, đóng toàn bộ theo ticket (rc=10009), `BASKET_CLOSED`.
- Xác nhận cơ chế: INIT validation, entry, grid add, combined/daily lock, đóng theo ticket, dashboard. Không xác nhận hiệu suất.
