# M1 — Hướng dẫn cài đặt, cấu hình và kiểm tra trên MT5

> EA này **chỉ đọc**: không mở, sửa, hủy hay đóng bất kỳ lệnh/position nào. Nó chỉ in trạng thái ra tab **Experts** của MT5.

## 1. Yêu cầu

- MetaTrader 5 (bản Exness) đã đăng nhập tài khoản, kèm MetaEditor.
- Không cần DLL, WebRequest hay quyền giao dịch.

## 2. Cài đặt

1. MT5 → **File → Open Data Folder** → mở `MQL5/Experts/`.
2. Copy **nguyên thư mục** `RiskManagement` từ repo vào đó. Cấu trúc sau khi copy:
   ```text
   MQL5/Experts/RiskManagement/
   ├── RiskManagement.mq5
   ├── Include/Core/CoreEngine.mqh, AccountEngine.mqh
   ├── Include/Models/AccountModel.mqh
   ├── Include/Validation/DataValidator.mqh
   ├── Include/Utils/Logger.mqh
   └── Tests/RiskManagement_M1_Tests.mq5
   ```
   Các thư mục `Documentation/`, `Tools/`, `Tests/host/` không bắt buộc; MetaEditor bỏ qua chúng.
3. Mở MetaEditor → mở `RiskManagement.mq5` → **Compile (F7)**. Sau đó compile `Tests/RiskManagement_M1_Tests.mq5`.
4. Gửi lại toàn bộ tab **Errors** của cả hai lần compile (số error/warning + nội dung).

Không đổi tên hoặc di chuyển thư mục `Include/`: các `#include` dùng đường dẫn tương đối (`Include/...`, `../...`).

## 3. Cấu hình (inputs)

| Input | Mặc định | Ý nghĩa | Giá trị hợp lệ |
|---|---|---|---|
| `InpAccountRefreshSeconds` | `1` | Chu kỳ làm mới (giây) | ≥ 1. Giá trị < 1 làm EA **không khởi động** (`EA_INITIALIZATION_FAILED`), không tự thay bằng mặc định |
| `InpEnableLogging` | `true` | Bật log INFO/WARNING | `false`: chỉ còn dòng **ERROR** (lỗi khởi tạo, dữ liệu INVALID/lỗi API, đổi tài khoản) |
| `InpEnableDebugLogging` | `false` | Mỗi chu kỳ thành công in 1 dòng đủ giá trị | Chỉ hiệu lực khi `InpEnableLogging=true`. Chỉ bật khi kiểm tra (khoảng 86.400 dòng/ngày với chu kỳ 1 s) |
| `InpRequireConnectedTerminal` | `true` | Bắt buộc có kết nối trade server | `true` (khuyến nghị): mất kết nối → `UNAVAILABLE`. `false`: dữ liệu lúc mất kết nối được gắn `STALE`, không bao giờ `VALID` |

Gắn EA: Navigator → Expert Advisors → `RiskManagement` → kéo vào **một** chart bất kỳ (symbol/timeframe không ảnh hưởng). EA không cần **Allow Algo Trading**; có thể để tắt như một lớp an toàn bổ sung (xem L-14).

## 4. Đọc log

Định dạng: `[RiskManagement][giờ local][MỨC][EVENT_CODE] nội dung`. Log chỉ in khi **trạng thái thay đổi**: lỗi lặp lại không in lại mỗi giây.

| Event code | Mức | Khi nào |
|---|---|---|
| `EA_INITIALIZED` | INFO | Khởi động xong (kèm cấu hình + identity, hoặc "identity pending") |
| `EA_INITIALIZATION_FAILED` | ERROR | Input sai, engine lỗi, tạo timer lỗi |
| `ACCOUNT_COLLECTION_SUCCESS` | INFO / DEBUG | Snapshot VALID đầu tiên (khóa identity), phục hồi sau lỗi; DEBUG = chi tiết mỗi chu kỳ |
| `ACCOUNT_COLLECTION_FAILED` | WARNING / ERROR | Vào trạng thái lỗi hoặc đổi lý do lỗi (WARNING: mất kết nối/STALE; ERROR: dữ liệu INVALID, lỗi API, thiếu giờ server) |
| `ACCOUNT_IDENTITY_CHANGED` | ERROR | Login/server/currency khác identity gốc → EA khóa, cần **restart EA** |
| `TERMINAL_DISCONNECTED` / `TERMINAL_RECONNECTED` | WARNING / INFO | Mất / có lại kết nối |
| `EA_SHUTDOWN` | INFO | EA dừng (kèm lý do: REMOVE, ACCOUNT, PARAMETERS, …) |

Log mẫu (mô phỏng trên host, file `Tests/host/results/host_log_sample.txt`):

```text
[RiskManagement][2026.11.19 17:00:00][WARNING][TERMINAL_DISCONNECTED] Terminal is not connected to the trade server (first check after start)
[RiskManagement][2026.11.19 17:00:00][INFO][EA_INITIALIZED] RiskManagement M1 initialized (strict read-only). refresh_seconds=1 logging=true debug_logging=false require_connected_terminal=true. Account identity pending (no valid snapshot yet): ...
[RiskManagement][2026.11.19 17:00:04][INFO][TERMINAL_RECONNECTED] Terminal connected to the trade server (it was not connected when the EA started) after about 4 s
[RiskManagement][2026.11.19 17:00:04][INFO][ACCOUNT_COLLECTION_SUCCESS] First valid account snapshot; identity baseline locked: login=12345678 server="Exness-MT5Real8" currency="USD" company="Exness Technologies Ltd" (after 4 failed cycle(s))
[RiskManagement][2026.11.19 17:00:06][ERROR][ACCOUNT_COLLECTION_FAILED] No valid account snapshot: status=INVALID reason=DATA_INVALID: ACCOUNT_EQUITY is not a finite number (NaN or Inf) ...
[RiskManagement][2026.11.19 17:00:11][INFO][ACCOUNT_COLLECTION_SUCCESS] Account collection recovered after 5 failed cycle(s)
[RiskManagement][2026.11.19 17:00:19][DEBUG][ACCOUNT_COLLECTION_SUCCESS] cycle=1 status=VALID login=12345678 ... balance=1000.00 equity=1013.75 profit=12.50 credit=25.00 margin=50.00 free_margin=960.00 margin_level=2027.25 leverage=500 margin_mode=RETAIL_HEDGING trade_allowed=true expert_allowed=true server_time=2026.11.19 10:00:19 collection_time=2026.11.19 17:00:19
```

## 5. Chạy test harness trên MT5

1. Navigator → Expert Advisors → `RiskManagement` → `Tests` → `RiskManagement_M1_Tests` → kéo vào một chart bất kỳ (demo hay real đều được: harness **chỉ dùng dữ liệu giả lập**, không đọc tài khoản thật, không giao dịch).
2. Tab Experts sẽ in các dòng `[RM-TEST] ...`, sau đó harness tự gỡ khỏi chart (`ExpertRemove`). Nếu nó vẫn còn trên chart, gỡ bằng tay.
3. Kỳ vọng: `[RM-TEST] SUMMARY total=48 passed=46 failed=0 not_run=2` và `[RM-TEST] RESULT: all executed tests passed`. Hai test F026 và F030 là `NOT RUN` theo thiết kế (lý do in ngay trên dòng của chúng).
4. Gửi lại toàn bộ các dòng `[RM-TEST]`.

## 6. Checklist kiểm tra trên tài khoản Exness (thủ công)

Bật `InpEnableDebugLogging=true` trong lúc kiểm tra. **Không cần mở lệnh nào** để kiểm tra.

| ID | Bước | Kỳ vọng | Test |
|---|---|---|---|
| L-01 | Compile `RiskManagement.mq5` | 0 error, 0 warning | Gate 1–2 |
| L-02 | Chạy harness (§5) | `failed=0` | F001–F029 |
| L-03 | Gắn EA, xem `EA_INITIALIZED` | login, server, currency, company khớp với tài khoản (Navigator → Accounts, thanh tiêu đề) | F001–F004 |
| L-04 | So dòng DEBUG với Toolbox → Trade | Balance, Equity, Margin, Free margin, Margin level, Profit, Credit khớp (cùng thời điểm) | F005–F011 |
| L-05 | Nếu đang có position | Equity ≠ Balance theo đúng terminal; EA không suy ra giá trị | F006, F010 |
| L-06 | Leverage | Khớp Personal Area Exness. **Nếu tài khoản dùng Unlimited: ghi lại giá trị `leverage=` và trạng thái** | F012, rủi ro L-03 |
| L-07 | `margin_mode` | Ghi lại (tài khoản Exness MT5 thường là `RETAIL_HEDGING`) | F013 |
| L-08 | `trade_allowed`, `expert_allowed` | Ghi lại giá trị | F014 |
| L-09 | Đặt `InpAccountRefreshSeconds=5` | Các dòng DEBUG cách nhau khoảng 5 s | F015 |
| L-10 | Ngắt mạng ngắn (tắt Wi-Fi/cáp) rồi bật lại | 1 `TERMINAL_DISCONNECTED` + 1 `ACCOUNT_COLLECTION_FAILED` (WARNING), không lặp; khi có mạng: `TERMINAL_RECONNECTED` + dòng phục hồi | F017, F018, F029 |
| L-11 | Đặt `InpAccountRefreshSeconds=0` | EA không khởi động, có `EA_INITIALIZATION_FAILED` | F016, F025 |
| L-12 | Gỡ EA; (tùy chọn) đổi sang tài khoản demo khác | `EA_SHUTDOWN reason=REMOVE`; khi đổi tài khoản: `EA_SHUTDOWN reason=ACCOUNT` rồi `EA_INITIALIZED` với identity mới | F027, F019 |
| L-13 | `InpEnableLogging=false` | Không có dòng INFO/WARNING; chỉ ERROR nếu có lỗi | Q-03 |
| L-14 | Tắt **Allow Algo Trading** của EA rồi gắn lại | EA vẫn log `EA_INITIALIZED` và dòng DEBUG; tab History không có giao dịch nào do EA | F030, read-only |

Gửi lại: log tab Experts (đoạn có `[RiskManagement]`), các giá trị Toolbox tương ứng, và ghi chú cho L-06/L-07/L-08.

## 7. Xử lý sự cố

| Hiện tượng | Nguyên nhân / cách xử lý |
|---|---|
| `can't open "...mqh" include file` | Sai cấu trúc thư mục — copy lại nguyên thư mục `RiskManagement` (§2) |
| `EA_INITIALIZATION_FAILED Invalid input` | `InpAccountRefreshSeconds` < 1 |
| `Account identity pending` sau khi gắn EA | Terminal chưa đăng nhập/kết nối; EA tự thử lại mỗi chu kỳ |
| `ACCOUNT_IDENTITY_CHANGED` | Tài khoản đổi khi EA đang chạy → gỡ EA và gắn lại để theo dõi tài khoản mới |
| `DATA_INVALID: ACCOUNT_LEVERAGE must be > 0` | Có thể do leverage Unlimited → gửi log để quyết định đặc tả |
| Không thấy log mỗi giây | Đúng thiết kế (chỉ log khi trạng thái đổi); bật `InpEnableDebugLogging` để xem giá trị mỗi chu kỳ |
