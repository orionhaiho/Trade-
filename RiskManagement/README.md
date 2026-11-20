# EA Risk Management — M1: Core & Account Engine

Expert Advisor MQL5 cho MetaTrader 5 (Exness). Nó thu thập snapshot tài khoản theo timer và chỉ đọc tuyệt đối: không mở, sửa, hủy hay đóng lệnh.

**Trạng thái:** `IMPLEMENTATION READY FOR MT5 VERIFICATION`
- Đã triển khai, đã review tĩnh, đã test mô phỏng trên host.
- Chưa compile bằng MetaEditor, chưa chạy trên MT5.

| Thư mục / file | Nội dung |
|---|---|
| `RiskManagement.mq5` | Entry point (inputs, OnInit/OnTimer/OnDeinit) |
| `Include/Core/` | `CCoreEngine`, `CAccountEngine` |
| `Include/Models/` | `ENUM_DATA_STATUS`, `AccountSnapshot` |
| `Include/Validation/` | `CDataValidator` |
| `Include/Utils/` | `CLogger` |
| `Include/Notify/` | Thông báo Telegram tiếng Việt (tùy chọn, mặc định tắt) — xem `Documentation/Telegram_Setup_Guide.md` |
| `Tests/RiskManagement_M1_Tests.mq5` | Test harness MQL5 (dữ liệu giả lập) |
| `Tests/host/` | Build C++ để chạy test trên host, mutation check, kết quả |
| `Tools/` | Audit read-only + tự kiểm tra |
| `Documentation/` | Phase 0, báo cáo triển khai, báo cáo test, audit, hướng dẫn cài đặt |

Bắt đầu từ `Documentation/M1_Installation_Guide.md`.

Kiểm chứng trên Linux (từ thư mục này):

```bash
bash Tests/host/run_host_tests.sh          # harness + lifecycle tests (host-simulated)
bash Tests/host/run_mutation_check.sh      # test có bắt được lỗi cố ý không
python3 -I Tools/readonly_audit.py .       # audit read-only
python3 -I Tools/readonly_audit_selftest.py .
```
