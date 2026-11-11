#!/usr/bin/env python3
"""`datos/animaciones_catalogo_ual.json` -> `datos/anims_extra/quaternius_ual.json` (formato de `LeagueCatalogo`).
Solo la locomoción que supera 1,8 m/s reales (trote y sprint); el resto de clips (saltos, caídas, celebración…) no son transiciones de
movimiento y se quedan en el catálogo. Sin versión espejo (la UAL no la trae).   python3 -I herramientas/ual_a_anims_extra.py"""
import json, os
raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
cat = json.load(open(os.path.join(raiz, "terceros/ual/animaciones_catalogo_ual.json"), encoding="utf-8"))
clase = lambda v: 8.0 if v >= 6.2 else 5.0 if v >= 4.4 else 3.5 if v >= 1.8 else 0.0
clips = []
for c in cat:
    v = float(c.get("velocidad_ms", 0))
    if c["tipo"] in ("carrera", "sprint") and clase(v) > 0:
        k = clase(v)
        clips.append({"nombre": "ext_" + c["nombre"], "clip": c["nombre"], "entra": k, "sale": k, "ang": 0.0, "cuerpo": 0.0, "cuerpo_ini": 0.0,
                      "largo": c["duracion_s"], "pie": "D", "pasos": 2, "reposo": 1, "v_entra": v, "v_sale": v})
doc = {"biblioteca": "res://assets/characters/quaternius/anims_ual/ual_uso.res",
       "fuente": "Quaternius Universal Animation Library 1 y 2, CC0 1.0", "clips": clips}
json.dump(doc, open(os.path.join(raiz, "datos/anims_extra/quaternius_ual.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
# --- Acciones puntuales: qué clip encaja con qué momento del partido (se leen por nombre desde la biblioteca de uso).
MOMENTOS = {
    "entrada_deslizante": {"nota": "Tackle por abajo: Start (0,83 s) → Loop mientras desliza → Exit (0,5 s) → LayToIdle si queda en el suelo. El motor mueve el cuerpo (los clips no desplazan la cadera)",
                           "secuencia": ["ual2_Slide_Start", "ual2_Slide_Loop", "ual2_Slide_Exit"], "despues": ["ual2_LayToIdle"]},
    "saque_de_banda": {"nota": "Lanzamiento con las dos manos por encima de la cabeza; soltar el balón hacia la mitad del clip", "secuencia": ["ual2_OverhandThrow"]},
    "celebracion_gol": {"nota": "Bucle de 1 s: repetir mientras dura la celebración", "secuencia": ["ual1_Dance_Loop"]},
    "falta_recibida_leve": {"nota": "Golpe en el pecho o la cabeza, 0,3-0,4 s, sin caída", "secuencia": ["ual1_Hit_Chest"], "alternativas": ["ual1_Hit_Head"]},
    "falta_recibida_fuerte": {"nota": "Empujón que tira al suelo; después se levanta", "secuencia": ["ual2_Hit_Knockback"], "despues": ["ual2_LayToIdle"]},
    "caida_con_voltereta": {"nota": "Tropiezo/caída con rodada; acaba cerca del suelo", "secuencia": ["ual1_Roll"], "despues": ["ual2_LayToIdle"]},
    "lesion_o_k_o": {"nota": "Cae y se queda en el suelo (2,4 s); usar para lesión grave", "secuencia": ["ual1_Death01"]},
    "disputa_aerea": {"nota": "Salto: Start (1,3 s) → Loop (aire) → Land (1,3 s). Elegir Ninja si hay carrera previa", "secuencia": ["ual1_Jump_Start", "ual1_Jump_Loop", "ual1_Jump_Land"],
                      "alternativas": ["ual2_NinjaJump_Start", "ual2_NinjaJump_Idle_Loop", "ual2_NinjaJump_Land"]},
    "disputa_cuerpo_a_cuerpo": {"nota": "Empuje continuo hombro con hombro (bucle)", "secuencia": ["ual1_Push_Loop"]},
    "protesta_reaccion": {"nota": "Negar con la cabeza / asentir / señalar", "secuencia": ["ual2_Idle_No_Loop"], "alternativas": ["ual2_Yes", "ual1_Interact"]},
    "espera_parado": {"nota": "Reposos de variedad para jugadores parados (bucle)", "secuencia": ["ual1_Idle_Loop"], "alternativas": ["ual1_Idle_Talking_Loop", "ual2_Idle_FoldArms_Loop", "ual1_Crouch_Idle_Loop"]},
}
por_nombre = {c["nombre"]: c for c in cat}
usados = [c["clip"] for c in clips]
for m in MOMENTOS.values():
    for k in ("secuencia", "alternativas", "despues"):
        for n in m.get(k, []):
            assert n in por_nombre, n
            m.setdefault("clips", {})[n] = {"duracion_s": por_nombre[n]["duracion_s"], "bucle": por_nombre[n]["bucle"], "desplazamiento_m": por_nombre[n]["desplazamiento_m"]}
            if n not in usados:
                usados.append(n)
doc2 = {"biblioteca": "res://assets/characters/quaternius/anims_ual/ual_uso.res", "fuente": "Quaternius Universal Animation Library 1 y 2, CC0 1.0",
        "nota": "Acciones puntuales por momento del partido. Los clips NO desplazan la cadera (desplazamiento_m ~ 0): el motor mueve al jugador. Sin espejo.", "momentos": MOMENTOS}
json.dump(doc2, open(os.path.join(raiz, "datos/anims_accion.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
json.dump({"salida": "res://assets/characters/quaternius/anims_ual/ual_uso.res", "clips": usados,
           "origen": {n: "res://terceros/ual/ual_extra.res" for n in usados}}, open(os.path.join(raiz, "terceros/ual/uso_clips.json"), "w"), indent=1)
print(len(clips), "clips de locomoción;", len(usados), "clips en la biblioteca de uso;", len(MOMENTOS), "momentos")
