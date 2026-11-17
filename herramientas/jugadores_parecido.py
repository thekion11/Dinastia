#!/usr/bin/env python3
"""Plantillas reales completas desde fuentes abiertas (Wikipedia + Wikidata), 17-11-2026.

Meta del dueño: que cada jugador real esté en el juego. Esta herramienta, para los clubes de
`herramientas/parecido/clubes_wikipedia.json`, saca la plantilla de primer equipo del artículo del club
(plantilla `{{Fs player}}`: dorsal, país, puesto, nombre), la edad y la altura de Wikidata (por enlace al
artículo), y mete lo que falte en `REALES` del pack (`pack_real.json`, solo uso privado). Después se
regenera la base pública con guiños:  python3 herramientas/base_ficticia.py

    python3 herramientas/jugadores_parecido.py ENG            # simula: informe, no escribe
    python3 herramientas/jugadores_parecido.py ENG --aplicar  # escribe el pack

Formato de fila (campos 1-6 igual que antes; los nuevos van detrás y el juego los ignora si no los lee):
    nombre|puesto|edad|media|país|región|dorsal|altura_cm|marcas
`marcas` dice qué es ESTIMADO y no viene de la fuente: m = media (regla por reputación del club), p = puesto
(regla por dorsal), a = edad, h = altura (la del puesto), e = país; sin esas letras, el dato viene de la fuente.
El pie no tiene fuente abierta: lo estima el juego.

Respeta la fuente: pausa entre peticiones, caché FUERA del repo (DINASTIA_CACHE o el directorio temporal),
nombre de cliente genérico. Valida cada plantilla (18-35 jugadores, ≥2 porteros, sin duplicados entre clubes) y
saca los casos dudosos a un informe en vez de meterlos a ciegas.
"""
import hashlib
import json
import os
import re
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ruta_segura import ruta_segura, RAIZ_REPO  # noqa: E402
from auditar_parecido_real import cargar, limpiar  # noqa: E402

CLIENTE = "dinastia-datos/1.0 (datos abiertos)"
PAUSA = 2.5
ANIO_AHORA = 2026
PACK = os.path.join(RAIZ_REPO, "dinastia-godot", "datos", "pack_real.json")
MAPA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "parecido", "clubes_wikipedia.json")
CACHE = os.environ.get("DINASTIA_CACHE") or os.path.join(tempfile.gettempdir(), "dinastia_cache_wiki")
## Wikipedia usa códigos de selección propios en algunos casos; el juego usa los de `PAIS_SELECCION`.
PAIS = {"SCO": "SCO", "WAL": "WAL", "NIR": "NIR", "IRL": "IRL", "ENG": "ENG", "SUI": "SUI", "NED": "NED"}
POSD = {"GK": "POR", "DF": "DFC", "MF": "MC", "FW": "DC"}
## media = reputación del club − 9 (media del pack: rep − 8); titulares (dorsal 1-11) +2, el resto −3.
DESCUENTO_MEDIA = 9
ALTURA_PUESTO = {"POR": 188, "DFC": 186, "LD": 177, "LI": 177, "MCD": 182, "MC": 178, "MCO": 175, "ED": 174, "EI": 174, "DC": 182}


def _cache_ruta(clave):
    os.makedirs(CACHE, exist_ok=True)
    return os.path.join(CACHE, hashlib.sha1(clave.encode("utf-8")).hexdigest() + ".txt")


def pedir(url, reintentos=4):
    """GET con caché y pausa; reintenta ante 429 con espera creciente. Devuelve texto o None."""
    ruta = _cache_ruta(url)
    if os.path.exists(ruta):
        with open(ruta, encoding="utf-8") as f:
            return f.read()
    espera = 10.0
    for _ in range(reintentos):
        time.sleep(PAUSA)
        try:
            peticion = urllib.request.Request(url, headers={"User-Agent": CLIENTE})
            with urllib.request.urlopen(peticion, timeout=40) as r:  # NOSONAR(S5332): solo HTTPS, URL fija de Wikimedia
                txt = r.read().decode("utf-8")
            with open(ruta, "w", encoding="utf-8") as f:
                f.write(txt)
            return txt
        except urllib.error.HTTPError as e:
            if e.code in (429, 503):
                time.sleep(espera)
                espera *= 2
                continue
            return None
        except (urllib.error.URLError, TimeoutError):
            time.sleep(espera)
    return None


def wikitexto(titulo):
    q = urllib.parse.urlencode({"title": titulo, "action": "raw"})
    return pedir("https://en.wikipedia.org/w/index.php?" + q)


RE_FS = re.compile(r"\{\{\s*[Ff]s player\s*\|(.*?)\}\}", re.S)
RE_ENL = re.compile(r"\[\[([^\]|]+)(?:\|([^\]]+))?\]\]")


def parsear_plantilla(txt):
    """Primer bloque `fs start ... fs end` tras «First-team squad»; devuelve [{no,nat,pos,nombre,titulo}]."""
    i = txt.find("First-team squad")
    if i < 0:
        i = txt.find("{{fs start")
    if i < 0:
        i = txt.find("{{Fs start")
    if i < 0:
        return []
    fin = re.search(r"\{\{\s*[Ff]s end\s*\}\}", txt[i:])
    bloque = txt[i:i + fin.end()] if fin else txt[i:i + 6000]
    res = []
    for m in RE_FS.finditer(bloque):
        campos = {}
        for trozo in re.split(r"\|(?=\s*\w+\s*=)", m.group(1)):
            if "=" in trozo:
                k, v = trozo.split("=", 1)
                campos[k.strip()] = v.strip()
        nom = campos.get("name", "")
        e = RE_ENL.search(nom)
        titulo = e.group(1).strip() if e else ""
        visible = (e.group(2) or e.group(1)).strip() if e else re.sub(r"[\[\]]", "", nom)
        visible = re.sub(r"\s*\(.*?\)$", "", visible).strip()
        if not visible:
            continue
        res.append({"no": campos.get("no", ""), "nat": campos.get("nat", "").upper(), "pos": campos.get("pos", "").upper(),
                    "nombre": visible, "titulo": titulo})
    return res


def datos_wikidata(titulos):
    """{titulo: {anio, altura_cm}} en lotes de 40 por enlace al artículo de la Wikipedia inglesa."""
    salida = {}
    lista = [t for t in titulos if t]
    for k in range(0, len(lista), 40):
        lote = lista[k:k + 40]
        q = urllib.parse.urlencode({"action": "wbgetentities", "sites": "enwiki", "titles": "|".join(lote), "props": "claims|sitelinks",
                                    "format": "json", "normalize": "1"})
        txt = pedir("https://www.wikidata.org/w/api.php?" + q)
        if not txt:
            continue
        try:
            ents = json.loads(txt).get("entities", {})
        except ValueError:
            continue
        for e in ents.values():
            tit = ((e.get("sitelinks") or {}).get("enwiki") or {}).get("title")
            cl = e.get("claims") or {}
            d = {}
            try:
                t = cl["P569"][0]["mainsnak"]["datavalue"]["value"]["time"]
                d["anio"] = int(t[1:5])
            except (KeyError, IndexError, ValueError):
                pass
            try:
                v = cl["P2048"][0]["mainsnak"]["datavalue"]["value"]
                cm = float(v["amount"])
                if "Q11573" in v.get("unit", ""):
                    cm *= 100
                if 150 <= cm <= 215:
                    d["altura"] = int(round(cm))
            except (KeyError, IndexError, ValueError):
                pass
            if tit:
                salida[tit] = d
    return salida


def puesto_de(pos, no):
    """Puesto del juego por el puesto general y el dorsal (estimado)."""
    n = int(no) if str(no).isdigit() else 0
    if pos == "DF":
        return "LD" if n == 2 else "LI" if n == 3 else "DFC"
    if pos == "MF":
        return "MCD" if n == 6 else "MCO" if n == 10 else "MC"
    if pos == "FW":
        return "ED" if n == 7 else "EI" if n == 11 else "DC"
    return POSD.get(pos, "MC")


def fila(j, wd, rep, club_pais):
    marcas = ""
    pos = puesto_de(j["pos"], j["no"])
    if j["pos"] in ("DF", "MF", "FW"):
        marcas += "p"
    n = int(j["no"]) if str(j["no"]).isdigit() else 99
    media = rep - DESCUENTO_MEDIA + (2 if n <= 11 else -3)
    media = max(48, min(90, media))
    marcas += "m"
    d = wd.get(j["titulo"], {})
    if "anio" in d:
        edad = ANIO_AHORA - d["anio"]
    else:
        edad, marcas = 25, marcas + "a"
    if "altura" in d:
        altura = str(d["altura"])
    else:
        altura, marcas = str(ALTURA_PUESTO.get(pos, 180)), marcas + "h"
    pais = PAIS.get(j["nat"], j["nat"]) or club_pais
    if not j["nat"]:
        marcas += "e"
    return f"{j['nombre']}|{pos}|{edad}|{media}||{''}|{j['no']}|{altura}|{marcas}".replace("||", "|" + pais + "|", 1)


def validar(jugadores):
    """Problemas de una plantilla: lista de textos (vacía = buena)."""
    p = []
    if not 18 <= len(jugadores) <= 35:
        p.append(f"tamaño {len(jugadores)}")
    if sum(1 for j in jugadores if j["pos"] == "GK") < 2:
        p.append("menos de 2 porteros")
    return p


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    aplicar = "--aplicar" in sys.argv
    if not args:
        sys.exit("uso: jugadores_parecido.py LIGA [LIGA…] [--aplicar]")
    with open(ruta_segura(MAPA), encoding="utf-8") as f:
        mapa = json.load(f)
    pack = cargar("pack_real.json")
    t = pack["tablas"]
    ligas = dict(t["PAISES_LIGAS"])
    ligas["CHI"] = {"clubes": t["DATA_P1"]}
    claves_reales = {limpiar(k): k for k in t["REALES"]}
    vistos = {}
    informe = []
    nuevos_total = 0
    for liga in args:
        for club in ligas[liga]["clubes"]:
            nom = limpiar(club[0])
            titulo = (mapa.get(liga) or {}).get(nom)
            if not titulo:
                continue
            txt = wikitexto(titulo)
            jug = parsear_plantilla(txt) if txt else []
            problemas = validar(jug) if jug else ["sin plantilla en el artículo"]
            wd = datos_wikidata([j["titulo"] for j in jug]) if jug else {}
            actuales = t["REALES"].get(claves_reales.get(nom, club[0]), [])
            ya = {limpiar(a.split("|")[0]).lower() for a in actuales}
            nuevos = []
            for j in jug:
                clave = limpiar(j["nombre"]).lower()
                if clave in vistos and vistos[clave] != nom:
                    problemas.append("duplicado con " + vistos[clave])
                    continue
                vistos[clave] = nom
                if clave not in ya:
                    nuevos.append(fila(j, wd, int(club[3]), liga))
            informe.append((liga, nom, len(jug), len(actuales), len(nuevos), problemas))
            print(f"{liga} {nom:22} wiki={len(jug):2} antes={len(actuales):2} nuevos={len(nuevos):2} {'; '.join(problemas)}")
            if aplicar and not problemas and nuevos:
                t["REALES"][claves_reales.get(nom, club[0])] = list(actuales) + nuevos
                nuevos_total += len(nuevos)
    if aplicar:
        with open(ruta_segura(PACK), "w", encoding="utf-8") as f:
            json.dump(pack, f, ensure_ascii=False, separators=(",", ":"))
        print("pack actualizado: +", nuevos_total, "jugadores")
    dudosos = [x for x in informe if x[5]]
    print(f"clubes: {len(informe)}; dudosos (no se aplican): {len(dudosos)}")


if __name__ == "__main__":
    main()
