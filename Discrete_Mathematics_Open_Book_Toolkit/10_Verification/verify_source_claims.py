"""Kiểm tra độc lập (bằng tính toán) các kết quả số/logic xuất hiện trong slide nguồn S1–S5.
Chạy: python3 verify_source_claims.py   (cần sympy, networkx)
Mỗi dòng in ra: [OK]/[FAIL] <mã nguồn> <mô tả>."""
import itertools, math
from sympy import symbols, Function, rsolve, simplify, binomial, expand, Rational

R = []
def check(tag, desc, cond):
    R.append(cond); print(("[OK]  " if cond else "[FAIL]"), tag, desc)

imp = lambda a, b: (not a) or b
def valid(premises, concl, n):
    """Suy luận hợp lệ <=> mọi bộ giá trị làm đúng tất cả tiền đề cũng làm đúng kết luận."""
    for v in itertools.product([0, 1], repeat=n):
        if all(p(*v) for p in premises) and not concl(*v):
            return False, v
    return True, None

# ---------- S1 (Chương 1) ----------
# S1 tr.29-30: (¬p→r)∧(q→r) ⇔ (p→q)→r
ok = all(((imp(not p, r) and imp(q, r)) == imp(imp(p, q), r)) for p, q, r in itertools.product([0,1], repeat=3))
check("S1-p30", "(¬p→r)∧(q→r) ⇔ (p→q)→r", ok)
# S1 tr.46: p→r, ¬p→q, q→s ∴ ¬r→s
check("S1-p46", "p→r, ¬p→q, q→s ⊢ ¬r→s", valid([lambda p,q,r,s: imp(p,r), lambda p,q,r,s: imp(not p,q), lambda p,q,r,s: imp(q,s)], lambda p,q,r,s: imp(not r, s), 4)[0])
# S1 tr.49: ông Minh: ¬p→q, q∧r→s, t→r, p ∴ ¬s→¬t  -> KHÔNG hợp lệ, phản ví dụ p=1,q=0,r=1,s=0,t=1
v = valid([lambda p,q,r,s,t: imp(not p,q), lambda p,q,r,s,t: imp(q and r, s), lambda p,q,r,s,t: imp(t,r), lambda p,q,r,s,t: p], lambda p,q,r,s,t: imp(not s, not t), 5)
check("S1-p49", "Suy luận ông Minh KHÔNG hợp lệ (có phản ví dụ)", v[0] is False)
pv = (1,0,1,0,1)
check("S1-p49", "Phản ví dụ nguồn p=1,q=0,r=1,s=0,t=1 làm đúng tiền đề, sai kết luận",
      imp(not pv[0],pv[1]) and imp(pv[1] and pv[2], pv[3]) and imp(pv[4],pv[2]) and pv[0] and not imp(not pv[3], not pv[4]))
# S1 tr.50-51: p→(q→r), p∨s, t→q, ¬s ∴ ¬r→¬t   (đọc từ lời giải tr.51: dùng s̄ và kết luận r̄→t̄)
check("S1-p50", "p→(q→r), p∨s, t→q, ¬s ⊢ ¬r→¬t", valid([lambda p,q,r,s,t: imp(p, imp(q,r)), lambda p,q,r,s,t: p or s, lambda p,q,r,s,t: imp(t,q), lambda p,q,r,s,t: not s], lambda p,q,r,s,t: imp(not r, not t), 5)[0])
# S1 tr.52-54: p→q, ¬r∨s, p∨r ∴ ¬q→s
check("S1-p52", "p→q, ¬r∨s, p∨r ⊢ ¬q→s", valid([lambda p,q,r,s: imp(p,q), lambda p,q,r,s: (not r) or s, lambda p,q,r,s: p or r], lambda p,q,r,s: imp(not q, s), 4)[0])
# S1 tr.55-56: p, p→r, p→(q∨¬r), ¬q∨¬s ∴ s  -> KHÔNG hợp lệ (p=q=r=1,s=0)
v = valid([lambda p,q,r,s: p, lambda p,q,r,s: imp(p,r), lambda p,q,r,s: imp(p, q or not r), lambda p,q,r,s: (not q) or (not s)], lambda p,q,r,s: s, 4)
check("S1-p55", "p, p→r, p→(q∨¬r), ¬q∨¬s ⊬ s ; phản ví dụ " + str(v[1]), v[0] is False and v[1] == (1,1,1,0))
# S1 tr.21: B = p→(p∨q) hằng đúng ; C = p∧¬(p→q) không hằng đúng/không hằng sai
check("S1-p21", "p→(p∨q) là hằng đúng", all(imp(p, p or q) for p,q in itertools.product([0,1],repeat=2)))
# S1 tr.20: bảng (p∨q)→r
check("S1-p20", "(p∨q)→r có đúng 3 dòng sai (pqr=010,100,110)", [ (p,q,r) for p,q,r in itertools.product([0,1],repeat=3) if not imp(p or q, r)] == [(0,1,0),(1,0,0),(1,1,0)])
# S1 ánh xạ f(x)=x^2+1: các ảnh/ảnh ngược (kiểm tra bằng lưới)
check("S1-ánh xạ", "f(x)=x²+1: f([-1,3])=[1,10], f^{-1}([2,5])=[-2,-1]∪[1,2]",
      min(x*x+1 for x in [i/100 for i in range(-100,301)]) == 1 and abs(max(x*x+1 for x in [i/100 for i in range(-100,301)]) - 10) < 1e-9
      and all(((2 <= x*x+1 <= 5) == (-2 <= x <= -1 or 1 <= x <= 2)) for x in [i/100 for i in range(-400,401)]))
# S1 quy nạp: 1+3+...+(2n-1)=n^2 ; 2^n < n! với n>3 (n≥4)
check("S1-quy nạp", "Σ(2i-1)=n² (n≤200)", all(sum(2*i-1 for i in range(1,n+1)) == n*n for n in range(1,201)))
check("S1-quy nạp", "2^n < n! với 4≤n≤60 và sai tại n=3", all(2**n < math.factorial(n) for n in range(4,61)) and not 2**3 < math.factorial(3))
check("S1-p47", "3 | n³−4n với 0≤n≤300", all((n**3-4*n) % 3 == 0 for n in range(0,301)))

# ---------- S2 (Chương 2) ----------
X = [1,2,3,4,5,0]
cnt = sum(1 for a,b,c in itertools.permutations(X,3) if a != 0 and c % 2 == 0)
check("S2-p5", "Số có 3 chữ số khác nhau, chẵn, từ {0,...,5} = 52", cnt == 52)
check("S2-p17", "SUCCESS: 7!/(3!1!2!1!) = 420", len(set(itertools.permutations("SUCCESS"))) == 420)
cnt = sum(1 for x1 in range(21) for x2 in range(21) for x3 in range(21) if (x4 := 20-x1-x2-x3) >= 0 and x1 <= 3 and x2 >= 2 and x3 > 4)
check("S2-p23", "x1+..+x4=20, x1≤3, x2≥2, x3>4 : 340 nghiệm", cnt == 340 and binomial(16,13)-binomial(12,9) == 340)
cnt = sum(1 for a in range(13) for b in range(13) if (c := 12-a-b) >= 0 and a >= 4 and b >= 2 and 2 <= c <= 5)
check("S2-p25", "12 táo cho A,B,C (A≥4, B≥2, 2≤C≤5): 14 cách = C(6,2)−C(2,2) [nguồn không có đáp án]", cnt == 14 and binomial(6,2)-binomial(2,2) == 14)
check("S2-pigeon", "Tập con 6 phần tử của {1..9} luôn có 2 phần tử tổng 10",
      all(any(a+b == 10 for a,b in itertools.combinations(S,2)) for S in itertools.combinations(range(1,10),6)))

n = symbols('n', integer=True)
x = Function('x')
def seq_ok(rec, closed, start, stop=15):
    return all(simplify(rec(closed, k)) == 0 for k in range(start, stop))
# Tháp Hà Nội
check("S2-HN", "x_n=2x_{n-1}+1, x1=1 -> 2^n-1", all((2**k-1) == 2*(2**(k-1)-1)+1 for k in range(2,40)))
# ví dụ 2x_n -3x_{n-1}=0, x0=1 -> (3/2)^n
# ví dụ b) thuần nhất kép: 4x_{n+1}-12x_n+9x_{n-1}=0, x0=2,x1=4 -> nghiệm nguồn ghi (3+n)(3/2)^{n-1}
f = lambda k: (3+k)*Rational(3,2)**(k-1)
check("S2-p44", "4x_{n+1}-12x_n+9x_{n-1}=0, x0=2,x1=4 => x_n=(3+n)(3/2)^{n-1}", f(0)==2 and f(1)==4 and all(4*f(k+1)-12*f(k)+9*f(k-1)==0 for k in range(1,20)))
# a) 2x_n-3x_{n-1}+x_{n-2}=4n+1 -> nghiệm riêng n(2n-1)
g = lambda k: k*(2*k-1)
check("S2-p53a", "Nghiệm riêng n(2n−1) của 2x_n−3x_{n−1}+x_{n−2}=4n+1", all(2*g(k)-3*g(k-1)+g(k-2) == 4*k+1 for k in range(2,30)))
# b) x_{n+1}-6x_n+9x_{n-1}=(18n+12)3^n, x0=2,x1=0 -> (n^3+2n^2-5n+2)3^n
h = lambda k: (k**3+2*k**2-5*k+2)*3**k
check("S2-p57b", "x_n=(n³+2n²−5n+2)3ⁿ thỏa b) và x0=2,x1=0", h(0)==2 and h(1)==0 and all(h(k+1)-6*h(k)+9*h(k-1) == (18*k+12)*3**k for k in range(1,25)))
# c) 4x_{n+1}-12x_n+9x_{n-1}=(2n^2+29n+56)2^{n-1}, x0=1,x1=-2 -> (2-6n)(3/2)^n+(2n^2+n-1)2^n
c_ = lambda k: (2-6*k)*Rational(3,2)**k + (2*k*k+k-1)*2**k
check("S2-p60c", "x_n=(2−6n)(3/2)ⁿ+(2n²+n−1)2ⁿ thỏa c) và x0=1,x1=−2",
      c_(0)==1 and c_(1)==-2 and all(4*c_(k+1)-12*c_(k)+9*c_(k-1) == (2*k*k+29*k+56)*2**(k-1) for k in range(1,25)))
# d) x_n-4x_{n-1}+3x_{n-2}=20+(2-n)2^{n-2}+3·4^n -> riêng -10n+n2^n+4^{n+2}
d_ = lambda k: -10*k + k*2**k + 4**(k+2)
check("S2-p64d", "Nghiệm riêng −10n+n2ⁿ+4^{n+2} của d)", all(d_(k)-4*d_(k-1)+3*d_(k-2) == 20+(2-k)*Rational(2)**(k-2)+3*4**k for k in range(2,25)))

# ---------- S3 (Chương 3) ----------
A = [1,2,3,4]
def props(Rl, A):
    Rs = set(Rl)
    refl = all((a,a) in Rs for a in A)
    sym = all((b,a) in Rs for a,b in Rs)
    anti = all(not((b,a) in Rs and a != b) for a,b in Rs)
    trans = all((a,d) in Rs for a,b in Rs for c,d in Rs if b == c)
    return refl, sym, anti, trans
R1 = [(1,1),(1,2),(2,1),(2,2),(3,4),(4,1),(4,4)]
R2 = [(1,1),(1,2),(1,4),(2,2),(3,3),(4,1),(4,4)]
check("S3-p7", "R1 không phản xạ; R2 phản xạ", props(R1,A)[0] is False and props(R2,A)[0] is True)
check("S3-p9", "{(1,1),(1,2),(2,1)} đối xứng", props([(1,1),(1,2),(2,1)],A)[1])
check("S3-p11", "{(1,1),(1,2),(2,1),(2,2),(1,3),(2,3)} bắc cầu", props([(1,1),(1,2),(2,1),(2,2),(1,3),(2,3)],A)[3])
div = [(a,b) for a in A for b in A if b % a == 0]
check("S3-p6", "Quan hệ ước trên {1,2,3,4} có 8 cặp như nguồn", sorted(div) == sorted([(1,1),(1,2),(1,3),(1,4),(2,2),(2,4),(3,3),(4,4)]))
P = [2,4,5,10,12,20,25]
maxi = [a for a in P if not any(b != a and b % a == 0 for b in P)]
mini = [a for a in P if not any(b != a and a % b == 0 for b in P)]
check("S3-p48", "({2,4,5,10,12,20,25},|): tối đại 12,20,25; tối tiểu 2,5", maxi == [12,20,25] and mini == [2,5])

# ---------- S4 (Chương 4) ----------
def minterms(fn, nv=4):
    return {v for v in itertools.product([0,1], repeat=nv) if fn(*v)}
N = lambda a: 1-a
# Ví dụ 1: f = xyzt ∨ xȳ ∨ xz̄ ∨ yz ∨ xyz̄ ∨ xyt̄  (S4-p41–42, đọc từ ảnh) -> x ∨ yz
f1 = lambda x,y,z,t: (x&y&z&t)|(x&N(y))|(x&N(z))|(y&z)|(x&y&N(z))|(x&y&N(t))
check("S4-VD1", "Ví dụ 1: f tương đương x ∨ yz (10 ô)", minterms(f1) == minterms(lambda x,y,z,t: x|(y&z)) and len(minterms(f1)) == 10)
# Ví dụ 2: f = ȳzt ∨ ȳz̄t̄ ∨ yz̄t̄ ∨ xyzt ∨ x̄zt̄ -> z̄t̄ ∨ x̄t̄ ∨ xzt ∨ (x̄ȳz | ȳzt)
f2 = lambda x,y,z,t: (N(y)&z&t)|(N(y)&N(z)&N(t))|(y&N(z)&N(t))|(x&y&z&t)|(N(x)&z&N(t))
g2a = lambda x,y,z,t: (N(z)&N(t))|(N(x)&N(t))|(x&z&t)|(N(x)&N(y)&z)
g2b = lambda x,y,z,t: (N(z)&N(t))|(N(x)&N(t))|(x&z&t)|(N(y)&z&t)
check("S4-VD2", "Ví dụ 2: 9 ô; hai công thức tối tiểu z̄t̄∨x̄t̄∨xzt∨x̄ȳz và z̄t̄∨x̄t̄∨xzt∨ȳzt", len(minterms(f2)) == 9 and minterms(f2) == minterms(g2a) == minterms(g2b))
# Bài tập: f = xz(ȳ∨t̄) ∨ x̄z̄t̄ ∨ z(yt ∨ x̄ȳ) -> xz ∨ zt ∨ x̄z̄t̄ ∨ ȳz
f3 = lambda x,y,z,t: (x&z&(N(y)|N(t)))|(N(x)&N(z)&N(t))|(z&((y&t)|(N(x)&N(y))))
g3 = lambda x,y,z,t: (x&z)|(z&t)|(N(x)&N(z)&N(t))|(N(y)&z)
g3b = lambda x,y,z,t: (x&z)|(z&t)|(N(x)&N(z)&N(t))|(N(x)&N(y)&N(t))
check("S4-BT", "Bài tập tr.62-65: cả hai phủ đều biểu diễn f; tối tiểu xz∨zt∨x̄z̄t̄∨ȳz", minterms(f3) == minterms(g3) == minterms(g3b))
check("S4-mạch", "Sơ đồ tr.74: (x∨y∨z)x̄ȳz̄ ≡ 0 (hằng sai)", minterms(lambda x,y,z: (x|y|z)&N(x)&N(y)&N(z), 3) == set())
maj = lambda x,y,z: int(x+y+z >= 2)
check("S4-bầu", "Hàm bầu đa số = xy ∨ yz ∨ xz", minterms(maj,3) == minterms(lambda x,y,z: (x&y)|(y&z)|(x&z),3))
odd = lambda x,y,z: (x+y+z) % 2
check("S4-3cầu dao", "F=1 khi 1 hoặc 3 công tắc bật = xyz ∨ xȳz̄ ∨ x̄yz̄ ∨ x̄ȳz", minterms(odd,3) == minterms(lambda x,y,z: (x&y&z)|(x&N(y)&N(z))|(N(x)&y&N(z))|(N(x)&N(y)&z),3))

# ---------- S5 (Chương 5) ----------
import networkx as nx
G = nx.Graph(); G.add_weighted_edges_from([('u','r',4),('u','y',1),('r','s',7),('r','t',3),('r','y',2),('s','t',3),('s','x',1),('t','x',1),('t','z',4),('x','w',3),('y','z',3),('z','w',5)])
d = nx.single_source_dijkstra_path_length(G,'u')
check("S5-p60", "Dijkstra từ u: r3,s8,t6,x7,y1,z4,w9", d == {'u':0,'y':1,'r':3,'z':4,'t':6,'x':7,'s':8,'w':9})
D = [[0,5,31,40,None,None,None],[None,0,27,None,73,None,None],[None,26,0,8,49,25,38],[None,None,None,0,None,16,None],[None,70,None,None,0,None,9],[None,None,None,None,23,0,12],[None,None,None,None,10,None,0]]
H = nx.DiGraph()
for i in range(7):
    for j in range(7):
        if i != j and D[i][j] is not None: H.add_edge(i+1,j+1,weight=D[i][j])
d = nx.single_source_dijkstra_path_length(H,1)
check("S5-p68", "Dijkstra ma trận 7 đỉnh: v2=5,v3=31,v4=39,v5=77,v6=55,v7=67", d == {1:0,2:5,3:31,4:39,5:77,6:55,7:67})
G = nx.Graph(); G.add_weighted_edges_from([('a','b',4),('a','c',3),('b','c',2),('b','d',5),('c','d',3),('c','e',6),('d','e',1),('d','f',5),('e','g',5),('f','g',2),('f','z',7),('g','z',4)])
d = nx.single_source_dijkstra_path_length(G,'a')
check("S5-p71", "Dijkstra a→z = 16 (a-c-d-e-g-z)", d['z'] == 16 and nx.dijkstra_path(G,'a','z') == ['a','c','d','e','g','z'])
def bt(w64):
    E = [(1,2,7),(1,4,8),(2,3,4),(2,6,1),(4,2,2),(2,5,2),(6,4,w64),(4,5,2),(5,6,3),(6,3,2)]
    return E
E = bt(-6)
H = nx.DiGraph(); H.add_weighted_edges_from(E)
check("S5-BT1", "BT1 (cung 6→4 = −6) có mạch âm 4→2→6→4 độ dài −3", nx.negative_edge_cycle(H) and (2+1-6) == -3)
H = nx.DiGraph(); H.add_weighted_edges_from(bt(-2))
d = nx.single_source_bellman_ford_path_length(H,1)
check("S5-BT2", "BT2 (cung 6→4 = −2): L=(0,7,10,6,8,8)", not nx.negative_edge_cycle(H) and d == {1:0,2:7,3:10,4:6,5:8,6:8})
G = nx.MultiGraph(); G.add_edges_from([('a','b'),('b','c'),('c','d'),('a','g'),('b','h'),('b','g'),('h','g'),('g','f'),('f','e'),('c','f'),('c','e'),('d','f')])
check("S5-p51", "Đồ thị Euler tr.51: mọi đỉnh bậc chẵn, liên thông, abcfdcefghbga là chu trình Euler",
      all(dg % 2 == 0 for _,dg in G.degree()) and nx.is_connected(G) and
      sorted(tuple(sorted(e)) for e in zip("abcfdcefghbg","bcfdcefghbga")) == sorted(tuple(sorted(e)) for e in G.edges()))
G = nx.Graph(); G.add_edges_from([('a','b'),('a','c'),('b','c'),('b','f'),('b','e'),('c','f')]); G.add_node('d')
check("S5-p21", "Bậc tr.21: a2 b4 c3 d0 e1 f2 ; tổng = 2m", dict(G.degree()) == {'a':2,'b':4,'c':3,'f':2,'e':1,'d':0} and sum(dict(G.degree()).values()) == 2*G.number_of_edges())

print("\nTỔNG:", sum(R), "/", len(R), "kiểm tra đạt")
