# Ví dụ Chương II (b) — Hệ thức đệ qui {#ex-ch2b}

> Mọi nghiệm trong phần này đã được thế lại vào hệ thức với $n$ từ 2 đến 25 và vào điều kiện đầu bằng `10_Verification/verify_examples.py` **[CC]**.

### REC-01-E01 · Lập hệ thức: cầu thang bước 1 hoặc 2 bậc {#REC-01-E01}
**D2 · V0 · Đề [SV] S2-p34 · Lời giải [SV] S2-p34–36, [CC]**

- **Đề.** Cầu thang có $n$ bậc, mỗi bước đi 1 hoặc 2 bậc. Gọi $x_n$ là số cách đi hết cầu thang. Tìm hệ thức đệ qui cho $x_n$.
- **Nhận diện.** "tìm một hệ thức đệ qui cho $x_n$" → [REC-01](#REC-01).
- **Kiến thức.** Nguyên lý cộng ([F-CNT-01](#F-CNT-01)).
- **Phương pháp.** [M-16](#M-16): chia theo bước đầu tiên.
- **Lời giải.** $x_1=1$; $x_2=2$ (1+1 hoặc 2). Với $n>2$: TH1 bước đầu 1 bậc → còn $n-1$ bậc: $x_{n-1}$ cách; TH2 bước đầu 2 bậc → còn $n-2$ bậc: $x_{n-2}$ cách. Hai trường hợp rời nhau ⇒ $x_n=x_{n-1}+x_{n-2}$.
- **Kết luận.** $\begin{cases}x_n-x_{n-1}-x_{n-2}=0\\ x_1=1,\ x_2=2\end{cases}$ (thuần nhất cấp 2). Giải: [REC-02-E03](#REC-02-E03).
- **Kiểm tra.** $n=3$: liệt kê 111, 12, 21 → 3 $=x_2+x_1$ ✓; $n=4$: 5 ✓.
- **Biến thể (V1).** Mỗi bước 1, 2 hoặc 3 bậc: $x_n=x_{n-1}+x_{n-2}+x_{n-3}$, $x_1=1,x_2=2,x_3=4$ (cấp 3 — lập được, **giải ngoài phạm vi slide**).
- **Lỗi thường gặp.** Thiếu điều kiện đầu $x_2$; trường hợp chồng nhau.
- **Liên kết.** [M-16](#M-16).

### REC-01-E02 · Lập hệ thức: tháp Hà Nội {#REC-01-E02}
**D2 · V0 · Đề [SV] S2-p27 · Lời giải [SV] S2-p28, p38–39, [CC]**

- **Đề.** 3 cọc A, B, C và $n$ đĩa khác cỡ ở cọc A (đĩa nhỏ trên đĩa lớn). Chuyển hết sang cọc C, mỗi lần một đĩa, không đặt đĩa lớn lên đĩa nhỏ. Gọi $x_n$ là số lần chuyển. Tìm hệ thức đệ qui và $x_n$.
- **Nhận diện.** [REC-01](#REC-01).
- **Kiến thức / Phương pháp.** [M-16](#M-16), [F-REC-03](#F-REC-03), [F-IND-01](#F-IND-01).
- **Lời giải.** $x_1=1$. Với $n>1$: chuyển $n-1$ đĩa trên sang B qua C ($x_{n-1}$ lần), chuyển đĩa lớn nhất sang C (1 lần), chuyển $n-1$ đĩa từ B sang C ($x_{n-1}$ lần) ⇒ $x_n=2x_{n-1}+1$, $x_1=1$.
  Giải: PTĐT $\lambda-2=0$, $\lambda=2$; vế phải $1=1^n\cdot1$, $\beta=1$ không là nghiệm ⇒ nghiệm riêng $A$: $A=2A+1\Rightarrow A=-1$. Nghiệm TQ $x_n=C2^n-1$; $x_1=2C-1=1\Rightarrow C=1$.
- **Kết luận.** $x_n=2x_{n-1}+1$, $x_1=1$; $x_n=2^n-1$. Với 64 đĩa, 1 giây/lần: $2^{64}-1\approx1{,}8\times10^{19}$ giây.
- **Kiểm tra (quy nạp — S2-p39).** $n=1$: $2^1-1=1$ ✓. Giả sử $x_k=2^k-1$: $x_{k+1}=2(2^k-1)+1=2^{k+1}-1$ ✓.
- **Biến thể (V2).** Gửi tiết kiệm: mỗi năm lãi 5% rồi gửi thêm 1 (triệu): $x_n=1{,}05x_{n-1}+1$, $x_0=a$ ⇒ nghiệm riêng $A=1{,}05A+1\Rightarrow A=-20$; $x_n=(a+20)\,1{,}05^n-20$.
- **Lỗi thường gặp.** Viết $x_n=2x_{n-1}$ (quên lần chuyển đĩa lớn).
- **Liên kết.** [REC-02](#REC-02).

### REC-01-E03 · Lập hệ thức: chuỗi bit không có hai số 0 liên tiếp {#REC-01-E03}
**D2 · V1 · [AI-GENERATED PRACTICE] · Lời giải [CC]**

- **Đề.** Gọi $x_n$ là số chuỗi bit độ dài $n$ không chứa hai bit 0 liên tiếp. Tìm hệ thức đệ qui và điều kiện đầu.
- **Nhận diện / Phương pháp.** [REC-01](#REC-01), [M-16](#M-16): chia theo bit **cuối**.
- **Kiến thức.** Nguyên lý cộng ([F-CNT-01](#F-CNT-01)); hai trường hợp bit cuối rời nhau.
- **Lời giải.** $x_1=2$ (0, 1); $x_2=3$ (01, 10, 11). $n\ge3$: bit cuối là 1 → $n-1$ bit đầu là chuỗi hợp lệ bất kỳ: $x_{n-1}$; bit cuối là 0 → bit kế cuối buộc là 1, $n-2$ bit đầu hợp lệ: $x_{n-2}$.
- **Kết luận.** $x_n=x_{n-1}+x_{n-2}$, $x_1=2$, $x_2=3$.
- **Kiểm tra.** $n=3$: 010, 011, 101, 110, 111 → 5 $=3+2$ ✓; vét cạn $n\le15$ [CC].
- **Biến thể (V2).** "không chứa hai bit 1 liên tiếp" — đổi vai 0/1, cùng đáp số.
- **Lỗi thường gặp.** Chia theo bit cuối nhưng quên ràng buộc ở bit kế cuối.
- **Liên kết.** [REC-01-E01](#REC-01-E01) (cùng hệ thức, khác điều kiện đầu).

### REC-02-E01 · Thuần nhất cấp 1 {#REC-02-E01}
**D1 · V0 · Đề [SV] S2-p42 · Lời giải [SV]**

- **Đề.** Giải $2x_n-3x_{n-1}=0$, $x_0=1$.
- **Nhận diện.** Vế phải 0, cấp 1 → [REC-02](#REC-02).
- **Kiến thức / Phương pháp.** [F-REC-01](#F-REC-01), [M-17](#M-17).
- **Lời giải.** PTĐT $2\lambda-3=0\Rightarrow\lambda_0=\frac32$. Nghiệm TQ $x_n=C\left(\frac32\right)^n$; $x_0=C=1$.
- **Kết luận.** $x_n=\left(\frac32\right)^n$.
- **Kiểm tra.** $x_1=\frac32$; từ hệ thức $2x_1=3x_0\Rightarrow x_1=\frac32$ ✓.
- **Biến thể (V1).** $x_n=-3x_{n-1}$, $x_0=2$ ⇒ $x_n=2(-3)^n$.
- **Lỗi thường gặp.** Viết $\lambda=-\frac32$ (sai dấu khi chuyển vế).
- **Liên kết.** [REC-02-E02](#REC-02-E02).

### REC-02-E02 · Thuần nhất cấp 2: nghiệm phân biệt và nghiệm kép {#REC-02-E02}
**D2 · V0 · Đề [SV] S2-p44 · Lời giải [SV] S2-p45–46 + toolkit tìm hằng số, [CC]**

- **Đề.** Giải (a) $2x_n-3x_{n-1}+x_{n-2}=0$; (b) $4x_{n+1}-12x_n+9x_{n-1}=0$, $x_0=2$, $x_1=4$.
- **Nhận diện.** Thuần nhất cấp 2 → [REC-02](#REC-02).
- **Kiến thức.** [F-REC-02](#F-REC-02). **Phương pháp.** [M-17](#M-17).
- **Lời giải.** (a) PTĐT $2\lambda^2-3\lambda+1=0\Rightarrow\lambda_1=1,\ \lambda_2=\frac12$ ⇒ $x_n=C_1+C_2\left(\frac12\right)^n$.
  (b) PTĐT $4\lambda^2-12\lambda+9=0\Leftrightarrow(2\lambda-3)^2=0$ ⇒ nghiệm kép $\lambda_0=\frac32$ ⇒ $x_n=(C_1+nC_2)\left(\frac32\right)^n$. $x_0=C_1=2$; $x_1=(2+C_2)\frac32=4\Rightarrow C_2=\frac23$. Vậy $x_n=\left(2+\frac{2n}{3}\right)\left(\frac32\right)^n=(3+n)\left(\frac32\right)^{n-1}$.
- **Kết luận.** (a) $x_n=C_1+C_2\left(\frac12\right)^n$; (b) $x_n=(3+n)\left(\frac32\right)^{n-1}$ (khớp đáp số S2-p44).
- **Kiểm tra.** (b) $x_2$ từ hệ thức: $4x_2=12\cdot4-9\cdot2=30\Rightarrow x_2=7{,}5$; công thức: $5\cdot\frac32=7{,}5$ ✓.
- **Biến thể (V1).** $x_n=5x_{n-1}-6x_{n-2}$, $x_0=1,x_1=0$: $\lambda=2,3$; $C_1+C_2=1$, $2C_1+3C_2=0$ ⇒ $x_n=3\cdot2^n-2\cdot3^n$.
- **Lỗi thường gặp.** Với nghiệm kép viết $C_1\lambda_0^n+C_2\lambda_0^n$ (thực chất chỉ một hằng số) — [T-15](#T-15).
- **Liên kết.** [F-REC-02](#F-REC-02).

### REC-02-E03 · Giải hệ thức cầu thang (nghiệm vô tỉ) {#REC-02-E03}
**D2 · V3 · Đề: nối tiếp [REC-01-E01](#REC-01-E01) [SV]; lời giải [AI-GENERATED PRACTICE], [CC]**

- **Đề.** Giải $x_n=x_{n-1}+x_{n-2}$, $x_1=1$, $x_2=2$.
- **Nhận diện / Phương pháp.** [REC-02](#REC-02), [M-17](#M-17).
- **Kiến thức.** [F-REC-02](#F-REC-02) — PTĐT có hai nghiệm thực phân biệt (vô tỉ).
- **Lời giải.** PTĐT $\lambda^2-\lambda-1=0\Rightarrow\lambda_{1,2}=\frac{1\pm\sqrt5}{2}$ (thực phân biệt). $x_n=C_1\left(\frac{1+\sqrt5}{2}\right)^n+C_2\left(\frac{1-\sqrt5}{2}\right)^n$. Từ $x_1=1,x_2=2$ (dùng $\lambda^2=\lambda+1$): $C_1=\frac{5+\sqrt5}{10}$, $C_2=\frac{5-\sqrt5}{10}$.
- **Kết luận.**
\[
\begin{aligned}
x_n&=\frac{5+\sqrt5}{10}\left(\frac{1+\sqrt5}{2}\right)^n+\frac{5-\sqrt5}{10}\left(\frac{1-\sqrt5}{2}\right)^n\\
&=\frac{1}{\sqrt5}\left[\left(\frac{1+\sqrt5}{2}\right)^{n+1}-\left(\frac{1-\sqrt5}{2}\right)^{n+1}\right].
\end{aligned}
\]

- **Kiểm tra.** $n=1$: $\frac{(5+\sqrt5)(1+\sqrt5)+(5-\sqrt5)(1-\sqrt5)}{20}=\frac{20}{20}=1$ ✓; so khớp dãy 1, 2, 3, 5, 8, … tới $n=25$ [CC].
- **Biến thể (V1).** Chuỗi bit [REC-01-E03](#REC-01-E03) ($x_1=2,x_2=3$): cùng $\lambda$, $C_1=\frac{5+3\sqrt5}{10}$, $C_2=\frac{5-3\sqrt5}{10}$.
- **Lỗi thường gặp.** Áp điều kiện đầu như thể có $x_0$ (đề cho $x_1,x_2$).
- **Liên kết.** [REC-01-E01](#REC-01-E01).

### REC-03-E01 · Vế phải đa thức, $\beta=1$ là nghiệm đơn {#REC-03-E01}
**D2 · V0 · Đề [SV] S2-p53 a) · Lời giải [SV] S2-p54–56, [CC]**

- **Đề.** Giải $2x_n-3x_{n-1}+x_{n-2}=4n+1$ (1).
- **Nhận diện.** Vế phải đa thức bậc 1 ⇒ $\beta=1$ → [REC-03](#REC-03).
- **Kiến thức.** [F-REC-03](#F-REC-03), [F-REC-05](#F-REC-05). **Phương pháp.** [M-17](#M-17).
- **Lời giải.** Thuần nhất: $2\lambda^2-3\lambda+1=0\Rightarrow\lambda=1,\frac12$ ⇒ $\bar x_n=C_1+C_2\left(\frac12\right)^n$. $f_n=4n+1=1^n P_1(n)$, $\beta=1$ là **nghiệm đơn** ⇒ $x_n^*=n(an+b)$. Thế vào (1): $2n(an+b)-3(n-1)[a(n-1)+b]+(n-2)[a(n-2)+b]=4n+1$. Cho $n=0$: $a+b=1$; $n=1$: $3a+b=5$ ⇒ $a=2$, $b=-1$ ⇒ $x_n^*=n(2n-1)$.
- **Kết luận.** $x_n=C_1+C_2\left(\frac12\right)^n+n(2n-1)$.
- **Kiểm tra.** Thế $x_n^*$: $2n(2n-1)-3(n-1)(2n-3)+(n-2)(2n-5)=4n+1$ (khai triển: hệ số $n^2$: $4-6+2=0$; $n$: $-2+15-9=4$; hằng: $-9+10=1$) ✓.
- **Biến thể (V1).** Thêm $x_0=0,x_1=1$: $C_1+C_2=0$, $C_1+\frac{C_2}{2}+1=1$ ⇒ $C_1=C_2=0$ ⇒ $x_n=n(2n-1)$.
- **Lỗi thường gặp.** Chọn $x_n^*=an+b$ (quên nhân $n$ vì $\beta=1$ là nghiệm) — hệ vô nghiệm — [T-13](#T-13), [T-15](#T-15).
- **Liên kết.** [REC-03-E04](#REC-03-E04).

### REC-03-E02 · $\beta$ là nghiệm kép, có điều kiện đầu {#REC-03-E02}
**D3 · V4 · Đề [SV] S2-p53 b), S2-p57 · Lời giải [SV] S2-p57–59 (ảnh), [CC]**

- **Đề.** Giải $x_{n+1}-6x_n+9x_{n-1}=(18n+12)3^n$, $x_0=2$, $x_1=0$.
- **Nhận diện.** $f_n=3^n\cdot(18n+12)$, $\beta=3$; PTĐT có nghiệm kép 3 → [REC-03](#REC-03).
- **Kiến thức.** [F-REC-03](#F-REC-03) (TH3). **Phương pháp.** [M-17](#M-17).
- **Lời giải.** PTĐT $\lambda^2-6\lambda+9=0\Rightarrow\lambda=3$ (kép) ⇒ $\bar x_n=(C_1+nC_2)3^n$. $\beta=3$ nghiệm kép ⇒ $x_n^*=n^2(an+b)3^n$. Thế: $(n+1)^2[a(n+1)+b]3^{n+1}-6n^2[an+b]3^n+9(n-1)^2[a(n-1)+b]3^{n-1}=(18n+12)3^n$. $n=0$: $6b=12$; $n=1$: $54a+18b=90$ ⇒ $b=2$, $a=1$ ⇒ $x_n^*=n^2(n+2)3^n$.
  Nghiệm TQ $x_n=(C_1+nC_2)3^n+n^2(n+2)3^n$. $x_0=C_1=2$; $x_1=3(2+C_2)+9=0\Rightarrow C_2=-5$.
- **Kết luận.** $x_n=(n^3+2n^2-5n+2)\,3^n$.
- **Kiểm tra.** $x_2$ từ hệ thức ($n=1$): $x_2=6\cdot0-9\cdot2+30\cdot3=72$; công thức: $(8+8-10+2)\cdot9=72$ ✓.
- **Biến thể (V4).** Vế phải chỉ là $3^n$: $x_n^*=An^23^n$, thế ⇒ $6A\cdot3^n=3^n$ ⇒ $A=\frac16$, $x_n^*=\frac{n^2 3^n}{6}$.
- **Lỗi thường gặp.** Chọn $x_n^*=(an+b)3^n$ hoặc $n(an+b)3^n$ — trùng nghiệm thuần nhất, hệ vô nghiệm — [T-15](#T-15).
- **Liên kết.** [REC-03-E09](#REC-03-E09).

### REC-03-E03 · $\beta$ không là nghiệm, đa thức bậc 2 {#REC-03-E03}
**D3 · V1 · Đề [SV] S2-p53 c), S2-p60 · Lời giải [SV] S2-p60–63, [CC]**

- **Đề.** Giải $4x_{n+1}-12x_n+9x_{n-1}=(2n^2+29n+56)2^{n-1}$, $x_0=1$, $x_1=-2$.
- **Nhận diện.** $\beta=2$, $r=2$; PTĐT nghiệm kép $\frac32$ → [REC-03](#REC-03).
- **Kiến thức / Phương pháp.** [F-REC-03](#F-REC-03) (TH1), [M-17](#M-17).
- **Lời giải.** $\bar x_n=(C_1+nC_2)\left(\frac32\right)^n$. $\beta=2$ không là nghiệm ⇒ $x_n^*=(an^2+bn+c)2^n$. Thế, chia hai vế cho $2^{n-1}$:
  $16[a(n+1)^2+b(n+1)+c]-24[an^2+bn+c]+9[a(n-1)^2+b(n-1)+c]=2n^2+29n+56$.
  Đồng nhất hệ số: $n^2$: $a=2$; $n$: $14a+b=29\Rightarrow b=1$; hằng: $25a+7b+c=56\Rightarrow c=-1$. (Slide cho $n=-1,0,1$ — cùng kết quả.) ⇒ $x_n^*=(2n^2+n-1)2^n$.
  $x_n=(C_1+nC_2)\left(\frac32\right)^n+(2n^2+n-1)2^n$. $x_0$: $C_1-1=1\Rightarrow C_1=2$; $x_1$: $\frac32(2+C_2)+4=-2\Rightarrow C_2=-6$.
- **Kết luận.** $x_n=(2-6n)\left(\frac32\right)^n+(2n^2+n-1)2^n$.
- **Kiểm tra.** $x_2$: hệ thức ($n=1$): $4x_2=12(-2)-9\cdot1+87\cdot1=54\Rightarrow x_2=13{,}5$; công thức: $(2-12)\cdot\frac94+9\cdot4=-22{,}5+36=13{,}5$ ✓.
- **Biến thể (V4).** Vế phải $\left(\frac32\right)^n$: $\beta=\frac32$ nghiệm kép ⇒ $x_n^*=An^2\left(\frac32\right)^n$, $A=\frac1{12}$.
- **Lỗi thường gặp.** Quên chia/nhân lũy thừa $2^{n\pm1}$ khi thế; tính $C_1,C_2$ từ nghiệm thuần nhất — [T-14](#T-14).
- **Liên kết.** [REC-03-E02](#REC-03-E02).

### REC-03-E04 · Bài tập S2-p67 (1): $\beta=1$ nghiệm đơn {#REC-03-E04}
**D2 · V1 · Đề [SV] S2-p67 (không có lời giải) · Lời giải [CC]**

- **Đề.** $x_n+4x_{n-1}-5x_{n-2}=12n+8$, $x_0=0$, $x_1=-5$.
- **Nhận diện / Phương pháp.** [REC-03](#REC-03), [M-17](#M-17).
- **Kiến thức.** [F-REC-03](#F-REC-03) (TH2: $\beta=1$ nghiệm đơn), [F-REC-05](#F-REC-05).
- **Lời giải.** PTĐT $\lambda^2+4\lambda-5=0\Rightarrow\lambda=1,\ -5$ ⇒ $\bar x_n=C_1+C_2(-5)^n$. $\beta=1$ nghiệm đơn ⇒ $x_n^*=n(an+b)$. Thế và khai triển: hệ số $n^2$: $0$; $n$: $12a=12$; hằng: $-16a+6b=8$ ⇒ $a=1,b=4$ ⇒ $x_n^*=n^2+4n$.
  $x_0$: $C_1+C_2=0$; $x_1$: $C_1-5C_2+5=-5$ ⇒ $C_2=\frac53$, $C_1=-\frac53$.
- **Kết luận.** $x_n=-\dfrac53+\dfrac53(-5)^n+n^2+4n$.
- **Kiểm tra.** $x_2=-4x_1+5x_0+32=52$; công thức: $-\frac53+\frac{125}{3}+12=52$ ✓.
- **Biến thể (V1).** Vế phải hằng 6: $x_n^*=An$, $6A=6\Rightarrow x_n^*=n$.
- **Lỗi thường gặp.** [T-13](#T-13) (coi vế phải đa thức là "không có $\beta$").
- **Liên kết.** [REC-03-E01](#REC-03-E01).

### REC-03-E05 · Bài tập S2-p67 (2): nghiệm âm, $\beta=3$ không là nghiệm {#REC-03-E05}
**D2 · V1 · Đề [SV] S2-p67 · Lời giải [CC]**

- **Đề.** $2x_{n+2}+5x_{n+1}+2x_n=(35n+51)3^n$, $x_0=3$, $x_1=0$.
- **Nhận diện.** Vế phải $(35n+51)3^n$: $\beta=3$, $r=1$; hệ thức viết theo $x_{n+2},x_{n+1},x_n$ → [REC-03](#REC-03).
- **Kiến thức.** [F-REC-02](#F-REC-02), [F-REC-03](#F-REC-03) (TH1).
- **Phương pháp.** [M-17](#M-17).
- **Lời giải.** PTĐT $2\lambda^2+5\lambda+2=0\Rightarrow\lambda=-2,\ -\frac12$ ⇒ $\bar x_n=C_1(-2)^n+C_2\left(-\frac12\right)^n$. $\beta=3$ không là nghiệm ⇒ $x_n^*=(an+b)3^n$. Thế, chia $3^n$: $18(an+2a+b)+15(an+a+b)+2(an+b)=35an+51a+35b$ ⇒ $35a=35$, $51a+35b=51$ ⇒ $a=1,b=0$ ⇒ $x_n^*=n3^n$.
  $x_0$: $C_1+C_2=3$; $x_1$: $-2C_1-\frac{C_2}{2}+3=0$ ⇒ $C_1=1$, $C_2=2$.
- **Kết luận.** $x_n=(-2)^n+2\left(-\dfrac12\right)^n+n\,3^n$.
- **Kiểm tra.** $n=0$ trong hệ thức: $2x_2+0+6=51\Rightarrow x_2=22{,}5$; công thức: $4+\frac12+18=22{,}5$ ✓.
- **Biến thể (V4).** Vế phải $9(-2)^n$: $\beta=-2$ là nghiệm đơn ⇒ $x_n^*=An(-2)^n$, $6A=9\Rightarrow A=\frac32$.
- **Lỗi thường gặp.** Sai dấu nghiệm PTĐT; quên rằng hệ thức viết theo $x_{n+2}$ nên thế $n+2,n+1,n$.
- **Liên kết.** [REC-03-E03](#REC-03-E03).

### REC-03-E06 · Bài tập S2-p67 (3): vế phải hằng, $\beta=1$ nghiệm kép {#REC-03-E06}
**D2 · V4 · Đề [SV] S2-p67 · Lời giải [CC]**

- **Đề.** $x_{n+2}-2x_{n+1}+x_n=2$, $x_0=1$, $x_1=0$.
- **Nhận diện.** Vế phải hằng số = đa thức bậc 0 ⇒ $\beta=1$; PTĐT có nghiệm kép 1 → [REC-03](#REC-03).
- **Kiến thức.** [F-REC-03](#F-REC-03) (TH3).
- **Phương pháp.** [M-17](#M-17).
- **Lời giải.** PTĐT $(\lambda-1)^2=0$: $\lambda=1$ kép ⇒ $\bar x_n=C_1+nC_2$. Vế phải $2=1^n\cdot2$: $\beta=1$ **nghiệm kép** ⇒ $x_n^*=An^2$. Thế: $A[(n+2)^2-2(n+1)^2+n^2]=2A=2\Rightarrow A=1$. $x_n=C_1+nC_2+n^2$; $x_0$: $C_1=1$; $x_1$: $1+C_2+1=0\Rightarrow C_2=-2$.
- **Kết luận.** $x_n=n^2-2n+1=(n-1)^2$.
- **Kiểm tra.** $x_2=2x_1-x_0+2=1=(2-1)^2$ ✓.
- **Biến thể (V1).** Vế phải $2^n$: $\beta=2$ không là nghiệm ⇒ $x_n^*=A2^n$, $A(4-4+1)=1\Rightarrow x_n^*=2^n$.
- **Lỗi thường gặp.** Thử $x_n^*=A$ hoặc $An$ (đều nằm trong nghiệm thuần nhất) — [T-15](#T-15).
- **Liên kết.** [REC-03-E09](#REC-03-E09).

### REC-03-E07 · Bài tập S2-p67 (4): đa thức bậc 2, $\beta=1$ không là nghiệm {#REC-03-E07}
**D2 · V1 · Đề [SV] S2-p67 · Lời giải [CC]**

- **Đề.** $2x_n-5x_{n-1}+2x_{n-2}=-n^2-2n+3$, $x_0=1$, $x_1=3$.
- **Nhận diện.** Vế phải đa thức bậc 2 ⇒ $\beta=1$, $r=2$ → [REC-03](#REC-03).
- **Kiến thức.** [F-REC-03](#F-REC-03) (TH1).
- **Phương pháp.** [M-17](#M-17), đồng nhất hệ số.
- **Lời giải.** PTĐT $2\lambda^2-5\lambda+2=0\Rightarrow\lambda=2,\ \frac12$. $\beta=1$ không là nghiệm ⇒ $x_n^*=an^2+bn+c$. Đồng nhất: $n^2$: $-a=-1$; $n$: $2a-b=-2$; hằng: $3a+b-c=3$ ⇒ $a=1,b=4,c=4$ ⇒ $x_n^*=(n+2)^2$.
  $x_n=C_12^n+C_2\left(\frac12\right)^n+(n+2)^2$; $x_0$: $C_1+C_2=-3$; $x_1$: $2C_1+\frac{C_2}2=-6$ ⇒ $C_1=-3$, $C_2=0$.
- **Kết luận.** $x_n=(n+2)^2-3\cdot2^n$.
- **Kiểm tra.** $2x_2=5\cdot3-2\cdot1+(-4-4+3)=8\Rightarrow x_2=4$; công thức $16-12=4$ ✓.
- **Biến thể (V4).** Vế phải $2^n$: $\beta=2$ nghiệm đơn ⇒ $x_n^*=An2^n$, $A=\frac23$.
- **Lỗi thường gặp.** Đồng nhất sai hệ số khi khai triển $(n-1)^2,(n-2)^2$.
- **Liên kết.** [REC-03-E04](#REC-03-E04).

### REC-03-E08 · Bài tập S2-p67 (5): viết lại vế phải $2\cdot5^{n+1}$ {#REC-03-E08}
**D2 · V2 · Đề [SV] S2-p67 · Lời giải [CC]**

- **Đề.** $x_{n+2}-8x_{n+1}+15x_n=2\cdot5^{n+1}$, $x_0=-1$, $x_1=-2$.
- **Nhận diện.** $2\cdot5^{n+1}=10\cdot5^n$ ⇒ $\beta=5$, $r=0$.
- **Kiến thức.** [F-REC-03](#F-REC-03) (TH2).
- **Phương pháp.** [M-17](#M-17).
- **Lời giải.** PTĐT $\lambda^2-8\lambda+15=0\Rightarrow\lambda=3,5$. $\beta=5$ nghiệm đơn ⇒ $x_n^*=An5^n$. Thế: $A5^n[25(n+2)-40(n+1)+15n]=10A\cdot5^n=10\cdot5^n\Rightarrow A=1$.
  $x_n=C_13^n+C_25^n+n5^n$; $x_0$: $C_1+C_2=-1$; $x_1$: $3C_1+5C_2+5=-2$ ⇒ $C_1=1$, $C_2=-2$.
- **Kết luận.** $x_n=3^n+(n-2)5^n$.
- **Kiểm tra.** $x_2=8(-2)-15(-1)+10=9$; công thức $9+0=9$ ✓.
- **Biến thể (V1).** Vế phải $3^n$: $\beta=3$ nghiệm đơn ⇒ $x_n^*=An3^n$, $A=-\frac16$.
- **Lỗi thường gặp.** Lấy $\beta=5$ nhưng giữ hệ số 2 thay vì 10 — [T-13](#T-13).
- **Liên kết.** [F-REC-03](#F-REC-03).

### REC-03-E09 · Bài tập S2-p67 (6): $\beta=8$ nghiệm kép {#REC-03-E09}
**D2 · V0 · Đề [SV] S2-p67 · Lời giải [CC]**

- **Đề.** $x_{n+2}-16x_{n+1}+64x_n=128\cdot8^n$, $x_0=2$, $x_1=32$.
- **Nhận diện.** $\beta=8$, PTĐT $(\lambda-8)^2=0$ → [REC-03](#REC-03).
- **Kiến thức.** [F-REC-03](#F-REC-03) (TH3).
- **Phương pháp.** [M-17](#M-17).
- **Lời giải.** PTĐT $(\lambda-8)^2=0$: $\lambda=8$ kép. $\beta=8$ nghiệm kép ⇒ $x_n^*=An^28^n$. Thế: $64A\cdot8^n[(n+2)^2-2(n+1)^2+n^2]=128A\cdot8^n\Rightarrow A=1$.
  $x_n=(C_1+nC_2)8^n+n^28^n$; $x_0$: $C_1=2$; $x_1$: $8(2+C_2)+8=32\Rightarrow C_2=1$.
- **Kết luận.** $x_n=(n^2+n+2)\,8^n$.
- **Kiểm tra.** $x_2=16\cdot32-64\cdot2+128=512$; công thức $8\cdot64=512$ ✓.
- **Biến thể (V1).** Vế phải hằng 64: $\beta=1$ không là nghiệm ⇒ $49A=64$, $x_n^*=\frac{64}{49}$.
- **Lỗi thường gặp.** [T-15](#T-15).
- **Liên kết.** [REC-03-E02](#REC-03-E02).

### REC-04-E01 · Vế phải tổng ba dạng (chồng chất) {#REC-04-E01}
**D3 · V3 · Đề [SV] S2-p53 d), S2-p64 · Lời giải [SV] S2-p64–66, [CC]**

- **Đề.** Giải $x_n-4x_{n-1}+3x_{n-2}=20+(2-n)2^{n-2}+3\cdot4^n$ (1).
- **Nhận diện.** Ba dạng với $\beta=1,2,4$ → [REC-04](#REC-04).
- **Kiến thức.** [F-REC-04](#F-REC-04). **Phương pháp.** [M-17](#M-17).
- **Lời giải.** PTĐT $\lambda^2-4\lambda+3=0\Rightarrow\lambda=1,3$ ⇒ $\bar x_n=C_1+C_23^n$.
  $(1')$ vế phải 20: $\beta=1$ nghiệm đơn ⇒ $An$: $A[n-4(n-1)+3(n-2)]=-2A=20\Rightarrow A=-10$.
  $(1'')$ vế phải $(2-n)2^{n-2}$: $\beta=2$ không là nghiệm ⇒ $(an+b)2^n$; chia $2^{n-2}$: $-an+(2a-b)=2-n\Rightarrow a=1,b=0$ ⇒ $n2^n$.
  $(1''')$ vế phải $3\cdot4^n$: $\beta=4$ không là nghiệm ⇒ $A4^n$: $A4^{n-2}(16-16+3)=3\cdot4^n\Rightarrow A=16$ ⇒ $16\cdot4^n=4^{n+2}$.
- **Kết luận.** $x_n=C_1+C_2\,3^n-10n+n\,2^n+4^{n+2}$.
- **Kiểm tra.** Thế nghiệm riêng tổng vào (1) với $n=2..25$ [CC].
- **Biến thể (V3).** $x_n-4x_{n-1}+3x_{n-2}=3^n+1$: cả $\beta=3$ và $\beta=1$ đều là nghiệm đơn ⇒ $x_n^*=\frac32n3^n-\frac n2$.
- **Lỗi thường gặp.** Gộp $(2-n)2^{n-2}$ và $3\cdot4^n$ chung một dạng; xét bội của $\beta$ chung cho cả vế phải — [T-15](#T-15).
- **Ghi chú nguồn.** S2-p65 gọi đây là "Trường hợp 4" — thực chất là Dạng 2 (ERR-09).
- **Liên kết.** [F-REC-04](#F-REC-04).
