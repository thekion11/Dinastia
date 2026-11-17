#!/usr/bin/env python3
"""Ningún nombre REAL en lo público (17-11-2026): la misma comprobación del banco (`revisar_build_publico.py`) dentro de la generación de la base.

Busca, dentro del texto de `tablas.json`, cada nombre completo (con espacio y ≥9 letras) de `datos/reales_lista.json`, `datos/creditos_fotos.txt`
y de las plantillas del pack. `base_ficticia.py` se detiene si hay alguna coincidencia."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ruta_segura import ruta_segura, RAIZ_REPO  # noqa: E402

DATOS = os.path.join(RAIZ_REPO, "dinastia-godot", "datos")


def nombres_reales(reales_pack=None):
    """Conjunto de nombres completos reales a vigilar."""
    n = set()
    with open(ruta_segura(os.path.join(DATOS, "reales_lista.json")), encoding="utf-8-sig") as f:
        for fila in json.load(f):
            n.add(str(fila.get("nombre", "")).strip())
    ruta = os.path.join(DATOS, "creditos_fotos.txt")
    if os.path.exists(ruta):
        with open(ruta_segura(ruta), encoding="utf-8") as f:
            for linea in f:
                if ": foto de " in linea:
                    n.add(linea.split(": foto de ")[0].strip())
    for filas in (reales_pack or {}).values():
        for fila in filas:
            n.add(fila.split("|")[0].strip())
    return sorted(x for x in n if " " in x and len(x) >= 9)


def encontrar(texto, reales_pack=None):
    """Lista de nombres reales que aparecen tal cual en `texto`."""
    return [x for x in nombres_reales(reales_pack) if x in texto]
