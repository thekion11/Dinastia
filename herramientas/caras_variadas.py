#!/usr/bin/env python3
"""Elige un surtido VARIADO de jugadores reales con cara 3D, para revisar que
el nivel se repite en todos (no solo en los de siempre): piel clara, piel
oscura, rizado, pelo largo, rapado o calvo, barba cerrada, foto de tres
cuartos... Imprime los nombres separados por comas (para CARAS=).

    python3 herramientas/caras_variadas.py [semilla] [cuantos]
"""
import base64
import json
import os
import random
import sys

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "dinastia-godot")


def lum(h):
    return 0.299 * int(h[1:3], 16) + 0.587 * int(h[3:5], 16) + 0.114 * int(h[5:7], 16)


def main():
    semilla = int(sys.argv[1]) if len(sys.argv) > 1 else random.randint(0, 9999)
    cuantos = int(sys.argv[2]) if len(sys.argv) > 2 else 6
    rnd = random.Random(semilla)
    m = json.load(open(os.path.join(RAIZ, "datos", "caras_reales_mallas.json"), encoding="utf-8"))
    def barba(v):
        b = base64.b64decode(v.get("b", ""))
        return sum(b) / max(len(b), 1) / 255
    grupos = {
        "piel clara": [k for k, v in m.items() if v.get("s") and lum(v["s"]) > 175],
        "piel oscura": [k for k, v in m.items() if v.get("s") and lum(v["s"]) < 85],
        "rizado": [k for k, v in m.items() if v.get("h", {}).get("rizo", 0) > 0.85],
        "pelo largo": [k for k, v in m.items() if v.get("h", {}).get("largo", 0) > 0.5],
        "rapado o calvo": [k for k, v in m.items() if not v.get("h") or v["h"].get("alto", 9) < 6.6],
        "barba cerrada": [k for k, v in m.items() if barba(v) > 0.17],
    }
    elegidos = []
    for nombre, lista in grupos.items():
        libres = [x for x in lista if x not in elegidos]
        if libres and len(elegidos) < cuantos:
            elegidos.append(rnd.choice(libres))
            print(f"# {nombre}: {elegidos[-1]}", file=sys.stderr)
    while len(elegidos) < cuantos:
        x = rnd.choice(list(m))
        if x not in elegidos:
            elegidos.append(x)
    print(",".join(elegidos))


if __name__ == "__main__":
    main()
