"""Tìm TẤT CẢ công thức đa thức tối tiểu (theo nghĩa S4-p20–21: ít đơn thức, đơn thức ít từ đơn)
bằng vét cạn: liệt kê tế bào lớn (prime implicants) rồi mọi phủ tối tiểu. Dùng để kiểm tra Karnaugh."""
import itertools
def implicants(ones, nv):
    res = []
    for mask in itertools.product([None, 0, 1], repeat=nv):      # None = biến vắng mặt
        cells = {v for v in itertools.product([0,1], repeat=nv) if all(m is None or m == b for m, b in zip(mask, v))}
        if cells and cells <= ones: res.append((mask, frozenset(cells)))
    return res
def primes(ones, nv):
    imp = implicants(ones, nv)
    return [(m, c) for m, c in imp if not any(c < c2 for _, c2 in imp)]
def lits(m): return sum(x is not None for x in m)
def term(m, names):
    s = ''.join((nm if b == 1 else nm + "'") for nm, b in zip(names, m) if b is not None)
    return s or '1'
def minimal_covers(ones, nv):
    P = primes(ones, nv); best = []
    for k in range(1, len(P) + 1):
        covers = [c for c in itertools.combinations(P, k) if set().union(*[x[1] for x in c]) == ones]
        if covers: best = covers; break
    # giữ các phủ có tổng số từ đơn nhỏ nhất (đơn giản hơn theo S4-p20)
    mn = min(sum(lits(m) for m, _ in c) for c in best)
    return P, [c for c in best if sum(lits(m) for m, _ in c) == mn]
def report(fn, names):
    nv = len(names); ones = {v for v in itertools.product([0,1], repeat=nv) if fn(*v)}
    P, covers = minimal_covers(ones, nv)
    ess = [p for p in P if any(sum(cell in q[1] for q in P) == 1 for cell in p[1])]
    print('  số ô =', len(ones))
    print('  tế bào lớn:', ', '.join(term(m, names) for m, _ in P))
    print('  bắt buộc  :', ', '.join(term(m, names) for m, _ in ess))
    for c in covers: print('  TỐI TIỂU  :', ' ∨ '.join(term(m, names) for m, _ in c))
if __name__ == '__main__':
    N = lambda a: 1 - a
    print('S4 VD1'); report(lambda x,y,z,t: (x&y&z&t)|(x&N(y))|(x&N(z))|(y&z)|(x&y&N(z))|(x&y&N(t)), 'xyzt')
    print('S4 VD2'); report(lambda x,y,z,t: (N(y)&z&t)|(N(y)&N(z)&N(t))|(y&N(z)&N(t))|(x&y&z&t)|(N(x)&z&N(t)), 'xyzt')
    print('S4 BT');  report(lambda x,y,z,t: (x&z&(N(y)|N(t)))|(N(x)&N(z)&N(t))|(z&((y&t)|(N(x)&N(y)))), 'xyzt')
    print('S4 p72'); report(lambda x,y,z,t: (x&z)|(N(y)&z)|(x&t)|(N(y)&N(t))|(N(x)&N(y)&N(z)), 'xyzt')
    print('Bầu cử'); report(lambda x,y,z: int(x+y+z>=2), 'xyz')
    print('AI-3biến f=Σ(1,2,3,5,7)? (xyz=001,010,011,101,111)'); report(lambda x,y,z: (x,y,z) in {(0,0,1),(0,1,0),(0,1,1),(1,0,1),(1,1,1)}, 'xyz')
    print('AI-4biến'); report(lambda x,y,z,t: (x,y,z,t) in {(0,0,0,0),(0,0,1,0),(1,0,0,0),(1,0,1,0),(0,1,0,1),(1,1,0,1),(0,1,1,1),(1,1,1,1),(0,0,0,1)}, 'xyzt')
