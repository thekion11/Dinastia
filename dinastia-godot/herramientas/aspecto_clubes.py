#!/usr/bin/env python3
"""ORDEN 15 (27-10-2026): el aspecto de cada club real (escudo, uniforme, butacas) parecido al de verdad, sin copiarlo.
Lee `herramientas/aspecto_clubes/*.txt` (una línea por club, campos separados por «|», vacío = el valor de siempre) y los vuelca en la tabla
`ASPECTO_CLUB` de `datos/pack_real.json` (privado, con los nombres retocados). Línea:
  nombre|forma|patrón|siglas|camiseta|k1|k2|pantalón|medias|esc1|esc2|butaca1|butaca2
  forma/patrón: `Escudo.FORMAS`/`PATRONES` · camiseta: clave de `DisenosKit.DISENOS` · k1/k2: colores de la camiseta · esc1/esc2: del escudo
  (si no, k1/k2 y luego los del club) · butaca1/butaca2: del estadio (si no, los del escudo).
   cd dinastia-godot && python3 herramientas/aspecto_clubes.py [--comprobar]
Termina con «ASPECTO: N clubes, M fallos». Con --comprobar no escribe."""
import glob
import json
import os
import re
import sys

UNLEET = {"0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "8": "b", "9": "g"}
RUTA = "datos/pack_real.json"
CAMPOS = ["forma", "patron", "siglas", "camiseta", "k1", "k2", "pant", "med", "esc1", "esc2", "asi1", "asi2"]
HEX = re.compile(r"^#[0-9a-fA-F]{6}$")


def es_letra(c: str) -> bool:
    return c.isalpha()


def limpiar(n: str) -> str:
    s = ""
    for i, c in enumerate(n):
        if c in UNLEET and ((i > 0 and es_letra(n[i - 1])) or (i + 1 < len(n) and es_letra(n[i + 1]))):
            s += UNLEET[c]
        else:
            s += c
    return s


def disenos() -> set:
    t = open("ui/disenos_kit_p1.gd", encoding="utf-8").read()
    a = t.index("const DISENOS")
    return set(re.findall(r'^\t\["(\w+)", "', t[a:t.index("\n]", a)], re.M))


def listas(src: str, nombre: str) -> set:
    t = open(src, encoding="utf-8").read()
    a = t.index(nombre)
    b = t.index("]", t.index("[", a))
    return set(re.findall(r'"(\w+)"', t[a:b + 1]))


def main() -> int:
    comprobar = "--comprobar" in sys.argv
    pack = json.load(open(RUTA, encoding="utf-8"))
    tablas = pack["tablas"]
    clubes = [c[0] for c in tablas["DATA_P1"] + tablas["DATA_P2"]]
    clubes += [c[0] for l in tablas["PAISES_LIGAS"].values() for c in l["clubes"]]
    por_limpio = {limpiar(n): n for n in clubes}
    formas = listas("ui/escudo_p1.gd", "const FORMAS")
    patrones = listas("ui/escudo_p1.gd", "const PATRONES")
    kits = disenos()
    nuevo, fallos, vistos = {}, 0, set()
    for f in sorted(glob.glob("herramientas/aspecto_clubes/*.txt")):
        for n, linea in enumerate(open(f, encoding="utf-8").read().splitlines(), 1):
            if not linea.strip() or linea.startswith("#"):
                continue
            v = [x.strip() for x in linea.split("|")]
            v += [""] * (13 - len(v))
            real = v[0]
            clave = por_limpio.get(real)
            malo = None
            if clave is None:
                malo = "club desconocido"
            elif real in vistos:
                malo = "repetido"
            elif v[1] and v[1] not in formas:
                malo = "forma «%s»" % v[1]
            elif v[2] and v[2] not in patrones:
                malo = "patrón «%s»" % v[2]
            elif v[4] and v[4] not in kits:
                malo = "camiseta «%s»" % v[4]
            elif any(x and not HEX.match(x) for x in v[5:13]):
                malo = "color mal escrito"
            elif len(v[3]) > 3:
                malo = "siglas largas"
            if malo:
                print("FALLO %s:%d %s: %s" % (os.path.basename(f), n, real, malo))
                fallos += 1
                continue
            vistos.add(real)
            d = dict(zip(CAMPOS, v[1:13]))
            fila = {}
            if d["forma"] or d["patron"]:
                fila["escudo"] = [d["forma"], d["patron"]]
            if d["siglas"]:
                fila["siglas"] = d["siglas"]
            if d["camiseta"]:
                fila["camiseta"] = d["camiseta"]
            k = {a: d[b] for a, b in (("c1", "k1"), ("c2", "k2"), ("pant", "pant"), ("med", "med")) if d[b]}
            if k:
                fila["kit"] = k
            esc = [d["esc1"] or d["k1"], d["esc2"] or d["k2"]]
            if esc[0] and esc[1]:
                fila["esc"] = esc
            asi = [d["asi1"] or esc[0], d["asi2"] or esc[1]]
            if asi[0] and asi[1]:
                fila["asientos"] = asi
            nuevo[clave] = fila
    falta = [n for n in clubes if n not in nuevo]
    print("ASPECTO: %d de %d clubes con aspecto; sin él: %d" % (len(nuevo), len(clubes), len(falta)))
    if fallos == 0 and not comprobar:
        tablas["ASPECTO_CLUB"] = nuevo
        with open(RUTA, "w", encoding="utf-8", newline="") as fh:
            fh.write(json.dumps(pack, ensure_ascii=False, separators=(",", ":")))
    print("ASPECTO: %d clubes, %d fallos" % (len(nuevo), fallos))
    return 1 if fallos else 0


if __name__ == "__main__":
    sys.exit(main())
