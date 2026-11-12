#!/usr/bin/env python3
"""Baja modelos CC0 de Poly Haven (glTF 1K) a assets/cc0_modelos/<id>/ (sin clave; licencia CC0).
Uso: python3 herramientas/bajar_cc0_modelos.py [id ...]  (sin argumentos: la lista de abajo)."""
import json, os, re, sys, urllib.parse, urllib.request
LISTA = ["modern_arm_chair_01", "modern_wooden_cabinet", "modern_coffee_table_01"]
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "cc0_modelos")

## (12-11, SonarCloud S5144) Solo HTTPS y solo los servidores de Poly Haven: las direcciones salen de la respuesta de su API
## (contenido externo) y no deben poder apuntar a otro sitio. Y los archivos solo se escriben dentro de la carpeta del modelo.
HOSTS = {"api.polyhaven.com", "dl.polyhaven.org"}

def abrir(url):
    u = urllib.parse.urlparse(url)
    if u.scheme != "https" or u.hostname not in HOSTS:
        raise ValueError("dirección no permitida: %r" % url)
    return urllib.request.urlopen(urllib.request.Request(urllib.parse.urlunparse(u), headers={"User-Agent": "Mozilla/5.0"}))

def dentro(base, ruta):
    destino = os.path.realpath(os.path.join(base, ruta))
    if not destino.startswith(os.path.realpath(base) + os.sep):
        raise ValueError("ruta fuera de la carpeta del modelo: %r" % ruta)
    return destino

def bajar(url, destino):
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    with abrir(url) as r, open(destino, "wb") as f:
        f.write(r.read())

for ident in (sys.argv[1:] or LISTA):
    if not re.fullmatch(r"[a-z0-9_]+", ident):
        raise ValueError("identificador de Poly Haven no válido: %r" % ident)
    with abrir("https://api.polyhaven.com/files/" + ident) as r:
        g = json.load(r)["gltf"]["1k"]["gltf"]
    carpeta = os.path.join(RAIZ, ident)
    bajar(g["url"], dentro(carpeta, os.path.basename(urllib.parse.urlparse(g["url"]).path)))
    for ruta, inc in g["include"].items():
        bajar(inc["url"], dentro(carpeta, ruta))
    from PIL import Image   ## texturas a 512 px (memoria en MEDIA: sin compresión VRAM los 1K cuestan ~45 MB)
    for f in os.listdir(os.path.join(carpeta, "textures")):
        im = Image.open(os.path.join(carpeta, "textures", f))
        if im.width > 512:
            im.resize((512, 512), Image.LANCZOS).save(os.path.join(carpeta, "textures", f), quality=88)
    print("ok", ident)
