#!/usr/bin/env python3
"""Monta `datos/narracion.json`, lo que carga `Idiomas` para traducir la
narración (títulos y cuerpos de las noticias) al inglés y al portugués.

Entrada:
  - `datos/narracion_plantillas.json` (lo extrae `extraer_narracion.py`);
  - `datos/narracion_traducida.json`: {muestra castellana: [en, pt]}, a mano.
Salida:
  - "directas": {"en": {frase: traducción}, "pt": {...}} para las fijas;
  - "patrones": [[regex, en, pt]] para las que llevan huecos ({1} → $1).
Avisa de las plantillas sin traducir y de los huecos que no cuadran.
"""
import json
import os
import re

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    plantillas = json.load(open(os.path.join(RAIZ, "datos/narracion_plantillas.json"), encoding="utf-8"))
    trad = json.load(open(os.path.join(RAIZ, "datos/narracion_traducida.json"), encoding="utf-8"))
    directas = {"en": {}, "pt": {}}
    patrones = []
    faltan = []
    for p in plantillas:
        es = p["es"]
        huecos = set(re.findall(r"\{\d+\}", es))
        fijo = re.sub(r"\{\d+\}", "", es)
        if len(re.findall(r"[A-Za-zÁÉÍÓÚáéíóúñÑ]", fijo)) < 3:
            continue   ## «{1} {2}»: encajaría con cualquier frase
        if es not in trad:
            faltan.append(es)
            continue
        en, pt = trad[es]
        for t in (en, pt):
            if set(re.findall(r"\{\d+\}", t)) != huecos:
                print("HUECOS DISTINTOS:", es, "→", t)
        if not huecos:
            directas["en"][es] = en
            directas["pt"][es] = pt
            ## Las que empiezan con espacio (se pegan detrás de otra frase)
            ## también sin él: el traductor las busca oración por oración.
            if es != es.strip():
                directas["en"][es.strip()] = en.strip()
                directas["pt"][es.strip()] = pt.strip()
            continue
        a_godot = lambda s: re.sub(r"\{(\d+)\}", r"$\1", s)
        patrones.append([p["re"], a_godot(en), a_godot(pt)])
    ## Frases sueltas traducidas a mano que no salen del extractor (textos de
    ## tablas que se meten dentro de una noticia): van como directas.
    vistas = {p["es"] for p in plantillas}
    for es, (en, pt) in trad.items():
        if es not in vistas and not re.search(r"\{\d+\}", es):
            directas["en"].setdefault(es, en)
            directas["pt"].setdefault(es, pt)
    ## Las más largas primero: una plantilla corta no debe tragarse a una larga.
    patrones.sort(key=lambda f: -len(f[0]))
    salida = {"directas": directas, "patrones": patrones}
    json.dump(salida, open(os.path.join(RAIZ, "datos/narracion.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("%d directas, %d patrones, %d sin traducir" % (len(directas["en"]), len(patrones), len(faltan)))
    for f in faltan:
        print("  SIN TRADUCIR:", f)


if __name__ == "__main__":
    main()
