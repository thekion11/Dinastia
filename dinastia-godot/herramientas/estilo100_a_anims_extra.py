#!/usr/bin/env python3
"""Convierte `datos/animaciones_catalogo_100style.json` al formato de `datos/anims_extra/*.json` (`LeagueCatalogo`, sesión 9).
Un ciclo continuo entra y sale a la misma velocidad y en la misma dirección (ang 0); el cuerpo respecto a la marcha es -angulo_mov
(atrás = ±π, lateral = ∓π/2). Solo pasan las fichas con `revision == ok` y con duración creíble (0,05 a 3 s). La clase de velocidad es la
REAL del clip (0 / 3,5 / 5 / 8 m/s): los ciclos lentos (< 1,8 m/s) son clase 0, es decir, «parado»; por eso solo se incluyen el reposo y
los que llegan a 1,8 m/s o más. Los demás se quedan en `animaciones_catalogo_100style.json` (marcha lenta).
  python3 -I herramientas/estilo100_a_anims_extra.py"""
import json, math, os
raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
import glob
cat = []
for ruta in sorted(glob.glob(os.path.join(raiz, "datos/animaciones_catalogo_100style*.json"))):
    base = os.path.basename(ruta)[len("animaciones_catalogo_"):-5]   # 100style, 100style_g2…
    for c in json.load(open(ruta, encoding="utf-8")):
        c["_biblioteca"] = "res://assets/characters/quaternius/anims_100style/%s.res" % base
        cat.append(c)
def clase(v):
    return 8.0 if v >= 6.2 else 5.0 if v >= 4.4 else 3.5 if v >= 1.8 else 0.0
por = {c["nombre"]: c for c in cat}
clips, omitidos = [], 0
for c in cat:
    n = c["nombre"]
    if n.endswith("_espejo"):
        continue
    if c.get("revision") != "ok" or not (0.05 <= c["duracion_s"] <= 3.0):
        omitidos += 1
        continue
    v = abs(float(c["velocidad_ms"])) if c["tipo"] != "reposo" else 0.0
    k = clase(v)
    if c["tipo"] != "reposo" and k == 0.0:
        omitidos += 1
        continue
    cuerpo = round(math.radians(-float(c["angulo_mov_grados"])), 3)
    cuerpo = max(-math.tau, min(math.tau, cuerpo))
    pie = c["pie_en_aire_al_inicio"]   # el pie que se mueve primero
    nombre = "ext_" + n[len("e100_"):]
    clips.append({"nombre": nombre, "biblioteca": c["_biblioteca"], "clip": n, "clip_espejo": n + "_espejo", "entra": k, "sale": k, "ang": 0.0, "cuerpo": cuerpo,
                  "cuerpo_ini": cuerpo, "largo": round(c["duracion_s"], 3), "pie": pie, "pasos": 2, "reposo": 1,
                  "v_entra": round(v, 2), "v_sale": round(v, 2), "tipo_100style": c["tipo"], "estilo": c["estilo"]})
por_bib = {}
for c in clips:
    por_bib.setdefault(c.pop("biblioteca"), []).append(c)
carpeta = os.path.join(raiz, "datos/anims_extra")
os.makedirs(carpeta, exist_ok=True)
for viejo in glob.glob(os.path.join(carpeta, "estilo100*.json")):
    os.remove(viejo)
for bib, lista in sorted(por_bib.items()):
    base = os.path.basename(bib)[:-4].replace("100style", "estilo100")
    doc = {"biblioteca": bib, "fuente": "100STYLE (Ian Mason, Sebastian Starke, Taku Komura), CC BY 4.0, zenodo.org/records/8127870", "clips": lista}
    json.dump(doc, open(os.path.join(carpeta, base + ".json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(base + ".json", len(lista))
print(len(clips), "clips (con espejo", 2 * len(clips), ") omitidos", omitidos)
