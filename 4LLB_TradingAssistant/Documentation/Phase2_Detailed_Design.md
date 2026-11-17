# Phase 2 — Detailed Technical Design

**Trạng thái:** `Designed` → được hiện thực trong `MQL5/Include/4LLB/*.mqh` (Phase 3). Khi code và tài liệu khác nhau, mục §11 ghi lại.

## 1. Hằng số SRS (không phải input — baseline không được đổi)

| Hằng số | Giá trị | Nguồn |
|---|---|---|
| `LLB_PIVOT_LEFT / RIGHT` | 3 / 3 | Pivot 3-3 |
| `LLB_ATR_PERIOD` | 14 | ATR14 |
| `LLB_SWEEP_MIN_ATR / MAX_ATR` | 0.05 / 0.50 | Sweep depth |
| `LLB_BREAKOUT_ATR` | 0.10 | Breakout close |
| `LLB_RETEST_ATR` | 0.15 | Retest range |
| `LLB_RETEST_MAX_BARS` | 4 | Retest window |
| `LLB_SL_BUFFER_TICKS / ATR` | 2 / 0.05 | Buffer |
| `LLB_RR` | 2.0 | TP RR 1:2 |
| `LLB_SWEEP_EXPIRY_SEC / BREAKOUT` | 900 / 1800 | 15 / 30 phút |

## 2. Cấu trúc dữ liệu (`LLB_Defines.mqh`)

| Struct | Trường chính |
|---|---|
| `LLBSymbolSpec` | name, digits, point, tickSize, tickValue, volMin/Max/Step/Limit, contract, stopsLevel, freezeLevel, expirationMode, fillingMode, orderMode, tradeMode, execMode |
| `LLBSwingPoint` | price, time, shift, valid |
| `LLBLevels` | pdh (P1), pdl (P2), p3, p4, p3Time, p4Time, d1Time, valid, why |
| `LLBSignalCandidate` | symbol, strategy, direction, level, levelPrice, signalBarTime, atr, entry, refSwingPrice, refSwingTime, reason |
| `LLBTradeProposal` | signalId, symbol, strategy, direction, level, levelPrice, entry, sl, tp, rr, atr, bid, ask, spreadPoints, digits, createdTime, expiresTime, signalBarTime, refSwingPrice, refSwingTime, monitorFromMsc, state, stateReason, decision, decisionUser, decisionTime, tgMessageId, execId, reason |
| `LLBExecutionRecord` | execId, signalId, symbol, direction, orderType, state, orderState, volume, entry, sl, tp, expiration, typeTime, filling, submitMsc, retcode, retComment, orderTicket, dealTicket, positionId, fillPrice, fillVolume, refSwingPrice, monitorFromMsc, structState, note |
| `LLBManagedPosition` | positionId, execId, signalId, symbol, direction, volume, openPrice, sl, tp, expectedSl, expectedTp, openTime, state, structState, ownership, sltpVerified, refSwingPrice, monitorFromMsc, closeTime, closePrice, profit, commission, swap, fee, closeReason, closeNote |
| `LLBTelegramCallback` | updateId, queryId, fromId, chatId, messageId, data |

## 3. Máy trạng thái

### 3.1 Proposal (trạng thái SRS)

| Từ \ Đến | ACCEPTED | REJECTED | EXPIRED | INVALIDATED | EXECUTING | EXECUTED | EXECUTION_FAILED |
|---|---|---|---|---|---|---|---|
| **ACTIVE** | ACCEPT hợp lệ | REJECT hợp lệ | `now ≥ expires` | touch | – | – | – |
| **ACCEPTED** | – | – | – | – | Execution ghi SUBMITTING | reconcile (orphan) | precheck lần 2 lỗi / restart trước khi gửi |
| **EXECUTING** | – | – | – | – | – | broker xác nhận PLACED / reconcile thấy lệnh | reject rõ ràng / reconcile không thấy |
| **EXECUTION_FAILED** | – | – | – | – | – | reconcile muộn thấy lệnh (sửa trạng thái theo thực tế) | – |

`REJECTED`, `EXPIRED`, `INVALIDATED`, `EXECUTED` là terminal. Không có trạng thái `APPROVED` riêng: `ACCEPTED` = đã duyệt và qua kiểm tra; `SUBMITTING` nằm ở ExecutionRecord. Mọi chuyển trạng thái đi qua `CLLBProposalManager::Transition` (kiểm bảng trên, ghi journal ngay). Hàm thuần `LLB_CanTransition()` có unit test (U-SM-*).

ACCEPT không đổi `expiresTime` (R-PRP-04): ExecutionManager dùng đúng `expiresTime` làm expiration của lệnh chờ.

### 3.2 ExecutionRecord (kỹ thuật)

`PRECHECK_FAILED` (không gửi) · `SUBMITTING` (đã ghi journal, sắp/đang gửi) → `PLACED` (ticket) | `REJECTED` (retcode rõ ràng) | `UNKNOWN` (không rõ) → `PLACED` | `NOT_FOUND` (sau reconciliation).

### 3.3 Order (sau khi PLACED)

`PENDING` → `PARTIAL` → `FILLED` | `EXPIRED` | `CANCELLED_EA` (EA xoá: invalidation / SL-TP sai / hết hạn do EA quản lý) | `CANCELLED_EXT` (bị xoá từ ngoài) | `REJECTED`.

### 3.4 Position

`OPEN` → `CLOSING` (EA đã gửi lệnh đóng, chờ xác nhận) → `CLOSED`. Thuộc tính song song: `structState` (INTACT/INVALIDATED), `ownership` (OK/CONFLICT), `sltpVerified`. Close reason: `SL`, `TP`, `INVALIDATION`, `MANUAL`, `STOP_OUT`, `EA_OTHER`, `SLTP_UNSETTABLE`, `OTHER` (theo `DEAL_REASON` của deal đóng; deal đóng do EA → lý do EA đã ghi).

## 4. Thời gian và chỉ số nến

- Mọi mốc thời gian là **server time** (`TimeTradeServer()`, `MqlRates.time`, `MqlTick.time_msc`).
- Mảng nến dùng `ArraySetAsSeries(true)`: index 0 = nến đang chạy (**không bao giờ dùng cho tín hiệu**), index 1 = nến vừa đóng.
- Đánh giá "as-of" nến `t`: chỉ dùng nến có index ≥ `t`.
- Pivot tại `i` được xác nhận as-of `t` khi `i − 3 ≥ t` (3 nến phải `i−1..i−3` đều đã đóng) và `i + 3 < n`. Điều kiện pivot high: `High[i] > High[i±k]`, k=1..3 (chặt, A-19).
- PDH/PDL as-of `t`: `d = iBarShift(sym, D1, Time[t])`, dùng nến D1 `d+1` (nến đã đóng gần nhất trước ngày của `t`).
- ATR as-of `t`: khung M15 → buffer ATR tại index `t`; khung khác → `iBarShift(sym, tf, Time[t]) + 1` (nến khung đó đã đóng).
- Nến mới: `iTime(sym, M15, 0)` thay đổi → đánh giá index 1. Lúc khởi động chỉ đánh giá index 1 nếu nó đóng ≤ `InpMaxStartupBarAgeSec` (60 s) trước và chưa được đánh giá (A-22). Dữ liệu chưa đủ → **không** đánh dấu đã đánh giá, thử lại.

## 5. Thuật toán chiến lược (nến `t` vừa đóng)

**Levels:** `P3` = pivot low as-of `t` có `Low < PDL`, chọn theo `InpLevelNearestMode` (giá: Low lớn nhất; thời gian: mới nhất); `P4` tương tự với `High > PDH` (giá: High nhỏ nhất). Tìm trong `[t+3, t+3+InpSwingLookbackBars)`. Hợp lệ khi `P3 < PDL < PDH < P4`.

**Sweep SELL** (thử P4 rồi P1 — A-20): `High[t] > L`, `Close[t] < L`, `Close[t] < Open[t]`, `0.05·ATR ≤ High[t] − L ≤ 0.50·ATR`. Entry = `Low[t] − tick`. Swing ref = `High[t]` (D-01) hoặc pivot high đã xác nhận ≥ `High[t]`.
**Sweep BUY** (P3 rồi P2): đối xứng, Entry = `High[t] + tick`, swing ref = `Low[t]` hoặc pivot low ≤ `Low[t]`.

**Breakout BUY tại P4** — với `b ∈ [t+1, t+4]` (nến breakout, ưu tiên `b` gần nhất):
1. `Lv_b` = levels as-of `b` hợp lệ; `X_b = P4_b + 0.10·ATR_b`; `Close[b] > X_b` và `Close[b+1] ≤ P4_b + 0.10·ATR_{b+1}` (nến breakout đầu tiên — A-03a).
2. Không có nến `j ∈ (t, b)` nào đã thoả điều kiện retest+xác nhận (setup đã dùng).
3. Nến `t`: `|Low[t] − P4_b| ≤ 0.15·ATR_t` và `Close[t] > Open[t]`.
4. Entry = `High[t] + tick`; swing ref = `min(Low[t..b−1])` (D-01) hoặc pivot low đã xác nhận ≤ giá đó.
**Breakout SELL tại P3**: đối xứng (`Close[b] < P3_b − 0.10·ATR_b`, `|High[t] − P3_b| ≤ 0.15·ATR_t`, nến giảm, Entry = `Low[t] − tick`, swing ref = `max(High[t..b−1])`).

**Stop loss** (`LLB_ComputeStops`): `buffer = max(2·tick, 0.05·ATR)`; BUY `SL = floor_tick(ref − buffer)`, SELL `SL = ceil_tick(ref + buffer)`; `risk = |Entry − SL|`; `TP = Entry ± 2·risk` (làm tròn tick gần nhất); hợp lệ khi BUY `SL < ref < Entry < TP`, SELL `TP < Entry < ref < SL`, `risk ≥ tick`. Sai → loại (A-05).

## 6. Chuẩn hoá giá & khối lượng

- `LLB_RoundToTick(p, tick, mode)`: `DOWN = floor(p/tick + 1e-7)·tick`, `UP = ceil(p/tick − 1e-7)·tick`, `NEAREST = round(p/tick)·tick`, sau đó `NormalizeDouble(…, digits)`. Dùng `SYMBOL_TRADE_TICK_SIZE`, không chỉ `_Digits`.
- Volume FIXED: `InpLotSize` phải là bội số của `volStep`, trong `[volMin, volMax]` → nếu không: **từ chối** (không làm tròn).
- Volume RISK_PERCENT: `risk$ = base × % / 100`; `lossPerLot = |OrderCalcProfit(type, sym, 1.0, Entry, SL)|`; `lots = floor(risk$/lossPerLot / step)·step`; `> volMax` → `volMax`; `< volMin` → **từ chối**.
- `SYMBOL_VOLUME_LIMIT` (nếu > 0): tổng volume lệnh + vị thế cùng symbol sau lệnh mới không vượt giới hạn.

## 7. ACCEPT → Execution (chi tiết)

**ApprovalManager** (theo thứ tự; dừng ở lỗi đầu tiên):

1. Parse `ACCEPT|ID` / `REJECT|ID` (A-31: ≤ 64 byte).
2. `message.chat.id == InpTgChatId` **và** `from.id ∈ allowlist` (mặc định allowlist = chat id). Sai → "Unauthorized", không đổi state, log `UNAUTHORIZED_CALLBACK`.
3. Signal ID tồn tại; nếu Proposal có `tgMessageId` thì phải khớp `message.message_id`.
4. REJECT: `ACTIVE` → `REJECTED` (ghi decision, user, time); state khác → trả lời "already <STATE>", không đổi gì.
5. ACCEPT: state ≠ `ACTIVE` → "already <STATE>" (idempotent). Startup recovery chưa xong → từ chối "syncing".
6. `now ≥ expiresTime` → `EXPIRED`.
7. Quét touch tươi tới hiện tại → touch → `INVALIDATED`.
8. `ExecutionManager.Precheck` (không gửi gì): terminal kết nối & cho phép trade, account cho phép EA, symbol trade mode cho phép hướng lệnh, phiên đang mở, `SYMBOL_ORDER_STOP/SL/TP` cho phép, expiration SPECIFIED được hỗ trợ (A-07), giá lệnh chờ còn hợp lệ (A-08), khoảng cách SL/TP ≥ StopsLevel, volume (§6), margin (`OrderCalcMargin` ≤ free margin), `ACCOUNT_LIMIT_ORDERS`, netting (A-12), Daily Loss Limit (A-10), chưa có ExecutionRecord/lệnh broker nào mang Execution ID này. Lỗi → trả lời lý do, Proposal **giữ ACTIVE** (người dùng có thể thử lại trước khi hết hạn).
9. Tất cả đạt → `ACTIVE → ACCEPTED` → `ExecutionManager.Execute`.

**ExecutionManager.Execute:**

1. Kiểm `state == ACCEPTED`, `decision == ACCEPT`, chưa hết hạn, Precheck lần 2 (giá có thể đã đổi). Lỗi → `EXECUTION_FAILED`.
2. Request: `TRADE_ACTION_PENDING`, `ORDER_TYPE_BUY_STOP`/`SELL_STOP`, `price=Entry`, `sl`, `tp`, `type_time=ORDER_TIME_SPECIFIED`, `expiration=expiresTime`, `magic`, `comment="4LLB|<ExecID>"`. `type_filling`: thử `ORDER_FILLING_RETURN` trước (tài liệu MQL5: lệnh chờ dùng RETURN), nếu `OrderCheck` báo `INVALID_FILL` thì thử FOK/IOC theo cờ `SYMBOL_FILLING_MODE` — chỉ `OrderCheck`, không gửi gì khi chọn.
3. `OrderCheck` lỗi (lý do khác filling) → `EXECUTION_FAILED` (`ORDERCHECK rc=<rc>`).
4. Ghi ExecutionRecord `SUBMITTING` vào journal (ghi thất bại → huỷ, `EXECUTION_FAILED`, **không gửi**). Proposal → `EXECUTING`.
5. `OrderSend`. Phân loại: `PLACED/DONE` + ticket → `PLACED`, Proposal `EXECUTED`, đọc lại lệnh để xác minh giá/SL/TP/expiration (sai → xoá lệnh, A-32). Reject rõ ràng (10004, 10006, 10007, 10013–10030, 10032–10046) → `REJECTED`, Proposal `EXECUTION_FAILED`, thông báo kèm retcode. Còn lại (10011 ERROR, 10012 TIMEOUT, 10031 CONNECTION, `OrderSend` false không retcode…) → `UNKNOWN`, **không gửi lại**.

**Execution ID** = `E` + `YYMMDD` + số thứ tự 4 chữ số của Signal ID (1-1 với Signal ID). Ví dụ Signal `4LLB-XAUUSD-SWEEP-BUY-20261117-0001` → `E2611170001`, comment `4LLB|E2611170001` (16 ký tự).

## 8. Reconciliation & restart

**Mỗi 2 s (và sau OnTradeTransaction), khi terminal đã kết nối:**

1. `SUBMITTING`/`UNKNOWN`: tìm lệnh mở → lịch sử lệnh (`HistorySelect(submit − 300 s, now)`) → vị thế/deal theo comment `4LLB|<ExecID>` + magic; dự phòng khớp tham số (symbol, loại, giá, SL, TP, volume). Thấy → `PLACED` (+ trạng thái lệnh). Không thấy khi đã kết nối ổn định ≥ 120 s kể từ lúc gửi (hoặc ngay khi đang recovery sau restart cho `SUBMITTING`) → `NOT_FOUND`, Proposal `EXECUTION_FAILED`.
2. `PLACED` + lệnh `PENDING`: còn trong `OrdersTotal` → giữ; không còn → `HistoryOrderSelect(ticket)` → `ORDER_STATE_FILLED/PARTIAL/EXPIRED/CANCELED/REJECTED`. Có deal → `DEAL_POSITION_ID` → PositionManager.Track.
3. Vị thế `OPEN/CLOSING`: tìm theo `POSITION_IDENTIFIER`; cập nhật volume/SL/TP/P&L; netting: volume ≠ volume EA đã khớp → `CONFLICT`. Không còn → `HistorySelectByPosition` → tổng hợp deal OUT (giá, profit, commission, swap, fee, `DEAL_REASON`) → `CLOSED`.
4. **Orphan scan:** mọi lệnh/vị thế có magic EA và comment `4LLB|E…` chưa liên kết → tạo bản ghi, liên kết Proposal theo Execution ID, cảnh báo `ORPHAN_ADOPTED`.

**Startup recovery (một lần, sau khi kết nối ổn định ≥ 3 s):**

1. `ACCEPTED` không có ExecutionRecord → `EXECUTION_FAILED` (`RESTART_BEFORE_SUBMIT`). (Orphan scan ở bước 4 sẽ sửa nếu thật ra lệnh đã tồn tại.)
2. `ACTIVE`: hết hạn → `EXPIRED`; quét tick từ `max(monitorFromMsc, lastScanMsc)` tới hiện tại → touch → `INVALIDATED`; `CopyTicksRange` lỗi → `INVALIDATED` (`DOWNTIME_UNVERIFIABLE`).
3. `SUBMITTING`/`UNKNOWN` → bước 1 ở trên (không thấy → `EXECUTION_FAILED`).
4. Reconcile lệnh, vị thế, orphan; quét touch downtime cho lệnh chờ/vị thế (touch → xoá/đóng).
5. Số thứ tự Signal = max(state file, journal, comment broker trong ngày) + 1.
6. Gửi Telegram tóm tắt khởi động; cho phép tạo Proposal mới và xử lý ACCEPT.

**Không bao giờ gửi lại** lệnh của một Execution ID đã có bản ghi hoặc đã có lệnh/deal trên broker.

## 9. Persistence

Thư mục: `MQL5/Files/4LLB/<login>_<magic>/` (A-34). Tester: `MQL5/Files/4LLB/tester_<magic>/`, xoá sạch khi khởi động tester.

| File | Định dạng | Ghi |
|---|---|---|
| `signals.csv` | Journal: mỗi lần đổi trạng thái thêm 1 dòng snapshot đầy đủ; dòng cuối cùng của một Signal ID là trạng thái hiện tại | Ngay lập tức + `FileFlush` |
| `executions.csv` | Journal snapshot ExecutionRecord | Ngay lập tức (SUBMITTING **trước** `OrderSend`) |
| `positions.csv` | Journal snapshot ManagedPosition | Ngay lập tức |
| `system_state.dat` | `key=value` + dòng `crc32=` ; ghi `tmp` → đọc lại kiểm CRC → backup `.bak` → `FileMove(FILE_REWRITE)` | Khi dirty, ≤ 1 lần/giây |

Dòng CSV: các trường phân tách `;` (ký tự `;`, CR, LF trong nội dung bị thay bằng khoảng trắng), trường cuối `crc=<CRC32 hex của phần trước>`. Dòng header bắt đầu `#`. Dòng sai CRC/thiếu trường → bỏ qua, đếm và cảnh báo. File > 5 MB → đổi tên thành `*_archive_<YYYYMMDDhhmmss>.csv` và ghi lại snapshot mới nhất (giữ lịch sử).

Cột `signals.csv`: `rec_time;signal_id;symbol;strategy;direction;level;level_price;entry;sl;tp;rr;atr;bid;ask;spread_pts;digits;created;expires;signal_bar;ref_swing_price;ref_swing_time;monitor_from_msc;state;state_reason;decision;decision_user;decision_time;tg_message_id;exec_id;reason;crc`

Cột `executions.csv`: `rec_time;exec_id;signal_id;symbol;direction;order_type;exec_state;order_state;volume;entry;sl;tp;expiration;type_time;filling;submit_msc;retcode;ret_comment;order_ticket;deal_ticket;position_id;fill_price;fill_volume;ref_swing_price;monitor_from_msc;struct_state;cancel_reason;note;crc` (`cancel_reason` ≠ rỗng ⇒ chính EA yêu cầu xoá lệnh chờ)

Cột `positions.csv`: `rec_time;position_id;exec_id;signal_id;symbol;direction;volume;open_price;sl;tp;expected_sl;expected_tp;open_time;pos_state;struct_state;ownership;sltp_verified;ref_swing_price;monitor_from_msc;close_time;close_price;profit;commission;swap;fee;close_reason;close_note;crc`

Khoá `system_state.dat`: `schema, version, login, server, magic, saved, tg_offset, seq_date, seq_value, sym_count, sym<i>_name, sym<i>_last_eval_bar, sym<i>_last_scan_msc`.

## 10. Telegram protocol

- Base URL `https://api.telegram.org/bot<TOKEN>/<method>` (token **không bao giờ** được log; Logger che mọi chuỗi đã đăng ký là secret).
- `POST` JSON, header `Content-Type: application/json`, body UTF-8 (`StringToCharArray(CP_UTF8)`, bỏ byte 0 cuối).
- `getMe` (kiểm token lúc khởi động) · `sendMessage` (Proposal + inline keyboard; thông báo) · `editMessageText` (cập nhật trạng thái Proposal, `reply_markup={"inline_keyboard":[]}` để gỡ nút) · `answerCallbackQuery` (text ≤ 200 ký tự) · `getUpdates` (`offset`, `timeout=0`, `limit=20`, `allowed_updates=["callback_query"]`).
- Inline keyboard: `[{"text":"ACCEPT","callback_data":"ACCEPT|<ID>"},{"text":"REJECT","callback_data":"REJECT|<ID>"}]`.
- Offset = `max(update_id)+1`, lưu vào `system_state.dat` sau khi xử lý xong lô callback. Update trùng lặp sau restart vô hại vì xử lý idempotent.
- Lỗi: −1 → backoff 2→60 s; 401 → `AUTH_ERROR`; 409 → `CONFLICT`; 429 → chờ `parameters.retry_after`; 4xx khác → bỏ tin sau 3 lần.
- Hàng đợi: answer callback ưu tiên cao nhất; tin Proposal bị huỷ khỏi hàng đợi nếu Proposal đã terminal trước khi gửi được.
- Chuỗi trong mã nguồn là ASCII (tránh lỗi encoding của MetaEditor); emoji tạo bằng code point (`ShortToString`).

## 10b. SL/TP sau khi khớp (R-EXE-10, bất biến #9)

- "Đã bảo vệ" = SL có mặt và **không rộng hơn** SL đã duyệt (BUY: `SL ≥ SL duyệt`, SELL: `SL ≤ SL duyệt`) **và** TP có mặt.
- SL thiếu hoặc rộng hơn mức duyệt → đặt SL duyệt (tức là siết lại). SL chặt hơn (ví dụ người dùng tự kéo) → **giữ nguyên**. TP thiếu → đặt TP duyệt; TP khác → giữ nguyên.
- Không đặt được SL vì giá đã vượt SL duyệt → đóng vị thế (`SLTP_UNSETTABLE`), vì không thể để vị thế không có SL.

## 11. Khác biệt giữa thiết kế và code

Ghi tại `Phase3_Implementation_Report.md` §4.
