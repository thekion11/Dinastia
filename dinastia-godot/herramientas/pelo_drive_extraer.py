#!/usr/bin/env python3
"""Saca peinados del OBJ «nv toufa» del Drive del dueño (105 grupos «samor_1125_NN», en cm, en rejilla) y los deja listos para Godot.
Cada peinado: se triangula, se decima (quadric) a ~OBJETIVO triángulos, se centra (x/z en el centro de su caja, y=0 en lo más alto) y se
normaliza a ANCHO 1,0, y se guarda como OBJ pequeño (posiciones + caras; las normales las calcula `pelo_drive_a_res.gd`).
Uso (venv con `pip install numpy fast-simplification`):
    python3 herramientas/pelo_drive_extraer.py pelo.obj SALIDA_DIR 73 74 77 79 ...
No sube nada a LFS: la salida son OBJ de unos KB.
"""
import sys, os, collections
import numpy as np
import fast_simplification as fs

OBJETIVO = int(os.environ.get("OBJETIVO", "800"))


def leer(ruta):
    V = []
    grupos = collections.OrderedDict()
    cur = None
    with open(ruta, "r", errors="ignore") as f:
        for linea in f:
            if linea.startswith("v "):
                p = linea.split()
                V.append((float(p[1]), float(p[2]), float(p[3])))
            elif linea.startswith("g ") or linea.startswith("o "):
                cur = linea[2:].strip()
                grupos.setdefault(cur, [])
            elif linea.startswith("f "):
                idx = [int(t.split("/")[0]) for t in linea.split()[1:]]
                grupos.setdefault(cur, []).append(idx)
    return np.array(V), grupos


def triangular(caras):
    tris = []
    for c in caras:
        c = [i - 1 if i > 0 else i for i in c]
        for k in range(1, len(c) - 1):
            tris.append((c[0], c[k], c[k + 1]))
    return np.array(tris, dtype=np.int32)


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        sys.exit(1)
    ruta, salida = sys.argv[1], sys.argv[2]
    ids = [int(a) for a in sys.argv[3:]]
    os.makedirs(salida, exist_ok=True)
    V, grupos = leer(ruta)
    for n in ids:
        nombre = "samor_1125_%d" % n if "samor_1125_%d" % n in grupos else "samor_1125_%02d" % n
        caras = grupos[nombre]
        tris = triangular(caras)
        usados = np.unique(tris)
        mapa = np.full(len(V), -1, dtype=np.int64)
        mapa[usados] = np.arange(len(usados))
        P = V[usados].astype(np.float32)
        T = mapa[tris].astype(np.int32)
        antes = len(T)
        if len(T) > OBJETIVO:
            ratio = 1.0 - OBJETIVO / float(len(T))
            P, T = fs.simplify(P, T, target_reduction=ratio, agg=6)
        lo, hi = P.min(0), P.max(0)
        ancho = hi[0] - lo[0]
        P = (P - np.array([(lo[0] + hi[0]) / 2.0, hi[1], (lo[2] + hi[2]) / 2.0], dtype=np.float32)) / ancho
        with open(os.path.join(salida, "pelo_%03d.obj" % n), "w") as f:
            f.write("# pelo nv toufa grupo %d: ancho 1.0, y=0 arriba, centro x/z. %d -> %d triángulos\n" % (n, antes, len(T)))
            for p in P:
                f.write("v %.5f %.5f %.5f\n" % tuple(p))
            for t in T:
                f.write("f %d %d %d\n" % (t[0] + 1, t[1] + 1, t[2] + 1))
        print("pelo %3d: %6d -> %4d triángulos, ancho original %.1f cm, alto %.2f, fondo %.2f (en anchos)" % (n, antes, len(T), ancho, (hi[1] - lo[1]) / ancho, (hi[2] - lo[2]) / ancho))


if __name__ == "__main__":
    main()
