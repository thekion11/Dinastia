"""PARTIR UN `match` GRANDE EN AUXILIARES (20-11-2026, avisos de complejidad). Uso, desde cualquier carpeta:
    python3 dinastia-godot/herramientas/partir_match.py <archivo.gd bajo dinastia-godot> <función> [casos por auxiliar=8]
Sirve SOLO si la función devuelve un valor (`-> X`, no void), tiene UN `match` en el nivel 1 y TODOS sus casos acaban en `return`.
Deja la función como despachador que prueba los auxiliares en orden (el primero que coincide gana, como el `match` original);
cada auxiliar vuelve a declarar los `var` del preámbulo que usa (conserva la inferencia de tipos). No parte si el preámbulo usa azar o await.
SIEMPRE: gdparse, `herramientas/compilar_todo.sh`, el banco y, si es una función pura, comparar con la versión de `git` (ver docs/01_metodo/REFACTOR_FORMA_CODIGO.md)."""
import re,sys,os
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))   ## raíz del proyecto de Godot
def ind(l): return len(l)-len(l.lstrip("\t"))
def partir(ruta,fn,trozo=8,verbo=None):
    L=open(ruta,encoding="utf-8").read().split("\n")
    i=next(k for k,l in enumerate(L) if re.match(rf"^(static )?func {re.escape(fn)}\(",l))
    est="static " if L[i].startswith("static ") else ""
    j=i+1
    while j<len(L) and (not L[j].strip() or L[j].startswith("\t")): j+=1
    while L[j-1].strip()=="" : j-=1
    # firma (puede ocupar varias líneas)
    f=i
    while not re.search(r":\s*(##.*)?$",L[f]): f+=1
    firma=" ".join(x.strip() for x in L[i:f+1])
    m=re.match(rf"^(?:static )?func {re.escape(fn)}\((.*)\)\s*->\s*([\w\[\]\.]+)\s*:",firma); assert m,firma
    params=[a.strip() for a in re.split(r",\s*(?![^\[\(]*[\]\)])",m.group(1)) if a.strip()]
    ret=m.group(2)
    cuerpo=L[f+1:j]
    k=next(n for n,l in enumerate(cuerpo) if re.match(r"^\tmatch .*:\s*$",l))
    pre=cuerpo[:k]; sujeto=re.match(r"^\tmatch (.*):\s*$",cuerpo[k]).group(1)
    # casos: líneas a indent 2 que no son comentario y acaban en ':' o 'return'; el resto del bloque a indent>=2
    resto=cuerpo[k+1:]
    fin=0
    while fin<len(resto) and (not resto[fin].strip() or ind(resto[fin])>=2): fin+=1
    casos_txt=resto[:fin]; cola=resto[fin:]
    while casos_txt and not casos_txt[-1].strip(): casos_txt.pop(); cola.insert(0,"")
    casos=[]; actual=[]
    for l in casos_txt:
        if ind(l)==2 and l.strip() and not l.strip().startswith("##") and actual and not (actual[-1].strip().startswith("##") and ind(actual[-1])==2 and not any(x.strip() and not x.strip().startswith("##") for x in actual)):
            casos.append(actual); actual=[]
        actual.append(l)
    if actual: casos.append(actual)
    # unir comentarios sueltos iniciales al caso siguiente (ya hecho por la condición); quitar casos vacíos
    chunks=[casos[n:n+trozo] for n in range(0,len(casos),trozo)]
    # nombres declarados en el preámbulo y parámetros
    pnames=[re.match(r"^(\w+)",a).group(1) for a in params]
    locales=[]; decl={}
    for l in pre:
        mm=re.match(r"^\tvar (\w+)",l)
        if mm: locales.append(mm.group(1)); decl[mm.group(1)]=l
    if any(re.search(r"rng|randi|randf|Azar|await",l) for l in decl.values()): raise SystemExit("preámbulo con azar o await: no se parte")
    tipo_local={}
    for l in pre:
        mm=re.match(r"^\tvar (\w+)\s*:\s*(\w+)",l)
        if mm: tipo_local[mm.group(1)]=mm.group(2)
    simple=re.fullmatch(r"\w+",sujeto) is not None
    sname=sujeto if simple else "clave"
    ayudas=[]; llamadas=[]
    base=verbo or fn
    for n,ch in enumerate(chunks,1):
        txt="\n".join("\n".join(c) for c in ch)
        usados_p=[a for a in params if re.search(rf"(?<![\w.]){re.escape(re.match(r'^(\w+)',a).group(1))}\b",txt)]
        usados_l=[v for v in locales if re.search(rf"(?<![\w.]){v}\b",txt)]
        # dependencias entre locales del preámbulo (c := m.mi_club() usa m)
        necesarios=[]
        def agregar(v):
            for w in locales:
                if w!=v and re.search(rf"(?<![\w.]){w}\b",decl[v].split("=",1)[1]) and w not in necesarios: agregar(w)
            if v not in necesarios: necesarios.append(v)
        for v in usados_l: agregar(v)
        extra_p=[a for a in params if any(re.search(rf"(?<![\w.]){re.escape(re.match(r'^(\w+)',a).group(1))}\b",decl[v].split("=",1)[1]) for v in necesarios) and a not in usados_p]
        usados_p=usados_p+extra_p
        sig_args=[a for a in usados_p]
        nombre=f"_{base.lstrip('_')}_{n}"
        call_args=[re.match(r"^(\w+)",a).group(1) for a in usados_p]
        llamadas.append((nombre,call_args))
        if sname not in [re.match(r"^(\w+)",x).group(1) for x in sig_args]: sig_args.append(f"{sname}: String")
        h=[f"{est}func {nombre}({', '.join(sig_args)}) -> Variant:"]+[decl[v] for v in necesarios]+[f"\tmatch {sname}:"]
        for c in ch:
            # los casos estaban a indent 2: ahora a indent 2 (dentro de match en un helper) -> igual
            h+=c
        h+=["\treturn null",""]
        ayudas.append("\n".join(h))
    # dispatcher
    # quitar del despachador los locales que ya no usa
    pre2=[]
    for l in pre:
        mm=re.match(r"^\tvar (\w+)",l)
        if mm:
            v=mm.group(1)
            otros="\n".join(x for x in pre if x is not l)+"\n"+"\n".join(cola)+"\n"+sujeto
            if not re.search(rf"(?<![\w.]){v}\b",otros): continue
        pre2.append(l)
    disp=L[i:f+1]+pre2+([] if simple else [f"\tvar clave := {sujeto}"])
    for nombre,args in llamadas:
        disp+= [f"\tvar r{nombre}: Variant = {nombre}({', '.join(args+([] if sname in args else [sname]))})", f"\tif r{nombre} != null:", f"\t\treturn r{nombre}"]
    disp+= [l[1:] if False else l for l in cola]
    nuevo=disp+[""]+"\n".join(ayudas).split("\n")
    L[i:j]=nuevo
    open(ruta,"w",encoding="utf-8").write("\n".join(L))
    print("ok",ruta,fn,"casos",len(casos),"->",len(chunks),"helpers")
if __name__=="__main__":
    partir(sys.argv[1],sys.argv[2],int(sys.argv[3]) if len(sys.argv)>3 else 8)
