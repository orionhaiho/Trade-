# Thư viện phương pháp giải (Method Library) {#methods}

Mỗi phương pháp: **Mục đích · Dấu hiệu · Điều kiện · Quy trình · Trình bày trong bài thi · Không nên dùng khi · Ví dụ · Lỗi thường gặp**. Tất cả phương pháp đều có căn cứ trong slide (nguồn ghi ở cuối mỗi mục).

### M-01 · Lập bảng chân trị {#M-01}

- **Mục đích:** xác định chân trị dạng mệnh đề; kiểm tra hằng đúng/sai; kiểm tra tương đương (đối chiếu).
- **Dấu hiệu:** "lập bảng chân trị", "hằng đúng?", ít biến ($\le4$).
- **Quy trình:** (1) đếm $n$ biến → $2^n$ dòng, liệt kê theo thứ tự nhị phân 00…0 → 11…1; (2) mở cột cho từng **biểu thức con** từ trong ra ngoài; (3) cột cuối = $E$; (4) toàn 1 → hằng đúng, toàn 0 → hằng sai.
- **Trình bày:** bảng có tiêu đề cột là biểu thức con; kết luận một câu.
- **Không nên dùng:** $\ge5$ biến (32 dòng) — chuyển sang [M-02](#M-02)/[M-05](#M-05).
- **Ví dụ:** [LOG-02-E01](#LOG-02-E01). **Lỗi:** sai cột $\to$ (nhớ chỉ sai ở 1→0) — [T-01](#T-01). *Nguồn:* S1-p19–22.

### M-02 · Biến đổi tương đương bằng luật logic {#M-02}

- **Mục đích:** chứng minh $E\Leftrightarrow F$ hoặc rút gọn.
- **Dấu hiệu:** "chứng minh tương đương", có $\to$ cần khử.
- **Quy trình:** (1) khử $\to$, $\leftrightarrow$ bằng luật kéo theo; (2) đẩy $\neg$ vào trong (De Morgan, phủ định kép); (3) phân phối / hấp thụ / phần tử bù / thống trị để gom; (4) nếu cần, đưa về lại dạng $\to$.
- **Trình bày:** mỗi dòng "$\Leftrightarrow\ \dots$ (tên luật)"; biến đổi từ vế phức tạp sang vế đơn giản.
- **Không nên dùng:** khi chỉ cần chỉ ra **không** tương đương — dùng một dòng phản ví dụ của bảng chân trị.
- **Ví dụ:** [LOG-03-E01](#LOG-03-E01). **Lỗi:** De Morgan quên đổi $\wedge\leftrightarrow\vee$ [T-02](#T-02). *Nguồn:* S1-p25–30.

### M-03 · Chuỗi quy tắc suy diễn (chứng minh trực tiếp) {#M-03}

- **Mục đích:** chứng minh tiền đề ⇒ kết luận.
- **Quy trình:** (1) đánh số tiền đề; (2) tìm tiền đề "đơn" (một biến) để kích hoạt Modus Ponens/Tollens/tam đoạn luận rời; (3) mỗi dòng mới ghi căn cứ (số dòng + tên quy tắc); (4) kết luận dạng kéo theo có thể dùng phản đảo hoặc tam đoạn luận.
- **Trình bày:** bảng 3 cột: bước – mệnh đề – lý do.
- **Không nên dùng:** khi nghi suy luận sai → [M-05](#M-05).
- **Ví dụ:** [LOG-04-E01](#LOG-04-E01). **Lỗi:** "khẳng định hệ quả" [T-04](#T-04). *Nguồn:* S1-p31–51.

### M-04 · Phản chứng (quy tắc mâu thuẫn) {#M-04}

- **Mục đích:** chứng minh $(p_1\wedge\dots\wedge p_n)\to h$ bằng cách thêm $\neg h$ và suy ra $0$.
- **Dấu hiệu:** kết luận dạng $a\to b$ hoặc khó suy trực tiếp.
- **Quy trình:** (1) viết $\neg h$ (với $h=a\to b$: $\neg h\Leftrightarrow a\wedge\neg b$); (2) tách bằng quy tắc đơn giản; (3) dùng các tiền đề cho tới khi có $r$ và $\neg r$; (4) $r\wedge\neg r\Leftrightarrow0$ ⇒ suy luận đúng.
- **Ví dụ:** [LOG-04-E02](#LOG-04-E02), [LOG-04-E03](#LOG-04-E03). **Lỗi:** phủ định $a\to b$ thành $\neg a\to\neg b$ [T-03](#T-03). *Nguồn:* S1-p44–46, p52–54.

### M-05 · Kiểm tra suy luận bằng hệ chân trị / phản ví dụ {#M-05}

- **Mục đích:** quyết định suy luận đúng hay sai; nếu sai, đưa phản ví dụ.
- **Quy trình:** (1) đặt kết luận $=0$ (nếu kết luận $a\to b$: $a=1,b=0$); (2) đặt mọi tiền đề $=1$; (3) suy lần lượt các biến bị ép; (4) **có nghiệm** ⇒ suy luận **sai** (nghiệm là phản ví dụ, phải thử lại đủ tiền đề); **vô nghiệm** ⇒ suy luận **đúng**.
- **Ví dụ:** [LOG-05-E01](#LOG-05-E01), [LOG-05-E02](#LOG-05-E02). **Lỗi:** quên thử lại phản ví dụ. *Nguồn:* S1-p48–49, p55–56.

### M-06 · Xét chân trị mệnh đề lượng từ {#M-06}

- **Quy trình:** đọc **từ trái sang phải**. $\forall x$ đúng: chứng minh với $x$ tùy ý; sai: chỉ ra **một** $x_0$. $\exists x$ đúng: chỉ ra **một** $x_0$; sai: chứng minh với mọi $x$. $\forall x\exists y$: $y$ được phép **phụ thuộc** $x$ (ví dụ $y=-x/2$). $\exists x\forall y$: một $x$ dùng cho **mọi** $y$.
- **Ví dụ:** [QNT-01-E01](#QNT-01-E01). **Lỗi:** đổi thứ tự lượng từ [T-06](#T-06). *Nguồn:* S1-p61–68.

### M-07 · Phủ định mệnh đề lượng từ {#M-07}

- **Quy trình:** (1) quét từ trái: $\forall\to\exists$, $\exists\to\forall$ (giữ miền); (2) phủ định phần vị từ: $<\to\ge$, $=\to\ne$, $\wedge\to\vee$ (De Morgan), $A\to B\ \to\ A\wedge\neg B$.
- **Ví dụ:** [QNT-02-E01](#QNT-02-E01). **Lỗi:** phủ định cả miền "$\varepsilon>0$" [T-07](#T-07). *Nguồn:* S1-p69–71.

### M-08 · Chứng minh đẳng thức tập hợp {#M-08}

- **Cách 1 (phần tử):** $x\in VT\Leftrightarrow\dots$ (dịch sang logic, dùng luật logic) $\Leftrightarrow x\in VP$.
- **Cách 2 (luật tập hợp):** biến đổi bằng [F-SET-01](#F-SET-01), dùng $A\setminus B=A\cap\bar B$ **[CC]**.
- **Kiểm tra nhanh:** sơ đồ Ven / thử với tập cụ thể nhỏ.
- **Ví dụ:** [SET-01-E01](#SET-01-E01). *Nguồn:* S1-p76–79.

### M-09 · Xét đơn/toàn/song ánh qua phương trình $f(x)=y$ {#M-09}

- **Quy trình:** (1) kiểm tra $f$ là ánh xạ (xác định với mọi $x\in X$, giá trị thuộc $Y$); (2) cố định $y\in Y$, giải $f(x)=y$ **trong $X$**; (3) đếm nghiệm: $\le1$ mọi $y$ → đơn; $\ge1$ mọi $y$ → toàn; đúng 1 → song ánh, $f^{-1}(y)$ = nghiệm đó; (4) để bác bỏ: một cặp $x\ne x'$ cùng ảnh, hoặc một $y$ vô nghiệm.
- **Ví dụ:** [FUN-02-E01](#FUN-02-E01), [FUN-02-E02](#FUN-02-E02). **Lỗi:** giải nghiệm ngoài $X$ [T-08](#T-08). *Nguồn:* S1-p88–94.

### M-10 · Quy nạp toán học {#M-10}

- **Quy trình:** (1) Đặt $P(n)$ = "…". (2) **Cơ sở:** kiểm tra $P(N_0)$. (3) **Quy nạp:** giả sử $P(k)$ đúng ($k\ge N_0$), chứng minh $P(k+1)$: viết vế của $P(k+1)$, **tách ra phần bằng vế của $P(k)$**, thay bằng giả thiết quy nạp. (4) Kết luận theo nguyên lý quy nạp.
- **Không nên dùng:** mệnh đề không phụ thuộc số tự nhiên.
- **Ví dụ:** [IND-01-E01](#IND-01-E01), [IND-01-E03](#IND-01-E03). **Lỗi:** sai $N_0$, không dùng giả thiết [T-09](#T-09). *Nguồn:* S1-p97–100.

### M-11 · Đếm bằng chia trường hợp + nguyên lý nhân {#M-11}

- **Quy trình:** (1) mô tả đối tượng bằng các "vị trí"; (2) vị trí **bị ràng buộc nhiều nhất** chọn trước (chữ số cuối khi "chẵn/chia hết cho 5", chữ số đầu $\ne0$); (3) nếu ràng buộc phụ thuộc nhau (chữ số 0) → chia trường hợp rời nhau; (4) nhân trong mỗi trường hợp, cộng các trường hợp.
- **Ví dụ:** [CNT-01-E01](#CNT-01-E01). **Lỗi:** quên chữ số đầu $\ne0$ [T-10](#T-10). *Nguồn:* S2-p3–5.

### M-12 · Nguyên lý chuồng bồ câu {#M-12}

- **Quy trình:** (1) xác định "chim" (đối tượng) và "chuồng" (nhóm) sao cho hai chim cùng chuồng ⇒ điều cần chứng minh; (2) đếm: số chim > số chuồng (hoặc dùng $\lceil n/k\rceil$); (3) kết luận.
- **Ví dụ:** [CNT-02-E01](#CNT-02-E01). *Nguồn:* S2-p6–7.

### M-13 · Bù trừ / đếm phần bù {#M-13}

- **Quy trình:** (1) đặt tên tập $A_i$ = các đối tượng có tính chất $i$; (2) "hoặc / ít nhất một" → $|\bigcup A_i|$ theo [F-CNT-03](#F-CNT-03); (3) "không có tính chất nào" = Tổng $-|\bigcup A_i|$; (4) ràng buộc "$\le b$" = tổng − số trường hợp "$\ge b+1$".
- **Ví dụ:** [CNT-03-E02](#CNT-03-E02), [CNT-06-E02](#CNT-06-E02). *Nguồn:* S2-p8–10, p22–24.

### M-14 · Chọn đúng công thức tổ hợp (cây quyết định) {#M-14}

| Thứ tự quan trọng? | Được lặp? | Dùng |
|--------------------|------------|------------------|
| Có, lấy hết $n$ | Không | $P_n=n!$ |
| Có, lấy $k$ | Không | $A_n^k$ |
| Có, lấy $k$ | Có | $n^k$ (nguyên lý nhân) |
| Không | Không | $C_n^k$ |
| Không | Có | $K_n^k=C_{n+k-1}^k$ |
| Sắp xếp $n$ vật có nhóm giống nhau | — | $\frac{n!}{n_1!\cdots n_k!}$ |


- **Mẹo thử thứ tự:** đổi chỗ hai phần tử được chọn — nếu ra kết quả **khác** thì có thứ tự. **Ví dụ:** [CNT-04-E01](#CNT-04-E01). **Lỗi:** [T-11](#T-11). *Nguồn:* S2-p11–21.

### M-15 · Đổi biến cho nghiệm nguyên có ràng buộc {#M-15}

- **Quy trình:** (1) đưa mọi ràng buộc về dạng $x_i\ge a_i$ hoặc $x_i\le b_i$ (nguyên: $x>4\Leftrightarrow x\ge5$); (2) đặt $x_i'=x_i-a_i$ cho ràng buộc dưới; (3) ràng buộc trên: $p=q-r$ với $q$ = không xét cận trên, $r$ = thay cận trên bằng $x_i\ge b_i+1$; (4) mỗi số đếm dùng $K_n^k=C_{n+k-1}^k$.
- **Ví dụ:** [CNT-06-E02](#CNT-06-E02), [CNT-06-E03](#CNT-06-E03). **Lỗi:** [T-12](#T-12). *Nguồn:* S2-p22–24.

### M-16 · Lập hệ thức đệ qui {#M-16}

- **Quy trình:** (1) đặt $x_n$ = đại lượng cần đếm với tham số $n$; (2) tính trực tiếp vài giá trị đầu ($x_1, x_2$); (3) với $n$ lớn, chia theo **bước đầu tiên** (hoặc cuối cùng) thành các trường hợp **rời nhau**, mỗi trường hợp quy về bài toán cỡ nhỏ hơn; (4) cộng (nguyên lý cộng) ⇒ hệ thức + điều kiện đầu; (5) kiểm tra bằng liệt kê $n$ nhỏ.
- **Ví dụ:** [REC-01-E01](#REC-01-E01), [REC-01-E02](#REC-01-E02). *Nguồn:* S2-p34–39.

### M-17 · Giải hệ thức đệ qui tuyến tính (quy trình đầy đủ) {#M-17}
1. **Chuẩn hóa:** viết vế trái theo $x_{n}, x_{n-1}, x_{n-2}$ (hoặc $x_{n+2}, x_{n+1}, x_n$) — giữ nguyên hệ số $a_0,a_1,a_2$; xác định vế phải $f_n$.
2. **PTĐT** $a_0\lambda^2+a_1\lambda+a_2=0$; giải; viết nghiệm TQ thuần nhất $\bar x_n$ ([F-REC-02](#F-REC-02)).
3. Nếu $f_n\ne0$: viết $f_n=\beta^nP_r(n)$ (hoặc tổng các dạng). Với **mỗi** $\beta$: xác định bội $m\in\{0,1,2\}$ của $\beta$ trong PTĐT → dạng $n^m\beta^nQ_r(n)$ ([F-REC-03](#F-REC-03)).
4. Thế vào hệ thức, cho $n$ nhận $r+1$ giá trị (hoặc đồng nhất hệ số) → hệ phương trình → hệ số.
5. Nghiệm TQ $=\bar x_n+x_n^*$; thế điều kiện đầu → $C_1,C_2$.
6. **Kiểm tra:** thế $n=0,1$ (điều kiện đầu) và tính $x_2$ hai cách (từ hệ thức và từ công thức).

- **Không nên dùng:** PTĐT có nghiệm phức, hệ thức cấp $\ge3$ (ngoài phạm vi, GAP-05) — [T-31](#T-31).
- **Ví dụ:** [REC-02-E02](#REC-02-E02), [REC-03-E02](#REC-03-E02), [REC-04-E01](#REC-04-E01). **Lỗi:** [T-13](#T-13), [T-14](#T-14), [T-15](#T-15). *Nguồn:* S2-p41–66.

### M-18 · Kiểm tra tính chất quan hệ {#M-18}

- **Quan hệ hữu hạn (liệt kê/ma trận):** phản xạ — xem đường chéo; đối xứng — mỗi $(a,b)$ có $(b,a)$; phản xứng — không có cặp $(a,b),(b,a)$ với $a\ne b$; bắc cầu — với **mỗi** $(a,b)$ và mỗi $(b,c)$ kiểm tra $(a,c)$.
- **Quan hệ cho bằng quy tắc trên tập vô hạn:** "có" → chứng minh tổng quát bằng định nghĩa; "không" → **một** phản ví dụ số cụ thể.
- **Trình bày:** bảng 4 tính chất × (Có/Không + lý do/phản ví dụ). Tương đương = PX + ĐX + BC; Thứ tự = PX + PXứng + BC.
- **Ví dụ:** [REL-02-E01](#REL-02-E01), [REL-02-E02](#REL-02-E02), [POS-01-E01](#POS-01-E01). **Lỗi:** [T-16](#T-16), [T-17](#T-17). *Nguồn:* S3-p7–18.

### M-19 · Tìm lớp tương đương {#M-19}

- **Quy trình:** (1) chứng minh $R$ tương đương; (2) lấy phần tử $a$ chưa thuộc lớp nào, tính $[a]=\{b\mid bRa\}$; (3) lặp tới khi phủ hết $A$; (4) kiểm tra: các lớp rời nhau, hợp bằng $A$ (phân hoạch).
- **Ví dụ:** [REL-03-E01](#REL-03-E01), [REL-03-E02](#REL-03-E02). *Nguồn:* S3-p23–27.

### M-20 · Vẽ Hasse và đọc phần tử đặc biệt, chặn {#M-20}

- **Quy trình:** (1) liệt kê các cặp $a\prec b$; (2) loại cặp bắc cầu (có $c$ ở giữa) → còn cặp trội trực tiếp; (3) xếp tầng: phần tử tối tiểu ở dưới; vẽ đoạn từ $a$ lên $b$; (4) đọc: tối đại = đỉnh không có cạnh đi lên; tối tiểu = không có cạnh đi xuống; lớn nhất = phần tử mà **mọi** phần tử đi lên được tới; (5) chặn trên của $A$ = các phần tử đi lên được từ **mọi** phần tử của $A$; sup = chặn trên nhỏ nhất (phải so sánh được và nhỏ hơn mọi chặn trên khác).
- **Ví dụ:** [POS-03-E01](#POS-03-E01), [POS-04-E01](#POS-04-E01). **Lỗi:** [T-18](#T-18), [T-19](#T-19). *Nguồn:* S3-p42–53.

### M-21 · Sắp xếp topo {#M-21}

- **Quy trình:** lặp: chọn một phần tử **tối tiểu** của tập còn lại, ghi ra, xóa khỏi poset. Kết quả không duy nhất. **Kiểm tra:** mọi cặp $a\prec b$ có $a$ đứng trước $b$.
- **Ví dụ:** [POS-05-E01](#POS-05-E01). *Nguồn:* S3-p54–56.

### M-22 · Thuật toán Karnaugh 5 bước {#M-22}
1. Vẽ $\mathrm{kar}(f)$: mỗi đơn thức của $f$ → tô tế bào tương ứng (hoặc tô từng hàng $f=1$ của bảng chân trị).
2. Liệt kê **tất cả** tế bào lớn (thử lần lượt: 8 ô → 4 ô → 2 ô → 1 ô, kể cả quấn biên và 4 góc).
3. Tế bào lớn **bắt buộc**: chứa một ô chỉ nằm trong nó.
4. Nếu chưa phủ hết: với mỗi ô chưa phủ, xét các tế bào lớn chứa nó → liệt kê mọi phủ; loại phủ không tối tiểu.
5. Viết công thức đa thức tương ứng; loại công thức có công thức khác thực sự đơn giản hơn.

- **Trình bày:** vẽ bản đồ, đánh số ô; liệt kê tế bào lớn kèm đơn thức; nêu ô quyết định khi chọn bắt buộc.
- **Ví dụ:** [BOO-03-E01](#BOO-03-E01), [BOO-03-E02](#BOO-03-E02). **Lỗi:** [T-20](#T-20), [T-21](#T-21). *Nguồn:* S4-p38–65.

### M-23 · Từ bảng chân trị / mô tả đến công thức và mạch {#M-23}

- **Quy trình:** (1) mã hóa biến (1 = bật/tán thành) và $f$ (1 = đèn sáng/thông qua); (2) lập bảng chân trị; (3) dạng nối rời chính tắc: mỗi hàng $f=1$ → từ tối tiểu; (4) (nên) rút gọn bằng Karnaugh; (5) vẽ mạch: mỗi đơn thức → cổng AND (biến có gạch → qua NOT), các đơn thức → cổng OR.
- **Đọc mạch:** đi từ ngõ vào tới ngõ ra, ghi biểu thức ở đầu ra của từng cổng.
- **Ví dụ:** [BOO-04-E01](#BOO-04-E01), [BOO-04-E02](#BOO-04-E02). *Nguồn:* S4-p12–19, p66–78.

### M-24 · Kiểm tra đẳng cấu {#M-24}

- **Quy trình:** (1) so bất biến: số đỉnh, số cạnh, dãy bậc (sắp giảm); khác ⇒ kết luận **không đẳng cấu**; (2) nếu giống: ghép các đỉnh **bậc duy nhất** trước, rồi theo quan hệ kề với các đỉnh đã ghép; (3) kiểm tra **mọi cạnh** $uv$ ↦ $f(u)f(v)$ là cạnh (và số cạnh bằng nhau ⇒ đủ); (4) nếu mọi cách ghép đều thất bại ⇒ không đẳng cấu (nêu bất biến phân biệt, ví dụ hai đỉnh bậc 3 kề nhau ở $G$ nhưng không kề ở $G'$).
- **Ví dụ:** [GRA-03-E01](#GRA-03-E01). **Lỗi:** [T-24](#T-24). *Nguồn:* S5-p29–35.

### M-25 · Euler: kiểm tra điều kiện + Fleury {#M-25}

- **Quy trình:** (1) kiểm tra liên thông; (2) tính bậc mọi đỉnh; (3) 0 đỉnh lẻ → chu trình Euler, 2 đỉnh lẻ → đường đi Euler (xuất phát ở đỉnh lẻ), >2 → không có; (4) Fleury: đi một cạnh, xóa cạnh; ưu tiên cạnh **không phải cầu** của đồ thị còn lại; (5) kiểm tra: dãy dùng đủ $m$ cạnh, mỗi cạnh một lần.
- **Ví dụ:** [GRA-05-E01](#GRA-05-E01), [GRA-05-E02](#GRA-05-E02). **Lỗi:** [T-25](#T-25). *Nguồn:* S5-p48–51.

### M-26 · Dijkstra dạng bảng {#M-26}

- **Quy trình:** (1) kiểm tra trọng số dương; (2) bảng: cột = đỉnh, dòng = bước; dòng 0: nguồn $0^*$, còn lại $(\infty,-)$; (3) mỗi bước: cập nhật các đỉnh **chưa cố định kề với đỉnh vừa cố định**: $L(v)=\min\{L(v),L(u_i)+w\}$, nhãn $(L,u_i)$ nếu giảm; (4) đánh dấu * đỉnh có $L$ nhỏ nhất; đỉnh đã cố định ghi "–"; (5) truy vết ngược theo đỉnh trước để có đường đi.
- **Trình bày:** bảng + "Đường đi ngắn nhất $u_0\to v$: … , độ dài $d$".
- **Không nên dùng:** có trọng số âm → [M-27](#M-27).
- **Ví dụ:** [GRA-06-E01](#GRA-06-E01). **Lỗi:** [T-26](#T-26), [T-27](#T-27). *Nguồn:* S5-p56–72.

### M-27 · Ford–Bellman dạng bảng {#M-27}

- **Quy trình:** (1) dòng $k=0$: nguồn 0, còn lại $(\infty,-)$; (2) dòng $k$: với mỗi $v\ne u_0$, $L_k(v)=\min$ trên **mọi cung vào** $uv$ của $L_{k-1}(u)+w(uv)$ (dùng giá trị **dòng trước**); ghi $(L_k(v),u)$; (3) dòng $k$ trùng dòng $k-1$ ⇒ dừng, đọc khoảng cách; (4) tới $k=n$ chưa ổn định ⇒ có mạch âm — chỉ ra một mạch âm bằng truy vết nhãn.
- **Ví dụ:** [GRA-07-E01](#GRA-07-E01), [GRA-07-E02](#GRA-07-E02). **Lỗi:** [T-28](#T-28). *Nguồn:* S5-p73–86.
