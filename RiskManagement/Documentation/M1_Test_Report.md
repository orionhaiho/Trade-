# M1 — Báo cáo thực thi kiểm thử

**Ngày chạy:** 2026-11-19 (UTC) · **Môi trường:** Linux container, g++ 13.3.0 `-std=c++17 -Wall -Wextra` · **Không có MetaTrader 5**

## 0. Phương pháp và cách đọc kết quả

| Ký hiệu | Phương pháp | Mức bằng chứng |
|---|---|---|
| **Host-sim** | Chính file `.mqh/.mq5` được build bằng C++17 với `Tests/host/mql5_shim.h` (giả lập API MQL5 + terminal) và chạy thật. Biến đổi cơ học duy nhất: bỏ `#property`, đổi `.`→`->` cho 2 con trỏ. | Logic đã chạy và quan sát được — **không** phải MT5 |
| **MT5 harness** | `Tests/RiskManagement_M1_Tests.mq5` compile bằng MetaEditor và chạy trên MT5 | Chưa chạy |
| **MT5 manual** | Kiểm tra thủ công trên tài khoản Exness (hướng dẫn §6) | Chưa chạy |
| **Static** | Review mã / audit tự động | Đã thực hiện |

`PASS` chỉ dùng cho test đã thực sự chạy. Mọi test trên MT5 hiện là **NOT RUN**.

Bằng chứng (đều nằm trong `Tests/host/results/`):

| File | Nội dung |
|---|---|
| `host_build_info.txt` | Thời điểm, compiler, cờ build |
| `host_compile_harness.log`, `host_compile_entrypoint.log`, `host_compile_log_sample.log` | Log compile host (rỗng = 0 lỗi, 0 cảnh báo) |
| `host_harness_output.txt` | Kết quả harness: **total=48 passed=46 failed=0 not_run=2** |
| `host_entrypoint_output.txt` | Kết quả lifecycle entry point: **total=13 passed=13 failed=0** |
| `host_mutation_check.txt` | 19/19 lỗi cố ý cài vào đều bị test phát hiện |
| `host_log_sample.txt` | Bản log mô phỏng của tab Experts |
| `readonly_audit_output.md`, `readonly_audit_selftest_output.txt` | Audit read-only + tự kiểm tra |

Chạy lại: `bash Tests/host/run_host_tests.sh`, `bash Tests/host/run_mutation_check.sh`, `python3 -I Tools/readonly_audit.py .`, `python3 -I Tools/readonly_audit_selftest.py .` (từ thư mục `RiskManagement/`).

## 1. Ma trận F001–F030

| Test ID | Mô tả | Phương pháp | Kết quả | Bằng chứng/Ghi chú |
|---|---|---|---|---|
| F001 | Khởi tạo hợp lệ | Host-sim + MT5 harness + MT5 manual | Host-sim **PASS** · MT5 **NOT RUN** | harness F001 (10 checks), E01 |
| F002 | Login chính xác (> 0) | Host-sim + MT5 harness + manual | Host-sim **PASS** · MT5 **NOT RUN** | login 0 → INVALID; manual L-03 |
| F003 | Server chính xác (không rỗng) | như trên | Host-sim **PASS** · MT5 **NOT RUN** | rỗng/khoảng trắng → INVALID |
| F004 | Currency chính xác; company được rỗng | như trên | Host-sim **PASS** · MT5 **NOT RUN** | "USC" giữ nguyên |
| F005 | Balance | như trên | Host-sim **PASS** · MT5 **NOT RUN** | 1234.56789 giữ nguyên, không làm tròn |
| F006 | Equity, không suy ra từ Balance + Profit | như trên | Host-sim **PASS** · MT5 **NOT RUN** | dữ liệu giả cố ý không nhất quán; mutation M03 bị bắt |
| F007 | Profit | như trên | Host-sim **PASS** · MT5 **NOT RUN** | |
| F008 | Credit (âm/dương) | như trên | Host-sim **PASS** · MT5 **NOT RUN** | |
| F009 | Margin | như trên | Host-sim **PASS** · MT5 **NOT RUN** | |
| F010 | Free Margin, không suy ra từ Equity − Margin | như trên | Host-sim **PASS** · MT5 **NOT RUN** | mutation M04 bị bắt |
| F011 | Margin Level, không tự tính | như trên | Host-sim **PASS** · MT5 **NOT RUN** | |
| F012 | Leverage (> 0) | như trên | Host-sim **PASS** · MT5 **NOT RUN** | 0 / −1 → INVALID; rủi ro Exness Unlimited (L-03 báo cáo triển khai) |
| F013 | Margin mode (chỉ giá trị MT5 hỗ trợ) | như trên | Host-sim **PASS** · MT5 **NOT RUN** | shim dùng giá trị số khác MT5 → chứng minh code chỉ dùng tên hằng |
| F014 | Permission flags (chỉ mô tả) | như trên | Host-sim **PASS** · MT5 **NOT RUN** | |
| F015 | Refresh theo chu kỳ cấu hình | Host-sim + MT5 manual | Host-sim **PASS (một phần)** · nhịp timer thực **NOT RUN** | 1 refresh = 1 collection; E02: `EventSetTimer(7)` khi input = 7; nhịp thực: manual L-09 |
| F016 | Từ chối chu kỳ không hợp lệ | Host-sim + MT5 manual | Host-sim **PASS** · MT5 **NOT RUN** | 0 / −5 / −3 → `INIT_PARAMETERS_INCORRECT` (E03) |
| F017 | Mất kết nối | Host-sim + MT5 manual | Host-sim **PASS** · MT5 **NOT RUN** | UNAVAILABLE, log 1 lần / 5 chu kỳ, không đọc tài khoản |
| F018 | Kết nối lại | Host-sim + MT5 manual | Host-sim **PASS** · MT5 **NOT RUN** | VALID lại, `TERMINAL_RECONNECTED` 1 lần (F018, E06) |
| F019 | Đổi identity tài khoản | Host-sim + MT5 manual | Host-sim **PASS** · MT5 **NOT RUN** | login/server/currency; chốt, ngừng đọc, bản lịch sử STALE (F019, E12). Trên MT5 đổi tài khoản thường gây reload EA (`REASON_ACCOUNT`) |
| F020 | Giá trị tài chính không hợp lệ | Host-sim | Host-sim **PASS** · MT5 **NOT RUN** | Margin âm; Margin Level âm khi Margin > 0 và Equity ≥ 0 (theo Q-02) |
| F021 | NaN và ±Inf bị từ chối | Host-sim | Host-sim **PASS** · MT5 **NOT RUN** | cả 7 giá trị tài chính × 3 trường hợp (56 checks) |
| F022 | Margin = 0 | Host-sim | Host-sim **PASS** · MT5 **NOT RUN** | Margin 0 + Margin Level 0 → VALID |
| F023 | Profit âm được chấp nhận | Host-sim | Host-sim **PASS** · MT5 **NOT RUN** | Equity < Balance vẫn VALID |
| F024 | Profit dương được chấp nhận | Host-sim | Host-sim **PASS** · MT5 **NOT RUN** | |
| F025 | Khởi tạo thất bại | Host-sim + MT5 manual | Host-sim **PASS** · MT5 **NOT RUN** | thiếu Configure, cấu hình sai (F025, E03) |
| F026 | Tạo timer thất bại | Host-sim + Static | Host-sim **PASS** (E04) · MT5 **NOT RUN** | Không ép được `EventSetTimer` lỗi trong MT5 → harness MQL5 ghi NOT RUN; E04 + mutation M18/M19 chứng minh hành vi |
| F027 | Shutdown an toàn | Host-sim + MT5 manual | Host-sim **PASS** · MT5 **NOT RUN** | idempotent, kill timer đúng 1 lần (F027, E05) |
| F028 | Snapshot cũ không bị coi là hiện tại | Host-sim | Host-sim **PASS** · MT5 **NOT RUN** | `GetLatestSnapshot()=false`, bản sao `STALE`, giá trị cũ không bị ghi đè |
| F029 | Lỗi lặp lại không spam log | Host-sim | Host-sim **PASS** · MT5 **NOT RUN** | 111 chu kỳ → đúng 6 dòng log; tắt logging → chỉ 1 dòng ERROR (F029, E08) |
| F030 | Không gọi API giao dịch | Static | **PASS** | `readonly_audit.py` PASS, self-test 17/17; build host không có API giao dịch nào |

## 2. Test bổ sung T01–T18 (harness, Host-sim)

| Test ID | Mô tả | Kết quả |
|---|---|---|
| T01 | Reset snapshot ghi đúng sentinel (không dùng 0 cho số) | **PASS** |
| T02 | Thu thập lỗi không tái sử dụng dữ liệu cũ (cùng biến output) | **PASS** |
| T03 | Lỗi API ở từng nhóm → UNAVAILABLE, nêu tên property + mã lỗi | **PASS** |
| T04 | Thiếu server time → UNAVAILABLE, `server_time=0`, không dùng giờ local | **PASS** |
| T05 | `Collect()` không bao giờ gắn VALID | **PASS** |
| T06 | Validator deterministic, thứ tự lỗi cố định | **PASS** |
| T07 | Quy tắc identity | **PASS** |
| T08 | Q-02: Balance/Equity/Free Margin âm được chấp nhận; quy tắc Margin giữ nguyên | **PASS** |
| T09 | Validator không sửa / clamp / làm tròn input | **PASS** |
| T10 | `InpRequireConnectedTerminal=false` + mất kết nối → STALE, không lưu | **PASS** |
| T11 | Login 0 sau khi có identity gốc → INVALID, không chốt nhầm | **PASS** |
| T12 | Chính sách mức log + 8 event code chính xác | **PASS** |
| T13 | Định dạng dòng log | **PASS** |
| T14 | Re-init = restart: identity gốc mới, không báo đổi identity | **PASS** |
| T15 | Q-01: identity gốc chờ tới snapshot VALID đầu tiên | **PASS** |
| T16 | Debug: 1 dòng chi tiết mỗi chu kỳ thành công, chỉ khi bật | **PASS** |
| T17 | Lỗi khi kiểm tra kết nối → coi như mất kết nối | **PASS** |
| T18 | Chưa có snapshot thành công → false, snapshot rỗng UNAVAILABLE | **PASS** |

## 3. Test lifecycle entry point E01–E13 (Host-sim, chạy trên `RiskManagement.mq5`)

| Test ID | Mô tả | Kết quả |
|---|---|---|
| E01 | Thứ tự: input → core → thu thập đầu → timer → `EA_INITIALIZED` | **PASS** |
| E02 | `OnTimer` làm mới; chu kỳ cấu hình truyền vào `EventSetTimer` | **PASS** |
| E03 | Chu kỳ không hợp lệ: không khởi tạo gì, không timer, không đọc tài khoản | **PASS** |
| E04 | Timer lỗi: `INIT_FAILED`, core shutdown, không gọi `EventKillTimer` | **PASS** |
| E05 | Shutdown: kill timer đúng 1 lần, `EA_SHUTDOWN` có lý do | **PASS** |
| E06 | Q-01: khởi động khi mất kết nối → init thành công → VALID khi có kết nối | **PASS** |
| E07 | Re-init không unload: reset toàn bộ trạng thái | **PASS** |
| E08 | Q-03: tắt logging → chỉ in ERROR | **PASS** |
| E09 | Debug logging | **PASS** |
| E10 | Không yêu cầu kết nối + mất kết nối → STALE | **PASS** |
| E11 | Thiếu server time → UNAVAILABLE, log 1 lần | **PASS** |
| E12 | Đổi identity khi không reload → chốt, ngừng đọc, log 1 lần | **PASS** |
| E13 | Lỗi API (`GetLastError`) → UNAVAILABLE nêu property | **PASS** |

## 4. Mutation check (độ mạnh của test)

19 lỗi cố ý được cài lần lượt vào bản sao tạm; **cả 19 đều làm test thất bại** (`host_mutation_check.txt`).

| ID | Lỗi cài vào | Bị phát hiện bởi |
|---|---|---|
| M01 | Chấp nhận Margin âm | E08 F020 T08 |
| M02 | Chấp nhận NaN/Inf | F021 F028 F029 T06 |
| M03 | Equity = Balance + Profit | E02 E09 F006 F021 F028 F029 T16 |
| M04 | Free Margin = Equity − Margin | E09 F010 F021 |
| M05 | Bỏ reset snapshot | T02 T04 |
| M06 | Bỏ qua mất kết nối | E06 F017 T15 T17 |
| M07 | Dùng giờ local làm giờ server | E11 |
| M08 | Log lỗi lặp mỗi chu kỳ | E08 E11 E13 F017 F029 T10 |
| M09 | Không chốt đổi identity | E12 F019 |
| M10 | Bản lịch sử gắn VALID | F017 F019 F028 |
| M11 | `GetLatestSnapshot` true với dữ liệu cũ | F017 F019 F028 T10 |
| M12 | Dữ liệu lúc mất kết nối công bố VALID | E10 T10 |
| M13 | Tắt logging chặn cả ERROR | E08 F029 T12 |
| M14 | `EventKillTimer` khi chưa có timer | E03 E04 E05 |
| M15 | Chấp nhận chu kỳ không hợp lệ | E03 E08 |
| M16 | Công bố dữ liệu INVALID | E08 F002 F003 F004 F012 F013 F020 F021 F028 F029 T11 |
| M17 | Chấp nhận login 0 | F002 T06 T11 |
| M18 | Không shutdown core khi timer lỗi | E04 |
| M19 | Timer lỗi nhưng báo thành công | E04 |

## 5. Việc còn lại để đạt `M1 ACCEPTED`

1. Compile `RiskManagement.mq5` và `Tests/RiskManagement_M1_Tests.mq5` bằng MetaEditor → gửi tab **Errors** (số error/warning).
2. Chạy harness trên MT5 → gửi các dòng `[RM-TEST]` (kỳ vọng `SUMMARY total=48 passed=46 failed=0 not_run=2`).
3. Chạy checklist thủ công L-01…L-12 (`M1_Installation_Guide.md` §6) trên tài khoản Exness → gửi log tab Experts + ảnh/ghi chú giá trị Toolbox.
