"""Sinh các tệp chỉ mục/registry từ nội dung Markdown (nguồn sự thật duy nhất = các heading có {#ID}).
Tạo: 02_Identifier_Registry.csv, 04_Formula_Registry.csv, 06_Example_Catalog.md, 03_Keyword_Index.md, 03_Method_Index.md.
Chạy từ thư mục gốc toolkit: python3 10_Verification/gen_indexes.py"""
import re, glob, csv, os, unicodedata
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
CONTENT = ['02_Problem_Taxonomy.md', '04_Formula_Handbook.md', '05_Method_Library.md'] + sorted(glob.glob('06_Example_Bank/*.md')) + ['07_Common_Traps.md']
H = re.compile(r'^(#+) (.*?) \{#([A-Za-z0-9-]+)\}\s*$')
items = []   # (id, title, file, extra-lines)
for f in CONTENT:
    lines = open(f, encoding='utf-8').read().split('\n')
    for i, l in enumerate(lines):
        m = H.match(l)
        if m:
            title = re.sub(r'^[A-Z]+-[0-9A-Z-]+ · ', '', m.group(2))
            items.append((m.group(3), title, f, lines[i + 1] if i + 1 < len(lines) else ''))
ids = [i[0] for i in items]
dups = {x for x in ids if ids.count(x) > 1}
assert not dups, f'Mã trùng: {dups}'
kind = lambda x: ('Ví dụ' if re.match(r'^[A-Z]{3}-\d\d-E\d\d$', x) else 'Dạng bài' if re.match(r'^[A-Z]{3}-\d\d$', x)
                  else 'Công thức/Định lý' if x.startswith('F-') else 'Phương pháp' if x.startswith('M-') else 'Bẫy/Lỗi' if x.startswith('T-') else 'Mục')

with open('02_Identifier_Registry.csv', 'w', newline='', encoding='utf-8') as fh:
    w = csv.writer(fh); w.writerow(['id', 'loai', 'ten', 'tep', 'nhan_nguon'])
    for i, t, f, extra in items:
        if kind(i) == 'Mục': continue
        tag = 'AI-GENERATED PRACTICE' if 'AI-GENERATED' in extra else ('SOURCE' if '[SV]' in extra else '')
        w.writerow([i, kind(i), t, f, tag])

with open('04_Formula_Registry.csv', 'w', newline='', encoding='utf-8') as fh:
    w = csv.writer(fh); w.writerow(['id', 'ten', 'tep'])
    for i, t, f, _ in items:
        if i.startswith('F-'): w.writerow([i, t, f])

# ---------- Catalog ví dụ ----------
ex = [(i, t, f, e) for i, t, f, e in items if kind(i) == 'Ví dụ']
out = ['# Danh mục ví dụ (Example Catalog) {#catalog}', '',
       f'Tổng số: **{len(ex)} ví dụ**; trong đó {sum("AI-GENERATED" in e for *_, e in ex)} ví dụ **[AI-GENERATED PRACTICE]**, còn lại đề lấy từ slide. Cột "Trang" là số trang trong bản PDF.', '',
       '| Mã | Tên | Độ khó · Biến thể · Nguồn đề | Trang |', '|--------|--------------------|-------------|---|']
for i, t, f, e in ex:
    meta = re.sub(r'\*\*', '', e).replace('|', '/').strip()
    meta = re.sub(r' · Lời giải.*$', '', meta)
    out.append(f'| [{i}](#{i}) | {t} | {meta} | \\pageref{{{i}}} |')
open('06_Example_Catalog.md', 'w', encoding='utf-8').write('\n'.join(out) + '\n')

# ---------- Keyword index ----------
KW = [
 ("mệnh đề? sơ cấp / phức hợp", "danh sách câu nói", "LOG-01", ""),
 ("lập bảng chân trị (dạng mệnh đề)", "cho $E(p,q,\\dots)$", "LOG-02", "hàm Bool từ mô tả → BOO-01"),
 ("hằng đúng, hằng sai, mâu thuẫn, chân lý", "", "LOG-02", ""),
 ("điều kiện cần, điều kiện đủ, nếu… thì…", "đọc $p\\to q$", "LOG-02", "xem F-LOG-01"),
 ("chứng minh tương đương logic, $\\Leftrightarrow$", "hai dạng mệnh đề", "LOG-03", ""),
 ("rút gọn / đơn giản dạng mệnh đề", "", "LOG-03", ""),
 ("hệ quả logic $\\Rightarrow$", "", "LOG-03", ""),
 ("chứng minh suy luận, $\\therefore$, quy tắc suy diễn", "tiền đề / vạch ngang / kết luận", "LOG-04", "nghi sai → LOG-05"),
 ("phản chứng, quy tắc mâu thuẫn", "kết luận dạng $a\\to b$", "LOG-04", ""),
 ("suy luận có đúng không, phản ví dụ", "", "LOG-05", ""),
 ("lời văn: \"nếu… thì…, biết rằng…, suy ra…\"", "đặt biến mệnh đề", "LOG-05", "nếu chắc đúng → LOG-04"),
 ("chứng minh theo trường hợp", "", "LOG-04", "chia hết theo $n\\bmod k$ → IND-01"),
 ("$\\forall$, $\\exists$, với mọi, tồn tại — đúng hay sai", "vị từ trên tập số", "QNT-01", ""),
 ("thứ tự lượng từ $\\forall x\\exists y$ / $\\exists y\\forall x$", "", "QNT-01", ""),
 ("phủ định mệnh đề lượng từ, $\\varepsilon$–$\\delta$", "", "QNT-02", ""),
 ("hợp, giao, hiệu, bù, De Morgan tập hợp", "", "SET-01", ""),
 ("chứng minh đẳng thức tập hợp", "$A\\setminus(B\\cup C)=\\dots$", "SET-01", ""),
 ("$P(X)$, tập các tập con, lực lượng", "", "SET-02", ""),
 ("tích Đề-các $A\\times B$", "", "SET-02", ""),
 ("có phải ánh xạ; ảnh $f(A)$, ảnh ngược $f^{-1}(B)$", "", "FUN-01", ""),
 ("đơn ánh, toàn ánh, song ánh", "chú ý miền & đích", "FUN-02", ""),
 ("ánh xạ ngược, khả nghịch, $f^{-1}$", "chỉ khi song ánh", "FUN-02", "ảnh ngược của tập → FUN-01"),
 ("tích ánh xạ, hàm hợp $g\\circ f$", "", "FUN-03", ""),
 ("quy nạp, $P(n)$, với mọi $n\\ge n_0$", "tổng, bất đẳng thức, chia hết", "IND-01", ""),
 ("bao nhiêu số … chữ số (khác nhau), chẵn, chia hết cho 5", "tập chữ số có 0", "CNT-01", ""),
 ("nguyên lý cộng / nhân, có bao nhiêu cách", "các bước hoặc các phương án", "CNT-01", "chọn nhóm → CNT-04"),
 ("chuồng bồ câu, Dirichlet, luôn tồn tại hai…", "chứng minh tồn tại", "CNT-02", ""),
 ("hoặc / ít nhất một trong / không chia hết cho", "đếm hợp các tập", "CNT-03", ""),
 ("hoán vị, chỉnh hợp, tổ hợp, chọn ủy ban, xếp hàng", "thứ tự? lặp?", "CNT-04", "có vật giống nhau → CNT-05"),
 ("sắp xếp chữ cái của một từ, vật giống nhau", "", "CNT-05", ""),
 ("tổ hợp lặp, chọn $k$ vật từ $n$ loại", "", "CNT-06", ""),
 ("số nghiệm nguyên không âm $x_1+\\dots+x_n=k$", "ràng buộc $\\ge,\\le,>$", "CNT-06", ""),
 ("chia $k$ vật giống nhau cho $n$ người / hộp", "", "CNT-06", "vật khác nhau → $n^k$ (CNT-04)"),
 ("tìm hệ thức đệ qui, cầu thang, tháp Hà Nội, chuỗi bit", "đặt $x_n$", "REC-01", ""),
 ("giải hệ thức đệ qui, vế phải = 0", "thuần nhất", "REC-02", ""),
 ("phương trình đặc trưng, nghiệm kép", "", "REC-02", "có vế phải → REC-03"),
 ("vế phải đa thức / $\\beta^n P(n)$, nghiệm riêng", "không thuần nhất", "REC-03", ""),
 ("vế phải là tổng nhiều dạng", "nhiều $\\beta$ khác nhau", "REC-04", ""),
 ("liệt kê quan hệ, ma trận biểu diễn $M_R$", "", "REL-01", "ma trận kề đồ thị → GRA-02"),
 ("phản xạ, đối xứng, phản xứng, bắc cầu", "", "REL-02", ""),
 ("quan hệ tương đương, lớp tương đương $[a]$", "", "REL-03", ""),
 ("đồng dư, modulo, $\\mathbb Z_m$, phân hoạch", "", "REL-03", ""),
 ("quan hệ thứ tự, poset, thứ tự toàn phần, so sánh được", "", "POS-01", ""),
 ("thứ tự từ điển, so sánh chuỗi", "", "POS-02", ""),
 ("biểu đồ Hasse", "", "POS-03", ""),
 ("tối đại, tối tiểu, lớn nhất, nhỏ nhất", "", "POS-03", "của tập con $A$ → POS-04"),
 ("chặn trên, chặn dưới, sup, inf, $a\\vee b$, $a\\wedge b$", "", "POS-04", ""),
 ("sắp xếp topo, thứ tự thực hiện công việc", "", "POS-05", ""),
 ("hàm Bool, bảng chân trị, bỏ phiếu", "mô tả bằng lời", "BOO-01", ""),
 ("dạng nối rời chính tắc, từ tối tiểu", "", "BOO-01", ""),
 ("vẽ biểu đồ Karnaugh; tế bào là kar của đơn thức nào", "", "BOO-02", ""),
 ("công thức đa thức tối tiểu, tối thiểu hóa hàm Bool, tế bào lớn", "", "BOO-03", ""),
 ("cổng AND, OR, NOT, NAND, NOR; vẽ mạch, viết biểu thức của sơ đồ", "", "BOO-04", ""),
 ("thiết kế mạch cầu dao / công tắc / đèn", "", "BOO-04", ""),
 ("bậc, bậc vào, bậc ra, số cạnh, định lý bắt tay", "", "GRA-01", ""),
 ("đơn đồ thị, đa đồ thị, giả đồ thị, khuyên", "", "GRA-01", ""),
 ("ma trận kề", "", "GRA-02", "ma trận trọng số → GRA-06"),
 ("đẳng cấu", "", "GRA-03", ""),
 ("đường đi đơn/sơ cấp, chu trình sơ cấp, liên thông", "", "GRA-04", ""),
 ("đỉnh khớp, cầu", "", "GRA-04", "Fleury → GRA-05"),
 ("Euler, đi qua mỗi cạnh đúng một lần, vẽ một nét, Königsberg", "", "GRA-05", ""),
 ("Fleury", "", "GRA-05", ""),
 ("đường đi ngắn nhất, khoảng cách, Dijkstra", "trọng số dương", "GRA-06", "có trọng số âm → GRA-07"),
 ("Ford–Bellman, trọng số âm, mạch âm", "", "GRA-07", ""),
]
strip = lambda s: ''.join(c for c in unicodedata.normalize('NFD', re.sub(r'\$[^$]*\$', '', s).replace('đ', 'd').replace('Đ', 'D')) if unicodedata.category(c) != 'Mn').lower().strip(' "(')
for _, _, c, _ in KW: assert c in ids, c
KW.sort(key=lambda r: strip(r[0]))
out = ['# Mục lục từ khóa (Keyword Index) {#keyword-index}', '',
       'Tra theo **từ khóa trong đề** → mã dạng bài → trang. Cột "Phân biệt" giúp tránh nhầm khi một từ khóa có thể dẫn tới dạng khác.', '',
       '| Từ khóa đề bài | Dấu hiệu nhận diện | Mã dạng bài | Phân biệt | Trang |', '|--------------------|------------|-------|--------------|----|']
for k, s, c, d in KW:
    out.append(f'| {k} | {s} | [{c}](#{c}) | {d} | \\pageref{{{c}}} |')
open('03_Keyword_Index.md', 'w', encoding='utf-8').write('\n'.join(out) + '\n')

# ---------- Method index ----------
meth = [(i, t) for i, t, f, _ in items if i.startswith('M-')]
txt = open('05_Method_Library.md', encoding='utf-8').read()
out = ['# Mục lục theo phương pháp giải (Method Index) {#method-index}', '',
       '| Mã | Phương pháp | Dùng cho dạng bài | Ví dụ minh họa | Trang |', '|----|--------------|----------|------------|---|']
tax = open('02_Problem_Taxonomy.md', encoding='utf-8').read()
for i, t in meth:
    # dạng bài dùng phương pháp: các mục taxonomy có tham chiếu (#M-xx)
    secs = re.split(r'\n(?=### )', tax)
    users = [re.match(r'### ([A-Z]{3}-\d\d)', s).group(1) for s in secs if s.startswith('### ') and f'(#{i})' in s]
    sec = re.search(rf'### {i} ·.*?(?=\n### |\Z)', txt, re.S).group(0)
    exs = sorted(set(re.findall(r'\(#([A-Z]{3}-\d\d-E\d\d)\)', sec)))
    out.append(f'| [{i}](#{i}) | {t} | ' + ', '.join(f'[{u}](#{u})' for u in users) + ' | ' + ', '.join(f'[{e}](#{e})' for e in exs) + f' | \\pageref{{{i}}} |')
open('03_Method_Index.md', 'w', encoding='utf-8').write('\n'.join(out) + '\n')
print('items:', len(items), '| ví dụ:', len(ex), '| từ khóa:', len(KW), '| phương pháp:', len(meth))
