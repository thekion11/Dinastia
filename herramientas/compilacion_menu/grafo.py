import os,re,json,collections
RAIZ=os.environ.get('GRAFO_RAIZ','/home/user/Dinastia/dinastia-godot')
EXCL=('pruebas','terceros','addons','.godot','herramientas')
scripts={}   # ruta res -> dict
for r,d,fs in os.walk(RAIZ):
    rel=os.path.relpath(r,RAIZ)
    if rel.split(os.sep)[0] in EXCL: continue
    for f in fs:
        if f.endswith('.gd'):
            p=os.path.join(r,f); res='res://'+os.path.relpath(p,RAIZ).replace(os.sep,'/')
            scripts[res]={'src':open(p,encoding='utf-8').read(),'bytes':os.path.getsize(p)}
clase={}  # nombre -> ruta
for res,s in scripts.items():
    m=re.search(r'^class_name\s+(\w+)',s['src'],re.M)
    if m: clase[m.group(1)]=res
# autoloads
auto={}
for l in open(RAIZ+'/project.godot',encoding='utf-8'):
    m=re.match(r'(\w+)="\*?(res://[^"]+)"',l.strip())
    if m and m.group(2).endswith('.gd'): auto[m.group(1)]=m.group(2)
def limpiar(src):
    src=re.sub(r'"(?:\\.|[^"\\\n])*"','""',src)   # cadenas
    src=re.sub(r"'(?:\\.|[^'\\\n])*'","''",src)
    src=re.sub(r'#.*','',src)
    return src
arist=collections.defaultdict(set)
etiq={}
for res,s in scripts.items():
    raw=s['src']
    for m in re.finditer(r'^extends\s+"(res://[^"]+\.gd)"',raw,re.M):
        if m.group(1) in scripts: arist[res].add(m.group(1))
    m=re.search(r'^extends\s+([A-Z]\w+)',raw,re.M)
    if m and m.group(1) in clase: arist[res].add(clase[m.group(1)])
    for m in re.finditer(r'preload\("(res://[^"]+\.gd)"\)',raw):
        if m.group(1) in scripts: arist[res].add(m.group(1))
    txt=limpiar(raw)
    for ident in set(re.findall(r'\b[A-Z]\w*\b',txt)):
        if ident in clase and clase[ident]!=res: arist[res].add(clase[ident])
        elif ident in auto and auto[ident]!=res: arist[res].add(auto[ident])
raices=['res://ui/principal.gd']+list(auto.values())
def alcance(raices,quitar=None):
    vis=set(); pila=[r for r in raices if r in scripts]
    while pila:
        n=pila.pop()
        if n in vis: continue
        vis.add(n)
        for v in arist[n]:
            if quitar and (n,v) in quitar: continue
            if v not in vis: pila.append(v)
    return vis
if __name__=='__main__':
    base=alcance(raices)
    tot=sum(scripts[x]['bytes'] for x in base)
    print('scripts totales',len(scripts),'alcanzados desde el menú+autocargas',len(base),'bytes',tot)
    json.dump({'base':sorted(base)},open(os.path.dirname(__file__)+'/base.json','w'))
