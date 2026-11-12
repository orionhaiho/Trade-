# 00 — Gap & Conflict Report (Khoảng trống, mâu thuẫn, lỗi nguồn)

Nhãn: **[SOURCE-VERIFIED]** có trong nguồn · **[CROSS-CHECKED]** kiểm tra độc lập · **[INFERRED]** suy luận · **[UNVERIFIED]** chưa đủ căn cứ · **[CONFLICT]** mâu thuẫn.

## A. Khoảng trống dữ liệu (GAP)

| Mã | Khoảng trống | Ảnh hưởng | Cách xử lý hiện tại | Cần người dùng cung cấp |
|---|---|---|---|---|
| GAP-01 | **Không có đề cương / phạm vi thi chính thức** | Không khẳng định được chương nào thi, trọng số | Phạm vi = toàn bộ 5 chương slide, nhãn **[INFERRED]** | Đề cương học phần hoặc thông báo phạm vi thi |
| GAP-02 | **Không có đề thi cũ / bài tập giảng viên giao riêng** | Không thống kê được tần suất dạng bài; dạng bài chỉ dựa vào ví dụ & "Bài tập" trong slide | Không ghi tần suất; ví dụ bổ sung gắn **[AI-GENERATED PRACTICE]** | Đề thi các năm trước (kèm đáp án nếu có) |
| GAP-03 | Không có giáo trình (4 tài liệu tham khảo ở S1-p3 không được cung cấp) | Một số định nghĩa chỉ có ở mức slide; không có số trang giáo trình | Chỉ dẫn nguồn tới trang slide | (Tùy chọn) PDF giáo trình Nguyễn Duy Nhất/Trần Ngọc Hội |
| GAP-04 | S2-p26 "Hệ thức đệ qui": slide chỉ có tiêu đề (nội dung không trích được, không có ảnh) | Không ảnh hưởng nội dung chính | Bỏ qua | — |
| GAP-05 | S2 nói tới "nghiệm phức" không có; slide chỉ dạy PTĐT **nghiệm thực phân biệt / nghiệm kép** (S2-p43) | Trường hợp nghiệm phức **ngoài phạm vi slide** | Không đưa vào phần chính thức (ghi chú ở Traps) | Xác nhận có thi nghiệm phức không |
| GAP-06 | S4-p79 chỉ dẫn link Quine–McCluskey, không có nội dung | Không biết có thi Q–M không | Chỉ biên soạn phương pháp Karnaugh | Xác nhận |
| GAP-07 | S5-p55 liệt kê "Vét cạn, Dijkstra, Ford–Bellman, **Floyd**" nhưng slide chỉ trình bày Dijkstra & Ford–Bellman | Floyd có thể ngoài phạm vi | Không biên soạn Floyd | Xác nhận |
| GAP-08 | S5: không có cây, đồ thị Hamilton, tô màu, đồ thị phẳng, BFS/DFS | — | **Không** mở rộng phạm vi (Quy tắc 14) | — |
| GAP-09 | S1 có "Bài tập" không lời giải (S1-p22, p50 lời giải ngắn, p100 quy nạp; S2-p25 bài chia táo; S2-p67 6 hệ thức đệ qui; S5-p21, p35) | — | Đã giải đầy đủ trong Example Bank, gắn nhãn nguồn + [CROSS-CHECKED] | — |
| GAP-10 | Hình thức thi open-book không xuất hiện trong nguồn (chỉ có trong S0) | — | Theo S0 | — |

## B. Lỗi / điểm có khả năng sai trong nguồn (không sửa âm thầm)

| Mã | Vị trí | Nội dung nguồn | Vấn đề | Quyết định trong toolkit |
|---|---|---|---|---|
| ERR-01 | S1-p94 | "f(x)=2x+1 … Khi đó $f^{-1}(x)=(y-1)/2$" | Lẫn biến: vế trái theo $x$, vế phải theo $y$ | Ghi đúng: $f^{-1}(y)=\frac{y-1}{2}$ (hay $f^{-1}(x)=\frac{x-1}{2}$). **[CROSS-CHECKED]** |
| ERR-02 | S2-p29 | Định nghĩa hệ thức cấp k: "$a_0\neq 0, a_1,\dots,a_n$ là các hệ số thực" | Chỉ số phải là $a_1,\dots,a_k$ (và để thực sự cấp $k$ cần $a_k\neq0$) | Ghi $a_1,\dots,a_k$; nêu điều kiện $a_k\ne0$ là **[INFERRED]** |
| ERR-03 | S3-p25 | "(i) a R b nếu $[a]_R=[b]_R$; (ii) $[a]_R\ne[b]_R$ nếu $[a]_R\cap[b]_R=\emptyset$" | Phát biểu chỉ một chiều; định lý chuẩn là "⇔" và (ii) phải là "$[a]\ne[b] \Leftrightarrow [a]\cap[b]=\emptyset$" | Toolkit ghi dạng ⇔, có chứng minh ngắn. **[CROSS-CHECKED]** |
| ERR-04 | S3-p37 | Thứ tự từ điển trên $A\times B$: "$(a_1,b_1)\preceq(a_2,b_2)$ nếu $a_1<a_2$ hay ($a_1=a_2$ và $b_1<' b_2$)" | Thiếu trường hợp bằng nhau → định nghĩa như vậy là thứ tự **chặt**, không phản xạ | Toolkit dùng "$b_1 \le' b_2$" và ghi chú. **[INFERRED]** |
| ERR-05 | S1-p85 (ví dụ 2 ánh xạ bằng nhau) | "$f(x)=x$ và $g(x)=(x+5)\bmod 5$ từ $[1,3]\to[1,3]$" | Nếu $[1,3]$ là đoạn số thực, $(x+5)\bmod 5$ với số thực không chuẩn; nếu hiểu $\{1,2,3\}$ thì $f=g$ | Không dùng làm ví dụ chính thức. **[UNVERIFIED]** |
| ERR-06 | S4-p28 | Bản đồ Karnaugh "Ví dụ 1" vẽ 5 hàng | Lỗi vẽ (bản đồ 4 biến có 4 hàng) | Bỏ qua, không ảnh hưởng kết quả |
| ERR-07 | S4-p77 | "Thiết kế mạch 3 cầu dao … biến $x,y$ … $F(x,y)$" | Ghi nhầm $F(x,y)$ thay vì $F(x,y,z)$ | Toolkit ghi $F(x,y,z)$ |
| ERR-08 | S4-p74 | Sơ đồ cổng cho $f=(x\vee y\vee z)\,\bar x\bar y\bar z$ | Biểu thức đọc đúng, nhưng **$f\equiv 0$** (hằng sai) — slide không nêu | Đưa thành bẫy **TRAP-BOO-04**. **[CROSS-CHECKED]** |
| ERR-09 | S2-p65 | "$f_n$ … có dạng ở **Trường hợp 4**" | Slide chỉ định nghĩa "Dạng 1, Dạng 2"; "Trường hợp 4" phải là **Dạng 2** | Toolkit gọi là Dạng 2 |
| ERR-10 | S2-p40 | Ước lượng thời gian tháp Hà Nội dùng "400 ngày/năm × 25 giờ/ngày × 4000 giây/giờ" | Không phải số thực tế; dùng làm **chặn trên mẫu số** để có bất đẳng thức "≥" — hợp lệ nhưng dễ gây hiểu nhầm | Không đưa vào phần chính thức |
| ERR-11 | S1-p10, S1-p69–70, S3, S4 | Phủ định/bù được viết bằng gạch trên ($\bar p$) và cả $\neg p$ | Không phải lỗi; là **hai ký hiệu tương đương** | Bảng ánh xạ ký hiệu trong Formula Handbook |
| ERR-13 | S1-p21 | Liệt kê $C(p,q)=p\wedge\overline{(p\to q)}$ ngay sau định nghĩa hằng sai | Như đã viết, $C\Leftrightarrow p\wedge\neg q$ **không** hằng sai (có thể ý định là $p\wedge\overline{(q\to p)}$) | Toolkit nêu rõ trong LOG-02-E02 **[CROSS-CHECKED]** |
| ERR-12 | S1-p68 | Định lý hoán vị lượng từ ghi "3) ∃x∀y ⇒ ∀y∃x" | Đúng; chiều ngược nói chung sai — nguồn đã nêu | Dùng nguyên văn |

## C. Mâu thuẫn quy ước giữa các phần nguồn (CONFLICT)

| Mã | Vị trí | Mâu thuẫn | Quyết định |
|---|---|---|---|
| CON-01 | S5-p26 vs S5-p28 | Định nghĩa: "$a_{ij}$ = số cạnh (cung) đi từ $i$ đến $j$" — theo định nghĩa này một khuyên tại $e$ cho $a_{ee}=1$; nhưng ma trận ví dụ S5-p28 ghi $a_{ee}=2$ | **[CONFLICT]** Toolkit ghi cả hai quy ước, mặc định theo **ví dụ S5-p28 (khuyên vô hướng đếm 2)** vì khớp với quy ước bậc (khuyên đếm 2, S5-p19) và tổng hàng = bậc. **Cần xác nhận của giảng viên** |
| CON-02 | S1-p58 vs thông lệ | $\mathbb N=\{0,1,2,\dots\}$ (có số 0) | Dùng theo nguồn: $0\in\mathbb N$ |
| CON-03 | S2-p6 | Chuồng bồ câu dùng $\lceil n/k\rceil$ — ký hiệu bị mất khi trích, đọc bằng ảnh | Theo nguồn |
| CON-04 | S5-p22 | "Đỉnh bậc 0 gọi là đỉnh cô lập, đỉnh bậc 1 gọi là đỉnh treo" đặt trong mục đồ thị có hướng | Áp dụng cho cả vô hướng (nghĩa phổ biến) **[INFERRED]** |
| CON-05 | S5-p49 | "Nếu G có 2k đỉnh bậc lẻ thì vẽ được bằng k nét" — đòi hỏi G liên thông, $k\ge1$ (slide không nêu điều kiện) | Thêm điều kiện liên thông **[INFERRED]** |
| CON-06 | S3-p33/S3-p30 | Ký hiệu thứ tự "≼" không hiển thị trong PDF (ô trống) | Dùng $\preceq$ |

## D. Câu hỏi cần người dùng xác nhận (gom một lần)

1. Có đề cương/phạm vi thi và đề thi cũ không? (GAP-01, GAP-02) — nếu có, tôi sẽ thêm thống kê tần suất và điều chỉnh ưu tiên.
2. Có thi **nghiệm phức của PTĐT**, **Quine–McCluskey**, **Floyd** không? (GAP-05/06/07)
3. Quy ước ma trận kề với khuyên: đếm 1 hay 2? (CON-01)

Các phần không bị ảnh hưởng bởi các câu hỏi trên đã được biên soạn tiếp; phần phụ thuộc được đánh dấu.
