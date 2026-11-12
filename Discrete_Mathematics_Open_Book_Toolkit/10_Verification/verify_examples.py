"""Kiểm tra độc lập mọi đáp số trong 06_Example_Bank (kể cả biến thể).
Chạy: python3 verify_examples.py   (cần sympy, networkx). In [OK]/[FAIL] theo mã ví dụ."""
import itertools, math
from fractions import Fraction as Fr
import networkx as nx
from sympy import sqrt, Rational, nsimplify, simplify
from boolmin import minimal_covers, term

R = []
def check(tag, desc, cond):
    R.append(bool(cond)); print(("[OK]  " if cond else "[FAIL]"), tag, desc)
imp = lambda a, b: (not a) or b
B = [0, 1]
def tt(fn, n): return [int(bool(fn(*v))) for v in itertools.product(B, repeat=n)]
def valid(prem, concl, n):
    return all(concl(*v) for v in itertools.product(B, repeat=n) if all(p(*v) for p in prem))

# ---------------- Chương I ----------------
check("LOG-02-E01", "E=¬(p∧q)∧p ⇔ p∧¬q", tt(lambda p,q: (not(p and q)) and p, 2) == tt(lambda p,q: p and not q, 2))
F = lambda p,q,r: (p and (q or r)) == (not q)
check("LOG-02-E01", "F đúng tại 010, 011, 101", [v for v in itertools.product(B,repeat=3) if F(*v)] == [(0,1,0),(0,1,1),(1,0,1)])
check("LOG-02-E01", "Biến thể F' đúng tại 101 duy nhất", [v for v in itertools.product(B,repeat=3) if (v[0] and ((v[1] or v[2]) == (not v[1])))] == [(1,0,1)])
check("LOG-02-E02", "B hằng đúng; C ⇔ p∧¬q; p∧¬(q→p) hằng sai",
      all(tt(lambda p,q: imp(p, p or q),2)) and tt(lambda p,q: p and not imp(p,q),2) == tt(lambda p,q: p and not q,2) and not any(tt(lambda p,q: p and not imp(q,p),2)))
check("LOG-02-E02", "Biến thể: (p∧q)→p hằng đúng; (p→q)∧(p∧¬q) hằng sai", all(tt(lambda p,q: imp(p and q,p),2)) and not any(tt(lambda p,q: imp(p,q) and p and not q,2)))
check("LOG-03-E01", "(p→r)∧(q→r) ⇔ (p∨q)→r", tt(lambda p,q,r: imp(p,r) and imp(q,r),3) == tt(lambda p,q,r: imp(p or q, r),3))
check("LOG-03-E02", "¬(p∨(¬p∧q)) ⇔ ¬p∧¬q; (p∧q)∨(p∧¬q) ⇔ p",
      tt(lambda p,q: not(p or ((not p) and q)),2) == tt(lambda p,q: (not p) and (not q),2) and tt(lambda p,q: (p and q) or (p and not q),2) == tt(lambda p,q: p,2))
P1 = [lambda p,q,r,s,t: imp(p, imp(q,r)), lambda p,q,r,s,t: p or s, lambda p,q,r,s,t: imp(t,q)]
check("LOG-04-E01", "Biến thể (tiền đề s): phản ví dụ p=0,q=1,r=0,s=1,t=1",
      all(f(0,1,0,1,1) for f in P1) and 1 and not imp(not 0, not 1))
check("LOG-04-E02", "Bỏ p∨r: phản ví dụ p=q=r=s=0", imp(0,0) and ((not 0) or 0) and not imp(not 0, 0))
check("LOG-05-E01", "Biến thể q∧t→s là kết luận đúng",
      valid([lambda p,q,r,s,t: imp(not p,q), lambda p,q,r,s,t: imp(q and r,s), lambda p,q,r,s,t: imp(t,r), lambda p,q,r,s,t: p], lambda p,q,r,s,t: imp(q and t, s), 5))
check("LOG-05-E02", "Biến thể ¬s là kết luận đúng",
      valid([lambda p,q,r,s: p, lambda p,q,r,s: imp(p,r), lambda p,q,r,s: imp(p, q or not r), lambda p,q,r,s: (not q) or (not s)], lambda p,q,r,s: not s, 4))
xs = [i/50 for i in range(-500, 501)]
check("QNT-01-E01", "(a): ∀ sai (x=0), ∃ đúng (x=-1), ∀ x²+1≥2x đúng, ∃ x²+1<0 sai",
      (0+0+1) > 0 and (1-3+1) <= 0 and all(x*x+1 >= 2*x for x in xs) and not any(x*x+1 < 0 for x in xs))
check("QNT-01-E01", "(b): y=-a/2 cho ∀∃; y=-a/2+2 bác bỏ ∃∀", all(a + 2*(-a/2) < 1 for a in xs) and all(a + 2*(-a/2+2) >= 1 for a in xs))
check("SET-01-E01", "A\\(B∪C)=(A\\B)∩(A\\C) với mọi A,B,C ⊆ {1,2,3}",
      all((A - (Bs | C)) == ((A - Bs) & (A - C)) for A in map(set, itertools.chain.from_iterable(itertools.combinations([1,2,3],k) for k in range(4)))
          for Bs in map(set, itertools.chain.from_iterable(itertools.combinations([1,2,3],k) for k in range(4)))
          for C in map(set, itertools.chain.from_iterable(itertools.combinations([1,2,3],k) for k in range(4)))))
check("SET-01-E01", "Biến thể: A\\(B∩C) ≠ (A\\B)∩(A\\C) với A={1,2},B={1},C={2}", ({1,2} - ({1} & {2})) != (({1,2}-{1}) & ({1,2}-{2})))
check("SET-02-E01", "|P({1,2,3})|=8, |A×B|=6, |P(A×B)|=64", len(list(itertools.chain.from_iterable(itertools.combinations([1,2,3],k) for k in range(4)))) == 8 and len(list(itertools.product('ab',[1,2,3]))) == 6 and 2**6 == 64)
f = lambda x: x*x+1
check("FUN-01-E01", "Biến thể: f([-3,2])=[1,10], f^{-1}([0,1])={0}, f^{-1}((5,10])=[-3,-2)∪(2,3]",
      min(map(f,[i/100 for i in range(-300,201)])) == 1 and max(map(f,[i/100 for i in range(-300,201)])) == 10
      and [x for x in xs if 0 <= f(x) <= 1] == [0.0] and all((5 < f(x) <= 10) == ((-3 <= x < -2) or (2 < x <= 3)) for x in xs))
g = lambda x: Fr(2*x+1, 1) / (x-1)
check("FUN-02-E02", "f(x)=(2x+1)/(x-1): f^{-1}(y)=(y+1)/(y-2), f(4)=3, ảnh không chứa 2",
      all(g(Fr(y+1)/(y-2)) == y for y in [Fr(k,7) for k in range(-50,50)] if y != 2) and g(4) == 3
      and all(g(Fr(k,13)) != 2 for k in range(-200,200) if Fr(k,13) != 1))
h = lambda x: Fr(2*x)/(x*x+1)
check("FUN-02-E02", "Biến thể 2x/(x²+1): f(2)=f(1/2)=4/5", h(2) == h(Fr(1,2)) == Fr(4,5))
def fpw(x): return x*x if x > 0 else x+1
gg = lambda x: 2*x+1
check("FUN-03-E01", "g∘f, f∘g cho hàm từng khúc", all(abs(gg(fpw(x)) - ((2*x*x+1) if x > 0 else (2*x+3))) < 1e-9 for x in xs)
      and all(abs(fpw(gg(x)) - (((2*x+1)**2) if x > -0.5 else (2*x+2))) < 1e-9 for x in xs))
check("FUN-03-E01", "(a) g∘f=x²+2, f∘g=x²+2x+2", all(abs((f(x)+1)-(x*x+2))<1e-9 and abs(f(x+1)-(x*x+2*x+2))<1e-9 for x in xs))
check("IND-01-E02", "Σk = n(n+1)/2, Σk² = n(n+1)(2n+1)/6 (n≤200)", all(sum(range(1,n+1)) == n*(n+1)//2 and sum(k*k for k in range(1,n+1)) == n*(n+1)*(2*n+1)//6 for n in range(1,201)))
check("IND-01-E03", "Biến thể 2^n > n² với n≥5 (và sai tại n=4)", all(2**n > n*n for n in range(5,80)) and not 2**4 > 16)
check("IND-01-E04", "6 | n³−n", all((n**3-n) % 6 == 0 for n in range(0,500)))

# ---------------- Chương II ----------------
X = [0,1,2,3,4,5]
num = lambda k, cond: sum(1 for d in itertools.permutations(X,k) if d[0] != 0 and cond(d))
check("CNT-01-E01", "Biến thể: 3 chữ số khác nhau chia hết cho 5 = 36", num(3, lambda d: d[-1] % 5 == 0) == 36)
check("CNT-01-E02", "4 chữ số khác nhau chia hết cho 5 = 108; số lẻ = 144", num(4, lambda d: d[-1] % 5 == 0) == 108 and num(4, lambda d: d[-1] % 2 == 1) == 144)
check("CNT-02-E01", "{1,2,3,4,5} không có cặp tổng 10; ⌈20/7⌉=3; ⌈367/366⌉=2", not any(a+b == 10 for a,b in itertools.combinations([1,2,3,4,5],2)) and -(-20//7) == 3 and -(-367//366) == 2)
check("CNT-03-E01", "24+26−15=35", 24+26-15 == 35)
check("CNT-03-E02", "734 số chia hết 2/3/5; 266 không; biến thể 33", sum(1 for n in range(1,1001) if n%2==0 or n%3==0 or n%5==0) == 734
      and sum(1 for n in range(1,101) if n%2 and n%3) == 33)
check("CNT-04-E01", "5!=120, A(6,3)=120, 6³=216, C(30,10)=30045015, A(30,3)=24360",
      math.factorial(5) == 120 and math.perm(6,3) == 120 and 6**3 == 216 and math.comb(30,10) == 30045015 and math.perm(30,3) == 24360)
check("CNT-05-E01", "MISSISSIPPI = 34650", math.factorial(11)//(math.factorial(4)**2*math.factorial(2)) == 34650)
check("CNT-06-E01", "K(3,2)=6, K(3,5)=21", math.comb(4,2) == 6 and math.comb(7,5) == 21)
cnt = sum(1 for x1 in range(21) for x2 in range(21) for x3 in range(21) if (x4 := 20-x1-x2-x3) >= 0 and x1 <= 3 and x2 >= 2 and x3 >= 5 and x4 <= 6)
check("CNT-06-E02", "Biến thể thêm x4≤6: 266", cnt == 266 == math.comb(16,3)-math.comb(12,3)-math.comb(9,3)+math.comb(5,3))
check("CNT-06-E03", "Bỏ ràng buộc C≤5: 15", sum(1 for a in range(13) for b in range(13) if (c := 12-a-b) >= 2 and a >= 4 and b >= 2) == 15)

def seq_check(tag, desc, rec, xfun, ics, start, stop=26):
    ok = all(xfun(k) == v for k, v in ics.items()) and all(rec(xfun, k) for k in range(start, stop))
    check(tag, desc, ok)
Q = Fr
check("REC-01-E01", "Cầu thang: x3=3,x4=5 (vét cạn); bước 1/2/3: x3=4",
      sum(1 for L in range(1,6) for c in itertools.product([1,2],repeat=L) if sum(c) == 3) == 3
      and sum(1 for L in range(1,6) for c in itertools.product([1,2],repeat=L) if sum(c) == 4) == 5
      and sum(1 for L in range(1,4) for c in itertools.product([1,2,3],repeat=L) if sum(c) == 3) == 4)
seq_check("REC-01-E02", "Hà Nội 2^n−1", lambda x,k: x(k) == 2*x(k-1)+1, lambda k: 2**k-1, {1:1}, 2)
seq_check("REC-01-E02", "Biến thể gửi tiết kiệm (a=3): (a+20)1.05^n−20", lambda x,k: x(k) == Q(105,100)*x(k-1)+1, lambda k: 23*Q(105,100)**k-20, {0:3}, 1)
bits = lambda n: sum(1 for s in itertools.product('01', repeat=n) if '00' not in ''.join(s))
check("REC-01-E03", "Chuỗi bit không '00': x1=2,x2=3, x_n=x_{n-1}+x_{n-2} (n≤15)", bits(1) == 2 and bits(2) == 3 and all(bits(n) == bits(n-1)+bits(n-2) for n in range(3,16)))
seq_check("REC-02-E01", "(3/2)^n; biến thể 2(−3)^n", lambda x,k: 2*x(k)-3*x(k-1) == 0, lambda k: Q(3,2)**k, {0:1}, 1)
seq_check("REC-02-E01", "biến thể x_n=2(−3)^n", lambda x,k: x(k) == -3*x(k-1), lambda k: 2*(-3)**k, {0:2}, 1)
seq_check("REC-02-E02", "(b) (3+n)(3/2)^{n−1}", lambda x,k: 4*x(k+1)-12*x(k)+9*x(k-1) == 0, lambda k: (3+k)*Q(3,2)**(k-1), {0:2,1:4,2:Q(15,2)}, 1)
seq_check("REC-02-E02", "biến thể 3·2^n−2·3^n", lambda x,k: x(k) == 5*x(k-1)-6*x(k-2), lambda k: 3*2**k-2*3**k, {0:1,1:0}, 2)
phi, psi = (1+sqrt(5))/2, (1-sqrt(5))/2
fibx = lambda k: simplify((5+sqrt(5))/10*phi**k + (5-sqrt(5))/10*psi**k)
fb = [None, 1, 2]
for k in range(3, 26): fb.append(fb[-1]+fb[-2])
check("REC-02-E03", "Công thức Binet khớp 1,2,3,5,... và dạng (φ^{n+1}−ψ^{n+1})/√5", all(fibx(k) == fb[k] for k in range(1,26)) and all(simplify((phi**(k+1)-psi**(k+1))/sqrt(5) - fb[k]) == 0 for k in range(1,15)))
bx = lambda k: simplify((5+3*sqrt(5))/10*phi**k + (5-3*sqrt(5))/10*psi**k)
check("REC-02-E03", "Biến thể chuỗi bit: hằng số (5±3√5)/10", all(bx(k) == bits(k) for k in range(1,14)))
seq_check("REC-03-E01", "nghiệm riêng n(2n−1); biến thể x0=0,x1=1 ⇒ x_n=n(2n−1)", lambda x,k: 2*x(k)-3*x(k-1)+x(k-2) == 4*k+1, lambda k: k*(2*k-1), {0:0,1:1}, 2)
seq_check("REC-03-E02", "(n³+2n²−5n+2)3^n", lambda x,k: x(k+1)-6*x(k)+9*x(k-1) == (18*k+12)*3**k, lambda k: (k**3+2*k*k-5*k+2)*3**k, {0:2,1:0,2:72}, 1)
seq_check("REC-03-E02", "biến thể n²3^n/6 cho vế phải 3^n", lambda x,k: x(k+1)-6*x(k)+9*x(k-1) == 3**k, lambda k: Q(k*k*3**k,6), {}, 1)
seq_check("REC-03-E03", "(2−6n)(3/2)^n+(2n²+n−1)2^n", lambda x,k: 4*x(k+1)-12*x(k)+9*x(k-1) == (2*k*k+29*k+56)*Q(2)**(k-1), lambda k: (2-6*k)*Q(3,2)**k+(2*k*k+k-1)*2**k, {0:1,1:-2,2:Q(27,2)}, 1)
seq_check("REC-03-E03", "biến thể n²(3/2)^n/12", lambda x,k: 4*x(k+1)-12*x(k)+9*x(k-1) == Q(3,2)**k, lambda k: Q(k*k,12)*Q(3,2)**k, {}, 1)
seq_check("REC-03-E04", "−5/3+(5/3)(−5)^n+n²+4n", lambda x,k: x(k)+4*x(k-1)-5*x(k-2) == 12*k+8, lambda k: Q(-5,3)+Q(5,3)*(-5)**k+k*k+4*k, {0:0,1:-5,2:52}, 2)
seq_check("REC-03-E04", "biến thể x*=n cho vế phải 6", lambda x,k: x(k)+4*x(k-1)-5*x(k-2) == 6, lambda k: k, {}, 2)
seq_check("REC-03-E05", "(−2)^n+2(−1/2)^n+n3^n", lambda x,k: 2*x(k+2)+5*x(k+1)+2*x(k) == (35*k+51)*3**k, lambda k: (-2)**k+2*Q(-1,2)**k+k*3**k, {0:3,1:0,2:Q(45,2)}, 0)
seq_check("REC-03-E05", "biến thể (3/2)n(−2)^n cho 9(−2)^n", lambda x,k: 2*x(k+2)+5*x(k+1)+2*x(k) == 9*(-2)**k, lambda k: Q(3,2)*k*(-2)**k, {}, 0)
seq_check("REC-03-E06", "(n−1)²", lambda x,k: x(k+2)-2*x(k+1)+x(k) == 2, lambda k: (k-1)**2, {0:1,1:0,2:1}, 0)
seq_check("REC-03-E06", "biến thể 2^n cho vế phải 2^n", lambda x,k: x(k+2)-2*x(k+1)+x(k) == 2**k, lambda k: 2**k, {}, 0)
seq_check("REC-03-E07", "(n+2)²−3·2^n", lambda x,k: 2*x(k)-5*x(k-1)+2*x(k-2) == -k*k-2*k+3, lambda k: (k+2)**2-3*2**k, {0:1,1:3,2:4}, 2)
seq_check("REC-03-E07", "biến thể (2/3)n2^n", lambda x,k: 2*x(k)-5*x(k-1)+2*x(k-2) == 2**k, lambda k: Q(2,3)*k*2**k, {}, 2)
seq_check("REC-03-E08", "3^n+(n−2)5^n", lambda x,k: x(k+2)-8*x(k+1)+15*x(k) == 2*5**(k+1), lambda k: 3**k+(k-2)*5**k, {0:-1,1:-2,2:9}, 0)
seq_check("REC-03-E08", "biến thể −n3^n/6", lambda x,k: x(k+2)-8*x(k+1)+15*x(k) == 3**k, lambda k: Q(-k*3**k,6), {}, 0)
seq_check("REC-03-E09", "(n²+n+2)8^n", lambda x,k: x(k+2)-16*x(k+1)+64*x(k) == 128*8**k, lambda k: (k*k+k+2)*8**k, {0:2,1:32,2:512}, 0)
seq_check("REC-03-E09", "biến thể 64/49", lambda x,k: x(k+2)-16*x(k+1)+64*x(k) == 64, lambda k: Q(64,49), {}, 0)
seq_check("REC-04-E01", "nghiệm riêng −10n+n2^n+4^{n+2} (C1=1,C2=2 tùy ý)", lambda x,k: x(k)-4*x(k-1)+3*x(k-2) == 20+(2-k)*Q(2)**(k-2)+3*4**k, lambda k: 1+2*3**k-10*k+k*2**k+4**(k+2), {}, 2)
seq_check("REC-04-E01", "biến thể (3/2)n3^n−n/2", lambda x,k: x(k)-4*x(k-1)+3*x(k-2) == 3**k+1, lambda k: Q(3,2)*k*3**k-Q(k,2), {}, 2)

# ---------------- Chương III ----------------
def props(Rl, A):
    Rs = set(Rl)
    return (all((a,a) in Rs for a in A), all((b,a) in Rs for a,b in Rs),
            all(not((b,a) in Rs and a != b) for a,b in Rs), all((a,d) in Rs for a,b in Rs for c,d in Rs if b == c))
A = [1,2,3,4]
check("REL-02-E01", "Bảng tính chất R1..R4", [props(r,A) for r in (
    [(1,1),(1,2),(2,1),(2,2),(3,4),(4,1),(4,4)], [(1,1),(1,2),(1,4),(2,2),(3,3),(4,1),(4,4)],
    [(1,1),(1,2),(2,1)], [(1,1),(1,2),(2,1),(2,2),(1,3),(2,3)])] ==
    [(False,False,False,False),(True,False,False,False),(False,True,False,False),(False,False,False,True)])
check("REL-02-E01", "Biến thể ma trận: PX, phản xứng, không bắc cầu", props([('u','u'),('u','v'),('v','v'),('v','w'),('w','w')], ['u','v','w']) == (True,False,True,False))
Z = range(-3,4)
Rz = [(a,b) for a in Z for b in Z if a*b >= 0]
check("REL-02-E02", "ab≥0: PX, ĐX, không phản xứng, không bắc cầu", props(Rz, list(Z)) == (True,True,False,False))
Zn = [a for a in range(-4,5) if a]
check("REL-02-E02", "Biến thể ab>0 trên Z\\{0}: tương đương", props([(a,b) for a in Zn for b in Zn if a*b > 0], Zn)[0:2] == (True,True) and props([(a,b) for a in Zn for b in Zn if a*b > 0], Zn)[3])
check("REL-03-E01", "−7 ∈ [1]_8; [5]_3=[2]_3", (-7-1) % 8 == 0 and (5-2) % 3 == 0)
blocks = [{1,2},{3},{4,5,6}]
Rp = [(a,b) for bl in blocks for a in bl for b in bl]
check("REL-03-E02", "|R|=14, tương đương, [5]={4,5,6}", len(Rp) == 14 and props(Rp,[1,2,3,4,5,6])[0] and props(Rp,[1,2,3,4,5,6])[1] and props(Rp,[1,2,3,4,5,6])[3] and {b for a,b in Rp if a == 5} == {4,5,6})
words = ['discreet','discrete','discreetness','0110','10','01100']
check("POS-02-E01", "discreet<discrete<…; 0110<10; 0110<01100; a<aab<ab<b", 'discreet' < 'discrete' and 'discreet' < 'discreetness' and '0110' < '10' and '0110' < '01100' and sorted(['b','ab','a','aab']) == ['a','aab','ab','b'])
def hasse(S):
    rel = [(a,b) for a in S for b in S if a != b and b % a == 0]
    return sorted((a,b) for a,b in rel if not any((a,c) in rel and (c,b) in rel for c in S))
check("POS-03-E01", "Cung Hasse của {2,4,5,10,12,20,25}", hasse([2,4,5,10,12,20,25]) == [(2,4),(2,10),(4,12),(4,20),(5,10),(5,25),(10,20)])
check("POS-03-E01", "Biến thể Ư(12): cung Hasse", hasse([1,2,3,4,6,12]) == [(1,2),(1,3),(2,4),(2,6),(3,6),(4,12),(6,12)])
S = [2,3,4,6,12,18]
ub = lambda A: [x for x in S if all(x % a == 0 for a in A)]
lb = lambda A: [x for x in S if all(a % x == 0 for a in A)]
sup = lambda A: [x for x in ub(A) if all(y % x == 0 for y in ub(A))]
inf = lambda A: [x for x in lb(A) if all(x % y == 0 for y in lb(A))]
check("POS-04-E01", "sup{2,3}=6, inf{2,3} không; sup{12,18} không, inf=6; sup{4,6}=12, inf=2",
      sup([2,3]) == [6] and inf([2,3]) == [] and lb([2,3]) == [] and sup([12,18]) == [] and inf([12,18]) == [6] and sup([4,6]) == [12] and inf([4,6]) == [2])
cov = [('a','b'),('a','c'),('e','c'),('b','d'),('c','d'),('d','f')]
D = nx.DiGraph(cov); clo = nx.transitive_closure(D)
ok_order = lambda order: all(order.index(u) < order.index(v) for u,v in clo.edges())
check("POS-05-E01", "a,e,b,c,d,f và e,a,c,b,d,f là sắp xếp topo; thêm f≺a tạo vòng", ok_order(list('aebcdf')) and ok_order(list('eacbdf')) and not nx.is_directed_acyclic_graph(nx.DiGraph(cov+[('f','a')])))

# ---------------- Chương IV ----------------
def ones(fn, n): return {v for v in itertools.product(B, repeat=n) if fn(*v)}
N = lambda a: 1-a
check("BOO-01-E01", "Bầu đa số = xy∨yz∨xz", ones(lambda x,y,z: x+y+z >= 2, 3) == ones(lambda x,y,z: (x&y)|(y&z)|(x&z), 3))
check("BOO-01-E02", "x∨ȳz có 5 từ tối tiểu; bù = x̄(y∨z̄) có 3", len(ones(lambda x,y,z: x|(N(y)&z),3)) == 5 and ones(lambda x,y,z: N(x|(N(y)&z)),3) == ones(lambda x,y,z: N(x)&(y|N(z)),3) == {(0,0,0),(0,1,0),(0,1,1)})
def mins(fn, names):
    o = ones(fn, len(names)); P, covers = minimal_covers(o, len(names))
    return sorted(sorted(term(m, names) for m, _ in c) for c in covers)
f1 = lambda x,y,z,t: (x&y&z&t)|(x&N(y))|(x&N(z))|(y&z)|(x&y&N(z))|(x&y&N(t))
check("BOO-03-E01", "f = x ∨ yz (duy nhất)", mins(f1,'xyzt') == [['x','yz']])
f2 = lambda x,y,z,t: (N(y)&z&t)|(N(y)&N(z)&N(t))|(y&N(z)&N(t))|(x&y&z&t)|(N(x)&z&N(t))
check("BOO-03-E02", "Hai công thức tối tiểu", mins(f2,'xyzt') == sorted([sorted(["z't'","x't'","xzt","x'y'z"]), sorted(["z't'","x't'","xzt","y'zt"])]))
check("BOO-03-E02", "Biến thể thêm ô 0001", mins(lambda x,y,z,t: f2(x,y,z,t) | int((x,y,z,t) == (0,0,0,1)),'xyzt') == [sorted(["z't'","x't'","xzt","x'y'"])])
f3 = lambda x,y,z,t: (x&z&(N(y)|N(t)))|(N(x)&N(z)&N(t))|(z&((y&t)|(N(x)&N(y))))
check("BOO-03-E03", "Tối tiểu duy nhất xz∨zt∨x̄z̄t̄∨ȳz", mins(f3,'xyzt') == [sorted(['xz','zt',"x'z't'","y'z"])])
check("BOO-03-E04", "z ∨ x̄y; bù x z̄ ∨ ȳz̄", mins(lambda x,y,z: (x,y,z) in {(0,0,1),(0,1,0),(0,1,1),(1,0,1),(1,1,1)},'xyz') == [sorted(['z',"x'y"])]
      and mins(lambda x,y,z: (x,y,z) in {(0,0,0),(1,0,0),(1,1,0)},'xyz') == [sorted(["xz'","y'z'"])])
S5 = {(0,0,0,0),(0,0,1,0),(1,0,0,0),(1,0,1,0),(0,1,0,1),(1,1,0,1),(0,1,1,1),(1,1,1,1),(0,0,0,1)}
check("BOO-03-E05", "Hai công thức tối tiểu", mins(lambda *v: v in S5,'xyzt') == sorted([sorted(["y't'","yt","x'z't"]), sorted(["y't'","yt","x'y'z'"])]))
check("BOO-03-E05", "Biến thể thêm 1001", mins(lambda *v: v in S5 | {(1,0,0,1)},'xyzt') == sorted([sorted(["y't'","yt","z't"]), sorted(["y't'","yt","y'z'"])]))
check("BOO-04-E01", "xy∨x̄ȳ; biến thể x ȳ∨x̄y", ones(lambda x,y: x == y, 2) == ones(lambda x,y: (x&y)|(N(x)&N(y)),2) and ones(lambda x,y: x != y,2) == ones(lambda x,y: (x&N(y))|(N(x)&y),2))
check("BOO-04-E02", "Đèn 3 công tắc: 4 từ tối tiểu là tối tiểu; biến thể đúng 2 bật", mins(lambda x,y,z: (x+y+z) % 2, 'xyz') == [sorted(['xyz',"xy'z'","x'yz'","x'y'z"])]
      and ones(lambda x,y,z: x+y+z == 2,3) == ones(lambda x,y,z: (x&y&N(z))|(x&N(y)&z)|(N(x)&y&z),3))
check("BOO-04-E03", "(x∨y∨z)x̄ȳz̄ ≡ 0; thay AND cuối bằng OR ≡ 1", ones(lambda x,y,z: (x|y|z)&N(x)&N(y)&N(z),3) == set() and len(ones(lambda x,y,z: (x|y|z)|(N(x)&N(y)&N(z)),3)) == 8)
f4 = lambda x,y,z,t: (x&z)|(N(y)&z)|(x&t)|(N(y)&N(t))|(N(x)&N(y)&N(z))
check("BOO-04-E04", "Rút gọn thành ȳ ∨ xz ∨ xt; = ȳ ∨ x(z∨t)", mins(f4,'xyzt') == [sorted(["y'",'xz','xt'])] and ones(f4,4) == ones(lambda x,y,z,t: N(y)|(x&(z|t)),4))

# ---------------- Chương V ----------------
G = nx.MultiGraph([('a','b'),('a','c'),('b','c'),('b','d'),('c','d'),('b','b')])
check("GRA-01-E01", "(a) bậc a2 b5 c3 d2", dict(G.degree()) == {'a':2,'b':5,'c':3,'d':2})
Dg = nx.DiGraph([('b','a'),('a','c'),('c','b'),('b','e'),('b','f'),('c','f')]); Dg.add_node('d')
check("GRA-01-E01", "(c) bậc vào/ra", {v:(Dg.in_degree(v),Dg.out_degree(v)) for v in 'abcdef'} == {'a':(1,1),'b':(1,3),'c':(1,2),'d':(0,0),'e':(1,0),'f':(2,0)})
seqs = set()
for E in itertools.chain.from_iterable(itertools.combinations(list(itertools.combinations(range(4),2)),k) for k in range(7)):
    H = nx.Graph(); H.add_nodes_from(range(4)); H.add_edges_from(E); seqs.add(tuple(sorted((d for _,d in H.degree()), reverse=True)))
check("GRA-01-E02", "Không có đơn đồ thị 4 đỉnh bậc (3,3,3,1); có (3,3,3,3)", (3,3,3,1) not in seqs and (3,3,3,3) in seqs)
M = nx.to_numpy_array(nx.MultiGraph([('a','b'),('a','b'),('a','c'),('b','c'),('b','e'),('b','f'),('c','f'),('e','e')]), nodelist=list('abcef'))
check("GRA-02-E01", "Ma trận (b): a_ab=2; networkx ghi khuyên = 1 (quy ước khác — CON-01)", M[0][1] == 2 and M[3][3] in (1,2))
G1 = nx.Graph([('a','b'),('b','c'),('c','d'),('d','e'),('e','a'),('c','e')]); G2 = nx.Graph([('a','b'),('b','c'),('a','c'),('a','e'),('a','d'),('c','d')])
H = nx.Graph([(1,2),(2,3),(3,4),(4,5),(5,1),(2,4)])
mp = {'a':5,'b':1,'c':2,'d':3,'e':4}
check("GRA-03-E01", "(a) không đẳng cấu; (b) đẳng cấu với ánh xạ đã cho; C6 ≇ 2K3",
      not nx.is_isomorphic(G1,G2) and all(H.has_edge(mp[u],mp[v]) for u,v in G1.edges()) and not nx.is_isomorphic(nx.cycle_graph(6), nx.disjoint_union(nx.cycle_graph(3),nx.cycle_graph(3))))
P = nx.Graph([('a','b'),('b','c'),('c','d'),('d','b'),('b','f'),('b','e'),('f','e'),('e','g')])
check("GRA-04-E01", "đỉnh khớp {b,e}; cầu {ab, eg}; bc không là cầu", set(nx.articulation_points(P)) == {'b','e'} and {frozenset(e) for e in nx.bridges(P)} == {frozenset('ab'),frozenset('eg')})
E5 = [('a','b'),('b','c'),('c','d'),('a','g'),('b','h'),('b','g'),('h','g'),('g','f'),('f','e'),('c','f'),('c','e'),('d','f')]
def is_trail(walk, edges):
    used = sorted(tuple(sorted(e)) for e in zip(walk, walk[1:])); return used == sorted(tuple(sorted(e)) for e in edges)
check("GRA-05-E01", "abcfdcefghbga là chu trình Euler; agbcdfcefghb là đường đi Euler khi bỏ ab",
      is_trail('abcfdcefghbga', E5) and is_trail('agbcdfcefghb', E5[1:]))
check("GRA-05-E02", "Königsberg: bậc 5,3,3,3 — 4 đỉnh lẻ", sum(d % 2 for d in (5,3,3,3)) == 4 and sum((5,3,3,3)) == 14)
X = nx.DiGraph(); X.add_weighted_edges_from([('a','b',2),('a','c',3),('c','b',-2)])
check("GRA-06-E01", "Biến thể trọng số âm: khoảng cách thật a→b = 1", nx.single_source_bellman_ford_path_length(X,'a')['b'] == 1)
Gd = nx.Graph(); Gd.add_weighted_edges_from([('a','b',4),('a','c',3),('b','c',2),('b','d',5),('c','d',3),('c','e',6),('d','e',1),('d','f',5),('e','g',5),('f','g',2),('f','z',7),('g','z',4)])
check("GRA-06-E03", "Biến thể a→f = 11 qua a c d f", nx.dijkstra_path_length(Gd,'a','f') == 11 and nx.dijkstra_path(Gd,'a','f') == ['a','c','d','f'])
Dm = [[0,5,31,40,None,None,None],[None,0,27,None,73,None,None],[None,26,0,8,49,25,38],[None,None,None,0,None,16,None],[None,70,None,None,0,None,9],[None,None,None,None,23,0,12],[None,None,None,None,10,None,0]]
Hm = nx.DiGraph([(i+1,j+1,{'weight':Dm[i][j]}) for i in range(7) for j in range(7) if i != j and Dm[i][j] is not None and (i,j) != (6,4)])
check("GRA-06-E02", "Biến thể bỏ v7→v5: d(v1,v5)=78", nx.dijkstra_path_length(Hm,1,5) == 78)
def fb(w):
    D_ = nx.DiGraph(); D_.add_weighted_edges_from([(1,2,7),(1,4,8),(2,3,4),(2,6,1),(4,2,2),(2,5,2),(6,4,w),(4,5,2),(5,6,3),(6,3,2)]); return D_
d3 = nx.single_source_bellman_ford_path_length(fb(-3),1)
check("GRA-07-E01", "Biến thể w=−3: không mạch âm, L=(0,7,10,5,7,8)", not nx.negative_edge_cycle(fb(-3)) and [d3[i] for i in range(1,7)] == [0,7,10,5,7,8])
# Công thức Ford–Bellman của nguồn (không min với L_{k-1}(v)) cho cùng kết quả với Bellman–Ford chuẩn trên các bài của nguồn
from graph_tables import bellman_table
for w in (-2, -3):
    _, L, msg = bellman_table([1,2,3,4,5,6], [(1,2,7),(1,4,8),(2,3,4),(2,6,1),(4,2,2),(2,5,2),(6,4,w),(4,5,2),(5,6,3),(6,3,2)], 1)
    std = nx.single_source_bellman_ford_path_length(fb(w),1)
    check("F-GRA-06", f"w={w}: công thức nguồn = Bellman–Ford chuẩn", all(L[v] == std[v] for v in range(1,7)))

print("\nTỔNG:", sum(R), "/", len(R), "kiểm tra đạt")
