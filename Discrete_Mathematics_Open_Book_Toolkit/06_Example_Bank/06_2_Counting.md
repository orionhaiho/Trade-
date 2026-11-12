# Ví dụ Chương II (a) — Phép đếm {#ex-ch2a}

### CNT-01-E01 · Đếm số chẵn có 3 chữ số khác nhau (chia trường hợp chữ số 0) {#CNT-01-E01}
**D2 · V0 · Đề [SV] S2-p5 · Lời giải [SV], [CC]**

- **Đề.** Cho $X=\{0,1,2,3,4,5\}$. Có bao nhiêu số tự nhiên có 3 chữ số khác nhau lấy từ $X$ và chia hết cho 2?
- **Nhận diện.** "bao nhiêu số … chữ số khác nhau … chia hết cho 2", tập có số 0 → [CNT-01](#CNT-01).
- **Kiến thức.** Nguyên lý cộng, nhân ([F-CNT-01](#F-CNT-01)).
- **Phương pháp.** [M-11](#M-11): chọn chữ số cuối $c$ trước; tách trường hợp $c=0$ / $c\ne0$ vì 0 ảnh hưởng chữ số đầu.
- **Lời giải.** Số $\overline{abc}$, $c\in\{0,2,4\}$, $a\ne0$.
  TH1 $c=0$: $c$: 1 cách; $a\in X\setminus\{0\}$: 5 cách; $b\in X\setminus\{a,0\}$: 4 cách ⇒ $1\cdot5\cdot4=20$.
  TH2 $c\in\{2,4\}$: 2 cách; $a\in X\setminus\{c,0\}$: 4 cách; $b\in X\setminus\{a,c\}$: 4 cách ⇒ $2\cdot4\cdot4=32$.
- **Kết luận.** $20+32=52$ số.
- **Kiểm tra.** Cách bù: số 3 chữ số khác nhau: $5\cdot5\cdot4=100$; số lẻ ($c\in\{1,3,5\}$): $3\cdot4\cdot4=48$; $100-48=52$ ✓. Liệt kê bằng máy [CC].
- **Biến thể (V1).** Cùng $X$, số 3 chữ số khác nhau **chia hết cho 5**: $c=0$: 20; $c=5$: $a\in X\setminus\{0,5\}$ 4 cách, $b$ 4 cách: 16 ⇒ **36**.
- **Lỗi thường gặp.** Tính $3\cdot5\cdot4$ (không tách trường hợp 0) — [T-10](#T-10).
- **Liên kết.** [CNT-01-E02](#CNT-01-E02).

### CNT-01-E02 · Số 4 chữ số khác nhau chia hết cho 5 {#CNT-01-E02}
**D2 · V1 · [AI-GENERATED PRACTICE] · Lời giải [CC]**

- **Đề.** Từ $X=\{0,1,2,3,4,5\}$ lập được bao nhiêu số có 4 chữ số khác nhau chia hết cho 5?
- **Nhận diện / Kiến thức / Phương pháp.** [CNT-01](#CNT-01), [F-CNT-01](#F-CNT-01), [M-11](#M-11).
- **Lời giải.** $\overline{abcd}$, $d\in\{0,5\}$. $d=0$: $a$: 5, $b$: 4, $c$: 3 ⇒ 60. $d=5$: $a\in X\setminus\{0,5\}$: 4, $b$: 4, $c$: 3 ⇒ 48.
- **Kết luận.** $60+48=108$ số.
- **Kiểm tra.** Liệt kê bằng máy [CC].
- **Biến thể (V2).** "Có bao nhiêu số **lẻ** có 4 chữ số khác nhau": $d\in\{1,3,5\}$: 3; $a$: 4 (≠0, ≠d); $b$: 4; $c$: 3 ⇒ $144$.
- **Lỗi thường gặp.** Chọn $a$ trước $d$ rồi không biết $d$ còn mấy cách.
- **Liên kết.** [CNT-01-E01](#CNT-01-E01).

### CNT-02-E01 · Nguyên lý chuồng bồ câu {#CNT-02-E01}
**D2 · V0 · Đề [SV] S2-p6–7 · Lời giải [SV], [CC]**

- **Đề.** (a) 20 bồ câu trong 7 chuồng: chứng tỏ có chuồng chứa $\ge3$ con. (b) Lấy $A\subset X=\{1,\dots,9\}$, $|A|=6$. Chứng minh trong $A$ có hai phần tử có tổng bằng 10.
- **Nhận diện.** "chứng minh tồn tại / luôn có" → [CNT-02](#CNT-02).
- **Kiến thức.** [F-CNT-02](#F-CNT-02).
- **Phương pháp.** [M-12](#M-12).
- **Lời giải.** (a) $\lceil20/7\rceil=3$. (b) Lập 5 "chuồng": $\{1,9\},\{2,8\},\{3,7\},\{4,6\},\{5\}$ (hai số cùng chuồng có tổng 10, trừ chuồng $\{5\}$ chỉ có 1 phần tử). 6 phần tử của $A$ vào 5 chuồng ⇒ có chuồng chứa 2 phần tử; chuồng đó không thể là $\{5\}$ ⇒ đó là một cặp tổng 10.
- **Kết luận.** Điều phải chứng minh.
- **Kiểm tra.** Vét cạn cả $C_9^6=84$ tập con [CC]. Con số 6 là tối ưu: $A=\{1,2,3,4,5\}$ (5 phần tử) không có cặp tổng 10.
- **Biến thể (V2).** Trong 367 người luôn có 2 người cùng ngày sinh (tối đa 366 ngày): $\lceil367/366\rceil=2$.
- **Lỗi thường gặp.** Chọn chuồng sao cho hai chim cùng chuồng không suy ra được điều cần chứng minh.
- **Liên kết.** [M-12](#M-12).

### CNT-03-E01 · Bù trừ hai tập {#CNT-03-E01}
**D1 · V0 · Đề [SV] S2-p10 · Lời giải [SV]**

- **Đề.** Lớp ngoại ngữ: 24 HS học tiếng Pháp, 26 học tiếng Anh, 15 học cả hai. Mọi HS học ít nhất một môn. Lớp có bao nhiêu người?
- **Nhận diện.** "học A hoặc B, cả hai" → [CNT-03](#CNT-03).
- **Kiến thức / Phương pháp.** [F-CNT-03](#F-CNT-03), [M-13](#M-13).
- **Lời giải.** $A$: học Pháp, $B$: học Anh. $|A\cup B|=24+26-15=35$.
- **Kết luận.** 35 học sinh.
- **Kiểm tra.** Chỉ Pháp $24-15=9$; chỉ Anh $26-15=11$; cả hai 15: $9+11+15=35$ ✓.
- **Biến thể (V2).** Nếu lớp có 40 HS: số HS không học môn nào $=40-35=5$.
- **Lỗi thường gặp.** Cộng $24+26=50$ (đếm hai lần nhóm học cả hai).
- **Liên kết.** [CNT-03-E02](#CNT-03-E02).

### CNT-03-E02 · Bù trừ ba tập: chia hết cho 2, 3 hoặc 5 {#CNT-03-E02}
**D2 · V3 · [AI-GENERATED PRACTICE] · Lời giải [CC]**

- **Đề.** Có bao nhiêu số nguyên trong $\{1,\dots,1000\}$ chia hết cho ít nhất một trong các số 2, 3, 5?
- **Nhận diện.** "ít nhất một trong" ba tính chất → [CNT-03](#CNT-03).
- **Kiến thức.** [F-CNT-03](#F-CNT-03) (3 tập); số bội của $d$ trong $1..N$ là $\lfloor N/d\rfloor$; chia hết cho 2 và 3 ⇔ chia hết cho 6.
- **Phương pháp.** [M-13](#M-13).
- **Lời giải.** $|A_2|=500$, $|A_3|=333$, $|A_5|=200$; $|A_2\cap A_3|=|A_6|=166$, $|A_2\cap A_5|=|A_{10}|=100$, $|A_3\cap A_5|=|A_{15}|=66$; $|A_2\cap A_3\cap A_5|=|A_{30}|=33$.
  $|A_2\cup A_3\cup A_5|=500+333+200-166-100-66+33=734$.
- **Kết luận.** 734 số.
- **Kiểm tra.** Đếm bằng máy [CC]. Số không chia hết cho 2, 3, 5: $1000-734=266$.
- **Biến thể (V2).** Số trong $1..100$ không chia hết cho 2 và không chia hết cho 3: $100-(50+33-16)=33$.
- **Lỗi thường gặp.** Quên cộng lại giao ba tập; dùng $\lceil\ \rceil$ thay cho $\lfloor\ \rfloor$.
- **Liên kết.** [M-13](#M-13).

### CNT-04-E01 · Hoán vị, chỉnh hợp hay tổ hợp? {#CNT-04-E01}
**D1 · V4 · Đề [SV] S2-p12, p14, p16 · Lời giải [SV]+[CC]**

- **Đề.** (a) Có bao nhiêu số gồm 5 chữ số khác nhau tạo từ $\{1,2,3,4,5\}$? (b) Có bao nhiêu số tự nhiên gồm 3 chữ số tạo thành từ $1,2,3,4,5,6$? (c) Lớp 30 HS, có bao nhiêu cách chọn 10 bạn? (d) $|A|=n$: có bao nhiêu song ánh $A\to A$?
- **Nhận diện.** Thứ tự? lặp? → [CNT-04](#CNT-04).
- **Kiến thức.** [F-CNT-04](#F-CNT-04). **Phương pháp.** [M-14](#M-14).
- **Lời giải.** (a) Có thứ tự, không lặp, lấy hết: $P_5=5!=120$. (b) Slide cho đáp số $A_6^3=\frac{6!}{3!}=120$ — **ngầm hiểu các chữ số khác nhau**. Nếu đề cho phép lặp chữ số: $6^3=216$. (c) Không thứ tự: $C_{30}^{10}=30\,045\,015$. (d) Mỗi song ánh là một hoán vị của $A$: $n!$.
- **Kết luận.** 120; 120 (khác nhau) hoặc 216 (cho lặp); 30 045 015; $n!$.
- **Kiểm tra.** $C_{30}^{10}=C_{30}^{20}$; tính bằng máy [CC].
- **Biến thể (V2).** Chọn 1 lớp trưởng, 1 lớp phó, 1 thủ quỹ từ 30 HS: có thứ tự (vai trò khác nhau) ⇒ $A_{30}^3=24\,360$.
- **Lỗi thường gặp.** Đề (b) không ghi "khác nhau" — phải nêu giả thiết rõ — [T-11](#T-11).
- **Liên kết.** [CNT-05](#CNT-05), [CNT-06](#CNT-06).

### CNT-05-E01 · Hoán vị lặp — sắp xếp chữ cái {#CNT-05-E01}
**D1 · V0 · Đề [SV] S2-p18 · Lời giải [SV], [CC]**

- **Đề.** Có bao nhiêu chuỗi ký tự khác nhau tạo bằng cách sắp xếp các chữ cái của từ SUCCESS?
- **Nhận diện.** Sắp xếp có chữ lặp → [CNT-05](#CNT-05).
- **Kiến thức.** [F-CNT-05](#F-CNT-05).
- **Phương pháp.** [M-14](#M-14): đếm số lần lặp của từng chữ rồi áp công thức hoán vị lặp.
- **Lời giải.** SUCCESS: S×3, U×1, C×2, E×1; $n=7$. Số chuỗi $=\frac{7!}{3!\,1!\,2!\,1!}=\frac{5040}{12}=420$.
- **Kết luận.** 420 chuỗi.
- **Kiểm tra.** Đếm tập hoán vị khác nhau bằng máy [CC].
- **Biến thể (V1).** MISSISSIPPI: M1, I4, S4, P2: $\frac{11!}{1!4!4!2!}=34\,650$.
- **Lỗi thường gặp.** Tính $7!$ (coi các chữ S là khác nhau).
- **Liên kết.** [M-14](#M-14).

### CNT-06-E01 · Tổ hợp lặp cơ bản {#CNT-06-E01}
**D1 · V0 · Đề [SV] S2-p20 · Lời giải [SV]**

- **Đề.** Có 3 loại nón A, B, C. An mua 2 cái. Có bao nhiêu cách chọn?
- **Nhận diện.** Chọn từ các **loại**, được lặp, không thứ tự → [CNT-06](#CNT-06).
- **Kiến thức.** [F-CNT-06](#F-CNT-06): $K_n^k=C_{n+k-1}^k$ với $n=3$ loại, $k=2$ vật.
- **Phương pháp.** [M-14](#M-14): không thứ tự + có lặp ⇒ tổ hợp lặp.
- **Lời giải.** $K_3^2=C_4^2=6$: AA, AB, AC, BB, BC, CC.
- **Kết luận.** 6 cách.
- **Kiểm tra.** Liệt kê đủ 6 ✓.
- **Biến thể (V1).** Mua 5 cái từ 3 loại: $K_3^5=C_7^5=21$.
- **Lỗi thường gặp.** Đảo $n,k$: $C_{n+k-1}^{k}$ với $n$ = số **loại** — [T-12](#T-12).
- **Liên kết.** [CNT-06-E02](#CNT-06-E02).

### CNT-06-E02 · Nghiệm nguyên không âm với ràng buộc trên và dưới {#CNT-06-E02}
**D3 · V0 · Đề [SV] S2-p22 · Lời giải [SV] S2-p23–24, [CC]**

- **Đề.** Tìm số nghiệm nguyên không âm của $x_1+x_2+x_3+x_4=20$ (1) thỏa $x_1\le3$; $x_2\ge2$; $x_3>4$ (∗).
- **Nhận diện.** "số nghiệm nguyên không âm" + "≤, ≥, >" → [CNT-06](#CNT-06).
- **Kiến thức.** [F-CNT-06](#F-CNT-06). **Phương pháp.** [M-15](#M-15), [M-13](#M-13).
- **Lời giải.** Viết (∗) thành $x_1\le3,\ x_2\ge2,\ x_3\ge5$. Xét (∗∗) $x_2\ge2,x_3\ge5$ và (∗∗∗) $x_1\ge4,x_2\ge2,x_3\ge5$. Gọi $p,q,r$ là số nghiệm thỏa (∗), (∗∗), (∗∗∗): $p=q-r$.
  $q$: đặt $x_2'=x_2-2$, $x_3'=x_3-5$ ⇒ $x_1+x_2'+x_3'+x_4=13$ ⇒ $q=K_4^{13}=C_{16}^{13}=560$.
  $r$: thêm $x_1'=x_1-4$ ⇒ tổng $=9$ ⇒ $r=K_4^9=C_{12}^9=220$.
- **Kết luận.** $p=560-220=340$ nghiệm.
- **Kiểm tra.** Đếm vét cạn bằng máy: 340 [CC].
- **Biến thể (V3).** Thêm $x_4\le6$: trừ thêm trường hợp $x_4\ge7$ và cộng lại giao — bù trừ 2 tập: $p'=C_{16}^{3}-C_{12}^{3}-C_{9}^{3}+C_{5}^{3}=560-220-84+10=266$ **[CC]**.
- **Lỗi thường gặp.** Đổi $x_3>4$ thành $x_3\ge4$; lấy $C_{16}^{4}$ (sai chỉ số trên) — [T-12](#T-12).
- **Liên kết.** [CNT-06-E03](#CNT-06-E03).

### CNT-06-E03 · Chia vật giống nhau có cận trên và cận dưới {#CNT-06-E03}
**D2 · V2 · Đề [SV] S2-p25 (slide không có đáp án) · Lời giải [CC]**

- **Đề.** Có 12 trái táo chia cho 3 bạn A, B, C. A lấy ít nhất 4 trái, B và C lấy ít nhất 2 trái, C không lấy quá 5 trái. Có bao nhiêu cách chia?
- **Nhận diện.** Chia vật **giống nhau** cho người khác nhau, có ràng buộc → [CNT-06](#CNT-06) (lời văn của bài nghiệm nguyên).
- **Kiến thức.** [F-CNT-06](#F-CNT-06). **Phương pháp.** [M-15](#M-15).
- **Lời giải.** $a+b+c=12$, $a\ge4$, $b\ge2$, $2\le c\le5$. Đặt $a'=a-4$, $b'=b-2$, $c'=c-2$: $a'+b'+c'=4$, $0\le c'\le3$.
  Không cận trên: $K_3^4=C_6^4=15$. Trường hợp $c'\ge4$: $c''=c'-4$, $a'+b'+c''=0$: $K_3^0=1$.
- **Kết luận.** $15-1=14$ cách.
- **Kiểm tra.** Liệt kê: $c=2$: $a+b=10$, $a\ge4,b\ge2$: $a=4..8$ (5 cách); $c=3$: 4; $c=4$: 3; $c=5$: 2 ⇒ $5+4+3+2=14$ ✓ [CC].
- **Biến thể (V1).** Bỏ ràng buộc "C không quá 5": 15 cách.
- **Lỗi thường gặp.** Trừ cận trên trước khi đổi biến cận dưới (dùng $c\ge6$ trong phương trình gốc nhưng quên các cận dưới khác).
- **Liên kết.** [CNT-06-E02](#CNT-06-E02).
