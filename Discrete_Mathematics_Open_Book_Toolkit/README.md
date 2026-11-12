# Discrete Mathematics Open-Book Toolkit

Bộ công cụ tra cứu & giải bài **Cấu trúc rời rạc** (theo 5 chương slide của Phạm Thế Bảo) cho kỳ thi open-book.

- **Bản dùng trong phòng thi:** `09_Publication/Discrete_Mathematics_Open_Book_Toolkit.pdf` (A4, in 2 mặt, 70 trang).
- **Trạng thái & giới hạn:** `00_Project_Control/00_Project_Status.md`, `00_Project_Control/00_Gap_And_Conflict_Report.md`.

## Cấu trúc

| Tệp / thư mục | Nội dung |
|---|---|
| `00_Project_Control/` | Kiểm kê nguồn, khoảng trống & mâu thuẫn, trạng thái dự án |
| `00_Front_Matter.md` | Cách dùng, hệ thống mã, nhãn |
| `01_Curriculum_Scope.md`, `01_Knowledge_Map.md` | Phạm vi, bản đồ kiến thức |
| `02_Problem_Taxonomy.md`, `02_Identifier_Registry.csv` | 42 dạng bài; registry mã (sinh tự động) |
| `03_Keyword_Index.md`, `03_Chapter_Map.md`, `03_Method_Index.md` | Chỉ mục tra cứu (keyword & method index sinh tự động) |
| `04_Formula_Handbook.md`, `04_Formula_Registry.csv` | 40 công thức/định lý |
| `05_Method_Library.md` | 27 phương pháp |
| `06_Example_Bank/`, `06_Example_Catalog.md` | 83 ví dụ có lời giải + catalog |
| `07_Common_Traps.md` | 31 bẫy/lỗi |
| `08_Quick_Reference.md` | Tra cứu nhanh |
| `09_Publication/` | `header.tex`, `build.py`, `.tex`, `.pdf` |
| `10_Verification/` | Script kiểm chứng toán học & kiểm toán mã |
| `Discrete_Mathematics_Source_References.txt` | Danh mục nguồn |

## Build & kiểm tra

Yêu cầu: Python 3 (`sympy`, `networkx`), `pandoc` ≥ 3, TeX Live với `xelatex` (+ `titlesec`, `fancyhdr`, `newunicodechar`), font Noto Serif / Noto Sans / DejaVu Sans Mono.

```bash
python3 10_Verification/verify_source_claims.py   # kiểm các kết quả trong slide (42 kiểm tra)
python3 10_Verification/verify_examples.py        # kiểm mọi đáp số của ví dụ & biến thể (101 kiểm tra)
python3 10_Verification/audit_ids.py              # mã trùng, liên kết gãy, cấu trúc A–L của ví dụ
python3 09_Publication/build.py                   # sinh chỉ mục -> .tex -> .pdf (XeLaTeX 3 lượt)
```

Sửa nội dung: chỉ sửa các tệp `.md`; không sửa tay `02_Identifier_Registry.csv`, `04_Formula_Registry.csv`, `03_Keyword_Index.md`, `03_Method_Index.md`, `06_Example_Catalog.md` (được sinh lại khi build). Danh sách từ khóa nằm trong `10_Verification/gen_indexes.py`.
