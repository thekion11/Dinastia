#!/usr/bin/env python3
"""Nacionalidades de los jugadores importados (17-11-2026): código de 3 letras DEL JUEGO (`visor/banderas.gd`, `Banderas.ISO`).

Wikipedia usa códigos y nombres que el juego no tiene (SPA, ROM, SER, «Argentina»…): `normalizar_pais` los traduce con una tabla de equivalencias y
devuelve None si no hay equivalente; eso va al informe de dudosos y NUNCA al pack. `normalizar_pack` corrige las filas ya metidas."""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ruta_segura import ruta_segura, RAIZ_REPO  # noqa: E402
from auditar_parecido_real import cargar, limpiar  # noqa: E402

## Códigos de nacionalidad ajenos o nombres completos (Wikipedia) → código de 3 letras del juego (`visor/banderas.gd`, tabla ISO).
EQUIVALENCIAS = {"SPA": "ESP", "ROM": "ROU", "SER": "SRB", "CTA": "CAF", "DRC": "COD", "ARGENTINA": "ARG", "URUGUAY": "URU", "PARAGUAY": "PAR",
                 "COLOMBIA": "COL", "CHILE": "CHI", "BRASIL": "BRA", "BRAZIL": "BRA", "ECUADOR": "ECU", "PERU": "PER", "PERÚ": "PER", "VENEZUELA": "VEN",
                 "MEXICO": "MEX", "MÉXICO": "MEX", "BOLIVIA": "BOL", "ESPAÑA": "ESP", "ITALIA": "ITA", "FRANCIA": "FRA", "ALEMANIA": "GER",
                 "GBR": "ENG", "NIG": "NGA", "CGO": "CGO", "ALL": "GER", "SWI": "SUI", "NET": "NED"}
_VALIDOS = None


def codigos_validos():
    """Los códigos de país con bandera del juego: las claves de `Banderas.ISO` (visor/banderas.gd)."""
    global _VALIDOS
    if _VALIDOS is None:
        with open(ruta_segura(os.path.join(RAIZ_REPO, "dinastia-godot", "visor", "banderas.gd")), encoding="utf-8") as f:
            t = f.read()
        a = t.index("const ISO")
        _VALIDOS = set(re.findall(r'"([A-Z]{3})":', t[a:t.index("\n}", a)]))
    return _VALIDOS


def normalizar_pais(codigo):
    """Código del juego para una nacionalidad de Wikipedia, o None si no hay equivalente (va al informe, nunca al pack)."""
    c = (codigo or "").strip().upper()
    c = EQUIVALENCIAS.get(c, c)
    return c if c in codigos_validos() else None


def normalizar_pack(pack_ruta):
    """Corrige las nacionalidades de las filas de esta herramienta (9 campos) ya metidas en el pack; lo desconocido pasa al país de la liga del club."""
    pack = cargar("pack_real.json")
    t = pack["tablas"]
    pais_club = {limpiar(c[0]): cod for cod, d in t["PAISES_LIGAS"].items() for c in d["clubes"]}
    pais_club.update({limpiar(c[0]): "CHI" for c in t["DATA_P1"] + t["DATA_P2"]})
    cambios, sin = 0, {}
    for club, filas in t["REALES"].items():
        for k, fila_txt in enumerate(filas):
            p = fila_txt.split("|")
            if len(p) < 9 or "m" not in p[8]:
                continue
            nuevo = normalizar_pais(p[4])
            if nuevo is None:
                sin[p[4]] = sin.get(p[4], 0) + 1
                nuevo = pais_club.get(limpiar(club), p[4])
                if "e" not in p[8]:
                    p[8] += "e"
            if nuevo != p[4] or "e" in p[8]:
                p[4] = nuevo
                filas[k] = "|".join(p)
                cambios += 1
    with open(ruta_segura(pack_ruta), "w", encoding="utf-8") as f:
        json.dump(pack, f, ensure_ascii=False, separators=(",", ":"))
    print("nacionalidades corregidas:", cambios, "; sin equivalencia:", sin)
