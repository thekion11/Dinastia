#!/usr/bin/env python3
"""ORDEN 15 f (27-10-2026): el PALMARÉS REAL de cada club (títulos por competición y año) en su historia.
Lee `herramientas/palmares/<clave>.txt` (una línea «año club» por título; ver `palmares/_LEEME.txt`) y lo entrega a `base_ficticia.py`, que lo guarda en
`HISTORIA_CLUBES[club]["palmares"] = {clave: [años]}` del pack (nombre real) y de la base ficticia (nombre ficticio).
Solo, comprueba los archivos:   python3 herramientas/palmares_clubes.py        Termina con «PALMARÉS: N títulos de M clubes, K fallos»."""
import glob
import os
import re
import sys

DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "palmares")
CLAVES = re.compile(r"^(liga_[A-Z]{3}|copa_[A-Z]{3}|conf_(lib|sud|ucl|uel|asia|afr|oce|conc)|mundial)$")


def leer(clubes_limpios):
    """({club limpio: {clave: [años]}}, [fallos]). La clave se escribe con «:» en los datos (liga_ESP.txt → liga:ESP)."""
    pal, fallos = {}, []
    for f in sorted(glob.glob(os.path.join(DIR, "[!_]*.txt"))):
        nombre = os.path.splitext(os.path.basename(f))[0]
        if not CLAVES.match(nombre):
            fallos.append("%s: clave de competición desconocida" % os.path.basename(f))
            continue
        clave = nombre.replace("_", ":", 1)
        vistos = set()
        for n, linea in enumerate(open(f, encoding="utf-8").read().splitlines(), 1):
            if not linea.strip() or linea.startswith("#"):
                continue
            partes = linea.split(" ", 1)
            if len(partes) != 2 or not partes[0].isdigit() or not 1880 <= int(partes[0]) <= 2030:
                fallos.append("%s:%d año mal escrito" % (os.path.basename(f), n))
                continue
            anio, club = int(partes[0]), partes[1].strip()
            if club not in clubes_limpios:
                fallos.append("%s:%d club desconocido «%s»" % (os.path.basename(f), n, club))
                continue
            if (anio, club) in vistos:
                fallos.append("%s:%d repetido" % (os.path.basename(f), n))
                continue
            vistos.add((anio, club))
            pal.setdefault(club, {}).setdefault(clave, []).append(anio)
    for d in pal.values():
        for v in d.values():
            v.sort()
    return pal, fallos


def tablas(CLUBES: dict):
    """(palmarés de la base ficticia, del pack): {nombre del club: {clave: [años]}}. Falla si hay errores."""
    pal, fallos = leer(set(CLUBES))
    if fallos:
        for e in fallos:
            print("ERROR palmares_clubes:", e)
        sys.exit(1)
    return {CLUBES[k]: v for k, v in pal.items()}, dict(pal)


def main() -> int:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import base_ficticia
    pal, fallos = leer(set(base_ficticia.CLUBES))
    for e in fallos:
        print("FALLO", e)
    n = sum(len(v) for d in pal.values() for v in d.values())
    print("PALMARÉS: %d títulos de %d clubes, %d fallos" % (n, len(pal), len(fallos)))
    return 1 if fallos else 0


if __name__ == "__main__":
    sys.exit(main())
