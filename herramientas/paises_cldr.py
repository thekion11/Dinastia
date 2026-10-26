#!/usr/bin/env python3
"""Nombres de los países del juego en los 9 idiomas, desde Unicode CLDR (26-10-2026, fila 26 de la propuesta s4).

  # 1) bajar los nombres de territorio de CLDR (Unicode License V3, ver datos/LICENCIA_CLDR_Unicode.txt):
  for l in es en pt fr it de ca pl tr; do curl -sS -o /tmp/cldr/$l.json \
    https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json/cldr-localenames-full/main/$l/territories.json; done
  # 2) generar datos/paises.json y el parche de traducciones:
  python3 herramientas/paises_cldr.py /tmp/cldr /tmp/trad_paises.json
  python3 herramientas/sumar_traducciones.py /tmp/trad_paises.json

Los códigos son los FIFA del juego (`visor/banderas.gd`, `ISO`). Inglaterra, Escocia y Gales no son territorios
de CLDR: van a mano. El nombre en castellano que ya usa el juego (`PAIS_SELECCION` de tablas.json) manda sobre el
de CLDR, para no cambiar textos que ya se ven."""
import json, re, sys

IDIOMAS = ["es", "en", "pt", "fr", "it", "de", "ca", "pl", "tr"]
A_MANO = {
    "gb-eng": ["Inglaterra", "England", "Inglaterra", "Angleterre", "Inghilterra", "England", "Anglaterra", "Anglia", "İngiltere"],
    "gb-sct": ["Escocia", "Scotland", "Escócia", "Écosse", "Scozia", "Schottland", "Escòcia", "Szkocja", "İskoçya"],
    "gb-wls": ["Gales", "Wales", "País de Gales", "Pays de Galles", "Galles", "Wales", "Gal·les", "Walia", "Galler"],
}
## Donde el castellano de CLDR suena raro en un juego de fútbol (CLDR usa el nombre oficial).
ES_A_MANO = {"CIV": "Costa de Marfil"}
RAIZ = "dinastia-godot/"

def main():
    cldr, parche = sys.argv[1], sys.argv[2]
    gd = open(RAIZ + "visor/banderas.gd", encoding="utf-8").read()
    bloque = gd[gd.index("const ISO := {"):gd.index("}", gd.index("const ISO := {"))]
    iso = dict(re.findall(r'"([A-Z]{3})": "([a-z-]+)"', bloque))
    nombres = {}
    for l in IDIOMAS:
        d = json.load(open(f"{cldr}/{l}.json", encoding="utf-8"))
        nombres[l] = d["main"][l]["localeDisplayNames"]["territories"]
    juego = json.load(open(RAIZ + "datos/tablas.json", encoding="utf-8")).get("PAIS_SELECCION", {})
    paises, exactas = {}, {}
    for fifa, cod in sorted(iso.items()):
        if cod in A_MANO:
            fila = dict(zip(IDIOMAS, A_MANO[cod]))
        else:
            fila = {l: nombres[l][cod.upper()] for l in IDIOMAS}
        if fifa in ES_A_MANO:
            fila["es"] = ES_A_MANO[fifa]
        if fifa in juego:
            fila["es"] = juego[fifa]
        paises[fifa] = dict(fila, iso=cod)
        exactas[fila["es"]] = {l: fila[l] for l in IDIOMAS if l != "es"}
    salida = {"_leeme": "Nombres de país en los 9 idiomas (Unicode CLDR, Unicode License V3: datos/LICENCIA_CLDR_Unicode.txt; "
              "Inglaterra, Escocia y Gales a mano). Lo genera herramientas/paises_cldr.py: no editar a mano.",
              "paises": paises}
    open(RAIZ + "datos/paises.json", "w", encoding="utf-8").write(json.dumps(salida, ensure_ascii=False, indent=1) + "\n")
    json.dump({"exactas": exactas}, open(parche, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(len(paises), "países ·", len(exactas), "nombres al parche")

if __name__ == "__main__":
    main()
