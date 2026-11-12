# Ví dụ Chương I — Logic, lượng từ, tập hợp, ánh xạ, quy nạp {#ex-ch1}

> Nhãn nguồn: **[SV]** = đề lấy từ slide (vị trí ghi kèm); **[AI-GENERATED PRACTICE]** = đề do toolkit tạo để lấp khoảng trống kỹ năng. Nhãn lời giải: **[CC]** = đã kiểm tra độc lập (bảng chân trị/vét cạn bằng `10_Verification`).

### LOG-01-E01 · Nhận biết mệnh đề; sơ cấp hay phức hợp {#LOG-01-E01}
**D1 · V0 · Đề [SV] S1-p8, S1-p9 · Lời giải [SV]+[INFERRED]**

- **Đề.** (a) Câu nào là mệnh đề: (1) Paris là thành phố của Mỹ; (2) $n$ là số tự nhiên; (3) Con nhà ai mà xinh thế!; (4) 3 là số nguyên tố; (5) Toán rời rạc là môn bắt buộc của ngành Tin học; (6) Bạn có khỏe không?; (7) $x^2+1$ luôn dương. (b) Mệnh đề nào sơ cấp, phức hợp: (i) 2 không là số nguyên tố; (ii) 2 là số nguyên tố; (iii) Nếu $3>4$ thì trời mưa; (iv) An đang xem phim hay An đang học bài; (v) Hôm nay trời đẹp và $1+1=3$.
- **Nhận diện.** "có phải mệnh đề", "sơ cấp/phức hợp" → [LOG-01](#LOG-01).
- **Kiến thức.** Mệnh đề = khẳng định có chân trị xác định (đúng hoặc sai); câu hỏi, cảm thán, mệnh lệnh không là mệnh đề (S1-p6). Phức hợp = xây từ mệnh đề khác bằng liên từ hoặc "không" (S1-p9).
- **Phương pháp.** Với mỗi câu: (1) là câu khẳng định? (2) có biến tự do không? (3) chân trị xác định không?
- **Lời giải.** (a) (1) mệnh đề, chân trị 0. (2) **không** — chứa biến $n$ chưa xác định, đây là vị từ (S1-p59). (3) không — câu cảm thán. (4) mệnh đề, chân trị 1. (5) mệnh đề (chân trị phụ thuộc chương trình đào tạo, nhưng xác định) **[INFERRED]**. (6) không — câu hỏi. (7) mệnh đề **nếu hiểu "luôn" là "với mọi $x\in\mathbb R$"**: $\forall x\in\mathbb R,\ x^2+1>0$, chân trị 1 **[INFERRED]**.
  (b) (i) phức hợp (có "không"); (ii) sơ cấp; (iii) phức hợp (kéo theo) — chân trị **1** vì tiền đề $3>4$ sai; (iv) phức hợp (tuyển); (v) phức hợp (hội) — chân trị 0 vì $1+1=3$ sai.
- **Kết luận.** Mệnh đề: (1), (4), (5), (7). Sơ cấp: (ii); phức hợp: (i), (iii), (iv), (v).
- **Kiểm tra.** Đối chiếu bảng chân trị [F-LOG-01](#F-LOG-01): $0\to q$ luôn 1; $q\wedge0=0$.
- **Biến thể (V2).** "$x+1=3$" — không là mệnh đề; "$\exists x\in\mathbb R,\ x+1=3$" — là mệnh đề đúng (lượng từ hóa biến tự do).
- **Lỗi thường gặp.** Coi câu chứa biến là mệnh đề; nghĩ "Nếu $3>4$ thì trời mưa" sai vì "vô lý" — [T-01](#T-01).
- **Liên kết.** [F-LOG-01](#F-LOG-01), [QNT-01](#QNT-01).

### LOG-02-E01 · Lập bảng chân trị {#LOG-02-E01}
**D1 · V0 · Đề [SV] S1-p22 (Bài tập) · Lời giải [CC]**

- **Đề.** Lập bảng chân trị của $E(p,q)=\neg(p\wedge q)\wedge p$ và $F(p,q,r)=p\wedge(q\vee r)\leftrightarrow\neg q$.
- **Nhận diện.** "lập bảng chân trị" → [LOG-02](#LOG-02).
- **Kiến thức.** [F-LOG-01](#F-LOG-01); $n$ biến → $2^n$ dòng. Quy ước ưu tiên: $\leftrightarrow$ yếu nhất, nên $F=\big(p\wedge(q\vee r)\big)\leftrightarrow\neg q$ **[INFERRED]** (slide không ghi ngoặc).
- **Phương pháp.** [M-01](#M-01).
- **Lời giải.**

| $p$ | $q$ | $p\wedge q$ | $\neg(p\wedge q)$ | $E$ |
|:-:|:-:|:-:|:-:|:-:|
| 0 | 0 | 0 | 1 | 0 |
| 0 | 1 | 0 | 1 | 0 |
| 1 | 0 | 0 | 1 | 1 |
| 1 | 1 | 1 | 0 | 0 |


| $p$ | $q$ | $r$ | $q\vee r$ | $p\wedge(q\vee r)$ | $\neg q$ | $F$ |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| 0 | 0 | 1 | 1 | 0 | 1 | 0 |
| 0 | 1 | 0 | 1 | 0 | 0 | 1 |
| 0 | 1 | 1 | 1 | 0 | 0 | 1 |
| 1 | 0 | 0 | 0 | 0 | 1 | 0 |
| 1 | 0 | 1 | 1 | 1 | 1 | 1 |
| 1 | 1 | 0 | 1 | 1 | 0 | 0 |
| 1 | 1 | 1 | 1 | 1 | 0 | 0 |


- **Kết luận.** $E$ đúng duy nhất khi $p=1,q=0$ (nên $E\Leftrightarrow p\wedge\neg q$). $F$ đúng tại $(p,q,r)=(0,1,0),(0,1,1),(1,0,1)$.
- **Kiểm tra.** Biến đổi: $E\Leftrightarrow(\neg p\vee\neg q)\wedge p\Leftrightarrow(\neg p\wedge p)\vee(\neg q\wedge p)\Leftrightarrow p\wedge\neg q$ — khớp cột $E$. Bảng $F$ được kiểm tra bằng chương trình.
- **Biến thể (V2).** Nếu đề hiểu $F'=p\wedge\big((q\vee r)\leftrightarrow\neg q\big)$ thì $F'$ đúng tại $(1,0,1)$ duy nhất — ngoặc thay đổi kết quả, nên ghi rõ quy ước.
- **Lỗi thường gặp.** Liệt kê thiếu dòng; tính $\leftrightarrow$ như $\to$.
- **Liên kết.** [M-01](#M-01), [LOG-03](#LOG-03).

### LOG-02-E02 · Hằng đúng, hằng sai — bẫy {#LOG-02-E02}
**D1 · V4 · Đề [SV] S1-p21 · Lời giải [CC]**

- **Đề.** Xét $B(p,q)=p\to(p\vee q)$ và $C(p,q)=p\wedge\neg(p\to q)$. Dạng nào là hằng đúng, hằng sai?
- **Nhận diện.** "hằng đúng / hằng sai" → [LOG-02](#LOG-02).
- **Kiến thức.** Hằng đúng: luôn 1; hằng sai (mâu thuẫn): luôn 0 (S1-p21).
- **Phương pháp.** [M-02](#M-02), đối chiếu [M-01](#M-01).
- **Lời giải.** $B\Leftrightarrow\neg p\vee p\vee q\Leftrightarrow1\vee q\Leftrightarrow1$ ⇒ **hằng đúng**. $C\Leftrightarrow p\wedge\neg(\neg p\vee q)\Leftrightarrow p\wedge(p\wedge\neg q)\Leftrightarrow p\wedge\neg q$: bằng 1 khi $p=1,q=0$ và bằng 0 khi $p=0$ ⇒ **không** hằng đúng, **không** hằng sai.
- **Kết luận.** $B$ hằng đúng; $C\Leftrightarrow p\wedge\neg q$ (khả đúng).
- **Kiểm tra.** Bảng 4 dòng: $B=(1,1,1,1)$; $C=(0,0,1,0)$.
- **Ghi chú nguồn.** Slide đặt $C$ ngay sau định nghĩa hằng sai nhưng **không** nói $C$ hằng sai; như đã viết, $C$ không hằng sai (ERR-13). Dạng hằng sai gần giống là $p\wedge\neg(q\to p)\Leftrightarrow p\wedge q\wedge\neg p\Leftrightarrow0$.
- **Biến thể (V1).** $(p\wedge q)\to p$ — hằng đúng (quy tắc đơn giản); $(p\to q)\wedge(p\wedge\neg q)$ — hằng sai.
- **Lỗi thường gặp.** Kết luận "hằng sai" chỉ vì thấy dấu phủ định; thử một dòng rồi kết luận cho mọi dòng — [T-05](#T-05).
- **Liên kết.** [F-LOG-03](#F-LOG-03).

### LOG-03-E01 · Chứng minh tương đương bằng luật logic {#LOG-03-E01}
**D2 · V0 · Đề [SV] S1-p29 · Lời giải [SV] S1-p30, [CC]**

- **Đề.** Chứng minh $(\neg p\to r)\wedge(q\to r)\Leftrightarrow(p\to q)\to r$.
- **Nhận diện.** "chứng minh ⇔" → [LOG-03](#LOG-03).
- **Kiến thức.** Luật kéo theo, phủ định kép, phân phối, De Morgan ([F-LOG-03](#F-LOG-03)).
- **Phương pháp.** [M-02](#M-02): khử $\to$ → gom bằng phân phối → đưa về $\to$.
- **Lời giải.**
\[
\begin{aligned}
(\neg p\to r)\wedge(q\to r)
&\Leftrightarrow(p\vee r)\wedge(\neg q\vee r) &&\text{(kéo theo, phủ định kép)}\\
&\Leftrightarrow(p\wedge\neg q)\vee r &&\text{(phân phối)}\\
&\Leftrightarrow\neg(\neg p\vee q)\vee r &&\text{(De Morgan, phủ định kép)}\\
&\Leftrightarrow\neg(p\to q)\vee r &&\text{(kéo theo)}\\
&\Leftrightarrow(p\to q)\to r &&\text{(kéo theo)}
\end{aligned}
\]

- **Kết luận.** Hai dạng tương đương logic.
- **Kiểm tra.** Bảng chân trị 8 dòng: hai vế cùng bằng 0 đúng tại các bộ $(p,q,r)$ = $(0,0,0)$, $(0,1,0)$, $(1,1,0)$ và bằng 1 ở 5 dòng còn lại [CC].
- **Biến thể (V1).** Chứng minh $(p\to r)\wedge(q\to r)\Leftrightarrow(p\vee q)\to r$ (cơ sở quy tắc chứng minh theo trường hợp): $(\neg p\vee r)\wedge(\neg q\vee r)\Leftrightarrow(\neg p\wedge\neg q)\vee r\Leftrightarrow\neg(p\vee q)\vee r\Leftrightarrow(p\vee q)\to r$.
- **Lỗi thường gặp.** Phân phối sai chiều: $(p\vee r)\wedge(\neg q\vee r)$ là "$r$ chung" nên gom thành $(p\wedge\neg q)\vee r$, không phải $(p\vee\neg q)\wedge r$ — [T-02](#T-02).
- **Liên kết.** [M-02](#M-02), [F-LOG-04](#F-LOG-04) (quy tắc 8).

### LOG-03-E02 · Rút gọn dạng mệnh đề; hệ quả logic {#LOG-03-E02}
**D1 · V1 · [AI-GENERATED PRACTICE] · Lời giải [CC]**

- **Đề.** Rút gọn $E=\neg\big(p\vee(\neg p\wedge q)\big)$ và chứng tỏ $E\Rightarrow\neg p$.
- **Nhận diện.** "rút gọn", "hệ quả logic" → [LOG-03](#LOG-03).
- **Kiến thức.** De Morgan, phân phối, phần tử bù, trung hòa; $E\Rightarrow F$ ⇔ $E\to F$ hằng đúng ([F-LOG-02](#F-LOG-02)).
- **Phương pháp.** [M-02](#M-02).
- **Lời giải.**
\[
\begin{aligned}
E&\Leftrightarrow\neg p\wedge\neg(\neg p\wedge q) &&\text{(De Morgan)}\\
&\Leftrightarrow\neg p\wedge(p\vee\neg q) &&\text{(De Morgan, phủ định kép)}\\
&\Leftrightarrow(\neg p\wedge p)\vee(\neg p\wedge\neg q) &&\text{(phân phối)}\\
&\Leftrightarrow0\vee(\neg p\wedge\neg q)\Leftrightarrow\neg p\wedge\neg q &&\text{(phần tử bù, trung hòa)}
\end{aligned}
\]

Khi đó $E\to\neg p\Leftrightarrow(\neg p\wedge\neg q)\to\neg p$ là hằng đúng (quy tắc đơn giản) ⇒ $E\Rightarrow\neg p$.

- **Kết luận.** $E\Leftrightarrow\neg p\wedge\neg q$; $E\Rightarrow\neg p$ (nhưng $\neg p\not\Rightarrow E$: $p=0,q=1$).
- **Kiểm tra.** Bảng: $E=(1,0,0,0)$ tại $pq=00,01,10,11$ — trùng $\neg p\wedge\neg q$.
- **Biến thể (V1).** Rút gọn $(p\wedge q)\vee(p\wedge\neg q)\Leftrightarrow p\wedge(q\vee\neg q)\Leftrightarrow p$.
- **Lỗi thường gặp.** Nhầm "$\Rightarrow$" với "$\Leftrightarrow$".
- **Liên kết.** [F-LOG-03](#F-LOG-03).

### LOG-04-E01 · Chứng minh suy luận bằng chuỗi quy tắc {#LOG-04-E01}
**D2 · V0 · Đề [SV] S1-p50 · Lời giải [SV] S1-p51 (đọc từ ảnh), [CC]**

- **Đề.** Chứng minh: $p\to(q\to r)$, $\ p\vee s$, $\ t\to q$, $\ \neg s\ \ \therefore\ \neg r\to\neg t$.
- **Nhận diện.** Sơ đồ tiền đề/kết luận → [LOG-04](#LOG-04); có tiền đề đơn $\neg s$ → khởi động bằng tam đoạn luận rời.
- **Kiến thức.** [F-LOG-04](#F-LOG-04) (1, 3, 4), luật phản đảo.
- **Phương pháp.** [M-03](#M-03).
- **Lời giải.**

| Bước | Mệnh đề | Lý do |
|---|---|---|
| 1 | $p\vee s$ | tiền đề |
| 2 | $\neg s$ | tiền đề |
| 3 | $p$ | 1, 2: tam đoạn luận rời |
| 4 | $p\to(q\to r)$ | tiền đề |
| 5 | $q\to r$ | 3, 4: Modus Ponens |
| 6 | $t\to q$ | tiền đề |
| 7 | $t\to r$ | 6, 5: tam đoạn luận |
| 8 | $\neg r\to\neg t$ | 7: luật kéo theo (phản đảo) |


- **Kết luận.** Suy luận đúng.
- **Kiểm tra.** Vét cạn 32 bộ chân trị: không bộ nào làm 4 tiền đề đúng mà kết luận sai [CC].
- **Biến thể (V1).** Thay tiền đề $\neg s$ bằng $s$: suy luận **sai** (phản ví dụ $p=0,q=1,r=0,s=1,t=1$: mọi tiền đề đúng, $\neg r\to\neg t=1\to0=0$).
- **Lỗi thường gặp.** Dùng $t\to q$ và $q$ để suy ra $t$ (khẳng định hệ quả) — [T-04](#T-04).
- **Liên kết.** [M-03](#M-03), [LOG-05](#LOG-05).

### LOG-04-E02 · Chứng minh suy luận bằng phản chứng {#LOG-04-E02}
**D2 · V3 · Đề [SV] S1-p52 · Lời giải [SV] S1-p53–54 (ảnh), [CC]**

- **Đề.** Kiểm tra suy luận: $p\to q$, $\ \neg r\vee s$, $\ p\vee r\ \ \therefore\ \neg q\to s$.
- **Nhận diện.** Kết luận dạng kéo theo → phản chứng ([LOG-04](#LOG-04)).
- **Kiến thức.** Quy tắc mâu thuẫn; $\neg(a\to b)\Leftrightarrow a\wedge\neg b$.
- **Phương pháp.** [M-04](#M-04).
- **Lời giải.**

| Bước | Mệnh đề | Lý do |
|---|---|---|
| 1 | $\neg(\neg q\to s)$ | giả thiết phản chứng |
| 2 | $\neg q\wedge\neg s$ | 1: kéo theo + De Morgan |
| 3 | $\neg q$ và $\neg s$ | 2: quy tắc đơn giản |
| 4 | $p\to q$ | tiền đề |
| 5 | $\neg p$ | 3, 4: quy tắc phủ định (Modus Tollens) |
| 6 | $\neg r\vee s$ | tiền đề |
| 7 | $\neg r$ | 3 ($\neg s$), 6: tam đoạn luận rời |
| 8 | $\neg p\wedge\neg r$ | 5, 7: nối liền |
| 9 | $\neg(p\vee r)$ | 8: De Morgan |
| 10 | $p\vee r$ | tiền đề |
| 11 | $0$ | 9, 10: phần tử bù |


- **Kết luận.** Suy luận đúng (quy tắc phản chứng).
- **Kiểm tra.** Vét cạn 16 bộ [CC]. Cách trực tiếp: $\neg q\to\neg p$ (phản đảo 4); $\neg p\to r$ (từ 10); $r\to s$ (từ 6) ⇒ tam đoạn luận: $\neg q\to s$.
- **Biến thể (V1).** Bỏ tiền đề $p\vee r$: suy luận sai (phản ví dụ $p=q=r=s=0$).
- **Lỗi thường gặp.** Viết giả thiết phản chứng là $q\to\neg s$ — [T-03](#T-03).
- **Liên kết.** [M-04](#M-04).

### LOG-04-E03 · Phản chứng hoặc tam đoạn luận nối tiếp {#LOG-04-E03}
**D2 · V1 · Đề [SV] S1-p46 · Lời giải [CC]**

- **Đề.** Chứng minh: $p\to r$, $\ \neg p\to q$, $\ q\to s\ \ \therefore\ \neg r\to s$.
- **Nhận diện.** Chuỗi kéo theo → [LOG-04](#LOG-04).
- **Kiến thức.** [F-LOG-04](#F-LOG-04); phản đảo.
- **Phương pháp.** [M-04](#M-04) (slide yêu cầu phản chứng); cách 2 [M-03](#M-03).
- **Lời giải (phản chứng).** Giả sử $\neg(\neg r\to s)\Leftrightarrow\neg r\wedge\neg s$. Từ $\neg r$ và $p\to r$: $\neg p$ (Modus Tollens). Từ $\neg p$ và $\neg p\to q$: $q$ (Modus Ponens). Từ $q$ và $q\to s$: $s$ (Modus Ponens). Có $s\wedge\neg s\Leftrightarrow0$ — mâu thuẫn.
- **Kết luận.** Suy luận đúng.
- **Kiểm tra (cách 2).** $\neg r\to\neg p$ (phản đảo), $\neg p\to q$, $q\to s$ ⇒ tam đoạn luận hai lần: $\neg r\to s$. Vét cạn [CC].
- **Biến thể (V2).** Lời văn: "Nếu trời mưa thì đường ướt; nếu trời không mưa thì tôi đi bộ; nếu tôi đi bộ thì tôi mệt. Vậy nếu đường không ướt thì tôi mệt." — cùng cấu trúc ⇒ đúng.
- **Lỗi thường gặp.** Suy $\neg p\to\neg r$ từ $p\to r$ (đảo sai) — [T-03](#T-03).
- **Liên kết.** [LOG-04-E02](#LOG-04-E02).

### LOG-05-E01 · Suy luận lời văn — tìm phản ví dụ {#LOG-05-E01}
**D3 · V2 · Đề [SV] S1-p49 · Lời giải [SV] S1-p49, [CC]**

- **Đề.** "Ông Minh nói rằng nếu không được tăng lương thì ông ta sẽ nghỉ việc. Mặt khác, nếu ông ấy nghỉ việc và vợ ông ấy bị mất việc thì phải bán xe. Biết rằng nếu vợ ông Minh hay đi làm trễ thì trước sau gì cũng sẽ bị mất việc và cuối cùng ông Minh đã được tăng lương. Suy ra nếu ông Minh không bán xe thì vợ ông ta đã không đi làm trễ." Suy luận có đúng không?
- **Nhận diện.** "Suy luận sau có đúng không" + lời văn → [LOG-05](#LOG-05).
- **Kiến thức.** Phản ví dụ ([F-LOG-04](#F-LOG-04) quy tắc 9).
- **Phương pháp.** Đặt biến → [M-05](#M-05).
- **Lời giải.** $p$: ông Minh được tăng lương; $q$: ông Minh nghỉ việc; $r$: vợ mất việc; $s$: phải bán xe; $t$: vợ hay đi làm trễ. Suy luận: $\neg p\to q$, $\ q\wedge r\to s$, $\ t\to r$, $\ p\ \ \therefore\ \neg s\to\neg t$.
  Đặt kết luận $=0$: $\neg s=1,\ \neg t=0$ ⇒ $s=0,\ t=1$. Tiền đề $p=1$. $t\to r=1$ với $t=1$ ⇒ $r=1$. $q\wedge r\to s=1$ với $r=1,s=0$ ⇒ $q=0$. Thử lại $\neg p\to q$: $0\to0=1$ ✓.
- **Kết luận.** Có bộ $p=1,q=0,r=1,s=0,t=1$ làm mọi tiền đề đúng, kết luận sai ⇒ **suy luận sai**. (Tình huống: được tăng lương, không nghỉ việc, vợ đi trễ và mất việc, không bán xe.)
- **Kiểm tra.** Vét cạn 32 bộ: phản ví dụ trên là duy nhất có $s=0,t=1$ [CC].
- **Biến thể (V3).** Đổi kết luận thành "Nếu ông Minh nghỉ việc và vợ hay đi làm trễ thì phải bán xe" ($q\wedge t\to s$): **đúng** — từ $t$ có $r$ ($t\to r$), có $q\wedge r$, suy ra $s$.
- **Lỗi thường gặp.** Đặt biến cho câu phủ định (đặt "không tăng lương" là $p$) làm rối dấu; thử ngẫu nhiên vài bộ rồi kết luận "đúng".
- **Liên kết.** [M-05](#M-05).

### LOG-05-E02 · Suy luận sai — và kết luận đúng là gì {#LOG-05-E02}
**D2 · V4 · Đề [SV] S1-p55 · Lời giải [SV] S1-p56 (ảnh), [CC]**

- **Đề.** Kiểm tra suy luận: $p$, $\ p\to r$, $\ p\to(q\vee\neg r)$, $\ \neg q\vee\neg s\ \ \therefore\ s$.
- **Nhận diện.** Kết luận đơn biến; nghi sai → [LOG-05](#LOG-05).
- **Kiến thức.** "Hệ (tiền đề = 1, kết luận = 0) vô nghiệm ⇔ suy luận đúng" (S1-p56).
- **Phương pháp.** [M-05](#M-05).
- **Lời giải.** Hệ: (1) $p=1$; (2) $p\to r=1$; (3) $p\to(q\vee\neg r)=1$; (4) $\neg q\vee\neg s=1$; (5) $s=0$. Từ (5): (4) đúng tự động. Từ (1),(2): $r=1$. Từ (1),(3): $q\vee\neg r=1$ ⇒ $q=1$. Thử lại: $p=q=r=1,s=0$ thỏa cả 5 phương trình.
- **Kết luận.** Hệ có nghiệm ⇒ **suy luận sai** (phản ví dụ $p=q=r=1$, $s=0$).
- **Kiểm tra.** Vét cạn 16 bộ: đây là phản ví dụ duy nhất [CC].
- **Biến thể (V4).** Với cùng tiền đề, kết luận **$\neg s$** là đúng: $p$ ⇒ $r$ ⇒ (vì $p\to(q\vee\neg r)$) $q$ ⇒ (tam đoạn luận rời với $\neg q\vee\neg s$) $\neg s$.
- **Lỗi thường gặp.** Dừng khi thấy (4) "tự đúng" mà không giải hết các biến.
- **Liên kết.** [M-05](#M-05), [LOG-04](#LOG-04).

### QNT-01-E01 · Chân trị mệnh đề lượng từ một và hai biến {#QNT-01-E01}
**D1–D2 · V0 · Đề [SV] S1-p61, p63, p65–67 · Lời giải [SV]+[CC]**

- **Đề.** (a) Với $x\in\mathbb R$: (1) $\forall x,\ x^2+3x+1\le0$; (2) $\exists x,\ x^2+3x+1\le0$; (3) $\forall x,\ x^2+1\ge2x$; (4) $\exists x,\ x^2+1<0$. (b) Với $x,y\in\mathbb R$, xét $p(x,y)$: "$x+2y<1$": $\forall x\forall y$; $\forall x\exists y$; $\exists x\forall y$; $\exists x\exists y$.
- **Nhận diện.** "đúng hay sai" + $\forall,\exists$ → [QNT-01](#QNT-01).
- **Kiến thức.** [F-QNT-01](#F-QNT-01).
- **Phương pháp.** [M-06](#M-06).
- **Lời giải.** (a) (1) **Sai**: $x=0$ cho $1\le0$ sai. (2) **Đúng**: $x=-1$: $1-3+1=-1\le0$. (3) **Đúng**: $x^2+1-2x=(x-1)^2\ge0\ \forall x$. (4) **Sai**: $x^2+1\ge1>0\ \forall x$.
  (b) $\forall x\forall y$: **sai**, $x_0=0,y_0=1$: $2\ge1$. $\forall x\exists y$: **đúng**, với $x=a$ chọn $y_a=-a/2$: $a+2y_a=0<1$. $\exists x\forall y$: **sai**, với mọi $a$, chọn $y=-a/2+2$: $a+2y=4\ge1$. $\exists x\exists y$: **đúng**, $x_0=y_0=0$.
- **Kết luận.** (a) S, Đ, Đ, S. (b) S, Đ, S, Đ.
- **Kiểm tra.** Định lý hoán vị (3): $\exists x\forall y\Rightarrow\forall y\exists x$ — ở đây vế trái sai nên không mâu thuẫn; $\forall x\exists y$ đúng nhưng $\exists x\forall y$ sai minh họa **chiều đảo không đúng**.
- **Biến thể (V1).** S1-p61: $p(x)$: "$x^2-2x+1=0$" chỉ đúng tại $x=1$ ⇒ $\exists x\,p(x)$ đúng, $\forall x\,p(x)$ sai; $p(x)$: "$x^2-2x+3=0$" ($\Delta'<0$) ⇒ $\exists x\,p(x)$ sai.
- **Lỗi thường gặp.** Ở $\exists x\forall y$ chọn $y$ trước rồi chọn $x$ theo $y$ — [T-06](#T-06).
- **Liên kết.** [QNT-02](#QNT-02).

### QNT-01-E02 · Thứ tự lượng từ và miền xác định — bẫy {#QNT-01-E02}
**D2 · V4 · [AI-GENERATED PRACTICE] · Lời giải [CC]**

- **Đề.** Xét $p(x,y)$: "$x+y=0$". Xác định chân trị: (a) $\forall x\in\mathbb Z\ \exists y\in\mathbb Z,\ p(x,y)$; (b) $\exists y\in\mathbb Z\ \forall x\in\mathbb Z,\ p(x,y)$; (c) $\forall x\in\mathbb N\ \exists y\in\mathbb N,\ p(x,y)$.
- **Nhận diện.** Hai lượng từ khác loại + đổi miền → [QNT-01](#QNT-01).
- **Kiến thức.** [F-QNT-01](#F-QNT-01); $\mathbb N=\{0,1,2,\dots\}$ (S1-p58).
- **Phương pháp.** [M-06](#M-06).
- **Lời giải.** (a) Đúng: với mỗi $x$, chọn $y=-x\in\mathbb Z$. (b) Sai: giả sử có $y_0$ với $x+y_0=0\ \forall x$; lấy $x=0$ ⇒ $y_0=0$; lấy $x=1$ ⇒ $1=0$, vô lý. (c) Sai: $x=1$ cần $y=-1\notin\mathbb N$.
- **Kết luận.** Đ, S, S.
- **Kiểm tra.** (b) phù hợp định lý: $\exists y\forall x$ sai trong khi $\forall x\exists y$ đúng — chiều $\forall\exists\Rightarrow\exists\forall$ không đúng.
- **Biến thể (V1).** $\exists x\in\mathbb N\ \forall y\in\mathbb N,\ x\le y$: đúng ($x=0$); trên $\mathbb Z$: sai.
- **Lỗi thường gặp.** Bỏ qua miền ($\mathbb N$ vs $\mathbb Z$) — [T-06](#T-06).
- **Liên kết.** [QNT-01-E01](#QNT-01-E01).

### QNT-02-E01 · Phủ định mệnh đề lượng từ {#QNT-02-E01}
**D2 · V0 · Đề [SV] S1-p71 (+ một câu AI) · Lời giải [SV]**

- **Đề.** Phủ định: (a) $\forall x\in A,\ 2x+1\le0$; (b) $\forall\varepsilon>0,\ \exists\delta>0,\ \forall x\in\mathbb R,\ |x-a|<\delta\to|f(x)-f(a)|<\varepsilon$; (c) [AI] $\forall x\in\mathbb R,\ \exists y\in\mathbb R,\ x+2y<1$.
- **Nhận diện.** "phủ định" → [QNT-02](#QNT-02).
- **Kiến thức.** [F-QNT-02](#F-QNT-02); $\neg(A\to B)\Leftrightarrow A\wedge\neg B$.
- **Phương pháp.** [M-07](#M-07).
- **Lời giải.** (a) $\exists x\in A,\ 2x+1>0$. (b) $\exists\varepsilon>0,\ \forall\delta>0,\ \exists x\in\mathbb R,\ |x-a|<\delta\ \wedge\ |f(x)-f(a)|\ge\varepsilon$. (c) $\exists x\in\mathbb R,\ \forall y\in\mathbb R,\ x+2y\ge1$.
- **Kết luận.** Như trên.
- **Kiểm tra.** (c): mệnh đề gốc đúng ([QNT-01-E01](#QNT-01-E01)) nên phủ định phải sai — đúng vậy (với mọi $x$, chọn $y=-x/2$ cho $x+2y=0<1$).
- **Biến thể (V2).** Phủ định "Mọi sinh viên đều có ít nhất một môn đạt điểm A" ⇒ "Có sinh viên mà mọi môn đều không đạt điểm A".
- **Lỗi thường gặp.** Viết $\varepsilon\le0$ (phủ định cả miền); viết $|x-a|\ge\delta\to\dots$ — [T-07](#T-07).
- **Liên kết.** [M-07](#M-07).

### SET-01-E01 · Chứng minh đẳng thức tập hợp {#SET-01-E01}
**D2 · V0 · [AI-GENERATED PRACTICE] · Lời giải [CC]**

- **Đề.** Chứng minh $A\setminus(B\cup C)=(A\setminus B)\cap(A\setminus C)$.
- **Nhận diện.** Đẳng thức tập hợp → [SET-01](#SET-01).
- **Kiến thức.** Định nghĩa $\cup,\cap,\setminus$ ([F-SET-01](#F-SET-01)); De Morgan logic.
- **Phương pháp.** [M-08](#M-08) cách 1.
- **Lời giải.**
\[
\begin{aligned}
x\in A\setminus(B\cup C)&\Leftrightarrow x\in A\wedge\neg(x\in B\vee x\in C)\\
&\Leftrightarrow x\in A\wedge x\notin B\wedge x\notin C &&\text{(De Morgan)}\\
&\Leftrightarrow(x\in A\wedge x\notin B)\wedge(x\in A\wedge x\notin C) &&\text{(lũy đẳng, giao hoán, kết hợp)}\\
&\Leftrightarrow x\in(A\setminus B)\cap(A\setminus C).
\end{aligned}
\]

- **Kết luận.** Hai tập bằng nhau.
- **Kiểm tra.** Cách 2: $A\setminus(B\cup C)=A\cap\overline{B\cup C}=A\cap\bar B\cap\bar C=(A\cap\bar B)\cap(A\cap\bar C)$. Thử $A=\{1,2,3,4\},B=\{1\},C=\{2\}$: hai vế $=\{3,4\}$; kiểm tra vét cạn trên mọi bộ tập con của $\{1,2,3\}$ [CC].
- **Biến thể (V4).** $A\setminus(B\cap C)=(A\setminus B)\cap(A\setminus C)$? **Sai**: $A=\{1,2\},B=\{1\},C=\{2\}$: vế trái $\{1,2\}$, vế phải $\emptyset$. Đúng là $A\setminus(B\cap C)=(A\setminus B)\cup(A\setminus C)$.
- **Lỗi thường gặp.** Chứng minh bằng một ví dụ cụ thể (chỉ dùng được để **bác bỏ**).
- **Liên kết.** [F-SET-01](#F-SET-01).

### SET-02-E01 · Tập các tập con, tích Đề-các {#SET-02-E01}
**D1 · V0 · Đề [SV] S1-p80–81 (câu hỏi mở) · Lời giải [CC]**

- **Đề.** (a) $Y=\{1,2,3\}$, tìm $P(Y)$. (b) $|X|=n$ thì $|P(X)|=?$ (c) $A=\{a,b\}$, $B=\{1,2,3\}$: tìm $A\times B$, $|A\times B|$; so sánh với $B\times A$.
- **Nhận diện.** $P(\cdot)$, $\times$ → [SET-02](#SET-02).
- **Kiến thức.** [F-SET-02](#F-SET-02).
- **Phương pháp.** Liệt kê tập con theo số phần tử 0, 1, 2, 3; nguyên lý nhân ([F-CNT-01](#F-CNT-01)) cho $|A\times B|$.
- **Lời giải.** (a) $P(Y)$ gồm 8 tập con:
  $\emptyset$; $\{1\}$, $\{2\}$, $\{3\}$; $\{1,2\}$, $\{1,3\}$, $\{2,3\}$; $\{1,2,3\}$.
  (b) Mỗi phần tử có 2 lựa chọn (thuộc/không thuộc tập con) ⇒ $2^n$.
  (c) $A\times B$ gồm $(a,1)$, $(a,2)$, $(a,3)$, $(b,1)$, $(b,2)$, $(b,3)$; $|A\times B|=2\cdot3=6$; $(1,a)\in B\times A$ nhưng $(1,a)\notin A\times B$ ⇒ $A\times B\ne B\times A$.
- **Kết luận.** $|P(Y)|=8$; $|P(X)|=2^n$; $|A\times B|=|A||B|=6$.
- **Kiểm tra.** $\sum_k C_3^k=1+3+3+1=8=2^3$.
- **Biến thể (V3).** $|P(A\times B)|=2^{6}=64$; $|P(\emptyset)|=1$ (chỉ có $\emptyset$).
- **Lỗi thường gặp.** Quên $\emptyset$ hoặc chính $Y$ trong $P(Y)$.
- **Liên kết.** [CNT-04](#CNT-04).

### FUN-01-E01 · Ảnh và ảnh ngược {#FUN-01-E01}
**D1 · V0 · Đề [SV] S1-p87 · Lời giải [SV], [CC]**

- **Đề.** $f:\mathbb R\to\mathbb R$, $f(x)=x^2+1$. Tìm $f([1,3])$, $f([-2,-1])$, $f([-1,3])$, $f((1,5))$, $f^{-1}(1)$, $f^{-1}(2)$, $f^{-1}(-5)$, $f^{-1}([2,5])$.
- **Nhận diện.** $f(A)$, $f^{-1}(B)$ → [FUN-01](#FUN-01).
- **Kiến thức.** [F-FUN-01](#F-FUN-01); $f$ giảm trên $(-\infty,0]$, tăng trên $[0,+\infty)$, $\min f=f(0)=1$.
- **Phương pháp.** Ảnh: dùng tính đơn điệu trên từng khúc; ảnh ngược: giải bất phương trình $f(x)\in B$.
- **Lời giải.** $f([1,3])=[2,10]$ (tăng). $f([-2,-1])=[f(-1),f(-2)]=[2,5]$ (giảm). $f([-1,3])$: chứa $0$ ⇒ min $=1$, max $=\max(f(-1),f(3))=10$ ⇒ $[1,10]$. $f((1,5))=(2,26)$. $f^{-1}(1)$: $x^2=0$ ⇒ $\{0\}$. $f^{-1}(2)$: $x^2=1$ ⇒ $\{-1,1\}$. $f^{-1}(-5)$: $x^2=-6$ vô nghiệm ⇒ $\emptyset$. $f^{-1}([2,5])$: $1\le x^2\le4$ ⇒ $[-2,-1]\cup[1,2]$.
- **Kết luận.** Như trên.
- **Kiểm tra.** Lưới số $x\in[-4,4]$ bước 0.01 xác nhận $f^{-1}([2,5])$ và $f([-1,3])$ [CC].
- **Biến thể (V1).** $f([-3,2])=[1,10]$; $f^{-1}([0,1])=\{0\}$; $f^{-1}((5,10])=[-3,-2)\cup(2,3]$.
- **Lỗi thường gặp.** Tính $f([-1,3])=[f(-1),f(3)]=[2,10]$ (quên điểm cực tiểu $x=0$) — [T-08](#T-08).
- **Liên kết.** [FUN-02-E01](#FUN-02-E01).

### FUN-02-E01 · Đơn, toàn, song ánh; ánh xạ ngược {#FUN-02-E01}
**D2 · V0 · Đề [SV] S1-p88, p90, p92, p94 · Lời giải [SV], [CC]**

- **Đề.** Xét: (a) $f:\mathbb N\to\mathbb R$, $f(x)=x^2+1$; (b) $g:\mathbb R\to\mathbb R$, $g(x)=x^2+1$; (c) $h:\mathbb R\to\mathbb R$, $h(x)=x^3+1$; (d) $k:\mathbb R\to\mathbb R$, $k(x)=2x+1$ — tìm $k^{-1}$.
- **Nhận diện.** "đơn/toàn/song ánh", "ánh xạ ngược" → [FUN-02](#FUN-02).
- **Kiến thức.** [F-FUN-02](#F-FUN-02), [F-FUN-03](#F-FUN-03).
- **Phương pháp.** [M-09](#M-09): giải $f(x)=y$ trong miền.
- **Lời giải.** (a) $x^2+1=x'^2+1\Rightarrow x^2=x'^2\Rightarrow x=x'$ (vì $x,x'\ge0$) ⇒ **đơn ánh**; $y=0$: $x^2=-1$ vô nghiệm ⇒ không toàn ánh. (b) $g(1)=g(-1)=2$ ⇒ **không đơn ánh**; $y=0$ vô nghiệm ⇒ không toàn ánh. (c) $x^3+1=y\Leftrightarrow x=\sqrt[3]{y-1}$, nghiệm duy nhất với mọi $y\in\mathbb R$ ⇒ **song ánh**. (d) $2x+1=y\Leftrightarrow x=\frac{y-1}{2}$, duy nhất ⇒ song ánh, $k^{-1}(y)=\frac{y-1}{2}$ (hay $k^{-1}(x)=\frac{x-1}{2}$).
- **Kết luận.** (a) đơn ánh, không toàn ánh; (b) không đơn, không toàn; (c), (d) song ánh; $k^{-1}(y)=\frac{y-1}{2}$.
- **Kiểm tra.** $k(k^{-1}(y))=2\cdot\frac{y-1}{2}+1=y$; $k^{-1}(k(x))=\frac{2x+1-1}{2}=x$.
- **Ghi chú nguồn.** Slide viết "$f^{-1}(x)=(y-1)/2$" — lẫn biến (ERR-01).
- **Biến thể (V4).** $g:[0,+\infty)\to[1,+\infty)$, $g(x)=x^2+1$ là song ánh, $g^{-1}(y)=\sqrt{y-1}$ — cùng công thức, đổi miền/đích thì kết quả đổi.
- **Lỗi thường gặp.** Kết luận theo công thức mà bỏ qua miền/đích — [T-08](#T-08).
- **Liên kết.** [M-09](#M-09).

### FUN-02-E02 · Hàm phân thức: đơn ánh nhưng không toàn ánh — bẫy tập đích {#FUN-02-E02}
**D3 · V4 · [AI-GENERATED PRACTICE] · Lời giải [CC]**

- **Đề.** $f:\mathbb R\setminus\{1\}\to\mathbb R$, $f(x)=\dfrac{2x+1}{x-1}$. $f$ có đơn ánh, toàn ánh không? Sửa tập đích để $f$ là song ánh và tìm $f^{-1}$.
- **Nhận diện.** Miền khuyết điểm, hàm phân thức → [FUN-02](#FUN-02).
- **Kiến thức.** [F-FUN-02](#F-FUN-02).
- **Phương pháp.** [M-09](#M-09).
- **Lời giải.** Với $y\in\mathbb R$: $\frac{2x+1}{x-1}=y\Leftrightarrow2x+1=yx-y$ (vì $x\ne1$) $\Leftrightarrow x(y-2)=y+1$.
  • $y\ne2$: $x=\frac{y+1}{y-2}$, và $x\ne1$ (vì $\frac{y+1}{y-2}=1\Leftrightarrow y+1=y-2$ vô lý) ⇒ đúng một nghiệm.
  • $y=2$: $0\cdot x=3$ vô nghiệm.
  Vậy mỗi $y$ có $\le1$ nghiệm ⇒ **đơn ánh**; $y=2$ không có tạo ảnh ⇒ **không toàn ánh**.
- **Kết luận.** Đơn ánh, không toàn ánh. $f:\mathbb R\setminus\{1\}\to\mathbb R\setminus\{2\}$ là song ánh, $f^{-1}(y)=\dfrac{y+1}{y-2}$.
- **Kiểm tra.** $f(f^{-1}(y))=\dfrac{2\frac{y+1}{y-2}+1}{\frac{y+1}{y-2}-1}$; tử $=\frac{3y}{y-2}$, mẫu $=\frac{3}{y-2}$ ⇒ $f(f^{-1}(y))=y$ ✓. Thử số: $f(4)=3$, $f^{-1}(3)=4$ ✓.
- **Biến thể (V1).** $f:\mathbb R\to\mathbb R$, $f(x)=\frac{2x}{x^2+1}$: không đơn ánh ($f(2)=f(\tfrac12)=\tfrac45$), không toàn ánh (ảnh là $[-1,1]$).
- **Lỗi thường gặp.** Quên kiểm tra nghiệm $x$ tìm được có thuộc miền ($x\ne1$).
- **Liên kết.** [FUN-02-E01](#FUN-02-E01).

### FUN-03-E01 · Tích ánh xạ, kể cả hàm từng khúc {#FUN-03-E01}
**D2 · V0 · Đề [SV] S1-p96 · Lời giải [CC]**

- **Đề.** Tìm $g\circ f$ và $f\circ g$ ($\mathbb R\to\mathbb R$): (a) $f(x)=x^2+1$, $g(x)=x+1$; (b) $f(x)=\begin{cases}x^2&x>0\\x+1&x\le0\end{cases}$, $g(x)=2x+1$.
- **Nhận diện.** "tìm $g\circ f$, $f\circ g$" → [FUN-03](#FUN-03).
- **Kiến thức.** [F-FUN-03](#F-FUN-03): $(g\circ f)(x)=g(f(x))$.
- **Phương pháp.** Thay biểu thức hàm trong vào biến của hàm ngoài; với hàm ngoài từng khúc, đặt điều kiện lên **giá trị hàm trong**.
- **Lời giải.** (a) $g\circ f(x)=(x^2+1)+1=x^2+2$; $\ f\circ g(x)=(x+1)^2+1=x^2+2x+2$.
  (b) $g\circ f(x)=2f(x)+1=\begin{cases}2x^2+1&x>0\\2x+3&x\le0\end{cases}$. $\ f\circ g(x)=f(2x+1)$: điều kiện $2x+1>0\Leftrightarrow x>-\tfrac12$ ⇒ $f\circ g(x)=\begin{cases}(2x+1)^2&x>-\tfrac12\\2x+2&x\le-\tfrac12\end{cases}$.
- **Kết luận.** Như trên; $g\circ f\ne f\circ g$.
- **Kiểm tra.** Thử $x=-0.25$: $g(-0.25)=0.5>0$ ⇒ $f(0.5)=0.25$; công thức: $(2\cdot(-0.25)+1)^2=0.25$ ✓. $x=-1$: $g(-1)=-1$, $f(-1)=0$; công thức $2(-1)+2=0$ ✓. Kiểm tra trên lưới [CC].
- **Biến thể (V1).** $f(x)=2x-3$, $g(x)=x^2$: $g\circ f=(2x-3)^2$, $f\circ g=2x^2-3$.
- **Lỗi thường gặp.** Ở $f\circ g$ giữ điều kiện "$x>0$" thay vì "$g(x)>0$".
- **Liên kết.** [F-FUN-03](#F-FUN-03).

### IND-01-E01 · Quy nạp: tổng số lẻ {#IND-01-E01}
**D1 · V0 · Đề [SV] S1-p97–99 · Lời giải [SV], [CC]**

- **Đề.** Chứng minh $1+3+5+\dots+(2n-1)=n^2$ với mọi $n\ge1$.
- **Nhận diện.** "chứng minh với mọi $n$" + tổng → [IND-01](#IND-01).
- **Kiến thức.** [F-IND-01](#F-IND-01). **Phương pháp.** [M-10](#M-10).
- **Lời giải.** $P(n)$: "$1+3+\dots+(2n-1)=n^2$". Cơ sở: $P(1)$: $1=1^2$ ✓. Quy nạp: giả sử $P(k)$: $1+3+\dots+(2k-1)=k^2$. Khi đó $1+3+\dots+(2k-1)+(2k+1)=k^2+2k+1=(k+1)^2$, tức $P(k+1)$ đúng.
- **Kết luận.** Theo nguyên lý quy nạp, $P(n)$ đúng $\forall n\ge1$.
- **Kiểm tra.** $n=4$: $1+3+5+7=16=4^2$; máy kiểm $n\le200$ [CC].
- **Biến thể (V1).** $2+4+\dots+2n=n(n+1)$.
- **Lỗi thường gặp.** Viết số hạng thứ $k+1$ là $2k-1$ thay vì $2(k+1)-1=2k+1$ — [T-09](#T-09).
- **Liên kết.** [IND-01-E02](#IND-01-E02).

### IND-01-E02 · Quy nạp: tổng $1+2+\dots+n$ {#IND-01-E02}
**D1 · V1 · Đề [SV] S1-p100 · Lời giải [CC]**

- **Đề.** Chứng minh $1+2+\dots+(n-1)+n=\dfrac{n(n+1)}{2}$, $\forall n\ge1$.
- **Nhận diện / Kiến thức / Phương pháp.** [IND-01](#IND-01), [F-IND-01](#F-IND-01), [M-10](#M-10).
- **Lời giải.** Cơ sở: $n=1$: $1=\frac{1\cdot2}{2}$ ✓. Giả sử $1+\dots+k=\frac{k(k+1)}2$. Khi đó $1+\dots+k+(k+1)=\frac{k(k+1)}2+(k+1)=\frac{(k+1)(k+2)}{2}$ — đúng dạng $P(k+1)$.
- **Kết luận.** Đúng $\forall n\ge1$.
- **Kiểm tra.** $n=10$: $55=\frac{10\cdot11}{2}$ ✓.
- **Biến thể (V3).** $1^2+2^2+\dots+n^2=\frac{n(n+1)(2n+1)}{6}$; bước quy nạp: $\frac{k(k+1)(2k+1)}6+(k+1)^2=\frac{(k+1)(k+2)(2k+3)}{6}$.
- **Lỗi thường gặp.** Chỉ kiểm tra vài giá trị rồi kết luận.
- **Liên kết.** [IND-01-E01](#IND-01-E01).

### IND-01-E03 · Quy nạp bất đẳng thức, bước cơ sở $n_0=4$ {#IND-01-E03}
**D2 · V4 · Đề [SV] S1-p100 · Lời giải [CC]**

- **Đề.** Chứng minh $\forall n>3,\ 2^n<n!$.
- **Nhận diện.** "$n>3$" ⇒ $N_0=4$ → [IND-01](#IND-01).
- **Kiến thức.** [F-IND-01](#F-IND-01). **Phương pháp.** [M-10](#M-10).
- **Lời giải.** Cơ sở $n=4$: $2^4=16<24=4!$ ✓. Giả sử $2^k<k!$ với $k\ge4$. Khi đó $2^{k+1}=2\cdot2^k<2\cdot k!<(k+1)\cdot k!=(k+1)!$ (vì $k+1\ge5>2$).
- **Kết luận.** $2^n<n!$ với mọi $n\ge4$.
- **Kiểm tra.** $n=3$: $8<6$ **sai** — đúng là phải bắt đầu từ 4; máy kiểm $4\le n\le60$ [CC].
- **Biến thể (V1).** $\forall n\ge5,\ 2^n>n^2$: cơ sở $32>25$; bước: $2^{k+1}>2k^2\ge(k+1)^2$ vì $k^2-2k-1>0$ khi $k\ge3$.
- **Lỗi thường gặp.** Lấy cơ sở $n=1$ ($2<1$ sai) rồi bế tắc; dùng bất đẳng thức "$2<k+1$" mà không nêu điều kiện $k\ge4$ — [T-09](#T-09).
- **Liên kết.** [M-10](#M-10).

### IND-01-E04 · Chia hết: quy nạp và chứng minh theo trường hợp {#IND-01-E04}
**D2 · V3 · Đề [SV] S1-p47 · Lời giải [CC]**

- **Đề.** Chứng minh $(n^3-4n)\ \vdots\ 3$ với mọi $n\in\mathbb N$.
- **Nhận diện.** Slide đặt bài này ở **quy tắc chứng minh theo trường hợp**; cũng giải được bằng quy nạp → [IND-01](#IND-01), [F-LOG-04](#F-LOG-04) (8).
- **Kiến thức.** [F-IND-01](#F-IND-01); chứng minh theo trường hợp.
- **Phương pháp.** Cách 1 theo trường hợp $n\bmod3$; cách 2 [M-10](#M-10).
- **Lời giải.** Cách 1: $n^3-4n=n(n^2-4)=n(n-2)(n+2)$. Nếu $n\equiv0\pmod3$: $3\mid n$. Nếu $n\equiv1$: $n+2\equiv0$. Nếu $n\equiv2$: $n-2\equiv0$. Mọi trường hợp đều có một thừa số chia hết cho 3.
  Cách 2: $n=0$: $0\ \vdots\ 3$. Giả sử $3\mid k^3-4k$. $(k+1)^3-4(k+1)=(k^3-4k)+3(k^2+k-1)$ chia hết cho 3.
- **Kết luận.** $3\mid n^3-4n$ với mọi $n\in\mathbb N$.
- **Kiểm tra.** $n=5$: $125-20=105=3\cdot35$ ✓; máy kiểm $n\le300$ [CC].
- **Biến thể (V1).** $6\mid n^3-n$: $n^3-n=(n-1)n(n+1)$ là tích 3 số liên tiếp (chia hết cho 2 và 3).
- **Lỗi thường gặp.** Quên trường hợp $n\equiv2$.
- **Liên kết.** [IND-01-E01](#IND-01-E01).
