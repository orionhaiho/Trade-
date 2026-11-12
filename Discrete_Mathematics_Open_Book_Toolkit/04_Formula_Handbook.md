# Sổ tay công thức & định lý (Formula Handbook) {#formulas}

Mỗi mục: **Công thức** · *Ký hiệu* · *Điều kiện* · *Lưu ý* · *Ví dụ* · *Nguồn* · *Trạng thái*. Trạng thái **SV** = có trong nguồn; **CC** = đã kiểm tra độc lập (bảng chân trị/vét cạn/máy tính, xem `10_Verification`).

## Chương I — Logic, tập hợp, ánh xạ, quy nạp

### F-LOG-01 · Năm phép toán mệnh đề {#F-LOG-01}

| $p$ | $q$ | $\neg p$ | $p\wedge q$ | $p\vee q$ | $p\to q$ | $p\leftrightarrow q$ |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| 0 | 0 | 1 | 0 | 0 | 1 | 1 |
| 0 | 1 | 1 | 0 | 1 | 1 | 0 |
| 1 | 0 | 0 | 0 | 1 | **0** | 0 |
| 1 | 1 | 0 | 1 | 1 | 1 | 1 |


- *Ký hiệu:* $\neg p$ = $\bar p$; 1 = Đ/T, 0 = S/F. Đọc $p\to q$: "nếu $p$ thì $q$", "$p$ là điều kiện **đủ** của $q$", "$q$ là điều kiện **cần** của $p$".
- *Lưu ý:* $p\to q$ **chỉ sai khi $p=1,q=0$** (tiền đề sai ⇒ kéo theo luôn đúng). Dạng mệnh đề $n$ biến có $2^n$ dòng.
- *Ví dụ:* [LOG-02-E01](#LOG-02-E01). *Nguồn:* S1-p10–19. *Trạng thái:* SV.

### F-LOG-02 · Tương đương logic, hệ quả logic, quy tắc thay thế {#F-LOG-02}
- $E\Leftrightarrow F$ khi và chỉ khi $E\leftrightarrow F$ là **hằng đúng** (cùng bảng chân trị). $E\Rightarrow F$ (hệ quả) khi $E\to F$ hằng đúng.
- Quy tắc thay thế: thay biểu thức con bởi biểu thức tương đương thì được biểu thức tương đương.
- *Ví dụ:* $\neg(p\vee q)\Rightarrow\neg p$. *Nguồn:* S1-p23–25. *Trạng thái:* SV.

### F-LOG-03 · Các luật logic (11 nhóm) {#F-LOG-03}

| # | Tên luật | Công thức |
|--|----------|------------------------------|
| 1 | Phủ định kép | $\neg\neg p\Leftrightarrow p$ |
| 2 | De Morgan | $\neg(p\wedge q)\Leftrightarrow\neg p\vee\neg q$; $\ \neg(p\vee q)\Leftrightarrow\neg p\wedge\neg q$ |
| 3 | Giao hoán | $p\vee q\Leftrightarrow q\vee p$; $\ p\wedge q\Leftrightarrow q\wedge p$ |
| 4 | Kết hợp | $(p\vee q)\vee r\Leftrightarrow p\vee(q\vee r)$; tương tự với $\wedge$ |
| 5 | Phân phối | $p\vee(q\wedge r)\Leftrightarrow(p\vee q)\wedge(p\vee r)$; $\ p\wedge(q\vee r)\Leftrightarrow(p\wedge q)\vee(p\wedge r)$ |
| 6 | Lũy đẳng | $p\vee p\Leftrightarrow p$; $\ p\wedge p\Leftrightarrow p$ |
| 7 | Trung hòa | $p\vee 0\Leftrightarrow p$; $\ p\wedge 1\Leftrightarrow p$ |
| 8 | Phần tử bù | $p\wedge\neg p\Leftrightarrow 0$; $\ p\vee\neg p\Leftrightarrow 1$ |
| 9 | Thống trị | $p\wedge 0\Leftrightarrow 0$; $\ p\vee 1\Leftrightarrow 1$ |
| 10 | Hấp thụ | $p\vee(p\wedge q)\Leftrightarrow p$; $\ p\wedge(p\vee q)\Leftrightarrow p$ |
| 11 | Kéo theo | $p\to q\Leftrightarrow\neg p\vee q\Leftrightarrow\neg q\to\neg p$ |


- *Lưu ý:* Mệnh đề **đảo** $q\to p$ và **phản đảo** $\neg q\to\neg p$: chỉ phản đảo tương đương với $p\to q$. **Phủ định** của $p\to q$ là $p\wedge\neg q$ (không phải $\neg p\to\neg q$). Hệ quả hay dùng (CC): $p\leftrightarrow q\Leftrightarrow(p\to q)\wedge(q\to p)$.
- *Ví dụ:* [LOG-03-E01](#LOG-03-E01). *Nguồn:* S1-p26–29. *Trạng thái:* SV; luật đảo/phủ định kéo theo: CC (bảng chân trị).

### F-LOG-04 · Các quy tắc suy diễn {#F-LOG-04}

| # | Tên (nguồn) | Sơ đồ | Hằng đúng |
|--|------------|--------------|--------------------|
| 1 | Khẳng định (Modus Ponens) | $p\to q,\ p\ \therefore q$ | $[(p\to q)\wedge p]\to q$ |
| 2 | Phủ định (Modus Tollens) | $p\to q,\ \neg q\ \therefore\neg p$ | $[(p\to q)\wedge\neg q]\to\neg p$ |
| 3 | Tam đoạn luận | $p\to q,\ q\to r\ \therefore p\to r$ | $[(p\to q)\wedge(q\to r)]\to(p\to r)$ |
| 4 | Tam đoạn luận rời | $p\vee q,\ \neg q\ \therefore p$ | $[(p\vee q)\wedge\neg q]\to p$ |
| 5 | Nối liền | $p,\ q\ \therefore p\wedge q$ | $(p\wedge q)\to(p\wedge q)$ |
| 6 | Đơn giản | $p\wedge q\ \therefore p$ | $(p\wedge q)\to p$ |
| 7 | Mâu thuẫn (phản chứng) | $p_1,\dots,p_n,\neg h\ \therefore 0$ | $(p_1\wedge\dots\wedge p_n)\to h\Leftrightarrow(p_1\wedge\dots\wedge p_n\wedge\neg h)\to 0$ |
| 8 | Chứng minh theo trường hợp | $p\to r,\ q\to r\ \therefore(p\vee q)\to r$ | $[(p\to r)\wedge(q\to r)]\to[(p\vee q)\to r]$ |
| 9 | Phản ví dụ | Suy luận sai nếu có **một** bộ chân trị làm mọi tiền đề = 1 và kết luận = 0 | — |


- *Lưu ý:* Không có quy tắc "$p\to q,\ q\ \therefore p$" (khẳng định hệ quả — **sai**) hay "$p\to q,\ \neg p\ \therefore\neg q$" (phủ định tiền đề — **sai**). Xem [T-04](#T-04).
- *Ví dụ:* [LOG-04-E01](#LOG-04-E01), [LOG-05-E01](#LOG-05-E01). *Nguồn:* S1-p31–48. *Trạng thái:* SV; hai suy luận sai: CC.

### F-QNT-01 · Lượng từ và hoán vị lượng từ {#F-QNT-01}
- $\forall x\in A,\ p(x)$ đúng ⇔ $p(a)$ đúng với **mọi** $a\in A$. $\exists x\in A,\ p(x)$ đúng ⇔ có **ít nhất một** $a_0$ với $p(a_0)$ đúng.
- Định lý (S1-p68): (1) $\forall x\forall y\,p\Leftrightarrow\forall y\forall x\,p$; (2) $\exists x\exists y\,p\Leftrightarrow\exists y\exists x\,p$; (3) $\exists x\forall y\,p(x,y)\Rightarrow\forall y\exists x\,p(x,y)$ — **chiều đảo nói chung sai**.
- Đặc biệt hóa phổ dụng: $\forall x\in A,\ p(x)$ và $a\in A$ $\therefore p(a)$.
- *Ví dụ:* [QNT-01-E01](#QNT-01-E01). *Nguồn:* S1-p62–68, p72. *Trạng thái:* SV.

### F-QNT-02 · Phủ định mệnh đề lượng từ {#F-QNT-02}
\[
\overline{\forall x\in A,\ p(x)}\Leftrightarrow\exists x\in A,\ \overline{p(x)},\qquad
\overline{\exists x\in A,\ p(x)}\Leftrightarrow\forall x\in A,\ \overline{p(x)}
\]

\[
\overline{\forall x\,\exists y,\ p(x,y)}\Leftrightarrow\exists x\,\forall y,\ \overline{p(x,y)},\qquad
\overline{\exists x\,\forall y,\ p(x,y)}\Leftrightarrow\forall x\,\exists y,\ \overline{p(x,y)}
\]

- *Quy tắc:* đổi $\forall\leftrightarrow\exists$, **giữ nguyên miền** (kể cả "$\varepsilon>0$"), phủ định vị từ: $\neg(<)$ là $\ge$; $\neg(A\to B)$ là $A\wedge\neg B$.
- *Ví dụ:* [QNT-02-E01](#QNT-02-E01). *Nguồn:* S1-p69–71. *Trạng thái:* SV.

### F-SET-01 · Phép toán và luật tập hợp {#F-SET-01}
- $x\in A\cup B\Leftrightarrow x\in A\vee x\in B$; $\ x\in A\cap B\Leftrightarrow x\in A\wedge x\in B$; $\ x\in A\setminus B\Leftrightarrow x\in A\wedge x\notin B$.
- Bù: khi $A\subset B$, $C_BA=B\setminus A$, ký hiệu $\bar A$.
- Lũy đẳng, giao hoán, kết hợp, $\emptyset\cup A=A$, $\emptyset\cap A=\emptyset$; phân phối $A\cup(B\cap C)=(A\cup B)\cap(A\cup C)$, $A\cap(B\cup C)=(A\cap B)\cup(A\cap C)$.
- De Morgan: $\overline{A\cap B}=\bar A\cup\bar B$, $\ \overline{A\cup B}=\bar A\cap\bar B$.
- *Lưu ý:* mỗi luật tập hợp tương ứng một luật logic ([F-LOG-03](#F-LOG-03)) qua định nghĩa phần tử.
- *Ví dụ:* [SET-01-E01](#SET-01-E01). *Nguồn:* S1-p76–79. *Trạng thái:* SV.

### F-SET-02 · Tập lũy thừa, tích Đề-các {#F-SET-02}
- $P(X)$ = tập mọi tập con của $X$; $|X|=n\Rightarrow|P(X)|=2^n$ **[CC]** (mỗi phần tử: chọn/không chọn).
- $A\times B=\{(x,y)\mid x\in A,\ y\in B\}$; $|A\times B|=|A|\cdot|B|$ **[CC]** (nguyên lý nhân); $A\times B\ne B\times A$ nói chung.
- *Nguồn:* S1-p80–82 (slide để dạng câu hỏi "$|P(X)|=?$", "$|A\times B|=?$"). *Trạng thái:* công thức CC.

### F-FUN-01 · Ánh xạ, ảnh, ảnh ngược {#F-FUN-01}
- $f:X\to Y$ là ánh xạ ⇔ $\forall x\in X,\ \exists!\,y\in Y:\ y=f(x)$.
- $f(A)=\{f(x)\mid x\in A\}$; $\ f^{-1}(B)=\{x\in X\mid f(x)\in B\}$ (**luôn định nghĩa được**, có thể $=\emptyset$).
- $f=g$ ⇔ cùng $X,Y$ và $f(x)=g(x)\ \forall x\in X$.
- *Ví dụ:* [FUN-01-E01](#FUN-01-E01). *Nguồn:* S1-p83–87. *Trạng thái:* SV.

### F-FUN-02 · Đơn ánh, toàn ánh, song ánh {#F-FUN-02}

| Loại | Định nghĩa | Tương đương theo phương trình $f(x)=y$ ($y\in Y$ là tham số) | Phủ định |
|------|------------|--------------------|------------|
| Đơn ánh | $f(x)=f(x')\Rightarrow x=x'$ | có **nhiều nhất 1** nghiệm $x\in X$ | $\exists x\ne x'$: $f(x)=f(x')$ |
| Toàn ánh | $f(X)=Y$ | có **ít nhất 1** nghiệm $x\in X$ | $\exists y$: phương trình vô nghiệm |
| Song ánh | đơn ánh + toàn ánh | có **đúng 1** nghiệm $x\in X$ | |


- *Ví dụ:* [FUN-02-E01](#FUN-02-E01). *Nguồn:* S1-p88–93. *Trạng thái:* SV.

### F-FUN-03 · Ánh xạ ngược, tích ánh xạ {#F-FUN-03}
- Chỉ **song ánh** mới có ánh xạ ngược: $f^{-1}:Y\to X$, $f^{-1}(y)=x$ với $f(x)=y$.
- $g\circ f:X\to Z$, $(g\circ f)(x)=g(f(x))$, cần $f(X)\subset$ miền của $g$. Nói chung $g\circ f\ne f\circ g$.
- *Ví dụ:* [FUN-02-E01](#FUN-02-E01), [FUN-03-E01](#FUN-03-E01). *Nguồn:* S1-p94–96 (ERR-01). *Trạng thái:* SV.

### F-IND-01 · Nguyên lý quy nạp toán học {#F-IND-01}
\[
\Big[P(N_0)\ \wedge\ \forall k\ge N_0\ \big(P(k)\to P(k+1)\big)\Big]\ \Longrightarrow\ \forall n\ge N_0,\ P(n)
\]

- *Lưu ý:* $N_0$ lấy theo đề ($n\ge1$, $n>3$ ⇒ $N_0=4$). *Ví dụ:* [IND-01-E01](#IND-01-E01). *Nguồn:* S1-p97. *Trạng thái:* SV.

## Chương II — Phép đếm, hệ thức đệ qui

### F-CNT-01 · Nguyên lý cộng, nguyên lý nhân {#F-CNT-01}

- **Cộng:** công việc làm bằng **một trong** các phương pháp rời nhau ($n$ cách hoặc $m$ cách) ⇒ $n+m$ cách.
- **Nhân:** công việc gồm **các bước liên tiếp** ($n$ cách rồi $m$ cách) ⇒ $n\cdot m$ cách.
- *Ví dụ:* [CNT-01-E01](#CNT-01-E01). *Nguồn:* S2-p3–5. *Trạng thái:* SV.

### F-CNT-02 · Nguyên lý chuồng bồ câu (Dirichlet) {#F-CNT-02}
$n$ chim trong $k$ chuồng ⇒ có chuồng chứa **ít nhất** $\left\lceil n/k\right\rceil$ chim ($\lceil x\rceil$ = số nguyên nhỏ nhất $\ge x$).
- *Ví dụ:* $\lceil 20/7\rceil=3$; [CNT-02-E01](#CNT-02-E01). *Nguồn:* S2-p6–7. *Trạng thái:* SV.

### F-CNT-03 · Nguyên lý bù trừ {#F-CNT-03}
\[
\lvert A\cup B\rvert=\lvert A\rvert+\lvert B\rvert-\lvert A\cap B\rvert
\]

\[
\begin{aligned}
\lvert A\cup B\cup C\rvert={}&\lvert A\rvert+\lvert B\rvert+\lvert C\rvert-\lvert A\cap B\rvert-\lvert A\cap C\rvert-\lvert B\cap C\rvert\\
&+\lvert A\cap B\cap C\rvert
\end{aligned}
\]

- Tổng quát (4 tập): cộng các $|A_i|$, trừ các giao đôi, cộng các giao ba, trừ giao bốn.
- *Nguồn:* S2-p8–10 (slide để câu hỏi "$|A\cup B\cup C|=?$" — công thức 3 tập là **CC** bằng đếm vét cạn). *Ví dụ:* [CNT-03-E02](#CNT-03-E02).

### F-CNT-04 · Hoán vị, chỉnh hợp, tổ hợp {#F-CNT-04}

| Khái niệm | Thứ tự? | Lặp? | Công thức |
|---|---|---|---|
| Hoán vị $n$ phần tử | có | không | $P_n=n!$, $0!=1$ |
| Chỉnh hợp chập $k$ của $n$ ($1\le k\le n$) | có | không | $A_n^k=\dfrac{n!}{(n-k)!}$ |
| Tổ hợp chập $k$ của $n$ | không | không | $C_n^k=\binom nk=\dfrac{n!}{k!(n-k)!}$ |


- Tính chất: $C_n^{n-k}=C_n^k$; $\ C_n^k+C_n^{k-1}=C_{n+1}^k$ (Pascal).
- Số song ánh $A\to A$ với $|A|=n$ là $n!$.
- *Ví dụ:* [CNT-04-E01](#CNT-04-E01). *Nguồn:* S2-p11–16. *Trạng thái:* SV.

### F-CNT-05 · Hoán vị lặp {#F-CNT-05}
\[
\frac{n!}{n_1!\,n_2!\cdots n_k!},\qquad n_1+n_2+\dots+n_k=n
\]

- *Ký hiệu:* $n_i$ = số đối tượng giống hệt nhau loại $i$. *Ví dụ:* SUCCESS → $\frac{7!}{3!1!2!1!}=420$, [CNT-05-E01](#CNT-05-E01). *Nguồn:* S2-p17–18. *Trạng thái:* SV, CC.

### F-CNT-06 · Tổ hợp lặp; nghiệm nguyên không âm {#F-CNT-06}
\[
K_n^k=C_{n+k-1}^{k}
\]

- $K_n^k$ = số cách chọn $k$ vật từ $n$ **loại** (được chọn lại) = số nghiệm nguyên không âm của $x_1+\dots+x_n=k$ = số cách chia $k$ vật giống nhau vào $n$ hộp phân biệt.
- *Ràng buộc:* $x_i\ge a_i$ ⇒ đặt $x_i'=x_i-a_i$, vế phải giảm $\sum a_i$. $x_i\le b$ ⇒ (tổng không ràng buộc trên) − (số nghiệm với $x_i\ge b+1$).
- *Lưu ý:* $n$ = số **ẩn/loại/hộp**, $k$ = vế phải/số vật — đừng đảo. *Ví dụ:* [CNT-06-E02](#CNT-06-E02). *Nguồn:* S2-p19–24. *Trạng thái:* SV, CC.

### F-REC-01 · Hệ thức đệ qui tuyến tính cấp $k$; cấp 1 {#F-REC-01}
\[
a_0x_n+a_1x_{n-1}+\dots+a_kx_{n-k}=f_n\quad(a_0\ne0)\qquad\text{PTĐT: } a_0\lambda^k+a_1\lambda^{k-1}+\dots+a_k=0
\]

- $f_n\equiv0$: thuần nhất. Nghiệm xác định duy nhất bởi $k$ giá trị đầu $x_0,\dots,x_{k-1}$.
- **Cấp 1:** $a_0x_n+a_1x_{n-1}=0$ ⇒ $\lambda_0=-a_1/a_0$, $x_n=C\lambda_0^n$.
- *Ví dụ:* [REC-02-E01](#REC-02-E01). *Nguồn:* S2-p29–32, p41–42 (ERR-02). *Trạng thái:* SV.

### F-REC-02 · Thuần nhất cấp 2 {#F-REC-02}
PTĐT $a_0\lambda^2+a_1\lambda+a_2=0$:
- Hai nghiệm **thực phân biệt** $\lambda_1\ne\lambda_2$: $\ x_n=C_1\lambda_1^n+C_2\lambda_2^n$.
- **Nghiệm kép** thực $\lambda_0$: $\ x_n=(C_1+nC_2)\lambda_0^n$.
- *Điều kiện:* slide chỉ xét nghiệm thực (GAP-05). *Ví dụ:* [REC-02-E02](#REC-02-E02). *Nguồn:* S2-p43–46. *Trạng thái:* SV, CC.

### F-REC-03 · Nghiệm riêng khi $f_n=\beta^nP_r(n)$ (Dạng 1) {#F-REC-03}

| Trường hợp | Dạng nghiệm riêng |
|---|---|
| $\beta$ **không** là nghiệm PTĐT | $x_n=\beta^nQ_r(n)$ |
| $\beta$ là nghiệm **đơn** | $x_n=n\,\beta^nQ_r(n)$ |
| $\beta$ là nghiệm **kép** | $x_n=n^2\beta^nQ_r(n)$ |


- $Q_r(n)=A_rn^r+\dots+A_0$: đa thức tổng quát **cùng bậc $r$** với $P_r(n)$; tìm $r+1$ hệ số bằng cách thế vào (1) và cho $n$ nhận $r+1$ giá trị (hoặc đồng nhất hệ số).
- *Lưu ý:* vế phải **chỉ là đa thức** ⇒ $\beta=1$; vế phải $2\cdot5^{n+1}=10\cdot5^n$ ⇒ $\beta=5$, $r=0$; $(2-n)2^{n-2}=\frac{2-n}{4}2^n$ ⇒ $\beta=2$, $r=1$.
- *Ví dụ:* [REC-03-E01](#REC-03-E01), [REC-03-E02](#REC-03-E02). *Nguồn:* S2-p48–51. *Trạng thái:* SV, CC.

### F-REC-04 · Chồng chất nghiệm riêng (Dạng 2) {#F-REC-04}
$f_n=f_{n1}+\dots+f_{ns}$ (mỗi $f_{ni}$ thuộc Dạng 1) ⇒ $x_n=x_{n1}+\dots+x_{ns}$ với $x_{ni}$ là nghiệm riêng của vế trái $=f_{ni}$.
- *Ví dụ:* [REC-04-E01](#REC-04-E01). *Nguồn:* S2-p52, p64–66 (ERR-09). *Trạng thái:* SV, CC.

### F-REC-05 · Cấu trúc nghiệm hệ không thuần nhất {#F-REC-05}
\[
\text{Nghiệm TQ của (1)}=\text{Nghiệm TQ của thuần nhất (2)}+\text{Một nghiệm riêng của (1)}
\]

- **Thứ tự bắt buộc:** tìm hằng số $C_1,C_2$ từ điều kiện đầu **sau khi** đã cộng nghiệm riêng ([T-14](#T-14)).
- *Nguồn:* S2-p47. *Trạng thái:* SV.

## Chương III — Quan hệ

### F-REL-01 · Quan hệ, ma trận biểu diễn, bốn tính chất {#F-REL-01}
- $R\subseteq A\times B$; $aRb\Leftrightarrow(a,b)\in R$. $M_R=[m_{ij}]$, $m_{ij}=1$ nếu $(a_i,b_j)\in R$, ngược lại 0.

| Tính chất (R trên A) | Định nghĩa | Dấu hiệu trên $M_R$ |
|----------|------------|----------------------|
| Phản xạ | $\forall a,\ aRa$ | đường chéo toàn 1 |
| Đối xứng | $aRb\to bRa$ | $M_R$ đối xứng: $m_{ij}=m_{ji}$ |
| Phản xứng | $aRb\wedge bRa\to a=b$ | $i\ne j$: không đồng thời $m_{ij}=m_{ji}=1$ |
| Bắc cầu | $aRb\wedge bRc\to aRc$ | $M_R\odot M_R\le M_R$ (tích Bool) **[CC]** |


- *Lưu ý:* đối xứng và phản xứng **không** loại trừ nhau (ví dụ quan hệ "=", hoặc $\emptyset$). Dấu hiệu bắc cầu bằng tích Bool không có trong slide — dùng để kiểm tra.
- *Ví dụ:* [REL-02-E01](#REL-02-E01). *Nguồn:* S3-p4–18. *Trạng thái:* SV.

### F-REL-02 · Quan hệ tương đương, lớp tương đương, phân hoạch {#F-REL-02}
- Tương đương = phản xạ + đối xứng + bắc cầu. $[a]_R=\{b\in A\mid bRa\}$.
- Định lý (viết dạng ⇔, xem ERR-03): $aRb\Leftrightarrow[a]_R=[b]_R$; $\ [a]_R\ne[b]_R\Leftrightarrow[a]_R\cap[b]_R=\emptyset$. Các lớp tương đương tạo **phân hoạch** của $A$; ngược lại mỗi phân hoạch xác định duy nhất một quan hệ tương đương.
- *Ví dụ:* [REL-03-E02](#REL-03-E02). *Nguồn:* S3-p21–26. *Trạng thái:* SV (dạng ⇔: CC).

### F-REL-03 · Đồng dư modulo $m$ {#F-REL-03}
- $a\equiv b\pmod m\Leftrightarrow m\mid(a-b)$ ($m$ nguyên dương). Là quan hệ tương đương trên $\mathbb Z$; có đúng $m$ lớp $[0]_m,\dots,[m-1]_m$; $\mathbb Z_m=\{[0]_m,\dots,[m-1]_m\}$; $[r]_m=[r+m]_m=\dots$
- *Ví dụ:* $[1]_8=\{\dots,-15,-7,1,9,17,\dots\}$; [REL-03-E01](#REL-03-E01). *Nguồn:* S3-p22–27. *Trạng thái:* SV.

### F-POS-01 · Quan hệ thứ tự (poset), thứ tự toàn phần {#F-POS-01}
- Thứ tự = **phản xạ + phản xứng + bắc cầu**; $(A,\preceq)$ là poset. $a,b$ so sánh được nếu $a\preceq b$ hoặc $b\preceq a$; toàn phần nếu mọi cặp so sánh được.
- Ví dụ chuẩn: $(\mathbb Z^+,\mid)$ poset, không toàn phần (5, 7); $(\mathbb Z,\mid)$ **không** poset ($3\mid-3$, $-3\mid3$, $3\ne-3$); $(P(S),\subseteq)$ poset; $(\mathbb Z^+,\le)$ toàn phần.
- *Nguồn:* S3-p29–35. *Trạng thái:* SV.

### F-POS-02 · Thứ tự từ điển {#F-POS-02}
- Trên $A\times B$ (hai tập sắp thứ tự toàn phần): $(a_1,b_1)\preceq(a_2,b_2)\Leftrightarrow a_1<a_2\ \vee\ (a_1=a_2\wedge b_1\le' b_2)$ (ERR-04).
- Trên $\Sigma^*$: $s=a_1\dots a_m\preceq t=b_1\dots b_n$ nếu (i) $s$ là **tiền tố** của $t$, hoặc (ii) tại vị trí khác nhau đầu tiên $k+1$: $a_{k+1}<b_{k+1}$.
- *Ví dụ:* $0110\prec10$; $0110\prec01100$; discreet $\prec$ discrete; [POS-02-E01](#POS-02-E01). *Nguồn:* S3-p36–41. *Trạng thái:* SV.

### F-POS-03 · Hasse, phần tử đặc biệt, chặn, sup/inf, topo {#F-POS-03}
- $b$ **trội trực tiếp** $a$: $a\prec b$ và không có $c$ với $a\prec c\prec b$. Hasse: chỉ vẽ cung trội trực tiếp, hướng từ dưới lên, bỏ khuyên và cung bắc cầu.
- **Tối đại** $m$: không có $b\ne m$ với $m\preceq b$ (không có cung đi lên). **Tối tiểu** tương tự. **Lớn nhất** $M$: $a\preceq M\ \forall a$; **nhỏ nhất** tương tự.
- Poset hữu hạn (khác rỗng) luôn có tối đại, tối tiểu; có thể không duy nhất. Lớn nhất (nếu có) là duy nhất và là tối đại duy nhất **[CC]**.
- Chặn trên của $A\subseteq S$: $x\in S$ với $a\preceq x\ \forall a\in A$ (có thể $x\notin A$). $\sup A$ = chặn trên nhỏ nhất ($a\vee b$), $\inf A$ = chặn dưới lớn nhất ($a\wedge b$) — **có thể không tồn tại**.
- Sắp xếp topo: lặp lại "lấy một phần tử tối tiểu, xóa nó" ⇒ dãy $a_1,a_2,\dots,a_m$ với $a_i\prec a_j\Rightarrow i<j$.
- *Ví dụ:* [POS-03-E01](#POS-03-E01), [POS-04-E01](#POS-04-E01), [POS-05-E01](#POS-05-E01). *Nguồn:* S3-p42–56. *Trạng thái:* SV.

## Chương IV — Đại số Bool

### F-BOO-01 · Tiên đề đại số Bool {#F-BOO-01}
$(A,\wedge,\vee)$, $A\ne\emptyset$: giao hoán, kết hợp, phân phối (cả hai chiều), phần tử trung hòa ($x\wedge1=x$, $x\vee0=x$), phần tử bù ($x\wedge\bar x=0$, $x\vee\bar x=1$). Ví dụ: $B=\{0,1\}$; tập dạng mệnh đề $n$ biến.
- *Nguồn:* S4-p5–9. *Trạng thái:* SV.

### F-BOO-02 · Hàm Bool, phép toán, dạng nối rời chính tắc {#F-BOO-02}
- Hàm Bool $n$ biến $f:B^n\to B$; bảng chân trị $2^n$ hàng. $F_n$: tập các hàm Bool $n$ biến (có $2^{2^n}$ hàm **[CC]**).
- $f\vee g=f+g-fg=\max\{f,g\}$; $\ f\wedge g=fg=\min\{f,g\}$; $\ \bar f=1-f$.
- **Từ đơn**: $x_i$ hoặc $\bar x_i$. **Đơn thức**: tích khác 0 của các từ đơn. **Từ tối tiểu**: tích đúng $n$ từ đơn. **Công thức đa thức**: tổng các đơn thức. **Dạng nối rời chính tắc**: tổng các từ tối tiểu — mỗi hàng $f=1$ ↦ một từ tối tiểu (biến bằng 1 → $x$, bằng 0 → $\bar x$).
- *Ví dụ:* [BOO-01-E01](#BOO-01-E01). *Nguồn:* S4-p10–19. *Trạng thái:* SV.

### F-BOO-03 · Biểu đồ Karnaugh (khung nhãn của nguồn) {#F-BOO-03}

**3 biến** $x,y,z$ (cột theo $x,y$; hàng theo $z$):

| | $x\bar y$ | $xy$ | $\bar xy$ | $\bar x\bar y$ |
|---|:-:|:-:|:-:|:-:|
| $z$ | 101 | 111 | 011 | 001 |
| $\bar z$ | 100 | 110 | 010 | 000 |


**4 biến** $x,y,z,t$ (cột theo $x,y$; hàng theo $z,t$):

| | $x\bar y$ | $xy$ | $\bar xy$ | $\bar x\bar y$ |
|---|:-:|:-:|:-:|:-:|
| $z\bar t$ | 1010 | 1110 | 0110 | 0010 |
| $zt$ | 1011 | 1111 | 0111 | 0011 |
| $\bar zt$ | 1001 | 1101 | 0101 | 0001 |
| $\bar z\bar t$ | 1000 | 1100 | 0100 | 0000 |


- Ô ghi chuỗi $xyz(t)$. Hai ô kề (kể cả ô đầu–ô cuối cùng hàng/cột) khác nhau đúng một biến.
- Định lý: $\mathrm{kar}(fg)=\mathrm{kar}(f)\cap\mathrm{kar}(g)$; $\ \mathrm{kar}(f\vee g)=\mathrm{kar}(f)\cup\mathrm{kar}(g)$; $\mathrm{kar}(f)$ có đúng một ô ⇔ $f$ là từ tối tiểu.
- *Lưu ý:* nhiều tài liệu khác dùng khung Gray "00,01,11,10" — **khác khung của nguồn**; trong bài thi theo nguồn hãy dùng khung trên.
- *Nguồn:* S4-p22–26 (đọc từ ảnh). *Trạng thái:* SV.

### F-BOO-04 · Tế bào, tế bào lớn, công thức đa thức tối tiểu {#F-BOO-04}

- **Tế bào**: hình chữ nhật (nghĩa rộng, kể cả quấn biên) gồm $2^{n-k}$ ô; là kar của **một** đơn thức gồm $k$ từ đơn: chiếu lên các cạnh, từ đơn nào chứa trọn hình chiếu thì có mặt.
- **Tế bào lớn** của $\mathrm{kar}(f)$: tế bào $T\subseteq\mathrm{kar}(f)$ không nằm trong tế bào nào lớn hơn cũng $\subseteq\mathrm{kar}(f)$.
- **Đơn giản hơn**: $F=m_1\vee\dots\vee m_k$ đơn giản hơn $G=M_1\vee\dots\vee M_l$ nếu có đơn ánh $h$ với mỗi $m_i$ có số từ đơn $\le$ số từ đơn của $M_{h(i)}$. **Tối tiểu**: không có công thức thực sự đơn giản hơn.
- *Nguồn:* S4-p20–21, p27, p33. *Trạng thái:* SV.

### F-BOO-05 · Cổng logic {#F-BOO-05}

| Cổng | Biểu thức | Ra = 1 khi |
|---|---|---|
| NOT | $\bar x$ | $x=0$ |
| AND | $xy$ ($x\wedge y$) | mọi ngõ vào = 1 |
| OR | $x\vee y$ ($x+y$) | có ít nhất một ngõ vào = 1 |
| NAND | $\overline{xy}$ | không phải mọi ngõ vào = 1 |
| NOR | $\overline{x\vee y}$ | mọi ngõ vào = 0 |


- *Nguồn:* S4-p66–71. *Trạng thái:* SV.

## Chương V — Đồ thị

### F-GRA-01 · Bậc, định lý bắt tay {#F-GRA-01}
\[
2m=\sum_{v\in V}\deg(v);\qquad\text{có hướng: } m=\sum_{v\in V}\deg^-(v)=\sum_{v\in V}\deg^+(v)
\]

- Số đỉnh bậc lẻ luôn **chẵn**. Khuyên đếm **2** vào bậc (vô hướng). Có hướng: $\deg(v)=\deg^-(v)+\deg^+(v)$. Bậc 0: đỉnh cô lập; bậc 1: đỉnh treo.
- Phân loại vô hướng: **đơn đồ thị** (không cạnh song song, không khuyên), **đa đồ thị** (cho phép song song, không khuyên), **giả đồ thị** (cho phép cả hai).
- *Ví dụ:* [GRA-01-E01](#GRA-01-E01). *Nguồn:* S5-p3–25. *Trạng thái:* SV, CC.

### F-GRA-02 · Ma trận kề {#F-GRA-02}
- $V=\{1,\dots,n\}$, $A=(a_{ij})$, $a_{ij}$ = số cạnh (cung) từ $i$ đến $j$. Vô hướng ⇒ $A$ đối xứng.
- **[CONFLICT] CON-01:** khuyên vô hướng — ví dụ S5-p28 ghi $a_{ii}=2$ (khớp quy ước bậc: tổng hàng $i$ = $\deg(i)$); định nghĩa chữ ở S5-p26 gợi ý 1. Toolkit mặc định theo ví dụ ($a_{ii}=2$), ghi rõ quy ước trong bài thi.
- Ma trận khoảng cách (trọng số): $d_{ii}=0$, $d_{ij}=w(v_iv_j)$ nếu có cạnh, $\infty$ nếu không.
- *Ví dụ:* [GRA-02-E01](#GRA-02-E01). *Nguồn:* S5-p26–28, p53. *Trạng thái:* SV.

### F-GRA-03 · Đẳng cấu và bất biến {#F-GRA-03}
- $G\cong G'$ ⇔ có song ánh $f:V\to V'$ với $uv\in E\Leftrightarrow f(u)f(v)\in E'$.
- Bất biến (điều kiện **cần**): cùng số đỉnh, số cạnh, số đỉnh có bậc cho trước; $\deg v=\deg f(v)$. **[INFERRED]** thêm: cùng số thành phần liên thông, cùng số chu trình độ dài 3, đỉnh kề của ảnh có cùng bậc.
- *Ví dụ:* [GRA-03-E01](#GRA-03-E01). *Nguồn:* S5-p29–35. *Trạng thái:* SV.

### F-GRA-04 · Điều kiện Euler {#F-GRA-04}
- $G$ vô hướng **liên thông**: $G$ có chu trình Euler ⇔ **mọi đỉnh bậc chẵn**.
- Liên thông, đúng **2 đỉnh bậc lẻ** ⇒ có đường đi Euler (bắt đầu ở một đỉnh lẻ, kết thúc ở đỉnh lẻ kia). Liên thông, $2k$ đỉnh bậc lẻ ($k\ge1$) ⇒ vẽ được bằng $k$ nét (CON-05).
- **Fleury:** xuất phát từ một đỉnh (đỉnh lẻ nếu tìm đường đi); qua cạnh nào xóa cạnh đó (và đỉnh cô lập); **không đi qua cầu** trừ khi không còn cách nào khác.
- *Ví dụ:* [GRA-05-E01](#GRA-05-E01). *Nguồn:* S5-p48–50. *Trạng thái:* SV, CC.

### F-GRA-05 · Dijkstra {#F-GRA-05}
- *Điều kiện:* $G$ đơn, liên thông, **trọng số dương**.
- Bước 1: $L(u_0)=0$, $L(v)=\infty$, nhãn $(\infty,-)$. Bước 2: với $v$ chưa cố định kề $u_i$: $L(v):=\min\{L(v),\ L(u_i)+w(u_iv)\}$; chọn $v$ có $L$ nhỏ nhất, cố định với nhãn $(L(v),u_i)$. Bước 3: lặp tới khi cố định đủ $n-1$ đỉnh.
- Kết quả: $0=d(u_0,u_0)<d(u_0,u_1)\le\dots\le d(u_0,u_{n-1})$; truy vết theo đỉnh trước.
- *Ví dụ:* [GRA-06-E01](#GRA-06-E01). *Nguồn:* S5-p56–59. *Trạng thái:* SV, CC.

### F-GRA-06 · Ford–Bellman {#F-GRA-06}
\[
L_0(u_0)=0,\quad L_0(v)=\infty\ (v\ne u_0);
\]

\[
L_k(u_0)=0,\qquad L_k(v)=\min\{L_{k-1}(u)+w(uv)\mid u\text{ là đỉnh trước của } v\}.
\]

- Dừng khi $L_k(v)=L_{k-1}(v)\ \forall v$ (ổn định — $L$ là khoảng cách). Nếu đến $k=n$ mà chưa ổn định ⇒ **có mạch âm**.
- *Lưu ý:* công thức của nguồn không lấy min với $L_{k-1}(v)$; nhiều tài liệu khác có lấy — với các bài trong nguồn hai cách cho cùng kết quả (CC).
- *Ví dụ:* [GRA-07-E01](#GRA-07-E01). *Nguồn:* S5-p73–74. *Trạng thái:* SV, CC.
