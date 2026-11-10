# ĐẶC TẢ CHIẾN LƯỢC & YÊU CẦU PHÁT TRIỂN EA
## XAUUSDc Adaptive Mean-Reversion Grid – M1 – Exness Standard Cent – MT5/MQL5

**Phiên bản tài liệu:** 1.0  
**Mục đích:** Làm tài liệu nguồn để yêu cầu AI thiết kế, lập trình, kiểm thử và bàn giao EA MQL5.  
**Trạng thái:** Đặc tả thiết kế ban đầu; chưa phải chiến lược đã được backtest hoặc chứng minh có lợi nhuận.

---

# 1. TÓM TẮT DỰ ÁN

Phát triển một Expert Advisor (EA) giao dịch vàng trên MetaTrader 5, tài khoản Exness Standard Cent, sử dụng chiến lược Adaptive Mean-Reversion Grid trên khung M1.

EA có hai cụm giao dịch độc lập:
- BUY Basket: chỉ quản lý các vị thế BUY do EA mở.
- SELL Basket: chỉ quản lý các vị thế SELL do EA mở.

Mỗi Basket có ngân sách rủi ro mục tiêu bằng 1% Equity tại thời điểm khởi tạo Basket. EA không dùng Martingale, không nhân khối lượng để gỡ lỗ, không mở Grid vô hạn. EA phải từ chối giao dịch nếu khối lượng tối thiểu hoặc chi phí thực tế khiến ngân sách rủi ro không thể đáp ứng.

**Nguyên tắc ưu tiên:** bảo toàn vốn > kiểm soát drawdown > chất lượng thực thi > lợi nhuận.

## 1.1. Thông tin tài khoản

| Thuộc tính | Giá trị |
|---|---|
| Broker | Exness |
| Account type | Standard Cent |
| Platform | MetaTrader 5 |
| Symbol dự kiến | XAUUSDc |
| Timeframe tín hiệu | M1 |
| Balance ban đầu | 500 USC |
| Giá trị quy đổi tham khảo | 500 USC = 5 USD |
| Rủi ro mỗi Basket | 1% Equity lúc khởi tạo Basket |
| Rủi ro tiền ban đầu mỗi Basket | 5 USC |
| Chế độ | BUY và SELL độc lập |
| Chiến lược | Adaptive Mean-Reversion Grid |
| Martingale | Cấm |
| Lot multiplier | 1.0 |

**Lưu ý bắt buộc:** Người dùng xác nhận tên symbol đang dự kiến sử dụng là `XAUUSDc`. EA phải kiểm tra tên symbol thực tế trong Market Watch và Specification của tài khoản. Không được tự động đổi sang `XAUUSC`, `XAUUSD` hoặc symbol khác. Nếu symbol không tồn tại hoặc thông số không khớp, EA phải dừng khởi tạo và ghi log lý do.

---

# 2. CÁC ĐIỂM PHẢI XÁC MINH TRƯỚC KHI GIAO DỊCH

Tài khoản Cent dùng cent lot và số dư hiển thị theo USC. Theo tài liệu Exness, Standard Cent có thể giao dịch XAUUSDc; 1 cent lot tương đương 0.01 standard lot và khối lượng tối thiểu được công bố là 0.01 lot. Tuy nhiên, thông số riêng của symbol phải được đọc trực tiếp từ MT5 tại thời điểm chạy.

EA phải đọc tối thiểu:
- `SYMBOL_VOLUME_MIN`
- `SYMBOL_VOLUME_MAX`
- `SYMBOL_VOLUME_STEP`
- `SYMBOL_TRADE_CONTRACT_SIZE`
- `SYMBOL_TRADE_TICK_SIZE`
- `SYMBOL_TRADE_TICK_VALUE`
- `SYMBOL_POINT`
- `SYMBOL_DIGITS`
- `SYMBOL_TRADE_STOPS_LEVEL`
- `SYMBOL_TRADE_FREEZE_LEVEL`
- `ACCOUNT_CURRENCY`
- `ACCOUNT_MARGIN_MODE`

Không hard-code contract size, tick value, point, digits hoặc volume step.

## 2.1. Quy đổi khối lượng tham khảo

Nếu symbol áp dụng đúng quy ước Exness Standard Cent:
- 1.00 cent lot = 0.01 standard lot.
- 0.01 cent lot = 0.0001 standard lot.
- Với contract vàng 100 troy ounces/standard lot, 0.01 cent lot tương đương exposure danh nghĩa 0.01 troy ounce.

Theo giả định trên, giá vàng biến động 1 USD với 0.01 cent lot sẽ tạo P/L xấp xỉ 0.01 USD, tức khoảng 1 USC. Đây chỉ là phép quy đổi tham khảo, không được dùng thay cho phép tính thực tế.

**Yêu cầu lập trình:** dùng `OrderCalcProfit()` để ước tính P/L theo giá vào/giá thoát và volume. Xác nhận kết quả bằng Strategy Tester và tài khoản Demo. Không được suy luận rằng mọi giá trị tick value trả về đều đã được quy đổi sang USC theo cách mong muốn.

## 2.2. Điều kiện tài khoản Hedging

Vì BUY và SELL phải tồn tại độc lập trên cùng symbol, EA phải kiểm tra `ACCOUNT_MARGIN_MODE`.

- Chỉ cho phép chạy khi tài khoản MT5 hỗ trợ Retail Hedging.
- Nếu tài khoản là Netting, hiển thị lỗi rõ ràng và `INIT_FAILED`.
- Không giả lập hai Basket độc lập bằng cách cộng/trừ vị thế trên tài khoản Netting.

---

# 3. THIẾT KẾ CHIẾN LƯỢC

## 3.1. Ý tưởng

EA tìm các nhịp giá bị kéo lệch khỏi vùng cân bằng ngắn hạn, chờ tín hiệu quay trở lại Bollinger Bands rồi mở vị thế đầu tiên. Nếu giá tiếp tục đi ngược vị thế, EA có thể thêm các lệnh cùng chiều theo khoảng cách Grid động dựa trên ATR.

Khi tổng P/L ròng của Basket đạt TP hoặc SL, EA đóng toàn bộ vị thế thuộc Basket đó.

Grid chỉ là cơ chế phân bổ điểm vào lệnh; không phải bảo đảm giá sẽ hồi về. Một xu hướng mạnh có thể khiến nhiều tầng cùng âm. Do đó, giới hạn rủi ro phải được kiểm tra trước mỗi lệnh mới.

## 3.2. Chỉ báo

Tất cả chỉ báo dùng dữ liệu M1:
- Bollinger Bands: period 20, deviation 2.0, applied price Close.
- RSI: period 7, applied price Close.
- ADX: period 14.
- ATR: period 14.
- EMA 200: tùy chọn để phân loại thiên hướng thị trường và nghiên cứu, không được âm thầm thêm điều kiện nếu chưa có input bật/tắt.

Dùng dữ liệu nến đã đóng để tạo tín hiệu. Không dùng giá trị indicator của nến đang chạy để xác nhận tín hiệu.

---

# 4. ĐIỀU KIỆN VÀO LỆNH BAN ĐẦU

## 4.1. BUY signal

Tại thời điểm hình thành nến M1 mới, kiểm tra các nến đã đóng:

1. ADX(14) tại nến tín hiệu nhỏ hơn 22.
2. RSI(7) tại nến trước khi xác nhận nhỏ hơn hoặc bằng 25.
3. Nến setup có Close nằm dưới Lower Bollinger Band.
4. Nến xác nhận sau đó đóng trở lại bên trong Bollinger Bands, tức Close > Lower Band.
5. Spread hiện tại không vượt ngưỡng cho phép.
6. Không có BUY Basket đang hoạt động.
7. Không có Global Risk Lock, Daily Lock hoặc Equity Lock.
8. Thời gian giao dịch được phép.
9. Không có trạng thái lỗi/đóng lệnh chưa hoàn tất.

Khi mọi điều kiện hợp lệ, mở BUY đầu tiên với volume khởi tạo.

**Yêu cầu cho AI lập trình:** mô tả rõ index nến (`shift`) và thứ tự setup/confirmation. Không được dùng cùng một nến để vừa xuyên band vừa xác nhận quay vào band nếu logic được định nghĩa là hai nến khác nhau. Cung cấp input cho phép chọn cách diễn giải, mặc định dùng hai nến đã đóng riêng biệt.

## 4.2. SELL signal

Đối xứng với BUY:

1. ADX(14) < 22.
2. RSI(7) >= 75.
3. Nến setup có Close nằm trên Upper Bollinger Band.
4. Nến xác nhận đóng trở lại bên trong Bands, tức Close < Upper Band.
5. Spread hợp lệ.
6. Không có SELL Basket đang hoạt động.
7. Tất cả bộ khóa rủi ro và bộ lọc thời gian đều cho phép.

## 4.3. Bộ lọc chế độ thị trường

- ADX < 22: đủ điều kiện xem xét tín hiệu.
- ADX >= 22: không khởi tạo Basket mới và không thêm tầng mới theo mặc định.
- Có input `MaxADX` để kiểm định.
- Nếu ADX tăng vượt ngưỡng trong lúc Basket đang mở: mặc định ngừng thêm tầng, tiếp tục quản lý TP/SL; không tự động đóng Basket chỉ vì ADX tăng.
- Có thể bổ sung chế độ đóng khẩn cấp theo regime như một tùy chọn riêng, mặc định OFF và phải được backtest riêng.

Không tuyên bố ADX < 22 chắc chắn là Sideway. Đây chỉ là bộ lọc giả thuyết cần kiểm định.

---

# 5. GRID MANAGER

## 5.1. Thông số cơ sở

| Tham số | Giá trị mặc định |
|---|---:|
| Initial lot | 0.01 cent lot |
| Lot multiplier | 1.0 |
| Max layers per side | 5 |
| Max total volume per side | 0.05 cent lot |
| ATR period | 14 |
| ATR multiplier | 0.80 |
| Minimum grid distance | 0.50 USD giá |
| Maximum grid distance | 1.50 USD giá |
| Cooldown | 60 giây |
| Chỉ xử lý thêm tầng | Tối đa một lần trên mỗi nến M1 |

Các giá trị trên là giá trị nghiên cứu ban đầu, không phải tối ưu đã được xác nhận.

## 5.2. Công thức Grid spacing

`GridDistance = clamp(ATR(14) * ATRMultiplier, MinGridUSD, MaxGridUSD)`

Trong đó:
- ATR tính theo đơn vị giá của XAUUSDc.
- `MinGridUSD = 0.50`.
- `MaxGridUSD = 1.50`.
- `ATRMultiplier = 0.80`.

Ví dụ ATR = 0.80 USD:
GridDistance = 0.80 × 0.80 = 0.64 USD.

Phải chuẩn hóa giá theo tick size hợp lệ của symbol. Không được nhầm pip, point và USD giá.

## 5.3. Quy tắc thêm BUY

Với Basket BUY:
- Lệnh đầu tiên là BUY đầu tiên.
- Lấy giá khớp thực tế của lệnh BUY gần nhất làm mốc.
- Chỉ xem xét thêm BUY nếu Bid giảm ít nhất `GridDistance` so với giá khớp của BUY gần nhất.
- Tối đa một lệnh mới mỗi nến M1.
- Không thêm nếu ADX >= MaxADX, spread vượt ngưỡng, Basket đã chạm risk limit, volume vượt giới hạn, margin không đủ hoặc đang có thao tác trade chưa hoàn tất.

Công thức điều kiện tham khảo:
`Bid <= LastBuyOpenPrice - GridDistance`

## 5.4. Quy tắc thêm SELL

Với Basket SELL:
- Lấy giá khớp thực tế của SELL gần nhất.
- Chỉ xem xét thêm SELL nếu Ask tăng ít nhất `GridDistance` so với giá khớp SELL gần nhất.
- Tối đa một lệnh mới mỗi nến M1.

Công thức:
`Ask >= LastSellOpenPrice + GridDistance`

## 5.5. Quy tắc volume

- Volume mặc định mọi tầng bằng 0.01 cent lot.
- Lot multiplier luôn bằng 1.0.
- Không tăng lot theo số tầng.
- Không dùng Fibonacci lot, Martingale, Anti-Martingale hoặc nhân volume để gỡ lỗ.
- Chuẩn hóa volume theo min/max/step từ symbol.
- Nếu volume yêu cầu không hợp lệ, không tự nâng volume vượt ngân sách; bỏ qua lệnh và ghi log.
- Tổng volume một phía không vượt 0.05 cent lot, đồng thời không vượt giới hạn risk-based.

**Max layers = 5 chỉ là giới hạn cứng. Không có nghĩa EA phải mở đủ 5 tầng.**

## 5.6. Kiểm tra rủi ro trước khi thêm tầng

Trước mọi lệnh mới, EA phải tính P/L dự kiến của toàn bộ vị thế hiện tại cộng lệnh dự kiến tại các mức giá stress.

Yêu cầu:
1. Dùng `OrderCalcProfit()` cho từng vị thế.
2. Tính tại mức giá bất lợi giả định, không chỉ dùng giá hiện tại.
3. Cộng spread dự kiến, commission, swap và buffer slippage nếu có.
4. Nếu mức lỗ dự kiến vượt ngân sách Basket còn lại, không mở lệnh.
5. Không được cho rằng Basket SL phần mềm bảo đảm lỗ tối đa chính xác trong gap, mất kết nối hoặc trượt giá.

Đề xuất mức stress kiểm định: giá đi bất lợi thêm 1.0 × ATR sau khi lệnh mới khớp. Đây là giả định kiểm thử, cần có input để thay đổi.

---

# 6. BASKET MANAGER

## 6.1. Tách Basket

Dùng Magic Number riêng:
- BUY Magic = 10001.
- SELL Magic = 10002.

Mọi thao tác đếm vị thế, tính lợi nhuận, đóng lệnh phải lọc đồng thời:
- Symbol = XAUUSDc (hoặc đúng symbol input đã xác thực).
- Magic Number tương ứng.
- Position type đúng phía.

Không tác động đến lệnh thủ công hoặc EA khác.

## 6.2. Ngân sách rủi ro

Balance ban đầu = 500 USC.

Rủi ro mỗi Basket = 1% Equity tại thời điểm bắt đầu Basket.

Tại lúc khởi tạo Basket:
`BasketRiskBudget = EquityAtBasketStart * 0.01`

Nếu Equity là 500 USC:
`BasketRiskBudget = 5 USC`.

Lưu lại EquityAtBasketStart và BasketRiskBudget để Basket không thay đổi ngân sách tùy tiện khi Equity biến động. Có thể bổ sung tùy chọn dùng Balance thay cho Equity, mặc định dùng Equity.

## 6.3. Basket TP/SL cơ sở

| Tham số | Giá trị |
|---|---:|
| Basket TP | +1.50 USC |
| Basket SL | -5.00 USC |
| TP theo Balance 500 USC | +0.30% |
| SL theo Balance 500 USC | -1.00% |

P/L Basket phải là P/L ròng:
`NetBasketProfit = Sum(PositionProfit + PositionSwap) + realized deal costs attributable to the Basket`

MQL5 cần tính commission/fee từ deal history theo position identifier/deal liên quan. Không giả định commission luôn bằng 0 chỉ vì tài khoản Standard Cent thường được quảng bá không commission. Tester và broker specification phải xác nhận.

Điều kiện:
- Nếu NetBasketProfit >= BasketTP: yêu cầu đóng tất cả vị thế Basket.
- Nếu NetBasketProfit <= -BasketRiskBudget: yêu cầu đóng tất cả vị thế Basket.
- Sau khi đóng xong, xác nhận không còn position thuộc Basket.
- Nếu đóng một phần thất bại, tiếp tục retry có kiểm soát, ghi log và không đánh dấu Basket đã đóng.

**Tỷ lệ TP/SL cơ sở là 1.5/5 = 0.3.** Tỷ lệ thắng hòa vốn lý thuyết trước chi phí:
`5 / (5 + 1.5) = 76.92%`.
Đây không phải dự báo Win Rate. Phải kiểm tra expectancy sau chi phí. Backtest thêm TP 2.5 USC và 3.0 USC với SL 5 USC để so sánh.

## 6.4. Đóng Basket không phải lệnh đóng tức thời chắc chắn

EA phải:
- Gửi lệnh đóng từng position theo ticket.
- Kiểm tra retcode.
- Xử lý requote/price changed/market closed/no connection.
- Thử lại theo số lần và khoảng chờ có giới hạn.
- Kiểm tra position còn tồn tại sau mỗi lần đóng.
- Ghi lại P/L thực hiện cuối cùng.
- Không mở Basket mới cùng phía cho đến khi quá trình đóng Basket trước hoàn tất.

---

# 7. GLOBAL RISK MANAGER

Có hai Basket độc lập, mỗi Basket có thể có ngân sách 1% Equity. Nếu BUY và SELL cùng tồn tại, tổng ngân sách danh nghĩa tối đa có thể là 2% Equity. Đây là chủ ý của cấu hình “1% mỗi Basket”, không phải tổng rủi ro 1%.

Thông số ban đầu:
- Max loss per Basket: 1% Equity tại lúc Basket mở.
- Max combined floating loss: 10 USC tại Equity ban đầu 500 USC, tương đương 2%.
- Daily loss limit: 10 USC, tương đương 2% Balance ban đầu.
- Maximum account drawdown: 25 USC, tương đương 5% Balance ban đầu.

Các mức tiền cố định cần có input; nên có tùy chọn tính theo phần trăm Balance/Equity.

## 7.1. Global loss

Tính tổng P/L ròng thả nổi của cả hai Basket. Nếu tổng lỗ chạm giới hạn:
1. Ngừng mở lệnh mới.
2. Ngừng thêm tầng.
3. Đóng tất cả vị thế do EA quản lý trên symbol.
4. Chuyển EA sang trạng thái Global Lock.
5. Chỉ mở khóa theo chính sách được cấu hình (mặc định người dùng phải reset thủ công hoặc sang ngày giao dịch mới theo đúng loại khóa).

## 7.2. Daily loss

- Xác định ngày theo server time của broker.
- Lưu equity/balance đầu ngày.
- Tính realized P/L và floating P/L theo chính sách nhất quán.
- Khi chạm Daily Loss Limit: đóng vị thế EA, khóa mở lệnh đến ngày server tiếp theo.
- Không reset nhầm khi EA restart trong cùng ngày.

## 7.3. Equity drawdown

- Theo dõi Equity high-water mark kể từ khi EA bắt đầu hoặc từ mốc lưu bền vững.
- Nếu Equity giảm 25 USC so với mốc tham chiếu được cấu hình: đóng toàn bộ vị thế EA và khóa.
- Không tự xóa khóa sau khi restart.
- Ghi log lý do và thời điểm kích hoạt.

## 7.4. Lưu ý giới hạn rủi ro

Basket SL là cơ chế quản lý chủ động, không phải bảo đảm tuyệt đối. Gap, thanh khoản thấp, spread giãn, slippage, mất mạng, terminal/VPS dừng hoặc broker từ chối lệnh có thể khiến mức lỗ thực tế vượt ngưỡng. Cần có kiểm thử lỗi thực thi và không quảng cáo “maximum loss guaranteed”.

---

# 8. SPREAD, EXECUTION VÀ THỜI GIAN GIAO DỊCH

Input nghiên cứu:
- `MaxSpreadUSD = 0.30` (đơn vị chênh lệch giá Ask-Bid, không phải pip/point).
- `MaxSlippagePoints = 30` (phải được diễn giải theo `SYMBOL_POINT`).
- `CooldownSeconds = 60`.
- `UseNewBarOnly = true`.

`MaxSpreadUSD = 0.30` chỉ là ngưỡng khởi tạo để kiểm định, không được coi là spread Exness cố định. Backtest phải dùng tick Bid/Ask lịch sử thực tế. Tạo thống kê spread median, 90th, 95th và 99th percentile; chọn ngưỡng dựa trên phân phối thực tế.

Không mở Basket mới khi:
- Spread vượt ngưỡng.
- Thị trường đóng cửa.
- Dữ liệu indicator chưa đủ.
- ATR bất thường hoặc vượt ngưỡng cấu hình.
- Có lỗi đồng bộ position/deal.
- Đang trong thời gian rollover/khung giờ thanh khoản thấp được cấu hình.
- Có lịch tin tức rủi ro cao nếu Economic Calendar khả dụng và đã được kiểm thử.

News filter không được giả định hoạt động nếu Strategy Tester hoặc broker không cung cấp dữ liệu lịch tin. Phải có tùy chọn bật/tắt và log rõ.

---

# 9. INPUT PARAMETERS ĐỀ XUẤT CHO EA

```cpp
input group "01. GENERAL"
input string InpSymbol = "XAUUSDc";
input ENUM_TIMEFRAMES InpTF = PERIOD_M1;
input long MagicBuy = 10001;
input long MagicSell = 10002;
input bool AllowBuy = true;
input bool AllowSell = true;

input group "02. GRID"
input double InitialLot = 0.01;
input double LotMultiplier = 1.0;
input int MaxLayers = 5;
input double MaxSideLots = 0.05;
input int ATRPeriod = 14;
input double ATRMultiplier = 0.80;
input double MinGridUSD = 0.50;
input double MaxGridUSD = 1.50;
input double StressMoveATR = 1.0;

input group "03. ENTRY FILTER"
input int RSIPeriod = 7;
input double RSI_Buy = 25.0;
input double RSI_Sell = 75.0;
input int BBPeriod = 20;
input double BBDeviation = 2.0;
input int ADXPeriod = 14;
input double MaxADX = 22.0;

input group "04. BASKET MANAGEMENT"
input double BasketRiskPercent = 1.0;
input double BasketTP_USC = 1.50;
input double MaxCombinedLoss_USC = 10.00;
input bool UseBasketSLFromRiskBudget = true;

input group "05. ACCOUNT PROTECTION"
input double DailyLoss_USC = 10.00;
input double MaxEquityDD_USC = 25.00;
input bool CloseAllOnRiskLimit = true;
input bool BlockAfterDailyLoss = true;
input bool RequireHedgingAccount = true;

input group "06. EXECUTION"
input double MaxSpreadUSD = 0.30;
input int MaxSlippagePoints = 30;
input int CooldownSeconds = 60;
input bool UseNewBarOnly = true;
input int MaxCloseRetries = 5;

input group "07. DIAGNOSTICS"
input bool EnableCSVLog = true;
input bool EnableDetailedJournal = true;
input bool ShowDashboard = true;
```

AI lập trình phải được phép điều chỉnh cấu trúc input nếu cần, nhưng không được tự ý thay đổi chiến lược mà không ghi rõ.

---

# 10. KIẾN TRÚC MQL5

Tách code thành các module/hàm có trách nhiệm rõ ràng:

1. `ValidateEnvironment()`
   - Xác thực symbol, account currency, account mode, volume rules và contract specs.
2. `InitIndicators()`
   - Tạo handle BB, RSI, ADX, ATR.
3. `IsNewBar()`
   - Kiểm soát xử lý theo nến M1 mới.
4. `GetMarketRegime()`
   - Đọc ADX, ATR và trạng thái spread.
5. `CheckBuySignal()`
   - Tạo tín hiệu BUY bằng nến đã đóng.
6. `CheckSellSignal()`
   - Tạo tín hiệu SELL bằng nến đã đóng.
7. `CalculateGridDistance()`
   - Tính ATR spacing, clamp và normalize theo tick size.
8. `ManageBuyBasket()`
   - Đếm lệnh, kiểm tra tầng, thêm BUY và quản lý Basket.
9. `ManageSellBasket()`
   - Đếm lệnh, kiểm tra tầng, thêm SELL và quản lý Basket.
10. `CalculateBasketNetProfit()`
    - Tính P/L ròng của đúng Basket.
11. `EstimateWorstCaseRisk()`
    - Ước tính rủi ro các vị thế hiện có và lệnh mới tại mức stress.
12. `CheckGlobalRisk()`
    - Daily loss, combined loss, equity drawdown.
13. `ExecuteOrderSafely()`
    - Kiểm tra margin, volume, price, spread, retcode.
14. `CloseBasketSafely()`
    - Đóng theo ticket, xác nhận kết quả và retry.
15. `RecoverStateAfterRestart()`
    - Khôi phục Basket, mốc risk, khóa và trạng thái từ positions/history/persistent storage.
16. `WriteCSVLog()`
    - Ghi sự kiện, lệnh, spread, ATR, ADX, P/L và lý do bỏ qua lệnh.

Có thể dùng class/module hoặc các file `.mqh` riêng. Không bắt buộc một file duy nhất, nhưng phải bàn giao đầy đủ source và hướng dẫn biên dịch.

---

# 11. QUẢN LÝ TRẠNG THÁI VÀ KHÔI PHỤC SAU RESTART

EA phải hoạt động đúng sau:
- MT5 đóng/mở lại.
- VPS restart.
- Mất mạng tạm thời.
- EA bị remove rồi gắn lại.
- Có position đang mở từ trước khi EA restart.

Yêu cầu:
- Xác định vị thế EA theo symbol + magic + type.
- Tái dựng số tầng và giá khớp gần nhất từ positions.
- Khôi phục thời điểm bắt đầu Basket và ngân sách rủi ro từ Global Variables hoặc file state có version.
- Nếu không thể xác định an toàn trạng thái Basket, chuyển sang SAFE MODE: không mở lệnh mới, tiếp tục giám sát/đóng lệnh theo risk nếu đủ dữ liệu, ghi log và yêu cầu can thiệp.
- Không được xóa khóa rủi ro khi restart.
- Không được mở Basket mới trùng lặp do mất trạng thái.

---

# 12. BACKTEST VÀ VALIDATION

## 12.1. Strategy Tester

| Thiết lập | Giá trị |
|---|---|
| Expert | XAUUSDc_AdaptiveGrid |
| Symbol | XAUUSDc |
| Period | M1 |
| Model | Every tick based on real ticks |
| Deposit | 500 USC |
| Deposit currency | USC, phải xác nhận trong tester |
| Leverage | Theo tài khoản thật |
| Optimization | Tắt ở vòng baseline |
| Forward | 30% cuối dữ liệu hoặc giai đoạn riêng |
| Execution delay | Kiểm tra cả delay thực tế và random delay |
| Visual mode | Bật khi debug logic |

Không dùng “Open prices only” cho chiến lược Grid M1 vì thứ tự tick, spread và kích hoạt tầng rất quan trọng.

## 12.2. Phân đoạn dữ liệu

Mục tiêu nếu dữ liệu đủ:
- In-sample: 60%.
- Validation: 20%.
- Out-of-sample: 20%.

Ưu tiên dữ liệu tick Bid/Ask chất lượng cao. Ghi rõ nguồn dữ liệu, timezone, missing ticks và khác biệt giữa tester với môi trường broker live.

## 12.3. Ma trận tham số nghiên cứu

Không tối ưu tất cả tham số cùng lúc.

| Tham số | Giá trị thử |
|---|---|
| ATR multiplier | 0.6 / 0.8 / 1.0 / 1.2 |
| Min grid USD | 0.3 / 0.5 / 0.7 |
| Max layers | 3 / 4 / 5 |
| RSI BUY | 20 / 25 / 30 |
| RSI SELL | 70 / 75 / 80 |
| Max ADX | 18 / 22 / 25 |
| Basket TP USC | 1.5 / 2.5 / 3.0 |
| Basket SL | Theo risk budget 5 USC ở Balance 500 |

Không chọn bộ tham số chỉ vì Net Profit cao nhất. Ưu tiên độ ổn định trên nhiều giai đoạn, drawdown thấp và out-of-sample không suy giảm nghiêm trọng.

## 12.4. Chỉ số phải xuất

- Net Profit.
- Gross Profit / Gross Loss.
- Profit Factor.
- Expected Payoff.
- Win Rate theo Basket.
- Số Basket BUY/SELL.
- Average win / average loss.
- Maximum Balance Drawdown.
- Maximum Equity Drawdown.
- Recovery Factor.
- Largest Basket Loss.
- Average/maximum Basket duration.
- Maximum number of layers reached.
- Spread trung bình và percentile.
- Commission, swap, slippage.
- Số lần chạm Basket SL.
- Số lần chạm Global Stop.
- Margin level thấp nhất.
- Kết quả tách riêng BUY, SELL và combined.

Phải phân biệt kết quả theo lệnh với kết quả theo Basket. Không chỉ báo cáo Win Rate.

## 12.5. Stress tests bắt buộc

1. Spread × 1.5.
2. Spread × 2.0.
3. Slippage tăng và execution delay.
4. Giá chạy một chiều 10–20 USD không hồi.
5. ATR tăng đột biến.
6. Tin tức mạnh/giãn spread.
7. Mất kết nối khi Basket đang mở.
8. EA/terminal restart khi đang có nhiều tầng.
9. Đóng một phần thất bại.
10. BUY và SELL cùng tồn tại, kiểm tra combined risk.

## 12.6. Monte Carlo và Walk-forward

- Monte Carlo tối thiểu 1,000 lần nếu có đủ dữ liệu Basket.
- Resample theo Basket hoặc chuỗi trade có bảo toàn phụ thuộc thời gian ở mức phù hợp; không xáo trộn từng lệnh một cách ngây thơ nếu nhiều lệnh thuộc cùng Basket.
- Kiểm tra phân phối drawdown, chuỗi thua, nguy cơ chạm equity stop và độ nhạy tham số.
- Walk-forward với các cửa sổ huấn luyện/kiểm tra tách biệt.
- Không dùng dữ liệu out-of-sample để tiếp tục chỉnh tham số rồi vẫn gọi đó là out-of-sample.

---

# 13. TIÊU CHUẨN NGHIỆM THU

Đây là ngưỡng mục tiêu nghiên cứu, không phải cam kết hiệu suất:

| Chỉ số | Ngưỡng tham khảo |
|---|---:|
| Profit Factor | >= 1.20 |
| Expectancy sau chi phí | > 0 |
| Maximum Equity DD | <= 5% mục tiêu |
| Recovery Factor | >= 2 mục tiêu |
| Out-of-sample expectancy | > 0 |
| Global risk control | Hoạt động đúng |
| Duplicate order | 0 |
| Unauthorized position close | 0 |
| Martingale/lot escalation | 0 |
| Restart recovery | Pass |
| Failed close handling | Pass |

Nếu không đạt, kết luận là chưa đạt điều kiện triển khai. Không được che giấu kết quả âm hoặc điều chỉnh dữ liệu để tạo báo cáo đẹp.

---

# 14. CÁC RỦI RO VÀ GIỚI HẠN

1. Grid có rủi ro đuôi lớn: nhiều Basket thắng nhỏ có thể bị xóa bởi một xu hướng mạnh.
2. Basket SL bằng phần mềm không bảo đảm mức lỗ chính xác trong gap, slippage, mất mạng hoặc broker từ chối lệnh.
3. TP 1.5 USC so với SL 5 USC yêu cầu win rate hòa vốn khoảng 76.92% trước chi phí.
4. Vốn 500 USC tương đương 5 USD rất nhỏ; chi phí spread có thể chiếm tỷ trọng đáng kể.
5. Khối lượng tối thiểu 0.01 cent lot có thể khiến rủi ro tối thiểu đã quá lớn so với 5 USC. Khi đó EA phải không giao dịch.
6. BUY và SELL cùng hoạt động có thể khiến tổng rủi ro lên 2% Equity theo cấu hình mỗi Basket 1%.
7. Dữ liệu Strategy Tester có thể khác spread, swap, execution và contract specification live.
8. Không dùng EA live chỉ dựa vào một giai đoạn backtest đẹp.

---

# 15. YÊU CẦU ĐẦU RA TỪ AI LẬP TRÌNH

AI được giao nhiệm vụ phải bàn giao:

1. Source code `.mq5` và toàn bộ `.mqh` cần thiết.
2. File `.set` cấu hình mặc định.
3. Hướng dẫn cài đặt EA vào MT5.
4. Hướng dẫn chọn symbol XAUUSDc và timeframe M1.
5. Hướng dẫn Strategy Tester từng bước.
6. Báo cáo kiểm tra compile, nêu rõ warning/error.
7. Báo cáo unit test cho:
   - Volume normalization.
   - Grid spacing.
   - Basket P/L.
   - Basket risk budget.
   - Combined risk.
   - Daily loss.
   - Equity drawdown.
   - Restart recovery.
   - Retry close.
8. File CSV log mẫu.
9. Báo cáo backtest chỉ khi thực sự đã chạy bằng dữ liệu được nêu rõ. Nếu AI không có MT5/tick data thì phải nói chưa chạy được; không được bịa kết quả.
10. Danh sách giả định, giới hạn và các thông số cần người dùng xác minh trên MT5.

---

# 16. PROMPT GỐC ĐỂ GIAO CHO AI TẠO EA

Bạn là Senior MQL5 Developer, Quantitative Trading System Architect và chuyên gia kiểm thử EA trên MetaTrader 5.

Hãy phát triển một Expert Advisor hoàn chỉnh theo đúng tài liệu đặc tả này cho Exness Standard Cent, symbol XAUUSDc, timeframe M1, balance thử nghiệm 500 USC.

Yêu cầu bắt buộc:

- Đọc và tuân thủ toàn bộ đặc tả, không tự ý bỏ qua điều kiện rủi ro.
- Trước tiên, hãy phân tích đặc tả và liệt kê các điểm mơ hồ/mâu thuẫn cần giải quyết. Không tự bịa contract size, tick value, volume step hoặc quy đổi USC.
- Sau khi thống nhất giả định, thiết kế state machine và kiến trúc module.
- Viết source MQL5 có thể compile, có xử lý lỗi và log rõ ràng.
- BUY và SELL Basket độc lập bằng Magic Number riêng; bắt buộc kiểm tra tài khoản Hedging.
- Không Martingale, không tăng lot, không Grid vô hạn.
- Trước mỗi lệnh phải kiểm tra volume, margin, spread và rủi ro dự kiến của toàn Basket.
- Dùng OrderCalcProfit và symbol specification để tính P/L/risk; xác minh đơn vị tiền tài khoản là USC.
- Quản lý Basket TP/SL theo P/L ròng, xử lý đóng lệnh thất bại và restart recovery.
- Không mở thêm tầng khi rủi ro dự kiến vượt ngân sách.
- Không tuyên bố giới hạn lỗ tuyệt đối được bảo đảm trong mọi điều kiện thị trường.
- Không giả vờ đã backtest nếu không có MetaTrader 5 và dữ liệu tick phù hợp.
- Viết test plan và hướng dẫn người dùng tự chạy Strategy Tester.

Quy trình bàn giao theo từng giai đoạn:
A. Phân tích yêu cầu và các giả định.
B. Thiết kế state machine, luồng xử lý và risk model.
C. Viết code.
D. Tự rà soát lỗi logic, lỗi MQL5 và tình huống biên.
E. Cung cấp source đầy đủ.
F. Cung cấp hướng dẫn compile, cài đặt và backtest.
G. Đưa ra checklist nghiệm thu.

Nếu có điểm nào không thể triển khai đúng trong MT5, hãy giải thích và đề xuất phương án thay thế an toàn. Không được âm thầm thay đổi chiến lược.

**Mục tiêu cuối cùng:** một EA có logic minh bạch, có thể compile, có thể backtest tái lập, có cơ chế bảo vệ vốn và có thể tiếp tục phát triển bằng dữ liệu thực nghiệm. Không có yêu cầu hoặc cam kết lợi nhuận.

---

# 17. NGUỒN THAM KHẢO VÀ VIỆC PHẢI XÁC MINH

Nguồn tham khảo chính thức:
- Exness Help Center – Standard Cent account: https://get.exness.help/hc/en-us/articles/17537782786588-Standard-Cent-account
- Exness Help Center – Commodities: https://get.exness.help/hc/en-us/articles/17854173039388-Commodities

Các thông tin công khai có thể thay đổi theo pháp nhân, máy chủ, tài khoản và thời điểm. Trước khi chạy EA, đối chiếu trực tiếp tab Specification của `XAUUSDc` trong MT5 và xác nhận:
- Contract size.
- Minimum volume / volume step.
- Tick size / tick value.
- Spread và trading hours.
- Swap.
- Account currency.
- Hedging mode.
- Margin requirement.

**Kết luận:** Đây là bản đặc tả để AI xây dựng và kiểm định EA, không phải bằng chứng chiến lược có lợi nhuận. Với balance 500 USC, điều kiện quan trọng nhất là EA phải từ chối lệnh khi không thể giữ rủi ro trong ngân sách; không được cố giao dịch chỉ để tạo tần suất lệnh.
