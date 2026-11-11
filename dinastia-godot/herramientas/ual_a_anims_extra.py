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
json.dump({"salida": "res://assets/characters/quaternius/anims_ual/ual_uso.res", "clips": [c["clip"] for c in clips],
           "origen": {c["clip"]: "res://terceros/ual/ual_extra.res" for c in clips}}, open(os.path.join(raiz, "terceros/ual/uso_clips.json"), "w"), indent=1)
print(len(clips), "clips")
