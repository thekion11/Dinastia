#!/usr/bin/env python3
"""Parte un script de GDScript en capas de <= LIMITE líneas SIN cambiar su comportamiento.

Cada capa EXTIENDE a la anterior (`extends "res://…/x_p1.gd"`); la última conserva el nombre,
el `class_name` y la ruta del archivo original, así que nadie que use la clase se entera.
Todo lo que no es función (variables, constantes, señales, enums, clases internas) va
en las primeras capas; las funciones, en el orden original, detrás.

Una función de una capa baja que llama a otra de una capa alta (el análisis de GDScript no
la ve desde la base) se reescribe con su tipo completo:  `(self as Clase).f()`  /  `Clase.f()`.

  python3 herramientas/partir_gd.py <archivo.gd> [más…]        # informe, no escribe
  python3 herramientas/partir_gd.py --aplicar <archivo.gd> …   # escribe las capas
  python3 herramientas/partir_gd.py --todos                    # informe de los que pasan del límite

Lo que NO puede hacer solo (lo avisa): funciones de más de LIMITE líneas, y scripts sin
`class_name` con llamadas hacia capas altas.
"""
import os
import re
import subprocess
import sys

LIMITE = 450
PRESUPUESTO = 436            # deja sitio a la cabecera de cada capa
RAIZ = "dinastia-godot"      # raíz del proyecto de Godot (res://)


AUTOLOADS = {}


def autoloads():
    """{ruta del script: nombre del autoload} según project.godot."""
    res = {}
    try:
        texto = open(os.path.join(RAIZ, "project.godot"), encoding="utf-8").read()
    except OSError:
        return res
    sec = texto.split("[autoload]", 1)[-1].split("\n[", 1)[0]
    for m in re.finditer(r'^(\w+)="\*?res://(.+?)"', sec, re.M):
        res[RAIZ + "/" + m.group(2)] = m.group(1)
    return res


# ---------------------------------------------------------------- lectura

def enmascarar(linea, en_cadena=None):
    """Devuelve (código, en_cadena): la línea con cadenas y comentarios sustituidos por espacios
    (misma longitud), para buscar identificadores sin tocar textos."""
    out = []
    i = 0
    n = len(linea)
    q = en_cadena
    while i < n:
        c = linea[i]
        if q:
            out.append(" ")
            if c == "\\" and i + 1 < n:
                out.append(" ")
                i += 2
                continue
            if linea.startswith(q, i):
                out.append(" " * (len(q) - 1))
                i += len(q)
                q = None
                continue
            i += 1
            continue
        if c == "#":
            out.append(" " * (n - i))
            break
        if c in "\"'":
            q = c * 3 if linea.startswith(c * 3, i) else c
            out.append(" " * len(q))
            i += len(q)
            continue
        out.append(c)
        i += 1
    if q in ("\"", "'"):
        q = None            # una cadena simple no cruza la línea
    return "".join(out), q


def profundidad(codigo):
    return sum(codigo.count(c) for c in "([{") - sum(codigo.count(c) for c in ")]}")


RE_FUNC = re.compile(r"^(static\s+)?func\s+(\w+)")
RE_VAR = re.compile(r"^(?:@\w+(?:\(.*?\))?\s+)*(?:static\s+)?var\s+(\w+)")
RE_CONST = re.compile(r"^const\s+(\w+)")
RE_SIGNAL = re.compile(r"^signal\s+(\w+)")
RE_ENUM = re.compile(r"^enum\b")
RE_CLASE = re.compile(r"^class\s+(\w+)")
RE_CLASSNAME = re.compile(r"^class_name\s+(\w+)(?:\s+extends\s+(.+?))?\s*$")
RE_EXTENDS = re.compile(r"^extends\b")
RE_ANOT_SOLA = re.compile(r"^@\w+(?:\(.*\))?\s*$")
RE_HEADER_ANOT = re.compile(r"^@(tool|icon|static_unload)\b")


def clasificar(linea):
    """(tipo, nombre, estática) de una línea de columna 0, o None si no abre unidad."""
    if RE_CLASSNAME.match(linea):
        return ("cabecera", "class_name", False)
    if RE_EXTENDS.match(linea) or RE_HEADER_ANOT.match(linea):
        return ("cabecera", "extends", False)
    m = RE_FUNC.match(linea)
    if m:
        return ("func", m.group(2), bool(m.group(1)))
    for rx, nom in ((RE_VAR, 1), (RE_CONST, 1), (RE_SIGNAL, 1), (RE_CLASE, 1)):
        m = rx.match(linea)
        if m:
            return ("decl", m.group(nom), False)
    if RE_ENUM.match(linea):
        return ("decl", "enum", False)
    return None


def leer_unidades(lineas):
    """Divide el archivo en unidades: cabecera, decl y func. Cada una lleva delante los
    comentarios, anotaciones y líneas en blanco que la preceden."""
    unidades = []
    cur = None
    sostenido = []          # comentarios/blancos/anotaciones de columna 0 pendientes
    prof = 0
    cadena = None
    for linea in lineas:
        codigo, cadena_nueva = enmascarar(linea, cadena)
        en_continuacion = cadena is not None or prof > 0
        cadena = cadena_nueva
        if cur is not None and en_continuacion:
            cur["lineas"].append(linea)
            prof = max(0, prof + profundidad(codigo))
            continue
        vacia = linea.strip() == ""
        col0 = (not vacia) and linea[0] not in (" ", "\t")
        if cur is not None and not col0:
            if vacia:
                sostenido.append(linea)      # puede ser del cuerpo o de lo siguiente
                continue
            cur["lineas"].extend(sostenido)  # indentada: el cuerpo sigue
            sostenido = []
            cur["lineas"].append(linea)
            prof = max(0, prof + profundidad(codigo))
            continue
        if vacia or linea.startswith("#") or (RE_ANOT_SOLA.match(linea) and not RE_HEADER_ANOT.match(linea)):
            sostenido.append(linea)
            continue
        info = clasificar(linea) or ("otro", "", False)
        cur = {"tipo": info[0], "nombre": info[1], "estatica": info[2],
               "lineas": sostenido + [linea], "extra": linea}
        sostenido = []
        unidades.append(cur)
        prof = max(0, profundidad(codigo))
    return unidades, sostenido


# ---------------------------------------------------------------- reescritura de llamadas

def reescribir(lineas, nombres_inst, nombres_est, clase, propios, modo="tipo"):
    """Sustituye las referencias a funciones de capas altas. Devuelve (líneas, nº de cambios).
    modo «tipo»: `(self as Clase).f` / `Clase.f`; modo «call»: `call(&"f", …)` (sin class_name)."""
    if not nombres_inst and not nombres_est:
        return lineas, 0
    todos = sorted(nombres_inst | nombres_est, key=len, reverse=True)
    rx = re.compile(r"(?<![\w.$%&@])(self\.)?(" + "|".join(map(re.escape, todos)) + r")\b")
    cambios = 0
    salida = []
    cadena = None
    for linea in lineas:
        codigo, cadena_nueva = enmascarar(linea, cadena)
        cadena = cadena_nueva
        if not codigo.strip() or codigo.lstrip().startswith("signal "):
            salida.append(linea)        # los parámetros de una señal no son llamadas
            continue
        trozos = []
        ultimo = 0
        for m in rx.finditer(codigo):
            nombre = m.group(2)
            if nombre in propios:
                continue                    # un parámetro o variable local se llama igual
            antes = codigo[:m.start()].rstrip()
            if antes.endswith("func"):
                continue                    # es la declaración
            resto = codigo[m.end():]
            if modo == "call" and nombre not in nombres_est:
                if resto.lstrip().startswith("("):
                    cierre = resto.lstrip()[1:].lstrip()[:1] == ")"
                    nuevo = f'call(&"{nombre}"' + ("" if cierre else ", ")
                    ultimo_fin = m.end() + (len(resto) - len(resto.lstrip())) + 1
                    trozos.append(linea[ultimo:m.start()])
                    trozos.append(nuevo)
                    ultimo = ultimo_fin
                    cambios += 1
                    continue
                nuevo = f'Callable(self, &"{nombre}")'
            elif nombre in nombres_est:
                nuevo = f"{clase}.{nombre}"
            elif modo == "autoload":
                nuevo = f"{clase}.{nombre}"
            else:
                nuevo = f"(self as {clase}).{nombre}"
            trozos.append(linea[ultimo:m.start()])
            trozos.append(nuevo)
            ultimo = m.end()
            cambios += 1
        trozos.append(linea[ultimo:])
        salida.append("".join(trozos))
    return salida, cambios


def locales_de(lineas):
    """Nombres de parámetros y variables locales de una unidad (para no confundirlos con funciones)."""
    texto = "\n".join(enmascarar(l)[0] for l in lineas)
    nombres = set(re.findall(r"\bvar\s+(\w+)", texto))
    nombres |= set(re.findall(r"\bfor\s+(\w+)\s+in\b", texto))
    for m in re.finditer(r"\bfunc\s*\w*\s*\((.*?)\)", texto, re.S):
        for p in m.group(1).split(","):
            p = p.strip().split(":")[0].split("=")[0].strip()
            if p:
                nombres.add(p)
    return nombres


# ---------------------------------------------------------------- partir

def partir(ruta, aplicar):
    with open(ruta, encoding="utf-8") as f:
        lineas = f.read().split("\n")
    if lineas and lineas[-1] == "":
        lineas.pop()
    if len(lineas) <= LIMITE:
        return None
    unidades, cola = leer_unidades(lineas)
    avisos = []
    cab = [u for u in unidades if u["tipo"] == "cabecera"]
    decl = [u for u in unidades if u["tipo"] in ("decl", "otro")]
    funcs = [u for u in unidades if u["tipo"] == "func"]
    for u in unidades:
        if u["tipo"] == "otro":
            avisos.append(f"línea de columna 0 que no se reconoce: {u['extra'][:60]!r}")
    clase = None
    extiende = None
    cab_otras = []
    clase_externa = CLASE_EXTERNA
    for u in cab:
        for linea in u["lineas"]:
            m = RE_CLASSNAME.match(linea)
            if m:
                clase = m.group(1)
                if m.group(2):
                    extiende = m.group(2)
            elif RE_EXTENDS.match(linea):
                extiende = linea[len("extends"):].strip()
            elif linea.strip() and not linea.startswith("#"):
                cab_otras.append(linea)
    if clase is None and clase_externa:
        clase_para_llamadas = clase_externa
    else:
        clase_para_llamadas = clase
    preambulo = []
    for u in cab:
        for linea in u["lineas"]:
            if linea.startswith("#") or not linea.strip():
                preambulo.append(linea)
    # --- reparto en capas (cabecera + decl primero, luego funciones)
    capas = [[]]
    peso = [0]

    def meter(u):
        n = len(u["lineas"])
        if peso[-1] and peso[-1] + n > PRESUPUESTO:
            capas.append([])
            peso.append(0)
        capas[-1].append(u)
        peso[-1] += n
        if n > LIMITE:
            avisos.append(f"{u['nombre']}(): {n} líneas, pasa del límite por sí sola")

    peso[0] = len(preambulo) + len(cab_otras) + 3
    if ORDENAR:
        funcs = ordenar_por_dependencias(funcs)
    for u in decl + funcs:
        meter(u)
    capa_de = {}
    for i, c in enumerate(capas):
        for u in c:
            capa_de[id(u)] = i
    if len(capas) == 1:
        avisos.append("cabe en una capa: no hace falta partir")
        return {"capas": 1, "avisos": avisos, "cambios": 0}
    # --- reescritura de las llamadas hacia arriba
    inst_en = {}
    est_en = {}
    for u in funcs:
        (est_en if u["estatica"] else inst_en)[u["nombre"]] = capa_de[id(u)]
    cambios = 0
    textos = []
    for i, c in enumerate(capas):
        texto = []
        for u in c:
            sup_i = {n for n, k in inst_en.items() if k > i}
            sup_s = {n for n, k in est_en.items() if k > i}
            if sup_i or sup_s:
                if clase_para_llamadas is not None:
                    nuevas, k = reescribir(u["lineas"], sup_i, sup_s, clase_para_llamadas, locales_de(u["lineas"]))
                elif ruta in AUTOLOADS:
                    nuevas, k = reescribir(u["lineas"], sup_i, sup_s, AUTOLOADS[ruta], locales_de(u["lineas"]), "autoload")
                else:
                    if sup_s:
                        avisos.append("sin class_name y con funciones estáticas llamadas hacia arriba: revisar a mano")
                    nuevas, k = reescribir(u["lineas"], sup_i, sup_s, "?", locales_de(u["lineas"]), "call")
                cambios += k
                texto.extend(nuevas)
            else:
                texto.extend(u["lineas"])
        textos.append(texto)
    # --- cabeceras y escritura
    carpeta = os.path.dirname(ruta)
    raiz = ruta.split(RAIZ + "/", 1)[0] + RAIZ + "/" if (RAIZ + "/") in ruta else ""
    base = os.path.splitext(os.path.basename(ruta))[0]
    n = len(capas)

    def res(k):
        rel = os.path.relpath(os.path.join(carpeta, f"{base}_p{k}.gd"), raiz or ".")
        return "res://" + rel.replace(os.sep, "/")

    ficheros = []
    for i, texto in enumerate(textos):
        k = i + 1
        ultimo = k == n
        cabecera = []
        if k == 1:
            cabecera += preambulo
            cabecera += cab_otras
            if extiende:
                cabecera.append("extends " + extiende)
            cabecera.append(f"## (Parte 1 de {n} de `{base}.gd`: la norma de 450 líneas lo partió en capas, cada una "
                            f"extiende a la anterior; la última, `{base}.gd`, conserva la clase.)")
        else:
            if ultimo and clase:
                cabecera.append(f"class_name {clase}")
            cabecera.append(f'extends "{res(k - 1)}"')
            cabecera.append(f"## (Parte {k} de {n} de `{base}.gd`.)")
        cuerpo = cabecera + [""] + _quitar_blancos_iniciales(texto)
        if ultimo:
            cuerpo += cola
        destino = ruta if ultimo else os.path.join(carpeta, f"{base}_p{k}.gd")
        ficheros.append((destino, cuerpo))
        if len(cuerpo) > LIMITE and not any("por sí sola" in a for a in avisos):
            avisos.append(f"capa {k}: {len(cuerpo)} líneas")
    if aplicar:
        for destino, cuerpo in ficheros:
            with open(destino, "w", encoding="utf-8", newline="\n") as f:
                f.write("\n".join(cuerpo).rstrip("\n") + "\n")
    return {"capas": n, "avisos": avisos, "cambios": cambios,
            "mayor": max(len(c) for _, c in ficheros), "ficheros": [d for d, _ in ficheros]}


def _quitar_blancos_iniciales(texto):
    i = 0
    while i < len(texto) and texto[i].strip() == "":
        i += 1
    return texto[i:]


ORDENAR = False
CLASE_EXTERNA = None   # --clase X: la clase de la capa final cuando se vuelve a partir una capa suelta


def ordenar_por_dependencias(funcs):
    """Pone cada función DESPUÉS de las que usa (recorrido en profundidad, estable): así casi
    ninguna llamada va hacia una capa alta y hay menos reescrituras."""
    por_nombre = {u["nombre"]: u for u in funcs}
    if not por_nombre:
        return funcs
    rx = re.compile(r"(?<![\w.$%&@])(?:self\.)?(" + "|".join(map(re.escape, sorted(por_nombre, key=len, reverse=True))) + r")\b")
    llama = {}
    for u in funcs:
        vistos = []
        cadena = None
        for linea in u["lineas"][1:] if False else u["lineas"]:
            codigo, cadena = enmascarar(linea, cadena)
            if RE_FUNC.match(linea):
                codigo = codigo[codigo.find(")") + 1:] if ")" in codigo else ""
            for m in rx.finditer(codigo):
                if m.group(1) != u["nombre"] and m.group(1) not in vistos:
                    vistos.append(m.group(1))
        llama[u["nombre"]] = vistos
    orden, estado = [], {}
    def visitar(n):
        if estado.get(n):
            return
        estado[n] = 1
        for c in llama[n]:
            visitar(c)
        orden.append(por_nombre[n])
    for u in funcs:
        visitar(u["nombre"])
    return orden


def candidatos():
    out = subprocess.check_output(["git", "ls-files", "*.gd"]).decode().split("\n")
    res = []
    for f in out:
        if not f or f.endswith("dialogos_ciudad.gd") or re.search(r"_p\d+\.gd$", f):
            continue
        try:
            n = sum(1 for _ in open(f, encoding="utf-8", errors="ignore"))
        except OSError:
            continue
        if n > LIMITE:
            res.append((n, f))
    return [f for _, f in sorted(res, reverse=True)]


def main():
    AUTOLOADS.update(autoloads())
    args = sys.argv[1:]
    global ORDENAR, CLASE_EXTERNA
    ORDENAR = "--ordenar" in args
    if "--clase" in args:
        CLASE_EXTERNA = args[args.index("--clase") + 1]
        args = [a for a in args if a != CLASE_EXTERNA]
    aplicar = "--aplicar" in args
    if "--todos" in args:
        archivos = candidatos()
    else:
        archivos = [a for a in args if not a.startswith("--")]
    for f in archivos:
        r = partir(f, aplicar)
        if r is None:
            continue
        av = "; ".join(dict.fromkeys(r["avisos"])) if r["avisos"] else "sin avisos"
        print(f"{f}: {r['capas']} capas, {r['cambios']} llamadas reescritas, capa mayor {r.get('mayor', '-')} · {av}")


if __name__ == "__main__":
    main()
