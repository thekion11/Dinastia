"""Aplica DE VERDAD el corte de la familia CIUDAD 3D (3-11-2026): desde fuera de la familia, `Clase.algo` pasa a `Ciudad.de("Clase").algo`
(cargador perezoso `nucleo/carga_ciudad.gd`) y los tipos en firmas/`as`/`is` se quitan. Escribe `nucleo/carga_ciudad_rutas.gd` con nombre->ruta.
Uso: python3 aplicar.py [seco]   (con `seco` solo lista los cambios)"""
import os,re,sys,json
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from dom import *
S=os.path.dirname(os.path.abspath(__file__))
fam=json.load(open(S+'/fam.json'))['fam']
nodos=[n for n,_ in fam['ciudad']]
prot=set()
def sub(n):
    prot.add(n)
    for h in hijos[n]: sub(h)
for n in nodos: sub(n)
todas={nombre[x]:x for x in prot if x in nombre}
seco=len(sys.argv)>1
cambios=0; lineas_tot=0
for res in scripts:
    if res in prot or res.startswith('res://nucleo/carga_ciudad'): continue
    p=RAIZ+'/'+res[6:]
    src=open(p,encoding='utf-8').read(); orig=src
    lineas=src.split('\n')
    for C in todas:
        if not re.search(r'\b'+C+r'\b',src): continue
        ld='CargaCiudad.de("%s")'%C
        for i,l in enumerate(lineas):
            if not re.search(r'\b'+C+r'\b',l) or re.match(r'\s*(const|enum|class_name|extends)\b',l): continue
            n=l
            code,sep,com=n.partition(' ## ') if ' ## ' in n and n.count('"')%2==0 else (n,'','')
            n=code
            n=re.sub(r'\s+as\s+'+C+r'\b','',n)
            n=re.sub(r'\bis\s+'+C+r'\b','is Object',n)
            n=re.sub(r'Array\['+C+r'(?:\.\w+)*\]','Array',n)
            n=re.sub(r'->\s*'+C+r'(?:\.\w+)+','-> Variant',n)
            decl=re.match(r'\s*(?:static\s+)?(?:var|func|for)\b',n) is not None
            if decl: n=re.sub(r':\s*'+C+r'(?:\.\w+)+(?=\s*(?:=|,|\)|$))','',n)
            n=re.sub(r'\s+as\s+'+C+r'(?:\.\w+)+','',n)
            n=re.sub(r'->\s*'+C+r'\b','-> Variant',n)
            if decl: n=re.sub(r':\s*'+C+r'\b(?=\s*(?:=|,|\)|$))','',n)
            n=re.sub(r'(?<!")\b'+C+r'\b(?=\.)',ld,n)
            if n!=code and ':=' in n: n=n.replace(':=','=',1)
            n=n+sep+com
            if n!=l: lineas[i]=n; lineas_tot+=1
    src='\n'.join(lineas)
    if src!=orig:
        cambios+=1
        if not seco: open(p,'w',encoding='utf-8').write(src)
print('archivos',cambios,'líneas',lineas_tot,'clases',len(todas))
if not seco:
    rutas='\n'.join('\t"%s": "%s",'%(k,v) for k,v in sorted(todas.items()))
    open(RAIZ+'/nucleo/carga_ciudad_rutas.gd','w',encoding='utf-8').write('class_name CargaCiudadRutas\nextends RefCounted\n## GENERADO por herramientas/compilacion_menu/aplicar.py: clase de la CIUDAD 3D -> ruta (se carga al usarla, no al abrir el menú).\nconst RUTAS := {\n%s\n}\n'%rutas)
