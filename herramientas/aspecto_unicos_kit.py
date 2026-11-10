#!/usr/bin/env python3
"""UNIFORMES ÚNICOS POR LIGA (10-11-2026, como `aspecto_unicos.py` con los escudos): tras los lotes, 303 clubes compartían uniforme exacto con otro de SU liga.
Lee las FIRMAS reales de `pruebas/herramienta_firmas_kit.tscn` (REAL=1: `KIT|liga|diseño|c1|c2|pantalón|medias|nombre`, liga = país+división) y, para cada firma repetida en una liga,
deja el primero como está y cambia el DISEÑO de la camiseta (y, si hace falta, el pantalón y las medias) de los demás, SIN tocar los colores del club. Los clubes con uniforme escrito
a mano en un `_uniformes_<lote>.txt` no se tocan salvo que choquen exactamente con otro igual de ese tipo. Prefiere combinaciones que no existan en ninguna otra liga.
Genera `aspecto_clubes/_uniformes_unicos.txt` (acumulativo; lo corre `herramientas/aspecto_unicos_kit.sh` hasta que no quede ningún choque).
Uso: python3 herramientas/aspecto_unicos_kit.py <firmas_kit.txt>"""
import glob
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
DATOS = os.path.join(AQUI, "aspecto_clubes")
DESTINO = os.path.join(DATOS, "_uniformes_unicos.txt")
## Diseños sobrios de camiseta (2 colores), del más al menos parecido a un uniforme clásico.
DISENOS = ["franjas", "franjas_finas", "franjas_anchas", "bastones", "mitad", "aros", "aros_finos", "aros_anchos", "banda", "banda_cruzada", "banda_inversa", "sash", "diagonal",
           "hombros", "franja_pecho", "franja_central", "banda_baja", "canesu", "raglan", "v_ancha", "cuello_v", "chevron", "v_invertida", "doble_faja", "paneles_lado",
           "costados_rayados", "vertical3", "cruz", "cuadros_grandes", "liso"]
## Familias parecidas: lo primero que se prueba para cada diseño de partida.
CERCANOS = {"liso": ["franja_pecho", "cuello_v", "raglan", "franja_central", "hombros", "banda_baja", "canesu", "v_ancha"],
            "franjas": ["franjas_finas", "franjas_anchas", "bastones", "vertical3"],
            "aros": ["aros_finos", "aros_anchos"]}


def fijos() -> set:
    sal = set()
    for f in glob.glob(os.path.join(DATOS, "_uniformes*.txt")):
        if os.path.abspath(f) == os.path.abspath(DESTINO):
            continue
        for l in open(f, encoding="utf-8"):
            if l.strip() and not l.startswith("#"):
                sal.add(l.split("|")[0].strip())
    return sal


def leer(ruta):
    return [l.strip().split("|")[1:] for l in open(ruta, encoding="utf-8") if l.startswith("KIT|")]


def main() -> int:
    clubes = [{"liga": f[0], "dis": f[1], "c1": f[2], "c2": f[3], "p": f[4], "m": f[5], "n": f[6]} for f in leer(sys.argv[1])]
    previos = {}
    if os.path.exists(DESTINO):
        for l in open(DESTINO, encoding="utf-8"):
            if l.strip() and not l.startswith("#"):
                c = l.rstrip("\n").split("|")
                previos[c[0]] = (c[1], c[4], c[5])
    fijo = fijos()
    firma = lambda c, d=None, p=None, m=None: (c["liga"], d or c["dis"], c["c1"], c["c2"], p or c["p"], m or c["m"])
    en_liga, en_mundo = set(), {}
    cambios = dict(previos)
    sin_hueco = []
    for c in sorted(clubes, key=lambda c: (c["n"] not in fijo, c["n"])):   ## primero los fijos, luego el resto por nombre
        if firma(c) in en_liga:
            primeros = []
            base = CERCANOS.get(c["dis"], []) + [d for d in DISENOS if d != c["dis"]]
            for d in base:
                for p, m in ((c["p"], c["m"]), (c["c2"], c["m"]), (c["p"], c["c2"]), ("ffffff", c["m"]), ("111111", c["m"]), (c["c2"], c["c1"])):
                    f = firma(c, d, p, m)
                    if f not in en_liga:
                        primeros.append((f[1:] in en_mundo, len(primeros), d, p, m))
                if len([x for x in primeros if not x[0]]) >= 1:
                    break
            if not primeros:
                sin_hueco.append(c["n"])
            else:
                _, _, d, p, m = min(primeros)
                cambios[c["n"]] = (d, p, m)
                c["dis"], c["p"], c["m"] = d, p, m
        en_liga.add(firma(c))
        en_mundo[firma(c)[1:]] = c["n"]
    nuevos = len(cambios) - len(previos)
    with open(DESTINO, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("# Generado por herramientas/aspecto_unicos_kit.sh (no editar a mano): diseño, pantalón y medias distintos para que ningún uniforme se repita dentro de una liga.\n")
        for n in sorted(cambios):
            d, p, m = cambios[n]
            fh.write("%s|%s|||%s|%s||||\n" % (n, d, "#" + p if p and not p.startswith("#") else p, "#" + m if m and not m.startswith("#") else m))
    print("kits únicos: %d filas (%d nuevas en esta vuelta; %d fijos movidos; sin hueco: %s)" % (len(cambios), nuevos, sum(1 for n in cambios if n in fijo), sin_hueco))
    return 0


if __name__ == "__main__":
    sys.exit(main())
