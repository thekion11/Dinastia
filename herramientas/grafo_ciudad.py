#!/usr/bin/env python3
"""(9-11) Grafo estático de referencias desde principal.tscn: qué archivos solo alcanza la ciudad abierta. python3 -I herramientas/grafo_ciudad.py <carpeta dinastia-godot> <salida.txt>"""
import os,re,sys,collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))   # se corre con -I: el directorio del script no está en sys.path
from ruta_segura import ruta_segura
R=ruta_segura(sys.argv[1])
exts=('.gd','.tscn','.tres','.gdshader')
files={}
for d,_,fs in os.walk(R):
    if '/.godot' in d or '/pruebas' in d or '/terceros' in d or '/addons' in d or '/.git' in d: continue
    for f in fs:
        p=os.path.join(d,f); files[p]=os.path.getsize(p)
rel=lambda p:'res://'+os.path.relpath(p,R)
cls={}
for p in files:
    if p.endswith('.gd'):
        m=re.search(r'^class_name\s+(\w+)',open(p,encoding='utf-8',errors='ignore').read(),re.M)
        if m: cls[m.group(1)]=p
# CargaCiudad rutas
rutas=dict(re.findall(r'"(\w+)":\s*"res://([^"]+)"',open(R+'/nucleo/carga_ciudad_rutas.gd').read()))
for k,v in rutas.items(): cls.setdefault(k,os.path.join(R,v))
byres={rel(p):p for p in files}
edges=collections.defaultdict(set)
tok=re.compile(r'\b[A-Z][A-Za-z0-9_]+\b'); res=re.compile(r'res://[^"\')\s]+')
for p in files:
    if not p.endswith(exts): continue
    t=open(p,encoding='utf-8',errors='ignore').read()
    for r in res.findall(t):
        r=r.rstrip(',;')
        if r in byres: edges[p].add(byres[r])
        else:
            # carpetas / glob: res://dir/
            pass
    if p.endswith('.gd'):
        for w in set(tok.findall(t)):
            if w in cls: edges[p].add(cls[w])
        for k in re.findall(r'"([a-z0-9_]+)"',t): pass
def reach(roots,cut):
    seen=set(); st=[r for r in roots if r not in cut]
    while st:
        x=st.pop()
        if x in seen: continue
        seen.add(x)
        for y in edges.get(x,()):
            if y not in cut and y not in seen: st.append(y)
    return seen
main=R+'/escenas/principal.tscn'
city_roots={cls[n] for n in ('VistaCiudad','ExploradorCiudad','CityBuilder','CiudadExpansion','VidaCiudad') if n in cls}
allr=reach([main],set())
sin=reach([main],city_roots)
# archivos de datos referenciados por rutas dinamicas no cuentan: informar solo lo alcanzable
quita=allr-sin
tot=sum(files[p] for p in allr if p in files)
print('alcanzables total',len(allr),round(tot/1e6,1),'MB')
print('sin ciudad',len(sin),round(sum(files[p] for p in sin)/1e6,1),'MB')
print('solo-ciudad',len(quita),round(sum(files[p] for p in quita if p in files)/1e6,1),'MB')
by=collections.Counter()
for p in quita: by[os.path.dirname(os.path.relpath(p,R))]+=files.get(p,0)
for d,s in by.most_common(15): print(round(s/1e6,2),'MB',d)
open(ruta_segura(sys.argv[2]),'w').write('\n'.join(sorted(rel(p) for p in quita)))
