# Ví dụ Chương III — Quan hệ, quan hệ thứ tự {#ex-ch3}

### REL-01-E01 · Quan hệ ↔ ma trận biểu diễn {#REL-01-E01}
**D1 · V0 · Đề [SV] S3-p13–15 · Lời giải [SV]**

- **Đề.** (a) $R$ từ $A=\{1,2,3,4\}$ đến $B=\{u,v,w\}$: $R=\{(1,u),(1,v),(2,w),(3,w),(4,u)\}$. Tìm $M_R$. (b) $R$ từ $A=\{1,2,3\}$ đến $B=\{1,2\}$: $aRb\Leftrightarrow a>b$. Tìm $M_R$. (c) $R$ từ $\{a_1,a_2,a_3\}$ đến $\{b_1,\dots,b_5\}$ có $M_R=\begin{pmatrix}0&1&0&0&0\\1&0&1&1&0\\1&0&1&0&1\end{pmatrix}$. Liệt kê $R$.
- **Nhận diện.** "ma trận biểu diễn" → [REL-01](#REL-01).
- **Kiến thức.** [F-REL-01](#F-REL-01): hàng = phần tử của $A$, cột = phần tử của $B$.
- **Phương pháp.** Duyệt từng cặp $(a_i,b_j)\in R$ và ghi 1 vào ô (hàng $i$, cột $j$); chiều ngược lại đọc từng ô bằng 1.
- **Lời giải.** (a) $M_R=\begin{pmatrix}1&1&0\\0&0&1\\0&0&1\\1&0&0\end{pmatrix}$ (hàng 1,2,3,4; cột $u,v,w$). (b) $R=\{(2,1),(3,1),(3,2)\}$, $M_R=\begin{pmatrix}0&0\\1&0\\1&1\end{pmatrix}$. (c) $R=\{(a_1,b_2),(a_2,b_1),(a_2,b_3),(a_2,b_4),(a_3,b_1),(a_3,b_3),(a_3,b_5)\}$.
- **Kết luận.** Như trên; $M_R$ cấp $|A|\times|B|$.
- **Kiểm tra.** Số số 1 trong ma trận = số cặp: (a) 5, (b) 3, (c) 7 ✓.
- **Biến thể (V1).** Quan hệ "$a$ là ước của $b$" trên $\{1,2,3,4\}$ (S3-p6): $M_R=\begin{pmatrix}1&1&1&1\\0&1&0&1\\0&0&1&0\\0&0&0&1\end{pmatrix}$ (8 cặp).
- **Lỗi thường gặp.** Đảo hàng/cột (viết $M_R$ cấp $|B|\times|A|$).
- **Liên kết.** [REL-02](#REL-02).

### REL-02-E01 · Bảng bốn tính chất của quan hệ hữu hạn {#REL-02-E01}
**D1 · V0 · Đề [SV] S3-p7, p9, p11 · Lời giải [CC]**

- **Đề.** Trên $A=\{1,2,3,4\}$ xét tính phản xạ, đối xứng, phản xứng, bắc cầu của:

\[
\begin{aligned}
R_1&=\{(1,1),(1,2),(2,1),(2,2),(3,4),(4,1),(4,4)\},\\
R_2&=\{(1,1),(1,2),(1,4),(2,2),(3,3),(4,1),(4,4)\},\\
R_3&=\{(1,1),(1,2),(2,1)\},\\
R_4&=\{(1,1),(1,2),(2,1),(2,2),(1,3),(2,3)\}.
\end{aligned}
\]

- **Nhận diện.** [REL-02](#REL-02). **Kiến thức.** [F-REL-01](#F-REL-01). **Phương pháp.** [M-18](#M-18).
- **Lời giải.**

| | Phản xạ | Đối xứng | Phản xứng | Bắc cầu |
|---|---|---|---|---|
| $R_1$ | Không: $(3,3)\notin R_1$ | Không: $(3,4)$, thiếu $(4,3)$ | Không: $(1,2),(2,1)$ | Không: $(3,4),(4,1)$ mà $(3,1)\notin R_1$ |
| $R_2$ | **Có** | Không: $(1,2)$, thiếu $(2,1)$ | Không: $(1,4),(4,1)$ | Không: $(4,1),(1,2)$ mà $(4,2)\notin R_2$ |
| $R_3$ | Không: $(2,2)\notin R_3$ | **Có** | Không: $(1,2),(2,1)$ | Không: $(2,1),(1,2)$ mà $(2,2)\notin R_3$ |
| $R_4$ | Không: $(3,3)\notin R_4$ | Không: $(1,3)$ | Không: $(1,2),(2,1)$ | **Có** |


- **Kết luận.** Như bảng (khớp các khẳng định của slide: $R_1$ không phản xạ, $R_2$ phản xạ, $R_3$ đối xứng, $R_4$ bắc cầu).
- **Kiểm tra.** Chương trình kiểm tra 4 tính chất theo định nghĩa [CC]. Bắc cầu $R_4$: mọi cặp nối $(a,b),(b,c)$: $(1,1)(1,x)$, $(1,2)(2,x)$, $(2,1)(1,x)$, $(2,2)(2,x)$ đều cho $(1,x),(2,x)\in R_4$ ✓.
- **Biến thể (V3).** Trên ma trận [AI]: $M=\begin{pmatrix}1&1&0\\0&1&1\\0&0&1\end{pmatrix}$ (trên $\{u,v,w\}$): phản xạ (chéo toàn 1), phản xứng, **không** bắc cầu ($uRv$, $vRw$, $u\not R w$).
- **Lỗi thường gặp.** Kết luận "đối xứng" khi chỉ thấy một cặp đối xứng; quên kiểm tra bắc cầu với cặp có $a=c$ (như $(2,1),(1,2)\Rightarrow(2,2)$) — [T-16](#T-16).
- **Liên kết.** [M-18](#M-18).

### REL-02-E02 · Quan hệ trên $\mathbb Z$: $aRb\Leftrightarrow ab\ge0$ — bẫy bắc cầu {#REL-02-E02}
**D2 · V4 · [AI-GENERATED PRACTICE] · Lời giải [CC]**

- **Đề.** Trên $\mathbb Z$: $aRb\Leftrightarrow ab\ge0$. $R$ có là quan hệ tương đương không?
- **Nhận diện.** Quan hệ cho bằng quy tắc trên tập vô hạn → [REL-02](#REL-02), [REL-03](#REL-03).
- **Kiến thức / Phương pháp.** [F-REL-01](#F-REL-01), [M-18](#M-18).
- **Lời giải.** Phản xạ: $a\cdot a=a^2\ge0$ ✓. Đối xứng: $ab=ba$ ✓. Bắc cầu: **sai** — $(-1)\cdot0\ge0$ và $0\cdot1\ge0$ nhưng $(-1)\cdot1<0$. Phản xứng: sai — $1\cdot2\ge0$, $2\cdot1\ge0$, $1\ne2$.
- **Kết luận.** Không phải quan hệ tương đương (không bắc cầu), cũng không phải quan hệ thứ tự.
- **Kiểm tra.** Kiểm tra vét cạn trên $\{-3,\dots,3\}$ tìm thấy đúng loại phản ví dụ chứa 0 [CC].
- **Biến thể (V4).** Trên $\mathbb Z\setminus\{0\}$, $aRb\Leftrightarrow ab>0$: **là** quan hệ tương đương (bỏ 0 thì bắc cầu đúng: cùng dấu), có 2 lớp: số dương, số âm.
- **Lỗi thường gặp.** Thử vài số dương rồi kết luận bắc cầu — [T-16](#T-16).
- **Liên kết.** [REL-03-E01](#REL-03-E01).

### REL-03-E01 · Đồng dư modulo $m$ và lớp tương đương {#REL-03-E01}
**D1 · V0 · Đề [SV] S3-p22, p24, p27 · Lời giải [SV]**

- **Đề.** (a) Chứng minh quan hệ đồng dư modulo $m$ ($aRb\Leftrightarrow m\mid a-b$) là quan hệ tương đương trên $\mathbb Z$. (b) Tìm các lớp tương đương modulo 8 chứa 0 và chứa 1. (c) Có bao nhiêu lớp đồng dư modulo $m$?
- **Nhận diện.** [REL-03](#REL-03). **Kiến thức.** [F-REL-02](#F-REL-02), [F-REL-03](#F-REL-03). **Phương pháp.** [M-18](#M-18), [M-19](#M-19).
- **Lời giải.** (a) Phản xạ: $a-a=0=0\cdot m$. Đối xứng: $a-b=km\Rightarrow b-a=(-k)m$. Bắc cầu: $a-b=km$, $b-c=jm$ ⇒ $a-c=(k+j)m$. (b) $[0]_8=\{a: 8\mid a\}=\{\dots,-16,-8,0,8,16,\dots\}$; $[1]_8=\{a: a\text{ chia 8 dư 1}\}=\{\dots,-15,-7,1,9,17,\dots\}$. (c) Đúng $m$ lớp $[0]_m,\dots,[m-1]_m$ (theo số dư), tạo phân hoạch của $\mathbb Z$; $\mathbb Z_m=\{[0]_m,\dots,[m-1]_m\}$.
- **Kết luận.** Như trên.
- **Kiểm tra.** $-7-1=-8$ chia hết cho 8 ⇒ $-7\in[1]_8$ ✓; $[0]_8\cap[1]_8=\emptyset$ (số dư khác nhau).
- **Biến thể (V1).** Lớp modulo 3: $[0]_3=\{\dots,-3,0,3,\dots\}$, $[1]_3=\{\dots,-2,1,4,\dots\}$, $[2]_3=\{\dots,-1,2,5,\dots\}$; $[5]_3=[2]_3$.
- **Lỗi thường gặp.** Ghi $-7\in[7]_8$ "vì giống 7" — dùng số dư không âm: $-7=8\cdot(-1)+1$.
- **Liên kết.** [M-19](#M-19).

### REL-03-E02 · Từ phân hoạch sang quan hệ tương đương {#REL-03-E02}
**D2 · V2 · [AI-GENERATED PRACTICE] dựa trên S3-p26 · Lời giải [CC]**

- **Đề.** Trên $A=\{1,2,3,4,5,6\}$ cho phân hoạch $\{\{1,2\},\{3\},\{4,5,6\}\}$. Viết quan hệ tương đương $R$ tương ứng; $|R|=?$; tìm $[5]_R$.
- **Nhận diện.** "phân hoạch" ↔ quan hệ tương đương → [REL-03](#REL-03).
- **Kiến thức.** [F-REL-02](#F-REL-02): $aRb\Leftrightarrow a,b$ cùng thuộc một khối.
- **Phương pháp.** [M-19](#M-19) theo chiều ngược: mỗi khối $B$ của phân hoạch góp các cặp $B\times B$.
- **Lời giải.** $R=\{1,2\}^2\cup\{3\}^2\cup\{4,5,6\}^2$, tức
\[
\begin{aligned}
R=\{&(1,1),(1,2),(2,1),(2,2),(3,3),\\
&(4,4),(4,5),(4,6),(5,4),(5,5),(5,6),(6,4),(6,5),(6,6)\}.
\end{aligned}
\]
  $|R|=2^2+1^2+3^2=14$. $[5]_R=\{4,5,6\}$.
- **Kết luận.** $|R|=14$, $[5]_R=\{4,5,6\}$.
- **Kiểm tra.** $R$ phản xạ, đối xứng, bắc cầu (máy kiểm) và các lớp đúng bằng các khối [CC].
- **Biến thể (V1).** S3-p21: trên $\mathbb R$, $aRb\Leftrightarrow a-b\in\mathbb Z$ là tương đương; $[x]=\{x+k\mid k\in\mathbb Z\}$, ví dụ $[0{,}5]=\{\dots,-0{,}5;\ 0{,}5;\ 1{,}5;\dots\}$.
- **Lỗi thường gặp.** Quên các cặp $(a,a)$.
- **Liên kết.** [M-19](#M-19).

### POS-01-E01 · Có phải poset? Thứ tự toàn phần? {#POS-01-E01}
**D2 · V0 · Đề [SV] S3-p31–35 · Lời giải [SV]**

- **Đề.** Xét: (a) $(\mathbb Z^+,\mid)$; (b) $(\mathbb Z,\mid)$; (c) $(P(S),\subseteq)$; (d) $(\mathbb Z^+,\le)$. Cái nào là poset? Cái nào là thứ tự toàn phần?
- **Nhận diện.** [POS-01](#POS-01). **Kiến thức.** [F-POS-01](#F-POS-01). **Phương pháp.** [M-18](#M-18).
- **Lời giải.** (a) Phản xạ: $x=1\cdot x$. Bắc cầu: $b=ka$, $c=jb$ ⇒ $c=(jk)a$. Phản xứng: $b=ka$, $a=jb$ ⇒ $a=jka$ ⇒ $jk=1$ ⇒ $j=k=1$ (vì $j,k$ nguyên dương) ⇒ $a=b$. ⇒ poset; **không toàn phần** (5 và 7 không so sánh được). (b) Không phản xứng: $3\mid-3$, $-3\mid3$, $3\ne-3$ ⇒ **không** poset. (c) $A\subseteq A$; $A\subseteq B\subseteq C\Rightarrow A\subseteq C$; $A\subseteq B,B\subseteq A\Rightarrow A=B$ ⇒ poset; không toàn phần khi $|S|\ge2$ ($\{a\},\{b\}$). (d) poset toàn phần.
- **Kết luận.** (a), (c), (d) là poset; chỉ (d) toàn phần.
- **Kiểm tra.** (b): lỗi xảy ra vì $k=j=-1$ cũng cho $jk=1$ trên $\mathbb Z$.
- **Biến thể (V4).** $(\{1,2,4,8\},\mid)$ là thứ tự toàn phần (một xích); $(\{2,3,6\},\mid)$ không toàn phần.
- **Lỗi thường gặp.** Chứng minh phản xứng trên $\mathbb Z$ giống trên $\mathbb Z^+$ — [T-17](#T-17).
- **Liên kết.** [POS-03](#POS-03).

### POS-02-E01 · Thứ tự từ điển {#POS-02-E01}
**D1 · V0 · Đề [SV] S3-p36, p40–41 · Lời giải [SV]**

- **Đề.** So sánh theo thứ tự từ điển: (a) discreet / discrete; (b) discreet / discreetness; (c) $0110$ / $10$; (d) $0110$ / $01100$. (e) Với thứ tự "$a_i\le b_i\ \forall i$" trên chuỗi bit cùng độ dài, $0110$ và $1000$ có so sánh được không?
- **Nhận diện.** [POS-02](#POS-02). **Kiến thức.** [F-POS-02](#F-POS-02).
- **Phương pháp.** So từng ký tự từ trái sang; dừng ở vị trí khác nhau đầu tiên hoặc khi chuỗi ngắn hơn hết ký tự (tiền tố).
- **Lời giải.** (a) Giống tới "discre", vị trí 7: e < t ⇒ discreet $\prec$ discrete. (b) discreet là tiền tố ⇒ discreet $\prec$ discreetness. (c) Vị trí 1: $0<1$ ⇒ $0110\prec10$ (độ dài không quan trọng). (d) $0110$ là tiền tố ⇒ $0110\prec01100$. (e) Không: vị trí 1 có $0<1$ nhưng vị trí 2 có $1>0$.
- **Kết luận.** Như trên.
- **Kiểm tra.** So sánh chuỗi bằng máy (thứ tự từ điển chuẩn trùng định nghĩa S3-p39) ✓.
- **Biến thể (V1).** Sắp tăng: b, ab, a, aab ⇒ a $\prec$ aab $\prec$ ab $\prec$ b.
- **Lỗi thường gặp.** So độ dài trước (đó là thứ tự khác) — [T-29](#T-29).
- **Liên kết.** [F-POS-02](#F-POS-02).

### POS-03-E01 · Hasse, tối đại, tối tiểu, lớn nhất, nhỏ nhất {#POS-03-E01}
**D2 · V0 · Đề [SV] S3-p48 · Lời giải [SV], [CC]**

- **Đề.** Vẽ biểu đồ Hasse và tìm phần tử tối đại, tối tiểu, lớn nhất, nhỏ nhất của poset $S=\{2,4,5,10,12,20,25\}$ với quan hệ chia hết $\mid$.
- **Nhận diện.** [POS-03](#POS-03). **Kiến thức.** [F-POS-03](#F-POS-03). **Phương pháp.** [M-20](#M-20).
- **Lời giải.** Cặp $a\mid b$ ($a\ne b$): 2|4, 2|10, 2|12, 2|20, 4|12, 4|20, 5|10, 5|20, 5|25, 10|20. Bỏ cặp bắc cầu: 2|12 (qua 4), 2|20 (qua 4 hoặc 10), 5|20 (qua 10). **Cung Hasse:** 2–4, 2–10, 4–12, 4–20, 5–10, 5–25, 10–20.
  Tầng dưới: 2, 5; tầng giữa: 4, 10, 25; tầng trên: 12, 20.
  Tối đại: không có cung đi lên: 12, 20, 25. Tối tiểu: không có cung đi xuống: 2, 5. Lớn nhất / nhỏ nhất: **không có** (có hơn một tối đại / tối tiểu).
- **Kết luận.** Tối đại 12, 20, 25; tối tiểu 2, 5; không có lớn nhất, nhỏ nhất.
- **Kiểm tra.** Chương trình liệt kê tối đại/tối tiểu theo định nghĩa [CC]. 25 vừa thuộc tầng giữa vừa tối đại — tối đại không nhất thiết ở tầng cao nhất.
- **Biến thể (V1).** $(\{1,2,3,4,6,12\},\mid)$: cung 1–2, 1–3, 2–4, 2–6, 3–6, 4–12, 6–12; nhỏ nhất 1, lớn nhất 12.
- **Lỗi thường gặp.** Vẽ cả cung 2–12, 2–20 (bắc cầu); cho rằng tối đại là lớn nhất — [T-18](#T-18).
- **Liên kết.** [POS-04-E01](#POS-04-E01).

### POS-04-E01 · Chặn trên, chặn dưới, sup, inf {#POS-04-E01}
**D2 · V4 · [AI-GENERATED PRACTICE] (định nghĩa S3-p50–53) · Lời giải [CC]**

- **Đề.** Poset $(S,\mid)$, $S=\{2,3,4,6,12,18\}$. Tìm chặn trên, chặn dưới, sup, inf (nếu có) của $A=\{2,3\}$, $B=\{12,18\}$, $C=\{4,6\}$.
- **Nhận diện.** [POS-04](#POS-04). **Kiến thức.** [F-POS-03](#F-POS-03). **Phương pháp.** [M-20](#M-20).
- **Lời giải.** Hasse: 2–4, 2–6, 3–6, 4–12, 6–12, 6–18.
  $A=\{2,3\}$: chặn trên = phần tử chia hết cho cả 2 và 3 trong $S$: $6,12,18$; nhỏ nhất trong chúng: 6 ($6\mid12$, $6\mid18$) ⇒ $\sup A=6$. Chặn dưới: ước chung của 2, 3 trong $S$: **không có** (1 $\notin S$) ⇒ $\inf A$ không tồn tại.
  $B=\{12,18\}$: chặn trên: không có ($36\notin S$) ⇒ không có sup. Chặn dưới: $2,3,6$; lớn nhất: 6 ($2\mid6$, $3\mid6$) ⇒ $\inf B=6$.
  $C=\{4,6\}$: chặn trên: 12 ⇒ $\sup C=12$; chặn dưới: 2 ⇒ $\inf C=2$.
- **Kết luận.** $\sup A=6$, $\inf A$ không có; $\sup B$ không có, $\inf B=6$; $\sup C=12$, $\inf C=2$.
- **Kiểm tra.** Chương trình vét cạn theo định nghĩa [CC]. Chặn trên 6 của $A$ **không thuộc** $A$ — hợp lệ (S3-p50).
- **Biến thể (V2).** Trong $(P(\{a,b,c\}),\subseteq)$: $\{a\}\vee\{b\}=\{a,b\}$, $\{a,b\}\wedge\{b,c\}=\{b\}$ (sup = hợp, inf = giao).
- **Lỗi thường gặp.** Chọn sup trong số các chặn trên **không so sánh được** (12 và 18 đều là chặn trên của $A$ nhưng không nhỏ nhất); cho rằng chặn phải thuộc $A$ — [T-19](#T-19).
- **Liên kết.** [POS-03-E01](#POS-03-E01).

### POS-05-E01 · Sắp xếp topo {#POS-05-E01}
**D1 · V0 · [AI-GENERATED PRACTICE] (thuật toán S3-p54–56) · Lời giải [CC]**

- **Đề.** Công việc $a,b,c,d,e,f$ có quan hệ "phải làm trước" (trội trực tiếp): $a\prec b$, $a\prec c$, $e\prec c$, $b\prec d$, $c\prec d$, $d\prec f$. Tìm một sắp xếp topo.
- **Nhận diện.** [POS-05](#POS-05). **Phương pháp.** [M-21](#M-21).
- **Kiến thức.** [F-POS-03](#F-POS-03): mỗi poset hữu hạn có phần tử tối tiểu; bỏ nó đi vẫn là poset (S3-p54).
- **Lời giải.** Tối tiểu ban đầu: $a$, $e$. Lấy $a$ → còn tối tiểu $b$, $e$. Lấy $e$ → tối tiểu $b$, $c$. Lấy $b$ → $c$. Lấy $c$ → $d$. Lấy $d$ → $f$.
- **Kết luận.** Một sắp xếp topo: $a, e, b, c, d, f$ (không duy nhất; ví dụ $e, a, c, b, d, f$ cũng đúng).
- **Kiểm tra.** Mọi cặp $x\prec y$ (kể cả cặp bắc cầu như $a\prec f$) có $x$ đứng trước $y$ — máy kiểm [CC].
- **Biến thể (V4).** Thêm $f\prec a$: tạo vòng $a\prec b\prec d\prec f\prec a$ ⇒ không còn là thứ tự (vi phạm phản xứng) ⇒ **không** có sắp xếp topo (thuật toán kẹt: không còn phần tử tối tiểu).
- **Lỗi thường gặp.** Lấy phần tử tối đại trước; quên rằng có nhiều đáp án đúng.
- **Liên kết.** [M-21](#M-21).
