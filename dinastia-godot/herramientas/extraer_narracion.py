#!/usr/bin/env python3
"""Extrae las plantillas de la narración (títulos y cuerpos de `noticia.emit`)
del código GDScript y las convierte en patrones de traducción.

Cada argumento se parte en trozos: los literales de texto quedan fijos y todo
lo demás (nombres, números, ternarios, llamadas) pasa a ser un hueco `(.+?)`.
Los formatos `"..." % [...]` cambian `%s`/`%d`/`%.1f` por huecos.

Salida: `datos/narracion_plantillas.json` con [regex, muestra con {1}{2}…,
archivo:línea]. Las traducciones viven aparte (`datos/narracion_traducida.json`)
y se cruzan por la regex, así que volver a extraer no pierde nada.

Uso: python3 herramientas/extraer_narracion.py
"""
import json
import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CARPETAS = ["nucleo", "ui", "visor"]
NARRATIVA = ["nucleo/prensa.gd", "nucleo/charlas.gd", "nucleo/vestuario.gd", "nucleo/redes.gd",
             "nucleo/carrera_jugador.gd"]


def argumentos(texto, ini):
    """Desde el paréntesis de apertura en `ini`, devuelve (lista de args, fin)."""
    prof = 0
    args = []
    actual = []
    i = ini
    cadena = None
    while i < len(texto):
        c = texto[i]
        if cadena:
            actual.append(c)
            if c == "\\":
                actual.append(texto[i + 1])
                i += 2
                continue
            if c == cadena:
                cadena = None
        elif c in "\"'":
            cadena = c
            actual.append(c)
        elif c in "([{":
            prof += 1
            if prof > 1:
                actual.append(c)
        elif c in ")]}":
            prof -= 1
            if prof == 0:
                args.append("".join(actual).strip())
                return args, i
            actual.append(c)
        elif c == "," and prof == 1:
            args.append("".join(actual).strip())
            actual = []
        else:
            actual.append(c)
        i += 1
    return args, i


def trozos_nivel_cero(expr, sep):
    """Parte `expr` por `sep` fuera de cadenas y paréntesis."""
    partes, actual, prof, cadena = [], [], 0, None
    i = 0
    while i < len(expr):
        c = expr[i]
        if cadena:
            actual.append(c)
            if c == "\\" and i + 1 < len(expr):
                actual.append(expr[i + 1])
                i += 2
                continue
            if c == cadena:
                cadena = None
        elif c in "\"'":
            cadena = c
            actual.append(c)
        elif c in "([{":
            prof += 1
            actual.append(c)
        elif c in ")]}":
            prof -= 1
            actual.append(c)
        elif prof == 0 and expr.startswith(sep, i):
            partes.append("".join(actual).strip())
            actual = []
            i += len(sep)
            continue
        else:
            actual.append(c)
        i += 1
    partes.append("".join(actual).strip())
    return partes


LITERAL = re.compile(r'^"((?:[^"\\]|\\.)*)"$')
FORMATO = re.compile(r"%(?:\.\d+)?[sdf]|%%")


def des_escapar(s):
    return s.encode("utf-8").decode("unicode_escape").encode("latin-1").decode("utf-8")


def a_patron(expr):
    """Devuelve (regex, muestra) o None si no hay ningún texto fijo."""
    expr = expr.strip()
    ## Formato: "texto %s" % [a, b]
    fmt = trozos_nivel_cero(expr, " % ")
    if len(fmt) == 2 and LITERAL.match(fmt[0]):
        s = des_escapar(LITERAL.match(fmt[0]).group(1))
        regex, muestra, n = "", "", 0
        pos = 0
        for m in FORMATO.finditer(s):
            regex += re.escape(s[pos:m.start()])
            muestra += s[pos:m.start()]
            if m.group(0) == "%%":
                regex += "%"
                muestra += "%"
            else:
                n += 1
                regex += "(.+?)"
                muestra += "{%d}" % n
            pos = m.end()
        regex += re.escape(s[pos:])
        muestra += s[pos:]
        return regex, muestra
    partes = trozos_nivel_cero(expr, " + ")
    regex, muestra, n, hay_texto = "", "", 0, False
    for p in partes:
        m = LITERAL.match(p)
        if m:
            s = des_escapar(m.group(1))
            regex += re.escape(s)
            muestra += s
            if re.search(r"[A-Za-zÁÉÍÓÚáéíóúñÑ]{3}", s):
                hay_texto = True
        else:
            ## Dos huecos seguidos se funden en uno.
            if regex.endswith("(.+?)"):
                continue
            n += 1
            regex += "(.+?)"
            muestra += "{%d}" % n
    if not hay_texto:
        return None
    return regex, muestra


def main():
    salida = []
    vistos = set()
    for carpeta in CARPETAS:
        for base, _, archivos in os.walk(os.path.join(RAIZ, carpeta)):
            for f in sorted(archivos):
                if not f.endswith(".gd"):
                    continue
                ruta = os.path.join(base, f)
                texto = open(ruta, encoding="utf-8").read()
                for m in re.finditer(r"noticia(?:_ojeo)?\.emit\(", texto):
                    args, _ = argumentos(texto, m.end() - 1)
                    linea = texto.count("\n", 0, m.start()) + 1
                    for k, a in enumerate(args[:2]):
                        pat = a_patron(a)
                        if pat is None:
                            continue
                        regex, muestra = pat
                        ## Los literales enteros ya los cubre la tabla directa
                        ## si son títulos; los cuerpos también van, como patrón.
                        if regex in vistos:
                            continue
                        vistos.add(regex)
                        salida.append({"re": "^" + regex + "$", "es": muestra,
                                       "de": "%s:%d" % (os.path.relpath(ruta, RAIZ), linea),
                                       "tipo": "titulo" if k == 0 else "cuerpo"})
    ## Las frases sueltas de los archivos de pura narración (prensa, vestuario,
    ## charlas, redes, carrera de jugador): todo literal con forma de frase.
    for rel in NARRATIVA:
        ruta = os.path.join(RAIZ, rel)
        if not os.path.exists(ruta):
            continue
        texto = open(ruta, encoding="utf-8").read()
        for m in re.finditer(r'"((?:[^"\\\n]|\\.)*)"', texto):
            lit = m.group(1)
            if len(lit.split()) < 3 or not re.search(r"[a-záéíóúñ]{3}", lit) or lit.startswith("res://"):
                continue
            pat = a_patron('"' + lit + '" % x') if "%" in lit else a_patron('"' + lit + '"')
            if pat is None:
                continue
            regex, muestra = pat
            ## Las comillas de cita se quedan: la pregunta se pinta con ellas.
            if regex in vistos:
                continue
            vistos.add(regex)
            linea = texto.count("\n", 0, m.start()) + 1
            salida.append({"re": "^" + regex + "$", "es": muestra, "de": "%s:%d" % (rel, linea), "tipo": "frase"})
    destino = os.path.join(RAIZ, "datos", "narracion_plantillas.json")
    json.dump(salida, open(destino, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("%d plantillas → %s" % (len(salida), os.path.relpath(destino, RAIZ)))


if __name__ == "__main__":
    sys.exit(main())
