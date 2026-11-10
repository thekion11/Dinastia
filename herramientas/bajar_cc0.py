#!/usr/bin/env python3
"""Baja texturas PBR CC0 de Poly Haven (https://polyhaven.com, licencia CC0, sin clave) a dinastia-godot/assets/cc0/<id>/{diff,nor,rough}.jpg a 1K.
   python3 herramientas/bajar_cc0.py            (todas las de LISTA)   |   python3 herramientas/bajar_cc0.py id1 id2
Sesión 7 (10-11): para que el vestuario del club se vea con materiales reales y distintos por país (`VestuarioRealista`). Quedan fuera de LFS (JPG pequeños)."""
import json, os, sys, urllib.request
LISTA = ["rubber_tiles", "hinoki_planks", "patterned_terracotta_tiling", "dark_wooden_planks",
         "beige_wall_001", "brick_wall_005", "clay_plaster", "floor_tiles_06",
         "herringbone_parquet", "beige_wall_002", "laminate_floor_02", "brushed_concrete_03", "granite_tile", "patterned_clay_plaster", "clay_floor_001", "patterned_clay_wall"]
DESTINO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "dinastia-godot", "assets", "cc0")
MAPAS = {"diff": "Diffuse", "nor": "nor_gl", "rough": "Rough"}
def pedir(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "dinastia-bajar-cc0"}), timeout=60).read()
for ident in (sys.argv[1:] or LISTA):
    archivos = json.loads(pedir("https://api.polyhaven.com/files/" + ident))
    carpeta = os.path.join(DESTINO, ident)
    os.makedirs(carpeta, exist_ok=True)
    for corto, clave in MAPAS.items():
        url = archivos[clave]["1k"]["jpg"]["url"]
        datos = pedir(url)
        with open(os.path.join(carpeta, corto + ".jpg"), "wb") as f:
            f.write(datos)
        print(ident, corto, len(datos) // 1024, "KB")
