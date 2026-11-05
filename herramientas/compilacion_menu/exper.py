import os,re,sys,json,shutil,subprocess,tempfile
TMP=tempfile.gettempdir()
sys.path.insert(0,os.path.dirname(__file__))
from dom import *
ORIG='/home/user/Dinastia/dinastia-godot'
S=os.path.dirname(os.path.abspath(__file__))
def preparar(dest):
    if os.path.exists(dest): shutil.rmtree(dest)  # NOSONAR(S8707): herramienta local: la ruta la da el propio dueño por línea de comandos
    os.makedirs(dest)
    for e in os.listdir(ORIG):
        if e in ('.godot',): continue
        o=os.path.join(ORIG,e); d=os.path.join(dest,e)
        if e in ('ui','visor','nucleo','minijuegos'): shutil.copytree(o,d)  # NOSONAR(S8707): herramienta local: la ruta la da el propio dueño por línea de comandos
        else: os.symlink(o,d)  # NOSONAR(S8707): herramienta local: la ruta la da el propio dueño por línea de comandos
    os.makedirs(dest+'/.godot')
    for e in os.listdir(ORIG+'/.godot'):
        o=os.path.join(ORIG,'.godot',e); d=os.path.join(dest,'.godot',e)  # NOSONAR(S8707): herramienta local: la ruta la da el propio dueño por línea de comandos
        if os.path.isdir(o): os.symlink(o,d)
        else: shutil.copy(o,d)
def subarbol(n,out):
    out.add(n)
    for h in hijos[n]: subarbol(h,out)
def transformar(dest,fam_nodos):
    prot=set()
    for n in fam_nodos: subarbol(n,prot)
    clases={nombre[n]:n for n in fam_nodos if n in nombre}
    # también las clases de TODO el subárbol (referencias a cualquiera de ellas desde fuera)
    todas={nombre[x]:x for x in prot if x in nombre}
    cambios=0
    for res in scripts:
        if res in prot: continue
        p=dest+'/'+res[6:]  # NOSONAR(S8707): herramienta local: la ruta la da el propio dueño por línea de comandos
        src=open(p,encoding='utf-8').read(); orig=src
        lineas=src.split('\n')
        for C,P in todas.items():
            if not re.search(r'\b'+C+r'\b',src): continue
            ld='load("%s")'%P
            for i,l in enumerate(lineas):
                if not re.search(r'\b'+C+r'\b',l) or re.match(r'\s*(const|enum)\b',l): continue
                n=l
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
                if n!=l and ':=' in n: n=n.replace(':=','=',1)
                lineas[i]=n
        src='\n'.join(lineas)
        if src!=orig:  # NOSONAR(S8707): herramienta local: la ruta la da el propio dueño por línea de comandos
            open(p,'w',encoding='utf-8').write(src); cambios+=1
    # sin inferencia local en TODO el proyecto (igual en el control): evita errores en cascada al volver Variant lo cortado
    for res in scripts:
        p=dest+'/'+res[6:]  # NOSONAR(S8707): herramienta local: la ruta la da el propio dueño por línea de comandos
        t=open(p,encoding='utf-8').read()
        t2=re.sub(r'\bvar\s+(\w+)\s*:=',r'var \1 =',t)
        t2=re.sub(r'(\bfor\s+\w+)\s*:=',r'\1 :=',t2)  # NOSONAR(S8707): herramienta local: la ruta la da el propio dueño por línea de comandos
        if t2!=t: open(p,'w',encoding='utf-8').write(t2)
    return cambios,len(prot)
def medir(dest,etiqueta):
    env=dict(os.environ); env['PATH']=os.path.join(TMP,'bin')+':'+env['PATH']  # NOSONAR(S8705): herramienta local: argumentos propios, subprocess sin shell
    r=subprocess.run(['godot','--headless','--path',dest,'--import'],capture_output=True,text=True,env=env,timeout=900)
    err=[l for l in (r.stdout+r.stderr).splitlines() if 'SCRIPT ERROR' in l or 'Parse Error' in l]
    pck=S+'/exp.pck'  # NOSONAR(S8705): herramienta local: argumentos propios, subprocess sin shell
    r=subprocess.run(['godot','--headless','--path',dest,'--export-pack','Windows',pck],capture_output=True,text=True,env=env,timeout=1200)
    r2=subprocess.run(['godot','--headless','--main-pack',pck,'--script',os.path.join(TMP,'mem3.gd')],capture_output=True,text=True,env=env,timeout=300,cwd=TMP)
    out=[l for l in r2.stdout.splitlines() if 'MEM3' in l]
    print(etiqueta,'| errores de compilación:',len(err)); [print('   ',e[:160]) for e in err[:4]]
    for l in out: print('   ',l)
    if os.path.exists(pck): os.remove(pck)
if __name__=='__main__':
    fam=json.load(open(S+'/fam.json'))['fam']
    nombre_exp=sys.argv[1]; fams=sys.argv[2].split('+')
    if not re.fullmatch(r'\w+',nombre_exp) or not all(re.fullmatch(r'\w+',f) for f in fams): sys.exit('nombre o familias no válidos')
    nodos=[n for f in fams for n,_ in fam[f]] if fams!=['ninguna'] else []
    dest=os.path.join(TMP,'exp_'+nombre_exp)
    preparar(dest)
    c,np_=transformar(dest,nodos)
    print('archivos tocados',c,'scripts en subárboles cortados',np_)
    medir(dest,nombre_exp)
