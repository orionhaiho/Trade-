# Phase 3 — Implementation Report

**Trạng thái:** `Implemented` + `Static-reviewed`. **CHƯA `Compiled`** — môi trường này không có MetaEditor/MT5. Người dùng compile trên MT5 Exness (Phase 4 §1) và gửi lại tab *Errors* nếu có.

## 1. Cây thư mục

```text
4LLB_TradingAssistant/
├─ MQL5/                                   ← copy nguyên thư mục này vào Data Folder của MT5
│  ├─ Experts/4LLB/4LLB_TradingAssistant.mq5   EA chính: inputs + event handlers (~120 dòng)
│  ├─ Include/4LLB/
│  │  ├─ LLB_Defines.mqh        hằng số SRS, enum, struct dữ liệu
│  │  ├─ LLB_Utils.mqh          hàm thuần: chuẩn hoá tick/volume, Signal/Exec ID, CRC32, state machine, retcode, touch
│  │  ├─ LLB_Logger.mqh         log Journal + file ngày, che token
│  │  ├─ LLB_Json.mqh           JSON reader (id 64-bit an toàn) + escape
│  │  ├─ LLB_MarketData.mqh     spec symbol, M15/D1 đã đóng, ATR, tick, phiên
│  │  ├─ LLB_Levels.mqh         Pivot 3-3, P1–P4 as-of (hàm thuần)
│  │  ├─ LLB_Strategy.mqh       Sweep + Breakout (hàm thuần)
│  │  ├─ LLB_StopLoss.mqh       buffer, SL, TP RR 1:2, hình học (hàm thuần)
│  │  ├─ LLB_Persistence.mqh    journal CSV + CRC, state file nguyên tử
│  │  ├─ LLB_Proposals.mqh      ProposalManager
│  │  ├─ LLB_Risk.mqh           LotSize / RiskPercent / Daily Loss Limit
│  │  ├─ LLB_Execution.mqh      ExecutionManager (DUY NHẤT có OrderSend/OrderCheck)
│  │  ├─ LLB_Positions.mqh      PositionManager
│  │  ├─ LLB_Telegram.mqh       TelegramGateway (DUY NHẤT có WebRequest)
│  │  ├─ LLB_Approval.mqh       ApprovalManager
│  │  ├─ LLB_Lock.mqh           khoá instance (Common folder, heartbeat)
│  │  ├─ LLB_Messages.mqh       định dạng tin nhắn
│  │  ├─ LLB_Dashboard.mqh      dashboard chỉ hiển thị
│  │  └─ LLB_Coordinator.mqh    điều phối
│  └─ Scripts/4LLB/4LLB_UnitTests.mq5        unit test logic thuần (chạy trên MT5)
├─ Tools/
│  ├─ mql5_static_check.py      kiểm tra tĩnh (không phải compiler)
│  └─ reference_model_test.py   mô hình tham chiếu Python của các hàm thuần
└─ Documentation/ …
```

Tổng ≈ 9.000 dòng MQL5 (định dạng MetaEditor). Mọi chuỗi trong mã nguồn là ASCII; emoji Telegram được tạo bằng `ShortToString(code point)`.

## 2. Truy vết Requirement → hàm

| Requirement | Hàm / vị trí |
|---|---|
| R-LVL-01/02 | `CLLBMarketData::PrevDayHL` (nến D1 `d+1`, kiểm tra D1 đã đồng bộ) |
| R-LVL-03/04, D-02 | `LLB_FindSwingBeyond`, `LLB_ComputeLevels` |
| R-LVL-05 | `LLB_ComputeLevels` (`ORDER_P3<PDL<PDH<P4_VIOLATED`) |
| R-LVL-06 | `LLB_IsPivotHigh/Low` + `start=asOf+3` trong `LLB_FindSwingBeyond` |
| R-SWP-01…08, A-01/02/20 | `LLB_SweepAtLevel`, `LLB_DetectSweep` |
| R-BRK-01…09, A-03/28 | `LLB_BreakoutClose`, `LLB_RetestConfirm`, `LLB_DetectBreakoutDir` |
| D-01 | `LLB_ReferenceSwing` (+ input `InpSwingRefMode`) |
| R-SLC-01…06 | `LLB_SlBuffer`, `LLB_ComputeStops`, `LLB_RoundToTick` |
| R-SWP-09, R-BRK-10, R-PRP-01…06 | `CLLBProposalManager::Create/Transition/ProcessExpiry/IsDuplicate`, `LLB_CanTransition` |
| R-INV-01…05, A-06/21/22 | `CLLBCoordinator::ScanSymbol`, `LLB_FindTouch`, `LLB_QuoteTouches` |
| R-TGM-01…04, R-SEC-01/02/05 | `CLLBTelegramGateway`, `CLLBFileLock`, `CLLBLogger::Redact` |
| R-TGM-05…08, R-SEC-03/04 | `CLLBApprovalManager::HandleCallback/ProcessDecision`, `LLB_TgAuthorized` |
| R-EXE-01…09 | `CLLBExecutionManager::Precheck/Execute/Reconcile/AdoptOrphans` |
| R-EXE-10, R-POS-01…07 | `CLLBPositionManager::Track/Reconcile/ProcessActions`, `ModifyPositionStops`, `ClosePosition` |
| R-RSK-01…05 | `CLLBRisk::ComputeVolume/DailyLossBlocked`, `LLB_CalcRiskLots` |
| R-PER-01…03 | `CLLBPersistence`, `*::Load`, `CLLBCoordinator::LoadAll/SaveState/RunStartupRecovery` |
| R-DSH-01…07 | `CLLBDashboard`, `CLLBCoordinator::UpdateDashboard` |
| R-CRD-01/02 | `CLLBCoordinator`, `CLLBFileLock` |

## 3. Kiểm tra đã chạy trong môi trường này (bằng chứng)

| Kiểm tra | Công cụ | Kết quả |
|---|---|---|
| Cân bằng `() [] {}`, include tồn tại, truy cập field/method trên struct/class đã biết, hàm `LLB_*` đã định nghĩa, số tham số khi gọi hàm/method của dự án, định danh chưa khai báo, chuỗi chỉ ASCII | `Tools/mql5_static_check.py MQL5` | **0 error** (20 file) |
| Công cụ trên thực sự bắt lỗi | Chèn có chủ đích 7 lỗi (sai tên field, sai tên method, hàm không tồn tại, sai số tham số ×3, biến chưa khai báo) | **bắt đủ** |
| `OrderSend`/`OrderCheck` chỉ trong `LLB_Execution.mqh`; `WebRequest` chỉ trong `LLB_Telegram.mqh`; không có literal giống token; URL/token không đi vào lệnh log | cùng công cụ | **đạt** |
| Mọi hàm MQL5 được gọi và mọi hằng số MQL5 được dùng | danh sách do công cụ in ra, soát tay với tài liệu `mql5.com` | hợp lệ |
| Thuật toán Pivot/Levels/Sweep/Breakout/SL/touch/volume + giá trị kỳ vọng của unit test | `Tools/reference_model_test.py` | **50/50 đạt** |

Giới hạn: công cụ tĩnh **không** kiểm tra kiểu dữ liệu, const-correctness hay cảnh báo chuyển kiểu ngầm định — chỉ MetaEditor xác nhận được.

## 4. Quyết định triển khai bổ sung / khác thiết kế

| ID | Nội dung | Lý do |
|---|---|---|
| I-01 | `executions.csv` thêm cột `cancel_reason` | Phân biệt lệnh chờ do EA xoá (invalidation/sai SL-TP/hết hạn EA quản lý) với bị xoá từ ngoài |
| I-02 | Chọn filling cho lệnh chờ bằng `OrderCheck`: RETURN → FOK → IOC | Tài liệu MQL5 yêu cầu RETURN cho lệnh chờ; nếu server không nhận, vẫn có phương án mà không gửi thử |
| I-03 | SL sau khi khớp: chỉ đặt khi thiếu hoặc rộng hơn mức duyệt; SL chặt hơn được giữ nguyên | Bất biến #9 (không nới SL) — không ghi đè SL người dùng tự siết |
| I-04 | Đồng hồ throttle `LLB_NowMs()` dùng thời gian mô phỏng trong Strategy Tester | Tránh reconcile/đóng lệnh bị trễ hàng giờ mô phỏng khi backtest |
| I-05 | Precheck bỏ kiểm tra `TERMINAL_CONNECTED` và phiên giao dịch trong tester | Tester không có kết nối thật; tester tự từ chối lệnh ngoài phiên |
| I-06 | Đánh giá nến yêu cầu `r[1].time` = nến kỳ vọng | Tránh đánh giá nhầm nến khi nến mới mở giữa `iTime` và `CopyRates` |
| I-07 | Recovery quét cả lịch sử lệnh 3 ngày để nhận lại lệnh "mồ côi" | Lệnh khớp/đóng lúc EA tắt mà journal hỏng vẫn được liên kết, Proposal không kẹt ở ACCEPTED |
| I-08 | Lời nhắn lỗi mạng Telegram luôn kèm gợi ý allowlist WebRequest | Tài liệu MQL5 không nêu mã lỗi riêng cho "URL chưa được phép" |

## 5. Rủi ro compile cần chú ý ở lần build đầu

1. Hàm thuần ảo (`virtual … =0`) trong `CLLBApprovalServices` và upcast `GetPointer(this)` — cú pháp MQL5 chuẩn nhưng lần đầu dùng trong repo này.
2. Định nghĩa method ngoài class `CLLBJson::Parse` (đặt sau class parser).
3. Mã retcode 10038–10046 dùng giá trị số (tương thích build cũ).
4. Cảnh báo chuyển kiểu ngầm định có thể xuất hiện (không ảnh hưởng logic) — gửi lại để dọn sạch.

## PHASE 2 + 3 REPORT

```text
PHASE: 2 (Detailed Design) + 3 (Implementation)
STATUS: PASS (Implemented + Static-reviewed) — chờ COMPILE trên MT5 của người dùng
1. Deliverables: Phase2_Detailed_Design.md; 19 file .mqh + EA .mq5 + script unit test; 2 công cụ kiểm tra.
2. Requirements covered: toàn bộ bảng §2 Phase 0 (truy vết §2 ở trên).
3. Technical decisions: §4 (I-01…I-08) + A-01…A-35 + D-01…D-04.
4. Tests executed: static check 0 lỗi (đã kiểm chứng bằng chèn lỗi), mô hình tham chiếu 50/50.
   Chưa compile, chưa chạy unit test MQL5, chưa backtest, chưa demo.
5. Open issues: rủi ro compile §5; A-23, A-24, A-30.
6. User decisions required: không.
7. Next: Phase 4 — compile + chạy 4LLB_UnitTests trên MT5 (entry: copy file theo Installation_Guide.md).
```
