"""Corta, EN EL CÓDIGO REAL, las referencias estáticas a una familia desde fuera de ella (R-memoria del menú, 3-11-2026).

Cada `Clase.miembro` de una clase de la familia, escrito fuera de ella, pasa a `load("res://…").miembro` (se compila al usarlo, no al abrir el menú);
`Clase.new(` igual; los tipos de firma (`x: Clase`, `-> Clase`, `Array[Clase]`, `as Clase`) se quitan. Lo que no se puede traducir solo
(`is Clase`, `const`/`enum` que la nombran, `extends`) se IMPRIME para hacerlo a mano.

  python3 cortar.py <familia> [--aplicar]      # familia = estadio_partido | ciudad | pantallas (de fam.json)
"""
import json,re,sys,os
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import io,contextlib
with contextlib.redirect_stdout(io.StringIO()):
    from dom import *
RAIZ=os.environ.get('GRAFO_RAIZ','/home/user/Dinastia/dinastia-godot')
fam=json.load(open(os.path.dirname(os.path.abspath(__file__))+'/fam.json'))['fam']
nombre_fam=sys.argv[1]; aplicar='--aplicar' in sys.argv
prot=set()
def sub(n):
    prot.add(n)
    for h in hijos[n]: sub(h)
for n,_ in fam[nombre_fam]: sub(n)
todas={nombre[x]:x for x in prot if x in nombre}
manual=[]; cambios=0; lineas_cambiadas=0
for res in sorted(scripts):
    if res in prot or res not in base: continue   # solo los que el menú compila (los demás ya se cargan al usarlos)
    p=RAIZ+'/'+res[6:]
    src=open(p,encoding='utf-8').read(); lineas=src.split('\n'); orig=list(lineas)
    for i,l in enumerate(lineas):
        s=l.strip()
        if s.startswith('#'): continue
        code=re.sub(r'#.*$','',l)
        code_nostr=re.sub(r'"[^"]*"','""',code)
        for C,P in todas.items():
            if not re.search(r'\b'+C+r'\b',code_nostr): continue
            if re.match(r'\s*(const|enum)\b',l) or re.search(r'\bis\s+'+C+r'\b',code_nostr) or re.match(r'\s*extends\b',l) or re.search(r'\bis_instance_of\b',code_nostr):
                manual.append((res,i+1,C,l.strip()[:110])); continue
            ld='load("%s")'%P
            n=lineas[i]
            n=re.sub(r'\s+as\s+'+C+r'\b','',n)
            n=re.sub(r'Array\['+C+r'(?:\.\w+)*\]','Array',n)
            n=re.sub(r'->\s*'+C+r'(?:\.\w+)*','-> Variant',n)
            decl=re.match(r'\s*(?:static\s+)?(?:var|func|for)\b',n) is not None or re.search(r'\bfunc\b',n) is not None
            n=re.sub(r':\s*'+C+r'(?:\.\w+)*(?=\s*(?:=|,|\)|$))','',n) if decl else n
            n=re.sub(r'(?<!")\b'+C+r'\b(?=\.)',ld,n)
            if n!=lineas[i] and ':=' in n: n=n.replace(':=','=',1)
            if re.search(r'(?<![\w"])'+C+r'\b',re.sub(r'"[^"]*"','""',re.sub(r'#.*$','',n))) and n!=lineas[i]:
                manual.append((res,i+1,C,'(queda) '+n.strip()[:100]))
            lineas[i]=n
    if lineas!=orig:
        cambios+=1; lineas_cambiadas+=sum(1 for a,b in zip(orig,lineas) if a!=b)
        if aplicar: open(p,'w',encoding='utf-8').write('\n'.join(lineas))
print('familia',nombre_fam,'· scripts',len(prot),'· archivos a tocar',cambios,'· líneas',lineas_cambiadas,'· a mano',len(manual))
for m in manual: print('  A MANO',m)
