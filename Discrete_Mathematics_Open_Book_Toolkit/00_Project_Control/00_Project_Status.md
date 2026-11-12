# 00 — Project Status

**Trạng thái tổng: `READY FOR REVIEW`** (nội dung theo slide đã hoàn chỉnh và kiểm chứng; phạm vi thi và tần suất dạng bài còn **chờ** đề cương/đề thi — GAP-01, GAP-02).

| Hạng mục | Trạng thái | Nguồn đầu vào | Kiểm tra còn thiếu | Ghi chú |
|---|---|---|---|---|
| 00 Source Inventory, Gap & Conflict | COMPLETE | S0–S5 | — | 13 lỗi nguồn (ERR), 6 mâu thuẫn quy ước (CON), 10 khoảng trống (GAP) |
| 01 Curriculum Scope, Knowledge Map | READY FOR REVIEW | S1–S5 | Xác nhận phạm vi thi (GAP-01) | Phạm vi thi đang là **giả định** |
| 02 Taxonomy (42 dạng) + Identifier Registry | COMPLETE | S1–S5 | — | Registry sinh tự động từ heading |
| 03 Keyword / Chapter / Method Index | COMPLETE | 02, 04, 05 | Thử nghiệm tra cứu thực tế 15–30 s | 64 từ khóa, có cột "Phân biệt" |
| 04 Formula Handbook (40 mục) + Registry | COMPLETE | S1–S5 | — | Mỗi mục có điều kiện, nguồn, trạng thái |
| 05 Method Library (27 phương pháp) | COMPLETE | S1–S5 | — | Chỉ phương pháp có trong slide |
| 06 Example Bank (83 ví dụ) + Catalog | COMPLETE | S1–S5 | — | 66 đề từ slide, 17 [AI-GENERATED PRACTICE]; đủ mục A–L |
| 07 Common Traps (31 bẫy) | COMPLETE | S1–S5 + phản ví dụ | — | |
| 08 Quick Reference | COMPLETE | 02–07 | — | |
| 09 Publication: `.tex` + `.pdf` (A4, 2 mặt) | COMPLETE | Markdown | Đọc soát toàn bộ 70 trang bằng mắt (đã soát mẫu ~10 trang) | 0 tham chiếu gãy, 0 thiếu glyph, 0 tràn lề > 10 pt |
| 09 Publication: `.docx` | NOT STARTED (có chủ đích) | — | — | Môi trường không có công cụ hiển thị DOCX để kiểm tra công thức; `\pageref` không chuyển sang DOCX ⇒ không tạo để tránh bản kém chất lượng |
| 10 Verification | COMPLETE | — | — | `verify_source_claims.py` 42/42; `verify_examples.py` 101/101; `audit_ids.py` 0 lỗi |

## Acceptance checklist (spec §8.6)

- [x] Phạm vi môn học được xác định từ nguồn (S1-p2) — *phạm vi **thi** là giả định*.
- [x] Mục lục từ khóa đặt ở đầu và ánh xạ đúng (mọi mã đích tồn tại — audit).
- [x] Bản đồ chương phản ánh tài liệu thực tế.
- [x] Sổ tay công thức có điều kiện áp dụng và nguồn.
- [x] Mỗi dạng bài có phương pháp giải rõ ràng.
- [x] Ví dụ có lời giải đầy đủ và được kiểm tra (máy tính kiểm 101 khẳng định).
- [x] Có biến thể thực sự hữu ích (mỗi ví dụ ≥ 1, có đáp số đã kiểm).
- [x] Có danh mục lỗi/bẫy.
- [x] Hệ thống mã không trùng và ổn định.
- [x] Liên kết nội bộ không bị gãy.
- [x] LaTeX không có lỗi chưa xử lý (còn 10 overfull < 10 pt, không mất nội dung).
- [~] PDF đã được kiểm tra thực tế — đã biên dịch, quét log, trích văn bản để dò lỗi định dạng và xem trực quan khoảng 10 trang đại diện; **chưa** soát bằng mắt từng trang.
- [x] Các giới hạn và nội dung chưa xác minh được công khai (Gap & Conflict Report, nhãn [INFERRED]/[CONFLICT]).

## Việc tiếp theo (khi có thêm nguồn)

1. Nhận đề cương thi / đề thi cũ → cập nhật phạm vi, thêm thống kê tần suất, bổ sung ví dụ từ đề thật (giữ nguyên mã cũ, cấp mã mới tiếp theo).
2. Xác nhận CON-01 (khuyên trong ma trận kề), GAP-05/06/07 (nghiệm phức, Quine–McCluskey, Floyd).
3. In thử 2 mặt, đo thời gian tra cứu thực tế với 5–10 đề mẫu.
