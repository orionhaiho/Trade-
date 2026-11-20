# Phase 0 — Specification Analysis & Implementation Plan

**Dự án:** EA Risk Management — MetaTrader 5 / MQL5 — Exness — Real account
**Milestone:** M1 — Core & Account Engine (Specification v1.0)
**Quyền:** Strict read-only
**Trạng thái tài liệu:** Phân tích + thiết kế (viết trước khi code).
**Rev2 — 2026-11-20:** người dùng yêu cầu thêm thông báo Telegram tiếng Việt → thay đổi đặc tả D-27 (§3.2).
**Rev1 — 2026-11-19:** đã nhận quyết định của người dùng cho Q-01…Q-04 (§3.1); D-21 cập nhật theo API bổ sung thực tế. Trạng thái triển khai/kiểm chứng xem `M1_Implementation_Report.md`, `M1_Test_Report.md`.

---

## 0. Nguồn, môi trường và giới hạn

| Nguồn | Trạng thái |
|---|---|
| `EA RISK MANAGEMENT – M1: CORE & ACCOUNT ENGINE` v1.0 (đặc tả gốc) | **Không được đính kèm** trong phiên này → **không thể xác nhận đã đọc toàn bộ đặc tả gốc** |
| `Source/EA_Risk_Management_M1_Claude_Master_Prompt.md` (sha256 `b012e1ed…bea`) | Đã đọc toàn bộ |

**Cách xử lý (D-01):** master prompt chứa đầy đủ data contract (inputs, enum, struct, public methods), quy tắc validation, event codes, test F001–F030 và deliverables → dùng làm **nguồn đặc tả thay thế**. Điểm nào master prompt không quy định được ghi thành quyết định thiết kế `D-xx` hoặc câu hỏi `Q-xx`. Khi có file đặc tả gốc, cần một bước đối chiếu (giống `Phase1_Rev2_Addendum_Reconciliation.md` của dự án XAUUSDc).

**Môi trường:** Linux container. Không có MetaTrader 5 / MetaEditor; `download.mql5.com` bị network policy chặn (HTTP 403) → **không compile được, không chạy được trên MT5 tại đây**. Kiểm chứng làm được tại đây:

1. Static review + read-only audit tự động (script).
2. Chạy logic test trên **bản build C++ của chính mã nguồn MQL5** với một shim mô phỏng API MQL5. Kết quả loại này luôn được ghi là **host-simulated**, không bao giờ ghi là MT5-tested.

### 0.1. Hành vi MQL5 đã đối chiếu với tài liệu chính thức

| # | Hành vi | Kết luận dùng trong thiết kế | Nguồn |
|---|---|---|---|
| K-01 | `#include "..."` | Tìm theo thư mục của **file đang chứa lệnh include**; cho phép đường dẫn tương đối `../folder/file.mqh` (ví dụ chính thức dùng `/`) | [MQL5 Book – #include](https://www.mql5.com/en/book/basis/preprocessor/preprocessor_include), [MetaEditor – structure](https://www.metatrader5.com/en/metaeditor/help/structure) |
| K-02 | `#pragma once` | Không có trong tài liệu → dùng include guard `#ifndef/#define/#endif` | [Preprocessor](https://www.mql5.com/en/docs/basis/preprosessor) |
| K-03 | `AccountInfoInteger/Double/String` | Mỗi hàm chỉ có 1 dạng, trả giá trị trực tiếp; tài liệu không mô tả cơ chế lỗi riêng → dùng cơ chế chung `ResetLastError()` → gọi → `GetLastError()`, sau đó validate giá trị | [AccountInfoInteger](https://www.mql5.com/en/docs/account/accountinfointeger) |
| K-04 | `ENUM_ACCOUNT_MARGIN_MODE` | 3 giá trị `RETAIL_NETTING`, `EXCHANGE`, `RETAIL_HEDGING`; **giá trị số không được công bố** → so sánh bằng hằng có tên, không dùng số | [Account properties](https://www.mql5.com/en/docs/constants/environment_state/accountinformation) |
| K-05 | `TimeTradeServer()` | "calculated current time of the trade server"; không mô tả lỗi; ví dụ chính thức coi `0` là chưa có → coi là không khả dụng khi `GetLastError()≠0` hoặc giá trị `≤ 0` | [TimeTradeServer](https://www.mql5.com/en/docs/dateandtime/timetradeserver) |
| K-06 | `TERMINAL_CONNECTED` | Thuộc tính bool, `TerminalInfoInteger()` trả `int` → so sánh `!= 0` | [Terminal properties](https://www.mql5.com/en/docs/constants/environment_state/terminalstatus) |
| K-07 | `EventSetTimer()` | Trả `bool`, lỗi lấy bằng `GetLastError()`; mỗi chương trình 1 timer; Timer event **không được xếp hàng thêm** nếu đã có trong hàng đợi hoặc đang xử lý | [EventSetTimer](https://www.mql5.com/en/docs/eventfunctions/eventsettimer), [OnTimer](https://www.mql5.com/en/docs/event_handlers/ontimer) |
| K-08 | Đổi symbol/period | EA không bị unload; gọi `OnDeinit` rồi `OnInit`, **biến global không bị reset** → `OnInit` phải tự reset toàn bộ trạng thái | [Program Running](https://www.mql5.com/en/docs/runtime/running) |
| K-09 | Đổi tài khoản | EA bị unload rồi load lại (`REASON_ACCOUNT`) | [Program Running](https://www.mql5.com/en/docs/runtime/running), [Uninit reasons](https://www.mql5.com/en/docs/constants/namedconstants/uninit) |
| K-10 | `OnInit` trả khác 0 | Sinh `OnDeinit(REASON_INITFAILED)`; `INIT_FAILED` → EA bị gỡ khỏi chart | [OnInit](https://www.mql5.com/en/docs/event_handlers/oninit) |
| K-11 | NaN / INF | `MathSqrt(<0)` → NaN; `MathExp` tràn → INF; `MathIsValidNumber` trả `false` với NaN và ±INF | [MathSqrt](https://www.mql5.com/en/docs/math/mathsqrt), [MathIsValidNumber](https://www.mql5.com/en/docs/math/mathisvalidnumber) |
| K-12 | Gán struct chứa `string` | Tài liệu không nói rõ → dùng hàm copy từng trường, không dựa vào phép gán struct | [Structures](https://www.mql5.com/en/docs/basis/types/classes) |

---

## 1. Phạm vi M1 và bất biến an toàn

**Trong phạm vi:** entry point + lifecycle, 4 input, thu thập identity / tài chính / cấu hình / thời gian, validation, `AccountSnapshot`, refresh theo timer, core engine + account engine, logger (Experts/Journal), test harness, audit read-only, tài liệu bàn giao.

**Ngoài phạm vi (không có trong source M1):** theo dõi position/order/deal, Risk per Trade, Open Risk, drawdown, Risk Score, khuyến nghị giao dịch, dashboard/chart objects/`Comment()`/`Alert()`, Telegram, tự động bảo vệ tài khoản, mọi thao tác đặt/sửa/hủy/đóng lệnh, placeholder cho M2.

| ID | Bất biến |
|---|---|
| INV-1 | **Read-only tuyệt đối.** Không `OrderSend*`, không `CTrade`/`<Trade\...>`, không `Position*`/`Order*`/`History*`/`Deal*`. Chỉ dùng API trong whitelist (§4.7). |
| INV-2 | Không bịa, không suy diễn: mọi giá trị đọc trực tiếp từ terminal (không `Equity = Balance + Profit`, không `FreeMargin = Equity − Margin`). Không làm tròn, không clamp. |
| INV-3 | Mỗi `Collect()` reset toàn bộ snapshot về sentinel đã tài liệu hóa (không dùng `0` cho số), không tái sử dụng dữ liệu cũ. |
| INV-4 | `VALID` chỉ khi đọc đủ mọi trường + validation pass + terminal đang kết nối. |
| INV-5 | Trạng thái lần thu thập mới nhất tách biệt với snapshot thành công gần nhất; refresh thất bại không ghi đè snapshot thành công. |
| INV-6 | Đổi identity → `UNAVAILABLE`, chốt cho tới khi restart, không trộn dữ liệu hai tài khoản. |
| INV-7 | Không ghi file, không network, không chart object, không `Sleep()`/busy-wait. |

---

## 2. Requirement Traceability Matrix

Nguồn: §x = mục của master prompt. Trạng thái hiện tại của tất cả: `NOT VERIFIED` (chưa có code).

| ID | Yêu cầu | Nguồn | File / Module | Hiện thực dự kiến | Kiểm chứng |
|---|---|---|---|---|---|
| LC-01 | Validate input trước khi khởi tạo | §6 Ph7 | `RiskManagement.mq5` | `RMValidateConfig()` → `INIT_PARAMETERS_INCORRECT` | F016 |
| LC-02 | Collection lần đầu trong `OnInit()` | §6 Ph7 | `.mq5` | `g_core.Refresh()` trước khi tạo timer | F001 |
| LC-03 | `EventSetTimer` chỉ sau khi core init OK; lỗi timer → init thất bại an toàn | §6 Ph7 | `.mq5` | kiểm tra `bool`, log `EA_INITIALIZATION_FAILED`, shutdown core | F026 |
| LC-04 | `EventKillTimer` chỉ khi timer đã tạo | §6 Ph7 | `.mq5` | cờ `g_timer_created` | F027 |
| LC-05 | Không collection chồng lấn, không busy-wait/`Sleep` | §6 Ph7 | `CoreEngine` | cờ `m_refresh_in_progress`; audit | static + audit |
| LC-06 | Shutdown đúng thứ tự + log kết thúc | §6 Ph7 | `.mq5`, `CoreEngine` | timer → core (account engine) → `EA_SHUTDOWN` | F027 |
| LC-07 | Re-init không unload (K-08) không mang trạng thái cũ | K-08 | `.mq5`, `CoreEngine` | `Initialize()` reset toàn bộ | host test |
| CFG-01 | 4 input đúng tên/kiểu/mặc định | §6 Ph2 | `.mq5` | khai báo nguyên văn | static |
| CFG-02 | Refresh < 1 → `OnInit` thất bại, không âm thầm thay default | §6 Ph2 | `CoreEngine.mqh` | `RMValidateConfig()` | F016 |
| CFG-03 | Cấu hình tập trung, không hardcode chu kỳ | §6 Ph2 | `CoreEngine.mqh` | `struct RiskManagementConfig` | static/audit |
| MOD-01 | `ENUM_DATA_STATUS` nguyên văn | §6 Ph2 | `AccountModel.mqh` | | static |
| MOD-02 | `AccountSnapshot` đủ trường, đúng kiểu | §6 Ph2 | `AccountModel.mqh` | | static |
| MOD-03 | Reset toàn bộ snapshot mỗi `Collect()`; sentinel không dùng `0` | §6 Ph2 | `AccountModel.mqh`, `AccountEngine` | `AccountSnapshotReset()` (D-05) | host test |
| MOD-04 | Không tái sử dụng trường của snapshot trước khi thu thập lỗi | §6 Ph2 | `AccountEngine` | reset đầu và reset lại khi lỗi (D-07) | host test |
| ACC-01 | `Initialize/Collect/Shutdown/GetLastErrorMessage` | §6 Ph3 | `AccountEngine.mqh` | chữ ký nguyên văn | static |
| ACC-02 | Helper theo nhóm identity / financial / config / time / error | §6 Ph3 | `AccountEngine.mqh` | `CollectIdentity()`… `Fail()` | static |
| ACC-03 | Dùng API chính thức, kiểm tra lỗi đúng cách | §6 Ph3–4 | `AccountEngine.mqh` | `ResetLastError/GetLastError` quanh từng lời gọi (D-04) | static + host test |
| ACC-04 | LOGIN, SERVER, COMPANY, CURRENCY | §6 Ph3 | `AccountEngine` | | F002–F004 |
| ACC-05 | 7 giá trị tài chính đọc trực tiếp, không suy diễn | §6 Ph3 | `AccountEngine` | | F005–F011 (dữ liệu giả cố ý "không nhất quán") |
| ACC-06 | LEVERAGE, MARGIN_MODE, TRADE_ALLOWED, TRADE_EXPERT | §6 Ph3 | `AccountEngine` | | F012–F014 |
| ACC-07 | `server_time` = `TimeTradeServer()`, không có → `0` + chẩn đoán, không thay bằng local; `collection_time` = `TimeLocal()` | §6 Ph3 | `AccountEngine` | D-09 | host test |
| ACC-08 | Require connected + mất kết nối → `UNAVAILABLE` | §6 Ph3 | `AccountEngine` | | F017, F028 |
| VAL-01 | 4 public method của `CDataValidator` | §6 Ph4 | `DataValidator.mqh` | chữ ký nguyên văn | static |
| VAL-02 | Deterministic | §6 Ph4 | `DataValidator` | không gọi API thời gian/terminal | host test |
| VAL-03 | `MathIsValidNumber` cho mọi số thực | §6 Ph4 | `DataValidator` | | F021 |
| VAL-04 | Balance, Equity, Margin, Free Margin không âm — **Rev1 theo Q-02: chỉ Margin ≥ 0** | §6 Ph4 + Q-02 | `DataValidator` | **Q-02** | F020, T08 |
| VAL-05 | Credit, Profit được âm/dương | §6 Ph4 | `DataValidator` | chỉ kiểm tra hữu hạn | F023–F024 |
| VAL-06 | Margin > 0 → Margin Level ≥ 0; Margin = 0 và Level = 0 không phải lỗi | §6 Ph4 | `DataValidator` | | F022 |
| VAL-07 | Không áp `Equity ≥ Balance`, `Profit == Equity − Balance` | §6 Ph4 | `DataValidator` | | host test |
| VAL-08 | Không làm tròn/clamp; thông báo lỗi nêu rõ property | §6 Ph4 | `DataValidator` | | host test |
| VAL-09 | Login > 0; server, currency không rỗng; company được rỗng | §6 Ph3 | `DataValidator` | | host test |
| VAL-10 | Leverage > 0; margin mode thuộc giá trị MT5 hỗ trợ | §6 Ph3 | `DataValidator` | K-04 | F012–F013 |
| CORE-01 | 6 public method của `CCoreEngine` | §6 Ph5 | `CoreEngine.mqh` | chữ ký nguyên văn | static |
| CORE-02 | Khởi tạo AccountEngine + DataValidator, quản lý refresh | §6 Ph5 | `CoreEngine` | | F001 |
| CORE-03 | Refresh lỗi không ghi đè snapshot thành công | §6 Ph5 | `CoreEngine` | | F028 |
| CORE-04 | `GetCurrentStatus()` = kết quả lần thu thập mới nhất | §6 Ph5 | `CoreEngine` | | F028 |
| CORE-05 | Caller không thể nhầm snapshot cũ là hiện tại; bản lịch sử gắn STALE | §6 Ph5 | `CoreEngine` | **Q-04**, D-08 | F028 |
| ID-01 | Lưu identity gốc (login, server, currency) | §6 Ph6 | `CoreEngine` | **Q-01**, D-10 | F001 |
| ID-02 | Đổi identity → `UNAVAILABLE`, log `ACCOUNT_IDENTITY_CHANGED`, không trộn, yêu cầu restart | §6 Ph6 | `CoreEngine` | D-11…D-13 | F019 |
| CONN-01 | Log chuyển trạng thái mất/có kết nối, không lặp | §6 Ph6 | `CoreEngine` | D-15 | F017–F018, F029 |
| LOG-01 | Mức INFO / WARNING / ERROR / DEBUG | §6 Ph8 | `Logger.mqh` | | host test |
| LOG-02 | 8 event code bắt buộc | §6 Ph8 | `Logger.mqh` | enum + bảng chuỗi cố định | static/host |
| LOG-03 | Log identity khi khởi tạo, không log credential | §6 Ph8 | `.mq5`, `CoreEngine` | chỉ login/server/currency/company | host test |
| LOG-04 | Không in toàn bộ giá trị mỗi giây (trừ debug) | §6 Ph8 | `CoreEngine` | D-19 | host test |
| LOG-05 | Log theo chuyển trạng thái, không lặp lỗi | §6 Ph8 | `CoreEngine` | D-16 | F029 |
| LOG-06 | Mỗi dòng có timestamp + event code | §6 Ph8 | `Logger` | D-18 | host test |
| LOG-07 | `InpEnableLogging=false` | §6 Ph8 | `Logger` | **Q-03** | host test |
| SAFE-01 | Không trading API / `CTrade`, kể cả gián tiếp, macro, nhánh chết | §6 Ph10 | toàn bộ | audit script + whitelist | F030 |
| SAFE-02 | Không file / network / chart object | §7.3 | toàn bộ | audit script | audit |
| DEL-01…08 | `.mq5`, `.mqh`, `.ex5`*, test source, test report, compile log*, audit report, hướng dẫn | §9.3 | — | *chỉ khi thực sự compile | Phase 11 |

---

## 3. Điểm mơ hồ, rủi ro và quyết định

### 3.1. Cần bạn xác nhận (ảnh hưởng tiêu chí khởi tạo / tính đúng dữ liệu / public interface)

| ID | Vấn đề | Đề xuất | **Quyết định của người dùng (2026-11-19)** |
|---|---|---|---|
| **Q-01** | Lần thu thập đầu trong `OnInit` không `VALID` (vd. MT5 vừa mở, chưa đăng nhập/kết nối — login có thể = 0). Nếu `OnInit` thất bại, MT5 gỡ EA khỏi chart (K-10) và không tự gắn lại. | `OnInit` thành công nếu input hợp lệ + engine khởi tạo + timer tạo được; trạng thái `UNAVAILABLE/INVALID`, timer tiếp tục thử; identity gốc khóa ở snapshot `VALID` đầu tiên. | **Chấp nhận đề xuất** ("Vẫn chạy, chờ dữ liệu"). |
| **Q-02** | Đặc tả: Balance, Equity, Margin, Free Margin không âm. Thực tế MT5: Free Margin = Equity − Margin **âm hợp lệ** khi Margin Level < 100% (vùng margin call; Exness có stop-out tới 0%). Theo đặc tả, snapshot bị `INVALID` đúng lúc tài khoản rủi ro nhất. | Cho phép Free Margin âm (chỉ cần hữu hạn); Balance/Equity/Margin vẫn ≥ 0. | **"Nới cả Balance/Equity"** — thay đổi đặc tả đã được chấp thuận: chỉ **Margin ≥ 0**; Balance, Equity, Free Margin (cùng Profit, Credit) chỉ cần hữu hạn; Margin Level ≥ 0 khi Margin > 0 **và** Equity ≥ 0 (được âm khi Equity âm); Margin = 0 → Margin Level chỉ cần hữu hạn. Ảnh hưởng: VAL-04, F020, T08. |
| **Q-03** | `InpEnableLogging=false`: xử lý lỗi nghiêm trọng thế nào mà không phá input contract. | Tắt INFO/WARNING/DEBUG; vẫn in sự kiện mức ERROR, mỗi chuyển trạng thái một dòng. | **Chấp nhận đề xuất** ("Vẫn in mức ERROR"). |
| **Q-04** | Ngữ nghĩa giá trị trả về của `GetLatestSnapshot()` sau khi refresh mới nhất thất bại. | Trả `true` chỉ khi lần thu thập mới nhất `VALID`; nếu không: `false`, tham số out là snapshot thành công gần nhất gắn `STALE` + lý do (chưa từng thành công → snapshot rỗng mang trạng thái mới nhất). | **Chấp nhận đề xuất** ("false + bản cũ gắn STALE"). Làm rõ khi triển khai: chưa từng thành công → snapshot đã reset với `data_status=UNAVAILABLE` và `error_message` nêu trạng thái + lý do của lần thu thập mới nhất (trạng thái mới nhất luôn lấy được qua `GetCurrentStatus()`). |

### 3.2. Quyết định thiết kế (áp dụng nếu bạn không phản đối)

| ID | Quyết định | Lý do |
|---|---|---|
| D-01 | Master prompt là nguồn đặc tả thay thế | Đặc tả gốc không có |
| D-02 | Include tương đối dùng `/`, ví dụ `#include "../Models/AccountModel.mqh"` | K-01 |
| D-03 | Include guard `#ifndef/#define/#endif` | K-02 |
| D-04 | Mỗi lời gọi API: `ResetLastError()` → gọi → `GetLastError()`; khác 0 → `UNAVAILABLE`, thông báo nêu tên property + mã lỗi. Giá trị hợp lệ hay không do validator quyết định | K-03 |
| D-05 | Sentinel: `login=-1`, mọi `double = NaN` (tạo bằng `MathSqrt(-1)`), `leverage=-1`, `margin_mode=-1`, chuỗi `""`, bool `false`, `server_time=0` (theo đặc tả), `collection_time=0` tới khi bắt đầu thu thập, `data_status=UNAVAILABLE`, `error_message="NOT_COLLECTED"`. NaN không bao giờ qua được validator | §6 Ph2, K-11 |
| D-06 | `Collect()` chỉ đọc dữ liệu thô, không bao giờ gắn `VALID`; chỉ `CCoreEngine` (qua `CDataValidator`) quyết định `VALID/INVALID/STALE` | Validate trước khi công bố |
| D-07 | Thu thập lỗi giữa chừng → reset lại toàn bộ trường dữ liệu (không công bố dữ liệu một phần); giữ `collection_time` = thời điểm thử | Không trộn dữ liệu |
| D-08 | `DATA_STATUS_STALE` dùng cho: (a) bản lịch sử trả từ `GetLatestSnapshot()` khi lần mới nhất thất bại; (b) `InpRequireConnectedTerminal=false` + đang mất kết nối + dữ liệu hợp lệ → `STALE`, không bao giờ `VALID`, không lưu làm snapshot thành công | Đặc tả không định nghĩa STALE; dữ liệu terminal khi mất kết nối là dữ liệu cũ |
| D-09 | Server time không khả dụng → `UNAVAILABLE`, `server_time=0`, thông báo `SERVER_TIME_UNAVAILABLE`; tuyệt đối không dùng `TimeLocal()` | §6 Ph3, K-05 |
| D-10 | Identity gốc = identity của snapshot `VALID` đầu tiên (thường là lần thu thập trong `OnInit`) | phụ thuộc Q-01 |
| D-11 | Đổi identity = identity **hợp lệ** (login > 0, server/currency không rỗng) khác identity gốc (so sánh chính xác, phân biệt hoa thường). Identity không hợp lệ (login 0, chuỗi rỗng) → `INVALID`, không chốt — tránh chốt nhầm lúc reconnect | Tránh báo động giả |
| D-12 | Sau khi chốt: không đọc tài khoản nữa, mọi chu kỳ trả `UNAVAILABLE`, log đúng 1 lần (ERROR). Snapshot thành công của tài khoản gốc giữ nguyên, chỉ trả ra dưới dạng `STALE` lịch sử | §6 Ph6 |
| D-13 | MT5 tự unload/load EA khi đổi tài khoản (K-09) = restart: toàn bộ trạng thái bị bỏ; log `EA_SHUTDOWN(reason=ACCOUNT)` rồi `EA_INITIALIZED` với identity mới. Phát hiện trong EA là lớp bảo vệ bổ sung | K-09 |
| D-14 | `OnInit` reset toàn bộ trạng thái global | K-08 |
| D-15 | Đọc `TERMINAL_CONNECTED` mỗi chu kỳ; chỉ log khi chuyển trạng thái: khởi động mất kết nối hoặc connected→disconnected = `TERMINAL_DISCONNECTED` (WARNING); disconnected→connected = `TERMINAL_RECONNECTED` (INFO, kèm thời gian mất kết nối). Lỗi khi đọc → coi như mất kết nối | Fail-safe, chống spam |
| D-16 | `ACCOUNT_COLLECTION_FAILED` chỉ log khi vào trạng thái lỗi hoặc khi (status, lý do) thay đổi; `ACCOUNT_COLLECTION_SUCCESS` (INFO) khi `VALID` lần đầu và khi phục hồi (kèm số chu kỳ lỗi). Thông báo lỗi không chứa giá trị biến thiên → khóa chống lặp ổn định | Chống spam |
| D-17 | Mức log: `EA_INITIALIZED` INFO; `EA_INITIALIZATION_FAILED` ERROR; `ACCOUNT_COLLECTION_SUCCESS` INFO (chi tiết mỗi chu kỳ: DEBUG); `ACCOUNT_COLLECTION_FAILED` WARNING nếu do mất kết nối/STALE, ERROR nếu do dữ liệu INVALID / lỗi API / server time; `ACCOUNT_IDENTITY_CHANGED` ERROR; `TERMINAL_DISCONNECTED` WARNING; `TERMINAL_RECONNECTED` INFO; `EA_SHUTDOWN` INFO | Nhất quán |
| D-18 | Định dạng: `[RiskManagement][yyyy.mm.dd hh:mi:ss][LEVEL][EVENT_CODE] message` (giờ local) | §6 Ph8 |
| D-19 | Debug chỉ có hiệu lực khi `InpEnableLogging=true`; in 1 dòng mỗi chu kỳ với đầy đủ giá trị (tối đa 8 chữ số thập phân, chỉ để hiển thị). Debug mặc định tắt | §6 Ph8 |
| D-20 | Validation: chuỗi chỉ gồm khoảng trắng coi là rỗng (không sửa giá trị); margin mode so với hằng có tên; Margin = 0 thì Margin Level chỉ cần hữu hạn; liệt kê mọi lỗi, thứ tự cố định, nêu tên property | Deterministic |
| D-21 | Public API **bổ sung** (không đổi chữ ký đã đặc tả). Rev1 — danh sách thực tế: `CCoreEngine::Configure(config, logger)`, `CCoreEngine::SetDataSource(...)` (chỉ test), `CCoreEngine::GetInitializationErrorMessage()`; `CAccountEngine::Configure(require_connected)`, `CAccountEngine::SetDataSource(...)` (chỉ test), `CAccountEngine::IsTerminalConnected()`, `CAccountEngine::GetLastCollectResult()`; class `CLogger` (đặc tả không quy định tên); `struct RiskManagementConfig`, `RMValidateConfig()`; enum `ENUM_RM_LOG_LEVEL`, `ENUM_RM_LOG_EVENT`, `ENUM_RM_COLLECT_RESULT`, `ENUM_RM_CONNECTION_STATE`; lớp trừu tượng `CAccountDataSource` + `CTerminalAccountDataSource`. `CTerminalAccountDataSource` là nơi **duy nhất** gọi `AccountInfo*`, `TerminalInfoInteger`, `TimeTradeServer` (đã kiểm bằng audit) | Testability, audit dễ |
| D-22 | `struct RiskManagementConfig` + `RMValidateConfig()` trong `CoreEngine.mqh`; input chỉ đọc một lần trong `OnInit` | §6 Ph2 |
| D-23 | Cờ chống chồng lấn trong `Refresh()` (timer vốn không xếp hàng trùng — K-07; cờ chỉ để phòng vệ) | §6 Ph7 |
| D-24 | **Rủi ro Exness Unlimited leverage:** chưa biết `ACCOUNT_LEVERAGE` trả gì. Nếu ≤ 0 thì theo đặc tả sẽ `INVALID` → cần quyết định đặc tả. Phải kiểm tra trên tài khoản thật (F012) | Môi trường |
| D-25 | **Giới hạn:** MT5 không có API đọc nguyên khối thông tin tài khoản; các trường được đọc liên tiếp trong cùng một chu kỳ, có thể lệch rất nhỏ giữa các trường | Môi trường |
| D-26 | Không `Comment()`, `Alert()`, chart object, file, network, `Sleep()` | §7.3 |
| **D-27** | **Thay đổi đặc tả do người dùng yêu cầu (2026-11-20): thêm Telegram.** Mục bị ảnh hưởng: §5 ("Tuyệt đối không triển khai Telegram integration"), §7.3 ("không network request"). Phương án: module tùy chọn `Include/Notify/` (mặc định tắt), gửi một chiều qua HTTPS chỉ tới `api.telegram.org`; `WebRequest` chỉ được gọi trong `CWebRequestTransport` (audit kiểm tra); tối đa 1 request/chu kỳ, sau khi làm mới dữ liệu; token không bao giờ được log. Tác động API: thêm 5 input `InpTelegram*`, `CCoreEngine::SetEventListener()`, `RiskEvent`/`CRiskEventListener`, 2 event code `TELEGRAM_SEND_FAILED`/`TELEGRAM_SEND_RECOVERED`, thư mục `Include/Notify/` ngoài cấu trúc bắt buộc. Data contract M1 và mọi chữ ký đã đặc tả **không đổi**. Bất biến read-only **giữ nguyên** (không có API giao dịch). Trạng thái: **đã được người dùng yêu cầu** | Yêu cầu của người dùng |

---

## 4. Kiến trúc

### 4.1. Cấu trúc file và phụ thuộc

```text
RiskManagement/                         → copy nguyên thư mục vào MQL5/Experts/
├── RiskManagement.mq5                  entry point: inputs, OnInit/OnTimer/OnDeinit, sở hữu timer
├── Include/
│   ├── Core/
│   │   ├── CoreEngine.mqh              CCoreEngine, RiskManagementConfig, RMValidateConfig()
│   │   └── AccountEngine.mqh           CAccountEngine, CAccountDataSource, CTerminalAccountDataSource
│   ├── Models/
│   │   └── AccountModel.mqh            ENUM_DATA_STATUS, AccountSnapshot, sentinel, reset/copy/format
│   ├── Validation/
│   │   └── DataValidator.mqh           CDataValidator (thuần, deterministic)
│   └── Utils/
│       └── Logger.mqh                  CLogger, mức log, 8 event code
├── Tests/                              test harness MQL5 + host-simulated build
└── Documentation/
```

```text
RiskManagement.mq5 ──► CoreEngine.mqh ──► AccountEngine.mqh ──► AccountModel.mqh
        │                   ├──────────► DataValidator.mqh ──► AccountModel.mqh
        │                   └──────────► Logger.mqh
        └──────────────────────────────► Logger.mqh
```

Không module nào include thư viện chuẩn MQL5 (không `<Trade\...>`, không `<...>` nào).

### 4.2. Trách nhiệm

| Class | Trách nhiệm | Không làm |
|---|---|---|
| `CTerminalAccountDataSource` | Gọi đúng 6 nhóm API đọc (`AccountInfo*`, `TerminalInfoInteger`, `TimeTradeServer`, `TimeLocal`) với `ResetLastError/GetLastError` | Không giữ trạng thái, không validate |
| `CAccountEngine` | Reset snapshot, kiểm tra kết nối, đọc identity → tài chính → cấu hình → thời gian, báo lỗi theo property | Không gắn `VALID`, không log |
| `CDataValidator` | Kiểm tra dữ liệu thuần, trả danh sách lỗi theo property | Không gọi API, không sửa dữ liệu |
| `CCoreEngine` | Điều phối chu kỳ, validate, quyết định trạng thái, giữ snapshot thành công gần nhất, identity gốc, trạng thái kết nối, log theo chuyển trạng thái | Không quản lý timer |
| `CLogger` | Định dạng, lọc theo mức, 8 event code | Không ghi file |
| `RiskManagement.mq5` | Đọc + validate input, tạo/hủy timer, thứ tự lifecycle | Không đọc tài khoản trực tiếp |

### 4.3. Lifecycle

```text
OnInit
 ├─ reset toàn bộ global (K-08)
 ├─ logger.Configure(InpEnableLogging, InpEnableDebugLogging)
 ├─ RMValidateConfig(inputs) ── lỗi ─► EA_INITIALIZATION_FAILED → INIT_PARAMETERS_INCORRECT
 ├─ core.Configure + core.Initialize() ── lỗi ─► EA_INITIALIZATION_FAILED → core.Shutdown → INIT_FAILED
 ├─ core.Refresh()                       (collection lần đầu; kết quả xử lý theo Q-01)
 ├─ EventSetTimer(refresh) ── lỗi ─► EA_INITIALIZATION_FAILED → core.Shutdown → INIT_FAILED
 ├─ g_timer_created = true
 └─ EA_INITIALIZED (identity nếu đã có, cấu hình, trạng thái lần đầu) → INIT_SUCCEEDED
OnTimer   → core.Refresh()
OnDeinit  → EventKillTimer() nếu g_timer_created → core.Shutdown() → EA_SHUTDOWN(reason)
```

### 4.4. Một chu kỳ `Refresh()` (thứ tự cố định)

1. Đang refresh → bỏ qua (D-23). Chưa khởi tạo → `UNAVAILABLE`.
2. Đã chốt đổi identity → `UNAVAILABLE`, không đọc API (D-12).
3. `CAccountEngine::Collect()`: reset → `collection_time = TimeLocal()` → đọc `TERMINAL_CONNECTED` → (require + mất kết nối ⇒ `UNAVAILABLE`) → identity → tài chính → cấu hình → server time. Lỗi API ở bất kỳ bước nào ⇒ reset dữ liệu, `UNAVAILABLE`, nêu property.
4. Cập nhật trạng thái kết nối, log nếu chuyển trạng thái (D-15).
5. Đã có identity gốc + identity đọc được hợp lệ + khác gốc ⇒ chốt, `ACCOUNT_IDENTITY_CHANGED`, `UNAVAILABLE` (trước mọi bước lưu).
6. `CDataValidator::ValidateSnapshot()` thất bại ⇒ `INVALID`.
7. Đang mất kết nối (chỉ xảy ra khi require=false) ⇒ `STALE` (D-08).
8. Còn lại ⇒ `VALID`: khóa identity gốc nếu chưa có, copy vào snapshot thành công gần nhất.
9. Log theo chuyển trạng thái (D-16), dòng debug nếu bật (D-19).

### 4.5. Hai trạng thái độc lập

| Thành phần | Cập nhật khi | Đọc qua |
|---|---|---|
| Trạng thái mới nhất (`status`, `error`) | **Mọi** chu kỳ | `GetCurrentStatus()` |
| Snapshot thành công gần nhất | **Chỉ** khi chu kỳ `VALID` | `GetLatestSnapshot()` (Q-04), `GetLastSuccessfulCollectionTime()` |

### 4.6. Identity

Identity gốc = (login, server, currency) của snapshot `VALID` đầu tiên. Mỗi chu kỳ sau đó so sánh trước khi lưu. Khác ⇒ chốt `UNAVAILABLE` tới khi restart EA; không tự chuyển ngữ cảnh tài khoản.

### 4.7. Bảo đảm read-only

- Whitelist API terminal: `AccountInfoInteger`, `AccountInfoDouble`, `AccountInfoString`, `TerminalInfoInteger`, `TimeTradeServer`, `TimeLocal`, `EventSetTimer`, `EventKillTimer`, `Print`, `ResetLastError`, `GetLastError`, cùng các hàm thuần (`Math*`, `String*`, `*ToString`).
- Không include thư viện chuẩn; không `#import`; không DLL.
- Audit script quét toàn bộ source + include tìm: `OrderSend`, `OrderSendAsync`, `CTrade`, `Trade.mqh`, `Position*`, `Order*`, `History*`, `Deal*`, `OrderCalc*`, `OrderCheck`, `#import`, `WebRequest`, `Socket*`, `File*`, `Object*`, `Chart*`, `Comment`, `Alert`, `SendNotification`, `SendMail`, `SendFTP`, `Sleep`, `GlobalVariable*`, `#define` dùng để che tên hàm, `#ifdef` bất thường.

---

## 5. Chiến lược kiểm chứng và kế hoạch

| Tầng | Chạy ở đâu | Nhãn kết quả |
|---|---|---|
| 1. Static review + audit script | Tại đây | `Static-reviewed` |
| 2. Host-simulated: build C++ của **cùng** file `.mqh/.mq5` + shim API MQL5 (biến đổi cơ học tối thiểu: bỏ `#property`, `input`, `.`→`->` cho 2 con trỏ) | Tại đây | `Simulated-tested (host)` |
| 3. Test harness MQL5 (`Tests/RiskManagement_M1_Tests.mq5`, test double, không đọc tài khoản thật) | MT5 của bạn | `MT5-tested` khi bạn gửi log |
| 4. Kiểm tra thủ công trên tài khoản Exness (so log với Toolbox) | MT5 của bạn | `Live-account-validated` khi có bằng chứng |

Kế hoạch: Phase 2 Model/Config → Phase 3 AccountEngine → Phase 4 Validator → Phase 5 CoreEngine → Phase 6 Identity/kết nối → Phase 7 Entry point → Phase 8 Logger → Phase 9 Test → Phase 10 Audit → Phase 11 Báo cáo + hướng dẫn. Kết luận dự kiến tối đa có thể đạt tại đây: **IMPLEMENTATION READY FOR MT5 VERIFICATION** (không thể là `M1 ACCEPTED` khi chưa compile/chạy trên MT5).
