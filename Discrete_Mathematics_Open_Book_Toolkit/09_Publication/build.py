"""Build: Markdown -> LaTeX (pandoc) -> PDF (XeLaTeX, 3 lượt cho \\pageref/mục lục).
Yêu cầu: pandoc >= 3, TeX Live (xelatex, titlesec, fancyhdr, newunicodechar), font Noto Serif/Noto Sans/DejaVu Sans Mono.
Chạy từ thư mục gốc toolkit:  python3 09_Publication/build.py"""
import os, subprocess, sys, re
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
subprocess.run([sys.executable, '10_Verification/gen_indexes.py'], check=True)
ORDER = ['00_Front_Matter.md', '03_Keyword_Index.md', '03_Chapter_Map.md', '03_Method_Index.md',
         '02_Problem_Taxonomy.md', '04_Formula_Handbook.md', '05_Method_Library.md', '06_Example_Catalog.md',
         '06_Example_Bank/06_1_Logic_Sets_Functions_Induction.md', '06_Example_Bank/06_2_Counting.md',
         '06_Example_Bank/06_3_Recurrences.md', '06_Example_Bank/06_4_Relations_Posets.md',
         '06_Example_Bank/06_5_Boolean.md', '06_Example_Bank/06_6_Graphs.md',
         '07_Common_Traps.md', '08_Quick_Reference.md',
         '00_Project_Control/00_Gap_And_Conflict_Report.md', '00_Project_Control/00_Source_Inventory.md']
parts = []
for f in ORDER:
    s = open(f, encoding='utf-8').read()
    if f.startswith('00_Project_Control'):   # phụ lục: hạ heading một bậc dưới chương "Phụ lục"
        s = re.sub(r'^# 00 — ', '# Phụ lục — ', s, count=1, flags=re.M)
    parts.append(s.strip())
meta = """---
title: "Discrete Mathematics Open-Book Toolkit"
subtitle: "Bộ công cụ tra cứu và giải bài Cấu trúc rời rạc (theo slide Phạm Thế Bảo, 5 chương)"
date: "Phiên bản 1.0 — 2026-11-12"
lang: vi
---

"""
os.makedirs('09_Publication', exist_ok=True)
combined = '09_Publication/_combined.md'
open(combined, 'w', encoding='utf-8').write(meta + '\n\n'.join(parts) + '\n')
tex = '09_Publication/Discrete_Mathematics_Open_Book_Toolkit.tex'
subprocess.run(['pandoc', combined, '-f', 'markdown+tex_math_single_backslash', '-o', tex, '--standalone',
                '--top-level-division=chapter', '--toc', '--toc-depth=1',
                '-V', 'documentclass=book', '-V', 'classoption=twoside,openany', '-V', 'fontsize=10pt',
                '-V', 'geometry:a4paper,inner=25mm,outer=17mm,top=20mm,bottom=20mm,headsep=6mm,footskip=9mm',
                '-V', 'colorlinks=true', '-V', 'linkcolor=idblue', '-V', 'urlcolor=idblue',
                '-H', '09_Publication/header.tex'], check=True)
os.chdir('09_Publication')
for i in range(3):
    r = subprocess.run(['xelatex', '-interaction=nonstopmode', '-halt-on-error', os.path.basename(tex)], capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stdout[-4000:]); sys.exit('XeLaTeX lỗi ở lượt %d' % (i + 1))
log = open('Discrete_Mathematics_Open_Book_Toolkit.log', encoding='utf-8', errors='replace').read()
und = sorted(set(re.findall(r"Reference `([^']+)' on page \d+ undefined", log)))
missing = sorted(set(re.findall(r'Missing character: There is no (.) ', log)))
overfull = len(re.findall(r'Overfull \\hbox \((\d+\.\d+)pt', log))
big = [float(x) for x in re.findall(r'Overfull \\hbox \((\d+\.\d+)pt', log) if float(x) > 10]
print('Tham chiếu chưa định nghĩa:', und or 'không có')
print('Ký tự thiếu glyph:', missing or 'không có')
print('Overfull hbox:', overfull, '| > 10pt:', len(big), sorted(big)[-5:])
print('Trang:', re.search(r'Output written on .*?\((\d+) pages', log).group(1))
