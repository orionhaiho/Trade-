# 01 — Curriculum Scope (Phạm vi môn học)

**Học phần:** Cấu trúc rời rạc — giảng viên Phạm Thế Bảo (SGU) — theo slide S1–S5.
**Căn cứ phạm vi:** S1-p2 ("Nội dung: gồm 5 phần: Cơ sở logic, Phép đếm, Quan hệ, Hàm Bool, Đồ thị") **[SOURCE-VERIFIED]**.
**Phạm vi thi:** chưa có đề cương thi → giả định **phạm vi thi = toàn bộ nội dung 5 chương slide** **[INFERRED]** (xem GAP-01).

| Chương (theo nguồn) | Mục trong nguồn | Mã chủ đề | Trong phạm vi toolkit | Căn cứ |
|---|---|---|---|---|
| I. Cơ sở logic | Mệnh đề; Dạng mệnh đề; Qui tắc suy diễn | `LOG` | Có | S1-p5–56 |
| | Vị từ, lượng từ | `QNT` | Có | S1-p58–72 |
| | Tập hợp | `SET` | Có | S1-p73–82 |
| | Ánh xạ | `FUN` | Có | S1-p83–96 |
| | Qui nạp toán học | `IND` | Có | S1-p97–100 |
| II. Phép đếm | Các nguyên lý; Giải tích tổ hợp; Hoán vị lặp, tổ hợp lặp | `CNT` | Có | S2-p3–25 |
| | Hệ thức đệ qui | `REC` | Có (chỉ nghiệm thực của PTĐT, cấp ≤ 2) | S2-p26–67 |
| III. Quan hệ | Định nghĩa, tính chất, biểu diễn, tương đương, đồng dư | `REL` | Có | S3-p4–27 |
| | Quan hệ thứ tự, thứ tự từ điển, Hasse, tối đại/tối tiểu, chặn, topo | `POS` | Có | S3-p28–56 |
| IV. Đại số Bool | Đại số Bool, hàm Bool, Karnaugh, mạch logic | `BOO` | Có (không gồm Quine–McCluskey) | S4-p2–78 |
| V. Đồ thị | Khái niệm, bậc, ma trận kề, đẳng cấu, đường đi–liên thông, Euler, đường đi ngắn nhất | `GRA` | Có (Dijkstra, Ford–Bellman; không gồm Floyd) | S5-p2–86 |

## Ngoài phạm vi (không biên soạn — Quy tắc 14)

- Nghiệm phức của phương trình đặc trưng; hệ thức đệ qui cấp ≥ 3 (slide chỉ có công thức cho k = 1, 2 — S2-p41–46).
- Quine–McCluskey (S4-p79 chỉ đưa link).
- Thuật toán Floyd, vét cạn (S5-p55 chỉ liệt kê tên).
- Cây, đồ thị Hamilton, tô màu, đồ thị phẳng, duyệt BFS/DFS (không có trong slide).

## Quy ước ký hiệu chung (bám nguồn)

| Khái niệm | Ký hiệu nguồn | Ký hiệu trong toolkit | Ghi chú |
|---|---|---|---|
| Phủ định / bù | $\neg p$ hoặc $\bar p$ (S1-p10) | $\neg p$ trong logic mệnh đề; $\bar x$ trong đại số Bool & tập bù | Hai ký hiệu tương đương |
| Chân trị | 1/0 (Đ/S, T/F) | 1/0 | S1-p7 |
| Tương đương logic | $\Leftrightarrow$ hoặc $\equiv$ | $\Leftrightarrow$ | S1-p23 |
| Hệ quả logic | $\Rightarrow$ | $\Rightarrow$ | S1-p24 |
| Số tự nhiên | $\mathbb N=\{0,1,2,\dots\}$ | như nguồn | S1-p58 |
| Chỉnh hợp / tổ hợp / tổ hợp lặp | $A_n^k$, $C_n^k$, $K_n^k$ | như nguồn | S2-p13, 15, 19 |
| Thứ tự | (ký hiệu bị mất trong PDF) | $\preceq$ | CON-06 |
| Hội / tuyển Bool | $\wedge$ (viết gọn $xy$), $\vee$ | như nguồn | S4-p14–16 |
| Bậc vào / ra | $\deg^-(v)$, $\deg^+(v)$ | như nguồn | S5-p22 |
