#!/usr/bin/env python3
"""La recreación de los jugadores reales: piel, pelo y barba sacados de su foto.

Con esto la cara procedural de un jugador real se le parece aunque el juego no
enseñe la foto (Ajustes → «Caras reales: recreación»). Usa los retratos de
256x256 (`caras_reales_recortar.py`) y sus ojos y boca
(`caras_reales_puntos.py`), y guarda:

    datos/caras_reales_rasgos.json  {nombre: {"piel": "#rrggbb",
                                              "peloC": "#rrggbb",  (si se ve)
                                              "barba": 0-5}}

Barba con los mismos números del retrato (`Cara._barba`): 0 nada, 2 perilla,
4 barba completa, 5 barba de días. Ojos: índice de `Cara.IRIS`.

    python3 herramientas/caras_reales_rasgos.py
"""
import colorsys
import json
import os

from PIL import Image

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "dinastia-godot")
INDICE = os.path.join(RAIZ, "datos", "caras_reales_recortes.json")
PUNTOS = os.path.join(RAIZ, "datos", "caras_reales_puntos.json")
SALIDA = os.path.join(RAIZ, "datos", "caras_reales_rasgos.json")


def mediana(img, cx, cy, r):
    """Mediana por canal de un cuadrado de lado 2r+1 (en píxeles)."""
    w, h = img.size
    px = [img.getpixel((x, y)) for x in range(int(cx - r), int(cx + r) + 1)
          for y in range(int(cy - r), int(cy + r) + 1) if 0 <= x < w and 0 <= y < h]
    if not px:
        return None
    return tuple(sorted(c[i] for c in px)[len(px) // 2] for i in range(3))


def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def hexa(c):
    return "#%02x%02x%02x" % tuple(max(0, min(255, int(v))) for v in c)


def sat(c):
    return colorsys.rgb_to_hls(*(v / 255 for v in c))[2]


def distancia(a, b):
    return sum((x - y) ** 2 for x, y in zip(a, b)) ** 0.5


def rasgos(img, p):
    w, h = img.size
    ox1, oy1, ox2, oy2, bx, by = (p[0] * w, p[1] * h, p[2] * w, p[3] * h, p[4] * w, p[5] * h)
    ojos_y = (oy1 + oy2) / 2
    sep = abs(ox2 - ox1)
    d = max(by - ojos_y, 4.0)  # de los ojos a la boca
    r = max(2, int(sep * 0.08))
    # Piel: mejillas y tabique.
    muestras = [mediana(img, ox1, ojos_y + d * 0.55, r), mediana(img, ox2, ojos_y + d * 0.55, r),
                mediana(img, (ox1 + ox2) / 2, ojos_y + d * 0.3, r)]
    muestras = [m for m in muestras if m]
    if not muestras:
        return None
    piel = tuple(sorted(m[i] for m in muestras)[len(muestras) // 2] for i in range(3))
    # Pedido del usuario (30-9): los colores EXACTOS de la foto, sin llevarlos
    # a una escala de tonos.
    out = {"piel": hexa(piel)}
    # Ojos: el iris es un puntito; azul o verde si se nota, si no, marrón.
    iris = [mediana(img, x, y, 1) for x, y in ((ox1, oy1), (ox2, oy2))]
    iris = [c for c in iris if c]
    if iris:
        ir = tuple(sum(c[i] for c in iris) / len(iris) for i in range(3))
        if ir[2] > ir[0] + 12 and lum(ir) > 55:
            out["ojos"] = 3
        elif ir[1] > ir[0] + 8 and lum(ir) > 55:
            out["ojos"] = 2
        else:
            out["ojos"] = 1 if lum(ir) < 45 else 0
    # Pelo: franja por encima de la frente (arriba de las cejas).
    pelo = [mediana(img, (ox1 + ox2) / 2 + k * sep * 0.35, ojos_y - d * f, r) for k in (-1, 0, 1) for f in (1.2, 1.4, 1.6)]
    pelo = [m for m in pelo if m]
    if pelo:
        # Una de las más oscuras (la segunda de nueve): el fondo suele ser más
        # claro que el pelo, pero la más oscura de todas borraba a los rubios.
        pc = sorted(pelo, key=lum)[min(1, len(pelo) - 1)]
        # Si parece piel (calvo, entradas) o el fondo claro, no se toca.
        if distancia(pc, piel) > 35 and lum(pc) < 175:
            out["peloC"] = hexa(pc)
    # Barba: el pelo es más oscuro Y menos saturado que la piel; una sombra
    # (bajo el labio, de la nariz) oscurece pero conserva la saturación de la
    # piel. Calibrado a mano con 22 retratos: se prefiere no poner barba a
    # ponerla donde no hay.
    lp = max(lum(piel), 1.0)
    sp = max(sat(piel), 0.01)

    # En piel oscura la diferencia con el pelo es menor y el contraste de la
    # foto engaña más: hace falta más evidencia.
    oscura = lp < 90

    def es_pelo(c, tope=0.6, tope_s=0.8):
        if oscura:
            tope, tope_s = tope * 0.75, tope_s * 0.85
        return c is not None and lum(c) / lp < tope and sat(c) / sp < tope_s

    menton = mediana(img, bx, by + d * 0.6, r)
    bigote = mediana(img, bx, by - d * 0.2, r)
    quijada = [mediana(img, x, by + d * 0.15, r) for x in (ox1 - sep * 0.05, ox2 + sep * 0.05)]
    m_pelo = es_pelo(menton)
    q_pelo = all(es_pelo(q) for q in quijada)
    b_pelo = es_pelo(bigote)
    barba = 0
    if m_pelo and (q_pelo or b_pelo):
        barba = 4
    elif m_pelo:
        barba = 2
    elif b_pelo or es_pelo(menton, 0.75, 0.82):
        # Un bigote solo casi nunca es bigote (sombra de la nariz, labio):
        # como mucho, barba de días.
        barba = 5
    out["barba"] = barba
    return out


def main() -> None:
    indice = json.load(open(INDICE, encoding="utf-8"))
    puntos = json.load(open(PUNTOS, encoding="utf-8"))
    salida = {}
    for nombre, p in puntos.items():
        fila = indice.get(nombre)
        if not fila:
            continue
        try:
            img = Image.open(os.path.join(RAIZ, fila["archivo"])).convert("RGB")
        except OSError:
            continue
        r = rasgos(img, p)
        if r:
            salida[nombre] = r
    json.dump(salida, open(SALIDA, "w", encoding="utf-8"), ensure_ascii=False, indent=0, sort_keys=True)
    print(f"{len(salida)} jugadores reales con piel, pelo y barba de su foto")


if __name__ == "__main__":
    main()
