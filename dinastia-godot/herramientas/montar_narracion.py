#!/usr/bin/env python3
"""Monta `datos/narracion.json`, lo que carga `Idiomas` para traducir la
narración (títulos y cuerpos de las noticias) al inglés y al portugués.

Entrada:
  - `datos/narracion_plantillas.json` (lo extrae `extraer_narracion.py`);
  - `datos/narracion_traducida.json`: {muestra castellana: [en, pt]}, a mano;
  - `datos/narracion_traducida_mas.json`: {muestra: {fr, it, de, ca, pl, tr}}.
Salida:
  - "directas": {"en": {frase: traducción}, "pt": {...}} para las fijas;
  - "patrones": [[regex, {idioma: texto}]] para las que llevan huecos ({1} → $1).
Avisa de las plantillas sin traducir y de los huecos que no cuadran.
"""
import json
import os
import re

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


IDIOMAS = ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]


def main():
    plantillas = json.load(open(os.path.join(RAIZ, "datos/narracion_plantillas.json"), encoding="utf-8"))
    base = json.load(open(os.path.join(RAIZ, "datos/narracion_traducida.json"), encoding="utf-8"))
    ruta_mas = os.path.join(RAIZ, "datos/narracion_traducida_mas.json")
    mas = json.load(open(ruta_mas, encoding="utf-8")) if os.path.exists(ruta_mas) else {}
    ## {muestra: {idioma: texto}} con todo lo que haya.
    trad = {}
    for es, (en, pt) in base.items():
        trad[es] = {"en": en, "pt": pt}
        trad[es].update(mas.get(es, {}))
    directas = {k: {} for k in IDIOMAS}
    patrones = []
    faltan = []
    faltan_mas = 0
    vistas = set()
    for p in plantillas:
        es = p["es"]
        huecos = set(re.findall(r"\{\d+\}", es))
        fijo = re.sub(r"\{\d+\}", "", es)
        if len(re.findall(r"[A-Za-zÁÉÍÓÚáéíóúñÑ]", fijo)) < 3:
            continue   ## «{1} {2}»: encajaría con cualquier frase
        vistas.add(es)
        if es not in trad:
            faltan.append(es)
            continue
        t = trad[es]
        if len(t) < len(IDIOMAS):
            faltan_mas += 1
        for k, v in t.items():
            ## Un hueco que solo es la «s» del plural («título{2}») se puede
            ## omitir en los idiomas que no forman el plural así.
            faltan_h = huecos - set(re.findall(r"\{\d+\}", v))
            if faltan_h and all(re.search(re.escape(x) + r"[:\s]", es) and es[es.index(x) - 1].isalpha() for x in faltan_h):
                continue
            if set(re.findall(r"\{\d+\}", v)) != huecos:
                print("HUECOS DISTINTOS (%s):" % k, es, "→", v)
        if not huecos:
            for k, v in t.items():
                directas[k][es] = v
                ## Las que empiezan con espacio (se pegan detrás de otra frase)
                ## también sin él: el traductor las busca oración por oración.
                if es != es.strip():
                    directas[k][es.strip()] = v.strip()
            continue
        a_godot = lambda s: re.sub(r"\{(\d+)\}", r"$\1", s)
        patrones.append([p["re"], {k: a_godot(v) for k, v in t.items()}])
    ## Frases sueltas traducidas a mano que no salen del extractor (textos de
    ## tablas que se meten dentro de una noticia): van como directas.
    for es, t in trad.items():
        if es not in vistas and not re.search(r"\{\d+\}", es):
            for k, v in t.items():
                directas[k].setdefault(es, v)
    ## Las más largas primero: una plantilla corta no debe tragarse a una larga.
    patrones.sort(key=lambda f: -len(f[0]))
    salida = {"directas": directas, "patrones": patrones}
    json.dump(salida, open(os.path.join(RAIZ, "datos/narracion.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("%d directas, %d patrones, %d sin traducir, %d sin los 6 idiomas nuevos" % (
        len(directas["en"]), len(patrones), len(faltan), faltan_mas))
    print("  por idioma:", {k: len(v) for k, v in directas.items()})
    for f in faltan:
        print("  SIN TRADUCIR:", f)


if __name__ == "__main__":
    main()
