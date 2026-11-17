# Hướng dẫn cài đặt Bot Telegram cho 4LLB Trading Assistant v2.0

Bot Telegram là **cổng phê duyệt duy nhất**: EA gửi đề xuất (Proposal) kèm 2 nút **ACCEPT / REJECT**. Không có ACCEPT hợp lệ từ bạn thì EA **không bao giờ** đặt lệnh.

Thời gian: khoảng 10–15 phút. Bạn cần: điện thoại/PC có Telegram, MT5 Exness đã cài EA (xem `Installation_Guide.md`).

> **Nguyên tắc bảo mật quan trọng nhất:** Bot Token giống như mật khẩu điều khiển bot. **Không gửi token cho bất kỳ ai** (kể cả trong chat với AI), không chụp màn hình có token, không đưa token lên mạng/GitHub.

---

## Bước 1 — Tạo bot bằng @BotFather

1. Mở Telegram, ô tìm kiếm gõ **`@BotFather`**. Chọn đúng tài khoản có **dấu tick xanh** (bot chính thức của Telegram).
2. Bấm **Start** (hoặc gõ `/start`).
3. Gõ **`/newbot`**.
4. BotFather hỏi **tên hiển thị** → gõ ví dụ: `4LLB Assistant`.
5. BotFather hỏi **username** → phải kết thúc bằng `bot` và chưa ai dùng, ví dụ: `my4llb_assistant_bot`.
6. BotFather trả về một đoạn có dạng:

   ```text
   Use this token to access the HTTP API:
   <dãy số>:<chuỗi bí mật khoảng 35 ký tự>
   ```

   Đó là **Bot Token**. Sao chép nguyên văn (gồm cả phần số, dấu `:` và phần chữ phía sau). Tạm thời **chưa dán vào đâu khác** ngoài file ở Bước 4.

> Nếu bạn chạy EA trên **hai tài khoản/terminal** (ví dụ XAUUSD trên tài khoản Pro và XAUUSDc trên tài khoản Standard Cent), hãy **tạo hai bot riêng** (lặp lại Bước 1). Mỗi bot chỉ được một EA dùng (Telegram chỉ cho một nơi đọc tin của một bot).

## Bước 2 — Mở cuộc trò chuyện với bot của bạn

Bot **không thể chủ động nhắn** cho người chưa từng nhắn với nó.

1. Trong tin nhắn của BotFather, bấm vào đường link `t.me/<username_bot>` (hoặc tìm username bot vừa tạo).
2. Bấm **Start**, rồi gửi thêm một tin bất kỳ, ví dụ `hello`.

## Bước 3 — Lấy Chat ID của bạn

Chat ID là số định danh cuộc trò chuyện mà EA sẽ gửi tin đến (với chat riêng, Chat ID = User ID của bạn, là **số dương**).

**Cách A — dùng chính API Telegram (khuyến nghị, không qua bên thứ ba):**

1. Làm bước này **trước khi chạy EA** (khi EA đang chạy, nó sẽ đọc hết tin và trang dưới đây sẽ trống).
2. Trên trình duyệt **của máy bạn**, mở địa chỉ (thay `<TOKEN>` bằng token ở Bước 1):

   ```text
   https://api.telegram.org/bot<TOKEN>/getUpdates
   ```

3. Tìm đoạn `"chat":{"id":123456789,` — con số đó là **Chat ID**.
   - Nếu chỉ thấy `{"ok":true,"result":[]}`: quay lại Bước 2 gửi thêm một tin cho bot rồi tải lại trang.
4. Đóng tab, **xoá lịch sử trình duyệt** cho địa chỉ này (URL có chứa token).

**Cách B — bot tra ID của bên thứ ba:** nhắn `/start` cho `@userinfobot`, bot trả về `Id: 123456789`. Đây là bot bên thứ ba (không phải Telegram), chỉ dùng để xem ID của chính bạn.

Ghi Chat ID ra giấy/ghi chú — đây **không** phải bí mật nhưng cần chính xác.

## Bước 4 — Lưu Bot Token vào máy (không lưu trong mã nguồn)

EA đọc token từ một file riêng trong thư mục dữ liệu MT5, **không** hardcode trong code và **không** ghi ra log.

1. Mở MT5 → menu **File → Open Data Folder**.
2. Vào **`MQL5` → `Files`**. Tạo thư mục mới tên **`4LLB`** (nếu chưa có).
3. Trong `MQL5\Files\4LLB\`, tạo file văn bản tên **`telegram_token.txt`**.
   - Trong Windows Explorer bật **View → File name extensions** để tránh lỗi file bị đặt thành `telegram_token.txt.txt`.
4. Mở file bằng Notepad, dán **đúng một dòng** là token, lưu lại (ANSI hoặc UTF-8 đều được).

Kết quả: `…\MQL5\Files\4LLB\telegram_token.txt` chứa đúng một dòng dạng `<dãy số>:<chuỗi bí mật>`.

> Cách thay thế: dán token vào input `InpTgBotToken` của EA. Cách này kém an toàn hơn vì token nằm trong cấu hình chart/preset `.set` (dễ lộ khi chia sẻ preset). Nếu đã dùng file thì để `InpTgBotToken` **trống**.

## Bước 5 — Cho phép MT5 gọi Telegram (WebRequest)

1. MT5 → **Tools → Options → tab Expert Advisors**.
2. Tích **Allow algorithmic trading**.
3. Tích **Allow WebRequest for listed URL**, bấm dòng `+ add new URL`, nhập chính xác:

   ```text
   https://api.telegram.org
   ```

4. Bấm **OK**.

Thiếu bước này, EA không gửi/nhận được gì từ Telegram (dashboard báo lỗi mạng kèm nhắc allowlist).

## Bước 6 — Nhập thông tin Telegram vào EA

Khi kéo EA `4LLB_TradingAssistant` vào **một** chart, tab **Inputs**, nhóm **4. Telegram approval**:

| Input | Giá trị | Ghi chú |
|---|---|---|
| `InpTelegramEnabled` | `true` | Bắt buộc để giao dịch live |
| `InpTgBotToken` | *(để trống)* | EA đọc từ `telegram_token.txt` |
| `InpTgChatId` | Chat ID ở Bước 3 | ví dụ `123456789` |
| `InpTgAllowedUserIds` | *(để trống)* | Trống = chỉ chính Chat ID đó được bấm nút (chat riêng) |
| `InpTgPollIntervalMs` | `1500` | Tần suất hỏi Telegram (ms) |
| `InpTgHttpTimeoutMs` | `5000` | Thời gian chờ tối đa mỗi lần gọi (ms) |

Tab **Common**: tích **Allow Algo Trading**. Bấm **OK**. Nút **Algo Trading** trên thanh công cụ MT5 phải đang bật (màu xanh).

## Bước 7 — Kiểm tra kết nối

Trong vòng vài giây sau khi gắn EA:

1. **Tab Experts** (cửa sổ Toolbox) có các dòng:
   - `[4LLB][INFO][TGW] bot verified: @ten_bot_cua_ban`
   - `[4LLB][INFO][TGW] Telegram connection OK`
2. **Telegram** nhận được tin: `4LLB Trading Assistant v2.00 started on account …` kèm danh sách symbol, chế độ khối lượng, số lệnh/vị thế khôi phục.
3. **Dashboard** trên chart: dòng đầu có `TG OK @ten_bot_cua_ban`.

Nếu không thấy, xem mục **Xử lý sự cố** bên dưới.

## Bước 8 — Sử dụng hằng ngày

### Tin đề xuất

```text
⚡ 4LLB PROPOSAL - BUY XAUUSD
Signal ID: 4LLB-XAUUSD-SWEEP-BUY-20261117-0001
Symbol: XAUUSD
Strategy: SWEEP
Direction: BUY (Buy Stop pending order)
Level: P2 (PDL) = 2650.00
Entry: 2655.40
SL: 2649.03
TP: 2668.14
RR: 1:2.00
ATR(14,M15): 5.23
Bid/Ask: 2654.90 / 2655.10 | Spread: 20 pts
Reference swing: 2649.30 (low @ 2026.11.17 08:00:00)
Invalidation: Bid <= 2649.30 (touch)
Created: 2026.11.17 08:15:02 (server)
Expiration: 2026.11.17 08:30:02 (server, 15 min)
Reason: SWEEP BUY at P2=2650.00 depth=0.13ATR; …
[ ✅ ACCEPT ]  [ ❌ REJECT ]
```

*(Số liệu minh hoạ. Thời gian là **giờ server broker** — Exness thường là GMT+0, có thể khác giờ điện thoại của bạn.)*

### Khi bạn bấm nút

| Bạn bấm | EA làm gì | Bạn thấy |
|---|---|---|
| **ACCEPT** | Kiểm tra lại: bạn có trong allowlist, Proposal còn ACTIVE, chưa hết hạn, cấu trúc chưa bị chạm (quét tick tới hiện tại), giá còn đặt được lệnh chờ, khối lượng/margin/stops hợp lệ… Đạt hết → đặt **Buy Stop/Sell Stop** với SL/TP, hết hạn đúng giờ Proposal | Popup `ACCEPTED - pending order placed.` + tin `ORDER PLACED …` |
| ACCEPT nhưng có điều kiện không đạt | **Không** đặt lệnh, báo lý do. Nếu chỉ là điều kiện tạm thời (ví dụ giá đang vượt Entry, thị trường đóng) Proposal **vẫn ACTIVE** — bạn có thể bấm lại trước khi hết hạn | Popup `Refused …: <lý do>` |
| **REJECT** | Đánh dấu REJECTED, không bao giờ đặt lệnh | Popup `REJECTED - no order will be sent.` |
| Bấm lại lần 2 / bấm nút cũ | Không thay đổi gì (idempotent) | `Already <TRẠNG THÁI> - nothing changed.` |

Sau mỗi thay đổi, tin Proposal được **sửa lại**: thêm dòng `STATUS: …` và **gỡ 2 nút** (EXPIRED, INVALIDATED, REJECTED, EXECUTED…).

### Các thông báo khác

- `ORDER PLACED`, `FILLED … position #…`, `PENDING ORDER EXPIRED (not filled)`
- `STRUCTURE INVALIDATED before fill` (EA xoá lệnh chờ) / `after fill` (EA đóng vị thế; SL broker vẫn bảo vệ nếu việc đóng gặp trục trặc)
- `POSITION CLOSED … reason TP/SL/INVALIDATION/MANUAL | profit … commission … swap …`
- `RESULT UNKNOWN … NOT re-sent` — EA **không gửi lại** lệnh, tự đối soát với broker
- `Broker connection lost / restored`

Telegram lỗi hoặc mất mạng: EA vẫn phân tích, Proposal vẫn hết hạn đúng giờ, **không có lệnh nào được đặt** vì không có ACCEPT.

## Dùng trong Group (tuỳ chọn)

Khuyến nghị dùng **chat riêng** với bot. Nếu muốn dùng group:

1. Thêm bot vào group.
2. Lấy **Chat ID của group** (số âm, dạng `-100…`) bằng Cách A ở Bước 3 sau khi gửi một tin trong group.
3. `InpTgChatId` = Chat ID group; `InpTgAllowedUserIds` = **User ID cá nhân** của những người được phép bấm, cách nhau dấu phẩy, ví dụ `123456789,987654321`.

Nếu để trống `InpTgAllowedUserIds` khi dùng group, **không ai** bấm được (EA sẽ cảnh báo trong log) — đây là cố ý, để thành viên khác trong group không thể ACCEPT thay bạn.

## Xử lý sự cố

| Triệu chứng (dashboard / tab Experts) | Nguyên nhân | Cách xử lý |
|---|---|---|
| EA không chạy, Alert `Telegram bot token not configured…` | Thiếu file token hoặc sai chỗ/sai tên | Kiểm tra đúng `MQL5\Files\4LLB\telegram_token.txt` (không phải `.txt.txt`) |
| `Telegram bot token format invalid` | Token dán thiếu/thừa ký tự | Sao chép lại từ BotFather (`/mybots` → bot → *API Token*) |
| `InpTgChatId must be set…` | Chưa nhập Chat ID | Bước 3 + Bước 6 |
| `TG token rejected by Telegram (HTTP 401/404)` | Token sai hoặc đã bị revoke | Lấy token mới từ BotFather, cập nhật file, gắn lại EA |
| `TG network error … (check … allow-list…)` hoặc `WebRequest not allowed` | Chưa thêm URL, hoặc mất Internet/tường lửa | Bước 5; kiểm tra Internet của PC/VPS |
| `conflict: webhook set or another instance polls this bot` | Bot đang có webhook, hoặc một chương trình khác đọc tin cùng bot | Dùng bot riêng cho EA; nếu chắc chắn webhook không còn dùng: mở một lần `https://api.telegram.org/bot<TOKEN>/deleteWebhook` |
| Không nhận tin, log `sendMessage HTTP 403: Forbidden: bot can't initiate conversation…` | Bạn chưa bấm Start với bot | Bước 2 |
| Log `sendMessage HTTP 400: Bad Request: chat not found` | Sai Chat ID | Lấy lại Chat ID (Bước 3) |
| Bấm nút → `Not authorized.` | Chat/User ID không nằm trong allowlist | Kiểm tra `InpTgChatId`, `InpTgAllowedUserIds` |
| Bấm nút → `Unknown Signal ID` | Tin thuộc EA/terminal khác dùng chung bot, hoặc dữ liệu cũ | Mỗi terminal một bot riêng |
| Nút quay mãi không phản hồi | EA không chạy, AutoTrading tắt, mất khoá instance, hoặc lỗi Telegram | Xem dashboard dòng đầu (`TG …`, `LOCK LOST`, `SYNCING`) |
| Alert `only ONE EA instance may poll a bot token` | Một chart/terminal khác trên cùng máy đang dùng token này | Gỡ EA trùng, hoặc tạo bot khác |
| ACCEPT → `Refused … TERMINAL_ALGO_TRADING_DISABLED` | Nút Algo Trading đang tắt | Bật Algo Trading, bấm ACCEPT lại (nếu Proposal còn hạn) |

## Bảo mật — checklist

- [ ] Token chỉ nằm trong `telegram_token.txt` trên máy chạy EA.
- [ ] Không gửi token qua chat/email, không chụp màn hình có token, không commit lên Git.
- [ ] Nghi token bị lộ: BotFather → `/mybots` → chọn bot → **API Token → Revoke current token** → cập nhật file → gắn lại EA.
- [ ] Bật xác minh hai bước (Two-Step Verification) cho tài khoản Telegram của bạn.
- [ ] Chỉ những User ID bạn tin cậy nằm trong `InpTgAllowedUserIds`.
- [ ] Mỗi terminal/tài khoản dùng một bot riêng.
