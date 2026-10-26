#!/usr/bin/env python3
"""Pone en la cabecera de cada capa (`x_p3.gd`) QUÉ contiene y genera `docs/05_referencia/indice_de_capas.md`.

Un script partido por la norma de 450 líneas queda en varios archivos encadenados con `extends "res://…"`.
Los nombres `_pN` no dicen nada; esta herramienta escribe en la 2.ª/3.ª línea de cada capa las funciones
que trae y deja un índice por archivo original. Es idempotente: se puede relanzar tras cada reparto.

  python3 herramientas/indice_capas.py
  python3 herramientas/indice_capas.py --solo pruebas/   # solo las cadenas bajo esa carpeta (26-10): no
                                                       # toca las cabeceras del resto ni sus apartados del índice
"""
import os
import re
import subprocess

RAIZ = "dinastia-godot"
RE_EXT = re.compile(r'^extends\s+"res://(.+?)"', re.M)
RE_FUNC = re.compile(r"^(?:static\s+)?func\s+(\w+)", re.M)
## Acepta «Capa 3/10 de …» (lo que escribe esta herramienta) y «Capa 3 de 10» / «Parte 3/10».
RE_CAB = re.compile(r"^## [\(\[](?:Parte|Capa) \d+ ?(?:de|/) ?\d+")


def archivos():
    out = subprocess.check_output(["git", "ls-files", "--cached", "--others", "--exclude-standard", "*.gd"]).decode()
    return [f for f in out.split("\n") if f.startswith(RAIZ + "/") and os.path.isfile(f)]


def main():
    import sys
    solo = sys.argv[sys.argv.index("--solo") + 1] if "--solo" in sys.argv else ""
    texto = {f: open(f, encoding="utf-8").read() for f in archivos()}
    hijo_de = {}
    for f, t in texto.items():
        m = RE_EXT.search(t)
        if m:
            padre = RAIZ + "/" + m.group(1)
            if padre in texto and re.search(r"_p\d+\.gd$", padre):
                hijo_de[padre] = f           # `padre` es la capa anterior a `f`
    # una cadena empieza en un archivo que extiende a una capa; su hoja no es extendida por nadie
    hojas = [f for f, t in texto.items() if (m := RE_EXT.search(t)) and (RAIZ + "/" + m.group(1)) in hijo_de
             and f not in hijo_de]
    if solo:
        hojas = [f for f in hojas if f.startswith(RAIZ + "/" + solo)]
    indice = ["# Índice de capas del código (norma de 450 líneas)", "",
              "Los scripts que pasaban de 450 líneas se partieron en **capas** encadenadas: cada una extiende a la anterior",
              "y la última (sin `_pN` en el nombre) conserva la ruta y el `class_name` de siempre. Este archivo lo genera",
              "`herramientas/indice_capas.py`; no se edita a mano.", ""]
    cambiadas = 0
    for hoja in sorted(hojas):
        cadena = [hoja]
        while True:
            m = RE_EXT.search(texto[cadena[-1]])
            if not m:
                break
            padre = RAIZ + "/" + m.group(1)
            if padre not in texto or not re.search(r"_p\d+\.gd$", padre):
                break
            cadena.append(padre)
        cadena.reverse()                      # de la capa 1 a la hoja
        n = len(cadena)
        indice.append(f"## `{hoja[len(RAIZ) + 1:]}` · {n} capas")
        indice.append("")
        for k, f in enumerate(cadena, 1):
            funcs = RE_FUNC.findall(texto[f])
            vistas = ", ".join(funcs[:6]) + (f" … (+{len(funcs) - 6})" if len(funcs) > 6 else "")
            resumen = vistas or "variables, constantes y señales"
            nombre = os.path.basename(f)
            indice.append(f"{k}. `{nombre}` — {len(texto[f].splitlines())} líneas — {resumen}")
            cab = f"## [Capa {k}/{n} de `{os.path.basename(hoja)}`] {resumen}"
            lineas = texto[f].split("\n")
            for i in range(min(8, len(lineas))):
                if RE_CAB.match(lineas[i]):
                    if lineas[i] != cab:
                        lineas[i] = cab
                        cambiadas += 1
                    break
            texto[f] = "\n".join(lineas)
            open(f, "w", encoding="utf-8", newline="\n").write(texto[f])
        indice.append("")
    ruta_md = "docs/05_referencia/indice_de_capas.md"
    if solo:
        ## Se conservan tal cual los apartados de fuera de `solo`; los de dentro se rehacen.
        viejo = open(ruta_md, encoding="utf-8").read().split("\n## ")
        apartados = {}
        for bloque in viejo[1:]:
            clave = bloque.split("`")[1]
            if not clave.startswith(solo):
                apartados[clave] = "## " + bloque.rstrip("\n")
        nuevos = "\n".join(indice[6:]).split("\n## ")
        for bloque in nuevos:
            if bloque.strip():
                b = bloque if bloque.startswith("## ") else "## " + bloque
                apartados[b.split("`")[1]] = b.rstrip("\n")
        indice = indice[:6] + ["\n\n".join(apartados[k] for k in sorted(apartados))]
    open(ruta_md, "w", encoding="utf-8", newline="\n").write("\n".join(indice) + "\n")
    print(f"{len(hojas)} scripts en capas; {cambiadas} cabeceras actualizadas")


if __name__ == "__main__":
    main()
