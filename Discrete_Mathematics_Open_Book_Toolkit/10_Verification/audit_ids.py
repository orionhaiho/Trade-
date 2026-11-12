"""Kiểm toán mã định danh & liên kết (spec §8.3) và cấu trúc ví dụ (spec §6.1).
Chạy từ thư mục gốc toolkit: python3 10_Verification/audit_ids.py"""
import re, glob, os, sys, collections
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
FILES = ['00_Front_Matter.md', '02_Problem_Taxonomy.md', '03_Keyword_Index.md', '03_Chapter_Map.md', '03_Method_Index.md',
         '04_Formula_Handbook.md', '05_Method_Library.md', '06_Example_Catalog.md', '07_Common_Traps.md', '08_Quick_Reference.md'] + sorted(glob.glob('06_Example_Bank/*.md'))
anchors = collections.Counter(); refs = collections.defaultdict(set); text = {}
for f in FILES:
    s = open(f, encoding='utf-8').read(); text[f] = s
    for a in re.findall(r'\{#([A-Za-z0-9-]+)\}', s): anchors[a] += 1
    for r in re.findall(r'\]\(#([A-Za-z0-9-]+)\)', s) + re.findall(r'\\pageref\{([A-Za-z0-9-]+)\}', s): refs[r].add(f)
problems = []
dup = [a for a, c in anchors.items() if c > 1]
if dup: problems.append(f'Mã trùng: {dup}')
broken = {r: sorted(fs) for r, fs in refs.items() if r not in anchors}
if broken: problems.append(f'Liên kết gãy: {broken}')
types = sorted(a for a in anchors if re.fullmatch(r'[A-Z]{3}-\d\d', a))
exs = sorted(a for a in anchors if re.fullmatch(r'[A-Z]{3}-\d\d-E\d\d', a))
forms = sorted(a for a in anchors if a.startswith('F-')); meths = sorted(a for a in anchors if a.startswith('M-')); traps = sorted(a for a in anchors if a.startswith('T-'))
# mọi ví dụ thuộc một dạng bài tồn tại; mọi dạng bài có ví dụ, có F- và M- (hoặc ghi rõ kiến thức)
for e in exs:
    if e[:6] not in types: problems.append(f'Ví dụ {e} không có dạng bài {e[:6]}')
tax = text['02_Problem_Taxonomy.md']
for t in types:
    sec = re.search(rf'### {t} .*?(?=\n### |\n## |\Z)', tax, re.S).group(0)
    if not any(e.startswith(t + '-E') for e in exs): problems.append(f'Dạng {t} chưa có ví dụ')
    if 'F-' not in sec and 'định nghĩa S' not in sec and 'đối chiếu định nghĩa' not in sec: problems.append(f'Dạng {t} thiếu liên kết công thức/định nghĩa')
    for e in re.findall(r'\(#([A-Z]{3}-\d\d-E\d\d)\)', sec):
        if not e.startswith(t): problems.append(f'Dạng {t} dẫn ví dụ khác dạng: {e}')
    listed = set(re.findall(r'\(#(' + t + r'-E\d\d)\)', sec)); rng = re.findall(r'\(#(' + t + r'-E\d\d)\) … \[', sec)
    missing = [e for e in exs if e.startswith(t + '-E') and e not in listed]
    if missing and not rng: problems.append(f'Taxonomy {t} không liệt kê ví dụ {missing}')
# không có F-/M-/T- nào "mồ côi" (không được tham chiếu)
for a in forms + meths + traps:
    if a not in refs: problems.append(f'{a} chưa được tham chiếu ở đâu')
# cấu trúc ví dụ A–L
REQ = ['Đề', 'Nhận diện', 'Kiến thức', 'Phương pháp', 'Lời giải', 'Kết luận', 'Kiểm tra', 'Biến thể', 'Lỗi thường gặp', 'Liên kết']
for f in sorted(glob.glob('06_Example_Bank/*.md')):
    for m in re.finditer(r'### ([A-Z]{3}-\d\d-E\d\d) .*?(?=\n### |\Z)', text[f], re.S):
        body = m.group(0)
        if not re.search(r'\*\*D[123](–D[123])? · V[0-4]', body): problems.append(f'{m.group(1)}: thiếu nhãn D/V')
        if not re.search(r'\[SV\]|AI-GENERATED PRACTICE', body.split('\n')[1] if '\n' in body else ''): problems.append(f'{m.group(1)}: thiếu nhãn nguồn đề')
        for k in REQ:
            if not re.search(r'\*\*[^*]*' + k, body): problems.append(f'{m.group(1)}: thiếu mục "{k}"')
print(f'Anchors: {len(anchors)} | dạng bài {len(types)} | ví dụ {len(exs)} | công thức {len(forms)} | phương pháp {len(meths)} | bẫy {len(traps)} | tham chiếu khác nhau {len(refs)}')
print('\n'.join(problems) if problems else 'KHÔNG CÓ LỖI: mã duy nhất, mọi liên kết trỏ tới mục tồn tại, mọi ví dụ đủ mục A–L.')
sys.exit(1 if problems else 0)
