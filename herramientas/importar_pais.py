#!/usr/bin/env python3
"""IMPORTAR UN PAÍS DESDE UNA TABLA (10-11-2026, orden 35 vía el líder; audit. de contenido §7): «un país = un formato de datos; todo lo demás, generado».

Entrada: `herramientas/paises/<COD>.csv` (UTF-8, separador «;»). Primero líneas `#clave=valor` con los datos del país, luego una fila por club:
  #seleccion=Turquía  #tier=1.0  #globo=lon,lat  #bandera=🇹🇷  #confed=uel,uecl   (copas a las que se apunta; «asia» etc. para otras confederaciones)
  #extra=no  (país que ya tiene sus tablas: no se escribe en paises_extra.json)
  #liga=nombre real con dígitos|nombre ficticio   #copa=nombre real|nombre ficticio   #nombres=a,b,c…   #apellidos=a,b,c…
  fila: real;ficticio;color1;color2;media;aforo;fundado;apodo;estadio;guiño   (el nombre real va LIMPIO: el dígito de «leetspeak» lo pone el script)
Salida (todo idempotente; se ejecuta solo, sin argumentos, y `base_ficticia.py` lo importa):
  · el PACK real (liga y copa con nombre real + clubes con dígitos) y la base ficticia (liga, copa y club con nombre ficticio),
  · `herramientas/aspecto_clubes/paises_csv.txt` (escudo único M-062, uniforme, siglas), `datos/estilos_clubes.json` (formación y estilo, sin pisar lo que ya hay),
  · `datos/paises_extra.json` → `paises[COD]` (selección, nivel, globo, bandera, bolsas de nombres, confederación), conservando lo demás,
  · la historia del club (fundación, apodo, estadio, guiño) y la arquitectura del estadio según su aforo.
Comprueba: nombres ficticios ≤16 caracteres y sin dígitos, sin repetir con ningún otro club, nombres reales sin repetir en el pack, escudos sin repetir.
SEGUNDA DIVISIÓN: `<COD>_2.csv` con solo `#liga=real|ficticia` y sus filas (cuelga de la fila del país; las reglas de ascenso van en `reglas_ascenso.gd`).
Para un país nuevo: copiar un CSV, rellenarlo y correr `python3 herramientas/base_ficticia.py` (que llama a este módulo)."""
import csv
import glob
import json
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
from ligas_europa_real import _limpio, _leet  # noqa: E402  (la misma convención de dígitos que el resto de ligas reales)

DATOS = os.path.join(os.path.dirname(AQUI), "dinastia-godot", "datos")
_FORM = ["4-4-2", "4-2-3-1", "4-3-3", "3-5-2", "4-4-2", "5-3-2", "4-3-3", "4-2-3-1"]
_EST = ["bloque", "equilibrado", "presion", "directo", "garra", "contra", "posesion", "vertical", "ofensivo"]
FORMAS = ["rombo", "octogono", "corona", "laurel", "frances", "curvo", "arco3", "hexalgo", "ojiva", "banderin", "estandarte", "doblepunta"]
PATRONES = ["estrella", "ondas", "rombos", "tablero", "sol", "escamas", "rayo", "cruz", "chevron", "abanico", "puntas"]


def leer_csv(ruta):
    meta, filas = {}, []
    with open(ruta, encoding="utf-8", newline="") as fh:
        for linea in fh:
            if linea.startswith("#") and "=" in linea:
                k, v = linea[1:].rstrip("\n").split("=", 1)
                meta[k.strip()] = v.strip()
            elif linea.strip() and not linea.startswith("#"):
                filas.append(next(csv.reader([linea], delimiter=";")))
    meta["pais"] = os.path.splitext(os.path.basename(ruta))[0]
    return meta, [f for f in filas if f[0] != "real"]


PAISES, SEGUNDAS, FILAS = {}, {}, []
for _ruta in sorted(glob.glob(os.path.join(AQUI, "paises", "*.csv"))):
    _m, _f = leer_csv(_ruta)
    ## `<COD>_2.csv` es la SEGUNDA división del país (mismo formato; solo `#liga` y las filas): sus clubes llevan la clave «COD_2».
    if _m["pais"].endswith("_2"):
        SEGUNDAS[_m["pais"][:-2]] = _m
    else:
        PAISES[_m["pais"]] = _m
    FILAS += [[_m["pais"]] + f[:2] + [f[2], f[3], int(f[4]), int(f[5]), int(f[6]), f[7], f[8], f[9]] for f in _f]
# FILAS: (país, real limpio, ficticio, c1, c2, media, aforo, fundado, apodo, estadio, guiño)

NUEVOS = [(f[0], f[1] if any(c.isdigit() for c in f[1]) else _leet(f[1]), f[2], f[3], f[4], f[5], f[6], _FORM[i % 8], _EST[i % 9]) for i, f in enumerate(FILAS)]
CLUBES = {_limpio(f[1]): f[2] for f in NUEVOS}
HISTORIA = {_limpio(f[1]): (f[7], f[8], f[9], f[10]) for f in FILAS}
ESTILOS = {f[2]: [f[7], f[8]] for f in NUEVOS}
LIGAS_FICTICIAS = {p: m["liga"].split("|")[1] for p, m in PAISES.items()}
COPAS_FICTICIAS = {p: m["copa"].split("|")[1] for p, m in PAISES.items()}
LIGAS2_FICTICIAS = {p: m["liga"].split("|")[1] for p, m in SEGUNDAS.items()}


def asegurar(real: dict) -> None:
    """Liga y copa REALES de cada país con sus clubes en el pack (reconstruye la lista en el mismo orden: idempotente)."""
    for pais, m in PAISES.items():
        clubes = [[n, c1, c2, media, aforo] for p, n, _f, c1, c2, media, aforo, _fo, _e in NUEVOS if p == pais]
        real["PAISES_LIGAS"][pais] = {"liga": m["liga"].split("|")[0], "clubes": clubes}
        real["COPA_NOM"][pais] = m["copa"].split("|")[0]
    for pais, m in SEGUNDAS.items():   ## la segunda cuelga de la fila de su país (ver `segundas_divisiones.py`)
        clubes = [[n, c1, c2, media, aforo] for p, n, _f, c1, c2, media, aforo, _fo, _e in NUEVOS if p == pais + "_2"]
        real["PAISES_LIGAS"][pais]["segunda"] = {"liga": m["liga"].split("|")[0], "clubes": clubes}


def estadios():
    """Arquitectura del estadio de cada club según su aforo (clave = nombre real limpio)."""
    from estadios_reales_p2 import e
    sal = {}
    for f in NUEVOS:
        a = f[6]
        sal[_limpio(f[1])] = e("ingles" if a < 8000 else ("rect" if a < 40000 else "oval"), 1 if a < 15000 else (2 if a < 40000 else 3),
                               "sin" if a < 8000 else ("parcial" if a < 40000 else "anillo"), False, "torres", "hormigon", "")
    return sal


def _escudos_ajenos():
    usados = set()
    for r in glob.glob(os.path.join(AQUI, "aspecto_clubes", "*.txt")):
        if os.path.basename(r) == "paises_csv.txt":
            continue
        for linea in open(r, encoding="utf-8"):
            c = linea.rstrip("\n").split("|")
            if not linea.startswith("#") and len(c) > 10:
                usados.add((c[1], c[2], c[9], c[10]))
    return usados


def aspecto():
    """Líneas de `aspecto_clubes/paises_csv.txt` (nombre|forma|patrón|siglas|camiseta|k1|k2|pant|med|esc1|esc2), con el escudo único frente a TODOS los demás."""
    sal, usados = [], _escudos_ajenos()
    for i, f in enumerate(NUEVOS):
        n = _limpio(f[1])
        letras = "".join(c for c in n if c.isalpha() and c.isascii() and c.isupper())[:3]
        if len(letras) < 2:
            letras = "".join(c for c in n if c.isascii() and c.isalpha()).upper()[:3]
        c1, c2 = f[3], f[4]
        fi, pa = i % len(FORMAS), (i // len(FORMAS) + i) % len(PATRONES)
        while (FORMAS[fi], PATRONES[pa], c1, c2) in usados:
            pa = (pa + 1) % len(PATRONES)
            if pa == (i // len(FORMAS) + i) % len(PATRONES):
                fi = (fi + 1) % len(FORMAS)
        usados.add((FORMAS[fi], PATRONES[pa], c1, c2))
        sal.append("|".join([n, FORMAS[fi], PATRONES[pa], letras, "franjas" if i % 3 == 0 else "liso", c1, c2, c2, c1, c1, c2]))
    return sal


def fila_extra(m):
    """`paises[COD]` de `paises_extra.json`."""
    lon, lat = (float(x) for x in m["globo"].split(","))
    fila = {"PAIS_SELECCION": m["seleccion"], "TIER_PAIS": float(m["tier"]), "GLOBO_PAIS": [lon, lat],
            "POOLS_EU": [m["nombres"].split(","), m["apellidos"].split(",")], "CONFED": m["confed"].split(",")}
    if m.get("bandera"):
        fila["BANDERA"] = m["bandera"]
    return fila


def comprobar() -> list:
    errores, vistos = [], {}
    for p, m in PAISES.items():
        for k in ("seleccion", "tier", "globo", "liga", "copa", "nombres", "apellidos", "confed"):
            if not m.get(k):
                errores.append("%s: falta #%s" % (p, k))
    for f in FILAS:
        fic = f[2]
        if len(fic) > 16 or any(c.isdigit() for c in fic):
            errores.append("%s: nombre ficticio inválido «%s»" % (f[0], fic))
        if fic in vistos or _limpio(f[1]) in vistos:
            errores.append("%s: repetido «%s»/«%s»" % (f[0], f[1], fic))
        vistos[fic] = vistos[_limpio(f[1])] = True
    ajenos = set()
    try:
        est = json.load(open(os.path.join(DATOS, "estilos_clubes.json"), encoding="utf-8"))
        ajenos = set(est) - set(ESTILOS)
    except OSError:
        pass
    errores += ["%s: «%s» ya lo usa otro club" % (f[0], f[2]) for f in FILAS if f[2] in ajenos]
    try:
        pack = json.load(open(os.path.join(DATOS, "pack_real.json"), encoding="utf-8"))["tablas"]["PAISES_LIGAS"]
        reales = {_limpio(c[0]): p for p, v in pack.items() if p not in PAISES for c in v["clubes"]}
        errores += ["%s: «%s» ya existe en %s" % (f[0], f[1], reales[f[1]]) for f in FILAS if f[1] in reales]
    except (OSError, KeyError):
        pass
    return errores


def escribir():
    ruta = os.path.join(AQUI, "aspecto_clubes", "paises_csv.txt")
    with open(ruta, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("# Generado por herramientas/importar_pais.py desde herramientas/paises/*.csv (no editar a mano).\n" + "\n".join(aspecto()) + "\n")
    r = os.path.join(DATOS, "estilos_clubes.json")
    est = json.load(open(r, encoding="utf-8"))
    for k, v in ESTILOS.items():
        est.setdefault(k, v)
    json.dump(est, open(r, "w", encoding="utf-8", newline="\n"), ensure_ascii=False, indent=1)
    r = os.path.join(DATOS, "paises_extra.json")
    ex = json.load(open(r, encoding="utf-8"))
    for p, m in PAISES.items():
        if m.get("extra") == "no":   ## país que ya trae sus tablas (los 24 del HTML): solo su liga y sus clubes entran
            ex["paises"].pop(p, None)
        else:
            ex["paises"][p] = fila_extra(m)
    ## Las selecciones de los países nuevos entran en la lista SELECCIONES (escalafón, convocatorias y torneos) si la base no las trae.
    base = json.load(open(os.path.join(DATOS, "tablas.json"), encoding="utf-8"))
    base = base.get("tablas", base).get("SELECCIONES", [])
    ex["listas"] = {"SELECCIONES": [m["seleccion"] for p, m in PAISES.items() if m.get("extra") != "no" and m["seleccion"] not in base]}
    json.dump(ex, open(r, "w", encoding="utf-8", newline="\n"), ensure_ascii=False, indent=1)
    print("importar_pais:", len(PAISES), "países,", len(FILAS), "clubes", comprobar() or "sin errores")


if __name__ == "__main__":
    escribir()
