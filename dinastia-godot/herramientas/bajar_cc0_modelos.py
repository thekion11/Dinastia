#!/usr/bin/env python3
"""Baja modelos CC0 de Poly Haven (glTF 1K) a assets/cc0_modelos/<id>/ (sin clave; licencia CC0).
Uso: python3 herramientas/bajar_cc0_modelos.py [id ...]  (sin argumentos: la lista de abajo)."""
import json, os, re, sys, urllib.parse, urllib.request
LISTA = ["modern_arm_chair_01", "modern_wooden_cabinet", "modern_coffee_table_01",
         ## (12-11, sesión 16) prensa, enfermería, utilería y pasillos
         "wall_clock", "korean_fire_extinguisher_01", "WetFloorSign_01", "metal_stool_02", "steel_frame_shelves_03", "worn_metal_rack"]
## Lado de las texturas: 512 px; las piezas pequeñas (se ven a menos de medio metro de pantalla) y la estantería de 5 materiales, 256 px (¼ de memoria).
PEQUENAS = {"wall_clock", "korean_fire_extinguisher_01", "WetFloorSign_01", "metal_stool_02", "steel_frame_shelves_03", "worn_metal_rack"}
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

def solo_color(carpeta, nombre_gltf):
    """Piezas pequeñas: solo la textura de color (fuera normal, rugosidad/metal y oclusión: a esa distancia no se notan y cuestan 2/3 de la memoria)."""
    ruta = dentro(carpeta, nombre_gltf)
    g = json.load(open(ruta, encoding="utf-8"))
    usadas = set()
    for m in g.get("materials", []):
        m.pop("normalTexture", None)
        m.pop("occlusionTexture", None)
        pbr = m.setdefault("pbrMetallicRoughness", {})
        if pbr.pop("metallicRoughnessTexture", None) is not None or "metallicFactor" not in pbr:
            ## Sin su mapa, el glTF entiende metal 1 y rugosidad 1 (gris apagado): un término medio de pieza pintada.
            pbr["metallicFactor"] = min(float(pbr.get("metallicFactor", 1.0)), 0.25)
            pbr["roughnessFactor"] = 0.55
        t = (m.get("pbrMetallicRoughness") or {}).get("baseColorTexture")
        if t is not None:
            usadas.add(g["textures"][t["index"]]["source"])
    for i, im in enumerate(g.get("images", [])):
        if i not in usadas and os.path.exists(dentro(carpeta, im["uri"])):
            os.remove(dentro(carpeta, im["uri"]))
    ## Se quitan las imágenes que ya nadie usa, renumerando texturas e índices.
    nuevas = [im for i, im in enumerate(g.get("images", [])) if i in usadas]
    mapa = {i: nuevas.index(im) for i, im in enumerate(g.get("images", [])) if i in usadas}
    texs = [t for t in g.get("textures", []) if t["source"] in usadas]
    mapa_t = {i: texs.index(t) for i, t in enumerate(g.get("textures", [])) if t["source"] in usadas}
    for t in texs:
        t["source"] = mapa[t["source"]]
    for m in g.get("materials", []):
        t = (m.get("pbrMetallicRoughness") or {}).get("baseColorTexture")
        if t is not None:
            t["index"] = mapa_t[t["index"]]
    g["images"], g["textures"] = nuevas, texs
    json.dump(g, open(ruta, "w", encoding="utf-8"), indent=1)

for ident in (sys.argv[1:] or LISTA):
    if not re.fullmatch(r"[A-Za-z0-9_]+", ident):
        raise ValueError("identificador de Poly Haven no válido: %r" % ident)
    with abrir("https://api.polyhaven.com/files/" + ident) as r:
        g = json.load(r)["gltf"]["1k"]["gltf"]
    carpeta = os.path.join(RAIZ, ident)
    bajar(g["url"], dentro(carpeta, os.path.basename(urllib.parse.urlparse(g["url"]).path)))
    for ruta, inc in g["include"].items():
        bajar(inc["url"], dentro(carpeta, ruta))
    from PIL import Image   ## texturas a 512 px (memoria en MEDIA: sin compresión VRAM los 1K cuestan ~45 MB)
    lado = 256 if ident in PEQUENAS else 512
    for f in os.listdir(os.path.join(carpeta, "textures")):
        im = Image.open(os.path.join(carpeta, "textures", f))
        if im.width > lado:
            im.resize((lado, lado), Image.LANCZOS).save(os.path.join(carpeta, "textures", f), quality=88)
    if ident in PEQUENAS:
        solo_color(carpeta, os.path.basename(urllib.parse.urlparse(g["url"]).path))
    print("ok", ident)
