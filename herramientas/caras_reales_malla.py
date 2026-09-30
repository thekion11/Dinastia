#!/usr/bin/env python3
"""La cara de verdad en 3D: una malla deformable por jugador, desde su foto.

Usa MediaPipe (Google, licencia Apache 2.0, uso comercial permitido, sin
registro): el detector `face_landmarker.task` saca de cada foto 478 puntos de
la cara EN 3D, y la malla canónica `canonical_face_model.obj` (468 vértices,
898 triángulos) da cómo se unen. Para cada jugador:

  1. RECORTE DE CARA en alta resolución desde la foto ORIGINAL (no desde el
     retrato de 256 px, donde la cara ocupaba ~100 px): un cuadrado ajustado a
     la cara con la frente, a 384x384 -> `recursos/caras_reales_cara/`;
  2. se detectan los puntos en ese recorte;
  3. se "enderezan" (Umeyama: rotación + escala + traslación contra la malla
     canónica): la forma queda de frente aunque la foto sea de lado;
  4. cada vértice guarda DÓNDE está en la foto (UV): la cara se pinta con los
     píxeles exactos, sin recolorear;
  5. si la foto es de tres cuartos, la mitad lejana (aplastada y en sombra)
     toma forma y píxeles de la cercana, en espejo;
  6. UN ANILLO MÁS alrededor del óvalo (36 vértices): la malla de MediaPipe
     termina a media frente; el anillo sube hasta el nacimiento del pelo,
     cubre sienes y quijada y se curva hacia atrás, con su lugar en la foto
     calculado con la misma proyección de la cámara.

Salida:
    datos/cara_malla_topologia.json  {"n": 504, "tri": [...], "alfa": [...]}
    datos/caras_reales_mallas.json   {nombre: {"m": base64(int16[n*5]),
                                               "f": "recursos/caras_reales_cara/x.jpg"}}
        por vértice: x, y, z (cm de la malla canónica * 100) y u, v (* 32767).

    python3 herramientas/caras_reales_malla.py face_landmarker.task canonical_face_model.obj
"""
import base64
import json
import os
import sys

import numpy as np
from PIL import Image, ImageOps

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "dinastia-godot")
INDICE = os.path.join(RAIZ, "datos", "caras_reales_recortes.json")
REPORTE = os.path.join(RAIZ, "datos", "caras_reales_reporte.json")
TOPOLOGIA = os.path.join(RAIZ, "datos", "cara_malla_topologia.json")
SALIDA = os.path.join(RAIZ, "datos", "caras_reales_mallas.json")
CARPETA_CARAS = "recursos/caras_reales_cara"
LADO = 384
N = 468
GIRO_ESPEJO = 18.0  # grados de giro a partir de los que se usa la mitad cercana


def leer_obj(ruta):
    v, t = [], []
    for linea in open(ruta, encoding="utf-8"):
        p = linea.split()
        if not p:
            continue
        if p[0] == "v":
            v.append([float(x) for x in p[1:4]])
        elif p[0] == "f":
            t.append([int(x.split("/")[0]) - 1 for x in p[1:4]])
    return np.array(v), t


def umeyama(origen, destino):
    """s, R, t que llevan `origen` a `destino` (mínimos cuadrados)."""
    mo, md = origen.mean(0), destino.mean(0)
    a, b = origen - mo, destino - md
    cov = b.T @ a / len(origen)
    u, d, vt = np.linalg.svd(cov)
    s_ = np.eye(3)
    if np.linalg.det(u) * np.linalg.det(vt) < 0:
        s_[2, 2] = -1
    r = u @ s_ @ vt
    escala = np.trace(np.diag(d) @ s_) / a.var(0).sum()
    return escala, r, md - escala * r @ mo


def topologia(canon, tris):
    """Pares simétricos, el lazo del borde (en orden), los triángulos del
    anillo nuevo y el alfa de cada vértice (el borde se funde con la piel)."""
    espejo = canon * np.array([-1, 1, 1])
    pares = [int(np.argmin(((canon - espejo[i]) ** 2).sum(1))) for i in range(N)]
    cuenta, orden = {}, {}
    for t in tris:
        for a, b in ((t[0], t[1]), (t[1], t[2]), (t[2], t[0])):
            k = (min(a, b), max(a, b))
            cuenta[k] = cuenta.get(k, 0) + 1
            orden[k] = (a, b)  # cómo aparece la arista en su triángulo
    aristas_borde = [k for k, c in cuenta.items() if c == 1]
    # Encadenar el lazo en el sentido en que lo recorren sus triángulos.
    siguiente = {orden[k][0]: orden[k][1] for k in aristas_borde}
    inicio = next(iter(siguiente))
    lazo = [inicio]
    while siguiente[lazo[-1]] != inicio:
        lazo.append(siguiente[lazo[-1]])
    m = len(lazo)
    nuevos = []
    for k in range(m):
        a, b = lazo[k], lazo[(k + 1) % m]
        na, nb = N + k, N + (k + 1) % m
        # La arista a->b ya la usa su triángulo: el nuevo la recorre b->a.
        nuevos += [[b, a, na], [b, na, nb]]
    vecinos = [set() for _ in range(N)]
    for (a, b) in cuenta:
        vecinos[a].add(b)
        vecinos[b].add(a)
    borde = set(lazo)
    anillo1 = {j for i in borde for j in vecinos[i]} - borde
    alfa = [0.7 if i in borde else 0.95 if i in anillo1 else 1.0 for i in range(N)] + [0.0] * m
    return pares, lazo, nuevos, alfa


def color_pelo(img, uv, lazo, forma, centro):
    """El color del pelo: una franja por encima de la frente, en la foto. Se
    toma el percentil 30 de claridad (los brillos del pelo engañan: el color
    "medio" salía casi rubio). None si ahí no hay pelo (calvo, fondo, gorra
    del color de la piel)."""
    lado = img.shape[0]
    muestras = []
    for b in lazo:
        d = forma[b, :2] - centro
        if d[1] / max(np.linalg.norm(d), 1e-6) < 0.75:
            continue  # solo el arco de arriba
        u, v = uv[b]
        for sube in (0.09, 0.13):
            x, y = int(u * lado), int((v - sube) * lado)
            if 2 <= x < lado - 2 and 2 <= y < lado - 2:
                muestras.extend(img[y - 2:y + 3, x - 2:x + 3].reshape(-1, 3).tolist())
    if len(muestras) < 20:
        return None
    m = np.array(muestras, dtype=float)
    lum = m @ np.array([0.299, 0.587, 0.114])
    orden = np.argsort(lum)
    c = m[orden[int(len(orden) * 0.25)]]
    # Piel (frente) para comparar: si el "pelo" es del color de la piel, no hay pelo.
    piel = np.median(img[[int(uv[i, 1] * lado) for i in (151, 9, 8)], [int(uv[i, 0] * lado) for i in (151, 9, 8)]], 0)
    # El pelo tiene que ser claramente distinto de la frente: más oscuro, o
    # (rubio, canoso) más claro y menos saturado. Si no, es frente (entradas)
    # o no se ve.
    lp = piel @ np.array([0.299, 0.587, 0.114])
    lc = c @ np.array([0.299, 0.587, 0.114])
    if np.linalg.norm(c - piel) < 35 or (lc > lp * 0.8 and lc < lp * 1.15):
        return None
    # Más claro que una piel oscura: es el fondo, no el pelo. Y azulado: cielo
    # o pared (el pelo no es azul).
    if (lc > lp and lp < 150) or c[2] > c[0] + 8:
        return None
    return "#%02x%02x%02x" % tuple(int(x) for x in c)


def detectar(det, mp, arr):
    img = mp.Image(image_format=mp.ImageFormat.SRGB, data=np.ascontiguousarray(arr))
    r = det.detect(img)
    return r.face_landmarks[0][:N] if r.face_landmarks else None


def recorte_cara(original, caja, det, mp):
    """El cuadrado de la cara (con frente) en la foto original, a LADO px."""
    x0, y0, lado = caja
    region = np.asarray(original.crop((x0, y0, x0 + lado, y0 + lado)).convert("RGB"))
    lm = detectar(det, mp, region)
    if lm is None:
        return None
    xs = np.array([p.x for p in lm]) * lado + x0
    ys = np.array([p.y for p in lm]) * lado + y0
    ancho, alto = xs.max() - xs.min(), ys.max() - ys.min()
    s = max(ancho, alto) * 1.6
    cx, cy = (xs.max() + xs.min()) / 2, (ys.max() + ys.min()) / 2 - s * 0.07
    w, h = original.size
    s = min(s, w, h)
    ix = int(min(max(cx - s / 2, 0), w - s))
    iy = int(min(max(cy - s / 2, 0), h - s))
    return original.crop((ix, iy, ix + int(s), iy + int(s))).convert("RGB").resize((LADO, LADO), Image.LANCZOS)


def main() -> None:
    import mediapipe as mp
    from mediapipe.tasks.python import BaseOptions, vision

    modelo, obj = sys.argv[1], sys.argv[2]
    canon, tris = leer_obj(obj)
    pares, lazo, nuevos, alfa = topologia(canon, tris)
    total = N + len(lazo)
    json.dump({"n": total, "tri": [i for t in tris + nuevos for i in t], "alfa": alfa},
              open(TOPOLOGIA, "w", encoding="utf-8"))
    det = vision.FaceLandmarker.create_from_options(vision.FaceLandmarkerOptions(
        base_options=BaseOptions(model_asset_path=modelo), num_faces=1))
    indice = json.load(open(INDICE, encoding="utf-8"))
    originales = {r["nombre"]: r["archivo"] for r in json.load(open(REPORTE, encoding="utf-8-sig"))
                  if r.get("encontrado") and r.get("archivo")}
    os.makedirs(os.path.join(RAIZ, CARPETA_CARAS), exist_ok=True)
    salida, giros = {}, 0
    for n, (nombre, fila) in enumerate(indice.items()):
        try:
            original = ImageOps.exif_transpose(Image.open(os.path.join(RAIZ, originales[nombre])))
        except Exception:  # noqa: BLE001 -una foto rota no para el lote
            continue
        cara = recorte_cara(original, fila["caja"], det, mp)
        if cara is None:
            continue
        lm = detectar(det, mp, np.asarray(cara))
        if lm is None:
            continue
        archivo = f"{CARPETA_CARAS}/{os.path.splitext(os.path.basename(fila['archivo']))[0]}.jpg"
        cara.save(os.path.join(RAIZ, archivo), quality=90, optimize=True)
        uv = np.array([[p.x, p.y] for p in lm])
        # Píxeles de imagen: x derecha, y ARRIBA, z hacia la cámara (como la
        # malla canónica).
        pts = np.array([[p.x * LADO, -p.y * LADO, -p.z * LADO] for p in lm])
        s, rot, t = umeyama(pts, canon)
        forma = (s * (rot @ pts.T)).T + t

        def a_foto(q):
            """Del espacio enderezado a la foto (la cámara, deshecha)."""
            p = rot.T @ ((q - t) / s)
            return np.array([p[0] / LADO, -p[1] / LADO])

        giro = np.degrees(np.arctan2(-rot[2, 0], rot[0, 0]))
        lejos = set()
        if abs(giro) > GIRO_ESPEJO:
            giros += 1
            # La mitad cercana ocupa más ancho en la foto.
            izq = [i for i in range(N) if canon[i, 0] < -0.5]
            der = [i for i in range(N) if canon[i, 0] > 0.5]
            lejos = set(izq if np.ptp(uv[izq, 0]) < np.ptp(uv[der, 0]) else der)
            for i in lejos:
                j = pares[i]
                forma[i] = forma[j] * np.array([-1, 1, 1])
                uv[i] = uv[j]
        # El anillo: hacia fuera del óvalo (más en la frente, poco bajo el
        # mentón) y hacia atrás, siguiendo la cabeza.
        centro = forma[:, :2].mean(0)
        anillo, uv_anillo = [], []
        for b in lazo:
            d = forma[b, :2] - centro
            d /= max(np.linalg.norm(d), 1e-6)
            largo = 0.7 + 1.1 * max(d[1], 0.0) - 0.3 * max(-d[1], 0.0)
            q = forma[b] + np.array([d[0] * largo, d[1] * largo, -largo * 0.8])
            anillo.append(q)
            uv_anillo.append(a_foto(q * np.array([-1, 1, 1])) if b in lejos else a_foto(q))
        forma = np.vstack([forma, anillo])
        uv = np.clip(np.vstack([uv, uv_anillo]), 0.0, 1.0)
        datos = np.concatenate([np.clip(forma * 100, -32767, 32767), uv * 32767], axis=1)
        salida[nombre] = {"m": base64.b64encode(datos.astype("<i2").tobytes()).decode(), "f": archivo}
        pelo = color_pelo(np.asarray(cara), uv, lazo, forma, centro)
        if pelo:
            salida[nombre]["p"] = pelo
        if n % 200 == 0:
            print(f"  {n}/{len(indice)}", flush=True)
    json.dump(salida, open(SALIDA, "w", encoding="utf-8"), sort_keys=True)
    print(f"{len(salida)} caras 3D de {len(indice)} retratos ({giros} de tres cuartos, en espejo)")
    os._exit(0)  # MediaPipe 1.0 falla al cerrarse con el intérprete


if __name__ == "__main__":
    main()
