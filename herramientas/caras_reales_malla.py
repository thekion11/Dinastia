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
import colorsys
import json
import os
import sys

import numpy as np
from PIL import Image, ImageFilter, ImageOps

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_caras as motor  # noqa: E402  (lo aprendido: parámetros y piezas)

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "dinastia-godot")
INDICE = os.path.join(RAIZ, "datos", "caras_reales_recortes.json")
REPORTE = os.path.join(RAIZ, "datos", "caras_reales_reporte.json")
TOPOLOGIA = os.path.join(RAIZ, "datos", "cara_malla_topologia.json")
SALIDA = os.path.join(RAIZ, "datos", "caras_reales_mallas.json")
CARPETA_CARAS = "recursos/caras_reales_cara"
CARPETA_ALBEDO = "recursos/caras_reales_albedo"
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


# Índices de MediaPipe: labios (fuera de la barba), cejas y párpado de arriba.
LABIOS = {61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291, 409, 270, 269, 267, 0, 37, 39, 40, 185,
          78, 95, 88, 178, 87, 14, 317, 402, 318, 324, 308, 415, 310, 311, 312, 13, 82, 81, 80, 191}
CEJAS = [70, 63, 105, 66, 107, 55, 65, 52, 53, 46, 300, 293, 334, 296, 336, 285, 295, 282, 283, 276]
NARIZ_PUNTA = 1
# Base de la nariz y aletas: los orificios son oscuros y no son barba.
NARIZ_BASE = {1, 2, 4, 5, 19, 20, 44, 45, 60, 64, 75, 79, 94, 97, 98, 99, 125, 141, 166, 195, 197,
              218, 219, 237, 238, 240, 242, 250, 274, 275, 290, 294, 305, 309, 326, 327, 328, 354,
              370, 392, 438, 439, 457, 458, 460, 462}
PIEL, PELO, CARA = 2, 1, 3  # clases del segmentador (0 fondo, 4 ropa, 5 otros)


def lum(c):
    return c @ np.array([0.299, 0.587, 0.114])


def media_ventana(a, r):
    """Media en una ventana (2r+1)^2, con sumas acumuladas (bordes repetidos)."""
    p = np.pad(a, r + 1, mode="edge").cumsum(0).cumsum(1)
    k = 2 * r + 1
    return (p[k:, k:] - p[:-k, k:] - p[k:, :-k] + p[:-k, :-k])[:a.shape[0], :a.shape[1]] / (k * k)


def b64(v):
    return base64.b64encode(np.clip(np.asarray(v) * 255, 0, 255).astype(np.uint8).tobytes()).decode()


def analizar(original, caja, cara, uv, forma, lazo, escala, seg, mp):
    """Pelo, piel, barba y cejas, medidos en la foto.

    - "s": color de la piel (mediana de los píxeles que el segmentador marca
      como piel de la cara: sin barba, cejas, ojos ni fondo).
    - "h": el pelo: "c" color (mediana), "r" raíz (más oscuro), "alto" cm de
      pelo sobre el cráneo, "lados" (0 rapado a los lados, 1 lleno), "largo"
      (0 corto, 1 por debajo de la mandíbula), "rizo" (0 liso, 1 muy rizado),
      "linea" (por vértice del anillo de arriba: 1 si encima hay pelo).
    - "b": densidad de barba por vértice (0-255), de la oscuridad del píxel
      frente a la piel; "e": lo mismo para las cejas.
    """
    ix, iy, s_cara = caja
    w, h = original.size
    # Un recorte ancho (2,4 veces la cara) para ver todo el pelo.
    ancho = int(s_cara * 2.4)
    wx = int(ix + s_cara / 2 - ancho / 2)
    wy = int(iy + s_cara * 0.45 - ancho * 0.42)
    L = 512
    grande = original.crop((wx, wy, wx + ancho, wy + ancho)).convert("RGB").resize((L, L), Image.BILINEAR)
    arr = np.asarray(grande)
    r = seg.segment(mp.Image(image_format=mp.ImageFormat.SRGB, data=np.ascontiguousarray(arr)))
    cat = np.squeeze(r.category_mask.numpy_view())
    # El modelo devuelve su máscara a 256x256 (no a la medida de la imagen):
    # llevarla a L x L. (Sin esto todo el pelo caía a la mitad de escala.)
    if cat.shape[0] != L:
        cat = np.asarray(Image.fromarray(cat.astype(np.uint8)).resize((L, L), Image.NEAREST))
    if os.environ.get("VER_SEG"):
        pal = np.array([[0, 0, 0], [255, 0, 0], [0, 255, 0], [0, 0, 255], [255, 255, 0], [0, 255, 255]], np.uint8)
        Image.fromarray((arr * 0.5 + pal[cat.clip(0, 5)] * 0.5).astype(np.uint8)).save(
            os.path.join(os.environ["VER_SEG"], "seg_%d.png" % (hash(str(caja)) % 100000)))
    # De uv de la cara (0-1) a píxeles del recorte ancho.
    def a_grande(u, v):
        return ((ix + u * s_cara - wx) / ancho * L, (iy + v * s_cara - wy) / ancho * L)
    cm_px = escala * (ancho / L) / (s_cara / LADO)  # cm (malla canónica) por píxel ancho
    out = {}
    piel_px = arr[cat == CARA].astype(float)
    if len(piel_px) < 200:
        return out
    # Piel: la parte ILUMINADA (del 55 al 90 % de claridad). Con el 60 % del
    # medio, en fotos con luz de costado entraba la mitad en sombra y la piel
    # salía más oscura que la del jugador; por arriba se deja fuera el brillo.
    orden = np.argsort(lum(piel_px))
    piel = piel_px[orden[int(len(orden) * 0.55):int(len(orden) * 0.9)]].mean(0)
    # BALANCE DE BLANCOS: una foto con luz amarilla, verde o azul (la camiseta,
    # los focos, el césped) daba pieles de colores imposibles. El tono de su
    # piel se lleva a la franja de las pieles reales (tono 12-32 grados,
    # saturación 0,2-0,6) sin cambiar su claridad; la misma corrección (por
    # canal, "wb") se aplica a toda la foto en el juego.
    # EXPOSICIÓN DE LA FOTO (auditoría 30-9: pieles claras salían marrones
    # porque la foto estaba oscura). Auto-niveles moderado: el percentil 95 de
    # la foto entera se lleva hacia 235; SOLO aclara, hasta x1,4. (Una cara en
    # sombra dentro de una foto bien expuesta no se puede distinguir de una
    # piel oscura con una sola foto: esos quedan como están.)
    todo = np.asarray(original.convert("RGB").resize((min(600, w), max(1, int(h * min(600, w) / w)))), dtype=float)
    p95 = np.percentile(todo @ np.array([0.299, 0.587, 0.114]), 95)
    ganancia = float(np.clip((235.0 / max(p95, 1.0)) ** 0.7, 1.0, 1.4))
    # Nunca aclarar una piel oscura por una foto con fondo oscuro (Sima salía
    # claro): la ganancia se aplica entera desde una piel medida de claridad
    # 122 y se apaga hacia 102.
    ganancia = 1.0 + (ganancia - 1.0) * float(np.clip((lum(piel) - 102.0) / 20.0, 0.0, 1.0))
    out["exp"] = round(ganancia, 3)
    piel = np.clip(piel * ganancia, 0, 255)
    # (motor_caras.piel_realista: tono 14-24° y la saturación típica de SU
    # claridad; antes solo se acotaba y las pieles claras salían rojas.)
    nuevo = motor.piel_realista(piel)
    # (Misma claridad que la medida, salvo el tope de piel_realista.)
    nuevo *= min(lum(piel), 0.9 * 255 * 0.82) / max(lum(nuevo), 1.0)
    lin = lambda c: np.where(c / 255 <= 0.04045, c / 255 / 12.92, ((c / 255 + 0.055) / 1.055) ** 2.4)
    # (el balance incluye la ganancia de exposición: se mide contra la piel SIN aclarar)
    wb = lin(nuevo) / np.maximum(lin(piel / ganancia), 1e-4)
    out["wb"] = [round(float(x), 3) for x in np.clip(wb, 0.5, 3.2)]
    piel = np.clip(nuevo, 0, 255)
    out["s"] = "#%02x%02x%02x" % tuple(int(x) for x in piel)
    lp = lum(piel)
    # PELO: solo el que está pegado a SU cabeza (en la foto puede salir el pelo
    # de otro jugador) y a no más de 1,6 caras de distancia.
    import cv2
    caracx, caracy = a_grande(*uv[1])
    # Ancho de la cara por la caja de todos sus puntos (en una foto de tres
    # cuartos los dos lados se copiaron en espejo y 234/454 coinciden).
    ancho_cara = max((uv[:N, 0].max() - uv[:N, 0].min()) * s_cara / ancho * L, 10.0)
    mascara = (cat == PELO).astype(np.uint8)
    _, etiquetas = cv2.connectedComponents(mascara)
    piel_cara = cv2.dilate((cat == CARA).astype(np.uint8), np.ones((9, 9), np.uint8))
    suyas = set(np.unique(etiquetas[(piel_cara > 0) & (mascara > 0)])) - {0}
    yy, xx = np.mgrid[0:L, 0:L]
    cerca = (xx - caracx) ** 2 + (yy - caracy) ** 2 < (ancho_cara * 1.6) ** 2
    if not suyas:
        # Nada pegado a la piel (una sombra en la frente, una cinta): el pelo
        # que esté encima de la frente, a menos de una cara.
        fx0, fy0 = a_grande(*uv[10])
        for k in range(1, etiquetas.max() + 1):
            ys_k, xs_k = np.nonzero(etiquetas == k)
            if len(xs_k) > 150 and (xs_k.mean() - fx0) ** 2 + (ys_k.mean() - fy0) ** 2 < ancho_cara ** 2:
                suyas.add(k)
    suyo = np.isin(etiquetas, list(suyas)) & cerca
    if os.environ.get("DEPURAR"):
        print("tam", original.size, "caja", caja, "ancho", ancho, "wx", wx, "wy", wy, "arr", arr.shape, "cat", cat.shape)
        ys_h, xs_h = np.nonzero(mascara)
        print("pelo", int(mascara.sum()), "suyas", suyas, "suyo", int(suyo.sum()), "cerca", int(cerca.sum()), "ancho", ancho_cara, "nariz", caracx, caracy, "pelo_c", xs_h.mean(), ys_h.mean(), "isin", int(np.isin(etiquetas, list(suyas)).sum()))
    cat = np.where((cat == PELO) & ~suyo, 0, cat)
    pelo_px = arr[cat == PELO].astype(float)
    hp = {}
    if len(pelo_px) > 300:
        # El color: del interior del pelo (erosionado: el borde se mezcla con
        # el fondo) y cerca de la frente.
        fx, fy = a_grande(*uv[10])
        interior = cv2.erode((cat == PELO).astype(np.uint8), np.ones((5, 5), np.uint8)) > 0
        junto = (xx - fx) ** 2 + (yy - fy) ** 2 < (ancho_cara * 0.9) ** 2
        muestra_pelo = arr[interior & junto].astype(float)
        if len(muestra_pelo) > 150:
            pelo_px = muestra_pelo
        o = np.argsort(lum(pelo_px))
        def con_wb(c):
            l = lin(np.asarray(c, dtype=float)) * np.array(out["wb"])
            srgb = np.where(l <= 0.0031308, l * 12.92, 1.055 * np.power(np.clip(l, 0, 1), 1 / 2.4) - 0.055)
            return "#%02x%02x%02x" % tuple(int(np.clip(x * 255, 0, 255)) for x in srgb)
        hp["c"] = motor.pelo_natural(con_wb(pelo_px[o[int(len(o) * 0.55)]]))
        hp["r"] = motor.pelo_natural(con_wb(pelo_px[o[int(len(o) * 0.12)]]), "#1a1411")
        # Cuánto sube el pelo por encima de la frente, en la dirección de SU
        # cara (del mentón a la frente): con la cabeza inclinada, medir en
        # vertical exageraba.
        p10 = np.array(a_grande(*uv[10]))
        p152 = np.array(a_grande(*uv[152]))
        arriba = (p10 - p152) / max(np.linalg.norm(p10 - p152), 1.0)
        py, px = np.nonzero(cat == PELO)
        t = (px - p10[0]) * arriba[0] + (py - p10[1]) * arriba[1]
        hp["cortado"] = bool(py.min() <= 1)
        hp["alto"] = round(float(max(0.0, np.percentile(t, 98) * cm_px)), 2)
        # Lados: pelo junto a las sienes, a la altura de los ojos.
        ox1, oy1 = a_grande(uv[:N, 0].min(), uv[234, 1])
        ox2, oy2 = a_grande(uv[:N, 0].max(), uv[454, 1])
        banda = int(3.0 / cm_px)
        lados = []
        for x0, y0, sg in ((ox1, oy1, -1), (ox2, oy2, 1)):
            xs = np.clip(np.arange(int(x0), int(x0) + sg * banda, sg), 0, L - 1)
            ys = np.clip(np.arange(int(y0 - banda * 1.5), int(y0)), 0, L - 1)
            if len(xs) and len(ys):
                lados.append(float((cat[np.ix_(ys, xs)] == PELO).mean()))
        hp["lados"] = round(max(lados) if lados else 0.0, 2)
        # Largo: pelo por debajo de la mandíbula, a los costados del cuello.
        _, ymenton = a_grande(*uv[152])
        # (junto a su cabeza: el pelo de otro jugador detrás no cuenta)
        # y de la MISMA mancha de pelo que el de arriba de su frente.
        fx1, fy1 = a_grande(*uv[10])
        encima = etiquetas[max(0, int(fy1) - int(ancho_cara)):max(1, int(fy1)), max(0, int(fx1) - 20):int(fx1) + 20]
        ids, cuentas = np.unique(encima[encima > 0], return_counts=True)
        propia = (etiquetas == ids[np.argmax(cuentas)]) if len(ids) else (cat == PELO)
        bajo = propia & (cat == PELO) & (yy > ymenton) & (np.abs(xx - caracx) < ancho_cara * 1.0)
        hp["largo"] = round(float(min(1.0, bajo.sum() / max(1.0, (cat == PELO).sum()) * 3.0)), 2)
        # Rizo: textura fina dentro del pelo (liso = poca, rizado = mucha).
        g = lum(arr.astype(float))
        fino = np.abs(g - np.asarray(Image.fromarray(g.astype(np.uint8)).filter(ImageFilter.GaussianBlur(2)), dtype=float))
        dentro = cat == PELO
        # Rizo: lo irregular que es el borde de arriba del pelo (un afro o un
        # rizado hacen bultos; el liso, una curva suave). La textura no servía:
        # un afro negro casi no tiene brillo.
        cols = np.where(dentro.any(0))[0]
        if len(cols) > 20:
            techo = np.array([np.argmax(dentro[:, x]) for x in cols], dtype=float)
            suave = np.convolve(techo, np.ones(15) / 15, mode="same")
            borde = np.abs(techo - suave)[7:-7].mean() / ancho_cara
        else:
            borde = 0.0
        hp["rizo_crudo"] = round(float(borde), 4)
        # Un afro es redondo (borde suave) pero abulta mucho: también cuenta.
        hp["rizo"] = round(float(np.clip(max((borde - 0.012) / 0.03, (hp["alto"] - 9.5) / 2.0), 0.0, 1.0)), 2)
        # Nacimiento del pelo: por cada vértice del anillo nuevo, ¿hay pelo
        # un poco más arriba?
        linea = []
        for k, b in enumerate(lazo):
            u, v = uv[N + k]
            x, y = a_grande(u, v)
            x, y = int(np.clip(x, 0, L - 1)), int(np.clip(y - 0.8 / cm_px, 0, L - 1))
            linea.append(1 if cat[y, x] == PELO else 0)
        hp["linea"] = linea
        # CORONILLA: ¿hay pelo arriba de la cabeza? (un calvo con pelo a los
        # lados tiene pelo en la foto, pero no encima). Banda de 2 a 6 cm sobre
        # la frente, en la mitad central de la cara.
        c_arriba = []
        tonos_arriba = []
        for cm in np.arange(1.5, 4.6, 0.5):  # (hasta 6 cm salía de la cabeza)
            q = p10 + arriba * (cm / cm_px)
            for dx in np.linspace(-0.25, 0.25, 6) * ancho_cara:
                x = int(np.clip(q[0] + dx * arriba[1], 0, L - 1))
                y = int(np.clip(q[1] - dx * arriba[0], 0, L - 1))
                c_arriba.append(cat[y, x] == PELO)
                if cat[y, x] != 0:
                    tonos_arriba.append(lum(arr[y, x].astype(float)))
        hp["coronilla"] = round(float(np.mean(c_arriba)), 2)
        # Calvo: poco pelo arriba Y la coronilla tiene color de piel (un
        # rapado al cero sale poco como "pelo" pero es más oscuro que la piel).
        claro = np.mean(tonos_arriba) if tonos_arriba else 0.0
        # y el pelo casi no sube sobre el cráneo (un pelo pegado hacia atrás o
        # rubio sale poco como "pelo" pero abulta).
        hp["claro_rel"] = round(float(claro / max(lp, 1.0)), 2)
        # Conservador: un pelo rubio o pegado da casi lo mismo que una calva, y
        # una calva de más se ve peor que un rapado de más (auditoría 30-9).
        hp["calvo"] = bool(hp["coronilla"] < 0.2 and 0.75 < hp["claro_rel"] < 1.15 and hp["alto"] < 6.6)
        out["h"] = hp
    # TAPADO: vértices de la cara cuyo píxel no es piel, pelo ni barba (una
    # mano, un brazo, la cinta del pelo, un balón delante).
    tapado = np.zeros(len(uv), dtype=bool)
    for i in range(N):
        x, y = a_grande(*uv[i])
        x, y = int(np.clip(x, 0, L - 1)), int(np.clip(y, 0, L - 1))
        # Solo piel de la CARA o pelo: el segmentador llama "piel" también a
        # los brazos (un jugador aplaudiendo con los brazos arriba).
        tapado[i] = cat[y, x] not in (CARA, PELO)
    # Los ojos y la boca pueden salir como "otros": no cuentan.
    tapado[list(LABIOS)] = False
    out["_tapado"] = tapado
    # El anillo de fuera: si cae en el fondo, un brazo o la camiseta, toma el
    # color del borde de la cara (su vértice de origen).
    for k, b in enumerate(lazo):
        i = N + k
        if i < len(uv):
            x, y = a_grande(*uv[i])
            x, y = int(np.clip(x, 0, L - 1)), int(np.clip(y, 0, L - 1))
            if cat[y, x] not in (CARA, PELO):
                uv[i] = uv[b]
    # BARBA Y CEJAS: por vértice, cuánto más oscuro (y menos saturado) que la
    # piel es su píxel en la foto de la cara.
    c = cara.astype(float)
    def muestra(i):
        x = int(np.clip(uv[i, 0] * LADO, 1, LADO - 2))
        y = int(np.clip(uv[i, 1] * LADO, 1, LADO - 2))
        return c[y - 1:y + 2, x - 1:x + 2].reshape(-1, 3).mean(0)
    def sat(col):
        mx, mn = col.max(), col.min()
        return (mx - mn) / max(mx, 1.0)
    sp = sat(piel)
    barba = np.zeros(N)
    cejas = np.zeros(N)
    y_nariz = forma[NARIZ_PUNTA, 1]
    # Textura fina: el vello la tiene, la piel lisa no (una barba pelirroja casi
    # no es más oscura que la piel, pero sí rugosa). Desvío local en 7x7.
    g = lum(c)
    m1 = media_ventana(g, 3)
    m2 = media_ventana(g * g, 3)
    desvio = np.sqrt(np.maximum(m2 - m1 * m1, 0.0))
    def textura(i):
        x = int(np.clip(uv[i, 0] * LADO, 0, LADO - 1))
        y = int(np.clip(uv[i, 1] * LADO, 0, LADO - 1))
        return desvio[y, x]
    # Referencia de piel lisa: frente y pómulos altos.
    base = max(np.median([textura(i) for i in (151, 9, 108, 337, 116, 345)]), 1.5)
    for i in range(N):
        col = muestra(i)
        oscuro = 1.0 - lum(col) / max(lp, 1.0)
        if i in CEJAS:
            cejas[i] = np.clip((oscuro - 0.08) / 0.35, 0, 1)
        elif i not in LABIOS and i not in NARIZ_BASE and forma[i, 1] < y_nariz - 0.3:
            por_color = np.clip((oscuro - 0.14) / 0.35, 0, 1) if sat(col) < sp * 1.15 else 0.0
            por_textura = np.clip((textura(i) / base - 1.6) / 2.0, 0, 1)
            barba[i] = max(por_color, por_textura * np.clip(oscuro + 0.35, 0, 1))
    out["b"] = b64(barba)
    out["e"] = b64(cejas)
    return out


def detectar(det, mp, arr):
    """Los puntos de LA cara de la foto: con varias personas (un compañero
    detrás), la más grande. Pedir una sola cara al detector a veces devolvía
    la de otro."""
    img = mp.Image(image_format=mp.ImageFormat.SRGB, data=np.ascontiguousarray(arr))
    r = det.detect(img)
    if not r.face_landmarks:
        return None
    def area(lm):
        xs = [p.x for p in lm]
        ys = [p.y for p in lm]
        return (max(xs) - min(xs)) * (max(ys) - min(ys))
    # Los 478 puntos: los 468 de la malla + 10 del iris (468-477).
    return max(r.face_landmarks, key=area)


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
    cara = original.crop((ix, iy, ix + int(s), iy + int(s))).convert("RGB").resize((LADO, LADO), Image.LANCZOS)
    return cara, (ix, iy, int(s))


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
        base_options=BaseOptions(model_asset_path=modelo), num_faces=3))
    # Segmentación por clases (pelo, piel de la cara, cuerpo, ropa): MediaPipe
    # `selfie_multiclass_256x256.tflite`, Apache 2.0. Va junto al detector.
    seg = vision.ImageSegmenter.create_from_options(vision.ImageSegmenterOptions(
        base_options=BaseOptions(model_asset_path=os.path.join(os.path.dirname(modelo), "selfie_multiclass.tflite")),
        output_category_mask=True))
    indice = json.load(open(INDICE, encoding="utf-8"))
    # SOLO="Nombre A,Nombre B": prueba rápida con unos pocos (no escribe nada).
    solo = [x.strip() for x in os.environ.get("SOLO", "").split(",") if x.strip()]
    if solo:
        indice = {k: v for k, v in indice.items() if k in solo}
    originales = {r["nombre"]: r["archivo"] for r in json.load(open(REPORTE, encoding="utf-8-sig"))
                  if r.get("encontrado") and r.get("archivo")}
    os.makedirs(os.path.join(RAIZ, CARPETA_CARAS), exist_ok=True)
    salida, giros = {}, 0
    for n, (nombre, fila) in enumerate(indice.items()):
        try:
            original = ImageOps.exif_transpose(Image.open(os.path.join(RAIZ, originales[nombre])))
        except Exception:  # noqa: BLE001 -una foto rota no para el lote
            continue
        rc = recorte_cara(original, fila["caja"], det, mp)
        if rc is None:
            continue
        cara, caja_cara = rc
        lm_todo = detectar(det, mp, np.asarray(cara))
        if lm_todo is None:
            continue
        lm = lm_todo[:N]
        archivo = f"{CARPETA_CARAS}/{os.path.splitext(os.path.basename(fila['archivo']))[0]}.jpg"
        cara.save(os.path.join(RAIZ, archivo), quality=90, optimize=True)
        uv = np.array([[p.x, p.y] for p in lm])
        uv_foto = uv.copy()  # dónde está cada punto en la foto (sin espejo)
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
        cabeceo = np.degrees(np.arctan2(rot[2, 1], rot[2, 2]))
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
        medido = analizar(original, caja_cara, np.asarray(cara), uv, forma, lazo, s, seg, mp)
        datos = np.concatenate([np.clip(forma * 100, -32767, 32767), uv * 32767], axis=1)
        salida[nombre]["m"] = base64.b64encode(datos.astype("<i2").tobytes()).decode()
        tapado = medido.pop("_tapado", None)
        if tapado is not None and tapado.any():
            # Lo tapado (una mano, el brazo, una cinta): se toma del lado
            # contrario si está a la vista; si no, queda marcado ("t") y el
            # juego pinta ahí su piel.
            for i in np.nonzero(tapado)[0]:
                j = pares[i]
                if not tapado[j]:
                    uv[i] = uv[j]
                    tapado[i] = False
            datos = np.concatenate([np.clip(forma * 100, -32767, 32767), uv * 32767], axis=1)
            salida[nombre]["m"] = base64.b64encode(datos.astype("<i2").tobytes()).decode()
            if tapado.any():
                medido["t"] = b64(tapado.astype(float))
        salida[nombre].update(medido)
        # LA PIEL REPLICADA (motor_caras.albedo_limpio): textura limpia de su
        # cara, que es la que pinta el juego. La foto recortada queda para 2D.
        if medido.get("s"):
            arr_cara = np.asarray(cara)
            rs = seg.segment(mp.Image(image_format=mp.ImageFormat.SRGB, data=np.ascontiguousarray(arr_cara)))
            cat_cara = np.squeeze(rs.category_mask.numpy_view())
            if cat_cara.shape[0] != LADO:
                cat_cara = np.asarray(Image.fromarray(cat_cara.astype(np.uint8)).resize((LADO, LADO), Image.NEAREST))
            barba_v = np.frombuffer(base64.b64decode(medido.get("b", "")), np.uint8) / 255.0 if medido.get("b") else np.zeros(N)
            piel_rgb = np.array([int(medido["s"][i:i + 2], 16) for i in (1, 3, 5)], dtype=float)
            # La barba medida en puntos con espejo se pinta en el lado de la
            # foto de donde sale (uv_foto).
            bm = motor.mascara_barba(uv_foto, tris, barba_v, LADO)
            alb = motor.albedo_limpio(arr_cara, cat_cara, uv_foto, piel_rgb, medido.get("wb", [1, 1, 1]), bm)
            archivo_a = archivo.replace(CARPETA_CARAS, CARPETA_ALBEDO)
            os.makedirs(os.path.join(RAIZ, CARPETA_ALBEDO), exist_ok=True)
            Image.fromarray(alb).save(os.path.join(RAIZ, archivo_a), quality=92, optimize=True)
            salida[nombre]["a"] = archivo_a
            if len(lm_todo) >= 478:
                iris = motor.color_iris(arr_cara, [
                    ((lm_todo[k].x * LADO, lm_todo[k].y * LADO),
                     np.hypot((lm_todo[k + 1].x - lm_todo[k].x) * LADO, (lm_todo[k + 1].y - lm_todo[k].y) * LADO))
                    for k in (motor.IRIS_DER, motor.IRIS_IZQ)])
                if iris:
                    salida[nombre]["iris"] = iris
        salida[nombre]["giro"] = round(float(giro), 1)
        salida[nombre]["cabeceo"] = round(float(cabeceo), 1)
        # Una foto muy de lado o muy desde arriba/abajo no sirve para la cara
        # 3D (se estira el fondo sobre la cara): el juego usa la recreación.
        tapados = int(np.frombuffer(base64.b64decode(medido["t"]), np.uint8).astype(bool).sum()) if medido.get("t") else 0
        # (Lo tapado ya se rellena con su piel: no descarta la foto.)
        if abs(cabeceo) > 38 or abs(giro) > 62 or tapados > N * 0.45:
            salida[nombre]["mala"] = True
        if n % 200 == 0:
            print(f"  {n}/{len(indice)}", flush=True)
    if solo and os.environ.get("VER"):
        from PIL import ImageDraw
        hojas = []
        for k, v in salida.items():
            im = Image.open(os.path.join(RAIZ, v["f"])).convert("RGB")
            d = ImageDraw.Draw(im)
            a = np.frombuffer(base64.b64decode(v["m"]), "<i2").reshape(-1, 5)[:, 3:5] / 32767 * LADO
            bb = np.frombuffer(base64.b64decode(v["b"]), np.uint8) / 255
            ee = np.frombuffer(base64.b64decode(v["e"]), np.uint8) / 255
            for i in range(N):
                if bb[i] > 0.05:
                    r = 1 + 3 * bb[i]
                    d.ellipse((a[i, 0] - r, a[i, 1] - r, a[i, 0] + r, a[i, 1] + r), outline=(0, 255, 0))
                if ee[i] > 0.05:
                    r = 1 + 3 * ee[i]
                    d.ellipse((a[i, 0] - r, a[i, 1] - r, a[i, 0] + r, a[i, 1] + r), outline=(255, 0, 255))
            hojas.append(np.asarray(im))
        Image.fromarray(np.concatenate(hojas, 1)).save(os.environ["VER"])
    if solo:
        for k, v in salida.items():
            tt = np.frombuffer(base64.b64decode(v["t"]), np.uint8) if v.get("t") else np.zeros(1)
            print(k, "giro", v.get("giro"), "cabeceo", v.get("cabeceo"), "mala", v.get("mala", False), "tapados", int((tt > 0).sum()))
            print(k, v.get("s"), v.get("h", {}) and {x: y for x, y in v["h"].items() if x != "linea"},
                  "barba", round(float(np.frombuffer(base64.b64decode(v["b"]), np.uint8).mean() / 255), 3),
                  "cejas", round(float(np.frombuffer(base64.b64decode(v["e"]), np.uint8)[CEJAS].mean() / 255), 2))
        os._exit(0)
    json.dump(salida, open(SALIDA, "w", encoding="utf-8"), sort_keys=True)
    print(f"{len(salida)} caras 3D de {len(indice)} retratos ({giros} de tres cuartos, en espejo)")
    os._exit(0)  # MediaPipe 1.0 falla al cerrarse con el intérprete


if __name__ == "__main__":
    main()
