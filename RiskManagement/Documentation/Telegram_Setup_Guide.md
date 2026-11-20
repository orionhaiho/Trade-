# Hướng dẫn cài bot Telegram cho EA RiskManagement

## 1. Bot sẽ gửi gì

EA gửi tin nhắn **tiếng Việt** tới một chat Telegram (chat riêng, nhóm hoặc kênh) khi:

| Sự kiện | Ví dụ tiêu đề tin nhắn |
|---|---|
| EA khởi động (kèm số dư, equity, margin…) | ✅ EA đã khởi động (chỉ đọc, không giao dịch) |
| EA khởi động thất bại | ❌ EA khởi động thất bại |
| Terminal mất / có lại kết nối | ⚠️ Terminal mất kết nối tới máy chủ giao dịch · ✅ Terminal đã kết nối lại |
| Dữ liệu tài khoản có vấn đề / hoạt động lại | ❌ Dữ liệu tài khoản có vấn đề · ✅ Dữ liệu tài khoản đã hoạt động lại |
| Phát hiện đổi tài khoản | ❌ Phát hiện tài khoản đã thay đổi |
| EA dừng (kèm lý do) | ℹ️ EA đã dừng |
| Tóm tắt định kỳ (tùy chọn) | ℹ️ Tóm tắt tài khoản |

- **Không spam:** chỉ gửi khi trạng thái thay đổi. Lỗi kéo dài 1 giờ vẫn chỉ tạo 1 tin nhắn, và sẽ có 1 tin nữa khi dữ liệu hoạt động lại.
- **Một chiều:** bot chỉ gửi đi. EA không đọc tin nhắn Telegram, nên không ai điều khiển được EA qua Telegram. EA vẫn **không giao dịch**.
- Mặc định **tắt** (`InpTelegramEnable=false`).

## 2. Tạo bot bằng @BotFather

1. Mở Telegram, tìm **@BotFather** (tài khoản chính thức, có dấu tích xanh) → **Start**.
2. Gửi lệnh `/newbot`.
3. Nhập **tên hiển thị**, ví dụ `Risk Monitor Exness`.
4. Nhập **username** của bot. Username phải kết thúc bằng `bot`, ví dụ `my_risk_monitor_bot`.
5. BotFather trả về **token**, dạng `123456789:AAH...`. Đây là chìa khóa của bot: **không chia sẻ cho ai**.

## 3. Lấy `chat_id`

### Cách A — gửi vào chat riêng của bạn (khuyến nghị)

1. Trong Telegram, mở bot vừa tạo (tìm theo username) → bấm **Start** → gửi một tin bất kỳ, ví dụ `hi`.
2. Trên máy tính, mở trình duyệt và truy cập (thay `<TOKEN>` bằng token thật):
   ```text
   https://api.telegram.org/bot<TOKEN>/getUpdates
   ```
3. Tìm đoạn `"chat":{"id":123456789,...`. Số đó là `chat_id`.
   - Nếu thấy `"result":[]`: gửi thêm một tin cho bot rồi tải lại trang.

### Cách B — gửi vào một nhóm

1. Thêm bot vào nhóm.
2. Trong nhóm, gửi `/start@ten_bot_cua_ban`. Bot trong nhóm mặc định chỉ thấy lệnh có nhắc tên nó.
3. Mở link `getUpdates` như trên. `chat_id` của nhóm là **số âm**, thường bắt đầu bằng `-100...`.

### Cách C — kênh (channel)

Thêm bot làm **quản trị viên** của kênh. Sau đó dùng `@ten_kenh` làm `chat_id`.

## 4. Cho phép MT5 gọi Telegram

1. MT5 → **Tools → Options → Expert Advisors**.
2. Tích **Allow WebRequest for listed URL**.
3. Thêm dòng `https://api.telegram.org` → **OK**.

Nếu bỏ qua bước này, tab Experts sẽ báo `TELEGRAM_SEND_FAILED ... error 4014`.

## 5. Cấu hình EA

Gắn (hoặc mở **Properties** của) EA `RiskManagement` → tab **Inputs**:

| Input | Giá trị | Ghi chú |
|---|---|---|
| `InpTelegramEnable` | `true` | Bật Telegram |
| `InpTelegramBotToken` | token từ BotFather | Không có khoảng trắng |
| `InpTelegramChatId` | ví dụ `123456789`, `-1001234567890` hoặc `@ten_kenh` | |
| `InpTelegramSummaryMinutes` | `0` = tắt; ví dụ `60` = mỗi giờ một tin tóm tắt | Tối đa 10080 (1 tuần) |
| `InpTelegramTimeoutMs` | `5000` | 1000–15000 ms |

Nếu token hoặc chat_id sai định dạng, EA **không khởi động** và báo `EA_INITIALIZATION_FAILED` trong tab Experts. EA không tự đoán hay sửa giá trị.

## 6. Kiểm tra

1. Gắn EA. Sau khoảng 1–2 chu kỳ timer, bạn sẽ nhận tin **"✅ EA đã khởi động (chỉ đọc, không giao dịch)"** kèm số dư.
2. Tab Experts không có dòng `TELEGRAM_SEND_FAILED`.
3. (Tùy chọn) Ngắt mạng vài giây rồi bật lại. Chỉ có tin nhắn khi mạng có lại, vì lúc mất mạng thì không gửi được. Tin nhắn đợi trong hàng đợi rồi gửi gộp: "mất kết nối" + "đã kết nối lại".
4. Gỡ EA → nhận **"ℹ️ EA đã dừng — Lý do: EA bị gỡ khỏi chart"**.

Mẫu tin nhắn (mô phỏng):

```text
[RiskManagement] ✅ EA đã khởi động (chỉ đọc, không giao dịch)
Tài khoản: 12345678 (Exness-MT5Real8, USD)
Thời gian: 2026.11.19 17:00:00
Chu kỳ làm mới: 1 giây
Balance: 1000.00 USD
Equity: 1013.75 USD
Lãi/lỗ đang mở: 12.50 USD
Margin đang dùng: 50.00 USD
Free Margin: 960.00 USD
Margin Level: 2027.25%
Đòn bẩy: 1:500
```

```text
[RiskManagement] ❌ Dữ liệu tài khoản có vấn đề
Tài khoản: 12345678 (Exness-MT5Real8, USD)
Thời gian: 2026.11.19 17:01:38
Trạng thái: Không hợp lệ
Lý do: Dữ liệu không hợp lệ: Margin bị âm
Lần có dữ liệu hợp lệ gần nhất: 2026.11.19 17:01:37
EA vẫn tiếp tục thử lại và sẽ báo khi dữ liệu hoạt động lại.
```

Thời gian trong tin nhắn là **giờ máy tính** chạy MT5. Toàn bộ mẫu nằm trong `Tests/host/results/host_log_sample.txt` (phần G).

## 7. Xử lý sự cố (xem tab Experts)

| Thông báo | Nguyên nhân | Cách xử lý |
|---|---|---|
| `WebRequest is not allowed (error 4014)` | Chưa thêm URL ở bước 4 | Thêm `https://api.telegram.org`; EA tự thử lại, không cần restart |
| `HTTP 401` hoặc `HTTP 404` | Token sai / đã bị thu hồi | Sửa `InpTelegramBotToken`. Telegram **tắt tới khi restart EA** |
| `HTTP 400 ... chat not found` | `chat_id` sai, hoặc chưa bấm **Start** với bot | Làm lại bước 3, sửa `InpTelegramChatId` |
| `HTTP 403` | Bạn đã chặn bot, hoặc bot bị xóa khỏi nhóm / không phải admin kênh | Bỏ chặn / thêm lại bot |
| `HTTP 429` | Gửi quá nhanh | EA tự chờ đúng thời gian Telegram yêu cầu |
| `WebRequest error 5200–5203` | Lỗi mạng / hết thời gian chờ | EA giữ tin nhắn và thử lại sau 10 s, 20 s, 40 s… tối đa 5 phút |
| Chữ tiếng Việt bị lỗi font | MetaEditor đọc sai mã hóa file `Include/Notify/TelegramMessagesVi.mqh` | File phải là **UTF-8 có BOM** (giữ nguyên như trong repo); test harness N01 sẽ FAIL nếu bị sai |

Hàng đợi chứa tối đa 50 tin. Khi đầy, tin cũ nhất bị bỏ, và tin gửi được tiếp theo sẽ ghi rõ đã bỏ bao nhiêu tin.

## 8. Bảo mật

- Ai có token đều gửi được tin nhắn dưới tên bot của bạn. **Đừng chụp màn hình tab Inputs** và đừng gửi file `.set`/profile có token cho người khác.
- Nếu lộ token: @BotFather → `/revoke` → chọn bot → nhận token mới → cập nhật EA.
- EA **không bao giờ** ghi token vào log (đã có test kiểm tra).

## 9. Lưu ý kỹ thuật

- `WebRequest` của MT5 là lệnh **đồng bộ**. Mỗi lần gửi có thể làm chu kỳ làm mới kế tiếp trễ tối đa bằng `InpTelegramTimeoutMs`. EA chỉ gửi **tối đa 1 request mỗi chu kỳ**, sau khi đã làm mới dữ liệu tài khoản. Khi dừng EA, việc gửi tin cuối cùng giới hạn trong 3 giây.
- Telegram không hoạt động trong Strategy Tester. EA tự tắt Telegram khi chạy trong tester.
- Telegram là phần **bổ sung theo yêu cầu**. Đặc tả M1 v1.0 ghi Telegram nằm ngoài phạm vi; thay đổi này đã được ghi lại trong `Phase0_Specification_Analysis.md` (D-27).
