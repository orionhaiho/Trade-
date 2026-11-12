# Ví dụ Chương IV — Hàm Bool, Karnaugh, mạch logic {#ex-ch4}

> Bản đồ Karnaugh dùng **đúng khung của nguồn** ([F-BOO-03](#F-BOO-03)): cột $x\bar y\,|\,xy\,|\,\bar xy\,|\,\bar x\bar y$; hàng $z\bar t\,|\,zt\,|\,\bar zt\,|\,\bar z\bar t$ (3 biến: hàng $z\,|\,\bar z$). Ô có 1 là ô thuộc $\mathrm{kar}(f)$. Mọi kết quả tối tiểu đã được kiểm tra bằng vét cạn `10_Verification/boolmin.py` **[CC]**.

### BOO-01-E01 · Hàm bỏ phiếu đa số: bảng chân trị → dạng nối rời chính tắc → tối tiểu {#BOO-01-E01}
**D1 · V0 · Đề [SV] S4-p12–13 · Lời giải [CC]**

- **Đề.** Quyết định $f$ thông qua (=1) khi đa số trong 3 phiếu $x,y,z$ tán thành (=1). Lập bảng chân trị, viết dạng nối rời chính tắc và công thức đa thức tối tiểu.
- **Nhận diện.** Mô tả lời → hàm Bool → [BOO-01](#BOO-01), [BOO-03](#BOO-03).
- **Kiến thức.** [F-BOO-02](#F-BOO-02), [F-BOO-03](#F-BOO-03). **Phương pháp.** [M-23](#M-23), [M-22](#M-22).
- **Lời giải.** $f=1$ khi có ít nhất 2 số 1: hàng $011,101,110,111$ (các hàng khác $f=0$; khớp bảng S4-p13).
  Dạng nối rời chính tắc: $f=\bar xyz\vee x\bar yz\vee xy\bar z\vee xyz$.
  Karnaugh: hàng $z$: $x\bar y$=1, $xy$=1, $\bar xy$=1, $\bar x\bar y$=0; hàng $\bar z$: 0, 1, 0, 0. Tế bào lớn: $xz$ (ô $x\bar yz$, $xyz$), $yz$ ($xyz$, $\bar xyz$), $xy$ ($xyz$, $xy\bar z$) — cả ba bắt buộc.
- **Kết luận.** $f=xy\vee yz\vee xz$.
- **Kiểm tra.** So bảng chân trị của $xy\vee yz\vee xz$ với "tổng $\ge2$" trên 8 hàng [CC].
- **Biến thể (V1).** "Thông qua khi **cả 3** tán thành": $f=xyz$; "khi có ít nhất 1": $f=x\vee y\vee z$.
- **Lỗi thường gặp.** Viết từ tối tiểu cho hàng $f=0$.
- **Liên kết.** [BOO-04](#BOO-04).

### BOO-01-E02 · Dạng nối rời chính tắc từ công thức {#BOO-01-E02}
**D1 · V1 · [AI-GENERATED PRACTICE] · Lời giải [CC]**

- **Đề.** Viết dạng nối rời chính tắc của $f(x,y,z)=x\vee\bar yz$ và của $\bar f$.
- **Nhận diện.** [BOO-01](#BOO-01). **Kiến thức.** [F-BOO-02](#F-BOO-02).
- **Phương pháp.** Bổ sung biến thiếu: $x=x(y\vee\bar y)(z\vee\bar z)$; hoặc đọc hàng $f=1$.
- **Lời giải.** $f=1$ khi $x=1$ (4 hàng $100,101,110,111$) hoặc $(x,y,z)=(0,0,1)$. ⇒ $f=x\bar y\bar z\vee x\bar yz\vee xy\bar z\vee xyz\vee\bar x\bar yz$. Các hàng còn lại $000,010,011$ ⇒ $\bar f=\bar x\bar y\bar z\vee\bar xy\bar z\vee\bar xyz$ $\big(=\bar x(y\vee\bar z)\big)$.
- **Kết luận.** $f$ có 5 từ tối tiểu; $\bar f$ có 3; tổng $5+3=2^3$.
- **Kiểm tra.** $\bar f=\overline{x\vee\bar yz}=\bar x\wedge(y\vee\bar z)$ (De Morgan) — khớp [CC].
- **Biến thể (V2).** Số hàm Bool 3 biến: $2^{2^3}=256$.
- **Lỗi thường gặp.** Bỏ sót từ tối tiểu khi bổ sung biến.
- **Liên kết.** [F-BOO-02](#F-BOO-02).

### BOO-02-E01 · Tế bào ↔ đơn thức {#BOO-02-E01}
**D1 · V0 · Đề [SV] S4-p28–32, p34–37 · Lời giải [SV]**

- **Đề.** (a) Vẽ kar của các đơn thức $x\bar yz\bar t$, $\bar yz\bar t$, $\bar y\bar t$, $\bar t$ (4 biến). (b) Tế bào gồm 4 ô: hàng $z\bar t$ và hàng $\bar z\bar t$, cột $xy$ và $\bar xy$ là kar của đơn thức nào?
- **Nhận diện.** [BOO-02](#BOO-02). **Kiến thức.** [F-BOO-03](#F-BOO-03), [F-BOO-04](#F-BOO-04).
- **Phương pháp.** Vẽ: $\mathrm{kar}$ của tích = giao các dải của từng từ đơn. Đọc: chiếu tế bào lên hai cạnh.
- **Lời giải.** (a) $x\bar yz\bar t$: 1 ô (hàng $z\bar t$, cột $x\bar y$). $\bar yz\bar t$: 2 ô (hàng $z\bar t$, cột $x\bar y$ và $\bar x\bar y$ — kề nhau qua biên). $\bar y\bar t$: 4 ô ở **4 góc**. $\bar t$: 8 ô (hàng $z\bar t$ và $\bar z\bar t$).
  (b) Chiếu lên cạnh trên: cột $xy,\bar xy$ nằm trọn trong $y$ (không trọn trong $x$ hay $\bar x$); chiếu lên cạnh phải: hàng $z\bar t,\bar z\bar t$ nằm trọn trong $\bar t$ ⇒ đơn thức $y\bar t$.
- **Kết luận.** Số ô $=2^{4-k}$ với $k$ = số từ đơn: 1, 2, 4, 8; (b) $y\bar t$ (khớp S4-p32).
- **Kiểm tra.** $\mathrm{kar}(\bar y\bar t)=\mathrm{kar}(\bar y)\cap\mathrm{kar}(\bar t)$ (định lý S4-p26) = 2 cột biên ∩ 2 hàng biên = 4 góc ✓.
- **Biến thể (V1).** S4-p37: 2 ô hàng $\bar zt$, cột $xy,\bar xy$ ⇒ $y\bar zt$.
- **Lỗi thường gặp.** Không coi cột đầu–cuối (hay 4 góc) là kề nhau — [T-20](#T-20).
- **Liên kết.** [BOO-03](#BOO-03).

### BOO-03-E01 · Karnaugh: một phủ tối tiểu duy nhất {#BOO-03-E01}
**D2 · V0 · Đề [SV] S4-p41 · Lời giải [SV] S4-p42–52 (ảnh), [CC]**

- **Đề.** Tìm tất cả công thức đa thức tối tiểu của $f(x,y,z,t)=xyzt\vee x\bar y\vee x\bar z\vee yz\vee xy\bar z\vee xy\bar t$.
- **Nhận diện.** "tìm tất cả công thức đa thức tối tiểu" → [BOO-03](#BOO-03).
- **Kiến thức.** [F-BOO-04](#F-BOO-04). **Phương pháp.** [M-22](#M-22).
- **Lời giải.** B1 — kar(f) (10 ô):

| | $x\bar y$ | $xy$ | $\bar xy$ | $\bar x\bar y$ |
|---|:-:|:-:|:-:|:-:|
| $z\bar t$ | 1 | 1 | 1 | 0 |
| $zt$ | 1 | 1 | 1 | 0 |
| $\bar zt$ | 1 | 1 | 0 | 0 |
| $\bar z\bar t$ | 1 | 1 | 0 | 0 |


  B2 — tế bào lớn: $x$ (2 cột đầu, 8 ô), $yz$ (cột $xy,\bar xy$ × hàng $z\bar t,zt$). B3 — bắt buộc: ô $x\bar y\bar z\bar t$ chỉ thuộc $x$; ô $\bar xyz\bar t$ chỉ thuộc $yz$ ⇒ chọn cả hai. B4 — đã phủ hết 10 ô ⇒ phủ tối tiểu duy nhất.

- **Kết luận.** $f=x\vee yz$ (duy nhất).
- **Kiểm tra.** Vét cạn: tế bào lớn $\{x, yz\}$, phủ tối tiểu duy nhất [CC]. Đại số: $x\bar y\vee x\bar z\vee xy\bar t\vee xyzt\vee xy\bar z=x$ (mọi ô có $x=1$ đều được phủ), cộng $yz$.
- **Ghi chú nguồn.** Dấu bù trong biểu thức đọc từ ảnh slide; bản đồ Bước 1 của slide (10 ô) xác nhận $\mathrm{kar}(f)$ như trên.
- **Biến thể (V1).** Bỏ hạng tử $yz$: $f'=x$ (tế bào lớn duy nhất là 8 ô cột $x$).
- **Lỗi thường gặp.** Dừng ở các tế bào 4 ô (ví dụ $x\bar y$, $xy$) mà không gộp thành 8 ô $x$ — [T-21](#T-21).
- **Liên kết.** [BOO-03-E02](#BOO-03-E02).

### BOO-03-E02 · Karnaugh: hai công thức tối tiểu {#BOO-03-E02}
**D3 · V0 · Đề [SV] S4-p53 · Lời giải [SV] S4-p53–61 (ảnh), [CC]**

- **Đề.** Tìm các công thức đa thức tối tiểu của $f=\bar yzt\vee\bar y\bar z\bar t\vee y\bar z\bar t\vee xyzt\vee\bar xz\bar t$.
- **Nhận diện.** [BOO-03](#BOO-03). **Phương pháp.** [M-22](#M-22).
- **Kiến thức.** [F-BOO-03](#F-BOO-03), [F-BOO-04](#F-BOO-04).
- **Lời giải.** B1 — kar(f), đánh số ô như slide:

| | $x\bar y$ | $xy$ | $\bar xy$ | $\bar x\bar y$ |
|---|:-:|:-:|:-:|:-:|
| $z\bar t$ | | | ① | ② |
| $zt$ | ③ | ④ | | ⑤ |
| $\bar zt$ | | | | |
| $\bar z\bar t$ | ⑥ | ⑦ | ⑧ | ⑨ |


  B2 — tế bào lớn: $\bar z\bar t$ {⑥⑦⑧⑨}, $\bar x\bar t$ {①②⑧⑨} (hàng $z\bar t$ và $\bar z\bar t$ kề nhau qua biên), $xzt$ {③④}, $\bar yzt$ {③⑤} (cột đầu–cuối kề nhau), $\bar x\bar yz$ {②⑤}.
  B3 — bắt buộc: ô ⑥ chỉ thuộc $\bar z\bar t$; ô ① chỉ thuộc $\bar x\bar t$; ô ④ chỉ thuộc $xzt$. Ba tế bào này phủ ①②③④⑥⑦⑧⑨, còn ô ⑤.
  B4 — ô ⑤ thuộc 2 tế bào lớn $\bar x\bar yz$ và $\bar yzt$ ⇒ 2 phủ, mỗi phủ 4 đơn thức, số từ đơn bằng nhau (2+2+3+3).

- **Kết luận.** Hai công thức tối tiểu: $f=\bar z\bar t\vee\bar x\bar t\vee xzt\vee\bar x\bar yz$ và $f=\bar z\bar t\vee\bar x\bar t\vee xzt\vee\bar yzt$.
- **Kiểm tra.** Vét cạn liệt kê đúng 5 tế bào lớn, 3 bắt buộc, 2 phủ tối tiểu [CC].
- **Biến thể (V2).** Thêm ô $\bar x\bar y\bar zt$ vào kar(f): cột $\bar x\bar y$ đủ 4 ô nên $\bar x\bar y$ thành tế bào lớn **bắt buộc** (chứa ô mới) và phủ luôn ô ⑤ ⇒ công thức tối tiểu duy nhất $\bar z\bar t\vee\bar x\bar t\vee xzt\vee\bar x\bar y$ **[CC]**.
- **Lỗi thường gặp.** Bỏ sót tế bào quấn biên $\bar yzt$ hoặc $\bar x\bar t$ — [T-20](#T-20).
- **Liên kết.** [BOO-03-E03](#BOO-03-E03).

### BOO-03-E03 · Karnaugh: hai phủ nhưng chỉ một tối tiểu — bẫy {#BOO-03-E03}
**D3 · V4 · Đề [SV] S4-p62 · Lời giải [SV] S4-p63–65, [CC]**

- **Đề.** Xác định các công thức đa thức tối tiểu của $f=xz(\bar y\vee\bar t)\vee\bar x\bar z\bar t\vee z(yt\vee\bar x\bar y)$.
- **Nhận diện.** [BOO-03](#BOO-03). **Phương pháp.** [M-22](#M-22) (chú ý Bước 5).
- **Kiến thức.** [F-BOO-04](#F-BOO-04) — định nghĩa "đơn giản hơn", "tối tiểu".
- **Lời giải.** Khai triển: $xz\bar y\vee xz\bar t\vee\bar x\bar z\bar t\vee yzt\vee\bar x\bar yz$. Kar(f):

| | $x\bar y$ | $xy$ | $\bar xy$ | $\bar x\bar y$ |
|---|:-:|:-:|:-:|:-:|
| $z\bar t$ | 1 | 1 | 0 | 1 |
| $zt$ | 1 | 1 | 1 | 1 |
| $\bar zt$ | 0 | 0 | 0 | 0 |
| $\bar z\bar t$ | 0 | 0 | 1 | 1 |


  Tế bào lớn: $xz$, $\bar yz$, $zt$, $\bar x\bar z\bar t$, $\bar x\bar y\bar t$. Bắt buộc: $xz$ (ô $xyz\bar t$), $zt$ (ô $\bar xyzt$), $\bar x\bar z\bar t$ (ô $\bar xy\bar z\bar t$). Còn ô (hàng 1, cột 4) $=\bar x\bar yz\bar t$: thuộc $\bar yz$ hoặc $\bar x\bar y\bar t$ ⇒ 2 phủ:
  $F_1=xz\vee zt\vee\bar x\bar z\bar t\vee\bar x\bar y\bar t$, $\ F_2=xz\vee zt\vee\bar x\bar z\bar t\vee\bar yz$.
  Bước 5: $F_2$ thực sự đơn giản hơn $F_1$ ($\bar yz$ có 2 từ đơn $<3$) ⇒ loại $F_1$.

- **Kết luận.** Công thức tối tiểu duy nhất: $f=xz\vee zt\vee\bar x\bar z\bar t\vee\bar yz$.
- **Kiểm tra.** Vét cạn: $F_1,F_2$ đều biểu diễn $f$, chỉ $F_2$ tối tiểu [CC].
- **Biến thể (V3).** Bỏ ô $\bar x\bar yz\bar t$ khỏi kar(f) thì chỉ còn 3 tế bào bắt buộc và $f=xz\vee zt\vee\bar x\bar z\bar t$.
- **Lỗi thường gặp.** Liệt kê cả hai phủ là "tối tiểu" mà không so sánh độ đơn giản — [T-21](#T-21).
- **Liên kết.** [F-BOO-04](#F-BOO-04).

### BOO-03-E04 · Karnaugh 3 biến {#BOO-03-E04}
**D1 · V1 · [AI-GENERATED PRACTICE] · Lời giải [CC]**

- **Đề.** $f(x,y,z)=1$ đúng tại các bộ $xyz\in\{001,010,011,101,111\}$. Tìm công thức đa thức tối tiểu.
- **Nhận diện.** Cho tập bộ giá trị làm $f=1$, hỏi công thức tối tiểu → [BOO-03](#BOO-03).
- **Kiến thức.** [F-BOO-03](#F-BOO-03) (bản đồ 3 biến), [F-BOO-04](#F-BOO-04).
- **Phương pháp.** [M-22](#M-22).
- **Lời giải.** Kar(f):

| | $x\bar y$ | $xy$ | $\bar xy$ | $\bar x\bar y$ |
|---|:-:|:-:|:-:|:-:|
| $z$ | 1 | 1 | 1 | 1 |
| $\bar z$ | 0 | 0 | 1 | 0 |


  Tế bào lớn: $z$ (cả hàng $z$, 4 ô), $\bar xy$ (cột $\bar xy$, 2 ô). Cả hai bắt buộc (ô $x\bar yz$ chỉ thuộc $z$; ô $\bar xy\bar z$ chỉ thuộc $\bar xy$).

- **Kết luận.** $f=z\vee\bar xy$.
- **Kiểm tra.** $z\vee\bar xy$ bằng 1 đúng tại 5 bộ đã cho [CC].
- **Biến thể (V2).** $\bar f$ (3 ô $000,100,110$): $\bar f=x\bar z\vee\bar y\bar z$.
- **Lỗi thường gặp.** Gom $\bar xy\bar z$ với $\bar x\bar yz$ (không kề nhau — khác 2 biến).
- **Liên kết.** [M-22](#M-22).

### BOO-03-E05 · Karnaugh 4 biến có tế bào bốn góc và hai lựa chọn {#BOO-03-E05}
**D2 · V3 · [AI-GENERATED PRACTICE] · Lời giải [CC]**

- **Đề.** $f(x,y,z,t)=1$ tại $xyzt\in\{0000,0010,1000,1010,0101,1101,0111,1111,0001\}$. Tìm các công thức đa thức tối tiểu.
- **Nhận diện.** Như trên, 4 biến → [BOO-03](#BOO-03).
- **Kiến thức.** [F-BOO-03](#F-BOO-03), [F-BOO-04](#F-BOO-04).
- **Phương pháp.** [M-22](#M-22).
- **Lời giải.** Kar(f):

| | $x\bar y$ | $xy$ | $\bar xy$ | $\bar x\bar y$ |
|---|:-:|:-:|:-:|:-:|
| $z\bar t$ | 1 | 0 | 0 | 1 |
| $zt$ | 0 | 1 | 1 | 0 |
| $\bar zt$ | 0 | 1 | 1 | 1 |
| $\bar z\bar t$ | 1 | 0 | 0 | 1 |


  Tế bào lớn: $\bar y\bar t$ (4 góc), $yt$ (khối giữa 2×2), $\bar x\bar zt$ (hàng $\bar zt$, cột $\bar xy,\bar x\bar y$), $\bar x\bar y\bar z$ (cột cuối, hàng $\bar zt,\bar z\bar t$). Bắt buộc: $\bar y\bar t$, $yt$. Còn ô $\bar x\bar y\bar zt$ ⇒ chọn $\bar x\bar zt$ hoặc $\bar x\bar y\bar z$ (cùng 3 từ đơn).

- **Kết luận.** $f=\bar y\bar t\vee yt\vee\bar x\bar zt$ hoặc $f=\bar y\bar t\vee yt\vee\bar x\bar y\bar z$.
- **Kiểm tra.** Vét cạn cho đúng 2 phủ tối tiểu [CC].
- **Biến thể (V4).** Thêm ô $1001$ ($x\bar y\bar zt$): xuất hiện tế bào lớn $\bar y\bar z$ (hàng $\bar zt,\bar z\bar t$ × cột $x\bar y,\bar x\bar y$) và $\bar zt$ (cả hàng $\bar zt$) ⇒ hai công thức tối tiểu $\bar y\bar t\vee yt\vee\bar zt$ và $\bar y\bar t\vee yt\vee\bar y\bar z$ **[CC]**.
- **Lỗi thường gặp.** Không nhận ra 4 góc là một tế bào — [T-20](#T-20).
- **Liên kết.** [BOO-03-E02](#BOO-03-E02).

### BOO-04-E01 · Thiết kế mạch 2 công tắc {#BOO-04-E01}
**D1 · V0 · Đề [SV] S4-p75–76 · Lời giải [SV]**

- **Đề.** Đèn điều khiển bởi 2 cầu dao $x,y$ (1 = bật). Đèn sáng ($F=1$) khi cả hai cùng bật hoặc cùng tắt. Thiết kế mạch.
- **Nhận diện.** [BOO-04](#BOO-04). **Phương pháp.** [M-23](#M-23).
- **Kiến thức.** [F-BOO-02](#F-BOO-02) (dạng nối rời chính tắc), [F-BOO-05](#F-BOO-05) (cổng).
- **Lời giải.** Bảng: $F(1,1)=1$, $F(1,0)=0$, $F(0,1)=0$, $F(0,0)=1$ ⇒ $F=xy\vee\bar x\bar y$ (không rút gọn được: hai ô không kề). Mạch: AND($x,y$); NOT $x$, NOT $y$ → AND($\bar x,\bar y$); hai đầu ra → OR.
- **Kết luận.** $F=xy\vee\bar x\bar y$ (2 cổng AND, 2 NOT, 1 OR).
- **Kiểm tra.** Thế 4 bộ giá trị ✓.
- **Biến thể (V2).** Đèn sáng khi **đúng một** công tắc bật: $F=x\bar y\vee\bar xy$ (phần bù).
- **Lỗi thường gặp.** Nhầm $\bar x\bar y$ với $\overline{xy}$ (NAND) — [T-22](#T-22).
- **Liên kết.** [BOO-04-E02](#BOO-04-E02).

### BOO-04-E02 · Thiết kế mạch 3 công tắc (đèn cầu thang) {#BOO-04-E02}
**D2 · V1 · Đề [SV] S4-p77–78 · Lời giải [SV], [CC]**

- **Đề.** Ba cầu dao $x,y,z$. $F(x,y,z)=1$ khi có 1 hoặc 3 cầu dao bật. Lập bảng, công thức, mạch; có rút gọn được không?
- **Nhận diện.** [BOO-04](#BOO-04). **Phương pháp.** [M-23](#M-23), [M-22](#M-22).
- **Kiến thức.** [F-BOO-02](#F-BOO-02), [F-BOO-04](#F-BOO-04), [F-BOO-05](#F-BOO-05).
- **Lời giải.** $F=1$ tại $111,100,010,001$ ⇒ $F=xyz\vee x\bar y\bar z\vee\bar xy\bar z\vee\bar x\bar yz$. Trên kar(F) 4 ô này đôi một **không kề** (bàn cờ) ⇒ mỗi ô là một tế bào lớn ⇒ công thức trên đã tối tiểu. Mạch: 4 cổng AND 3 ngõ vào (dùng NOT cho biến có gạch) → 1 cổng OR 4 ngõ vào.
- **Kết luận.** $F=xyz\vee x\bar y\bar z\vee\bar xy\bar z\vee\bar x\bar yz$, không rút gọn được dạng đa thức.
- **Kiểm tra.** $F=1\Leftrightarrow x+y+z$ lẻ (8 hàng) [CC]; vét cạn xác nhận phủ tối tiểu là 4 từ tối tiểu.
- **Ghi chú nguồn.** Slide ghi "$F(x,y)$" — đúng phải là $F(x,y,z)$ (ERR-07).
- **Biến thể (V1).** 3 cầu dao, đèn sáng khi **đúng 2** cầu dao bật: $F=xy\bar z\vee x\bar yz\vee\bar xyz$.
- **Lỗi thường gặp.** Cố gộp ô chéo nhau trên bản đồ.
- **Liên kết.** [BOO-04-E01](#BOO-04-E01).

### BOO-04-E03 · Đọc mạch: kết quả là hằng 0 — bẫy {#BOO-04-E03}
**D1 · V4 · Đề [SV] S4-p74 · Lời giải [SV]+[CC]**

- **Đề.** Sơ đồ: cổng OR với ngõ vào $x,y,z$; ba cổng NOT với ngõ vào $x,y,z$ nối vào cổng AND; đầu ra OR và đầu ra AND nối vào một cổng AND cuối. Viết biểu thức $f$ và nhận xét.
- **Nhận diện.** "Viết biểu thức $f$ của sơ đồ" → [BOO-04](#BOO-04).
- **Phương pháp.** [M-23](#M-23) (đọc mạch từ trái sang phải).
- **Kiến thức.** [F-BOO-05](#F-BOO-05); De Morgan ([F-LOG-03](#F-LOG-03)).
- **Lời giải.** Đầu ra OR: $x\vee y\vee z$. Đầu ra AND giữa: $\bar x\bar y\bar z$. Đầu ra cuối: $f=(x\vee y\vee z)\,\bar x\bar y\bar z$. Theo De Morgan $\bar x\bar y\bar z=\overline{x\vee y\vee z}$ ⇒ $f=u\cdot\bar u=0$ với $u=x\vee y\vee z$.
- **Kết luận.** $f\equiv0$ — mạch luôn cho ra 0 (slide chỉ yêu cầu viết biểu thức; nhận xét hằng 0 là phân tích bổ sung, ERR-08).
- **Kiểm tra.** 8 bộ giá trị đều cho 0 [CC].
- **Biến thể (V2).** Thay cổng AND cuối bằng OR: $f=u\vee\bar u\equiv1$.
- **Lỗi thường gặp.** Dừng ở biểu thức mà không rút gọn; viết $\overline{xyz}$ thay cho $\bar x\bar y\bar z$ — [T-22](#T-22).
- **Liên kết.** [F-BOO-05](#F-BOO-05).

### BOO-04-E04 · Vẽ mạch từ công thức — và rút gọn trước khi vẽ {#BOO-04-E04}
**D2 · V3 · Đề [SV] S4-p72 · Lời giải [SV] (mạch), rút gọn [CC]**

- **Đề.** Vẽ mạch cho $f=xz\vee\bar yz\vee xt\vee\bar y\bar t\vee\bar x\bar y\bar z$. Có mạch nào ít cổng hơn không?
- **Nhận diện.** [BOO-04](#BOO-04) + [BOO-03](#BOO-03).
- **Phương pháp.** [M-23](#M-23), [M-22](#M-22).
- **Kiến thức.** [F-BOO-04](#F-BOO-04), [F-BOO-05](#F-BOO-05).
- **Lời giải.** Mạch nguồn: 5 cổng AND ($xz$; $\bar y$ qua NOT với $z$; $xt$; $\bar y,\bar t$ qua NOT; $\bar x,\bar y,\bar z$ qua NOT) → 1 cổng OR 5 ngõ vào.
  Rút gọn: mọi ô có $y=0$ đều thuộc kar(f) ($\bar yz$ phủ $z=1$; $\bar y\bar t$ phủ $\bar z\bar t$; ô $\bar x\bar y\bar zt$ do $\bar x\bar y\bar z$; ô $x\bar y\bar zt$ do $xt$) ⇒ $\bar y$ là tế bào lớn 8 ô. Tế bào lớn: $\bar y$, $xz$, $xt$ — đều bắt buộc.
- **Kết luận.** $f=\bar y\vee xz\vee xt$ — chỉ cần 1 NOT, 2 AND, 1 OR.
- **Kiểm tra.** Vét cạn: hai công thức cùng 11 ô; phủ tối tiểu duy nhất $\bar y\vee xt\vee xz$ [CC].
- **Biến thể (V1).** Có thể viết thêm $f=\bar y\vee x(z\vee t)$ (không còn là công thức đa thức nhưng ít cổng hơn: 1 NOT, 1 OR, 1 AND, 1 OR).
- **Lỗi thường gặp.** Vẽ mạch ngay từ công thức chưa rút gọn khi đề yêu cầu "mạch đơn giản".
- **Liên kết.** [BOO-03-E01](#BOO-03-E01).
