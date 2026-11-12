# 00 — Source Inventory (Kiểm kê nguồn)

Ngày kiểm kê: 2026-11-12. Tất cả vị trí nguồn trong bộ tài liệu dùng dạng `S<k>-p<n>` = **trang PDF thứ n** của tệp nguồn S<k> (với hầu hết slide, trang PDF = số slide in ở chân trang).

| Mã | Tệp gốc | Loại | Số trang | Nội dung chính | Chất lượng trích xuất | Vai trò |
|---|---|---|---|---|---|---|
| S0 | Tệp prompt *Claude Discrete Mathematics Open Book Toolkit Prompt* (.md; 2 bản tải lên giống hệt nhau, 33 980 byte) | Project Specification | — | Kiến trúc sản phẩm, quy chuẩn, tiêu chí nghiệm thu | Tốt | **Specification** — không phải nguồn kiến thức |
| S1 | `01.pdf` — "CẤU TRÚC RỜI RẠC", Phạm Thế Bảo (SGU), Chương I | Slide bài giảng (PowerPoint, xuất PDF) | 100 | Mệnh đề, dạng mệnh đề, luật logic, quy tắc suy diễn, vị từ–lượng từ, tập hợp, ánh xạ, quy nạp | Tốt; **dấu gạch trên (phủ định/bù) mất khi trích văn bản** → đã đối chiếu bằng ảnh các trang 21, 52–56, 69–70, 80 | Nguồn kiến thức chính |
| S2 | `02.pdf` — Chương II: Phép đếm | Slide | 67 | Nguyên lý cộng, nhân, Dirichlet, bù trừ; hoán vị, chỉnh hợp, tổ hợp; hoán vị lặp, tổ hợp lặp; hệ thức đệ qui tuyến tính | Tốt; trang 57–59 (ví dụ b) **chỉ có ảnh** → đã đọc bằng ảnh; trang 51–66 dùng font VNI (mã hóa lỗi khi trích) → đọc bằng ảnh khi cần | Nguồn kiến thức chính |
| S3 | `03.pdf` — Chương 3: Quan hệ | Slide | 56 | Định nghĩa & tính chất quan hệ, ma trận biểu diễn, quan hệ tương đương, đồng dư, lớp tương đương, quan hệ thứ tự, thứ tự từ điển, Hasse, tối đại/tối tiểu, chặn trên/dưới, sup/inf, sắp xếp topo | Tốt; ký hiệu "≼" bị mất (hiển thị trống); trang 30 có ảnh lỗi "This image cannot currently be displayed" | Nguồn kiến thức chính |
| S4 | `04.pdf` — Chương IV: Đại số Bool | Slide | 79 | Đại số Bool, hàm Bool, dạng nối rời chính tắc, công thức đa thức tối tiểu, biểu đồ Karnaugh (3–4 biến), tế bào lớn, thuật toán phủ, cổng logic, thiết kế mạch | **Kém khi trích văn bản** (mất toàn bộ dấu bù; bản đồ Karnaugh là hình) → toàn bộ ví dụ đã đọc lại bằng ảnh 90–200 dpi | Nguồn kiến thức chính |
| S5 | `05.pdf` — Chương 5: Đồ thị | Slide | 86 | Đồ thị vô/có hướng, đơn/đa/giả đồ thị, bậc, định lý bắt tay, ma trận kề, đẳng cấu, đường đi–chu trình–liên thông, đỉnh khớp, cầu, Euler (điều kiện, Fleury), đường đi ngắn nhất (Dijkstra, Ford–Bellman) | Văn bản tốt; **hình đồ thị chỉ có trong ảnh** → đã đọc bằng ảnh các trang 20–35, 42, 51, 60, 71, 75, 84, 86 | Nguồn kiến thức chính |

## Phân loại nguồn

- **Nguồn chính thức (theo thứ tự ưu tiên của S0 §5.3):** chưa có đề cương/phạm vi thi (mức 1), chưa có giáo trình (mức 2). Nguồn cao nhất hiện có là **slide giảng dạy S1–S5 (mức 3)**.
- **Tài liệu tham khảo được slide nhắc tới (S1-p3) nhưng KHÔNG được cung cấp:** Nguyễn Duy Nhất – Nguyễn Văn Phong – Đinh Ngọc Thanh, *Toán rời rạc*; Trần Ngọc Hội, *Toán rời rạc*; Nguyễn Hữu Anh, *Toán rời rạc* (NXB Giáo dục); Rosen, *Discrete Mathematics and Its Applications*, 6th ed., 2007.
- **Trùng lặp:** chỉ S0 (2 bản giống hệt). S1–S5 không trùng nhau.
- **Thông tin đánh giá (S1-p4):** Quá trình 30%, cuối kỳ 70%, điểm thưởng 5–10%. Không có thông tin hình thức thi (open-book được giả định từ S0).

## Trang chỉ có ảnh / khó trích (đã xử lý bằng đọc ảnh)

S1: 21, 52–56, 73, 76, 84. S2: 26–27, 40, 57–59. S3: 2, 4–5, 16–20, 29, 39, 45. S4: 9, 19, 22–37, 42–49, 53–65, 72–78. S5: 4, 6, 8, 13, 15–16, 20–35, 37, 39, 42–47, 51, 54, 60–86 (hình trong bảng).

## Công cụ đã dùng để đọc nguồn

`pdftotext` (văn bản), `pdftoppm` (ảnh 60–200 dpi) và đọc ảnh trực tiếp. Mọi kết quả số/logic trong slide đã được kiểm tra lại bằng `10_Verification/verify_source_claims.py` (42/42 đạt).
