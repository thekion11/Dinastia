#!/usr/bin/env python3
"""Trocea UNA función gigante de GDScript en funciones más pequeñas (norma de 450 líneas).

  python3 herramientas/trocear_funcion.py <archivo.gd> <función> [--objetivo 380] [--tipos x=int,y=Mundo] [--aplicar]

Corta el cuerpo en tramos entre sentencias de primer nivel y deja la función original como una
secuencia de llamadas `_funcion_1(...)`, `_funcion_2(...)`…  Las variables que cruzan de un tramo
a otro viajan como parámetros; las que un tramo reasigna o declara y luego se usan, vuelven en
un Array. Un `return` dentro de un tramo se convierte en `[true, valor]` y el llamador sale.
Si no puede deducir el tipo de una variable que cruza, la deja sin tipo (y avisa); `--tipos`
la fija a mano. Sin `--aplicar` solo informa.
"""
import re
import sys

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from partir_gd import enmascarar  # noqa: E402

ASIGNA = r"\s*(?:=|\+=|-=|\*=|/=|%=|\|=|&=|\^=|<<=|>>=)(?!=)"
TIPOS_LITERAL = [
    (r'^-?\d+$', "int"), (r'^-?\d*\.\d+$', "float"), (r'^(true|false)$', "bool"),
    (r'^"[^"]*"$', "String"), (r'^\[\]$', "Array"), (r'^\{\}$', "Dictionary"),
    (r'^str\(', "String"), (r'^int\(', "int"), (r'^float\(', "float"),
    (r'^(\w+)\.new\(', None), (r'^(Vector2|Vector3|Color)\(', None),
]


def tipo_de(decl):
    """Tipo de una declaración `var x: T = …` / `var x := …`, o None."""
    m = re.match(r"var\s+\w+\s*:\s*([\w\[\]\.]+)\s*=", decl)
    if m:
        return m.group(1)
    m = re.match(r"var\s+\w+\s*:=\s*(.+)$", decl)
    if not m:
        return None
    rhs = m.group(1).strip()
    for rx, t in TIPOS_LITERAL:
        mm = re.match(rx, rhs)
        if mm:
            return t or mm.group(1)
    return None


def dividir_matches(cuerpo, maximo):
    """Un `match` de primer nivel muy largo se reparte en varios `match` seguidos con la misma
    expresión (las ramas son excluyentes y no hay rama por defecto), para poder trocearlo."""
    salida = []
    i = 0
    n = len(cuerpo)
    while i < n:
        l = cuerpo[i]
        if re.match(r"\tmatch\s", l):
            j = i + 1
            while j < n and (cuerpo[j].strip() == "" or cuerpo[j].startswith("\t\t") or cuerpo[j].startswith("\t#")):
                j += 1
            while j > i + 1 and cuerpo[j - 1].strip() == "":
                j -= 1
            if j - i > maximo:
                ramas = []
                for k in range(i + 1, j):
                    if re.match(r"\t\t[^\t#\s]", cuerpo[k]):
                        ramas.append([cuerpo[k]])
                    elif ramas:
                        ramas[-1].append(cuerpo[k])
                    else:
                        ramas = [[cuerpo[k]]]
                if any(re.match(r'\t\t_\s*:', r[0]) for r in ramas):
                    sys.exit("el match tiene rama por defecto `_:`: no se puede dividir solo")
                grupo, peso = [], 0
                for r in ramas:
                    if grupo and peso + len(r) > maximo:
                        salida.append(l)
                        for q in grupo:
                            salida.extend(q)
                        grupo, peso = [], 0
                    grupo.append(r)
                    peso += len(r)
                salida.append(l)
                for q in grupo:
                    salida.extend(q)
                i = j
                continue
        salida.append(l)
        i += 1
    return salida


def en_lambda(mask):
    """Para cada línea, ¿está dentro del cuerpo de una lambda de varias líneas? (sus `return` no son de la función)"""
    marca = [False] * len(mask)
    pila = []
    for i, c in enumerate(mask):
        if not c.strip():
            continue
        ind = len(c) - len(c.lstrip("\t"))
        while pila and ind <= pila[-1]:
            pila.pop()
        marca[i] = bool(pila)
        if re.search(r"\bfunc\s*\(", c) and c.rstrip().endswith(":"):
            pila.append(ind)
    return marca


def main():
    args = sys.argv[1:]
    aplicar = "--aplicar" in args
    objetivo = 380
    tipos_manual = {}
    pos = []
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--objetivo":
            objetivo = int(args[i + 1])
            i += 2
            continue
        if a == "--tipos":
            for par in args[i + 1].split(","):
                k, v = par.split("=")
                tipos_manual[k] = v
            i += 2
            continue
        if not a.startswith("--"):
            pos.append(a)
        i += 1
    ruta, nombre = pos[0], pos[1]
    lineas = open(ruta, encoding="utf-8").read().split("\n")
    s = next(i for i, l in enumerate(lineas) if re.match(r"(static\s+)?func\s+" + re.escape(nombre) + r"\(", l))
    e = next((i for i in range(s + 1, len(lineas)) if re.match(r"(static\s+)?func\s", lineas[i])
              or (lineas[i] and lineas[i][0] not in " \t#" and not lineas[i].startswith(")"))), len(lineas))
    # los comentarios/blancos finales pertenecen a lo siguiente
    while e > s + 1 and (lineas[e - 1].strip() == "" or lineas[e - 1].startswith("#")):
        e -= 1
    cab = lineas[s]
    cuerpo = lineas[s + 1:e]
    estatica = cab.startswith("static")
    m = re.match(r"(?:static\s+)?func\s+\w+\((.*)\)\s*(?:->\s*([\w\[\]\.]+))?\s*:\s*$", cab)
    if not m:
        sys.exit("no entiendo la firma: " + cab)
    params_orig = []
    for p in re.split(r",\s*(?![^()\[\]]*[\)\]])", m.group(1)) if m.group(1).strip() else []:
        pn = re.match(r"\s*(\w+)\s*(?::\s*([\w\[\]\.]+))?", p)
        params_orig.append((pn.group(1), pn.group(2)))
    ret = m.group(2)
    cuerpo = dividir_matches(cuerpo, objetivo // 2)
    # sentencias de primer nivel
    inicios = []
    for i, l in enumerate(cuerpo):
        if re.match(r"\t[^\t#\s]", l) and not re.match(r"\t(elif|else)\b", l):
            inicios.append(i)
    # el comentario que precede a una sentencia viaja con ella
    corte_en = []
    for i in inicios:
        j = i
        while j > 0 and (cuerpo[j - 1].startswith("\t#") or cuerpo[j - 1].strip() == ""):
            j -= 1
        corte_en.append(j)
    # tramos voraces
    tramos = []
    ini = 0
    for k in range(1, len(corte_en)):
        if corte_en[k] - ini > objetivo:
            fin = corte_en[k - 1] if corte_en[k - 1] > ini else corte_en[k]
            tramos.append((ini, fin))
            ini = fin
    tramos.append((ini, len(cuerpo)))
    tramos = [t for t in tramos if t[1] > t[0]]
    if len(tramos) < 2:
        sys.exit("no hay dónde cortar (una sola sentencia gigante)")
    # variables conocidas
    conocidas = {n: t for n, t in params_orig}
    decl_tipos = {}
    salida_funcs = []
    todos_tipos_dudosos = []
    info = []
    for (a, b) in tramos:
        txt = cuerpo[a:b]
        mask = []
        cad = None
        for l in txt:
            c, cad = enmascarar(l, cad)
            mask.append(c)
        usados = set(re.findall(r"(?<![\w.$%&@])([A-Za-z_]\w*)", "\n".join(mask)))
        declaradas = []
        for l in txt:
            mm = re.match(r"\tvar\s+(\w+)", l)
            if mm:
                declaradas.append(mm.group(1))
                decl_tipos[mm.group(1)] = tipo_de(l.strip())
        reasignadas = [n for n in conocidas if n in usados and any(
            re.match(r"\s*" + re.escape(n) + ASIGNA, c) for c in mask)]
        entran = [n for n in conocidas if n in usados]
        lam = en_lambda(mask)
        hay_return = any(re.match(r"\s*return\b", c) and not lam[q] for q, c in enumerate(mask))
        hay_await = any(re.search(r"\bawait\b", c) for c in mask)
        info.append({"a": a, "b": b, "txt": txt, "mask": mask, "entran": entran, "reasig": reasignadas,
                     "decl": declaradas, "ret": hay_return, "await": hay_await})
        for n in declaradas:
            conocidas[n] = decl_tipos[n]
    # qué declaraciones hacen falta después
    for k, t in enumerate(info):
        despues = set()
        for u in info[k + 1:]:
            despues |= set(re.findall(r"(?<![\w.$%&@])([A-Za-z_]\w*)", "\n".join(u["mask"])))
        t["salen_decl"] = [n for n in t["decl"] if n in despues]
    for t in info:
        for n in t["entran"] + t["salen_decl"]:
            tp = tipos_manual.get(n) or conocidas.get(n)
            if tp is None and n not in todos_tipos_dudosos:
                todos_tipos_dudosos.append(n)
    # generar
    base = nombre
    nuevas = []
    llamador = [cab]
    for k, t in enumerate(info, 1):
        fn = f"{base}_{k}"
        pars = []
        for n in t["entran"]:
            tp = tipos_manual.get(n) or conocidas.get(n)
            pars.append(f"{n}: {tp}" if tp else n)
        vuelve = list(dict.fromkeys(t["reasig"] + t["salen_decl"]))
        proto = "[true, " if t["ret"] else "["
        # cuerpo del tramo: `:=` sobre variables sin tipo pasa a `=`
        sin_tipo = {n for n in t["entran"] if not (tipos_manual.get(n) or conocidas.get(n))}
        cuerpo_t = []
        lam_t = en_lambda(t["mask"])
        for q, (l, c) in enumerate(zip(t["txt"], t["mask"])):
            if sin_tipo and re.match(r"\s*var\s+\w+\s*:=", l):
                rhs = c.split(":=", 1)[1]
                if any(re.search(r"(?<![\w.])" + re.escape(n) + r"\b", rhs) for n in sin_tipo):
                    nuevo = re.match(r"\s*var\s+(\w+)", l).group(1)
                    sin_tipo.add(nuevo)
                    l = l.replace(":=", "=", 1)
            if t["ret"] and re.match(r"\s*return\b", c) and not lam_t[q]:
                ind = re.match(r"\s*", l).group(0)
                val = l.strip()[len("return"):].strip()
                l = f"{ind}return [true, {val if val else 'null'}]"
            cuerpo_t.append(l)
        sufijo = ""
        fin = "\treturn [false" + ("".join(f", {n}" for n in vuelve)) + "]" if t["ret"] else (
            "\treturn [" + ", ".join(vuelve) + "]" if vuelve else "")
        nuevas.append(f"## Tramo {k} de {len(info)} de `{nombre}` (la norma de 450 líneas la troceó).")
        nuevas.append(("static " if estatica else "") + f"func {fn}({', '.join(pars)}){' -> Array' if (vuelve or t['ret']) else ''}:")
        nuevas.extend(cuerpo_t)
        if fin:
            nuevas.append(fin)
        nuevas.append("")
        # llamador
        llam = f"{fn}({', '.join(t['entran'])})"
        if t["await"]:
            llam = "await " + llam
        if vuelve or t["ret"]:
            llamador.append(f"\tvar _r{k} = {llam}")
            off = 1 if t["ret"] else 0
            if t["ret"] and k == len(info) and ret and ret != "void":
                llamador.append(f"\treturn _r{k}[1]")   # el último tramo cierra la función
            elif t["ret"]:
                llamador.append(f"\tif _r{k}[0]:")
                llamador.append("\t\treturn" + (f" _r{k}[1]" if ret and ret != "void" else ""))
                off = 1
            for j, n in enumerate(vuelve):
                idx = j + (1 if t["ret"] else 0)
                if n in t["reasig"]:
                    llamador.append(f"\t{n} = _r{k}[{idx}]")
                else:
                    tp = tipos_manual.get(n) or conocidas.get(n)
                    llamador.append(f"\tvar {n}{': ' + tp if tp else ''} = _r{k}[{idx}]")
        else:
            llamador.append("\t" + llam)
    print(f"{ruta}: {nombre}() {e - s} líneas → {len(info)} tramos de {[t['b'] - t['a'] for t in info]} líneas")
    if todos_tipos_dudosos:
        print("  variables SIN tipo deducido (viajan sin tipo; fíjalas con --tipos si hace falta):", ", ".join(todos_tipos_dudosos))
    if aplicar:
        nuevo = lineas[:s] + nuevas + llamador + lineas[e:]
        open(ruta, "w", encoding="utf-8", newline="\n").write("\n".join(nuevo))
        print("  escrito")


if __name__ == "__main__":
    main()
