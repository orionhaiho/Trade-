"""Sinh bảng từng bước Dijkstra và Ford–Bellman đúng quy trình slide S5-p59, S5-p73–74.
Nhãn (L, đỉnh trước). Dấu * = đỉnh được cố định ở bước đó."""
INF = float('inf')
def fmt(L, p): return '(∞,-)' if L == INF else f'({L:g},{p})'
def dijkstra_table(V, E, s, directed=False):
    adj = {v: [] for v in V}
    for u, v, w in E:
        adj[u].append((v, w))
        if not directed: adj[v].append((u, w))
    L = {v: INF for v in V}; P = {v: '-' for v in V}; L[s] = 0; done = []
    rows = []; cur = s; done.append(s)
    rows.append({v: ('0*' if v == s else fmt(L[v], P[v])) for v in V})
    while len(done) < len(V):
        for v, w in adj[cur]:
            if v not in done and L[cur] + w < L[v]: L[v] = L[cur] + w; P[v] = cur
        cand = [v for v in V if v not in done]
        k = min(cand, key=lambda v: (L[v], V.index(v)))
        if L[k] == INF: break
        row = {}
        for v in V:
            if v in done: row[v] = '–'
            else: row[v] = fmt(L[v], P[v]) + ('*' if v == k else '')
        rows.append(row); done.append(k); cur = k
    return rows, L, P
def bellman_table(V, E, s):
    n = len(V); L = {v: INF for v in V}; P = {v: '-' for v in V}; L[s] = 0
    rows = [dict((v, fmt(L[v], P[v]) if v != s else '0') for v in V)]
    for k in range(1, n + 1):
        NL = {}; NP = {}
        for v in V:
            if v == s: NL[v] = 0; NP[v] = '-'; continue
            best = INF; bp = '-'
            for u, x, w in E:                       # S5-p73: L_k(v)=min{L_{k-1}(u)+w(uv)}
                if x == v and L[u] + w < best: best = L[u] + w; bp = u
            NL[v] = best; NP[v] = bp
        stable = all(NL[v] == L[v] for v in V)
        L, P = NL, NP
        rows.append(dict((v, fmt(L[v], P[v]) if v != s else '0') for v in V))
        if stable: return rows, L, 'ổn định tại k=%d' % k
    return rows, L, 'k=n=%d chưa ổn định ⇒ có mạch âm' % n
def md(rows, V, first='Bước'):
    out = ['| ' + first + ' | ' + ' | '.join(map(str, V)) + ' |', '|' + '---|' * (len(V) + 1)]
    for i, r in enumerate(rows): out.append(f'| {i} | ' + ' | '.join(str(r[v]) for v in V) + ' |')
    return '\n'.join(out)
if __name__ == '__main__':
    V = ['u','r','s','t','x','y','z','w']
    E = [('u','r',4),('u','y',1),('r','s',7),('r','t',3),('r','y',2),('s','t',3),('s','x',1),('t','x',1),('t','z',4),('x','w',3),('y','z',3),('z','w',5)]
    rows, L, P = dijkstra_table(V, E, 'u'); print('## S5-p60\n' + md(rows, V)); print(L, P)
    V = ['a','b','c','d','e','f','g','z']
    E = [('a','b',4),('a','c',3),('b','c',2),('b','d',5),('c','d',3),('c','e',6),('d','e',1),('d','f',5),('e','g',5),('f','g',2),('f','z',7),('g','z',4)]
    rows, L, P = dijkstra_table(V, E, 'a'); print('## S5-p71\n' + md(rows, V)); print(L, P)
    D = [[0,5,31,40,None,None,None],[None,0,27,None,73,None,None],[None,26,0,8,49,25,38],[None,None,None,0,None,16,None],[None,70,None,None,0,None,9],[None,None,None,None,23,0,12],[None,None,None,None,10,None,0]]
    V = ['v%d' % i for i in range(1, 8)]
    E = [(V[i], V[j], D[i][j]) for i in range(7) for j in range(7) if i != j and D[i][j] is not None]
    rows, L, P = dijkstra_table(V, E, 'v1', directed=True); print('## S5-p68\n' + md(rows, V)); print(L, P)
    V = [1,2,3,4,5,6]
    for w in (-6, -2):
        E = [(1,2,7),(1,4,8),(2,3,4),(2,6,1),(4,2,2),(2,5,2),(6,4,w),(4,5,2),(5,6,3),(6,3,2)]
        rows, L, msg = bellman_table(V, E, 1); print(f'## Ford-Bellman w(6,4)={w}\n' + md(rows, V, 'k')); print(msg)
