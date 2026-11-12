# Danh mục bẫy & lỗi thường gặp (Common Traps) {#traps}

Mỗi mục: **Tình huống · Vì sao sai · Cách sửa · Đối chiếu · Liên quan · Căn cứ**. Căn cứ là định nghĩa/định lý trong nguồn (ghi vị trí) hoặc phản ví dụ đã kiểm tra.

### T-01 · Kéo theo có tiền đề sai; câu chứa biến {#T-01}

- **Tình huống:** đánh giá "Nếu $3>4$ thì trời mưa" là sai; coi "$n$ là số tự nhiên" là mệnh đề.
- **Vì sao sai:** $p\to q$ chỉ sai khi $p=1,q=0$; câu chứa biến tự do là vị từ.
- **Cách sửa:** tra bảng [F-LOG-01](#F-LOG-01); kiểm tra biến tự do trước. **Liên quan:** [LOG-01](#LOG-01), [LOG-02](#LOG-02). **Căn cứ:** S1-p14, p59.

### T-02 · De Morgan và phân phối sai chiều {#T-02}

- **Tình huống:** $\neg(p\wedge q)\to\neg p\wedge\neg q$; gom $(p\vee r)\wedge(\neg q\vee r)$ thành $(p\vee\neg q)\wedge r$.
- **Vì sao sai:** De Morgan đổi $\wedge\leftrightarrow\vee$; phần tử chung $r$ phải đứng ngoài với phép **còn lại**.
- **Cách sửa:** viết đúng $\neg(p\wedge q)\Leftrightarrow\neg p\vee\neg q$; $(a\vee r)\wedge(b\vee r)\Leftrightarrow(a\wedge b)\vee r$. **Đối chiếu:** $p=1,q=0$: $\neg(p\wedge q)=1$ nhưng $\neg p\wedge\neg q=0$. **Liên quan:** [LOG-03](#LOG-03), [SET-01](#SET-01). **Căn cứ:** S1-p26–27.

### T-03 · Đảo, phản đảo, phủ định của kéo theo {#T-03}

- **Tình huống:** từ $p\to r$ suy ra $\neg p\to\neg r$; phủ định $a\to b$ thành $\neg a\to\neg b$ hoặc $a\to\neg b$.
- **Vì sao sai:** chỉ phản đảo $\neg r\to\neg p$ tương đương $p\to r$; $\neg(a\to b)\Leftrightarrow a\wedge\neg b$.
- **Cách sửa:** dùng [F-LOG-03](#F-LOG-03) luật 11. **Đối chiếu:** $p=0,r=1$: $p\to r=1$ nhưng $\neg p\to\neg r=0$. **Liên quan:** [LOG-04](#LOG-04), [QNT-02](#QNT-02). **Căn cứ:** S1-p29.

### T-04 · Khẳng định hệ quả / phủ định tiền đề {#T-04}

- **Tình huống:** $p\to q,\ q\ \therefore p$ hoặc $p\to q,\ \neg p\ \therefore\neg q$.
- **Vì sao sai:** không phải hằng đúng: $p=0,q=1$ làm tiền đề đúng, kết luận sai.
- **Cách sửa:** chỉ dùng 9 quy tắc [F-LOG-04](#F-LOG-04). **Liên quan:** [LOG-04](#LOG-04), [LOG-05](#LOG-05). **Căn cứ:** S1-p32–48 + phản ví dụ [CC].

### T-05 · "Có dấu phủ định nên là hằng sai" {#T-05}

- **Tình huống:** kết luận $p\wedge\neg(p\to q)$ là hằng sai.
- **Vì sao sai:** $p\wedge\neg(p\to q)\Leftrightarrow p\wedge\neg q$ đúng tại $p=1,q=0$.
- **Cách sửa:** rút gọn hoặc lập đủ bảng. **Liên quan:** [LOG-02-E02](#LOG-02-E02). **Căn cứ:** S1-p21 (ERR-13).

### T-06 · Đổi thứ tự lượng từ; bỏ qua miền {#T-06}

- **Tình huống:** coi $\forall x\exists y$ như $\exists y\forall x$; quên $\mathbb N$ không có số âm.
- **Vì sao sai:** chỉ có $\exists x\forall y\Rightarrow\forall y\exists x$ (S1-p68); miền thay đổi chân trị.
- **Cách sửa:** đọc từ trái sang; ở $\forall x\exists y$, $y$ được phụ thuộc $x$. **Đối chiếu:** "$x+y=0$" trên $\mathbb Z$ — [QNT-01-E02](#QNT-01-E02). **Liên quan:** [QNT-01](#QNT-01).

### T-07 · Phủ định lượng từ: phủ định cả miền {#T-07}

- **Tình huống:** phủ định $\forall\varepsilon>0$ thành $\exists\varepsilon\le0$.
- **Vì sao sai:** miền không đổi; chỉ đổi lượng từ và phủ định vị từ.
- **Cách sửa:** [M-07](#M-07). **Liên quan:** [QNT-02-E01](#QNT-02-E01). **Căn cứ:** S1-p69–71.

### T-08 · Ánh xạ: bỏ qua miền, tập đích, điểm cực trị {#T-08}

- **Tình huống:** "$x^2+1$ đơn ánh" mà không xét miền; $f([-1,3])=[f(-1),f(3)]$; giải $f(x)=y$ được nghiệm ngoài miền.
- **Vì sao sai:** tính chất ánh xạ phụ thuộc $X,Y$; ảnh của đoạn chứa điểm cực trị không phải đoạn nối hai đầu mút.
- **Cách sửa:** [M-09](#M-09); xét tính đơn điệu từng khúc. **Liên quan:** [FUN-01](#FUN-01), [FUN-02](#FUN-02). **Căn cứ:** S1-p87–90.

### T-09 · Quy nạp: sai bước cơ sở, sai số hạng thứ $k+1$, không dùng giả thiết {#T-09}

- **Tình huống:** bắt đầu $n=1$ cho mệnh đề "$n>3$"; số hạng cuối của $P(k+1)$ viết sai.
- **Cách sửa:** $N_0$ theo đề; viết rõ $P(k+1)$ trước khi biến đổi; chỉ ra chỗ dùng giả thiết quy nạp. **Liên quan:** [IND-01](#IND-01). **Căn cứ:** S1-p97–100.

### T-10 · Chữ số đầu bằng 0; không tách trường hợp chữ số 0 {#T-10}

- **Tình huống:** đếm số chẵn 3 chữ số khác nhau từ $\{0..5\}$ bằng $3\cdot5\cdot4$.
- **Vì sao sai:** khi chữ số cuối là 0, chữ số đầu có 5 lựa chọn; khi khác 0, chỉ còn 4.
- **Cách sửa:** [M-11](#M-11). **Liên quan:** [CNT-01-E01](#CNT-01-E01). **Căn cứ:** S2-p5.

### T-11 · Nhầm có thứ tự / không thứ tự; có lặp / không lặp {#T-11}

- **Tình huống:** dùng $C_n^k$ cho bài lập số; dùng $A_n^k$ khi đề không nói "khác nhau".
- **Cách sửa:** bảng [M-14](#M-14); ghi rõ giả thiết khi đề mơ hồ. **Liên quan:** [CNT-04-E01](#CNT-04-E01). **Căn cứ:** S2-p13–16.

### T-12 · Tổ hợp lặp: đảo $n,k$; "$>$" thành "$\ge$" sai {#T-12}

- **Tình huống:** $K_n^k$ tính thành $C_{n+k-1}^{n}$ với $n,k$ đảo; $x>4$ đổi thành $x\ge4$.
- **Cách sửa:** $n$ = số loại/ẩn/hộp, $k$ = vế phải; với số nguyên $x>4\Leftrightarrow x\ge5$. **Liên quan:** [CNT-06](#CNT-06). **Căn cứ:** S2-p19–24.

### T-13 · Vế phải là đa thức thì $\beta=1$; viết lại lũy thừa {#T-13}

- **Tình huống:** coi $12n+8$ là "không có $\beta$" và quên xét $\beta=1$ có là nghiệm PTĐT; với $2\cdot5^{n+1}$ lấy hệ số 2.
- **Cách sửa:** $P(n)=1^nP(n)$; $2\cdot5^{n+1}=10\cdot5^n$; $(2-n)2^{n-2}=\frac{2-n}{4}2^n$. **Liên quan:** [REC-03](#REC-03). **Căn cứ:** S2-p48.

### T-14 · Tìm hằng số $C_1,C_2$ trước khi cộng nghiệm riêng {#T-14}

- **Vì sao sai:** điều kiện đầu áp cho nghiệm của hệ **không thuần nhất**.
- **Cách sửa:** $x_n=\bar x_n+x_n^*$ rồi mới thế $x_0,x_1$. **Đối chiếu:** [REC-03-E02](#REC-03-E02): dùng sai thứ tự cho $C_2=-2$ thay vì $-5$. **Căn cứ:** S2-p47, p59.

### T-15 · Bội của $\beta$ và dạng nghiệm kép {#T-15}

- **Tình huống:** chọn $x_n^*=\beta^nQ_r(n)$ khi $\beta$ là nghiệm (hệ vô nghiệm); với nghiệm kép viết $C_1\lambda^n+C_2\lambda^n$.
- **Cách sửa:** nhân $n^m$ ($m$ = bội của $\beta$, xét **riêng từng** $\beta$); nghiệm kép: $(C_1+nC_2)\lambda_0^n$. **Liên quan:** [REC-02](#REC-02), [REC-03](#REC-03), [REC-04](#REC-04). **Căn cứ:** S2-p43, p49–50.

### T-16 · Tính chất quan hệ: chứng minh bằng ví dụ, bỏ sót cặp {#T-16}

- **Tình huống:** thử vài số rồi kết luận "bắc cầu"; quên cặp $(a,b),(b,a)\Rightarrow(a,a)$.
- **Cách sửa:** "có" → chứng minh tổng quát; "không" → một phản ví dụ. Kiểm tra bắc cầu với **mọi** cặp nối nhau. **Liên quan:** [REL-02](#REL-02). **Căn cứ:** S3-p7–11.

### T-17 · Phản xứng ≠ "không đối xứng"; $(\mathbb Z,\mid)$ không là poset {#T-17}

- **Tình huống:** cho rằng quan hệ không đối xứng thì phản xứng (hoặc ngược lại không thể vừa đối xứng vừa phản xứng).
- **Vì sao sai:** "=" vừa đối xứng vừa phản xứng; $\{(1,2),(2,1),(1,3)\}$ không đối xứng, không phản xứng. Trên $\mathbb Z$: $3\mid-3$, $-3\mid3$.
- **Liên quan:** [REL-02](#REL-02), [POS-01](#POS-01). **Căn cứ:** S3-p9, p32.

### T-18 · Hasse: vẽ cung bắc cầu; tối đại ≠ lớn nhất {#T-18}

- **Cách sửa:** chỉ vẽ trội trực tiếp; "lớn nhất" phải so sánh được và lớn hơn **mọi** phần tử — có nhiều tối đại thì không có lớn nhất. **Đối chiếu:** [POS-03-E01](#POS-03-E01). **Căn cứ:** S3-p42–49.

### T-19 · Chặn trên/dưới và sup/inf {#T-19}

- **Tình huống:** đòi chặn phải thuộc $A$; chọn sup là một chặn trên bất kỳ; khẳng định sup luôn tồn tại.
- **Cách sửa:** chặn thuộc $S$; sup = chặn trên **nhỏ nhất** (so sánh được với mọi chặn trên); có thể không tồn tại. **Đối chiếu:** [POS-04-E01](#POS-04-E01). **Căn cứ:** S3-p50–53.

### T-20 · Karnaugh: quên quấn biên và 4 góc {#T-20}

- **Cách sửa:** cột $x\bar y$ kề cột $\bar x\bar y$; hàng $z\bar t$ kề hàng $\bar z\bar t$; 4 góc là một tế bào ($\bar y\bar t$). **Liên quan:** [BOO-02](#BOO-02), [BOO-03](#BOO-03). **Căn cứ:** S4-p25, p30.

### T-21 · Karnaugh: tế bào chưa "lớn"; không so sánh độ đơn giản {#T-21}

- **Tình huống:** dùng hai tế bào 4 ô thay cho một tế bào 8 ô; liệt kê mọi phủ là tối tiểu.
- **Cách sửa:** kiểm tra từng tế bào có mở rộng gấp đôi được không; Bước 5 loại công thức có công thức khác thực sự đơn giản hơn. **Đối chiếu:** [BOO-03-E03](#BOO-03-E03). **Căn cứ:** S4-p33, p40, p65.

### T-22 · Bù của tích ≠ tích các bù; mạch hằng {#T-22}

- **Tình huống:** $\overline{xy}$ (NAND) nhầm với $\bar x\bar y$; không nhận ra $(x\vee y\vee z)\bar x\bar y\bar z\equiv0$.
- **Cách sửa:** De Morgan: $\overline{xy}=\bar x\vee\bar y$, $\overline{x\vee y}=\bar x\bar y$. **Liên quan:** [BOO-04](#BOO-04). **Căn cứ:** S4-p70–71, p74.

### T-23 · Bậc và ma trận kề: khuyên, cạnh song song {#T-23}

- **Cách sửa:** khuyên cộng 2 vào bậc (vô hướng); cạnh song song: $a_{ij}$ = số cạnh. **Kiểm tra:** $\sum\deg=2m$. **Liên quan:** [GRA-01](#GRA-01), [GRA-02](#GRA-02). **Căn cứ:** S5-p19, p26–28.

### T-24 · Đẳng cấu: bất biến chỉ là điều kiện cần {#T-24}

- **Cách sửa:** bất biến khác ⇒ không đẳng cấu; bất biến giống ⇒ phải dựng song ánh và kiểm tra **mọi** cạnh. **Đối chiếu:** $C_6$ và 2 tam giác ([GRA-03-E01](#GRA-03-E01)). **Căn cứ:** S5-p29–30.

### T-25 · Euler: quên liên thông, đếm sai đỉnh lẻ, đi qua cầu sớm {#T-25}

- **Cách sửa:** [M-25](#M-25): liên thông → đếm đỉnh lẻ (0: chu trình, 2: đường đi bắt đầu ở đỉnh lẻ) → Fleury tránh cầu. **Liên quan:** [GRA-05](#GRA-05). **Căn cứ:** S5-p49–50.

### T-26 · Dùng Dijkstra khi có trọng số âm {#T-26}

- **Vì sao sai:** Dijkstra cố định đỉnh dựa trên giả thiết trọng số dương (S5-p56). **Đối chiếu:** $a\to b$ (2), $a\to c$ (3), $c\to b$ (−2): Dijkstra cho 2, đúng là 1. **Cách sửa:** dùng Ford–Bellman. **Liên quan:** [GRA-06](#GRA-06), [GRA-07](#GRA-07).

### T-27 · Dijkstra: cập nhật đỉnh đã cố định; chọn min sai phạm vi; dừng sớm {#T-27}

- **Cách sửa:** chỉ cập nhật đỉnh **chưa cố định** kề với đỉnh vừa cố định; chọn min trên **toàn bộ** đỉnh chưa cố định; với bài $u_0\to z$ chỉ dừng khi $z$ được cố định. **Liên quan:** [GRA-06](#GRA-06). **Căn cứ:** S5-p59.

### T-28 · Ford–Bellman: dùng giá trị cùng dòng; điều kiện dừng {#T-28}

- **Cách sửa:** $L_k$ chỉ dùng giá trị $L_{k-1}$; dừng khi **cả dòng** không đổi hoặc $k=n$ (mạch âm). **Liên quan:** [GRA-07](#GRA-07). **Căn cứ:** S5-p73–74.

### T-29 · Thứ tự từ điển: so độ dài trước {#T-29}

- **Cách sửa:** so ký tự tại vị trí khác nhau đầu tiên; tiền tố nhỏ hơn ($0110\prec10$, $0110\prec01100$). **Liên quan:** [POS-02](#POS-02). **Căn cứ:** S3-p39–41.

### T-30 · Ma trận kề/trọng số: đọc sai hướng; không nêu quy ước khuyên {#T-30}

- **Cách sửa:** hàng = đỉnh đầu, cột = đỉnh cuối; ma trận không đối xứng ⇒ có hướng; ghi rõ quy ước khuyên (CON-01). **Liên quan:** [GRA-02](#GRA-02), [GRA-06-E02](#GRA-06-E02). **Căn cứ:** S5-p26–28, p53.

### T-31 · Áp dụng công thức ngoài phạm vi slide {#T-31}

- **Tình huống:** PTĐT có nghiệm phức; hệ thức cấp 3; Floyd; Quine–McCluskey.
- **Cách sửa:** slide chỉ có nghiệm thực, cấp $\le2$, Dijkstra/Ford–Bellman, Karnaugh (GAP-05/06/07). Nếu gặp trong đề, trình bày bằng kiến thức bổ sung và ghi rõ là ngoài slide. **Liên quan:** [REC-02](#REC-02), [GRA-06](#GRA-06), [BOO-03](#BOO-03).
