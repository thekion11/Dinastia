#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
MASCARA DE EQUIPACION PARA EL CUERPO QUATERNIUS
===============================================

Por que existe (25-9-2026): los jugadores del partido 3D se veian como
siluetas casi negras y con "texturas rotas". La causa: encima del cuerpo
Quaternius (piel + ropa interior oscura) se ponian cuatro piezas de ROPA
MEDIEVAL ("Peasant", marron, con desgarros) tenidas multiplicando por el
color del club. Marron x color = casi negro, y los desgarros dejaban ver la
piel a parches.

Aqui se genera, desde la geometria real del modelo, que pixel de su textura
es camiseta, pantalon, medias o botines. El shader `visor/equipacion_q.gdshader`
pinta la equipacion encima de la piel con los colores y el estilo del club
-sin mallas extra: cuatro mallas con esqueleto menos por jugador-.

Salidas (en `assets/characters/quaternius/`):
  * `equipacion_mascara.png`  R=camiseta  G=pantalon  B=medias  A=botines
  * `equipacion_coords.png`   R=x  G=y  B=z  de la pose de reposo (pose T),
    normalizadas. El shader las usa para los estampados (franjas, banda,
    aros, mitad...) y para saber que es pecho y que es espalda.

Como se decide cada zona: el modelo esta en pose T, de pie, con los pies en
y=0. Las alturas se midieron sobre los vertices (ver el historial de
`LEEME.md`, 25-9-2026): tobillo ~0,09 m, rodilla ~0,50, cadera ~0,95,
hombro ~1,45, base del cuello ~1,53; los brazos salen en horizontal desde
|x|~0,20 y la mano empieza en |x|~0,75.

    python3 herramientas/mascara_equipacion.py
"""
import json
import os

import numpy as np
from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR = os.path.join(RAIZ, "dinastia-godot", "assets", "characters", "quaternius")
MODELO = os.path.join(DIR, "Superhero_Male_FullBody.gltf")
MATERIAL = "MI_Superhero_Male"
LADO = 1024
# Pixeles de "sangrado" hacia fuera de cada isla de UV. Sin esto, el filtrado
# bilineal mezcla el borde de la isla con el fondo vacio y se ve una costura
# de piel en cada union de la malla.
SANGRADO = 6

# Rango de normalizacion de las coordenadas de reposo.
X_MIN, X_MAX = -0.95, 0.95
Y_MIN, Y_MAX = 0.0, 1.85
Z_MIN, Z_MAX = -0.25, 0.25


def leer_accesor(g, binario, indice):
    a = g["accessors"][indice]
    bv = g["bufferViews"][a["bufferView"]]
    off = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    n = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[a["type"]]
    dt = {5126: np.float32, 5123: np.uint16, 5125: np.uint32, 5121: np.uint8}[a["componentType"]]
    tam = np.dtype(dt).itemsize
    stride = bv.get("byteStride")
    cnt = a["count"]
    if stride and stride != n * tam:
        crudo = np.frombuffer(binario, dtype=np.uint8, count=stride * cnt, offset=off).reshape(cnt, stride)
        return crudo[:, : n * tam].copy().view(dt).reshape(cnt, n)
    return np.frombuffer(binario, dtype=dt, count=cnt * n, offset=off).reshape(cnt, n)


def zonas(x, y):
    """(camiseta, pantalon, medias, botines) en 0/1 para arrays de puntos de la
    pose de reposo. Una sola fuente de verdad para las cuatro zonas. Se evalua
    POR PIXEL con la posicion interpolada: por triangulo, los cortes salian en
    diente de sierra siguiendo las aristas de la malla."""
    ax = np.abs(x)
    brazo = (ax > 0.215) & (y > 1.22)
    camiseta = (brazo & (ax < 0.43)) | (~brazo & (y >= 1.0) & (y < 1.535))
    pantalon = ~brazo & (y >= 0.62) & (y < 1.0)
    medias = ~brazo & (y >= 0.085) & (y < 0.47)
    botines = ~brazo & (y < 0.085)
    return np.stack([camiseta, pantalon, medias, botines], axis=-1).astype(np.float64)


def main():
    g = json.load(open(MODELO, encoding="utf-8"))
    binario = open(os.path.join(DIR, g["buffers"][0]["uri"]), "rb").read()
    prim = None
    for m in g["meshes"]:
        for p in m["primitives"]:
            if g["materials"][p["material"]]["name"] == MATERIAL:
                prim = p
    if prim is None:
        raise SystemExit("no encuentro la primitiva con el material %s" % MATERIAL)
    pos = leer_accesor(g, binario, prim["attributes"]["POSITION"]).astype(np.float64)
    uv = leer_accesor(g, binario, prim["attributes"]["TEXCOORD_0"]).astype(np.float64)
    idx = leer_accesor(g, binario, prim["indices"]).reshape(-1, 3)

    mascara = np.zeros((LADO, LADO, 4), dtype=np.float64)
    coords = np.zeros((LADO, LADO, 3), dtype=np.float64)
    cubierto = np.zeros((LADO, LADO), dtype=bool)

    for tri in idx:
        p = pos[tri]
        t = uv[tri] * LADO
        x0, y0 = np.floor(t.min(axis=0)).astype(int)
        x1, y1 = np.ceil(t.max(axis=0)).astype(int)
        x0, y0 = max(x0, 0), max(y0, 0)
        x1, y1 = min(x1, LADO - 1), min(y1, LADO - 1)
        if x1 < x0 or y1 < y0:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        (ax, ay), (bx, by), (cx, cy) = t
        den = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(den) < 1e-12:
            continue
        w0 = ((by - cy) * (xs - cx) + (cx - bx) * (ys - cy)) / den
        w1 = ((cy - ay) * (xs - cx) + (ax - cx) * (ys - cy)) / den
        w2 = 1.0 - w0 - w1
        dentro = (w0 >= -0.02) & (w1 >= -0.02) & (w2 >= -0.02)
        if not dentro.any():
            continue
        py = ys[dentro].astype(int)
        px = xs[dentro].astype(int)
        punto = (w0[dentro, None] * p[0] + w1[dentro, None] * p[1] + w2[dentro, None] * p[2])
        mascara[py, px] = zonas(punto[:, 0], punto[:, 1])
        coords[py, px, 0] = (punto[:, 0] - X_MIN) / (X_MAX - X_MIN)
        coords[py, px, 1] = (punto[:, 1] - Y_MIN) / (Y_MAX - Y_MIN)
        coords[py, px, 2] = (punto[:, 2] - Z_MIN) / (Z_MAX - Z_MIN)
        cubierto[py, px] = True

    # Sangrado: cada pixel vacio toma el valor de un vecino cubierto.
    for _ in range(SANGRADO):
        nuevo = cubierto.copy()
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            vecino = np.roll(np.roll(cubierto, dy, axis=0), dx, axis=1)
            toma = vecino & ~nuevo
            if toma.any():
                mascara[toma] = np.roll(np.roll(mascara, dy, axis=0), dx, axis=1)[toma]
                coords[toma] = np.roll(np.roll(coords, dy, axis=0), dx, axis=1)[toma]
                nuevo |= toma
        cubierto = nuevo

    Image.fromarray((np.clip(mascara, 0, 1) * 255).astype(np.uint8), "RGBA").save(
        os.path.join(DIR, "equipacion_mascara.png"), optimize=True)
    Image.fromarray((np.clip(coords, 0, 1) * 255).astype(np.uint8), "RGB").save(
        os.path.join(DIR, "equipacion_coords.png"), optimize=True)
    tot = LADO * LADO
    print("camiseta %.1f%%  pantalon %.1f%%  medias %.1f%%  botines %.1f%%  (de la textura)" % tuple(
        100.0 * (mascara[:, :, i] > 0.5).sum() / tot for i in range(4)))


if __name__ == "__main__":
    main()
