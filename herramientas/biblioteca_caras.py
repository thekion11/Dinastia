#!/usr/bin/env python3
"""BIBLIOTECA MODULAR DE CARAS Y PELOS (5-10-2026).

Pedido del usuario: «los pelos y las caras que estás creando, guárdalas para que
los personajes sean modulares (como el personaje que crea el jugador) y tener
más variantes; reciclar para tener más alternativas».

CARAS: cada cara de la biblioteca es una MEZCLA de 4 jugadores reales del mismo
tono de piel (forma 3D promediada y textura promediada en un mapa común), así
que no es la cara de nadie: es una persona nueva. Nunca se pone la cara de un
jugador real en otro personaje.
    - forma: media de las 4 mallas (espacio de la malla canónica de MediaPipe);
    - textura: la piel replicada de cada uno (motor_caras) llevada triángulo a
      triángulo al mapa UV de la malla canónica, igualada a SU tono y promediada.
PELOS: cortes medidos en las fotos (forma: alto, lados, rizo, largo, nacimiento),
sin color ni nada de la persona; el color se elige aparte.

Salida:
    datos/biblioteca_caras.json   {"cara_000": {"m", "a", "s", "iris", "tono"}, ...}
    recursos/caras_biblioteca/cara_NNN.jpg  (256 px)
    datos/biblioteca_pelos.json   {"pelo_00": {corte, alto, lados, rizo, largo, linea, ...}}

    python3 herramientas/biblioteca_caras.py canonical_face_model.obj [caras_por_tono]
"""
import base64
import json
import os
import random
import sys

import cv2
import numpy as np
from PIL import Image

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "dinastia-godot")
MALLAS = os.path.join(RAIZ, "datos", "caras_reales_mallas.json")
TOPO = os.path.join(RAIZ, "datos", "cara_malla_topologia.json")
SALIDA_CARAS = os.path.join(RAIZ, "datos", "biblioteca_caras.json")
SALIDA_PELOS = os.path.join(RAIZ, "datos", "biblioteca_pelos.json")
CARPETA = "recursos/caras_biblioteca"
LADO = 256
N = 468
MEZCLA = 4  # caras reales por cara de la biblioteca
# Tonos de piel (por claridad de la piel medida), de claro a oscuro.
TONOS = [(175, 999), (150, 175), (125, 150), (100, 125), (80, 100), (0, 80)]


def lum(h):
    return 0.299 * int(h[1:3], 16) + 0.587 * int(h[3:5], 16) + 0.114 * int(h[5:7], 16)


def uv_canonico(obj, n_total, lazo):
    """UV por vértice de la malla canónica (el OBJ los da por esquina de
    triángulo) y, para el anillo, el UV del borde empujado hacia fuera."""
    vt, cara_vt = [], {}
    for linea in open(obj, encoding="utf-8"):
        p = linea.split()
        if p and p[0] == "vt":
            vt.append((float(p[1]), 1.0 - float(p[2])))
        elif p and p[0] == "f":
            for esq in p[1:4]:
                v, t = esq.split("/")[:2]
                cara_vt[int(v) - 1] = int(t) - 1
    uv = np.zeros((n_total, 2))
    for i in range(N):
        uv[i] = vt[cara_vt[i]]
    centro = uv[:N].mean(0)
    for k, b in enumerate(lazo):
        uv[N + k] = centro + (uv[b] - centro) * 1.12
    # Margen dentro del mapa.
    mn, mx = uv.min(0), uv.max(0)
    return (uv - mn) / (mx - mn) * 0.94 + 0.03


def llevar_al_mapa(img, uv_src, uv_dst, tris):
    """La textura de una cara (UV en su foto) al mapa común, triángulo a triángulo."""
    h, w = img.shape[:2]
    out = np.zeros((LADO, LADO, 3), np.float32)
    peso = np.zeros((LADO, LADO), np.float32)
    for t in tris:
        s = np.float32([[uv_src[i, 0] * w, uv_src[i, 1] * h] for i in t])
        d = np.float32([[uv_dst[i, 0] * LADO, uv_dst[i, 1] * LADO] for i in t])
        r = cv2.boundingRect(d)
        if r[2] <= 0 or r[3] <= 0:
            continue
        d_loc = d - np.float32([r[0], r[1]])
        m = cv2.getAffineTransform(s, d_loc)
        trozo = cv2.warpAffine(img, m, (r[2], r[3]), flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_REFLECT)
        mask = np.zeros((r[3], r[2]), np.float32)
        cv2.fillConvexPoly(mask, np.int32(d_loc), 1.0)
        y0, x0 = r[1], r[0]
        y1, x1 = min(y0 + r[3], LADO), min(x0 + r[2], LADO)
        if y1 <= y0 or x1 <= x0 or y0 < 0 or x0 < 0:
            continue
        mk = mask[:y1 - y0, :x1 - x0]
        out[y0:y1, x0:x1] = out[y0:y1, x0:x1] * (1 - mk[..., None]) + trozo[:y1 - y0, :x1 - x0] * mk[..., None]
        peso[y0:y1, x0:x1] = np.maximum(peso[y0:y1, x0:x1], mk)
    return out, peso


def decodificar(e, n):
    a = np.frombuffer(base64.b64decode(e["m"]), "<i2").reshape(n, 5).astype(float)
    return a[:, :3], a[:, 3:5] / 32767.0


def caras(obj, por_tono):
    m = json.load(open(MALLAS, encoding="utf-8"))
    t = json.load(open(TOPO, encoding="utf-8"))
    n = t["n"]
    tris = np.array(t["tri"]).reshape(-1, 3)
    # El lazo del borde = vértices N.. del anillo; su vértice de origen no se
    # guarda en la topología: se recupera como el de la cara más cercano.
    lazo = []
    ej = next(v for v in m.values() if v.get("a") and not v.get("mala"))
    forma0, _ = decodificar(ej, n)
    for k in range(n - N):
        d = ((forma0[:N] - forma0[N + k]) ** 2).sum(1)
        lazo.append(int(np.argmin(d)))
    uv_dst = uv_canonico(obj, n, lazo)
    rnd = random.Random(2026)
    salida = {}
    os.makedirs(os.path.join(RAIZ, CARPETA), exist_ok=True)
    def boca_cerrada(e):
        f, _ = decodificar(e, n)
        alto = abs(f[10, 1] - f[152, 1])
        return abs(f[13, 1] - f[14, 1]) < alto * 0.045
    buenas = [k for k, v in m.items() if v.get("a") and v.get("s") and not v.get("mala")
              and abs(v.get("giro", 0)) < 26 and abs(v.get("cabeceo", 0)) < 22 and not v.get("t")
              and boca_cerrada(v)]
    print(f"{len(buenas)} caras de frente, sin tapar y con la boca cerrada para mezclar")
    # Solo los triángulos de dentro de la cara (los del borde y el anillo
    # traían fondo y dejaban garabatos).
    dentro = np.array([tr for tr in tris if max(tr) < N])
    idx = 0
    for ti, (lo, hi) in enumerate(TONOS):
        grupo = [k for k in buenas if lo <= lum(m[k]["s"]) < hi]
        if len(grupo) < MEZCLA:
            continue
        for _ in range(por_tono):
            elegidos = rnd.sample(grupo, MEZCLA)
            formas, mapas, pesos, tonos, iris = [], [], [], [], []
            for k in elegidos:
                e = m[k]
                forma, uv = decodificar(e, n)
                img = np.asarray(Image.open(os.path.join(RAIZ, e["a"])).convert("RGB"), dtype=np.float32)
                mapa, peso = llevar_al_mapa(img, uv, uv_dst, dentro)
                # Borde suave: se encoge un poco la zona válida y se difumina.
                peso = cv2.GaussianBlur(cv2.erode(peso, np.ones((7, 7), np.uint8)), (0, 0), 3)
                tono = np.array([int(e["s"][i:i + 2], 16) for i in (1, 3, 5)], dtype=float)
                formas.append(forma)
                mapas.append(mapa)
                pesos.append(peso)
                tonos.append(tono)
                if e.get("iris"):
                    iris.append([int(e["iris"][i:i + 2], 16) for i in (1, 3, 5)])
            tono_med = np.mean(tonos, 0)
            # Cada textura llevada al tono medio del grupo (por canal) y promediada.
            acc = np.zeros((LADO, LADO, 3), np.float32)
            pw = np.zeros((LADO, LADO), np.float32)
            for mapa, peso, tono in zip(mapas, pesos, tonos):
                acc += mapa * (tono_med / np.maximum(tono, 1))[None, None, :] * peso[..., None]
                pw += peso
            atlas = acc / np.maximum(pw[..., None], 1e-3)
            # Mediana donde hay al menos 3 caras: una marca que solo trae una
            # de las cuatro (oreja, mechón, borde de la foto) desaparece.
            pila = np.stack([mp * (tono_med / np.maximum(tn, 1))[None, None, :] for mp, tn in zip(mapas, tonos)])
            validos = np.stack([pe > 0.5 for pe in pesos])
            pila = np.where(validos[..., None], pila, np.nan)
            mediana = np.nanmedian(pila, axis=0)
            hay3 = (validos.sum(0) >= 3)[..., None]
            atlas = np.where(hay3, mediana, atlas)
            # Hacia el borde se funde con su tono (sin corte).
            f = np.clip(pw / MEZCLA * 1.6, 0, 1)[..., None]
            atlas = atlas * f + tono_med[None, None, :] * (1 - f)
            atlas = np.clip(atlas, 0, 255).astype(np.uint8)
            clave = "cara_%03d" % idx
            archivo = f"{CARPETA}/{clave}.jpg"
            Image.fromarray(atlas).save(os.path.join(RAIZ, archivo), quality=90, optimize=True)
            forma_med = np.mean(formas, 0)
            datos = np.concatenate([np.clip(forma_med, -32767, 32767), uv_dst * 32767], axis=1)
            iris_m = np.mean(iris, 0) if iris else np.array([70, 48, 30])
            salida[clave] = {"m": base64.b64encode(datos.astype("<i2").tobytes()).decode(), "a": archivo,
                             "s": "#%02x%02x%02x" % tuple(int(x) for x in tono_med),
                             "iris": "#%02x%02x%02x" % tuple(int(x) for x in iris_m), "tono": ti, "wb": [1, 1, 1]}
            idx += 1
    json.dump(salida, open(SALIDA_CARAS, "w", encoding="utf-8"), sort_keys=True)
    print(f"{len(salida)} caras en la biblioteca ({por_tono} por tono, {len(TONOS)} tonos)")


def pelos():
    """Cortes de pelo: por tipo de corte, los cuantiles de lo medido (sin
    color: el color se elige aparte)."""
    m = json.load(open(MALLAS, encoding="utf-8"))
    medidos = [v["h"] for v in m.values() if v.get("h") and not v["h"].get("gorro")]

    def corte(h):
        a, l = h.get("alto", 7), h.get("lados", .5)
        if h.get("rizo", 0) > .5 and a > 9.5 and l > .45:
            return "afro"
        if h.get("largo", 0) >= 0.12 and l > 0.75:
            return "melena_rizada"
        if h.get("largo", 0) >= 0.12:
            return "melena"
        if h.get("calvo"):
            return "calvo"
        if a < 6.6:
            return "rapado"
        if a > 8.3 and l < .45:
            return "tupe"
        if l < .35:
            return "degradado"
        return "normal"

    grupos = {}
    for h in medidos:
        grupos.setdefault(corte(h), []).append(h)
    salida = {}
    for nombre, lista in sorted(grupos.items()):
        lista.sort(key=lambda h: h.get("alto", 7))
        cuantos = 2 if len(lista) < 12 else 6
        for q in range(cuantos):
            h = lista[int((q + 0.5) / cuantos * len(lista))]
            pieza = {k: h[k] for k in ("alto", "lados", "rizo", "largo", "linea", "coronilla", "calvo", "cortado") if k in h}
            pieza["corte"] = nombre
            salida["pelo_%02d" % len(salida)] = pieza
    json.dump(salida, open(SALIDA_PELOS, "w", encoding="utf-8"), sort_keys=True, indent=0)
    print(f"{len(salida)} cortes en la biblioteca: " + ", ".join(f"{k} {len(v)}" for k, v in sorted(grupos.items())))


if __name__ == "__main__":
    caras(sys.argv[1], int(sys.argv[2]) if len(sys.argv) > 2 else 12)
    pelos()
