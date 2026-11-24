#!/usr/bin/env python3
"""TABLAS `const` DEL NÚCLEO PARA C++ (21-11-2026, orden 63, tanda 7).
Lee las constantes literales de `nucleo/*.gd` que usan las funciones puras de `nativo/src/puras_nucleo7.cpp` y escribe
`nativo/src/puras_nucleo7_tablas.inc` (cada tabla en el formato de texto de Variant de Godot, dentro de un texto crudo; C++ la lee con `str_to_var`, que distingue 1 de 1.0, así que los tipos coinciden con el GDScript; el JSON NO sirve: lo lee todo como flotante). Si cambia una tabla en GDScript, se vuelve a correr
(la prueba `probar_nativo_puras.gd` falla si no). Uso: python3 herramientas/generar_tablas_puras.py"""
import ast
import json
import os
import re

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
TABLAS = [  # (archivo de nucleo/, constante, nombre en C++)
    ("carrera_habilidad", "DETALLE", "DETALLE"),
    ("carrera_momentos", "TIPOS", "TIPOS_MOMENTO"),
    ("carrera_momentos", "DESENLACES", "DESENLACES"),
    ("finanzas", "CAMPANAS", "CAMPANAS"),
    ("logros_largo", "CATALOGO", "LOGROS"),
    ("retos", "LISTA", "RETOS"),
    ("ropero_dt", "CATALOGO", "ROPERO"),
    ("tactica", "CORNERS", "CORNERS"),
    ("tactica", "LIBRES", "LIBRES"),
    ("tienda_gasolinera", "SURTIDO", "SURTIDO"),
    ("expendedora", "BEBIDA", "BEBIDA"),
    ("expendedora", "SNACK", "SNACK"),
    ("expendedora", "AGUA", "AGUA"),
]


def a_var(v) -> str:
    """Un valor de Python como texto de Variant de Godot (str_to_var)."""
    if v is None:
        return "null"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        return repr(v)
    if isinstance(v, str):
        return json.dumps(v, ensure_ascii=False)
    if isinstance(v, list):
        return "[" + ", ".join(a_var(x) for x in v) + "]"
    return "{" + ", ".join("%s: %s" % (a_var(k), a_var(x)) for k, x in v.items()) + "}"


def literal(txt: str) -> str:
    """El texto de un literal de GDScript sin comentarios y con true/false/null de Python."""
    out, i, en_cad = [], 0, False
    while i < len(txt):
        c = txt[i]
        if en_cad:
            out.append(c)
            if c == "\\":
                out.append(txt[i + 1])
                i += 1
            elif c == '"':
                en_cad = False
        elif c == '"':
            en_cad = True
            out.append(c)
        elif c == "#":
            while i < len(txt) and txt[i] != "\n":
                i += 1
            continue
        else:
            out.append(c)
        i += 1
    s = "".join(out)
    parts = re.split(r'("(?:[^"\\]|\\.)*")', s)
    for k in range(0, len(parts), 2):
        parts[k] = re.sub(r"\btrue\b", "True", re.sub(r"\bfalse\b", "False", re.sub(r"\bnull\b", "None", parts[k])))
    return "".join(parts)


def cuerpo(src: str, nombre: str) -> str:
    m = re.search(r"^const %s\s*(?::\s*\w+\s*)?:?=\s*" % nombre, src, re.M)
    ini = m.end()
    prof, i, en_cad = 0, ini, False
    while True:
        c = src[i]
        if en_cad:
            if c == "\\":
                i += 1
            elif c == '"':
                en_cad = False
        elif c == '"':
            en_cad = True
        elif c == "#":
            while src[i] != "\n":
                i += 1
            continue
        elif c in "[{(":
            prof += 1
        elif c in "]})":
            prof -= 1
            if prof == 0:
                return src[ini:i + 1]
        i += 1


def main() -> None:
    sal = ["// GENERADO por herramientas/generar_tablas_puras.py: no editar a mano (tablas `const` del núcleo en formato Variant).\n"]
    for archivo, const, nombre in TABLAS:
        with open(os.path.join(RAIZ, "nucleo", archivo + ".gd"), encoding="utf-8") as f:
            src = f.read()
        valor = ast.literal_eval(literal(cuerpo(src, const)))
        js = a_var(valor)
        assert ")TXT\"" not in js
        sal.append('static const char *TABLA_%s = R"TXT(%s)TXT";\n' % (nombre, js))
    with open(os.path.join(RAIZ, "nativo", "src", "puras_nucleo7_tablas.inc"), "w", encoding="utf-8") as f:
        f.write("".join(sal))
    print("escrito puras_nucleo7_tablas.inc (%d tablas)" % len(TABLAS))


if __name__ == "__main__":
    main()
