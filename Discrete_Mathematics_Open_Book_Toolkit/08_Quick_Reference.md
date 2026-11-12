# Tra cứu nhanh (Quick Reference) {#quickref}

## Mã dạng bài — một dòng

| Mã | Dạng | Mã | Dạng |
|---|---|---|---|
| [LOG-01](#LOG-01) | Mệnh đề? sơ cấp/phức hợp | [CNT-05](#CNT-05) | Hoán vị lặp |
| [LOG-02](#LOG-02) | Bảng chân trị, hằng đúng/sai | [CNT-06](#CNT-06) | Tổ hợp lặp, nghiệm nguyên |
| [LOG-03](#LOG-03) | Tương đương / rút gọn | [REC-01](#REC-01) | Lập hệ thức đệ qui |
| [LOG-04](#LOG-04) | Chứng minh suy luận | [REC-02](#REC-02) | Giải thuần nhất |
| [LOG-05](#LOG-05) | Suy luận sai, phản ví dụ | [REC-03](#REC-03) | Vế phải $\beta^nP_r(n)$ |
| [QNT-01](#QNT-01) | Chân trị $\forall,\exists$ | [REC-04](#REC-04) | Vế phải tổng nhiều dạng |
| [QNT-02](#QNT-02) | Phủ định lượng từ | [REL-01](#REL-01) | Liệt kê, ma trận $M_R$ |
| [SET-01](#SET-01) | Đẳng thức tập hợp | [REL-02](#REL-02) | 4 tính chất quan hệ |
| [SET-02](#SET-02) | $P(X)$, $A\times B$ | [REL-03](#REL-03) | Tương đương, lớp, đồng dư |
| [FUN-01](#FUN-01) | Ảnh, ảnh ngược | [POS-01](#POS-01) | Poset, toàn phần |
| [FUN-02](#FUN-02) | Đơn/toàn/song ánh, $f^{-1}$ | [POS-02](#POS-02) | Thứ tự từ điển |
| [FUN-03](#FUN-03) | $g\circ f$ | [POS-03](#POS-03) | Hasse, tối đại/tối tiểu |
| [IND-01](#IND-01) | Quy nạp | [POS-04](#POS-04) | Chặn, sup, inf |
| [CNT-01](#CNT-01) | Cộng/nhân, lập số | [POS-05](#POS-05) | Sắp xếp topo |
| [CNT-02](#CNT-02) | Chuồng bồ câu | [BOO-01](#BOO-01) | Hàm Bool, dạng chính tắc |
| [CNT-03](#CNT-03) | Bù trừ | [BOO-02](#BOO-02) | Karnaugh ↔ đơn thức |
| [CNT-04](#CNT-04) | $P_n$, $A_n^k$, $C_n^k$ | [BOO-03](#BOO-03) | Đa thức tối tiểu |
| [GRA-01](#GRA-01) | Bậc, bắt tay | [BOO-04](#BOO-04) | Mạch logic |
| [GRA-02](#GRA-02) | Ma trận kề | [GRA-05](#GRA-05) | Euler, Fleury |
| [GRA-03](#GRA-03) | Đẳng cấu | [GRA-06](#GRA-06) | Dijkstra |
| [GRA-04](#GRA-04) | Liên thông, khớp, cầu | [GRA-07](#GRA-07) | Ford–Bellman |


## Công thức trọng yếu

- $p\to q\Leftrightarrow\neg p\vee q\Leftrightarrow\neg q\to\neg p$; $\ \neg(p\to q)\Leftrightarrow p\wedge\neg q$; De Morgan $\neg(p\wedge q)\Leftrightarrow\neg p\vee\neg q$.
- $\overline{\forall x\,p(x)}\Leftrightarrow\exists x\,\overline{p(x)}$; $\ \exists x\forall y\Rightarrow\forall y\exists x$ (không ngược lại).
- $|P(X)|=2^{|X|}$, $|A\times B|=|A||B|$; $|A\cup B|=|A|+|B|-|A\cap B|$; 3 tập: $+$đơn $-$đôi $+$ba.
- $P_n=n!$, $A_n^k=\frac{n!}{(n-k)!}$, $C_n^k=\frac{n!}{k!(n-k)!}$, $K_n^k=C_{n+k-1}^k$, hoán vị lặp $\frac{n!}{n_1!\cdots n_k!}$; Dirichlet $\lceil n/k\rceil$.
- Đệ qui cấp 2: phân biệt $C_1\lambda_1^n+C_2\lambda_2^n$; kép $(C_1+nC_2)\lambda_0^n$; nghiệm riêng $n^m\beta^nQ_r(n)$, $m$ = bội của $\beta$.
- Đồ thị: $\sum\deg=2m$; có hướng $\sum\deg^-=\sum\deg^+=m$; Euler: liên thông + 0 (chu trình) / 2 (đường đi) đỉnh lẻ.
- Karnaugh 4 biến: cột $x\bar y|xy|\bar xy|\bar x\bar y$, hàng $z\bar t|zt|\bar zt|\bar z\bar t$; tế bào $2^{n-k}$ ô ↔ đơn thức $k$ từ đơn.

## Quy trình giải nhanh

1. **Đọc đề → gạch từ khóa** → tra [Mục lục từ khóa](#keyword-index) → mã dạng bài.
2. Mở dạng bài trong [taxonomy](#taxonomy): đọc **Kiểm tra trước**.
3. Mở công thức (F-) và phương pháp (M-) được dẫn.
4. Mở ví dụ cùng mã, đối chiếu biến thể gần nhất với đề.
5. Giải theo các bước của phương pháp, trình bày theo mục "Trình bày".
6. Chạy **kiểm tra** (thế lại, tính $x_2$, đếm bằng cách bù, thử phản ví dụ) và soát [bẫy](#traps).

## Kiểm tra trước khi kết luận

- Logic: đã xét đủ $2^n$ dòng / phản ví dụ đã **thử lại** mọi tiền đề? Lượng từ giữ đúng thứ tự và miền?
- Ánh xạ: đã ghi rõ miền $X$, tập đích $Y$? Nghiệm của $f(x)=y$ thuộc $X$?
- Quy nạp: $N_0$ đúng đề? Bước quy nạp có dùng giả thiết?
- Đếm: thứ tự? lặp? chữ số đầu $\ne0$? ràng buộc "$>$" đổi thành "$\ge$" đúng? kiểm tra bằng cách đếm phần bù?
- Đệ qui: bội của **từng** $\beta$? $C_1,C_2$ tính **sau** khi cộng nghiệm riêng? $x_2$ từ hệ thức = từ công thức?
- Quan hệ: "không" có phản ví dụ cụ thể? tương đương = PX+ĐX+BC; thứ tự = PX+phản xứng+BC.
- Poset: Hasse chỉ có cung trực tiếp? sup/inf có thể không tồn tại?
- Karnaugh: đủ tế bào lớn (quấn biên, 4 góc)? đã so sánh độ đơn giản các phủ?
- Đồ thị: liên thông? trọng số âm (→ Ford–Bellman)? Dijkstra chỉ dừng khi đỉnh đích **được cố định**?

## Lỗi dễ mất điểm nhất

[T-03](#T-03) đảo/phủ định kéo theo · [T-06](#T-06) thứ tự lượng từ · [T-08](#T-08) miền ánh xạ · [T-10](#T-10) chữ số 0 · [T-12](#T-12) tổ hợp lặp · [T-14](#T-14) thứ tự tìm hằng số · [T-15](#T-15) bội của $\beta$ · [T-16](#T-16) chứng minh bằng ví dụ · [T-18](#T-18) tối đại ≠ lớn nhất · [T-20](#T-20) quấn biên Karnaugh · [T-24](#T-24) đẳng cấu · [T-26](#T-26) Dijkstra với trọng số âm.
