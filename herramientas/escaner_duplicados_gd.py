#!/usr/bin/env python3
"""ESCÁNER DE BLOQUES REPETIDOS DE GDSCRIPT (13-11-2026, pulido de código; Sonar no analiza .gd).
Busca ventanas de N líneas iguales (sin espacios ni comentarios) que aparezcan en archivos DISTINTOS y lista los pares con más coincidencias.
  python3 herramientas/escaner_duplicados_gd.py dinastia-godot [ventana=10] [--sin-pruebas]
`--sin-pruebas` deja fuera `pruebas/` (casi todo lo repetido son escenas de captura y diagnóstico de un solo uso).
Resultado del 13-11 con ventana 10: 42 ventanas entre dos capturas, 21 entre dos diagnósticos…; en código del juego solo
`casa_recorrido`↔`explorador_estadio_p1` (crear el avatar y `_buscar_anim`, ~12 líneas), `pasajeros_bus`↔`pasajeros_teleferico`
(seguir una ruta, ciudad 3D apagada) e `inicio_p1`↔`principal_p13`: poco que ganar y riesgo en la primera persona, no se tocó."""
import collections
import glob
import os
import re
import sys

from ruta_segura import ruta_segura

MIN_CARACTERES = 200   # una ventana de líneas triviales («}», «pass»…) no cuenta


def normalizadas(ruta):
    salida = []
    with open(ruta_segura(ruta), encoding="utf-8", errors="replace") as f:
        for i, linea in enumerate(f):
            t = re.sub(r"\s+", " ", linea.split("##")[0].strip())
            if t and not t.startswith("#"):
                salida.append((i + 1, t))
    return salida


def escanear(raiz, ventana, con_pruebas=True):
    raiz = ruta_segura(raiz)
    archivos = [f for f in glob.glob(os.path.join(raiz, "**", "*.gd"), recursive=True)
                if "/terceros/" not in f and "/addons/" not in f and (con_pruebas or "/pruebas/" not in f)]
    indice = collections.defaultdict(list)
    for f in archivos:
        lineas = normalizadas(f)
        for k in range(len(lineas) - ventana + 1):
            indice[tuple(t for _, t in lineas[k:k + ventana])].append((f, lineas[k][0]))
    pares = collections.Counter()
    for clave, lugares in indice.items():
        archivos_con = {f for f, _ in lugares}
        if len(archivos_con) > 1 and sum(len(t) for t in clave) > MIN_CARACTERES:
            pares[tuple(sorted(archivos_con))] += 1
    return pares


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not args:
        sys.exit(__doc__)
    ventana = int(args[1]) if len(args) > 1 else 10
    for archivos, n in escanear(args[0], ventana, "--sin-pruebas" not in sys.argv).most_common(25):
        print(n, " | ".join(os.path.relpath(x, args[0]) for x in archivos))
