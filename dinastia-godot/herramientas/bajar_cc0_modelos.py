#!/usr/bin/env python3
"""Baja modelos CC0 de Poly Haven (glTF 1K) a assets/cc0_modelos/<id>/ (sin clave; licencia CC0).
Uso: python3 herramientas/bajar_cc0_modelos.py [id ...]  (sin argumentos: la lista de abajo)."""
import json, os, sys, urllib.request
LISTA = ["modern_arm_chair_01", "modern_wooden_cabinet", "modern_coffee_table_01"]
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "cc0_modelos")

def abrir(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"}))

def bajar(url, destino):
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    with abrir(url) as r, open(destino, "wb") as f:
        f.write(r.read())

for ident in (sys.argv[1:] or LISTA):
    with abrir("https://api.polyhaven.com/files/" + ident) as r:
        g = json.load(r)["gltf"]["1k"]["gltf"]
    carpeta = os.path.join(RAIZ, ident)
    bajar(g["url"], os.path.join(carpeta, os.path.basename(g["url"])))
    for ruta, inc in g["include"].items():
        bajar(inc["url"], os.path.join(carpeta, ruta))
    from PIL import Image   ## texturas a 512 px (memoria en MEDIA: sin compresión VRAM los 1K cuestan ~45 MB)
    for f in os.listdir(os.path.join(carpeta, "textures")):
        im = Image.open(os.path.join(carpeta, "textures", f))
        if im.width > 512:
            im.resize((512, 512), Image.LANCZOS).save(os.path.join(carpeta, "textures", f), quality=88)
    print("ok", ident)
