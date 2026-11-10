# MASTER PROMPT — XAUUSDc Adaptive Mean-Reversion Grid EA (MT5 / MQL5)

> **Cách sử dụng:** Dán toàn bộ tài liệu này vào Claude, đồng thời đính kèm `EA_XAUUSDc_Adaptive_Grid_M1_Specification.md` (đặc tả nguồn). Yêu cầu Claude coi đặc tả nguồn là tài liệu yêu cầu chuẩn; prompt này quy định cách phân tích, triển khai, kiểm thử và bàn giao.
>
> **Mục tiêu:** xây dựng EA có logic minh bạch, kiểm soát rủi ro nghiêm ngặt và có thể kiểm chứng. Đây không phải yêu cầu bảo đảm lợi nhuận hay bảo đảm mức lỗ tuyệt đối.

---

## 1. Claude Model Recommendation

**Khuyến nghị:** dùng phiên bản Claude Opus mới nhất đang khả dụng cho giai đoạn phân tích kiến trúc, mô hình rủi ro, triển khai MQL5 và rà soát mã nguồn. Công việc có nhiều trạng thái giao dịch, tương tác với đặc tả broker và các tình huống lỗi có hậu quả tài chính; độ chính xác quan trọng hơn tốc độ.

**Phương án thay thế:** Claude Sonnet mới nhất nếu cần triển khai theo từng module hoặc giới hạn chi phí. Với Sonnet, chia công việc thành các giai đoạn nhỏ, yêu cầu kiểm tra chéo sau mỗi giai đoạn. Không dùng Haiku làm mô hình duy nhất để thiết kế hoặc nghiệm thu toàn bộ EA; có thể dùng cho tác vụ phụ trợ đơn giản như định dạng log hoặc tài liệu.

Không giả định một model ID cụ thể luôn tồn tại. Hãy chọn model Claude mới nhất thuộc dòng được khuyến nghị trong giao diện hoặc API tại thời điểm thực hiện.

## 2. Reasoning Configuration

- Ưu tiên chế độ suy luận sâu nhất mà phiên bản Claude đang sử dụng thực sự hỗ trợ cho các phần: phân tích đặc tả, thiết kế risk engine, xử lý trạng thái, concurrency/order execution và code review.
- Nếu giao diện/API có **Adaptive Thinking**, bật cho các tác vụ phức tạp và để hệ thống tự phân bổ nỗ lực.
- Nếu không có Adaptive Thinking nhưng có **Extended Thinking**, sử dụng mức effort/budget cao phù hợp với giới hạn thực tế của phiên bản đó.
- Nếu không có các chế độ trên, làm việc theo quy trình nhiều lượt, mỗi lượt có đầu vào/đầu ra và checklist xác minh rõ ràng.
- Không tự đặt tham số API, tên tính năng hoặc mức token không được phiên bản hiện tại hỗ trợ.
- Không yêu cầu hoặc tiết lộ chain of thought. Chỉ trình bày kết luận kỹ thuật, giả định, căn cứ, phép tính có thể kiểm tra, các rủi ro và tóm tắt quy trình xác minh.

---

## 3. Role & Context

Bạn là một nhóm chuyên gia kỹ thuật tích hợp trong một vai trò duy nhất:

1. **Senior MQL5 Developer:** thành thạo MetaTrader 5, MQL5 Standard Library, `CTrade`, position/deal/order APIs, Strategy Tester, event handlers và quản lý tài nguyên indicator.
2. **Quantitative Trading System Architect:** hiểu mean reversion, grid execution, market regime filters, expectancy, drawdown, overfitting, walk-forward và Monte Carlo.
3. **Risk Engineer:** thiết kế giới hạn rủi ro theo Basket và toàn tài khoản, stress testing, fail-safe, recovery và kiểm soát lỗi thực thi.
4. **QA / Code Reviewer:** rà soát compile correctness, logic, state transitions, dữ liệu lịch sử, tình huống biên và khả năng tái lập kiểm thử.

### Bối cảnh dự án

Phát triển Expert Advisor cho:

- Broker dự kiến: Exness.
- Loại tài khoản: Standard Cent.
- Nền tảng: MetaTrader 5.
- Symbol yêu cầu: `XAUUSDc` — không tự đổi tên symbol.
- Timeframe tín hiệu: M1.
- Balance thử nghiệm tham chiếu: 500 USC (quy đổi tham khảo 5 USD; phải xác minh currency thực tế).
- Chiến lược: Adaptive Mean-Reversion Grid.
- Hai cụm độc lập: BUY Basket và SELL Basket.
- Nguyên tắc ưu tiên: **bảo toàn vốn > kiểm soát drawdown > chất lượng thực thi > lợi nhuận**.

Tài liệu đặc tả đi kèm có tên `EA_XAUUSDc_Adaptive_Grid_M1_Specification.md`. Hãy đọc toàn bộ trước khi đề xuất hoặc viết code. Không coi các tham số nghiên cứu ban đầu là tham số đã tối ưu hoặc đã chứng minh có lợi nhuận.

---

## 4. Objectives

Tạo một EA MQL5 hoàn chỉnh, có thể biên dịch và kiểm thử, đáp ứng các mục tiêu:

1. Triển khai đúng chiến lược và các tham số mặc định trong đặc tả.
2. Quản lý BUY và SELL độc lập bằng Magic Number riêng; chỉ chạy trên tài khoản Hedging.
3. Chỉ dùng nến đã đóng để xác nhận tín hiệu.
4. Dùng ATR để tính khoảng cách Grid động, có giới hạn min/max và chuẩn hóa theo tick size.
5. Không Martingale, không tăng lot, không mở Grid vô hạn.
6. Kiểm tra volume, margin, spread, trạng thái giao dịch và rủi ro dự kiến trước mọi lệnh mới.
7. Quản lý Basket TP/SL theo P/L ròng, có tính phí liên quan và xử lý đóng lệnh thất bại.
8. Có Global Risk Manager, Daily Loss Lock, Equity Drawdown Lock và cơ chế lưu/khôi phục trạng thái.
9. Có log đủ chi tiết để giải thích vì sao EA vào lệnh, bỏ qua lệnh, thêm tầng, đóng Basket hoặc kích hoạt khóa.
10. Có test plan và báo cáo trung thực. Không tuyên bố compile/backtest/pass test nếu chưa thực sự thực hiện.

---

## 5. Source of Truth & Priority Rules

### 5.1. Thứ tự ưu tiên

Khi triển khai, áp dụng thứ tự sau:

1. Các nguyên tắc an toàn và cấm giao dịch trong prompt này.
2. Yêu cầu bắt buộc và thông số trong đặc tả nguồn.
3. Các giả định đã được người dùng xác nhận.
4. Giả định kỹ thuật do bạn đề xuất và công khai.
5. Không tự dùng kiến thức chung để âm thầm thay đổi chiến lược.

Nếu phát hiện mâu thuẫn giữa các mục, hãy ghi rõ mục liên quan, tác động và phương án giải quyết. Không âm thầm chọn một cách hiểu.

### 5.2. Những gì tuyệt đối không được thay đổi nếu chưa được chấp thuận

- Symbol mặc định `XAUUSDc`.
- Timeframe tín hiệu M1.
- BB(20, 2.0), RSI(7), ADX(14), ATR(14).
- BUY: ADX < 22, RSI <= 25 theo đúng nến được thống nhất, setup close dưới Lower Band, nến xác nhận đóng trở lại bên trong Bands.
- SELL đối xứng: ADX < 22, RSI >= 75, setup close trên Upper Band, nến xác nhận đóng trở lại bên trong Bands.
- Grid distance = `clamp(ATR(14) * 0.80, 0.50 USD, 1.50 USD)`.
- Initial lot 0.01 cent lot; LotMultiplier = 1.0.
- Tối đa 5 tầng mỗi phía và tổng volume mỗi phía không quá 0.05 cent lot, đồng thời phải qua risk check.
- Ngân sách rủi ro mục tiêu mỗi Basket = 1% Equity tại thời điểm khởi tạo Basket.
- Basket TP mặc định 1.50 USC; Basket SL theo risk budget khi tùy chọn tương ứng bật.
- Max combined floating loss 10 USC; Daily loss limit 10 USC; Max equity DD 25 USC theo cấu hình tham chiếu.
- Không Martingale, không tăng volume để gỡ lỗ, không Grid vô hạn.
- Không can thiệp position thủ công hoặc position của EA khác.

Mọi thay đổi chiến lược phải được trình bày thành đề xuất riêng, nêu lý do và tác động; mặc định không triển khai thay đổi đó.

---

## 6. Execution Instructions

Thực hiện theo các phase dưới đây. Không nhảy thẳng vào viết toàn bộ code khi chưa hoàn thành phân tích và thiết kế.

### PHASE 0 — Đọc đặc tả và lập Requirement Traceability

1. Đọc toàn bộ file đặc tả, không chỉ phần prompt gốc ở cuối tài liệu.
2. Tóm tắt yêu cầu thành bảng:
   - ID.
   - Yêu cầu.
   - Loại: bắt buộc / mặc định / tùy chọn / giả định.
   - Module chịu trách nhiệm.
   - Cách kiểm chứng.
3. Liệt kê các điều kiện cấm giao dịch và điều kiện phải chuyển sang SAFE MODE.
4. Xác định dữ liệu MT5/broker cần đọc runtime.
5. Không tự điền giá trị cho các thông số chưa được xác minh từ symbol/account.

### PHASE 1 — Phân tích điểm mơ hồ, mâu thuẫn và rủi ro

Trước khi code, lập bảng gồm: vấn đề, nội dung liên quan, các cách hiểu, rủi ro nếu chọn sai, đề xuất mặc định an toàn và có cần người dùng xác nhận hay không.

Tối thiểu phải phân tích các vấn đề sau:

1. **Nến setup/confirmation và RSI shift:** Đặc tả yêu cầu hai nến đã đóng riêng biệt nhưng diễn đạt RSI là “tại nến trước khi xác nhận”. Hãy đề xuất mapping shift cụ thể, ví dụ setup candle và confirmation candle, xác định RSI/ADX/BB lấy ở shift nào. Mặc định không dùng cùng một nến vừa xuyên band vừa xác nhận quay vào band.
2. **ADX trong khi Basket đang mở:** ADX >= MaxADX chặn khởi tạo Basket mới và mặc định chặn thêm tầng; vẫn tiếp tục quản lý TP/SL. Đảm bảo code không vô tình ngừng quản lý Basket.
3. **Basket risk budget so với fixed TP/SL:** `BasketRiskBudget = EquityAtBasketStart * 1%`; Basket SL có thể dùng budget này, trong khi TP mặc định là 1.50 USC. Xác định rõ precedence của `UseBasketSLFromRiskBudget` và hành vi nếu input cố định mâu thuẫn với budget.
4. **Risk model trước khi thêm tầng:** xác định mức giá stress cho từng vị thế và lệnh mới, cách tính P/L bằng `OrderCalcProfit()`, spread, commission, swap và slippage buffer. Nêu rõ giả định về giá stress và cách tránh tính trùng chi phí.
5. **Minimum volume vs risk budget:** nếu volume tối thiểu của symbol khiến mức rủi ro stress vượt ngân sách, EA phải từ chối giao dịch; tuyệt đối không tự tăng lot để đạt min volume rồi bỏ qua risk limit.
6. **Currency và cent conversion:** không mặc định `OrderCalcProfit()` trả về USC theo một quy ước cụ thể. Phải xác định `ACCOUNT_CURRENCY`, cách broker thể hiện cent account và đơn vị của mọi ngưỡng tiền.
7. **Commission/fees attribution:** xác định cách gắn deal history với position identifier/Basket, gồm cả phí vào và ra, swap, commission và fee. Không giả định commission bằng 0.
8. **Daily loss:** làm rõ công thức gồm realized P/L, floating P/L, phí và tiền nạp/rút (nếu có); xác định mốc đầu ngày theo server time và cách lưu qua restart.
9. **Equity drawdown:** đặc tả nói high-water mark nhưng cũng nói giảm 25 USC so với mốc tham chiếu. Đề xuất lựa chọn rõ giữa high-water mark, initial equity hoặc mốc cấu hình; không trộn các cách tính.
10. **Global combined loss:** xác định phạm vi gồm floating loss của hai Basket, chi phí và realized loss hay không. Phân biệt với Daily Loss và Equity DD để tránh bỏ sót hoặc đếm trùng.
11. **Lock policy:** phân biệt Global Lock, Daily Lock và Equity Lock; điều kiện mở khóa, reset theo ngày server, reset thủ công và persistence sau restart.
12. **Restart recovery:** nếu không thể khôi phục chính xác thời điểm mở Basket, equity gốc, budget, lock state hoặc lịch sử phí, phải SAFE MODE và không mở lệnh mới.
13. **Đóng Basket nhiều lần:** thiết kế trạng thái CLOSING, retry có giới hạn, xác nhận position đã biến mất và chống gửi lệnh đóng trùng.
14. **Hai Basket đồng thời:** kiểm tra combined risk trước khi mở/thêm tầng ở một phía khi phía kia đang tồn tại.
15. **New bar/cooldown:** quy định rõ cooldown áp dụng cho lệnh đầu, lệnh thêm tầng hay cả hai; chống mở nhiều lệnh trên cùng một nến kể cả khi có nhiều tick hoặc restart.
16. **ATR và grid distance:** xác định ATR shift đã đóng, đơn vị giá, tick-size rounding và cách xử lý dữ liệu bất thường/zero.
17. **Rollover/news filter:** nếu không có dữ liệu lịch tin khả dụng, không giả định filter hoạt động. News filter phải có trạng thái/log minh bạch.
18. **MaxSpreadUSD:** đây là Ask-Bid theo đơn vị giá, không phải pip/point. Chuẩn hóa và log cả giá trị raw lẫn point-equivalent.
19. **Hedging/netting:** kiểm tra `ACCOUNT_MARGIN_MODE`; Netting phải `INIT_FAILED`, không mô phỏng Hedging.
20. **Broker execution:** xử lý retcode, requote, price changed, market closed, no connection, invalid volume/stops, insufficient margin và partial close.

Nếu một điểm ảnh hưởng trực tiếp đến an toàn tiền thật mà không thể giải quyết bằng lựa chọn cấu hình rõ ràng, hãy dừng tại Phase 1 và hỏi người dùng câu hỏi ngắn, chỉ hỏi những gì thực sự cần. Không hỏi lại các thông tin đã có trong đặc tả. Với vấn đề không phải blocker, đề xuất safe default, ghi rõ và tiếp tục sau khi người dùng chấp thuận hoặc theo cơ chế giả định được cho phép.

### PHASE 2 — Thiết kế kiến trúc và state machine

Trước khi code, cung cấp:

1. Sơ đồ module và trách nhiệm.
2. State machine cho từng Basket, tối thiểu gồm:
   - `IDLE`
   - `ENTRY_PENDING`
   - `ACTIVE`
   - `ADD_PENDING`
   - `CLOSING`
   - `RECOVERY`
   - `SAFE_MODE`
3. State machine cho các khóa:
   - `NORMAL`
   - `DAILY_LOCK`
   - `GLOBAL_LOCK`
   - `EQUITY_LOCK`
4. Sơ đồ luồng xử lý `OnInit`, `OnDeinit`, `OnTick`, `OnTradeTransaction` và xử lý nến mới.
5. Quy tắc đồng bộ giữa positions, orders, deals, local state và persistent storage.
6. Quy tắc ưu tiên khi nhiều điều kiện xảy ra cùng lúc. Risk lock/close phải có ưu tiên cao hơn entry/grid.
7. Bảng dữ liệu cần lưu bền vững, version schema và cách xử lý state file lỗi/hỏng.

Kiến trúc gợi ý, có thể điều chỉnh nếu giải thích được lý do:

- `ValidateEnvironment()`
- `InitIndicators()`
- `IsNewBar()`
- `GetMarketRegime()`
- `CheckBuySignal()`
- `CheckSellSignal()`
- `CalculateGridDistance()`
- `ManageBuyBasket()`
- `ManageSellBasket()`
- `CalculateBasketNetProfit()`
- `EstimateWorstCaseRisk()`
- `CheckGlobalRisk()`
- `ExecuteOrderSafely()`
- `CloseBasketSafely()`
- `RecoverStateAfterRestart()`
- `WriteCSVLog()`

### PHASE 3 — Thiết kế công thức và đơn vị

Trình bày công thức trước khi lập trình:

**Grid spacing**

`GridDistance = clamp(ATR(14) * ATRMultiplier, MinGridUSD, MaxGridUSD)`

- ATR dùng dữ liệu M1 đã đóng.
- Đơn vị ATR và grid là đơn vị giá của symbol.
- Chuẩn hóa theo `SYMBOL_TRADE_TICK_SIZE`, không nhầm pip, point, digits và USD giá.

**Basket risk**

`BasketRiskBudget = EquityAtBasketStart * BasketRiskPercent / 100`

- Lưu snapshot lúc Basket bắt đầu.
- Không tự tăng budget khi equity tăng hoặc thay đổi budget của Basket đang chạy.
- Nếu không thể xác định budget sau restart, SAFE MODE.

**Basket net P/L**

Tính đúng các vị thế thuộc symbol + magic + hướng tương ứng. Công thức phải tính được floating profit, swap và realized deal costs có thể quy thuộc cho Basket. Giải thích cách tránh double-count commission hoặc phí đã được phản ánh trong deal history.

**Risk estimate**

- Dùng `OrderCalcProfit()` cho từng position và lệnh dự kiến.
- Tính tại mức giá stress bất lợi, không chỉ giá hiện tại.
- Bao gồm chi phí còn thiếu, spread/slippage buffer và swap/commission theo mô hình được công khai.
- Không coi Basket SL phần mềm là bảo đảm mức lỗ tối đa.
- Tính cả combined risk của BUY và SELL trước mọi lệnh mới.
- Nếu dữ liệu đầu vào thiếu hoặc phép tính không đáng tin cậy, từ chối lệnh.

Mọi công thức phải nêu rõ đơn vị, dấu (+/-), nguồn dữ liệu và ví dụ số học. Không suy đoán giá trị tiền tệ từ số lot nếu chưa đọc symbol/account specification.

### PHASE 4 — Implement EA

Viết MQL5 theo hướng:

- Dễ đọc, module hóa, tên biến/hàm rõ nghĩa.
- Dùng API MQL5 đúng chuẩn; không chuyển máy móc cú pháp MQL4.
- Dùng `CTrade` hoặc lớp giao dịch phù hợp, nhưng phải kiểm tra retcode và trạng thái thực tế sau request.
- Indicator handles phải được tạo, kiểm tra `INVALID_HANDLE`, đọc bằng `CopyBuffer()` và giải phóng đúng cách.
- Không dùng dữ liệu nến đang chạy để xác nhận tín hiệu.
- Không hard-code contract size, tick value, point, digits, volume min/max/step.
- Không dùng số lượng position đơn thuần để suy ra Basket nếu chưa lọc symbol, magic và position type.
- Không tác động đến lệnh thủ công hoặc EA khác.
- Chống duplicate order bằng state/pending guard, kiểm tra position/deal thực tế và kiểm soát theo bar.
- Kiểm tra margin bằng API phù hợp trước khi gửi lệnh.
- Normalize volume theo min/max/step; nếu volume tối thiểu không phù hợp risk budget thì skip và log.
- Chuẩn hóa giá theo tick size hợp lệ.
- Không gửi thêm lệnh khi đang có request chưa hoàn tất.
- Mọi đường đi lỗi phải có log và fail-safe.

### PHASE 5 — Basket Manager & Safe Execution

Đối với BUY/SELL:

1. Quản lý riêng Magic Number (mặc định BUY 10001, SELL 10002).
2. Chỉ quản lý position thuộc đúng symbol + magic + type.
3. Dùng giá khớp thực tế của lệnh gần nhất để xác định grid level kế tiếp.
4. BUY add khi `Bid <= LastBuyOpenPrice - GridDistance`.
5. SELL add khi `Ask >= LastSellOpenPrice + GridDistance`.
6. Tối đa một lệnh mới mỗi nến M1 và tuân thủ cooldown.
7. Không thêm tầng khi ADX >= MaxADX, spread cao, risk limit bị chạm, margin thiếu, volume vượt giới hạn hoặc trade operation đang pending.
8. Không bao giờ vượt MaxLayers hoặc MaxSideLots.
9. Basket đạt TP/SL thì chuyển sang `CLOSING`, đóng từng position theo ticket.
10. Kiểm tra retcode, xác nhận position còn hay mất, retry có giới hạn, log P/L cuối cùng.
11. Nếu một phần đóng thất bại, tiếp tục quản lý trạng thái CLOSING; không báo Basket đã đóng và không mở Basket mới cùng phía.
12. Nếu terminal mất kết nối, giữ trạng thái đủ để tiếp tục recovery khi kết nối lại.

### PHASE 6 — Global Risk & Recovery

Phải triển khai và kiểm tra:

- Max loss per Basket.
- Max combined floating loss.
- Daily loss limit theo server day.
- Maximum account equity drawdown.
- Global Lock, Daily Lock, Equity Lock.
- Đóng toàn bộ position do EA quản lý theo đúng phạm vi được cấu hình.
- Persist lock state qua restart.
- Không reset lock chỉ vì EA/terminal restart.
- Daily lock chỉ reset khi sang ngày server tiếp theo và điều kiện reset hợp lệ.
- Equity/global lock cần chính sách reset rõ ràng; mặc định yêu cầu reset thủ công nếu đặc tả không xác định khác.
- Recovery phải đối chiếu positions, deals, state storage và lock state.
- Nếu dữ liệu không nhất quán: SAFE MODE, không mở lệnh mới, tiếp tục giám sát và chỉ đóng khi có đủ dữ liệu an toàn.

### PHASE 7 — Logging & Dashboard

Tối thiểu CSV log phải có timestamp server, event, symbol, magic, basket ID, side, bar time, bid, ask, spread, ATR, ADX, RSI, BB values, layer count, volume, grid distance, Basket P/L, risk budget, stress risk, retcode và reason.

Ghi rõ cả:
- Lệnh được mở.
- Lệnh bị từ chối và lý do cụ thể.
- Tầng Grid bị bỏ qua.
- Basket bắt đầu/kết thúc.
- TP/SL/risk lock kích hoạt.
- Close retry và lỗi.
- Restart recovery và SAFE MODE.
- Symbol/account validation.
- Các input đang sử dụng.

Dashboard không được hiển thị giá trị giả định như giá trị đã xác minh. Phân biệt rõ `VALID`, `INVALID`, `UNKNOWN` cho các kiểm tra môi trường.

### PHASE 8 — Test, Backtest & Validation

Tạo test plan trước khi tuyên bố hoàn thành.

**Unit tests / logic tests tối thiểu:**

- Volume normalization.
- Price/tick-size normalization.
- Grid spacing và clamp.
- Candle shift/setup-confirmation.
- BUY/SELL signal symmetry.
- Basket P/L và fee attribution.
- Basket risk budget.
- Stress loss cho position hiện tại + lệnh mới.
- Combined risk hai phía.
- Max layers / MaxSideLots.
- Spread filter.
- ADX regime.
- Cooldown và one-order-per-bar.
- Daily loss.
- Equity drawdown.
- Lock persistence.
- Restart recovery.
- Close retry/partial close.
- Không đóng position ngoài phạm vi.
- Không duplicate order.

**Strategy Tester baseline:**

- Expert: `XAUUSDc_AdaptiveGrid`.
- Symbol: `XAUUSDc`.
- Period: M1.
- Model: Every tick based on real ticks.
- Deposit: 500 USC, xác minh currency trong tester.
- Leverage: theo tài khoản thật.
- Optimization: OFF cho baseline.
- Forward: 30% cuối dữ liệu hoặc giai đoạn riêng.
- Kiểm tra execution delay thực tế và random delay.
- Dùng Visual Mode để debug logic khi cần.
- Không dùng Open prices only cho chiến lược Grid M1.

**Data segmentation:**

- In-sample 60%.
- Validation 20%.
- Out-of-sample 20%.
- Ghi rõ nguồn dữ liệu, timezone, missing ticks và khác biệt tester/live.
- Không dùng OOS để tiếp tục điều chỉnh rồi vẫn gọi đó là OOS.

**Stress tests bắt buộc:**

1. Spread × 1.5 và × 2.0.
2. Slippage và execution delay tăng.
3. Giá chạy một chiều 10–20 USD không hồi.
4. ATR tăng đột biến.
5. Tin mạnh/giãn spread.
6. Mất kết nối khi Basket mở.
7. Restart khi đang có nhiều tầng.
8. Đóng một phần thất bại.
9. BUY và SELL cùng tồn tại.
10. Minimum lot khiến risk budget không đủ.
11. Currency/account specification không đúng kỳ vọng.
12. State file bị thiếu, lỗi hoặc không tương thích version.

**Nghiên cứu robustness:**

- Monte Carlo tối thiểu 1,000 lần nếu dữ liệu cho phép.
- Resample theo Basket hoặc chuỗi trade có xét phụ thuộc thời gian; không xáo trộn độc lập từng lệnh thuộc cùng Basket.
- Walk-forward với cửa sổ tách biệt.
- So sánh tham số theo từng nhóm, không tối ưu tất cả cùng lúc.
- Báo cáo độ nhạy tham số và nguy cơ overfitting.

**Chỉ số phải báo cáo:**

Net Profit, Gross Profit/Loss, Profit Factor, Expected Payoff, Win Rate theo Basket, số Basket BUY/SELL, average win/loss, Maximum Balance DD, Maximum Equity DD, Recovery Factor, Largest Basket Loss, thời lượng Basket trung bình/tối đa, số tầng tối đa, spread trung bình và percentile, commission, swap, slippage, số lần chạm Basket SL, Global Stop, margin level thấp nhất, kết quả BUY riêng, SELL riêng và combined.

Phân biệt thống kê theo lệnh và theo Basket. Không chỉ báo cáo Win Rate.

**Tiêu chuẩn tham khảo từ đặc tả (không phải cam kết):**

- Profit Factor >= 1.20.
- Expectancy sau chi phí > 0.
- Maximum Equity DD mục tiêu <= 5%.
- Recovery Factor mục tiêu >= 2.
- Out-of-sample expectancy > 0.
- Global risk control hoạt động đúng.
- Duplicate order = 0.
- Unauthorized position close = 0.
- Martingale/lot escalation = 0.
- Restart recovery: PASS.
- Failed close handling: PASS.

Nếu không đạt, kết luận **NOT READY FOR LIVE**. Không che giấu kết quả âm hoặc điều chỉnh dữ liệu để tạo báo cáo đẹp.

### PHASE 9 — Final Code Review & Delivery

Trước bàn giao:

1. Rà soát từng yêu cầu trong Requirement Traceability Matrix.
2. Kiểm tra tất cả đường đi có thể gửi order; đảm bảo risk check được gọi trước order.
3. Kiểm tra mọi đường đi đóng Basket và Global Close.
4. Kiểm tra magic/symbol/type filters.
5. Kiểm tra shift nến và không repaint/look-ahead.
6. Kiểm tra volume/price normalization.
7. Kiểm tra commission/fee attribution và currency units.
8. Kiểm tra restart, duplicate prevention, lock persistence.
9. Kiểm tra compile warning/error nếu có môi trường MetaEditor.
10. Ghi rõ những kiểm tra chưa thể chạy.

---

## 7. Constraints & Rules

### 7.1. Risk-first — quy tắc không thể thương lượng

- Bảo toàn vốn quan trọng hơn tạo giao dịch.
- Nếu risk không tính được, **không giao dịch**.
- Nếu minimum lot vượt risk budget, **không giao dịch**.
- Nếu symbol/account specification không khớp, **không khởi tạo EA**.
- Nếu tài khoản không Hedging, `INIT_FAILED`.
- Nếu trạng thái Basket không thể khôi phục an toàn, SAFE MODE.
- Không mở thêm tầng chỉ vì giá đã đi đủ khoảng cách; phải qua toàn bộ risk, spread, margin, regime và execution checks.
- Không xem SL phần mềm là bảo đảm lỗ tối đa.
- Không khuyến nghị chạy live chỉ dựa trên một giai đoạn backtest.

### 7.2. Cấm

- Martingale, lot multiplier lớn hơn 1, tăng lot theo tầng hoặc bất kỳ biến thể tăng volume để gỡ lỗ.
- Grid vô hạn hoặc bỏ qua MaxLayers/MaxSideLots.
- Tự đổi symbol.
- Hard-code thông số contract/tick/volume của broker.
- Dùng dữ liệu nến chưa đóng để xác nhận tín hiệu.
- Tự ý thêm EMA200, news filter hoặc bộ lọc khác nếu chưa có input bật/tắt và chưa được phê duyệt.
- Đóng hoặc sửa lệnh không thuộc EA.
- Bịa kết quả compile, unit test, backtest, Monte Carlo hoặc dữ liệu tick.
- Dùng profit cao nhất làm tiêu chí tối ưu duy nhất.
- Che giấu lỗi, warning, giới hạn môi trường hoặc kết quả không đạt.

### 7.3. Quy tắc về tính trung thực

Nếu không có MetaTrader 5, MetaEditor, broker connection hoặc dữ liệu tick phù hợp:
- Vẫn có thể viết source và test plan.
- Phải ghi rõ chưa compile/chưa chạy tester.
- Không ghi PASS cho kiểm thử chưa thực hiện.
- Cung cấp lệnh/hướng dẫn để người dùng tự kiểm tra.
- Phân biệt rõ `Implemented`, `Static-reviewed`, `Compiled`, `Tested`, `Backtested` và `Validated`.

### 7.4. Quy tắc tương tác

- Chỉ hỏi người dùng khi thiếu thông tin có thể làm thay đổi an toàn hoặc tính đúng đắn của triển khai.
- Gom các câu hỏi blocker thành một lượt ngắn, không hỏi lại dữ liệu đã có.
- Với lựa chọn không blocker, đề xuất mặc định an toàn và ghi vào Assumptions Register.
- Không tự thay đổi phạm vi dự án.
- Không tiết lộ chain of thought; cung cấp kết luận, căn cứ và bằng chứng kiểm thử.

---

## 8. Quality Assurance

### 8.1. Verification Loop bắt buộc

Sau mỗi phase:

1. Đối chiếu kết quả với đặc tả nguồn.
2. Tìm yêu cầu bị bỏ sót, diễn giải sai hoặc xung đột.
3. Kiểm tra các trường hợp biên và failure modes.
4. Sửa lỗi trước khi chuyển phase.
5. Cập nhật Requirement Traceability Matrix và Assumptions Register.
6. Nêu rõ phần nào đã xác minh và phần nào chưa thể xác minh.

### 8.2. Risk-focused review

Đặc biệt kiểm tra các lỗi nghiêm trọng:

- Sai đơn vị USC/USD hoặc point/USD.
- Sai volume step/minimum.
- Dùng tick value sai currency.
- Sai shift khiến tín hiệu dùng nến tương lai hoặc nến đang chạy.
- Grid add dựa trên giá không phải giá khớp thực tế.
- Basket P/L bỏ sót phí hoặc tính phí trùng.
- Risk check chỉ tính lệnh mới mà không tính toàn Basket.
- Không tính combined risk hai phía.
- Daily loss reset sai ngày hoặc reset sau restart.
- Equity high-water mark không được lưu bền vững.
- Đánh dấu Basket đã đóng khi còn position.
- Gửi lệnh trùng do nhiều tick hoặc restart.
- Đóng nhầm position manual/EA khác.
- Lỗi retcode bị bỏ qua.
- Không có fail-safe khi dữ liệu indicator hoặc history thiếu.

### 8.3. Acceptance checklist

Chỉ đánh dấu PASS khi có bằng chứng:

| Hạng mục | Điều kiện PASS |
|---|---|
| Environment | Xác thực đúng symbol, account currency, Hedging và symbol specs |
| Signals | BUY/SELL đúng logic, đúng shift, chỉ dùng nến đóng |
| Grid | Đúng ATR spacing, tick normalization, giới hạn tầng/volume |
| Risk per Basket | Đúng snapshot equity và stress-risk gate |
| Combined risk | Không vượt giới hạn tổng đã cấu hình |
| Basket P/L | Đúng floating + realized attributable costs |
| Basket close | Đóng theo ticket, kiểm tra retcode và xác nhận không còn position |
| Global locks | Kích hoạt, persist và reset đúng chính sách |
| Recovery | Restart không tạo lệnh trùng hoặc mất risk state |
| Isolation | Không tác động position ngoài symbol/magic/type |
| Logs | Có lý do cho mọi quyết định giao dịch quan trọng |
| Compile | Có bằng chứng compile thực tế, hoặc ghi NOT VERIFIED |
| Backtest | Có dữ liệu, cấu hình, giai đoạn và báo cáo tái lập |
| Robustness | Stress tests và OOS được báo cáo trung thực |

---

## 9. Expected Output & Delivery Format

Bàn giao theo cấu trúc thư mục đề xuất:

```text
XAUUSDc_AdaptiveGrid/
├── Experts/
│   └── XAUUSDc_AdaptiveGrid.mq5
├── Include/
│   ├── AG_Environment.mqh
│   ├── AG_Indicators.mqh
│   ├── AG_Signals.mqh
│   ├── AG_GridManager.mqh
│   ├── AG_BasketManager.mqh
│   ├── AG_RiskManager.mqh
│   ├── AG_Execution.mqh
│   ├── AG_Recovery.mqh
│   └── AG_Logger.mqh
├── Presets/
│   └── XAUUSDc_AdaptiveGrid_Default.set
├── Tests/
│   ├── TestPlan.md
│   ├── TestCases.md
│   └── SampleLog.csv
└── Documentation/
    ├── InstallationGuide.md
    ├── BacktestGuide.md
    ├── Parameters.md
    └── KnownLimitations.md
```

Có thể thay đổi cấu trúc nếu có lý do kỹ thuật, nhưng phải bàn giao đầy đủ mọi file phụ thuộc; không được cung cấp source bị thiếu `.mqh`.

### Các deliverables bắt buộc

1. Source `.mq5` và toàn bộ `.mqh`.
2. File `.set` cấu hình mặc định.
3. Hướng dẫn cài EA vào MT5.
4. Hướng dẫn xác minh symbol `XAUUSDc`, timeframe M1 và account Hedging.
5. Hướng dẫn Strategy Tester từng bước.
6. Báo cáo compile: số error/warning và môi trường compile.
7. Unit test/test plan cho volume, grid spacing, Basket P/L, risk budget, combined risk, daily loss, equity DD, recovery và close retry.
8. CSV log mẫu.
9. Backtest report chỉ khi thực sự chạy; ghi nguồn dữ liệu, giai đoạn, cấu hình và điều kiện tester.
10. Danh sách giả định, giới hạn, vấn đề chưa giải quyết và thông số người dùng phải xác minh trên MT5.
11. Requirement Traceability Matrix với trạng thái `PASS / FAIL / NOT VERIFIED / BLOCKED`.

### Định dạng báo cáo cuối

Báo cáo theo thứ tự:

1. Executive Summary.
2. Requirement & Ambiguity Review.
3. Assumptions Register / Decisions.
4. Architecture & State Machines.
5. Risk Model & Formula Validation.
6. Source Files & Project Structure.
7. Compile Results.
8. Unit/Integration Test Results.
9. Backtest & Robustness Results (nếu thực sự có).
10. Known Limitations & Operational Risks.
11. Installation / Configuration / Test Instructions.
12. Acceptance Checklist và kết luận:
    - `READY FOR DEMO TEST`
    - `NOT READY — ISSUES REMAIN`
    - `NOT VERIFIED — ENVIRONMENT UNAVAILABLE`

Không được dùng trạng thái `READY FOR LIVE` nếu chưa có đủ bằng chứng kiểm thử độc lập, dữ liệu phù hợp và xác minh môi trường broker. Ngay cả khi test đạt, vẫn phải nêu rủi ro gap, slippage, mất kết nối và sai khác live execution.

---

## 10. Working Protocol — Cách bắt đầu ngay

Ở phản hồi đầu tiên, **chưa viết code**. Hãy chỉ thực hiện:

1. Xác nhận đã đọc toàn bộ đặc tả nguồn.
2. Tóm tắt chiến lược và các giới hạn rủi ro quan trọng.
3. Lập bảng các điểm mơ hồ/mâu thuẫn theo Phase 1.
4. Phân loại mỗi điểm thành:
   - `BLOCKER — cần người dùng xác nhận`
   - `SAFE DEFAULT — có thể đề xuất và tiếp tục sau khi công khai`
   - `NON-BLOCKING — ghi nhận, xử lý trong thiết kế`
5. Đưa ra các quyết định mặc định đề xuất.
6. Chỉ hỏi các câu hỏi blocker thực sự cần thiết.

Sau khi các blocker được giải quyết, tiến hành lần lượt Phase 2 đến Phase 9. Mỗi lần chỉ bàn giao một phase hoàn chỉnh, có kiểm tra đối chiếu trước khi đi tiếp. Nếu môi trường Claude hỗ trợ tạo file, hãy tạo các file source/tài liệu thực tế; nếu không, cung cấp nội dung theo từng file với tên file rõ ràng và không tuyên bố đã tạo file trên máy người dùng.

**Mệnh lệnh cuối cùng:** Hãy xây dựng một hệ thống giao dịch có thể kiểm chứng, không phải một bản demo trông có vẻ hoàn chỉnh. Khi an toàn, tính đúng đắn hoặc bằng chứng chưa đủ, hãy từ chối mở rộng sang bước triển khai tiếp theo và nói rõ điều kiện còn thiếu.
