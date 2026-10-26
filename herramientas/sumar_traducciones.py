#!/usr/bin/env python3
"""Suma traducciones a dinastia-godot/datos/idiomas_extra.json SIN pisar a otros (24-10-2026).
   python3 herramientas/sumar_traducciones.py parche.json
parche.json: {"exactas": {"frase en castellano": {"en":..,"pt":..,"fr":..,"it":..,"de":..,"ca":..,"pl":..,"tr":..}},
              "patrones": [[regex_es, en, pt, fr, it, de, ca, pl, tr], ...]}
Toma el candado /tmp/idiomas.lock (varios procesos a la vez), conserva el formato exacto del archivo y no
sobrescribe claves que ya existen (setdefault). Rechaza entradas a las que les falte algún idioma."""
import fcntl, json, sys
RUTA = "dinastia-godot/datos/idiomas_extra.json"
LANGS = ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]
parche = json.load(open(sys.argv[1], encoding="utf-8"))
with open("/tmp/idiomas.lock", "w") as cand:
    fcntl.flock(cand, fcntl.LOCK_EX)
    d = json.loads(open(RUTA, encoding="utf-8").read())
    nuevas, malas = 0, []
    for es, tr in parche.get("exactas", {}).items():
        if any(l not in tr or not str(tr[l]).strip() for l in LANGS):
            malas.append(es)
            continue
        for l in LANGS:
            if es not in d[l]:
                d[l][es] = tr[l]
                nuevas += 1
    ya = {p[0] for p in d["patrones"]}
    np_ = 0
    for p in parche.get("patrones", []):
        if len(p) != 9:
            malas.append(str(p[:1]))
            continue
        if p[0] not in ya:
            d["patrones"].append(p)
            np_ += 1
    open(RUTA, "w", encoding="utf-8").write(json.dumps(d, ensure_ascii=False, indent=1))
print("claves nuevas", nuevas, "· patrones nuevos", np_, "· rechazadas (faltan idiomas)", len(malas), malas[:5])
