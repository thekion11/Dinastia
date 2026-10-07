#!/usr/bin/env python3
"""RETRATOS DE LAS CARAS REALES (25-9-2026).

Las 1.219 fotos de futbolistas reales que bajó `caras_reales_buscar.ps1` de
Wikimedia Commons son fotos de prensa enteras: muchas son de cuerpo completo,
en plena jugada, y el recorte "cuadrado del centro" que hacía el juego dejaba
la cara del tamaño de un botón. Esta herramienta busca la cara con YuNet (el
detector de caras neuronal de OpenCV) y recorta cabeza y hombros alrededor de
ella, como el retrato de un manager moderno. De paso guarda cada retrato a
256x256, así el juego deja de decodificar fotos de 3.000 px en cada lista.

Uso (desde la raíz del repo):
    pip install opencv-python-headless pillow
    python herramientas/caras_reales_recortar.py --modelo face_detection_yunet_2023mar.onnx

El modelo sale de opencv_zoo (models/face_detection_yunet). Escribe:
    dinastia-godot/recursos/caras_reales_256/<nombre>.jpg
    dinastia-godot/datos/caras_reales_recortes.json   {nombre: {archivo, confianza, caja}}
    (y una hoja de contactos opcional con --hoja)
Las fotos originales no se tocan.
"""
import argparse
import json
import os
import sys

import cv2
import numpy as np
from PIL import Image, ImageOps

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "dinastia-godot")
REPORTE = os.path.join(RAIZ, "datos", "caras_reales_reporte.json")
SALIDA_DIR = os.path.join(RAIZ, "recursos", "caras_reales_256")
INDICE = os.path.join(RAIZ, "datos", "caras_reales_recortes.json")
CREDITOS = os.path.join(RAIZ, "datos", "creditos_fotos.txt")
LADO = 256
# Cabeza y hombros: el lado del cuadrado es 2,5 veces el alto de la cara, y la
# cara queda en el tercio superior (su centro, a 0,40 del borde de arriba).
ESCALA = 2.5
CENTRO_Y = 0.40
MAX_DETECCION = 1280


def detectar(detector, img_rgb):
    h, w = img_rgb.shape[:2]
    f = min(1.0, MAX_DETECCION / max(w, h))
    peq = cv2.resize(img_rgb, (int(w * f), int(h * f))) if f < 1.0 else img_rgb
    detector.setInputSize((peq.shape[1], peq.shape[0]))
    _, caras = detector.detect(cv2.cvtColor(peq, cv2.COLOR_RGB2BGR))
    if caras is None or len(caras) == 0:
        return None
    # La más grande entre las seguras: en una foto de grupo o con la grada
    # detrás, el retratado es el que ocupa más.
    mejor = max(caras, key=lambda c: c[2] * c[3] * (1.0 if c[14] > 0.75 else 0.2))
    x, y, cw, ch = (float(v) / f for v in mejor[:4])
    return x, y, cw, ch, float(mejor[14])


def recorte(w, h, caja):
    x, y, cw, ch, _ = caja
    lado = min(max(cw, ch) * ESCALA, w, h)
    cx = x + cw / 2.0
    cy = y + ch / 2.0
    x0 = min(max(0.0, cx - lado / 2.0), w - lado)
    y0 = min(max(0.0, cy - lado * CENTRO_Y), h - lado)
    return int(x0), int(y0), int(lado)


def recorte_viejo(w, h):
    lado = min(w, h)
    return (w - lado) // 2, max(0, int((h - lado) * 0.28)), lado


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--modelo", required=True)
    ap.add_argument("--hoja", help="PNG con una muestra antes/después")
    a = ap.parse_args()
    detector = cv2.FaceDetectorYN.create(a.modelo, "", (320, 320), 0.6, 0.3, 50)
    with open(REPORTE, encoding="utf-8-sig") as f:
        filas = [r for r in json.load(f) if r.get("encontrado") and r.get("archivo")]
    os.makedirs(SALIDA_DIR, exist_ok=True)
    indice = {}
    sin_cara = 0
    muestra = []
    for n, r in enumerate(filas):
        ruta = os.path.join(RAIZ, r["archivo"])
        if not os.path.exists(ruta):
            continue
        try:
            im = ImageOps.exif_transpose(Image.open(ruta)).convert("RGB")
        except Exception as e:  # noqa: BLE001 -una foto rota no para el lote
            print("  no se pudo abrir", ruta, e, file=sys.stderr)
            continue
        w, h = im.size
        caja = detectar(detector, np.asarray(im))
        if caja is None:
            sin_cara += 1
            x0, y0, lado = recorte_viejo(w, h)
            conf = 0.0
        else:
            x0, y0, lado = recorte(w, h, caja)
            conf = caja[4]
        ret = im.crop((x0, y0, x0 + lado, y0 + lado)).resize((LADO, LADO), Image.LANCZOS)
        nombre_archivo = os.path.splitext(os.path.basename(r["archivo"]))[0] + ".jpg"
        ret.save(os.path.join(SALIDA_DIR, nombre_archivo), quality=88, optimize=True)
        indice[r["nombre"]] = {
            "archivo": "recursos/caras_reales_256/" + nombre_archivo,
            "confianza": round(conf, 3),
            "caja": [x0, y0, lado],
            # Las licencias CC BY / BY-SA exigen nombrar autor y licencia, y
            # avisar de que la foto se modificó (aquí, recortada).
            "autor": r.get("autor") or "desconocido",
            "licencia": r.get("licencia") or "",
            "qid": r.get("qid") or "",
        }
        if a.hoja and len(muestra) < 48 and n % 25 == 0:
            vx, vy, vl = recorte_viejo(w, h)
            muestra.append((im.crop((vx, vy, vx + vl, vy + vl)).resize((128, 128)), ret.resize((128, 128))))
        if n % 100 == 0:
            print(f"  {n}/{len(filas)}")
    with open(INDICE, "w", encoding="utf-8") as f:
        json.dump(indice, f, ensure_ascii=False, indent=1, sort_keys=True)
    with open(CREDITOS, "w", encoding="utf-8") as f:
        f.write("CRÉDITOS DE LAS FOTOS DE JUGADORES REALES\n")
        f.write("Fotos de Wikimedia Commons (https://commons.wikimedia.org), recortadas\n")
        f.write("alrededor de la cara y reducidas a 256x256 por DINASTÍA. Cada una conserva\n")
        f.write("su licencia original, indicada junto al autor. Textos de las licencias:\n")
        f.write("https://creativecommons.org/licenses/  -  Dominio público: sin restricciones.\n\n")
        for nombre in sorted(indice):
            e = indice[nombre]
            f.write(f"{nombre}: foto de {e['autor']}, {e['licencia']}, Wikidata {e['qid']}\n")
    print(f"{len(indice)} retratos, {sin_cara} sin cara detectada (recorte de siempre)")
    if a.hoja and muestra:
        hoja = Image.new("RGB", (8 * 128, 12 * 128), (20, 30, 25))
        for k, (antes, despues) in enumerate(muestra):
            col, fila = k % 8, (k // 8) * 2
            hoja.paste(antes, (col * 128, fila * 128))
            hoja.paste(despues, (col * 128, (fila + 1) * 128))
        hoja.save(a.hoja)


if __name__ == "__main__":
    main()
