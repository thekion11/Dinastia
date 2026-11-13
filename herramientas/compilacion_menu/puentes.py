import re
from dom import *
capas=lambda n: re.match(r'res://ui/principal(_p\d+)?\.gd$',n) is not None
cadena={n for n in base if capas(n)}
print('bytes de las capas de Principal:',sum(scripts[n]['bytes'] for n in cadena)//1024,'KB de',tot//1024)
# hijos inmediatos del dominador que no son capas de Principal, agrupados por su subárbol dominado
cand=[]
for n in base:
    if n==ROOT or capas(n): continue
    d=idom[n]
    if d in cadena:
        cand.append((dom_b[n],n))
cand.sort(reverse=True)
print('subárboles dominados por Principal (los que SOLO entran por Principal):',len(cand))
acum_b=0
for b,n in cand[:40]:
    acum_b+=b
    # sitios de referencia desde Principal
    nm=nombre.get(n,'')
    sitios=0;arch=set()
    if nm:
        for c in cadena:
            k=len(re.findall(r'\b'+nm+r'\b',limpiar(scripts[c]['src'])))
            if k: sitios+=k; arch.add(c.split('/')[-1])
    print('%7.0f KB %5.1f%%  %-22s sitios=%-3d archivos=%-2d %s'%(b/1024,100*b/tot,nm or '(capa)',sitios,len(arch),n.split('/')[-1]))
print('suma top40: %.0f KB (%.1f%%)'%(acum_b/1024,100*acum_b/tot))
tot_cand=sum(b for b,n in cand)
print('suma de todos los subárboles: %.0f KB (%.1f%%)'%(tot_cand/1024,100*tot_cand/tot))
