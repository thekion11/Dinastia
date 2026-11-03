import sys,collections
from grafo import *
base=alcance(raices)
ROOT='__raiz__'
suc={n:[v for v in arist[n] if v in base] for n in base}
suc[ROOT]=[r for r in raices if r in base]
# orden postorden
orden=[];vis=set()
def dfs(n):
    pila=[(n,iter(suc[n]))]; vis.add(n)
    while pila:
        u,it=pila[-1]
        for v in it:
            if v not in vis:
                vis.add(v); pila.append((v,iter(suc[v]))); break
        else:
            orden.append(u); pila.pop()
dfs(ROOT)
num={n:i for i,n in enumerate(orden)}
pred=collections.defaultdict(list)
for u in suc:
    for v in suc[u]: pred[v].append(u)
idom={ROOT:ROOT}
def inter(a,b):
    while a!=b:
        while num[a]<num[b]: a=idom[a]
        while num[b]<num[a]: b=idom[b]
    return a
cambio=True
rpo=list(reversed(orden))
while cambio:
    cambio=False
    for n in rpo:
        if n==ROOT: continue
        ps=[p for p in pred[n] if p in idom]
        nuevo=ps[0]
        for p in ps[1:]: nuevo=inter(p,nuevo)
        if idom.get(n)!=nuevo: idom[n]=nuevo; cambio=True
hijos=collections.defaultdict(list)
for n,d in idom.items():
    if n!=ROOT: hijos[d].append(n)
def peso(n):
    return scripts[n]['bytes'] if n in scripts else 0
dom_b={}
def acum(n):
    s=peso(n)
    for h in hijos[n]: s+=acum(h)
    dom_b[n]=s; return s
sys.setrecursionlimit(10000)
acum(ROOT)
tot=dom_b[ROOT]
print('total bytes',tot)
nombre={v:k for k,v in clase.items()}
fil=sorted([(b,n) for n,b in dom_b.items() if n!=ROOT],reverse=True)[:30]
for b,n in fil:
    print('%8.0f KB  %5.1f%%  %-14s hijos=%-3d %s'%(b/1024,100*b/tot,nombre.get(n,''),len(hijos[n]),n))
