#!/usr/bin/env python3
"""MOTOR DE CARAS: lo aprendido, en un solo lugar (30-9-2026).

Pedido del usuario: «construye un motor o algo para facilitar las mejoras ya
aprendidas; escanear los colores y las formas para calcar la cara, el pelo, los
ojos, las cejas, las pestañas y la barba». Este módulo guarda:

  * CONFIG: cada número que se afinó mirando capturas, con el porqué.
  * LECCIONES: los errores que ya se cometieron, para no repetirlos.
  * Las piezas del escaneo que usa `caras_reales_malla.py`:
      - `albedo_limpio`: la PIEL REPLICADA (no la foto pegada);
      - `color_iris`: el color de los ojos;
      - `regiones`: máscaras de ojos, cejas, labios, nariz y barba.

El lado del juego (Godot) lee lo que esto produce; sus propios números están
documentados en `herramientas/MOTOR_CARAS.md`.
"""
import numpy as np
from PIL import Image, ImageFilter

# Índices de la malla de MediaPipe (468 puntos).
OJO_DER = [33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246]
OJO_IZQ = [263, 249, 390, 373, 374, 380, 381, 382, 362, 398, 384, 385, 386, 387, 388, 466]
CEJA_DER = [46, 53, 52, 65, 55, 107, 66, 105, 63, 70]
CEJA_IZQ = [276, 283, 282, 295, 285, 336, 296, 334, 293, 300]
LABIOS_FUERA = [61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291, 409, 270, 269, 267, 0, 37, 39, 40, 185]
NARIZ_ABAJO = [129, 98, 97, 2, 326, 327, 358, 294, 278, 344, 440, 275, 4, 45, 220, 115, 48, 64]
MANDIBULA = [234, 93, 132, 58, 172, 136, 150, 149, 176, 148, 152, 377, 400, 378, 379, 365, 397, 288, 361,
             323, 454, 366, 376, 411, 425, 266, 330, 280, 346, 352, 329, 371, 355, 437, 399, 419, 351,
             168, 122, 196, 3, 51, 45, 220, 115, 48, 64, 129, 102, 100, 142, 126, 217, 174, 188,
             100, 119, 118, 117, 111, 116, 123, 147, 213, 192, 214, 210, 211, 32, 208, 199, 428, 262, 431]
IRIS_DER, IRIS_IZQ = 468, 473  # centros del iris (puntos 468-477 del detector)

CONFIG = {
    # --- Piel replicada ---------------------------------------------------
    # Radio (px del recorte de 384) de la "luz" de la foto: lo que cambia más
    # despacio que esto es sombra/luz del fotógrafo y se quita.
    "luz_radio": 14,
    # Del relieve de la piel (poros, arrugas, manchas) se conserva esta fracción
    # (en exponente): 1 = foto tal cual (se veía SUCIO), 0 = piel lisa de muñeco.
    "relieve_piel": 0.32,
    # Límites del relieve (un grano, un brillo de flash no pasan de aquí).
    "relieve_min": 0.86,
    "relieve_max": 1.1,
    # Cuánto del color propio de cada píxel de piel se deja (0 = tono único
    # exacto de su piel: sin rojeces ni manchas de color de la foto).
    "croma_propio": 0.12,
    # Suavizado bilateral antes del relieve (quita ruido JPG sin borrar bordes).
    "bilateral": (9, 26, 9),
    # Rasgos (ojos, cejas, labios, nariz, barba): se quedan con el color de la
    # foto, con la luz quitada a medias.
    "rasgo_luz": 0.6,
    # Borde suave de las máscaras de rasgos (px).
    "rasgo_suave": 3,
    # --- Pelo ---------------------------------------------------------------
    "craneo_cm": 6.0,          # altura del cráneo sobre el punto 10 (rapado)
    "percentil_color_pelo": 0.55,
    # --- Descartes ------------------------------------------------------------
    "giro_max": 62, "cabeceo_max": 38,
}

LECCIONES = [
    "Pegar la foto tal cual se ve SUCIO y SATURADO: replicar la piel (tono único + relieve suave).",
    "El segmentador llama 'piel' también a los brazos: para lo tapado, solo piel de CARA o pelo.",
    "Con varias personas en la foto, quedarse con la cara MÁS GRANDE (el detector daba la de otro).",
    "En fotos de tres cuartos el espejo copia UN ojo en los dos: parece estrabismo -> ojos 3D.",
    "Compatibility no pasa a lineal las ImageTexture con source_color: convertir a mano.",
    "La textura del cuerpo es más clara en cuello y brazos que su media: la piel del cuerpo con un",
    "  color plano exacto y solo un cuarto del relieve.",
    "El 'rizo' no sale de la textura (un afro negro no brilla): sale del borde y del volumen.",
    "Medir el volumen del pelo en la dirección de la cara (cabeza inclinada), no en vertical.",
    "Un calvo con pelo a los lados: poco pelo en la coronilla Y la coronilla del color de la piel.",
    "El pelo de otro jugador detrás: solo la mancha de pelo pegada a su cabeza.",
    "Mostrar SIEMPRE un surtido variado de jugadores (caras_variadas.py), no los de siempre.",
    "El tono de piel se mide en la parte ILUMINADA de la piel (55-90 % de claridad), no en la media.",
    "Piel clara con la saturación de la foto -> ROJA en el juego: llevarla al lugar de las pieles reales.",
    "Una sombra teñida de rojo (falso subsuelo) pinta media cara de rojo: solo un matiz.",
    "El pie del mapeo de tonos satura lo oscuro (~x1,7 en exponente): compensar en la piel.",
    "La normalización de exposición solo SUBE fotos oscuras; bajar las claras las bronceaba.",
    "Calvo: criterio conservador (una calva de más se ve peor que un rapado de más).",
    "La recreación dibujada queda peor que la malla aunque la foto sea mala: malla para todos.",
    "Pelo azul/verde = cielo o césped detrás: filtrar a colores de pelo naturales (pelo_natural).",
    "Iris de foto oscura sale gris verdoso: un iris oscuro es castaño (iris_natural).",
    "«Se ve sucio» (30-9): relieve de la foto 0,32 y acotado 0,86-1,1; bilateral 9/26/9.",
    "El iris 3D se centra en la abertura de SU malla; sin eso parecía bizco.",
    "Con cara real, los ojos 3D sin párpados propios (la malla ya los tiene).",
]


# EL LUGAR DE LAS PIELES REALES (claridad V de HSV -> saturación típica),
# sacado de tonos de referencia de piel (muy clara a muy oscura). Una piel
# clara con la saturación de la foto (flash, luz cálida) salía ROJA en el
# juego: la saturación se lleva a esta franja (+-0,05) y el tono a 14-24°.
LOCUS_PIEL = [(0.25, 0.46), (0.35, 0.46), (0.50, 0.44), (0.65, 0.39), (0.78, 0.33), (0.90, 0.27), (1.0, 0.22)]
TONO_PIEL = (14.0, 24.0)


def piel_realista(rgb):
    """Lleva un color de piel medido (sRGB 0-255) al lugar de las pieles
    reales conservando su claridad. Devuelve (rgb nuevo, rgb original)."""
    import colorsys
    h, s, v = colorsys.rgb_to_hsv(*(np.asarray(rgb, dtype=float) / 255.0))
    tono = h * 360.0
    tono = tono if tono < 180 else tono - 360
    tono = min(max(tono, TONO_PIEL[0]), TONO_PIEL[1])
    vs = [p[0] for p in LOCUS_PIEL]
    ss = [p[1] for p in LOCUS_PIEL]
    s_ok = float(np.interp(v, vs, ss))
    s = min(max(s, s_ok - 0.05), s_ok + 0.05)
    # Ni blanca quemada: la piel más clara real ronda V 0,9 (flash y
    # auto-niveles daban #ffe2cf, casi blanco, en el juego).
    v = min(v, 0.9)
    return np.array(colorsys.hsv_to_rgb((tono % 360) / 360.0, s, v)) * 255.0


def iris_natural(h):
    """Un iris creíble a partir de lo medido (las fotos no dan más que una
    pista: el iris ocupa pocos píxeles). Tres familias:
      - azul/gris: el azul pesa tanto como el rojo (ojo frío);
      - verde/avellana: el verde claramente por encima del rojo;
      - castaño (lo demás), de oscuro a claro según lo medido.
    Nunca gris verdoso ni negro (salían ojos de muerto)."""
    r, g, b = (int(h[i:i + 2], 16) for i in (1, 3, 5))
    claro = 0.299 * r + 0.587 * g + 0.114 * b
    t = min(max((claro - 25.0) / 90.0, 0.0), 1.0)
    if b >= r - 4 and claro > 45:
        c = np.array([62, 80, 96]) * (1 - t) + np.array([98, 120, 136]) * t
    elif g > r + 6 and claro > 50:
        c = np.array([70, 78, 46]) * (1 - t) + np.array([118, 122, 72]) * t
    else:
        c = np.array([44, 28, 18]) * (1 - t) + np.array([98, 68, 44]) * t
    return "#%02x%02x%02x" % tuple(int(x) for x in c)


def pelo_natural(h, respaldo="#2a211b"):
    """Un color de pelo natural (negro, castaño, rubio, pelirrojo, canoso). Si
    el medido tiene un matiz imposible (azul, verde: el cielo o el césped
    detrás), el castaño oscuro de respaldo; si es teñido claro (rubio platino),
    se deja. Tono 0-50°, o casi gris."""
    import colorsys
    r, g, b = (int(h[i:i + 2], 16) / 255.0 for i in (1, 3, 5))
    hh, ss, vv = colorsys.rgb_to_hsv(r, g, b)
    tono = hh * 360
    if ss < 0.12 or tono <= 50 or tono >= 345:
        return h
    return respaldo


def a_lineal(c):
    c = np.asarray(c, dtype=float) / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def a_srgb(l):
    l = np.clip(l, 0.0, 1.0)
    return np.where(l <= 0.0031308, l * 12.92, 1.055 * np.power(l, 1 / 2.4) - 0.055) * 255.0


def lum(c):
    return c[..., 0] * 0.2126 + c[..., 1] * 0.7152 + c[..., 2] * 0.0722


def _poligono(mask_img, pts, lado):
    from PIL import ImageDraw
    ImageDraw.Draw(mask_img).polygon([(float(u * lado), float(v * lado)) for u, v in pts], fill=255)


def _envolvente(pts):
    """Envolvente convexa (Andrew) de puntos 2D."""
    pts = sorted(set(map(tuple, np.round(pts, 5))))
    if len(pts) < 3:
        return pts
    def cruz(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    baja, alta = [], []
    for p in pts:
        while len(baja) >= 2 and cruz(baja[-2], baja[-1], p) <= 0:
            baja.pop()
        baja.append(p)
    for p in reversed(pts):
        while len(alta) >= 2 and cruz(alta[-2], alta[-1], p) <= 0:
            alta.pop()
        alta.append(p)
    return baja[:-1] + alta[:-1]


def regiones(uv, lado):
    """Máscaras (0-1, lado x lado) de ojos, cejas, labios, nariz y mandíbula."""
    out = {}
    for nombre, idx in (("ojos", (OJO_DER, OJO_IZQ)), ("cejas", (CEJA_DER, CEJA_IZQ)),
                        ("labios", (LABIOS_FUERA,)), ("nariz", (NARIZ_ABAJO,)), ("mandibula", (MANDIBULA,))):
        m = Image.new("L", (lado, lado), 0)
        for grupo in idx:
            pts = uv[grupo]
            _poligono(m, _envolvente(pts) if nombre in ("nariz", "mandibula", "cejas") else pts, lado)
        out[nombre] = np.asarray(m, dtype=float) / 255.0
    return out


def mascara_barba(uv, tris, barba, lado):
    """La barba medida por punto (color + textura), pintada triángulo a
    triángulo (media de sus tres puntos)."""
    import cv2
    m = np.zeros((lado, lado), np.float32)
    for t in tris:
        if max(t) >= len(barba):
            continue
        v = float(np.mean([barba[i] for i in t]))
        if v > 0.02:
            pts = np.round(uv[list(t)] * lado).astype(np.int32)
            cv2.fillPoly(m, [pts], v)
    return m


def albedo_limpio(cara, cat, uv, piel_srgb, wb, barba_m=None, cara_cls=3, pelo_cls=1):
    """LA PIEL REPLICADA. `cara`: recorte RGB (uint8, lado x lado); `cat`:
    clases del segmentador a la misma medida; `uv`: puntos (0-1); `piel_srgb`:
    su tono medido; `wb`: balance de blancos por canal (lineal).

    Piel = SU tono exacto (uno solo) x un relieve suave de la foto (poros y
    arrugas atenuados, sin la luz del fotógrafo ni las manchas de color).
    Rasgos (ojos, cejas, labios, orificios de la nariz, barba) = los píxeles de
    la foto, con el balance de blancos y la luz quitada a medias."""
    C = CONFIG
    lado = cara.shape[0]
    import cv2
    d, s1, s2 = C["bilateral"]
    suave = cv2.bilateralFilter(cara, d, s1, s2)
    lin = a_lineal(suave) * np.asarray(wb)[None, None, :]
    L = lum(lin)
    Lb = np.asarray(Image.fromarray(np.clip(L * 255 / max(L.max(), 1e-4), 0, 255).astype(np.uint8))
                    .filter(ImageFilter.GaussianBlur(C["luz_radio"])), dtype=float) / 255.0 * max(L.max(), 1e-4)
    Lb = np.maximum(Lb, 1e-4)
    relieve = np.clip((L / Lb) ** C["relieve_piel"], C["relieve_min"], C["relieve_max"])
    tono = a_lineal(piel_srgb)
    # Piel: su tono, con un poco del color propio del píxel (rubor de mejillas).
    croma = lin / np.maximum(L[..., None], 1e-4) * lum(tono)
    base = tono[None, None, :] * (1 - C["croma_propio"]) + croma * C["croma_propio"]
    piel = base * relieve[..., None]
    # Rasgos: foto con la luz quitada a medias (hacia la luz media de la cara).
    media = np.median(Lb[cat == cara_cls]) if (cat == cara_cls).any() else Lb.mean()
    rasgo = lin * ((media / Lb) ** C["rasgo_luz"])[..., None]
    reg = regiones(uv, lado)
    # Barba: la medida por punto (no "lo oscuro": la sombra de la mandíbula
    # también es oscura y no es barba).
    barba = (barba_m if barba_m is not None else np.zeros_like(L)) * (1 - reg["labios"])
    mascara = np.maximum.reduce([reg["ojos"], reg["cejas"], reg["labios"], reg["nariz"] * 0.8, barba])
    mascara = np.asarray(Image.fromarray((mascara * 255).astype(np.uint8))
                         .filter(ImageFilter.GaussianBlur(C["rasgo_suave"])), dtype=float) / 255.0
    # Fuera de la piel de la cara y del pelo (fondo, una mano): su tono.
    fuera = ~np.isin(cat, [cara_cls, pelo_cls])
    rasgo[fuera] = tono
    final = piel * (1 - mascara[..., None]) + rasgo * mascara[..., None]
    return a_srgb(final).astype(np.uint8)


def color_iris(cara, iris):
    """Color del iris. `iris`: por ojo, (centro, radio) en px. Se mide el
    ANILLO del iris (sin la pupila, del 45 al 90 % del radio) y solo su mitad
    de ABAJO (arriba cae la sombra del párpado y las pestañas); de ahí, la
    mediana. (Con el disco entero y el percentil 35, todos salían castaño
    oscuro, incluso los ojos azules.)"""
    muestras = []
    lado = cara.shape[0]
    ys, xs = np.mgrid[0:lado, 0:lado]
    for (cx, cy), r in iris:
        r = max(2.0, min(r, 14.0))
        d = np.hypot(xs - cx, ys - cy)
        anillo = (d >= r * 0.45) & (d <= r * 0.9) & (ys >= cy)
        px = cara[anillo].astype(float)
        if len(px) < 4:
            continue
        muestras.append(np.median(px, 0))
    if not muestras:
        return None
    m = np.mean(muestras, 0)
    return "#%02x%02x%02x" % tuple(int(v) for v in np.clip(m, 0, 255))

