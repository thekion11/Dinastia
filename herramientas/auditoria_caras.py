#!/usr/bin/env python3
"""AUDITORÍA AUTOMÁTICA DE LAS CARAS REALES (30-9-2026).

Revisa, jugador por jugador, lo que el motor midió y produjo, y marca lo que
sale de lo razonable. No reemplaza mirar las hojas de `captura_lote_caras.gd`:
sirve para saber CUÁLES mirar con lupa y para contar sin engañarse.

    python3 herramientas/auditoria_caras.py   -> dinastia-godot/AUDITORIA_CARAS.md
"""
import base64
import colorsys
import json
import os

import numpy as np
from PIL import Image

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "dinastia-godot")
MALLAS = os.path.join(RAIZ, "datos", "caras_reales_mallas.json")
TOPO = os.path.join(RAIZ, "datos", "cara_malla_topologia.json")
SALIDA = os.path.join(RAIZ, "AUDITORIA_CARAS.md")
PIEL_LISA = [50, 280, 101, 330, 108, 337, 151, 9, 10, 117, 346, 118, 347, 123, 352, 205, 425, 36, 266]


def hexa(h):
    return np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)], dtype=float)


def main():
    m = json.load(open(MALLAS, encoding="utf-8"))
    n = json.load(open(TOPO, encoding="utf-8"))["n"]
    problemas = {}
    cuenta = {}

    def marca(nombre, que):
        problemas.setdefault(nombre, []).append(que)
        clave = que.split(":")[0].split(" (")[0]
        cuenta[clave] = cuenta.get(clave, 0) + 1

    for nombre, v in sorted(m.items()):
        if v.get("mala"):
            marca(nombre, "recreación: foto inservible para 3D (giro %s, cabeceo %s)" % (v.get("giro"), v.get("cabeceo")))
            continue
        s = v.get("s")
        if not s:
            marca(nombre, "sin piel medida")
            continue
        h, sat, val = colorsys.rgb_to_hsv(*(hexa(s) / 255))
        if not (8 / 360 <= h <= 28 / 360):
            marca(nombre, "tono de piel raro: %s (%.0f°)" % (s, h * 360))
        if val < 0.18 or val > 0.91:
            marca(nombre, "claridad de piel extrema: %s" % s)
        if not v.get("a") or not os.path.exists(os.path.join(RAIZ, v["a"])):
            marca(nombre, "sin textura limpia")
        else:
            a = np.asarray(Image.open(os.path.join(RAIZ, v["a"])).convert("RGB"), dtype=float)
            datos = np.frombuffer(base64.b64decode(v["m"]), "<i2").reshape(n, 5)
            uv = datos[:468, 3:5] / 32767.0
            # Solo piel lisa: mejillas y frente (labios, cejas, ojos y barba
            # varían de color por naturaleza).
            uv = uv[PIEL_LISA]
            px = a[np.clip((uv[:, 1] * 383).astype(int), 0, 383), np.clip((uv[:, 0] * 383).astype(int), 0, 383)]
            # Manchas: variación de color en la piel de la cara replicada.
            croma = px / np.maximum(px.sum(1, keepdims=True), 1)
            if croma.std(0).max() > 0.03:
                marca(nombre, "piel con manchas de color (%.3f)" % croma.std(0).max())
        iris = v.get("iris")
        if iris:
            li = hexa(iris) @ np.array([0.299, 0.587, 0.114])
            if li < 12:
                marca(nombre, "iris casi negro: %s" % iris)
        else:
            marca(nombre, "sin color de iris")
        t = v.get("t")
        if t:
            tap = (np.frombuffer(base64.b64decode(t), np.uint8) > 0).mean()
            if tap > 0.1:
                marca(nombre, "cara tapada en la foto: %.0f%%" % (tap * 100))
        hp = v.get("h")
        if not hp:
            marca(nombre, "sin pelo medido")
        elif hp.get("alto", 0) > 14:
            marca(nombre, "pelo muy alto (¿mal medido?): %.1f" % hp["alto"])
        if abs(v.get("giro", 0)) > 40:
            marca(nombre, "foto muy de lado: %.0f°" % v["giro"])

    total = len(m)
    malas = sum(1 for v in m.values() if v.get("mala"))
    lineas = ["# Auditoría de caras reales", "",
              "Generado por `herramientas/auditoria_caras.py`. Automático: marca lo que se sale de lo",
              "razonable para mirarlo en las hojas de lotes (`pruebas/captura_lote_caras.gd`).", "",
              f"- Jugadores con cara 3D: **{total - malas}** de {total} (recreación: {malas}).",
              f"- Sin ninguna marca: **{total - len(problemas)}**.", "", "## Marcas por tipo", ""]
    for k, c in sorted(cuenta.items(), key=lambda x: -x[1]):
        lineas.append(f"- {k}: {c}")
    lineas += ["", "## Por jugador", ""]
    for nombre, ps in sorted(problemas.items()):
        lineas.append(f"- **{nombre}**: " + "; ".join(ps))
    open(SALIDA, "w", encoding="utf-8").write("\n".join(lineas) + "\n")
    print(f"{total} jugadores, {len(problemas)} con marcas. Informe: {SALIDA}")
    for k, c in sorted(cuenta.items(), key=lambda x: -x[1]):
        print(f"  {k}: {c}")


if __name__ == "__main__":
    main()
