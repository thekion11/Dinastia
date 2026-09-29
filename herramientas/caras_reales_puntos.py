#!/usr/bin/env python3
"""Ojos y boca de cada retrato real, para calzar la foto sobre la cara 3D.

Pasa YuNet (el mismo detector de `caras_reales_recortar.py`) por los retratos
de 256x256 ya recortados y guarda, normalizados de 0 a 1:

    datos/caras_reales_puntos.json  {nombre: [ojo_izq_x, ojo_izq_y,
                                              ojo_der_x, ojo_der_y,
                                              boca_x, boca_y]}

"izq"/"der" son los de la imagen (el ojo derecho del jugador cae a la
izquierda). Uso: python3 herramientas/caras_reales_puntos.py yunet.onnx
"""
import json
import os
import sys

import cv2

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "dinastia-godot")
INDICE = os.path.join(RAIZ, "datos", "caras_reales_recortes.json")
SALIDA = os.path.join(RAIZ, "datos", "caras_reales_puntos.json")


def main() -> None:
    modelo = sys.argv[1] if len(sys.argv) > 1 else "face_detection_yunet_2023mar.onnx"
    det = cv2.FaceDetectorYN.create(modelo, "", (256, 256), 0.6, 0.3, 50)
    indice = json.load(open(INDICE, encoding="utf-8"))
    salida = {}
    for nombre, fila in indice.items():
        img = cv2.imread(os.path.join(RAIZ, fila["archivo"]))
        if img is None:
            continue
        h, w = img.shape[:2]
        det.setInputSize((w, h))
        _, caras = det.detect(img)
        if caras is None or len(caras) == 0:
            continue
        c = max(caras, key=lambda k: k[2] * k[3])
        if c[14] < 0.7:
            continue
        ox1, oy1, ox2, oy2 = c[4], c[5], c[6], c[7]
        bx, by = (c[10] + c[12]) / 2.0, (c[11] + c[13]) / 2.0
        # Cara muy de perfil: los ojos casi juntos no sirven para calzar.
        if abs(ox2 - ox1) < 0.12 * w:
            continue
        salida[nombre] = [round(float(v), 4) for v in (ox1 / w, oy1 / h, ox2 / w, oy2 / h, bx / w, by / h)]
    json.dump(salida, open(SALIDA, "w", encoding="utf-8"), ensure_ascii=False, indent=0, sort_keys=True)
    print(f"{len(salida)} de {len(indice)} retratos con ojos y boca")


if __name__ == "__main__":
    main()
