#!/usr/bin/env python3
"""RELLENO DE ESCUDOS (10-11-2026, calidad de los clubes de hoy): a los clubes de los países importados desde CSV (`paises_csv.txt`), de POR/BEL/CRO/DEN
(`ligas_europa_real.txt`) y de las segundas (`segundas_divisiones.txt`) que ningún lote de retoques dejó con emblema o letras (`_escudos*.txt`) les da unas LETRAS
(hasta 3, de su nombre) para que no salgan como un círculo liso. No toca forma, patrón ni colores (así sigue el escudo único de M-062).
Genera `aspecto_clubes/_escudos_relleno.txt`; idempotente. Uso: python3 herramientas/aspecto_relleno.py"""
import glob
import os
import unicodedata

AQUI = os.path.dirname(os.path.abspath(__file__))
DATOS = os.path.join(AQUI, "aspecto_clubes")
FUENTES = ["paises_csv.txt", "ligas_europa_real.txt", "segundas_divisiones.txt"]
PREFIJOS = {"FC", "FK", "IF", "IK", "BK", "SK", "AC", "AS", "CF", "SC", "KS", "NK", "HNK", "MFK", "TSC", "SV", "SG", "1.", "AFC", "UD", "CD", "CA", "RC", "US", "SS", "AEL"}


def plano(t: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFD", t) if unicodedata.category(c) != "Mn")


def letras(nombre: str) -> str:
    palabras = [p for p in plano(nombre).replace("-", " ").replace("/", " ").split() if p.upper().strip(".") not in PREFIJOS]
    base = palabras[0] if palabras else plano(nombre)
    base = "".join(c for c in base.upper() if c.isalpha() and c.isascii())
    return base[:3] if len(base) >= 2 else "".join(c for c in plano(nombre).upper() if c.isalpha() and c.isascii())[:3]


def cubiertos() -> set:
    vistos = set()
    for f in glob.glob(os.path.join(DATOS, "_escudos*.txt")):
        if os.path.basename(f) == "_escudos_relleno.txt":
            continue
        for l in open(f, encoding="utf-8"):
            c = [x.strip() for x in l.split("|")] + ["", "", "", "", ""]
            if l.strip() and not l.startswith("#") and (c[3] or c[4]):   ## ya tiene emblema o letras
                vistos.add(c[0])
    return vistos


def main():
    hechos = cubiertos()
    sal = ["# Generado por herramientas/aspecto_relleno.py (no editar a mano): letras del escudo de los clubes que ningún lote de retoques cubrió."]
    for fuente in FUENTES:
        for l in open(os.path.join(DATOS, fuente), encoding="utf-8"):
            if not l.strip() or l.startswith("#"):
                continue
            c = l.rstrip("\n").split("|")
            nombre = c[0]
            if nombre in hechos or (len(c) > 14 and c[14]) or len(letras(nombre)) < 2:
                continue
            sal.append("%s||||%s|||" % (nombre, letras(nombre)))
            hechos.add(nombre)
    open(os.path.join(DATOS, "_escudos_relleno.txt"), "w", encoding="utf-8", newline="\n").write("\n".join(sal) + "\n")
    print("relleno:", len(sal) - 1, "clubes con letras")


if __name__ == "__main__":
    main()
