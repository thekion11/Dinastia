#!/usr/bin/env python3
"""Baja modelos CC0 de Poly Haven (glTF 1K) a assets/cc0_modelos/<id>/ (sin clave; licencia CC0).
Uso: python3 herramientas/bajar_cc0_modelos.py [id ...]  (sin argumentos: la lista de abajo)."""
import json, os, re, sys, urllib.parse, urllib.request
LISTA = ["modern_arm_chair_01", "modern_wooden_cabinet", "modern_coffee_table_01"]
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "cc0_modelos")

## (12-11, SonarCloud S5144) Solo HTTPS y solo los servidores de Poly Haven: las direcciones salen de la respuesta de su API
## (contenido externo) y no deben poder apuntar a otro sitio. Y los archivos solo se escriben dentro de la carpeta del modelo.
HOSTS = {"api.polyhaven.com", "dl.polyhaven.org"}

def direccion_limpia(url):
    """La dirección rehecha con NUESTRO servidor (de la lista) y la ruta comprobada: sin «..», sin barras invertidas y sin puntos
    escritos en clave (%2e). (12-11, SonarCloud S7044: la ruta viene de la respuesta de la API y no debe poder salirse de ahí.)"""
    u = urllib.parse.urlparse(url)
    servidor = next((h for h in sorted(HOSTS) if h == u.hostname), None)
    if u.scheme != "https" or servidor is None or u.username or u.port not in (None, 443):
        raise ValueError("dirección no permitida: %r" % url)
    ruta = urllib.parse.unquote(u.path)
    if ".." in ruta.split("/") or "\\" in ruta or "%2e" in u.path.lower() or not ruta.startswith("/"):
        raise ValueError("ruta no permitida en la dirección: %r" % url)
    return "https://" + servidor + urllib.parse.quote(ruta)

def abrir(url):
    return urllib.request.urlopen(urllib.request.Request(direccion_limpia(url), headers={"User-Agent": "Mozilla/5.0"}))

def dentro(base, ruta):
    destino = os.path.realpath(os.path.join(base, ruta))
    if not destino.startswith(os.path.realpath(base) + os.sep):
        raise ValueError("ruta fuera de la carpeta del modelo: %r" % ruta)
    return destino

def bajar(url, destino):
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    with abrir(url) as r, open(destino, "wb") as f:
        f.write(r.read())

for ident in ((sys.argv[1:] or LISTA) if __name__ == "__main__" else []):
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
