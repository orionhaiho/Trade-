# Ví dụ Chương V — Đồ thị {#ex-ch5}

> Hình đồ thị trong slide chỉ có dạng ảnh; toolkit ghi lại **danh sách cạnh** đọc từ ảnh để có thể dựng lại. Bảng Dijkstra/Ford–Bellman được sinh bằng `10_Verification/graph_tables.py` theo đúng quy trình slide và trùng khớp từng ô với bảng của nguồn **[CC]**.

### GRA-01-E01 · Bậc đỉnh: vô hướng có khuyên; có hướng {#GRA-01-E01}
**D1 · V0 · Đề [SV] S5-p20, p21, p24 · Lời giải [SV], [CC]**

- **Đề.** (a) Đồ thị vô hướng cạnh $ab, ac, bc, bd, cd$ và một khuyên tại $b$: tìm bậc, phân loại đồ thị. (b) Đồ thị vô hướng cạnh $ab, ac, bc, be, bf, cf$, đỉnh $d$ cô lập: tìm bậc. (c) Đồ thị có hướng cung $b\to a$, $a\to c$, $c\to b$, $b\to e$, $b\to f$, $c\to f$ và đỉnh $d$: tìm bậc vào, bậc ra.
- **Nhận diện.** "bậc của các đỉnh" → [GRA-01](#GRA-01). **Kiến thức.** [F-GRA-01](#F-GRA-01).
- **Phương pháp.** Đếm cạnh kề từng đỉnh (khuyên +2; có hướng: đếm cung vào/ra); kiểm tra tổng bậc $=2m$.
- **Lời giải.** (a) $\deg a=2$, $\deg b=3+2=5$ (khuyên đếm 2), $\deg c=3$, $\deg d=2$; có khuyên ⇒ **giả đồ thị**. (b) $\deg a=2,\ \deg b=4,\ \deg c=3,\ \deg d=0$ (cô lập), $\deg e=1$ (treo), $\deg f=2$. (c) $a$: $\deg^-=1,\deg^+=1$; $b$: 1, 3; $c$: 1, 2; $d$: 0, 0; $e$: 1, 0; $f$: 2, 0.
- **Kết luận.** Như trên (khớp S5-p20, p24).
- **Kiểm tra.** (a) tổng bậc $12=2\cdot6$ (5 cạnh + 1 khuyên). (b) tổng $12=2\cdot6$; đỉnh bậc lẻ: $c,e$ — 2 đỉnh (chẵn) ✓. (c) $\sum\deg^-=\sum\deg^+=6=m$ ✓.
- **Biến thể (V1).** Ma trận kề của (c): xem [GRA-02-E01](#GRA-02-E01) biến thể.
- **Lỗi thường gặp.** Đếm khuyên là 1 — [T-23](#T-23).
- **Liên kết.** [F-GRA-01](#F-GRA-01).

### GRA-01-E02 · Định lý bắt tay: tồn tại đồ thị? số cạnh? — bẫy {#GRA-01-E02}
**D2 · V4 · [AI-GENERATED PRACTICE] · Lời giải [CC]**

- **Đề.** (a) Có đồ thị nào có 5 đỉnh đều bậc 3? (b) Đơn đồ thị 10 đỉnh, mỗi đỉnh bậc 3 có bao nhiêu cạnh? (c) Có đơn đồ thị 4 đỉnh với bậc $3,3,3,1$ không?
- **Nhận diện.** "có tồn tại", "số cạnh" → [GRA-01](#GRA-01). **Kiến thức.** [F-GRA-01](#F-GRA-01).
- **Phương pháp.** Định lý bắt tay để bác bỏ; với đơn đồ thị $n$ đỉnh thêm điều kiện $\deg v\le n-1$ và lập luận kề.
- **Lời giải.** (a) Tổng bậc $15$ lẻ, mâu thuẫn $2m=\sum\deg$ ⇒ **không**. (b) $2m=30\Rightarrow m=15$. (c) Tổng $10$ chẵn nhưng **vẫn không**: trong đơn đồ thị 4 đỉnh, đỉnh bậc 3 kề cả 3 đỉnh còn lại; có 3 đỉnh như vậy ⇒ đỉnh thứ tư kề cả 3, bậc $\ge3\ne1$.
- **Kết luận.** (a) không; (b) 15; (c) không.
- **Kiểm tra.** Vét cạn mọi đơn đồ thị 4 đỉnh (64 đồ thị): không có dãy bậc $(3,3,3,1)$ [CC].
- **Biến thể (V1).** Dãy $3,3,3,3$: có ($K_4$, 6 cạnh).
- **Lỗi thường gặp.** Coi "tổng bậc chẵn" là điều kiện đủ.
- **Liên kết.** [GRA-01-E01](#GRA-01-E01).

### GRA-02-E01 · Ma trận kề {#GRA-02-E01}
**D1 · V0 · Đề [SV] S5-p27, p28 · Lời giải [SV]**

- **Đề.** Tìm ma trận kề của: (a) đồ thị cạnh $ab, ac, bc, bd, cd$; (b) đa/giả đồ thị cạnh $ab$ (2 cạnh song song), $ac$, $bc$, $be$, $bf$, $cf$, khuyên tại $e$; $d$ cô lập.
- **Nhận diện.** [GRA-02](#GRA-02). **Kiến thức.** [F-GRA-02](#F-GRA-02).
- **Phương pháp.** Cố định thứ tự đỉnh; $a_{ij}$ = số cạnh giữa $i$ và $j$; vô hướng thì điền đối xứng.
- **Lời giải.** (a) Thứ tự $a,b,c,d$: $\begin{pmatrix}0&1&1&0\\1&0&1&1\\1&1&0&1\\0&1&1&0\end{pmatrix}$. (b) Thứ tự $a,\dots,f$: $\begin{pmatrix}0&2&1&0&0&0\\2&0&1&0&1&1\\1&1&0&0&0&1\\0&0&0&0&0&0\\0&1&0&0&2&0\\0&1&1&0&0&0\end{pmatrix}$.
- **Kết luận.** Như trên (khớp S5-p27, p28).
- **Kiểm tra.** Ma trận đối xứng (vô hướng). Với quy ước khuyên = 2: tổng hàng = bậc ($\deg b=5$, $\deg e=3$).
- **Ghi chú nguồn — [CONFLICT] CON-01.** Định nghĩa S5-p26 ("số cạnh từ $i$ đến $j$") cho $a_{ee}=1$, ví dụ S5-p28 ghi 2. Khi làm bài: **ghi rõ quy ước** đang dùng.
- **Biến thể (V2).** Đồ thị có hướng [GRA-01-E01](#GRA-01-E01)(c), thứ tự $a..f$: hàng $a$: $(0,0,1,0,0,0)$; $b$: $(1,0,0,0,1,1)$; $c$: $(0,1,0,0,0,1)$; $d,e,f$: hàng 0 — **không** đối xứng; tổng hàng = bậc ra, tổng cột = bậc vào.
- **Lỗi thường gặp.** Ghi 1 cho cạnh song song; không nêu quy ước khuyên — [T-23](#T-23), [T-30](#T-30).
- **Liên kết.** [F-GRA-02](#F-GRA-02).

### GRA-03-E01 · Đẳng cấu: bác bỏ bằng bất biến, khẳng định bằng song ánh {#GRA-03-E01}
**D2 · V0 · Đề (a) [SV] S5-p32; (b) [AI-GENERATED PRACTICE] · Lời giải [CC]**

- **Đề.** (a) $G_1$: cạnh $ab,bc,cd,de,ea,ce$; $G_2$: cạnh $ab,bc,ac,ae,ad,cd$. Đẳng cấu không? (b) $G_1$ như (a) và $H$: đỉnh $1..5$, cạnh $12,23,34,45,51,24$. Đẳng cấu không?
- **Nhận diện.** [GRA-03](#GRA-03). **Kiến thức.** [F-GRA-03](#F-GRA-03). **Phương pháp.** [M-24](#M-24).
- **Lời giải.** (a) Cùng 5 đỉnh, 6 cạnh; dãy bậc $G_1$: $(3,3,2,2,2)$; $G_2$: $(4,3,2,2,1)$ — $G_2$ có đỉnh bậc 1 ($e$), $G_1$ không ⇒ **không đẳng cấu**.
  (b) Dãy bậc đều $(3,3,2,2,2)$. Ở $G_1$ hai đỉnh bậc 3 là $c,e$ (kề nhau), đỉnh kề chung của chúng là $d$; ở $H$: $2,4$ (kề nhau), kề chung $3$. Ghép $c\mapsto2$, $e\mapsto4$, $d\mapsto3$; $b$ (kề $c$) $\mapsto1$ (kề 2); $a\mapsto5$. Kiểm tra 6 cạnh: $ab\mapsto51$, $bc\mapsto12$, $cd\mapsto23$, $de\mapsto34$, $ea\mapsto45$, $ce\mapsto24$ — đều là cạnh của $H$ ⇒ **đẳng cấu**.
- **Kết luận.** (a) không; (b) có, $f=(a,b,c,d,e)\mapsto(5,1,2,3,4)$.
- **Kiểm tra.** Thuật toán kiểm tra đẳng cấu của `networkx` xác nhận cả hai kết luận [CC].
- **Biến thể (V4).** Cùng dãy bậc **không** đủ: $C_6$ (chu trình 6 đỉnh) và hai tam giác rời nhau đều có 6 đỉnh bậc 2, 6 cạnh nhưng một liên thông, một không ⇒ không đẳng cấu.
- **Lỗi thường gặp.** Kết luận đẳng cấu chỉ vì cùng số đỉnh, cạnh, dãy bậc — [T-24](#T-24).
- **Liên kết.** [M-24](#M-24).

### GRA-04-E01 · Đường đi đơn/sơ cấp, chu trình sơ cấp, đỉnh khớp, cầu {#GRA-04-E01}
**D1 · V0 · Đề [SV] S5-p42 (+ đỉnh khớp, cầu theo định nghĩa S5-p38) · Lời giải [SV]+[CC]**

- **Đề.** Đồ thị: $e_1=ab$, $e_2=bc$, $e_3=cd$, $e_4=db$, $e_5=bf$, $e_6=be$, $e_7=fe$, $e_8=eg$. (a) $(a,e_1,b,e_2,c,e_3,d,e_4,b)$ là đường đi gì, độ dài? (b) Liệt kê các chu trình sơ cấp. (c) Tìm đỉnh khớp và cầu.
- **Nhận diện.** [GRA-04](#GRA-04). **Kiến thức.** Định nghĩa S5-p38–41.
- **Phương pháp.** Áp định nghĩa; với khớp/cầu: xóa thử đỉnh/cạnh rồi kiểm tra liên thông.
- **Lời giải.** (a) Đường đi từ $a$ tới $b$ độ dài 4; không lặp cạnh ⇒ **đơn**; lặp đỉnh $b$ ⇒ **không sơ cấp**. Viết gọn $(a,b,c,d,b)$ (đơn đồ thị). (b) $(b,c,d,b)$, $(b,f,e,b)$. (c) Xóa $b$: $a$ tách ra ⇒ $b$ là đỉnh khớp; xóa $e$: $g$ tách ra ⇒ $e$ là đỉnh khớp. Cầu: $e_1=ab$, $e_8=eg$.
- **Kết luận.** (a) đơn, không sơ cấp, độ dài 4; (b) 2 chu trình sơ cấp; (c) đỉnh khớp $b,e$; cầu $ab, eg$.
- **Kiểm tra.** `networkx`: articulation points $\{b,e\}$, bridges $\{ab, eg\}$ [CC].
- **Biến thể (V1).** Cạnh $bc$ có phải cầu? Không — nằm trên chu trình $(b,c,d,b)$ (cạnh là cầu ⇔ không thuộc chu trình nào **[INFERRED]**).
- **Lỗi thường gặp.** Nhầm "đơn" (không lặp **cạnh**) với "sơ cấp" (không lặp **đỉnh**).
- **Liên kết.** [GRA-05](#GRA-05) (Fleury dùng khái niệm cầu).

### GRA-05-E01 · Chu trình Euler bằng Fleury {#GRA-05-E01}
**D2 · V0 · Đề [SV] S5-p51 · Lời giải [SV], [CC]**

- **Đề.** Đồ thị cạnh $ab, bc, cd, ag, bh, bg, hg, gf, fe, cf, ce, df$. Tìm chu trình Euler.
- **Nhận diện.** [GRA-05](#GRA-05). **Kiến thức.** [F-GRA-04](#F-GRA-04). **Phương pháp.** [M-25](#M-25).
- **Lời giải.** Liên thông. Bậc: $a2, b4, c4, d2, e2, f4, g4, h2$ — **tất cả chẵn** ⇒ có chu trình Euler. Fleury từ $a$: $a\to b\to c\to f\to d\to c\to e\to f\to g\to h\to b\to g\to a$ (mỗi bước tránh cầu của đồ thị còn lại; ví dụ khi tới $f$ lần đầu, cạnh $fd$ chưa là cầu vì $d$ còn nối với $c$).
- **Kết luận.** Chu trình Euler: $abcfdcefghbga$ (12 cạnh).
- **Kiểm tra.** Dãy dùng đúng 12 cạnh, mỗi cạnh một lần, về lại $a$ [CC].
- **Biến thể (V2).** Xóa cạnh $ab$: $a$ và $b$ thành bậc lẻ ⇒ không còn chu trình Euler nhưng có **đường đi** Euler từ $a$ tới $b$, ví dụ $a\,g\,b\,c\,d\,f\,c\,e\,f\,g\,h\,b$ (11 cạnh) [CC].
- **Lỗi thường gặp.** Không kiểm tra liên thông; đi qua cầu sớm làm kẹt — [T-25](#T-25).
- **Liên kết.** [GRA-05-E02](#GRA-05-E02).

### GRA-05-E02 · Bài toán 7 cây cầu Königsberg {#GRA-05-E02}
**D1 · V2 · Đề [SV] S5-p44–47 · Lời giải [INFERRED] (bậc đọc từ hình), [CC]**

- **Đề.** 4 vùng đất nối bởi 7 cây cầu. Có thể đi qua mỗi cầu đúng một lần không?
- **Nhận diện.** "đi qua … đúng một lần" → Euler → [GRA-05](#GRA-05).
- **Kiến thức.** [F-GRA-04](#F-GRA-04).
- **Phương pháp.** [M-25](#M-25): mô hình đa đồ thị, đếm đỉnh bậc lẻ.
- **Lời giải.** Mô hình đa đồ thị: đỉnh = vùng đất, cạnh = cầu. Bậc: đảo giữa 5, ba vùng còn lại đều 3 ⇒ **4 đỉnh bậc lẻ** ⇒ không có đường đi Euler (cần 0 hoặc 2 đỉnh lẻ).
- **Kết luận.** Không thể. Cần ít nhất $k=2$ nét để vẽ đồ thị.
- **Kiểm tra.** Tổng bậc $5+3+3+3=14=2\cdot7$ ✓.
- **Biến thể (V3).** Xây thêm một cầu nối hai vùng bậc 3 ⇒ còn 2 đỉnh lẻ ⇒ có đường đi Euler (không có chu trình).
- **Lỗi thường gặp.** Dùng đơn đồ thị (gộp các cầu song song) làm sai bậc.
- **Liên kết.** [GRA-05-E01](#GRA-05-E01).

### GRA-06-E01 · Dijkstra trên đồ thị vô hướng {#GRA-06-E01}
**D2 · V0 · Đề [SV] S5-p60 · Lời giải [SV] S5-p61–65, [CC]**

- **Đề.** Tìm đường đi ngắn nhất từ $u$ đến các đỉnh còn lại. Cạnh (trọng số): ur 4, uy 1, rs 7, rt 3, ry 2, st 3, sx 1, tx 1, tz 4, xw 3, yz 3, zw 5.
- **Nhận diện.** Trọng số dương → [GRA-06](#GRA-06). **Kiến thức.** [F-GRA-05](#F-GRA-05). **Phương pháp.** [M-26](#M-26).
- **Lời giải.**

| Bước | u | r | s | t | x | y | z | w |
|---|---|---|---|---|---|---|---|---|
| 0 | 0* | (∞,-) | (∞,-) | (∞,-) | (∞,-) | (∞,-) | (∞,-) | (∞,-) |
| 1 | – | (4,u) | (∞,-) | (∞,-) | (∞,-) | (1,u)* | (∞,-) | (∞,-) |
| 2 | – | (3,y)* | (∞,-) | (∞,-) | (∞,-) | – | (4,y) | (∞,-) |
| 3 | – | – | (10,r) | (6,r) | (∞,-) | – | (4,y)* | (∞,-) |
| 4 | – | – | (10,r) | (6,r)* | (∞,-) | – | – | (9,z) |
| 5 | – | – | (9,t) | – | (7,t)* | – | – | (9,z) |
| 6 | – | – | (8,x)* | – | – | – | – | (9,z) |
| 7 | – | – | – | – | – | – | – | (9,z)* |


- **Kết luận.** $d(u,\cdot)$: $y=1$ ($u y$); $r=3$ ($u y r$); $z=4$ ($u y z$); $t=6$ ($u y r t$); $x=7$ ($u y r t x$); $s=8$ ($u y r t x s$); $w=9$ ($u y z w$).
- **Kiểm tra.** Trùng bảng S5-p64 và cây đường đi S5-p65; `networkx` cho cùng khoảng cách [CC]. Bước 3: $r$ (3) và $z$ (4) — chọn $r$ trước vì nhỏ hơn.
- **Biến thể (V4).** Dijkstra **sai** khi có trọng số âm: đồ thị có hướng $a\to b$ (2), $a\to c$ (3), $c\to b$ (−2): Dijkstra cố định $b=2$ ở bước 1, nhưng thực tế $d(a,b)=1$ (qua $c$) ⇒ phải dùng Ford–Bellman.
- **Lỗi thường gặp.** Cập nhật cả đỉnh đã cố định; chọn đỉnh nhỏ nhất chỉ trong số đỉnh vừa cập nhật — [T-26](#T-26), [T-27](#T-27).
- **Liên kết.** [GRA-07](#GRA-07).

### GRA-06-E02 · Dijkstra trên đồ thị có hướng cho bằng ma trận trọng số {#GRA-06-E02}
**D2 · V2 · Đề [SV] S5-p66–68 · Lời giải [SV] S5-p69, [CC]**

- **Đề.** $V=\{v_1,\dots,v_7\}$, ma trận trọng số (hàng = đỉnh đầu):
\[
D=\begin{pmatrix}0&5&31&40&\infty&\infty&\infty\\ \infty&0&27&\infty&73&\infty&\infty\\ \infty&26&0&8&49&25&38\\ \infty&\infty&\infty&0&\infty&16&\infty\\ \infty&70&\infty&\infty&0&\infty&9\\ \infty&\infty&\infty&\infty&23&0&12\\ \infty&\infty&\infty&\infty&10&\infty&0\end{pmatrix}
\]

Tìm đường đi ngắn nhất từ $v_1$ đến các đỉnh khác.

- **Nhận diện.** Ma trận không đối xứng ⇒ **có hướng**; trọng số dương → [GRA-06](#GRA-06).
- **Kiến thức.** [F-GRA-05](#F-GRA-05); ma trận trọng số ([F-GRA-02](#F-GRA-02)).
- **Phương pháp.** [M-26](#M-26): đỉnh kề của $u_i$ = các cột $j$ có $d_{ij}<\infty$ ở hàng $u_i$.
- **Lời giải.**

| Bước | v1 | v2 | v3 | v4 | v5 | v6 | v7 |
|---|---|---|---|---|---|---|---|
| 0 | 0* | (∞,-) | (∞,-) | (∞,-) | (∞,-) | (∞,-) | (∞,-) |
| 1 | – | (5,v1)* | (31,v1) | (40,v1) | (∞,-) | (∞,-) | (∞,-) |
| 2 | – | – | (31,v1)* | (40,v1) | (78,v2) | (∞,-) | (∞,-) |
| 3 | – | – | – | (39,v3)* | (78,v2) | (56,v3) | (69,v3) |
| 4 | – | – | – | – | (78,v2) | (55,v4)* | (69,v3) |
| 5 | – | – | – | – | (78,v2) | – | (67,v6)* |
| 6 | – | – | – | – | (77,v7)* | – | – |


- **Kết luận.** $v_2$: 5; $v_3$: 31; $v_4$: 39 ($v_1v_3v_4$); $v_6$: 55 ($v_1v_3v_4v_6$); $v_7$: 67 ($\dots v_6v_7$); $v_5$: 77 ($v_1v_3v_4v_6v_7v_5$).
- **Kiểm tra.** $31+8+16+12+10=77$; trùng bảng S5-p69 [CC]. Ở bước 2, $v_3$ qua $v_2$ là $5+27=32>31$ nên giữ $(31,v_1)$.
- **Biến thể (V1).** Bỏ cung $v_7\to v_5$: $d(v_1,v_5)=78$ (qua $v_2$ hoặc qua $v_6$: $55+23$) [CC].
- **Lỗi thường gặp.** Đọc ma trận theo cột (đảo hướng cung) — [T-30](#T-30).
- **Liên kết.** [GRA-06-E01](#GRA-06-E01).

### GRA-06-E03 · Dijkstra: đường đi ngắn nhất từ $a$ đến $z$ {#GRA-06-E03}
**D2 · V1 · Đề [SV] S5-p71 · Lời giải [SV] S5-p72, [CC]**

- **Đề.** Đồ thị vô hướng, cạnh (trọng số): ab 4, ac 3, bc 2, bd 5, cd 3, ce 6, de 1, df 5, eg 5, fg 2, fz 7, gz 4. Tìm đường đi ngắn nhất $a\to z$ và độ dài.
- **Nhận diện.** Vô hướng, trọng số dương, hỏi đường đi $a\to z$ → [GRA-06](#GRA-06).
- **Kiến thức.** [F-GRA-05](#F-GRA-05).
- **Phương pháp.** [M-26](#M-26).
- **Lời giải.**

| Bước | a | b | c | d | e | f | g | z |
|---|---|---|---|---|---|---|---|---|
| 0 | 0* | (∞,-) | (∞,-) | (∞,-) | (∞,-) | (∞,-) | (∞,-) | (∞,-) |
| 1 | – | (4,a) | (3,a)* | (∞,-) | (∞,-) | (∞,-) | (∞,-) | (∞,-) |
| 2 | – | (4,a)* | – | (6,c) | (9,c) | (∞,-) | (∞,-) | (∞,-) |
| 3 | – | – | – | (6,c)* | (9,c) | (∞,-) | (∞,-) | (∞,-) |
| 4 | – | – | – | – | (7,d)* | (11,d) | (∞,-) | (∞,-) |
| 5 | – | – | – | – | – | (11,d)* | (12,e) | (∞,-) |
| 6 | – | – | – | – | – | – | (12,e)* | (18,f) |
| 7 | – | – | – | – | – | – | – | (16,g)* |


- **Kết luận.** Đường đi $a\to c\to d\to e\to g\to z$, độ dài $3+3+1+5+4=16$.
- **Kiểm tra.** Truy vết: $z\leftarrow g\leftarrow e\leftarrow d\leftarrow c\leftarrow a$; trùng S5-p72 [CC].
- **Biến thể (V1).** Đường đi ngắn nhất $a\to f$: $a\,c\,d\,f$, độ dài 11.
- **Lỗi thường gặp.** Dừng khi lần đầu thấy nhãn của $z$ (18) — chỉ dừng khi $z$ được **cố định** (*).
- **Liên kết.** [M-26](#M-26).

### GRA-07-E01 · Ford–Bellman phát hiện mạch âm {#GRA-07-E01}
**D3 · V4 · Đề [SV] S5-p75 · Lời giải [SV] S5-p76–83, [CC]**

- **Đề.** Đồ thị có hướng 6 đỉnh, cung: $1\to2$ (7), $1\to4$ (8), $2\to3$ (4), $2\to5$ (2), $2\to6$ (1), $4\to2$ (2), $4\to5$ (2), $5\to6$ (3), $6\to3$ (2), $6\to4$ (−6). Tìm đường đi ngắn nhất từ 1 hoặc chỉ ra mạch âm.
- **Nhận diện.** Có trọng số âm → [GRA-07](#GRA-07). **Kiến thức.** [F-GRA-06](#F-GRA-06). **Phương pháp.** [M-27](#M-27).
- **Lời giải.**

| k | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| 0 | 0 | (∞,-) | (∞,-) | (∞,-) | (∞,-) | (∞,-) |
| 1 | 0 | (7,1) | (∞,-) | (8,1) | (∞,-) | (∞,-) |
| 2 | 0 | (7,1) | (11,2) | (8,1) | (9,2) | (8,2) |
| 3 | 0 | (7,1) | (10,6) | (2,6) | (9,2) | (8,2) |
| 4 | 0 | (4,4) | (10,6) | (2,6) | (4,4) | (8,2) |
| 5 | 0 | (4,4) | (8,2) | (2,6) | (4,4) | (5,2) |
| 6 | 0 | (4,4) | (7,6) | (−1,6) | (4,4) | (5,2) |


- **Kết luận.** $k=n=6$ mà $L_6\ne L_5$ ⇒ **có mạch âm**, ví dụ $4\to2\to6\to4$ có độ dài $2+1-6=-3$.
- **Kiểm tra.** Trùng S5-p76–83; `networkx` xác nhận có chu trình âm [CC].
- **Biến thể (V4).** Đổi $w(6\to4)=-3$: mạch $4\to2\to6\to4$ có độ dài $0$ (không âm) ⇒ ổn định tại $k=5$ với $L=(0,7,10,5,7,8)$ [CC].
- **Lỗi thường gặp.** Dùng giá trị **cùng dòng** vừa cập nhật thay cho dòng $k-1$ (kết quả trung gian khác bảng) — [T-28](#T-28).
- **Liên kết.** [GRA-07-E02](#GRA-07-E02).

### GRA-07-E02 · Ford–Bellman hội tụ {#GRA-07-E02}
**D2 · V0 · Đề [SV] S5-p84 · Lời giải [SV] S5-p85–86, [CC]**

- **Đề.** Như [GRA-07-E01](#GRA-07-E01) nhưng $w(6\to4)=-2$.
- **Phương pháp.** [M-27](#M-27).
- **Nhận diện.** Có cung trọng số âm → [GRA-07](#GRA-07).
- **Kiến thức.** [F-GRA-06](#F-GRA-06).
- **Lời giải.**

| k | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| 0 | 0 | (∞,-) | (∞,-) | (∞,-) | (∞,-) | (∞,-) |
| 1 | 0 | (7,1) | (∞,-) | (8,1) | (∞,-) | (∞,-) |
| 2 | 0 | (7,1) | (11,2) | (8,1) | (9,2) | (8,2) |
| 3 | 0 | (7,1) | (10,6) | (6,6) | (9,2) | (8,2) |
| 4 | 0 | (7,1) | (10,6) | (6,6) | (8,4) | (8,2) |
| 5 | 0 | (7,1) | (10,6) | (6,6) | (8,4) | (8,2) |


- **Kết luận.** Ổn định tại $k=5$. $d(1,2)=7$ ($1\,2$); $d(1,6)=8$ ($1\,2\,6$); $d(1,3)=10$ ($1\,2\,6\,3$); $d(1,4)=6$ ($1\,2\,6\,4$); $d(1,5)=8$ ($1\,2\,6\,4\,5$). Cây đường đi như S5-p86.
- **Kiểm tra.** Mạch $4\to2\to6\to4$ dài $+1>0$; `networkx` Bellman–Ford cho cùng khoảng cách [CC].
- **Biến thể (V2).** Hỏi riêng $d(1,5)$: không dừng ở $(9,2)$ của $k=2$ — giá trị cuối là 8.
- **Lỗi thường gặp.** Dừng ở $k$ đầu tiên một cột không đổi (phải là **cả dòng** không đổi).
- **Liên kết.** [F-GRA-06](#F-GRA-06).
