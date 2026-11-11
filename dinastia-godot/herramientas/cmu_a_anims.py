#!/usr/bin/env python3
"""Catálogo de CMU (`terceros/cmu/catalogos/`) -> lo que usa el motor (sesión 10, 11-11-2026).
 · `datos/anims_extra/cmu.json`: los ciclos de carrera reales (3,2-4,3 m/s) en el formato de `LeagueCatalogo` (con espejo).
 · `datos/anims_accion_cmu.json`: acciones por momento del partido (patada, saque, salto, baile, acrobacia, emoción, gesto, caída, transiciones de carrera)
   con duración, velocidad de entrada y salida, giro y cuadro de golpeo.
 · `terceros/cmu/uso_clips.json`: la lista de clips que van a la biblioteca de uso (`anims_uso_a_res.gd`).
  python3 -I herramientas/cmu_a_anims.py"""
import glob, json, math, os
raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
cat = json.load(open(os.path.join(raiz, "terceros/cmu/catalogos/animaciones_catalogo_cmu.json"), encoding="utf-8"))
USO = "res://assets/characters/quaternius/anims_cmu/cmu_uso.res"
ORIGEN = "res://terceros/cmu/biblioteca/cmu.res"
por = {c["nombre"]: c for c in cat}
base = lambda c: c["nombre"][:-len("_espejo")] if c["nombre"].endswith("_espejo") else c["nombre"]
ELEGIR = {  # momento -> ids de CMU
    "pase_y_tiro": ["10_01", "10_02", "10_03", "10_05", "10_06", "11_01"],
    "saque_de_banda_y_portero": ["124_12", "33_01", "33_02", "34_01", "34_02"],
    "disputa_aerea": ["16_03", "16_04", "124_11", "13_10"],
    "transiciones_de_carrera": ["127_04", "127_05", "127_09", "127_10", "127_13", "127_14", "127_15", "127_16", "127_17", "127_23", "128_05", "16_08"],
    "celebracion_baile": ["60_%02d" % i for i in range(1, 16)] + ["93_03", "93_08", "93_06"] + ["94_%02d" % i for i in range(1, 17)] +
                         ["15_04", "15_05", "18_15", "20_01", "85_04", "85_08", "85_10", "49_09", "49_12", "49_22", "05_02", "05_06"],
    "celebracion_acrobacia": ["90_01", "90_02", "90_03", "90_04", "90_08", "90_09", "90_11", "90_14", "85_01", "85_02", "90_05", "49_06"],
    "celebracion_emocion": ["79_69", "79_70", "80_43", "142_08", "142_09", "142_06", "141_22"],
    "derrota_y_protesta": ["79_71", "79_72", "79_74", "79_73", "142_05", "111_25", "141_21", "56_02"],
    "saludo": ["111_37", "113_27", "141_16", "111_02", "113_02"],
    "caidas": ["90_16", "90_17", "90_18"],
}
usados, momentos = [], {}
for mom, ids in ELEGIR.items():
    lista = []
    for i in ids:
        for suf in ("", "_espejo"):
            c = por.get("cmu_" + i + suf)
            if c is None:
                continue
            usados.append(c["nombre"])
            f = {k: c[k] for k in ("nombre", "tipo", "duracion_s", "nota", "vel_entrada_ms", "vel_salida_ms", "giro_cuerpo_grados", "desplazamiento_adelante_m",
                                   "desplazamiento_izquierda_m", "cambio_direccion_rad", "cuadro_toque_balon", "pie_que_golpea", "golpeos") if k in c}
            lista.append(f)
    momentos[mom] = lista
# ciclos de carrera -> anims_extra (formato LeagueCatalogo)
clase = lambda v: 8.0 if v >= 6.2 else 5.0 if v >= 4.4 else 3.5 if v >= 1.8 else 0.0
clips = []
for c in cat:
    if not c.get("bucle") or c["tipo"] != "carrera" or c["nombre"].endswith("_espejo"):
        continue
    v = float(c["velocidad_ms"])
    k = clase(v)
    n = c["nombre"]
    clips.append({"nombre": "ext_" + n[4:], "clip": n, "clip_espejo": n + "_espejo", "entra": k, "sale": k, "ang": 0.0, "cuerpo": 0.0, "cuerpo_ini": 0.0,
                  "largo": c["duracion_s"], "pie": c["pie_en_aire_inicio"], "pasos": 2, "reposo": 1, "v_entra": v, "v_sale": v})
    usados += [n, n + "_espejo"]
fuente = "CMU Graphics Lab Motion Capture Database (mocap.cs.cmu.edu; BVH de B. Hahne): libre para uso comercial, citar la fuente"
json.dump({"biblioteca": USO, "fuente": fuente, "clips": clips}, open(os.path.join(raiz, "datos/anims_extra/cmu.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
json.dump({"biblioteca": USO, "fuente": fuente,
           "nota": "Los clips NO se desplazan: la velocidad y el giro son los medidos en el original (el motor mueve al jugador). Con espejo («_espejo») los de pie/lado; los bailes no.",
           "momentos": momentos}, open(os.path.join(raiz, "datos/anims_accion_cmu.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
usados = sorted(set(usados))
json.dump({"salida": USO, "clips": usados, "origen": {n: ORIGEN for n in usados}}, open(os.path.join(raiz, "terceros/cmu/uso_clips.json"), "w"), indent=1)
print(len(clips), "ciclos de carrera;", sum(len(v) for v in momentos.values()), "fichas de acción;", len(usados), "clips en la biblioteca de uso")
