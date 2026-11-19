# M1 — Báo cáo triển khai (Core & Account Engine)

**Dự án:** EA Risk Management — MT5 / MQL5 — Exness — Real account
**Đặc tả:** M1 v1.0 (thay bằng master prompt, xem Phase 0 §0) + quyết định Q-01…Q-04 (Phase 0 §3.1)
**Ngày:** 2026-11-19

## 0. Trạng thái

| Trạng thái | Kết quả | Bằng chứng |
|---|---|---|
| Implemented | **Có** — đủ 6 file nguồn theo cấu trúc bắt buộc | §1 |
| Compiled (MetaEditor) | **NOT COMPILED** — container không có MetaEditor/MT5 (`download.mql5.com` bị chặn) | — |
| Static-reviewed | **Có** | §5, `M1_ReadOnly_Audit_Report.md` |
| Simulated-tested (host) | **Có** — 46/46 test harness chạy được PASS (2 NOT RUN theo thiết kế), 13/13 test lifecycle PASS, 19/19 mutation bị phát hiện | `M1_Test_Report.md`, `Tests/host/results/` |
| MT5-tested | **NOT RUN** — cần bạn compile và chạy harness trên MT5 | `M1_Installation_Guide.md` §5 |
| Live-account-validated | **NOT RUN** | `M1_Installation_Guide.md` §6 |

**Kết luận hiện tại: `IMPLEMENTATION READY FOR MT5 VERIFICATION`** (chưa thể là `M1 ACCEPTED` vì chưa có bằng chứng compile MetaEditor và chạy trên MT5).

## 1. File đã tạo

| File | Trách nhiệm |
|---|---|
| `RiskManagement.mq5` | 4 input (nguyên văn), `OnInit` / `OnTimer` / `OnDeinit`, sở hữu timer, log `EA_INITIALIZED` / `EA_INITIALIZATION_FAILED` / `EA_SHUTDOWN` |
| `Include/Models/AccountModel.mqh` | `ENUM_DATA_STATUS`, `AccountSnapshot` (nguyên văn), sentinel, reset/copy, định dạng hiển thị |
| `Include/Utils/Logger.mqh` | `CLogger`, 4 mức log, 8 event code, chính sách log khi tắt logging (Q-03) |
| `Include/Validation/DataValidator.mqh` | `CDataValidator` (4 method nguyên văn), thuần, deterministic, quy tắc Q-02 |
| `Include/Core/AccountEngine.mqh` | `CAccountDataSource`, `CTerminalAccountDataSource` (nơi duy nhất gọi API tài khoản/terminal), `CAccountEngine` (4 method nguyên văn) |
| `Include/Core/CoreEngine.mqh` | `RiskManagementConfig`, `RMValidateConfig`, `CCoreEngine` (6 method nguyên văn), identity, kết nối, chống spam log |
| `Tests/RiskManagement_M1_Tests.mq5` | Test harness MQL5 (EA): F001–F030 + T01–T18, chỉ dùng dữ liệu giả lập |
| `Tests/host/*` | Shim MQL5 cho C++, test lifecycle entry point, mutation check, kết quả |
| `Tools/readonly_audit.py`, `Tools/readonly_audit_selftest.py` | Audit read-only tự động + tự kiểm tra của audit |

## 2. Public interface so với đặc tả

| Đặc tả | Trong code | Ghi chú |
|---|---|---|
| `input int InpAccountRefreshSeconds = 1;` … `InpRequireConnectedTerminal = true;` | Nguyên văn | `RiskManagement.mq5` |
| `enum ENUM_DATA_STATUS { VALID, UNAVAILABLE, INVALID, STALE }` | Nguyên văn | |
| `struct AccountSnapshot` (19 trường) | Nguyên văn, đúng thứ tự và kiểu | Chỉ thêm comment |
| `CAccountEngine::Initialize/Collect/Shutdown/GetLastErrorMessage` | Nguyên văn | |
| `CDataValidator::ValidateAccountIdentity/Financials/Configuration/ValidateSnapshot` | Nguyên văn | |
| `CCoreEngine::Initialize/Refresh/Shutdown/GetLatestSnapshot/GetCurrentStatus/GetLastSuccessfulCollectionTime` | Nguyên văn | Ngữ nghĩa `GetLatestSnapshot` theo Q-04 |
| API bổ sung | Xem Phase 0 D-21 (Rev1) | Chỉ thêm, không đổi tên/chữ ký nào đã đặc tả |

## 3. Truy vết yêu cầu → code

| Yêu cầu | Hiện thực |
|---|---|
| LC-01, CFG-02 | `RMValidateConfig()` gọi đầu tiên trong `OnInit`; lỗi → `INIT_PARAMETERS_INCORRECT`, không thay giá trị mặc định |
| LC-02 | `g_core.Refresh()` trong `OnInit`, trước `EventSetTimer` |
| LC-03 | `EventSetTimer(g_config.account_refresh_seconds)` chỉ sau `Configure` + `Initialize` thành công; lỗi → log + `g_core.Shutdown()` + `INIT_FAILED` |
| LC-04 | Cờ `g_timer_created`; `EventKillTimer()` chỉ khi cờ bật |
| LC-05 | `CCoreEngine::Refresh()` có cờ `m_refresh_in_progress`; không `Sleep`, không vòng chờ |
| LC-06 | `OnDeinit`: kill timer → `g_core.Shutdown()` (account engine trước, validator không có trạng thái) → `EA_SHUTDOWN` kèm lý do |
| LC-07 | `OnInit` gọi `g_core.Shutdown()` rồi `Configure` + `Initialize` (reset toàn bộ); logger reset bộ đếm |
| CFG-03 | `struct RiskManagementConfig` đọc input một lần (`LoadConfigFromInputs`) |
| MOD-03/04 | `AccountSnapshotReset()` đầu mỗi `Collect()`; `Fail()` reset lại toàn bộ trường khi lỗi; mỗi nhóm chỉ gán vào snapshot khi cả nhóm đọc xong |
| ACC-03 | `CTerminalAccountDataSource`: `ResetLastError()` → API → `GetLastError()` cho từng lời gọi |
| ACC-04…06 | `CollectIdentity`, `CollectFinancials`, `CollectConfiguration` — đọc trực tiếp, không suy diễn |
| ACC-07 | `collection_time = TimeLocal()`; `server_time = TimeTradeServer()`, không có → `0` + `SERVER_TIME_UNAVAILABLE`, không bao giờ dùng giờ local |
| ACC-08 | `CollectConnectionAndAttemptTime()` → `TERMINAL_DISCONNECTED`, `UNAVAILABLE` |
| VAL-* | `CDataValidator::CheckIdentity/CheckFinancials/CheckConfiguration/CheckTimes` |
| CORE-03…05 | `HandleSuccess()` là nơi duy nhất ghi `m_last_success`; `GetLatestSnapshot()` trả `true` chỉ khi trạng thái mới nhất `VALID`, ngược lại bản lịch sử gắn `STALE` |
| ID-01/02 | Identity gốc khóa trong `HandleSuccess()` lần đầu; `RunCycle()` bước 3 so sánh trước khi lưu; `LatchIdentityChange()` chốt và ngừng đọc |
| CONN-01 | `UpdateConnectionState()` — chỉ log khi chuyển trạng thái |
| LOG-* | `CLogger::Log()` định dạng `[RiskManagement][thời gian][MỨC][EVENT] nội dung`; `HandleFailure()` chống lặp bằng khóa (trạng thái, lý do) |

## 4. Quyết định triển khai bổ sung (công khai)

| ID | Nội dung | Lý do |
|---|---|---|
| I-01 | Thứ tự một chu kỳ: thu thập → cập nhật kết nối → kiểm tra identity → validate → (mất kết nối ⇒ STALE) → công bố | Identity được kiểm tra trước khi bất kỳ dữ liệu nào được lưu |
| I-02 | Đọc `TERMINAL_CONNECTED` trước tiên, rồi `TimeLocal()` (thời điểm thử), sau đó mới áp quy tắc kết nối | `collection_time` có cả khi thất bại vì mất kết nối; luôn biết trạng thái kết nối |
| I-03 | Mỗi nhóm (identity / tài chính / cấu hình) đọc vào biến tạm, chỉ gán vào snapshot khi cả nhóm thành công | Không bao giờ có dữ liệu một phần |
| I-04 | Dòng log lỗi không chứa giá trị biến thiên; khóa chống lặp = (trạng thái, lý do) | Không spam, vẫn log khi lý do đổi |
| I-05 | Mức log: mất kết nối / STALE = WARNING; dữ liệu INVALID, lỗi API, thiếu server time, đổi identity, lỗi khởi tạo = ERROR | Q-03: khi tắt logging chỉ lỗi thật sự nghiêm trọng còn được in |
| I-06 | Debug: 1 dòng chi tiết cho mỗi chu kỳ **thành công**; chu kỳ lỗi không lặp dòng debug | Vẫn kiểm được nhịp timer (F015) mà không vi phạm quy tắc không lặp lỗi |
| I-07 | Lần kết nối đầu sau khi khởi động lúc mất kết nối được ghi là "connected (it was not connected when the EA started)", cùng event code `TERMINAL_RECONNECTED` | Rõ nghĩa cho người đọc log |
| I-08 | Sau khi chốt đổi identity: không đọc tài khoản, không theo dõi kết nối; bản lịch sử của tài khoản gốc chỉ trả ra dưới dạng `STALE` | D-12, không trộn tài khoản |
| I-09 | Không có `OnTick`: EA chỉ chạy theo timer | Đặc tả chỉ định OnInit/OnTimer/OnDeinit; giảm bề mặt sự kiện |

## 5. Rủi ro compile cần kiểm tra khi build bằng MetaEditor

Bản build C++ trên host (0 lỗi, 0 cảnh báo với `-Wall -Wextra`) bắt được lỗi cú pháp/kiểu, nhưng **không** thay thế compiler MQL5. Các điểm đặc thù MQL5 cần để ý:

1. `virtual ~CAccountDataSource()` — tài liệu MQL5 nói destructor luôn là virtual dù có khai báo `virtual` hay không.
2. Hàm thuần ảo `=0` trong `CAccountDataSource` (lớp trừu tượng) — có từ các build MT5 hiện hành.
3. Gán `GetPointer(m_terminal_source)` (con trỏ lớp dẫn xuất) cho con trỏ lớp cơ sở `CAccountDataSource*`.
4. EA không có `OnTick()` (chỉ timer).
5. `#include` tương đối với `/` và `..` — đúng ví dụ chính thức của MetaEditor.
6. Test harness gọi `ExpertRemove()` trong `OnInit` (không ảnh hưởng EA chính).

Nếu MetaEditor báo bất kỳ error/warning nào, gửi lại toàn bộ tab **Errors**; mình sẽ sửa và chỉ đổi trạng thái thành `Compiled` khi có bằng chứng 0 error.

## 6. Giới hạn đã biết

| ID | Giới hạn |
|---|---|
| L-01 | MT5 không có API đọc nguyên khối thông tin tài khoản: các trường được đọc liên tiếp trong cùng chu kỳ, có thể lệch rất nhỏ giữa nhau. |
| L-02 | `TimeTradeServer()` là giờ server do terminal tính; tài liệu không mô tả trường hợp lỗi — EA coi `0` hoặc có lỗi là không khả dụng. |
| L-03 | **Exness Unlimited leverage:** chưa biết `ACCOUNT_LEVERAGE` trả gì. Nếu ≤ 0, snapshot sẽ `INVALID` theo đặc tả → cần quyết định đặc tả mới. Kiểm tra ở bước L-08 của hướng dẫn. |
| L-04 | Khi bạn đổi tài khoản, MT5 thường unload/load lại EA (`REASON_ACCOUNT`) — đó là một lần restart: log `EA_SHUTDOWN reason=ACCOUNT` rồi `EA_INITIALIZED` với identity mới. Cơ chế `ACCOUNT_IDENTITY_CHANGED` bên trong EA là lớp bảo vệ bổ sung, đã kiểm bằng mô phỏng. |
| L-05 | `TERMINAL_CONNECTED` chỉ cho biết có kết nối tới trade server; độ "tươi" của dữ liệu ngay sau khi kết nối lại phụ thuộc terminal. |
| L-06 | Debug logging với chu kỳ 1 s sinh khoảng 86.400 dòng/ngày — chỉ bật khi kiểm tra. |
| L-07 | Không lưu trạng thái ra file (đặc tả cấm ghi file): restart EA thì mất snapshot cũ — đúng thiết kế. |
| L-08 | `InpRequireConnectedTerminal=false`: dữ liệu khi mất kết nối được gắn `STALE`, không bao giờ `VALID` (D-08). |

## 7. Out of Scope / Future Considerations (không có trong source M1)

- Theo dõi position/order/deal; Risk per Trade, Open Risk, drawdown, Risk Score (M2+).
- Dashboard / chart objects, cảnh báo Telegram.
- Bảo vệ tài khoản tự động, mọi thao tác giao dịch.
- Lưu lịch sử snapshot ra file, hoặc cho phép tự chuyển ngữ cảnh tài khoản (cần thiết kế + phê duyệt riêng).

## 8. Acceptance gate (master prompt §10)

| # | Điều kiện | Trạng thái |
|---|---|---|
| 1 | Source compile không lỗi | **NOT VERIFIED** (chưa có MetaEditor) |
| 2 | Không còn compiler warning | **NOT VERIFIED** |
| 3 | Mọi test áp dụng được đều pass | Host-simulated: PASS; MT5: **NOT RUN** |
| 4 | Giá trị khớp dữ liệu MT5 | **NOT RUN** (bước L-03…L-08 của hướng dẫn) |
| 5 | Dữ liệu sai không bị báo VALID | Host-simulated PASS (F020, F021, T08, mutation M01/M02/M16/M17) |
| 6 | Disconnect/reconnect đúng | Host-simulated PASS (F017, F018, E06); MT5 **NOT RUN** |
| 7 | Phát hiện đổi identity | Host-simulated PASS (F019, E12) |
| 8 | Timer lifecycle đúng | Host-simulated PASS (E01–E05); nhịp timer thực **NOT RUN** |
| 9 | Không có thao tác giao dịch | **PASS** — audit tự động + self-test 17/17 + build host thiếu toàn bộ API giao dịch |
| 10 | Modular, đúng data contract | Static-reviewed — PASS |
