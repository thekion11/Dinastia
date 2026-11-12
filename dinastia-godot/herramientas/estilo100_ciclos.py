#!/usr/bin/env python3
"""100STYLE -> ciclos de locomoción (sesión 10, 11-11-2026).

Entrada: la carpeta `100STYLE/` descomprimida de https://zenodo.org/records/8127870 (Ian Mason et al., CC BY 4.0).
Salida: un JSON con los ciclos elegidos (rotaciones LOCALES en cuaterniones, 30 fps) y su catálogo de etiquetas.
Después `herramientas/estilo100_a_res.gd` los retargetea a nuestro esqueleto.

  python3 -I herramientas/estilo100_ciclos.py /ruta/a/100STYLE salida.json [estilo1,estilo2,...]

Para cada estilo y movimiento (FW marcha adelante, FR carrera adelante, BW/BR atrás, SW/SR lateral, ID reposo) busca dentro del
tramo útil de `Frame_Cuts.csv` las ventanas de UN ciclo completo (dos pasos) donde la pose del final es la del principio, la
marcha es recta y la velocidad estable; el cierre se ajusta con una mezcla de los últimos cuadros. Marco de ejes: igual que el
esqueleto de Quaternius (Y arriba, mira a +Z, izquierda +X), así que las rotaciones locales se usan tal cual.
"""
import csv
import json
import math
import os
import sys

import numpy as np
_sys_rs = __import__("sys"); _os_rs = __import__("os")
_sys_rs.path.insert(0, _os_rs.path.join(_os_rs.path.dirname(_os_rs.path.abspath(__file__)), "..", "..", "herramientas"))
from ruta_segura import ruta_segura  # noqa: E402  (rutas por argumento: SonarCloud S8707)

FPS_ORIGEN = 60
FPS_SALIDA = 30
MOV = {"FW": ("marcha", 0.0), "FR": ("carrera", 0.0), "BW": ("marcha_atras", 180.0), "BR": ("carrera_atras", 180.0),
       "SW": ("marcha_lateral", 90.0), "SR": ("carrera_lateral", 90.0), "ID": ("reposo", None)}
ESTILOS_DEF = ["Neutral", "Proud", "Angry", "Rushed", "Elated", "Depressed", "Old", "Heavyset", "BigSteps", "HighKnees",
               "March", "Strutting", "Stiff", "Crouched", "Followed", "CrowdAvoidance"]
CLAVES_POSE = None
TOBILLO_D, TOBILLO_I = "RightAnkle", "LeftAnkle"   # otros esqueletos (CMU: RightFoot / LeftFoot) los cambian


def leer_bvh(ruta):
    with open(ruta_segura(ruta), "r", encoding="ascii") as f:
        lin = f.read().split("\n")
    juntas, pila, i = [], [], 0
    while not lin[i].strip().startswith("MOTION"):
        t = lin[i].split()
        if t and t[0] in ("ROOT", "JOINT"):
            juntas.append({"nombre": t[1], "padre": pila[-1] if pila else -1, "offset": None, "canales": []})
            pila.append(len(juntas) - 1)
        elif t and t[0] == "End":
            pila.append(-2)
        elif t and t[0] == "OFFSET" and pila and pila[-1] >= 0:
            juntas[pila[-1]]["offset"] = [float(x) for x in t[1:4]]
        elif t and t[0] == "CHANNELS":
            juntas[pila[-1]]["canales"] = t[2:]
        elif t and t[0] == "}":
            pila.pop()
        i += 1
    n = int(lin[i + 1].split()[1])
    datos = np.array([[float(x) for x in l.split()] for l in lin[i + 3:i + 3 + n]], dtype=np.float64)
    return juntas, datos


def rot_eje(eje, ang):
    c, s = np.cos(ang), np.sin(ang)
    m = np.zeros(ang.shape + (3, 3))
    m[..., 0, 0] = m[..., 1, 1] = m[..., 2, 2] = 1.0
    a, b = {"X": (1, 2), "Y": (2, 0), "Z": (0, 1)}[eje]
    m[..., a, a] = c
    m[..., b, b] = c
    m[..., a, b] = -s
    m[..., b, a] = s
    return m


def matrices(juntas, datos):
    """Matrices locales (F,J,3,3) y posición de la raíz (F,3). El orden de los canales del BVH se aplica de izquierda a derecha."""
    F = datos.shape[0]
    R = np.zeros((F, len(juntas), 3, 3))
    col, pos = 0, None
    for j, d in enumerate(juntas):
        canales = d["canales"]
        m = np.broadcast_to(np.eye(3), (F, 3, 3)).copy()
        for c in canales:
            v = datos[:, col]
            col += 1
            if c.endswith("position"):
                if pos is None:
                    pos = np.zeros((F, 3))
                pos[:, "XYZ".index(c[0])] = v
            else:
                m = m @ rot_eje(c[0], np.radians(v))
        R[:, j] = m
    return R, pos


def a_cuaternion(m):
    """Matrices (...,3,3) -> cuaterniones (x,y,z,w)."""
    sh = m.shape[:-2]
    m = m.reshape(-1, 3, 3)
    q = np.zeros((m.shape[0], 4))
    tr = m[:, 0, 0] + m[:, 1, 1] + m[:, 2, 2]
    for k in range(m.shape[0]):
        a = m[k]
        if tr[k] > 0:
            s = math.sqrt(tr[k] + 1.0) * 2
            q[k] = [(a[2, 1] - a[1, 2]) / s, (a[0, 2] - a[2, 0]) / s, (a[1, 0] - a[0, 1]) / s, 0.25 * s]
        elif a[0, 0] > a[1, 1] and a[0, 0] > a[2, 2]:
            s = math.sqrt(1.0 + a[0, 0] - a[1, 1] - a[2, 2]) * 2
            q[k] = [0.25 * s, (a[0, 1] + a[1, 0]) / s, (a[0, 2] + a[2, 0]) / s, (a[2, 1] - a[1, 2]) / s]
        elif a[1, 1] > a[2, 2]:
            s = math.sqrt(1.0 + a[1, 1] - a[0, 0] - a[2, 2]) * 2
            q[k] = [(a[0, 1] + a[1, 0]) / s, 0.25 * s, (a[1, 2] + a[2, 1]) / s, (a[0, 2] - a[2, 0]) / s]
        else:
            s = math.sqrt(1.0 + a[2, 2] - a[0, 0] - a[1, 1]) * 2
            q[k] = [(a[0, 2] + a[2, 0]) / s, (a[1, 2] + a[2, 1]) / s, 0.25 * s, (a[1, 0] - a[0, 1]) / s]
    q /= np.linalg.norm(q, axis=1, keepdims=True)
    return q.reshape(sh + (4,))


def slerp(a, b, t):
    d = float(np.dot(a, b))
    if d < 0:
        b, d = -b, -d
    if d > 0.9995:
        r = a + (b - a) * t
    else:
        th = math.acos(d)
        r = (math.sin((1 - t) * th) * a + math.sin(t * th) * b) / math.sin(th)
    return r / np.linalg.norm(r)


def globales(juntas, R, pos, nombres):
    """Posición global (F,3) de cada articulación pedida (cm)."""
    F = R.shape[0]
    idx = {d["nombre"]: i for i, d in enumerate(juntas)}
    G = {}
    P = {}
    for j, d in enumerate(juntas):
        off = np.array(d["offset"])
        if d["padre"] < 0:
            G[j] = R[:, j]
            P[j] = pos
        else:
            p = d["padre"]
            P[j] = P[p] + np.einsum("fab,b->fa", G[p], off)
            G[j] = G[p] @ R[:, j]
    return {n: P[idx[n]] for n in nombres}, G, idx


def ventanas(juntas, R, pos, ini, fin, tipo):
    """Mejores ventanas de un ciclo. Devuelve [(coste, a, b, info)]."""
    F = R.shape[0]
    pts, G, idx = globales(juntas, R, pos, [TOBILLO_D, TOBILLO_I])
    h = G[idx["Hips"]]
    fwd = h[:, :, 2]
    left = h[:, :, 0]
    hp = pos[:, [0, 2]]
    k = 6
    vel = np.zeros_like(hp)
    vel[k:-k] = (hp[2 * k:] - hp[:-2 * k]) / (2 * k / FPS_ORIGEN)   # cm/s
    nombre, ang_esp = MOV[tipo]
    out = []
    ya, yl = pts[TOBILLO_D][:, 1], pts[TOBILLO_I][:, 1]
    s = yl - ya
    ini, fin = max(ini, 40), min(fin, F - 40)
    if tipo == "ID":
        largos = [150, 210, 270]
        pasos = 15
    else:
        seg = s[ini:fin] - s[ini:fin].mean()
        ac = np.correlate(seg, seg, "full")[len(seg) - 1:]
        ac /= max(ac[0], 1e-9)
        lo, hi = 24, 150
        lag = lo + int(np.argmax(ac[lo:hi]))
        largos = [lag]
        pasos = 4
    pose = np.concatenate([R[:, 1:].reshape(F, -1)], axis=1)
    for L in largos:
        for a in range(ini, fin - L - 1, pasos):
            b = a + L
            dp = np.linalg.norm(pose[a] - pose[b]) / math.sqrt(R.shape[1])
            v = vel[a:b]
            sp = np.linalg.norm(v, axis=1)
            vm = sp.mean()
            if tipo == "ID":
                if vm > 12:
                    continue
                coste = dp + 0.02 * float(np.abs(pos[b, 1] - pos[a, 1]))
                info = {"vel": vm, "ang": 0.0}
            else:
                if vm < 25:
                    continue
                vf = np.einsum("fa,fa->f", v, fwd[a:b][:, [0, 2]])
                vl = np.einsum("fa,fa->f", v, left[a:b][:, [0, 2]])
                ang = np.degrees(np.arctan2(vl.mean(), vf.mean()))
                atras = math.isclose(ang_esp, 180.0)   # S1244: los ángulos esperados son 0, 90 o 180 exactos, pero se comparan con tolerancia
                dif = abs(abs(ang) - ang_esp) if (math.isclose(ang_esp, 0.0) or atras) else abs(abs(ang) - 90.0)
                if atras:
                    dif = 180.0 - abs(ang)
                if dif > 25:
                    continue
                dir_v = np.arctan2(v[:, 1], v[:, 0])
                recta = float(np.degrees(np.abs(np.unwrap(dir_v)[-1] - np.unwrap(dir_v)[0])))
                yaw = np.arctan2(fwd[a:b, 0], fwd[a:b, 2])
                giro = float(np.degrees(np.abs(np.unwrap(yaw)[-1] - np.unwrap(yaw)[0])))
                varv = float(sp.std() / max(vm, 1.0))
                coste = dp + 0.01 * recta + 0.01 * giro + 0.5 * varv + 0.01 * dif
                info = {"vel": vm, "ang": float(ang)}
            out.append((coste, a, b, info))
    out.sort(key=lambda x: x[0])
    return out, s, pts


def elegir(cands, minsep, n):
    res = []
    for c in cands:
        if all(abs(c[1] - r[1]) >= minsep for r in res):
            res.append(c)
        if len(res) >= n:
            break
    return res


def empaquetar(juntas, R, pos, a, b, pts, s, tipo, estilo):
    """Un ciclo [a,b) a 30 fps con el cierre suavizado, y sus etiquetas."""
    idx = list(range(a, b, FPS_ORIGEN // FPS_SALIDA))
    n = len(idx)
    q = a_cuaternion(R[idx])   # (n,J,4)
    alto = pos[idx, 1].copy()
    q = normalizar_rumbo(q)
    k = max(3, min(5, n // 6))
    for i in range(k):
        w = 0.5 * (i + 1) / (k + 1)   # el último cuadro se acerca al primero (el siguiente a repetir)
        j = n - k + i
        for jj in range(q.shape[1]):
            q[j, jj] = slerp(q[j, jj], q[0, jj], w * 2 if i == k - 1 else w)
        alto[j] = alto[j] * (1 - w) + alto[0] * w
    ya = pts[TOBILLO_D][idx, 1]
    yl = pts[TOBILLO_I][idx, 1]
    return q, alto, ya, yl


def normalizar_rumbo(q):
    """El BVH conserva el rumbo absoluto del actor: se gira la cadera para que la media del ciclo mire a +Z."""
    h = q[:, 0]
    fx = 2 * (h[:, 0] * h[:, 2] + h[:, 3] * h[:, 1])
    fz = 1 - 2 * (h[:, 0] ** 2 + h[:, 1] ** 2)
    medio = math.atan2(float(np.sin(np.arctan2(fx, fz)).mean()), float(np.cos(np.arctan2(fx, fz)).mean()))
    c, sn = math.cos(-medio / 2), math.sin(-medio / 2)
    r = np.array([0.0, sn, 0.0, c])   # giro sobre Y de -medio
    out = q.copy()
    for i in range(len(q)):
        x1, y1, z1, w1 = r
        x2, y2, z2, w2 = q[i, 0]
        out[i, 0] = [w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2, w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2,
                     w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2, w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2]
    return out


def minimos(y):
    """Cuadros donde el pie toca el suelo (mínimos locales de altura)."""
    n = len(y)
    res = []
    for i in range(n):
        if y[i] <= y[(i - 1) % n] and y[i] < y[(i + 1) % n] and y[i] <= np.percentile(y, 35):
            res.append(i)
    return res


def main():
    carpeta, salida = sys.argv[1], sys.argv[2]
    estilos = sys.argv[3].split(",") if len(sys.argv) > 3 else ESTILOS_DEF
    cortes = {}
    with open(ruta_segura(os.path.join(carpeta, "Frame_Cuts.csv")), newline="") as f:
        for fila in csv.DictReader(f):
            cortes[fila["STYLE_NAME"]] = fila
    res = {"juntas": None, "clips": []}
    for st in estilos:
        for tipo in MOV:
            ruta = os.path.join(carpeta, st, "%s_%s.bvh" % (st, tipo))
            c = cortes[st]
            if not os.path.exists(ruta) or c[tipo + "_START"] == "N/A":
                continue
            juntas, datos = leer_bvh(ruta)
            if res["juntas"] is None:
                res["juntas"] = [{"nombre": d["nombre"], "padre": d["padre"], "offset": d["offset"]} for d in juntas]
            R, pos = matrices(juntas, datos)
            cands, s, pts = ventanas(juntas, R, pos, int(c[tipo + "_START"]), int(c[tipo + "_STOP"]), tipo)
            quedan = 1 if tipo == "ID" else (3 if tipo in ("SW", "SR") else 2)
            sel = elegir(cands, 120, quedan)
            if tipo in ("SW", "SR"):   # un ciclo hacia cada lado, si los hay
                izq = [x for x in cands if x[3]["ang"] > 0][:1]
                der = [x for x in cands if x[3]["ang"] < 0][:1]
                sel = izq + der
            for n, (coste, a, b, info) in enumerate(sel):
                q, alto, ya, yl = empaquetar(juntas, R, pos, a, b, pts, s, tipo, st)
                nombre = "%s_%s_%d" % (st, tipo, n + 1)
                dur = (b - a) / FPS_ORIGEN
                clip = {"nombre": nombre, "estilo": st, "mov": tipo, "tipo": MOV[tipo][0], "cuadros": len(q),
                        "fps": FPS_SALIDA, "duracion": round(dur, 3), "velocidad_ms": round(info["vel"] / 100.0, 2),
                        "angulo_mov": round(info["ang"], 1), "coste_cierre": round(float(coste), 3),
                        "apoyos_D": minimos(ya), "apoyos_I": minimos(yl),
                        "pie_en_aire_inicio": "D" if ya[0] > yl[0] else "I",
                        "toque_balon": None, "bucle": True,
                        "alto_cadera_cm": [round(float(v), 2) for v in alto],
                        "q": [round(float(v), 5) for v in q.reshape(-1)]}
                res["clips"].append(clip)
                print(nombre, "vel %.2f m/s ang %+.0f dur %.2f coste %.3f" % (info["vel"] / 100, info["ang"], dur, coste), flush=True)
    with open(ruta_segura(salida), "w") as f:
        json.dump(res, f, separators=(",", ":"))
    print("clips:", len(res["clips"]))


if __name__ == "__main__":
    main()
