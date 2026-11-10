#!/usr/bin/env python3
"""ESCUDOS ÚNICOS (10-11-2026, prueba M-062 «ningún escudo repetido»): tras los lotes de retoques (`_escudos_lote*.txt`) muchos clubes de los mismos colores
quedaron con la misma forma y el mismo patrón. Este paso mira las FIRMAS reales del escudo (las mismas de M-062: forma, patrón, colores, símbolo e iniciales) que
imprime `pruebas/herramienta_firmas_escudos.tscn` en la base pública y en el pack real (mismo orden: se emparejan línea a línea) y, para cada grupo repetido,
deja el primero como está y cambia el PATRÓN de los demás por uno libre. Los clubes que ningún lote retocó tienen prioridad (no se tocan).
Genera `aspecto_clubes/_escudos_unicos.txt`; lo corre `herramientas/aspecto_unicos.sh` (que repite hasta que no quede ninguno).
Uso: python3 herramientas/aspecto_unicos.py <firmas_base.txt> <firmas_real.txt>"""
import glob
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
DATOS = os.path.join(AQUI, "aspecto_clubes")
DESTINO = os.path.join(DATOS, "_escudos_unicos.txt")
PATRONES = ["liso", "banda", "franjas", "mitad", "cuartos", "aro", "chevron", "cruz", "rombos", "tablero", "banda_h", "borde", "interior", "barras",
            "escalera", "anillos", "puntas", "tercios_v", "tercios_h", "abanico", "escamas", "estrella", "ondas", "sol", "pila", "manchas", "trebol", "medialuna"]


def lotes() -> set:
    sal = set()
    for f in glob.glob(os.path.join(DATOS, "_escudos_lote*.txt")) + [os.path.join(DATOS, "_escudos_relleno.txt")]:
        if os.path.exists(f):
            for l in open(f, encoding="utf-8"):
                if l.strip() and not l.startswith("#"):
                    sal.add(l.split("|")[0].strip())
    return sal


def leer(ruta):
    return [l.strip().split("|") for l in open(ruta, encoding="utf-8") if l.startswith("SIG|")]


def main() -> int:
    base, real = leer(sys.argv[1]), leer(sys.argv[2])
    assert len(base) == len(real), (len(base), len(real))
    mutables = lotes()
    previos = {}
    if os.path.exists(DESTINO):
        for l in open(DESTINO, encoding="utf-8"):
            if l.strip() and not l.startswith("#"):
                c = l.split("|")
                previos[c[0]] = c[2]
    clubes = []
    for b, r in zip(base, real):
        clubes.append({"real": r[7], "forma": b[1], "patron": b[2], "c1": b[3], "c2": b[4], "sb": (b[5], b[6]), "sr": (r[5], r[6])})
    ## La firma tiene que ser única en la base pública (nombres ficticios) Y en el pack real (M-062 corre con el pack): mismas partes, distintas iniciales.
    firma = lambda c, modo, p=None: (c["forma"], p or c["patron"], c["c1"], c["c2"]) + c[modo]
    usadas = {"sb": {}, "sr": {}}
    cambios = dict(previos)
    for c in sorted(clubes, key=lambda c: (c["real"] in mutables, c["real"])):
        if any(firma(c, m) in usadas[m] for m in usadas):
            for p in PATRONES:
                if p != c["patron"] and all(firma(c, m, p) not in usadas[m] for m in usadas):
                    cambios[c["real"]] = p
                    c["patron"] = p
                    break
            else:
                print("sin patrón libre para", c["real"])
        for m in usadas:
            usadas[m][firma(c, m)] = c["real"]
    nuevos = len(cambios) - len(previos)
    with open(DESTINO, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("# Generado por herramientas/aspecto_unicos.sh (no editar a mano): patrón distinto para que ningún escudo se repita (M-062).\n")
        for n in sorted(cambios):
            fh.write("%s||%s||||||\n" % (n, cambios[n]))
    print("únicos: %d patrones cambiados (%d nuevos en esta vuelta)" % (len(cambios), nuevos))
    return 0


if __name__ == "__main__":
    sys.exit(main())
