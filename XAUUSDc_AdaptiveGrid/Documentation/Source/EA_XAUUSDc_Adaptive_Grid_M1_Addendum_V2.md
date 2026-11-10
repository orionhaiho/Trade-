# Ý KIẾN BỔ SUNG VÀ HIỆU CHỈNH ĐẶC TẢ EA

## XAUUSDc Adaptive Grid M1 – Exness Standard Cent – MT5/MQL5

Phiên bản: Addendum V2.0

Mục đích: Bổ sung các yêu cầu kỹ thuật, quản trị rủi ro và xử lý ngoại lệ cho đặc tả EA gốc.

Quy tắc ưu tiên: Các nội dung trong phụ lục này được ưu tiên áp dụng nếu có bất kỳ mâu thuẫn nào với đặc tả gốc.

# 1. Thứ tự ưu tiên xử lý của EA

EA phải ưu tiên bảo vệ vốn và quản lý vị thế đang tồn tại trước khi tìm kiếm tín hiệu mới.

Thứ tự xử lý bắt buộc:

1. Đồng bộ trạng thái tài khoản, Positions, Orders và Deals.
2. Đối chiếu các trade request chưa rõ kết quả.
3. Kiểm tra Global Risk, Daily Loss và Equity Drawdown.
4. Cập nhật P/L từng Basket BUY và SELL.
5. Kiểm tra và xử lý Basket TP/SL.
6. Quản lý các yêu cầu đóng đang Pending hoặc cần Retry.
7. Kiểm tra SAFE MODE và các trạng thái Lock.
8. Chỉ khi không bị khóa mới xét điều kiện mở lệnh hoặc thêm tầng Grid.
9. Trước mỗi lệnh mới phải chạy Risk Gate.

Yêu cầu quan trọng: Không được để bộ lọc ADX, RSI, Bollinger Bands hoặc điều kiện nến làm dừng quản lý TP/SL và các giới hạn rủi ro.

# 2. Logic tín hiệu hai nến – mặc định

## 2.1. Input

```
enum ENUM_SIGNAL_MODE
{
   SIGNAL_TWO_CANDLE = 0,
   SIGNAL_ONE_CANDLE = 1
};

input ENUM_SIGNAL_MODE SignalMode = SIGNAL_TWO_CANDLE;
```

Mặc định sử dụng `SIGNAL_TWO_CANDLE`.

## 2.2. BUY – hai nến riêng biệt

Nến `shift 2` là nến Setup:

- `Close[2] < LowerBB[2]`
- `RSI[2] <= RSI_Buy`

Nến `shift 1` là nến Confirmation:

- `Close[1] > LowerBB[1]`
- `Close[1] < UpperBB[1]`
- `ADX[1] < MaxADX`

Tất cả điều kiện phải đồng thời thỏa mãn.

## 2.3. SELL – hai nến riêng biệt

Nến `shift 2` là nến Setup:

- `Close[2] > UpperBB[2]`
- `RSI[2] >= RSI_Sell`

Nến `shift 1` là nến Confirmation:

- `Close[1] < UpperBB[1]`
- `Close[1] > LowerBB[1]`
- `ADX[1] < MaxADX`

Tất cả điều kiện phải đồng thời thỏa mãn.

## 2.4. Quy tắc lấy dữ liệu

- RSI chỉ lấy tại shift 2.
- ADX chỉ lấy tại shift 1.
- Bollinger Bands lấy tương ứng với từng shift.
- Chỉ sử dụng nến đã đóng.
- Chỉ đánh giá tín hiệu một lần khi xuất hiện nến M1 mới.
- Phải lưu timestamp nến đã xử lý để tránh mở lệnh lặp trên nhiều tick.

`SIGNAL_ONE_CANDLE` chỉ là chế độ thử nghiệm tùy chọn. Phải định nghĩa chính xác và backtest độc lập. Không được gộp kết quả của hai chế độ để tạo ra kết quả backtest đẹp hơn.

# 3. ADX chỉ chặn mở lệnh mới

Khi:

`ADX >= MaxADX`

EA phải:

- Không mở Basket mới.
- Không thêm tầng Grid mới.
- Không tự động đóng Basket đang chạy chỉ vì ADX tăng.

Tuy nhiên, Basket đang tồn tại vẫn phải được quản lý bình thường.

Dù ADX cao, EA vẫn phải kiểm tra trên mỗi tick:

1. Basket TP.
2. Basket SL.
3. Combined Loss.
4. Daily Loss.
5. Equity Drawdown.
6. Các lệnh đóng đang Pending hoặc cần Retry.
7. Order Reconciliation.

Không được đặt toàn bộ Basket Manager bên trong điều kiện `ADX < MaxADX`.

# 4. Basket Stop Loss theo ngân sách rủi ro

## 4.1. Input

```
input bool   UseBasketSLFromRiskBudget = true;
input double BasketSL_AccountCurrency = 5.00;
```

## 4.2. Công thức tính

Tại thời điểm khởi tạo Basket:

```
BasketRiskBudget =
EquityAtBasketStart * BasketRiskPercent / 100
```

Nếu:

`UseBasketSLFromRiskBudget = true`

Thì:

```
EffectiveBasketSL = BasketRiskBudget
```

Nếu:

`UseBasketSLFromRiskBudget = false`

Thì:

```
EffectiveBasketSL =
min(BasketSL_AccountCurrency, BasketRiskBudget)
```

Nguyên tắc bắt buộc:

Basket SL không bao giờ được rộng hơn ngân sách rủi ro đã cấp.

Nếu SL không hợp lệ, nhỏ hơn hoặc bằng 0, hoặc đơn vị tiền chưa được xác minh, EA không được mở Basket mới.

Lưu ý: Basket SL phần mềm chỉ là ngưỡng kích hoạt đóng lệnh. Nó không bảo đảm mức lỗ thực tế không thể vượt ngưỡng trong các trường hợp gap, slippage, mất kết nối hoặc broker từ chối lệnh.

# 5. Risk Gate trước mọi lệnh mới

Risk Gate phải chạy trước tất cả các loại lệnh:

- Lệnh khởi tạo BUY.
- Lệnh khởi tạo SELL.
- Lệnh thêm tầng BUY.
- Lệnh thêm tầng SELL.

Một lệnh chỉ được phép gửi nếu rủi ro dự kiến sau khi khớp đồng thời thỏa mãn:

1. Ngân sách rủi ro còn lại của Basket.
2. Combined Loss Limit của BUY + SELL.
3. Daily Loss Limit còn lại.
4. Giới hạn Margin và Volume.
5. Các giới hạn Equity và Account khác.

Nếu bất kỳ điều kiện nào không đạt, EA phải từ chối lệnh và ghi log lý do.

Không được tự động nới ngân sách rủi ro để cho phép lệnh được thực hiện.

## 5.1. Phương pháp tính rủi ro dự kiến

Phải tính P/L stress của toàn bộ vị thế Basket hiện tại cộng với lệnh mới dự kiến.

Sử dụng:

`OrderCalcProfit()`

cho từng vị thế và lệnh giả định.

Không tự suy diễn tick value, contract size hoặc giá trị point bằng các phép nhân cố định.

Mô hình khái niệm:

```
ProjectedBasketLoss =
max(0, -ProjectedNetBasketPLAtStress)
```

Trong đó:

- Existing Positions được định giá tại mức giá stress bất lợi.
- New Order được mô phỏng tại giá khớp giả định.
- Sau đó đánh giá toàn bộ Basket tại mức giá stress.
- Cộng các chi phí chưa được phản ánh trong P/L.
- Cộng phí đóng dự kiến.
- Cộng buffer slippage.
- Ghi nhận chính xác commission và phí đã phát sinh.

Không được cộng trùng commission hoặc phí đã được ghi nhận trong Deal/Position History.

Phải liên kết Deal với Basket bằng Position Identifier, Magic Number, Symbol và lịch sử giao dịch.

## 5.2. Mức giá Stress

Input:

```
input double StressMoveATR = 1.0;
```

Công thức:

```
StressMove = ATR(14) * StressMoveATR
```

Quy tắc:

- BUY: mô phỏng giá giảm bất lợi.
- SELL: mô phỏng giá tăng bất lợi.
- Sử dụng Bid/Ask phù hợp với giá đóng thực tế.
- Cộng thêm spread và slippage stress theo cấu hình.

Đây là mô hình stress để ước tính rủi ro, không phải mức lỗ tối đa được bảo đảm.

## 5.3. Minimum Lot vượt ngân sách

EA phải:

- Đọc `SYMBOL_VOLUME_MIN`.
- Đọc `SYMBOL_VOLUME_STEP`.
- Tính rủi ro với volume nhỏ nhất hợp lệ.
- Nếu minimum lot đã vượt bất kỳ giới hạn rủi ro nào thì từ chối giao dịch.

Tuyệt đối không:

- Tự nâng lot.
- Tự nới Basket SL.
- Tự tăng Risk Budget.
- Bỏ qua Risk Gate.

Log bắt buộc:

```
REJECT_MIN_VOLUME_EXCEEDS_RISK_BUDGET
```

# 6. Xác thực đơn vị tiền tài khoản

Mọi ngưỡng tiền phải sử dụng đơn vị tiền thực tế của tài khoản MT5.

Không hard-code quy đổi USD/USC trong logic giao dịch.

Input:

```
input string RequiredAccountCurrency = "USC";
```

Tại `OnInit()`:

1. Đọc `ACCOUNT_CURRENCY`.
2. Kiểm tra currency có đúng `USC` hay không.
3. Nếu không phải USC, ghi log và trả về `INIT_FAILED`.
4. Không tự động quy đổi USD sang USC.
5. Strategy Tester phải sử dụng Deposit Currency phù hợp.

Tên biến tiền đề xuất:

```
BasketTP_AccountCurrency
BasketSL_AccountCurrency
MaxCombinedLoss_AccountCurrency
DailyLoss_AccountCurrency
MaxEquityDD_AccountCurrency
```

Không được mặc định rằng mọi giá trị tick value đã có đơn vị tiền như mong muốn. Phải xác minh bằng `OrderCalcProfit()` và kiểm tra trên tài khoản Demo.

# 7. Bắt buộc tài khoản Hedging

Tài khoản Netting luôn phải bị từ chối.

Không có Input nào được phép bỏ qua yêu cầu này.

Tại `OnInit()`:

- Đọc `ACCOUNT_MARGIN_MODE`.
- Chỉ chấp nhận `ACCOUNT_MARGIN_MODE_RETAIL_HEDGING`.
- Nếu là Netting hoặc Exchange thì ghi log và trả `INIT_FAILED`.

Đề xuất xóa Input:

`RequireHedgingAccount`

Nếu vẫn giữ để tương thích file `.set` cũ thì phải đánh dấu Deprecated và không cho phép đặt `false` để bỏ qua kiểm tra.

# 8. Giới hạn tần suất gửi lệnh

Áp dụng độc lập cho BUY và SELL.

Quy định:

- Tối đa một lệnh mới mỗi nến M1.
- Đồng thời phải đủ `CooldownSeconds` kể từ fill được xác nhận.
- Mặc định `CooldownSeconds = 60`.
- Áp dụng cho cả lệnh khởi tạo và lệnh thêm tầng.
- Cooldown tính từ Deal Fill Time/Server Time, không tính đơn thuần từ thời điểm gửi request.
- BUY và SELL có timestamp riêng.
- Sau restart, phải khôi phục fill time từ History/Deals.
- Nếu không xác định được thời điểm fill cuối thì vào SAFE MODE.
- Nếu đã có lệnh cùng phía trong nến hiện tại thì không được gửi lệnh mới.

# 9. SAFE MODE và khôi phục trạng thái

## 9.1. Điều kiện kích hoạt SAFE MODE

EA phải vào SAFE MODE nếu xảy ra một trong các trường hợp:

- Không đọc hoặc khôi phục được Basket State.
- Không xác định được `BasketRiskBudget`.
- Không xác định được `EquityAtBasketStart`.
- Không khôi phục được Global Lock.
- Không khôi phục được Daily Lock.
- Không khôi phục được Equity Lock.
- Có request gửi lệnh chưa rõ kết quả.
- Orders, Deals và Positions không thể đối chiếu nhất quán.
- Persistent State bị lỗi, sai version hoặc checksum không hợp lệ.

## 9.2. Hành vi trong SAFE MODE

Khi SAFE MODE được kích hoạt:

- Không mở Basket mới.
- Không thêm tầng Grid.
- Không gửi lại request chưa rõ kết quả.
- Tiếp tục đọc và quản lý Positions thực tế.
- Tiếp tục TP nếu trạng thái Basket được xác minh.
- Chỉ sử dụng SL dự phòng nếu ngân sách bảo vệ khôi phục được đáng tin cậy.
- Nếu không xác định được giới hạn bảo vệ đáng tin cậy, đóng các vị thế EA theo quy trình khẩn cấp an toàn và giữ khóa.
- Nếu không khôi phục được trạng thái khóa, mặc định coi như đang Locked.
- Chỉ thoát SAFE MODE khi trạng thái đã được đối chiếu và xác minh đầy đủ hoặc người vận hành Reset theo quy trình có log.

Không được tạo BasketRiskBudget mới cho Basket cũ sau restart.

Input:

```
input bool SafeModeCloseIfRiskStateUnknown = true;
```

## 9.3. Persistent State tối thiểu

Phải lưu:

- Schema Version và Checksum.
- Symbol.
- Magic BUY/SELL.
- Basket Start Time.
- `EquityAtBasketStart`.
- `BasketRiskBudget`.
- `EffectiveBasketSL`.
- Last Confirmed Fill Time theo từng phía.
- Last Processed M1 Bar Timestamp theo từng phía.
- Daily Baseline.
- Daily Lock.
- Global Lock.
- Equity Lock.
- Pending Order Intent.
- Trạng thái Order Reconciliation.

Có thể sử dụng Global Variables hoặc File State có Version/Checksum.

Phải có cơ chế kiểm tra dữ liệu khi đọc và tránh ghi state không hoàn chỉnh.

# 10. Order Reconciliation – chống gửi lệnh trùng

Nếu trade request trả về Timeout, mất kết nối hoặc kết quả không xác định:

1. Đánh dấu request là `UNKNOWN/PENDING_RECONCILIATION`.
2. Lưu Intent gồm Symbol, Magic, Side, Volume, Request Time và các thuộc tính nhận dạng phù hợp.
3. Khóa mọi lệnh mới có khả năng tạo trùng Intent.
4. Đối chiếu Active Orders.
5. Đối chiếu Positions.
6. Đối chiếu Deal History.
7. Xác định request đã khớp, bị từ chối hay chưa thể kết luận.
8. Chỉ mở khóa sau khi trạng thái thực tế được xác minh.

Nếu chưa thể kết luận, tiếp tục giữ SAFE MODE và đối chiếu.

Tuyệt đối không gửi lại lệnh chỉ vì request bị Timeout.

Không được dựa duy nhất vào Comment để nhận dạng giao dịch.

Phải kết hợp:

- Ticket.
- Order/Deal/Position Identifiers.
- Magic.
- Symbol.
- Side.
- Volume.
- Thời gian.
- Broker History trong phạm vi có thể.

Không giả định broker cung cấp cơ chế Idempotency tuyệt đối.

# 11. Thứ tự xử lý OnTick()

Luồng `OnTick()` bắt buộc:

```
1. Sync account, positions, orders, deals.

2. Reconcile các request chưa rõ kết quả.

3. Kiểm tra Global Risk / Daily Loss / Equity DD.

4. Tính P/L Basket BUY và SELL.

5. Kiểm tra và xử lý Basket TP/SL.

6. Xử lý các lệnh đóng Pending/Retry.

7. Nếu SAFE MODE hoặc Lock:
   - Không mở Basket mới.
   - Không thêm tầng Grid.
   - Vẫn quản lý vị thế và bảo vệ rủi ro.

8. Nếu không có nến M1 mới:
   - Bỏ qua Signal Logic.
   - Nhưng không bỏ qua Risk Management và Basket TP/SL.

9. Nếu có nến M1 mới:
   - Kiểm tra Regime.
   - Kiểm tra Spread.
   - Kiểm tra Cooldown.
   - Kiểm tra giới hạn một lệnh/nến.

10. Đánh giá tín hiệu BUY/SELL.

11. Chạy Risk Gate trước từng lệnh.

12. Gửi request và quản lý kết quả/reconciliation.
```

Không được `return` sớm do ADX cao hoặc không có nến mới trước khi chạy Risk Management và Basket TP/SL.

# 12. Danh sách Input đề xuất cập nhật

```
input group "ACCOUNT VALIDATION"
input string RequiredAccountCurrency = "USC";
input string InpSymbol = "XAUUSDc";

input group "SIGNAL"
input ENUM_SIGNAL_MODE SignalMode = SIGNAL_TWO_CANDLE;

input group "BASKET"
input double BasketRiskPercent = 1.0;
input bool UseBasketSLFromRiskBudget = true;
input double BasketTP_AccountCurrency = 1.50;
input double BasketSL_AccountCurrency = 5.00;

input group "GLOBAL RISK"
input double MaxCombinedLoss_AccountCurrency = 10.00;
input double DailyLoss_AccountCurrency = 10.00;
input double MaxEquityDD_AccountCurrency = 25.00;

input group "RISK STRESS"
input double StressMoveATR = 1.0;
input double SlippageStressPoints = 30.0;

input group "EXECUTION"
input int CooldownSeconds = 60;
input bool UseNewBarOnly = true;
input int MaxCloseRetries = 5;

input group "RECOVERY"
input bool SafeModeCloseIfRiskStateUnknown = true;
input bool EnablePersistentState = true;
```

Đây là danh sách Input định hướng. Có thể tinh chỉnh tên và kiểu dữ liệu, nhưng không được thay đổi hành vi bắt buộc.

# 13. Test Case nghiệm thu bổ sung

| ID      | Tình huống                           | Kết quả mong đợi                        |
| ------- | ------------------------------------ | --------------------------------------- |
| SIG-01  | Shift 2 xuyên Band, shift 1 xác nhận | Chỉ một tín hiệu                        |
| SIG-02  | Chỉ shift 1 xuyên Band               | Không có tín hiệu TWO_CANDLE            |
| SIG-03  | ADX >= MaxADX                        | Không mở/thêm lệnh                      |
| RISK-01 | Risk nằm trong Basket Budget         | Có thể qua Risk Gate                    |
| RISK-02 | Risk vượt Basket Budget              | Từ chối                                 |
| RISK-03 | Combined Risk vượt giới hạn          | Từ chối                                 |
| RISK-04 | Daily Loss còn lại không đủ          | Từ chối                                 |
| RISK-05 | Minimum Lot vượt ngân sách           | Từ chối, không nâng lot                 |
| ACC-01  | Account Currency khác USC            | INIT_FAILED                             |
| ACC-02  | Account Mode Netting                 | INIT_FAILED                             |
| RATE-01 | Đã có lệnh cùng phía trong nến       | Không gửi lệnh mới                      |
| RATE-02 | Chưa đủ Cooldown                     | Không gửi lệnh mới                      |
| REC-01  | Restart mất Basket State             | SAFE MODE                               |
| REC-02  | Không khôi phục được Lock            | Mặc định Locked                         |
| ORD-01  | Timeout nhưng broker đã Fill         | Reconcile, không gửi trùng              |
| ORD-02  | Timeout chưa rõ kết quả              | Giữ Pending/SAFE MODE                   |
| ORD-03  | Đóng Basket một phần thất bại        | Retry có kiểm soát, không mở Basket mới |
| TICK-01 | ADX tăng khi Basket đang mở          | TP/SL vẫn hoạt động                     |
| TICK-02 | Không có nến M1 mới                  | Risk/TP/SL vẫn chạy                     |

# 14. Chỉ thị dành cho AI lập trình

Hãy coi phụ lục này là yêu cầu bắt buộc và ưu tiên hơn mô tả cũ nếu có xung đột.

## Trước khi viết code

1. Đọc toàn bộ đặc tả gốc và phụ lục.
2. Liệt kê các mâu thuẫn còn tồn tại.
3. Xác minh Currency, Account Mode và Symbol Specification từ MT5.
4. Nếu không thể xác minh thông tin, phải nêu rõ và không được giả định.
5. Thiết kế State Machine cho Basket, SAFE MODE, Pending Request và Risk Locks.
6. Giải thích cách tính Projected Risk và tránh Double-count Commission/Fees.

## Khi viết code

- Dùng MQL5 chuẩn, không dùng cú pháp MQL4.
- Kiểm tra Retcode cho mọi Trade Action.
- Quản lý Position theo Ticket.
- Tách BUY/SELL bằng Magic riêng.
- Có Order Reconciliation khi kết quả request không rõ.
- Không gửi Duplicate Request.
- Không bỏ qua Risk Gate.
- Không tự thay đổi thông số chiến lược.
- Ghi log lý do mở lệnh, bỏ qua lệnh, đóng lệnh và khóa EA.

## Khi bàn giao

Phải cung cấp:

- Source `.mq5` và `.mqh`.
- File `.set`.
- Hướng dẫn Compile.
- Hướng dẫn Strategy Tester.
- Test Report cho các Test Case ở trên.
- Nêu rõ phần nào đã thực sự chạy và phần nào mới chỉ được Review tĩnh.
- Không được bịa kết quả Backtest, Monte Carlo hoặc Forward Test.

# 15. Nguyên tắc vận hành cuối cùng

EA phải tuân thủ ba nguyên tắc:

Nguyên tắc 1 – Không mở thêm rủi ro khi trạng thái không chắc chắn.

Nếu EA không xác định được trạng thái giao dịch hoặc kết quả request, phải khóa lệnh mới và tiến hành đối chiếu.

Nguyên tắc 2 – Không đánh đổi an toàn để duy trì hoạt động giao dịch.

Nếu không thể xác định mức bảo vệ đáng tin cậy cho vị thế đang tồn tại, phải chuyển sang quy trình khẩn cấp và giữ khóa.

Nguyên tắc 3 – Không ép EA phải giao dịch.

Không có tín hiệu đạt chuẩn hoặc Risk Gate không cho phép thì đứng ngoài thị trường. Không được tăng lot, nới SL hoặc bỏ qua bộ lọc để tạo thêm giao dịch.

Mục tiêu tối thượng: Bảo toàn vốn, kiểm soát drawdown và chỉ chấp nhận rủi ro có thể định lượng, kiểm chứng.

## Lưu ý phản biện trước khi đưa AI lập trình

Có một điểm cần đặc biệt lưu ý trong đặc tả tổng thể: với vốn ban đầu 500 USC và Risk per Basket 1%, ngân sách rủi ro mỗi Basket là 5 USC. Nếu BUY và SELL được phép chạy độc lập, hai Basket có thể cùng tiêu thụ tổng ngân sách 10 USC, tương đương 2% vốn ban đầu.

Do đó:

- `BasketRiskPercent = 1%` là giới hạn riêng cho từng Basket.
- `MaxCombinedLoss_AccountCurrency = 10` là giới hạn tổng cho cả hai phía.
- `DailyLoss_AccountCurrency = 10` là giới hạn lỗ ngày, nhưng cần xác định rõ có bao gồm realized P/L, floating P/L, commission và swap hay không.
- `MaxEquityDD_AccountCurrency = 25` là giới hạn drawdown 5% so với mốc equity tham chiếu được xác định trước.

Các giới hạn này không thay thế nhau. EA cần một bộ Risk Manager thống nhất để tránh tính thiếu hoặc tính trùng rủi ro.
