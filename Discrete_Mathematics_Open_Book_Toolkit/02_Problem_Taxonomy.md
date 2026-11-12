# Phân loại dạng bài (Problem Taxonomy) {#taxonomy}

Mỗi dạng: **Từ khóa** (cách đề hỏi) · **Dấu hiệu** · **Kiểm tra trước** · **Kiến thức** (mã F-) · **Phương pháp** (mã M-) · **Ví dụ** · **Nguồn**. Mã ví dụ dạng `DẠNG-Exx`; nhãn độ khó D1–D3 và biến thể V0–V4 ghi trong từng ví dụ.

## Chương I — Cơ sở logic

### LOG-01 · Nhận biết mệnh đề, phân loại sơ cấp/phức hợp {#LOG-01}

- **Từ khóa:** "có phải là mệnh đề không", "mệnh đề sơ cấp / phức hợp", "xác định chân trị".
- **Dấu hiệu:** cho danh sách câu nói tự nhiên.
- **Kiểm tra trước:** câu hỏi, cảm thán, mệnh lệnh, câu chứa biến tự do ("n là số tự nhiên") **không** là mệnh đề.
- **Kiến thức:** [F-LOG-01](#F-LOG-01). **Phương pháp:** đối chiếu định nghĩa (S1-p6, p9).
- **Ví dụ:** [LOG-01-E01](#LOG-01-E01). **Nguồn:** S1-p6–9.

### LOG-02 · Lập bảng chân trị; hằng đúng / hằng sai {#LOG-02}

- **Từ khóa:** "lập bảng chân trị", "hằng đúng", "hằng sai", "mâu thuẫn", "chân lý".
- **Dấu hiệu:** cho dạng mệnh đề $E(p,q,\dots)$.
- **Kiểm tra trước:** số dòng $=2^n$; thứ tự ưu tiên ngoặc.
- **Kiến thức:** [F-LOG-01](#F-LOG-01). **Phương pháp:** [M-01](#M-01).
- **Ví dụ:** [LOG-02-E01](#LOG-02-E01), [LOG-02-E02](#LOG-02-E02). **Nguồn:** S1-p18–22.

### LOG-03 · Chứng minh tương đương logic / rút gọn dạng mệnh đề {#LOG-03}

- **Từ khóa:** "chứng minh $E \Leftrightarrow F$", "tương đương logic", "rút gọn", "đơn giản biểu thức", "hệ quả logic".
- **Dấu hiệu:** hai dạng mệnh đề nối bằng $\Leftrightarrow$ hoặc $\Rightarrow$.
- **Kiểm tra trước:** mỗi bước phải nêu tên luật; "$\Rightarrow$" (hệ quả) khác "$\Leftrightarrow$".
- **Kiến thức:** [F-LOG-02](#F-LOG-02), [F-LOG-03](#F-LOG-03). **Phương pháp:** [M-02](#M-02) (hoặc [M-01](#M-01) để đối chiếu).
- **Ví dụ:** [LOG-03-E01](#LOG-03-E01), [LOG-03-E02](#LOG-03-E02). **Nguồn:** S1-p23–30.

### LOG-04 · Chứng minh suy luận đúng (quy tắc suy diễn, phản chứng) {#LOG-04}

- **Từ khóa:** "chứng minh suy luận", "kiểm tra suy luận", "$\therefore$", "suy ra", "tiền đề – kết luận".
- **Dấu hiệu:** danh sách tiền đề trên vạch ngang, kết luận dưới có dấu $\therefore$.
- **Kiểm tra trước:** kết luận dạng kéo theo → có thể dùng phản chứng (thêm $\neg h$) hoặc đổi sang phản đảo.
- **Kiến thức:** [F-LOG-04](#F-LOG-04). **Phương pháp:** [M-03](#M-03), [M-04](#M-04).
- **Ví dụ:** [LOG-04-E01](#LOG-04-E01), [LOG-04-E02](#LOG-04-E02), [LOG-04-E03](#LOG-04-E03). **Nguồn:** S1-p31–54.

### LOG-05 · Suy luận sai — tìm phản ví dụ; bài toán lời văn {#LOG-05}

- **Từ khóa:** "suy luận sau có đúng không", "đúng hay sai", đoạn văn có "nếu… thì…", "biết rằng".
- **Dấu hiệu:** không chắc kết luận đúng; bài toán lời văn cần đặt biến mệnh đề.
- **Kiểm tra trước:** gán kết luận = 0, giải hệ "mọi tiền đề = 1"; có nghiệm ⇒ suy luận sai.
- **Kiến thức:** [F-LOG-04](#F-LOG-04) (quy tắc 9 — phản ví dụ). **Phương pháp:** [M-05](#M-05).
- **Ví dụ:** [LOG-05-E01](#LOG-05-E01), [LOG-05-E02](#LOG-05-E02). **Nguồn:** S1-p48–49, p55–56.

### QNT-01 · Xét chân trị mệnh đề có lượng từ {#QNT-01}

- **Từ khóa:** "∀", "∃", "với mọi", "tồn tại", "đúng hay sai", "có ít nhất một".
- **Dấu hiệu:** vị từ một hoặc hai biến trên tập số.
- **Kiểm tra trước:** **thứ tự lượng từ** ($\forall x\exists y$ ≠ $\exists y\forall x$); miền của biến.
- **Kiến thức:** [F-QNT-01](#F-QNT-01). **Phương pháp:** [M-06](#M-06).
- **Ví dụ:** [QNT-01-E01](#QNT-01-E01), [QNT-01-E02](#QNT-01-E02). **Nguồn:** S1-p59–68.

### QNT-02 · Phủ định mệnh đề có lượng từ {#QNT-02}

- **Từ khóa:** "phủ định", "viết mệnh đề phủ định", "$\overline{\forall x\dots}$".
- **Dấu hiệu:** mệnh đề lượng từ hóa cần lấy phủ định.
- **Kiểm tra trước:** đổi $\forall\leftrightarrow\exists$, phủ định vị từ; phủ định của $A\to B$ là $A\wedge\neg B$; giữ nguyên miền.
- **Kiến thức:** [F-QNT-02](#F-QNT-02). **Phương pháp:** [M-07](#M-07).
- **Ví dụ:** [QNT-02-E01](#QNT-02-E01). **Nguồn:** S1-p69–71.

### SET-01 · Phép toán tập hợp, chứng minh đẳng thức tập hợp {#SET-01}

- **Từ khóa:** "hợp, giao, hiệu, bù", "chứng minh $A\setminus(B\cup C)=\dots$", "De Morgan".
- **Kiểm tra trước:** bù lấy trong tập nào (vũ trụ); hiệu không giao hoán.
- **Kiến thức:** [F-SET-01](#F-SET-01). **Phương pháp:** [M-08](#M-08).
- **Ví dụ:** [SET-01-E01](#SET-01-E01). **Nguồn:** S1-p73–79.

### SET-02 · Tập lũy thừa, tích Đề-các, lực lượng {#SET-02}

- **Từ khóa:** "$P(X)$", "tập các tập con", "$A\times B$", "$|A\times B|$", "lực lượng".
- **Kiểm tra trước:** $\emptyset\in P(X)$, $X\in P(X)$; $A\times B\neq B\times A$.
- **Kiến thức:** [F-SET-02](#F-SET-02). **Ví dụ:** [SET-02-E01](#SET-02-E01). **Nguồn:** S1-p80–82.

### FUN-01 · Ánh xạ: kiểm tra định nghĩa, ảnh và ảnh ngược {#FUN-01}

- **Từ khóa:** "có phải ánh xạ", "$f(A)$", "$f^{-1}(B)$", "ảnh", "ảnh ngược / tạo ảnh".
- **Kiểm tra trước:** mỗi $x$ có **đúng một** ảnh trong $Y$; $f^{-1}(B)$ tồn tại kể cả khi $f$ không song ánh.
- **Kiến thức:** [F-FUN-01](#F-FUN-01). **Phương pháp:** [M-09](#M-09).
- **Ví dụ:** [FUN-01-E01](#FUN-01-E01). **Nguồn:** S1-p83–87.

### FUN-02 · Đơn ánh, toàn ánh, song ánh; ánh xạ ngược {#FUN-02}

- **Từ khóa:** "đơn ánh", "toàn ánh", "song ánh", "ánh xạ ngược", "khả nghịch", "1-1", "lên".
- **Dấu hiệu:** cho $f:X\to Y$ cụ thể (chú ý $X$, $Y$).
- **Kiểm tra trước:** **miền và tập đích** quyết định kết quả ($x^2+1$ đơn ánh trên $\mathbb N$ nhưng không trên $\mathbb R$).
- **Kiến thức:** [F-FUN-02](#F-FUN-02), [F-FUN-03](#F-FUN-03). **Phương pháp:** [M-09](#M-09).
- **Ví dụ:** [FUN-02-E01](#FUN-02-E01), [FUN-02-E02](#FUN-02-E02). **Nguồn:** S1-p88–94.

### FUN-03 · Tích (hợp) ánh xạ $g\circ f$, $f\circ g$ {#FUN-03}

- **Từ khóa:** "tìm $g\circ f$", "$f\circ g$", "tích ánh xạ", "hàm hợp".
- **Kiểm tra trước:** $g\circ f(x)=g(f(x))$ — áp $f$ trước; với hàm từng khúc, xét điều kiện trên **$f(x)$** chứ không trên $x$.
- **Kiến thức:** [F-FUN-03](#F-FUN-03). **Ví dụ:** [FUN-03-E01](#FUN-03-E01). **Nguồn:** S1-p95–96.

### IND-01 · Chứng minh bằng quy nạp toán học {#IND-01}

- **Từ khóa:** "chứng minh với mọi $n\ge n_0$", "quy nạp", "$P(n)$", tổng $1+3+\dots$, "chia hết", "$2^n<n!$".
- **Kiểm tra trước:** bước cơ sở đúng giá trị $n_0$ của đề (có thể khác 1); bước quy nạp phải **dùng** giả thiết quy nạp.
- **Kiến thức:** [F-IND-01](#F-IND-01). **Phương pháp:** [M-10](#M-10).
- **Ví dụ:** [IND-01-E01](#IND-01-E01) … [IND-01-E04](#IND-01-E04). **Nguồn:** S1-p97–100, S1-p47.

## Chương II — Phép đếm

### CNT-01 · Nguyên lý cộng, nhân (đếm số, chia trường hợp) {#CNT-01}

- **Từ khóa:** "có bao nhiêu cách", "bao nhiêu số … chữ số khác nhau", "chia hết cho 2/5", "chẵn".
- **Dấu hiệu:** lập số từ tập chữ số có chứa 0; điều kiện ở chữ số cuối.
- **Kiểm tra trước:** chữ số đầu $\ne0$; "khác nhau" hay không; xét chữ số bị ràng buộc **trước**.
- **Kiến thức:** [F-CNT-01](#F-CNT-01). **Phương pháp:** [M-11](#M-11).
- **Ví dụ:** [CNT-01-E01](#CNT-01-E01), [CNT-01-E02](#CNT-01-E02). **Nguồn:** S2-p3–5.

### CNT-02 · Nguyên lý chuồng bồ câu (Dirichlet) {#CNT-02}

- **Từ khóa:** "chứng minh tồn tại", "ít nhất", "luôn có hai phần tử", "cùng ngày sinh".
- **Kiểm tra trước:** xác định rõ "chim" và "chuồng"; dùng $\lceil n/k\rceil$.
- **Kiến thức:** [F-CNT-02](#F-CNT-02). **Phương pháp:** [M-12](#M-12).
- **Ví dụ:** [CNT-02-E01](#CNT-02-E01). **Nguồn:** S2-p6–7.

### CNT-03 · Nguyên lý bù trừ {#CNT-03}

- **Từ khóa:** "học tiếng Anh hoặc tiếng Pháp", "chia hết cho 2 hoặc 3 hoặc 5", "ít nhất một", "không chia hết cho".
- **Kiến thức:** [F-CNT-03](#F-CNT-03). **Phương pháp:** [M-13](#M-13).
- **Ví dụ:** [CNT-03-E01](#CNT-03-E01), [CNT-03-E02](#CNT-03-E02). **Nguồn:** S2-p8–10.

### CNT-04 · Hoán vị, chỉnh hợp, tổ hợp {#CNT-04}

- **Từ khóa:** "sắp xếp", "xếp hàng" (hoán vị); "chọn và sắp thứ tự", "lập số có $k$ chữ số khác nhau" (chỉnh hợp); "chọn nhóm", "tập con $k$ phần tử", "ủy ban" (tổ hợp).
- **Kiểm tra trước:** có **thứ tự** không? có **lặp** không? (cây quyết định [M-14](#M-14)).
- **Kiến thức:** [F-CNT-04](#F-CNT-04). **Ví dụ:** [CNT-04-E01](#CNT-04-E01). **Nguồn:** S2-p11–16.

### CNT-05 · Hoán vị lặp (sắp xếp có phần tử giống nhau) {#CNT-05}

- **Từ khóa:** "sắp xếp các chữ cái của từ", "chuỗi khác nhau", "đồ vật giống nhau".
- **Kiến thức:** [F-CNT-05](#F-CNT-05). **Ví dụ:** [CNT-05-E01](#CNT-05-E01). **Nguồn:** S2-p17–18.

### CNT-06 · Tổ hợp lặp; số nghiệm nguyên không âm có ràng buộc; chia vật giống nhau {#CNT-06}

- **Từ khóa:** "chọn $k$ vật từ $n$ loại (được lặp)", "số nghiệm nguyên không âm $x_1+\dots+x_n=k$", "chia $k$ vật giống nhau vào $n$ hộp", "ít nhất", "không quá".
- **Kiểm tra trước:** ràng buộc "$\ge a$" → đổi biến; "$\le b$" → **lấy phần bù** (trừ trường hợp "$\ge b+1$"); "$>$" → đổi thành "$\ge$" với số nguyên.
- **Kiến thức:** [F-CNT-06](#F-CNT-06). **Phương pháp:** [M-15](#M-15), [M-13](#M-13).
- **Ví dụ:** [CNT-06-E01](#CNT-06-E01), [CNT-06-E02](#CNT-06-E02), [CNT-06-E03](#CNT-06-E03). **Nguồn:** S2-p19–25.

### REC-01 · Lập hệ thức đệ qui từ bài toán {#REC-01}

- **Từ khóa:** "tìm một hệ thức đệ qui cho $x_n$", "cầu thang", "tháp Hà Nội", "số cách", "chuỗi bit độ dài $n$".
- **Kiểm tra trước:** các trường hợp phải **rời nhau và đầy đủ**; tìm đủ điều kiện ban đầu ($x_1$, $x_2$…).
- **Kiến thức:** [F-CNT-01](#F-CNT-01) (nguyên lý cộng). **Phương pháp:** [M-16](#M-16).
- **Ví dụ:** [REC-01-E01](#REC-01-E01), [REC-01-E02](#REC-01-E02), [REC-01-E03](#REC-01-E03). **Nguồn:** S2-p27–39.

### REC-02 · Giải hệ thức đệ qui tuyến tính thuần nhất (cấp 1, 2) {#REC-02}

- **Từ khóa:** "giải hệ thức", "vế phải = 0", "tìm nghiệm tổng quát", "nghiệm riêng thỏa $x_0, x_1$".
- **Kiểm tra trước:** viết đúng PTĐT (bậc = cấp); nghiệm kép → $(C_1+nC_2)\lambda_0^n$.
- **Kiến thức:** [F-REC-01](#F-REC-01), [F-REC-02](#F-REC-02). **Phương pháp:** [M-17](#M-17).
- **Ví dụ:** [REC-02-E01](#REC-02-E01), [REC-02-E02](#REC-02-E02), [REC-02-E03](#REC-02-E03). **Nguồn:** S2-p41–46.

### REC-03 · Giải hệ thức không thuần nhất, vế phải $f_n=\beta^nP_r(n)$ {#REC-03}

- **Từ khóa:** vế phải là đa thức theo $n$, hoặc $\beta^n\times$ đa thức; "$(18n+12)3^n$", "$12n+8$", "hằng số".
- **Kiểm tra trước:** **$\beta$ có là nghiệm của PTĐT không, bội mấy?** → nhân $n^0, n^1, n^2$; đa thức thuần ($\beta=1$!).
- **Kiến thức:** [F-REC-03](#F-REC-03), [F-REC-05](#F-REC-05). **Phương pháp:** [M-17](#M-17).
- **Ví dụ:** [REC-03-E01](#REC-03-E01) … [REC-03-E09](#REC-03-E09). **Nguồn:** S2-p47–63, p67.

### REC-04 · Vế phải là tổng nhiều dạng (chồng chất nghiệm riêng) {#REC-04}

- **Từ khóa:** vế phải có dạng "$20+(2-n)2^{n-2}+3\cdot4^n$".
- **Kiểm tra trước:** tách thành các dạng 1 theo từng $\beta$ khác nhau; xét bội của **từng** $\beta$.
- **Kiến thức:** [F-REC-04](#F-REC-04). **Phương pháp:** [M-17](#M-17).
- **Ví dụ:** [REC-04-E01](#REC-04-E01). **Nguồn:** S2-p52, p64–66.

## Chương III — Quan hệ

### REL-01 · Liệt kê quan hệ; ma trận biểu diễn {#REL-01}

- **Từ khóa:** "liệt kê các cặp", "ma trận biểu diễn $M_R$", "từ ma trận suy ra các cặp".
- **Kiểm tra trước:** hàng = phần tử của $A$ (tập nguồn), cột = phần tử của $B$; thứ tự liệt kê.
- **Kiến thức:** [F-REL-01](#F-REL-01). **Ví dụ:** [REL-01-E01](#REL-01-E01). **Nguồn:** S3-p4–6, p12–15.

### REL-02 · Kiểm tra tính chất phản xạ, đối xứng, phản xứng, bắc cầu {#REL-02}

- **Từ khóa:** "quan hệ có tính chất gì", "phản xạ", "đối xứng", "phản xứng / phản đối xứng", "bắc cầu / truyền".
- **Kiểm tra trước:** chứng minh "có" phải tổng quát; "không" chỉ cần **một phản ví dụ cụ thể**.
- **Kiến thức:** [F-REL-01](#F-REL-01). **Phương pháp:** [M-18](#M-18).
- **Ví dụ:** [REL-02-E01](#REL-02-E01), [REL-02-E02](#REL-02-E02). **Nguồn:** S3-p7–11, p16–18.

### REL-03 · Quan hệ tương đương, lớp tương đương, đồng dư {#REL-03}

- **Từ khóa:** "chứng minh quan hệ tương đương", "tìm các lớp tương đương", "$[a]_R$", "đồng dư modulo $m$", "phân hoạch", "$\mathbb Z_m$".
- **Kiến thức:** [F-REL-02](#F-REL-02), [F-REL-03](#F-REL-03). **Phương pháp:** [M-18](#M-18), [M-19](#M-19).
- **Ví dụ:** [REL-03-E01](#REL-03-E01), [REL-03-E02](#REL-03-E02). **Nguồn:** S3-p19–27.

### POS-01 · Chứng minh quan hệ thứ tự; thứ tự toàn phần {#POS-01}

- **Từ khóa:** "có phải poset", "quan hệ thứ tự", "thứ tự toàn phần / tuyến tính", "so sánh được".
- **Kiểm tra trước:** cần **phản xạ + phản xứng + bắc cầu**; tập nguồn ($\mathbb Z$ hay $\mathbb Z^+$) quyết định phản xứng của "|".
- **Kiến thức:** [F-POS-01](#F-POS-01). **Phương pháp:** [M-18](#M-18).
- **Ví dụ:** [POS-01-E01](#POS-01-E01). **Nguồn:** S3-p28–35.

### POS-02 · Thứ tự từ điển {#POS-02}

- **Từ khóa:** "thứ tự từ điển", "so sánh chuỗi", "chuỗi bit", "$\Sigma^*$".
- **Kiểm tra trước:** chuỗi là **tiền tố** của chuỗi kia thì nhỏ hơn; so sánh tại vị trí khác đầu tiên.
- **Kiến thức:** [F-POS-02](#F-POS-02). **Ví dụ:** [POS-02-E01](#POS-02-E01). **Nguồn:** S3-p36–41.

### POS-03 · Biểu đồ Hasse; tối đại, tối tiểu, lớn nhất, nhỏ nhất {#POS-03}

- **Từ khóa:** "vẽ biểu đồ Hasse", "phần tử tối đại / tối tiểu", "lớn nhất / nhỏ nhất".
- **Kiểm tra trước:** chỉ vẽ cung **trội trực tiếp**; tối đại ≠ lớn nhất (có thể nhiều tối đại, không có lớn nhất).
- **Kiến thức:** [F-POS-03](#F-POS-03). **Phương pháp:** [M-20](#M-20).
- **Ví dụ:** [POS-03-E01](#POS-03-E01). **Nguồn:** S3-p42–49.

### POS-04 · Chặn trên, chặn dưới, sup, inf {#POS-04}

- **Từ khóa:** "chặn trên / chặn dưới của $A$", "chặn trên nhỏ nhất", "chặn dưới lớn nhất", "sup", "inf", "$a\vee b$, $a\wedge b$".
- **Kiểm tra trước:** chặn có thể nằm ngoài $A$; sup có thể không tồn tại.
- **Kiến thức:** [F-POS-03](#F-POS-03). **Phương pháp:** [M-20](#M-20).
- **Ví dụ:** [POS-04-E01](#POS-04-E01). **Nguồn:** S3-p50–53.

### POS-05 · Sắp xếp topo {#POS-05}

- **Từ khóa:** "sắp xếp topo", "thứ tự thực hiện công việc", "mặc quần áo".
- **Kiến thức:** [F-POS-03](#F-POS-03). **Phương pháp:** [M-21](#M-21).
- **Ví dụ:** [POS-05-E01](#POS-05-E01). **Nguồn:** S3-p54–56.

## Chương IV — Đại số Bool

### BOO-01 · Hàm Bool từ mô tả; bảng chân trị; dạng nối rời chính tắc {#BOO-01}

- **Từ khóa:** "lập bảng chân trị của $f$", "bỏ phiếu", "đa số", "dạng nối rời chính tắc", "tổng các từ tối tiểu".
- **Kiến thức:** [F-BOO-01](#F-BOO-01), [F-BOO-02](#F-BOO-02). **Phương pháp:** [M-23](#M-23).
- **Ví dụ:** [BOO-01-E01](#BOO-01-E01), [BOO-01-E02](#BOO-01-E02). **Nguồn:** S4-p10–19.

### BOO-02 · Biểu đồ Karnaugh: vẽ kar(f), đọc tế bào ↔ đơn thức {#BOO-02}

- **Từ khóa:** "vẽ biểu đồ Karnaugh", "tế bào sau là biểu đồ của đơn thức nào".
- **Kiểm tra trước:** đúng **khung nhãn của nguồn** (cột $x\bar y, xy, \bar xy, \bar x\bar y$; hàng $z\bar t, zt, \bar zt, \bar z\bar t$); ô đầu–cuối hàng/cột là kề nhau.
- **Kiến thức:** [F-BOO-03](#F-BOO-03), [F-BOO-04](#F-BOO-04). **Ví dụ:** [BOO-02-E01](#BOO-02-E01). **Nguồn:** S4-p22–32.

### BOO-03 · Tìm công thức đa thức tối tiểu bằng Karnaugh {#BOO-03}

- **Từ khóa:** "tìm (tất cả) công thức đa thức tối tiểu", "tối thiểu hóa", "rút gọn hàm Bool", "tế bào lớn".
- **Kiểm tra trước:** liệt kê **đủ** tế bào lớn; tế bào bắt buộc; ô còn lại có thể có nhiều cách phủ → so sánh độ đơn giản.
- **Kiến thức:** [F-BOO-03](#F-BOO-03), [F-BOO-04](#F-BOO-04). **Phương pháp:** [M-22](#M-22).
- **Ví dụ:** [BOO-03-E01](#BOO-03-E01) … [BOO-03-E05](#BOO-03-E05). **Nguồn:** S4-p33–65.

### BOO-04 · Mạng logic: vẽ mạch, đọc mạch, thiết kế mạch công tắc {#BOO-04}

- **Từ khóa:** "vẽ mạch", "cổng AND/OR/NOT/NAND/NOR", "viết biểu thức $f$ của sơ đồ", "thiết kế mạch điều khiển bởi … cầu dao".
- **Kiến thức:** [F-BOO-05](#F-BOO-05). **Phương pháp:** [M-23](#M-23).
- **Ví dụ:** [BOO-04-E01](#BOO-04-E01) … [BOO-04-E04](#BOO-04-E04). **Nguồn:** S4-p66–78.

## Chương V — Đồ thị

### GRA-01 · Phân loại đồ thị; bậc; định lý bắt tay {#GRA-01}

- **Từ khóa:** "bậc của các đỉnh", "đơn đồ thị / đa đồ thị / giả đồ thị", "bậc vào, bậc ra", "số cạnh", "có tồn tại đồ thị với dãy bậc".
- **Kiểm tra trước:** khuyên đếm **2** vào bậc (vô hướng); số đỉnh bậc lẻ phải chẵn.
- **Kiến thức:** [F-GRA-01](#F-GRA-01). **Ví dụ:** [GRA-01-E01](#GRA-01-E01), [GRA-01-E02](#GRA-01-E02). **Nguồn:** S5-p3–25.

### GRA-02 · Ma trận kề {#GRA-02}

- **Từ khóa:** "tìm ma trận kề", "biểu diễn đồ thị bằng ma trận", "vẽ đồ thị từ ma trận".
- **Kiểm tra trước:** cạnh song song → số > 1; khuyên → quy ước (CON-01); vô hướng → ma trận đối xứng.
- **Kiến thức:** [F-GRA-02](#F-GRA-02). **Ví dụ:** [GRA-02-E01](#GRA-02-E01). **Nguồn:** S5-p26–28.

### GRA-03 · Đẳng cấu đồ thị {#GRA-03}

- **Từ khóa:** "hai đồ thị có đẳng cấu không", "tìm song ánh".
- **Kiểm tra trước:** bất biến (số đỉnh, số cạnh, dãy bậc, …) — khác ⇒ **không** đẳng cấu; giống **chưa đủ** ⇒ phải chỉ ra song ánh.
- **Kiến thức:** [F-GRA-03](#F-GRA-03). **Phương pháp:** [M-24](#M-24). **Ví dụ:** [GRA-03-E01](#GRA-03-E01). **Nguồn:** S5-p29–35.

### GRA-04 · Đường đi, chu trình, liên thông, đỉnh khớp, cầu {#GRA-04}

- **Từ khóa:** "đường đi đơn / sơ cấp", "chu trình sơ cấp", "thành phần liên thông", "đỉnh khớp", "cầu".
- **Kiến thức:** định nghĩa S5-p36–41. **Ví dụ:** [GRA-04-E01](#GRA-04-E01). **Nguồn:** S5-p36–42.

### GRA-05 · Đường đi / chu trình Euler; thuật toán Fleury {#GRA-05}

- **Từ khóa:** "đi qua mỗi cạnh đúng một lần", "vẽ bằng một nét", "chu trình Euler", "cây cầu Königsberg", "Fleury".
- **Kiểm tra trước:** **liên thông** (bỏ qua đỉnh cô lập) + đếm đỉnh bậc lẻ: 0 → chu trình; 2 → đường đi (bắt đầu ở đỉnh lẻ).
- **Kiến thức:** [F-GRA-04](#F-GRA-04). **Phương pháp:** [M-25](#M-25). **Ví dụ:** [GRA-05-E01](#GRA-05-E01), [GRA-05-E02](#GRA-05-E02). **Nguồn:** S5-p43–51.

### GRA-06 · Đường đi ngắn nhất — Dijkstra {#GRA-06}

- **Từ khóa:** "đường đi ngắn nhất", "khoảng cách", "Dijkstra", "trọng số dương", "ma trận trọng số".
- **Kiểm tra trước:** **mọi trọng số > 0** (nếu có cạnh âm → dùng Ford–Bellman); vô hướng hay có hướng.
- **Kiến thức:** [F-GRA-05](#F-GRA-05). **Phương pháp:** [M-26](#M-26). **Ví dụ:** [GRA-06-E01](#GRA-06-E01), [GRA-06-E02](#GRA-06-E02), [GRA-06-E03](#GRA-06-E03). **Nguồn:** S5-p52–72.

### GRA-07 · Đường đi ngắn nhất — Ford–Bellman; phát hiện mạch âm {#GRA-07}

- **Từ khóa:** "Ford–Bellman", "trọng số âm", "mạch âm", "chỉ ra đồ thị có mạch âm".
- **Kiểm tra trước:** dừng khi $L_k=L_{k-1}$ (ổn định) hoặc khi $k=n$ (mạch âm).
- **Kiến thức:** [F-GRA-06](#F-GRA-06). **Phương pháp:** [M-27](#M-27). **Ví dụ:** [GRA-07-E01](#GRA-07-E01), [GRA-07-E02](#GRA-07-E02). **Nguồn:** S5-p73–86.
