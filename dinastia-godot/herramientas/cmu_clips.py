#!/usr/bin/env python3
"""CMU Graphics Lab Motion Capture Database (BVH de Bruce Hahne/cgspeed) -> clips para nuestro esqueleto (sesión 10, 11-11-2026).

Licencia (mocap.cs.cmu.edu, citada en `READMEFIRST.txt` de la conversión): «This data is free for use in research and commercial projects
worldwide.» Se pide el agradecimiento: «The data used in this project was obtained from mocap.cs.cmu.edu. The database was created with
funding from NSF EIA-0196217.» (ya en `nucleo/creditos.gd`).

Entrada: la carpeta `data/` de https://github.com/sfd158/cmu-mocap (2.548 BVH; NO entran al repo).
Salida: un JSON con los clips elegidos (rotaciones locales a 30 fps, la pose en T del primer cuadro y las etiquetas); después
`herramientas/cmu_a_res.gd` los retargetea. Diferencias con 100STYLE: canales Z-Y-X, unidades propias (1 unidad = 5,644 cm), reposo que NO
es una T (la T es el cuadro 0), y 120 fps.
  python3 -I herramientas/cmu_clips.py /ruta/cmu-mocap/data salida.json"""
import importlib.util
import json
import math
import os
import sys

import numpy as np

AQUI = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("e100", os.path.join(AQUI, "estilo100_ciclos.py"))
e100 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(e100)
e100.TOBILLO_D, e100.TOBILLO_I = "RightFoot", "LeftFoot"
e100.FPS_ORIGEN = 120   # el detector de ciclos asume 60 fps (100STYLE)
CM = 5.644            # centímetros por unidad del BVH de CMU
FPS_O, FPS = 120, 30
PASO = FPS_O // FPS
MAX_S = 15.0          # los clips de acción se recortan a 15 s
DEDOS = ("Finger", "Thumb", "Index")

# --- selección: (archivo, tipo, momento del partido, nota)
CARRERA = ["09_%02d" % i for i in range(1, 12)] + ["35_%02d" % i for i in range(17, 27)] + ["127_03", "127_06", "127_07", "127_08"]
MARCHA = ["35_01", "35_02", "35_03", "35_04", "35_05", "09_12"]
FUTBOL = [("10_01", "patada_balon", "pase_tiro", "patadas al balón de fútbol"), ("10_02", "patada_balon", "pase_tiro", ""), ("10_03", "patada_balon", "pase_tiro", ""),
          ("10_05", "patada_balon", "pase_tiro", ""), ("10_06", "patada_balon", "pase_tiro", ""), ("11_01", "patada_balon", "pase_tiro", ""),
          ("33_01", "lanzar_atrapar", "saque_portero", "lanzar y atrapar un balón (fútbol americano)"), ("33_02", "lanzar_atrapar", "saque_portero", ""),
          ("34_01", "lanzar_atrapar", "saque_portero", ""), ("34_02", "lanzar_atrapar", "saque_portero", ""),
          ("124_12", "lanzar", "saque_de_banda", "lanzamiento a una mano por abajo"), ("124_11", "salto", "disputa_aerea", "salto a pies juntos"),
          ("16_03", "salto", "disputa_aerea", "salto alto"), ("16_04", "salto", "disputa_aerea", "salto alto"), ("13_10", "salto", "disputa_aerea", "salto para alcanzar"),
          ("13_12", "salto", "disputa_aerea", "salto para alcanzar"), ("14_07", "salto", "disputa_aerea", "salto para alcanzar"), ("86_01", "patada_salto", "disputa", "saltos, patadas y puñetazos")]
TRANSICION = [("127_%02d" % i, "transicion_carrera", "movimiento", "") for i in (4, 5, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26)] + \
             [("128_%02d" % i, "transicion_carrera", "movimiento", "") for i in (2, 3, 5, 6, 9, 10)] + [("16_08", "transicion_carrera", "movimiento", "trote y parada brusca")]
BAILE = [("60_%02d" % i, "baile_salsa", "celebracion", "salsa") for i in range(1, 16)] + \
        [("93_03", "baile_charleston", "celebracion", ""), ("93_08", "baile_charleston", "celebracion", "charleston elaborado"), ("93_06", "baile_lindy", "celebracion", "lindy hop")] + \
        [("94_%02d" % i, "baile_indio", "celebracion", "danza india") for i in range(1, 17)] + \
        [("15_04", "baile_varios", "celebracion", "Egyptian walk, the Dive, the Twist, Cabbage Patch"), ("15_05", "baile_varios", "celebracion", ""),
         ("18_15", "baile_pollo", "celebracion", "chicken dance"), ("20_01", "baile_pollo", "celebracion", ""),
         ("49_09", "baile_moderno", "celebracion", ""), ("49_12", "baile_moderno", "celebracion", ""), ("49_22", "baile_moderno", "celebracion", ""),
         ("05_02", "baile_moderno", "celebracion", ""), ("05_06", "baile_moderno", "celebracion", "")]
ACROBACIA = [("90_01", "acrobacia", "celebracion", "voltereta atrás"), ("90_02", "acrobacia", "celebracion", "voltereta lateral"), ("90_03", "acrobacia", "celebracion", ""),
             ("90_04", "acrobacia", "celebracion", ""), ("90_05", "acrobacia", "celebracion", "patada en salto"), ("90_08", "acrobacia", "celebracion", "mortal lateral"),
             ("90_09", "acrobacia", "celebracion", ""), ("90_11", "acrobacia", "celebracion", ""), ("90_14", "acrobacia", "celebracion", ""),
             ("85_01", "acrobacia", "celebracion", "salto con giro"), ("85_02", "acrobacia", "celebracion", ""), ("85_04", "baile_breakdance", "celebracion", "juego de pies"),
             ("85_08", "baile_breakdance", "celebracion", "helicóptero"), ("85_10", "baile_breakdance", "celebracion", ""), ("49_06", "acrobacia", "celebracion", "voltereta lateral"),
             ("90_16", "caida", "falta", "caer de cara"), ("90_17", "caida", "falta", "resbalón con cáscara de plátano"), ("90_18", "caida", "falta", "caída al tirarle de la alfombra")]
EMOCION = [("79_69", "emocion_alegria", "celebracion", "muy contento"), ("79_70", "emocion_risa", "celebracion", ""), ("80_43", "emocion_alegria", "celebracion", ""),
           ("79_71", "emocion_tristeza", "derrota", "triste"), ("79_72", "emocion_llanto", "derrota", ""), ("79_74", "emocion_enfado", "protesta", "enfadado"),
           ("79_73", "emocion_miedo", "reaccion", ""), ("142_08", "andar_alegre", "celebracion", ""), ("142_09", "andar_alegre", "celebracion", "alegría"),
           ("142_06", "andar_alegre", "celebracion", "eufórico"), ("142_05", "andar_triste", "derrota", "deprimido"), ("141_22", "choque_de_manos", "celebracion", "high five"),
           ("111_25", "gesto_encogerse", "protesta", "encoger los hombros"), ("141_21", "gesto_encogerse", "protesta", ""), ("111_37", "gesto_saludo", "saludo", "saludar con la mano"),
           ("113_27", "gesto_saludo", "saludo", ""), ("141_16", "gesto_saludo", "saludo", ""), ("111_02", "gesto_reverencia", "saludo", "reverencia"), ("113_02", "gesto_reverencia", "saludo", ""),
           ("56_02", "gesto_puños", "protesta", "puños arriba")]
ACCIONES = FUTBOL + TRANSICION + BAILE + ACROBACIA + EMOCION
ESPEJO = ("patada_balon", "lanzar", "transicion_carrera", "salto")   # tipos que llevan versión espejo (los demás son casi simétricos)


def ruta(base, ident):
    return os.path.join(base, ident.split("_")[0].zfill(3), ident + ".bvh")


def filtrar(juntas):
    """Quita los dedos: devuelve (juntas nuevas, índices que se conservan)."""
    keep = [i for i, d in enumerate(juntas) if not any(k in d["nombre"] for k in DEDOS)]
    remap = {old: new for new, old in enumerate(keep)}
    nuevas = [{"nombre": juntas[i]["nombre"], "padre": remap.get(juntas[i]["padre"], -1) if juntas[i]["padre"] >= 0 else -1, "offset": juntas[i]["offset"]} for i in keep]
    return nuevas, keep


def cargar(base, ident):
    juntas, datos = e100.leer_bvh(ruta(base, ident))
    # el último cuadro puede venir incompleto
    R, pos = e100.matrices(juntas, datos)
    return juntas, R, pos


def escalar(juntas):
    return [{"nombre": d["nombre"], "padre": d["padre"], "offset": [v * CM for v in d["offset"]]} for d in juntas]


def yaw_de(q):
    fx = 2 * (q[0] * q[2] + q[3] * q[1])
    fz = 1 - 2 * (q[0] ** 2 + q[1] ** 2)
    return math.atan2(fx, fz)


def girar_cadera(q, yaw):
    """Gira la cadera `-yaw` sobre Y (q: n,J,4)."""
    c, s = math.cos(-yaw / 2), math.sin(-yaw / 2)
    x1, y1, z1, w1 = 0.0, s, 0.0, c
    out = q.copy()
    for i in range(len(q)):
        x2, y2, z2, w2 = q[i, 0]
        out[i, 0] = [w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2, w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2,
                     w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2, w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2]
    return out


def etiquetas_movimiento(pos_cm, q, dt):
    """Velocidad al entrar y al salir (m/s), giro total del cuerpo y desplazamiento, sobre la cadera."""
    hp = pos_cm[:, [0, 2]] / 100.0
    n = len(hp)
    k = max(1, int(round(0.25 / dt)))
    v_in = np.linalg.norm(hp[min(k, n - 1)] - hp[0]) / (min(k, n - 1) * dt) if n > 1 else 0.0
    v_out = np.linalg.norm(hp[-1] - hp[max(0, n - 1 - k)]) / (min(k, n - 1) * dt) if n > 1 else 0.0
    yi, yo = yaw_de(q[0, 0]), yaw_de(q[-1, 0])
    giro = math.degrees(math.atan2(math.sin(yo - yi), math.cos(yo - yi)))
    desp = hp[-1] - hp[0]
    # dirección de salida respecto a la de entrada (rad, + izquierda): rumbo de la cadera al final menos al principio
    def rumbo(a, b):
        d = hp[b] - hp[a]
        return math.atan2(d[0], d[1]) if np.linalg.norm(d) > 0.02 else None
    ri, ro = rumbo(0, min(k, n - 1)), rumbo(max(0, n - 1 - k), n - 1)
    ang = None if ri is None or ro is None else math.atan2(math.sin(ro - ri), math.cos(ro - ri))
    return {"vel_entrada_ms": round(float(v_in), 2), "vel_salida_ms": round(float(v_out), 2), "giro_cuerpo_grados": round(giro, 1),
            "desplazamiento_adelante_m": round(float(desp[1]), 2), "desplazamiento_izquierda_m": round(float(desp[0]), 2),
            "cambio_direccion_rad": None if ang is None else round(ang, 3)}


def golpeos(juntas, R, pos, idx, dt):
    """Cuadros (30 fps) con picos de velocidad de la punta del pie (> 45 % del máximo) y qué pie."""
    pts, _, _ = e100.globales(juntas, R[idx], pos[idx], ["LeftToeBase", "RightToeBase"])
    res = []
    for lado, n in (("I", "LeftToeBase"), ("D", "RightToeBase")):
        p = pts[n] * CM / 100.0
        v = np.linalg.norm(np.diff(p, axis=0), axis=1) / dt
        mx = float(v.max()) if len(v) else 0.0
        for k in range(1, len(v) - 1):
            if v[k] > 0.45 * mx and v[k] >= v[k - 1] and v[k] > v[k + 1] and mx > 1.0:
                res.append({"cuadro": k + 1, "pie": lado, "velocidad_pie_ms": round(float(v[k]), 1)})
    res.sort(key=lambda r: r["cuadro"])
    return res


def clip_accion(base, ident, tipo, momento, nota):
    j0, R0, pos0 = cargar(base, ident)
    n0 = R0.shape[0]
    fin = min(n0, 1 + int(MAX_S * FPS_O))
    idx = list(range(1, fin, PASO))
    if len(idx) < 4:
        return None, None
    j, keep = filtrar(j0)
    R = R0[:, keep]
    q = e100.a_cuaternion(R[idx])
    q0 = e100.a_cuaternion(R[0:1])[0]
    yaw0 = yaw_de(q[0, 0])
    q = girar_cadera(q, yaw0)
    pos_cm = pos0[idx] * CM
    dt = 1.0 / FPS
    et = etiquetas_movimiento(pos_cm, q, dt)
    # la posición se mide con el giro de cadera original (no con el normalizado): se usa sólo la distancia, que no cambia
    clip = {"nombre": ident, "fuente": "CMU Mocap " + ident, "tipo": tipo, "momento": nota and momento or momento, "nota": nota, "cuadros": len(idx), "fps": FPS,
            "duracion": round(len(idx) / FPS, 2), "bucle": False, "espejo": tipo in ESPEJO,
            "alto_cadera_cm": [round(float(v), 2) for v in pos_cm[:, 1]], "alto_t_cm": round(float(pos0[0, 1] * CM), 2),
            "q0": [round(float(v), 5) for v in q0.reshape(-1)], "q": [round(float(v), 5) for v in q.reshape(-1)],
            "offsets": [list(d["offset"]) for d in j]}
    clip.update(et)
    if tipo in ("patada_balon", "lanzar_atrapar", "lanzar", "patada_salto", "salto"):
        clip["golpeos"] = golpeos(j, R, pos0, idx, dt)
    return clip, j


def clips_ciclo(base, ident, tipo):
    j0, R0, pos0 = cargar(base, ident)
    js = escalar(j0)
    pos = pos0 * CM
    F = R0.shape[0]
    ini, fin = 20, F - 20
    if fin - ini < 100:   # los clips de carrera de CMU duran ~1,3 s y un ciclo ~0,6 s
        return []
    cands, s, pts = e100.ventanas(js, R0, pos, ini, fin, "FR")
    sel = e100.elegir(cands, 120, 1)
    j, keep = filtrar(j0)
    q0 = e100.a_cuaternion(R0[0:1, keep])[0]
    out = []
    for n, (coste, a, b, info) in enumerate(sel):
        if coste > 1.0:
            continue
        q, alto, ya, yl = e100.empaquetar(js, R0, pos, a, b, pts, s, "FR", ident)
        q = q[:, keep]
        dur = (b - a) / FPS_O
        out.append({"nombre": "%s_ciclo" % ident, "fuente": "CMU Mocap " + ident, "tipo": tipo, "momento": "movimiento", "nota": "", "cuadros": len(q), "fps": FPS,
                    "duracion": round(dur, 3), "bucle": True, "espejo": True, "velocidad_ms": round(info["vel"] / 100.0, 2), "angulo_mov": round(info["ang"], 1),
                    "coste_cierre": round(float(coste), 3), "apoyos_D": e100.minimos(ya), "apoyos_I": e100.minimos(yl),
                    "pie_en_aire_inicio": "D" if ya[0] > yl[0] else "I",
                    "alto_cadera_cm": [round(float(v), 2) for v in alto], "alto_t_cm": round(float(pos0[0, 1] * CM), 2),
                    "q0": [round(float(v), 5) for v in q0.reshape(-1)], "q": [round(float(v), 5) for v in q.reshape(-1)],
                    "offsets": [list(d["offset"]) for d in j]})
    return out


def main():
    base, salida = sys.argv[1], sys.argv[2]
    res = {"juntas": None, "clips": []}
    for ident in CARRERA:
        for c in clips_ciclo(base, ident, "carrera"):
            res["clips"].append(c)
            print(c["nombre"], "ciclo %.2f m/s %.2f s coste %.3f" % (c["velocidad_ms"], c["duracion"], c["coste_cierre"]), flush=True)
    for ident in MARCHA:
        for c in clips_ciclo(base, ident, "marcha"):
            res["clips"].append(c)
            print(c["nombre"], "ciclo %.2f m/s" % c["velocidad_ms"], flush=True)
    for ident, tipo, momento, nota in ACCIONES:
        if not os.path.exists(ruta(base, ident)):
            print("NO EXISTE", ident)
            continue
        c, j = clip_accion(base, ident, tipo, momento, nota)
        if c is None:
            continue
        res["clips"].append(c)
        if res["juntas"] is None:
            res["juntas"] = [{"nombre": d["nombre"], "padre": d["padre"]} for d in j]
        print(ident, tipo, "%.1f s v_in %.1f v_out %.1f giro %.0f" % (c["duracion"], c["vel_entrada_ms"], c["vel_salida_ms"], c["giro_cuerpo_grados"]), flush=True)
    if res["juntas"] is None:
        j0, _, _ = cargar(base, CARRERA[0])
        res["juntas"] = [{"nombre": d["nombre"], "padre": d["padre"]} for d in filtrar(j0)[0]]
    with open(salida, "w") as f:
        json.dump(res, f, separators=(",", ":"))
    print("clips:", len(res["clips"]))


if __name__ == "__main__":
    main()
