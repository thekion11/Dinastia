#!/usr/bin/env python3
"""La cara de verdad en 3D: una malla deformable por jugador, desde su foto.

Usa MediaPipe (Google, licencia Apache 2.0, uso comercial permitido, sin
registro): el detector `face_landmarker.task` saca de cada retrato 478 puntos
de la cara EN 3D, y la malla canónica `canonical_face_model.obj` (468
vértices, 898 triángulos) da cómo se unen. Para cada jugador:

  1. se detectan los puntos en su foto;
  2. se "enderezan" (Umeyama: rotación + escala + traslación contra la malla
     canónica), así la forma queda de frente aunque la foto sea de lado: su
     nariz, sus pómulos, su mentón, su frente;
  3. cada vértice guarda DÓNDE está en la foto (UV): la cara se pinta con los
     píxeles exactos de la foto, sin recolorear;
  4. si la foto es de tres cuartos, la mitad lejana (aplastada y en sombra)
     toma forma y píxeles de la cercana, en espejo.

Salida:
    datos/cara_malla_topologia.json  {"tri": [...], "alfa": [...], "pares": [...]}
    datos/caras_reales_mallas.json   {nombre: base64(int16[468*5])}
        por vértice: x, y, z (décimas de milímetro de la malla canónica, en
        cm*100) y u, v (0-1 * 32767).

    python3 herramientas/caras_reales_malla.py face_landmarker.task canonical_face_model.obj
"""
import base64
import json
import os
import sys

import numpy as np

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "dinastia-godot")
INDICE = os.path.join(RAIZ, "datos", "caras_reales_recortes.json")
TOPOLOGIA = os.path.join(RAIZ, "datos", "cara_malla_topologia.json")
SALIDA = os.path.join(RAIZ, "datos", "caras_reales_mallas.json")
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
    # Pares simétricos: el vértice más cercano al espejo (x -> -x).
    espejo = canon * np.array([-1, 1, 1])
    pares = [int(np.argmin(((canon - espejo[i]) ** 2).sum(1))) for i in range(N)]
    # Borde de la malla (aristas de un solo triángulo) y su vecindad: la cara
    # se funde con la piel del modelo en vez de cortar en seco.
    cuenta = {}
    for t in tris:
        for a, b in ((t[0], t[1]), (t[1], t[2]), (t[2], t[0])):
            k = (min(a, b), max(a, b))
            cuenta[k] = cuenta.get(k, 0) + 1
    borde = {i for k, c in cuenta.items() if c == 1 for i in k}
    vecinos = [set() for _ in range(N)]
    for (a, b) in cuenta:
        vecinos[a].add(b)
        vecinos[b].add(a)
    anillo1 = {j for i in borde for j in vecinos[i]} - borde
    anillo2 = {j for i in anillo1 for j in vecinos[i]} - borde - anillo1
    alfa = [0.0 if i in borde else 0.45 if i in anillo1 else 0.85 if i in anillo2 else 1.0 for i in range(N)]
    return pares, alfa


def main() -> None:
    import mediapipe as mp
    from mediapipe.tasks.python import BaseOptions, vision

    modelo, obj = sys.argv[1], sys.argv[2]
    canon, tris = leer_obj(obj)
    pares, alfa = topologia(canon, tris)
    json.dump({"tri": [i for t in tris for i in t], "alfa": alfa, "pares": pares},
              open(TOPOLOGIA, "w", encoding="utf-8"))
    det = vision.FaceLandmarker.create_from_options(vision.FaceLandmarkerOptions(
        base_options=BaseOptions(model_asset_path=modelo), num_faces=1))
    indice = json.load(open(INDICE, encoding="utf-8"))
    salida, giros = {}, 0
    for nombre, fila in indice.items():
        ruta = os.path.join(RAIZ, fila["archivo"])
        try:
            img = mp.Image.create_from_file(ruta)
        except Exception:  # noqa: BLE001
            continue
        r = det.detect(img)
        if not r.face_landmarks:
            continue
        w, h = img.width, img.height
        lm = r.face_landmarks[0][:N]
        uv = np.array([[p.x, p.y] for p in lm])
        # A metros de imagen: x derecha, y ARRIBA, z hacia la cámara (como la
        # malla canónica).
        pts = np.array([[p.x * w, -p.y * h, -p.z * w] for p in lm])
        s, rot, t = umeyama(pts, canon)
        forma = (s * (rot @ pts.T)).T + t
        # Giro de la cabeza en la foto (yaw): el de la rotación que la endereza.
        giro = np.degrees(np.arctan2(-rot[2, 0], rot[0, 0]))
        if abs(giro) > GIRO_ESPEJO:
            giros += 1
            # La mitad lejana es la del lado hacia el que gira: x de la malla
            # canónica con el mismo signo que el giro... se decide midiendo:
            # la mitad cercana ocupa más ancho en la foto.
            izq = [i for i in range(N) if canon[i, 0] < -0.5]
            der = [i for i in range(N) if canon[i, 0] > 0.5]
            ancho_i = np.ptp(uv[izq, 0])
            ancho_d = np.ptp(uv[der, 0])
            lejos = izq if ancho_i < ancho_d else der
            for i in lejos:
                j = pares[i]
                forma[i] = forma[j] * np.array([-1, 1, 1])
                uv[i] = uv[j]
        datos = np.concatenate([np.clip(forma * 100, -32767, 32767), np.clip(uv * 32767, 0, 32767)], axis=1)
        salida[nombre] = base64.b64encode(datos.astype("<i2").tobytes()).decode()
    json.dump(salida, open(SALIDA, "w", encoding="utf-8"), sort_keys=True)
    print(f"{len(salida)} caras 3D de {len(indice)} retratos ({giros} de tres cuartos, en espejo)")
    os._exit(0)  # MediaPipe 1.0 falla al cerrarse con el intérprete


if __name__ == "__main__":
    main()
