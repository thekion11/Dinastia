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
nombre de cliente genérico. Valida cada plantilla (18-45 jugadores, ≥2 porteros, sin duplicados entre clubes) y
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


HOSTS_PERMITIDOS = ("en.wikipedia.org", "es.wikipedia.org", "www.wikidata.org")


def validar_url(url):
    """Solo https y hosts fijos de Wikimedia; si no, ValueError (Sonar: descargas validadas por causa)."""
    u = urllib.parse.urlparse(url)
    if u.scheme != "https" or u.hostname not in HOSTS_PERMITIDOS:
        raise ValueError(f"URL no permitida: {url!r}")
    return url


def pedir(url, reintentos=4):
    """GET con caché y pausa; reintenta ante 429 con espera creciente. Devuelve texto o None."""
    validar_url(url)
    ruta = _cache_ruta(url)
    if os.path.exists(ruta):
        with open(ruta, encoding="utf-8") as f:
            return f.read()
    espera = 10.0
    for _ in range(reintentos):
        time.sleep(PAUSA)
        try:
            peticion = urllib.request.Request(url, headers={"User-Agent": CLIENTE})
            with urllib.request.urlopen(peticion, timeout=40) as r:
                txt = r.read().decode("utf-8")
            if '"error"' not in txt[:80]:
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


RE_REDIR = re.compile(r"^\s*#(?:REDIRECT|REDIRECCI[ÓO]N)\s*:?\s*\[\[([^\]|#]+)", re.I)


def wikitexto(titulo, idioma="en", saltos=2):
    """Wikitexto crudo del artículo; sigue hasta `saltos` redirecciones (action=raw no las sigue)."""
    q = urllib.parse.urlencode({"title": titulo, "action": "raw"})
    txt = pedir(f"https://{idioma}.wikipedia.org/w/index.php?" + q)
    m = RE_REDIR.match(txt) if txt else None
    if m and saltos > 0:
        return wikitexto(m.group(1).strip(), idioma, saltos - 1)
    return txt


RE_FS = re.compile(r"\{\{\s*[Ff]s player\s*\|(.*?)\}\}", re.S)
RE_ENL = re.compile(r"\[\[([^\]|]+)(?:\|([^\]]+))?\]\]")


RE_ES = re.compile(r"\{\{\s*Jugador de fútbol\s*\|(.*?)\}\}(?=\s*\n)", re.S)
RE_EDAD = re.compile(r"\{\{\s*edad\s*\|\s*\d+\s*\|\s*\d+\s*\|\s*(\d{4})", re.I)
POS_ES = {"ARQ": "GK", "POR": "GK", "DEF": "DF", "MED": "MF", "DEL": "FW"}


def _campos(txt):
    campos = {}
    for trozo in re.split(r"\|(?=\s*\w+\s*=)", txt):
        if "=" in trozo:
            k, v = trozo.split("=", 1)
            campos[k.strip()] = v.strip()
    return campos


def _jugador(campos):
    nom = campos.get("name") or campos.get("nombre", "")
    e = RE_ENL.search(nom)
    titulo = e.group(1).strip() if e else ""
    visible = (e.group(2) or e.group(1)).strip() if e else re.sub(r"[\[\]]", "", nom)
    visible = re.sub(r"\s*\(.*?\)$", "", visible).strip()
    if not visible:
        return None
    pos = campos.get("pos", "").upper()
    j = {"no": campos.get("no", ""), "nat": campos.get("nat", "").upper(), "pos": POS_ES.get(pos, pos), "nombre": visible, "titulo": titulo}
    m = RE_EDAD.search(campos.get("edad", ""))
    if m:
        j["anio"] = int(m.group(1))
    return j


def parsear_plantilla(txt):
    """Plantilla de primer equipo: `{{Fs player}}` (inglesa) o `{{Jugador de fútbol}}` (española, con año de nacimiento)."""
    i = txt.find("First-team squad")
    if i < 0:
        m0 = re.search(r"\{\{\s*[Ff]s start", txt)
        i = m0.start() if m0 else -1
    res = []
    if i >= 0:
        fin = re.search(r"\{\{\s*[Ff]s end\s*\}\}", txt[i:])
        bloque = txt[i:i + fin.end()] if fin else txt[i:i + 6000]
        for m in RE_FS.finditer(bloque):
            j = _jugador(_campos(m.group(1)))
            if j:
                res.append(j)
        return res
    i = txt.find("{{Jugador de fútbol")
    if i < 0:
        return res
    fin = re.search(r"\{\{\s*Equipo de fútbol fin", txt[i:])
    bloque = txt[i:i + fin.start()] if fin else txt[i:i + 12000]
    for m in RE_ES.finditer(bloque):
        j = _jugador(_campos(m.group(1)))
        if j:
            res.append(j)
    return res


def datos_wikidata(titulos, sitio="enwiki"):
    """{titulo: {anio, altura_cm}} en lotes de 40 por enlace al artículo de la Wikipedia inglesa."""
    salida = {}
    lista = [t for t in titulos if t]
    for k in range(0, len(lista), 40):
        lote = lista[k:k + 40]
        q = urllib.parse.urlencode({"action": "wbgetentities", "sites": sitio, "titles": "|".join(lote), "props": "claims|sitelinks",
                                    "format": "json"})
        txt = pedir("https://www.wikidata.org/w/api.php?" + q)
        if not txt:
            continue
        try:
            ents = json.loads(txt).get("entities", {})
        except ValueError:
            continue
        for e in ents.values():
            tit = ((e.get("sitelinks") or {}).get(sitio) or {}).get("title")
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
            d["fama"] = len(e.get("sitelinks") or {})   ## señal objetiva de notoriedad: en cuántas Wikipedias tiene artículo
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


def _semilla(texto):
    """Número estable (0-1) a partir de un texto: la misma fila sale igual en cada ejecución."""
    return int(hashlib.sha1(texto.encode("utf-8")).hexdigest()[:8], 16) / 0xFFFFFFFF


def media_estimada(j, edad, rep, club, bono=0):
    """Media del jugador DENTRO del club: reputación − 9, y por puesto, edad (pico 25-29), dorsal y una variación estable.
    Los titulares (dorsal 1-11, portero 1) salen +2/+3 por encima de los suplentes y los juveniles bajan. Es una ESTIMACIÓN."""
    n = int(j["no"]) if str(j["no"]).isdigit() else 99
    base = rep - DESCUENTO_MEDIA
    if n <= 11:
        base += 3 if j["pos"] == "GK" else 2
    elif n <= 20:
        base -= 1
    else:
        base -= 4
    if edad <= 19:
        base -= 6
    elif edad <= 21:
        base -= 3
    elif edad <= 24:
        base -= 1
    elif edad <= 29:
        base += 2
    elif edad <= 32:
        base += 0
    elif edad <= 35:
        base -= 3
    else:
        base -= 6
    base += round((_semilla(limpiar(j["nombre"]) + "|" + club) - 0.5) * 6)
    return max(45, min(rep + 3 + bono, min(90, base + bono)))


def fila(j, wd, rep, club_pais, club, bono=0):
    marcas = "m"
    pos = puesto_de(j["pos"], j["no"])
    if j["pos"] in ("DF", "MF", "FW"):
        marcas += "p"
    d = wd.get(j["titulo"], {})
    anio = j.get("anio") or d.get("anio")
    if anio:
        edad = ANIO_AHORA - anio
    else:
        edad, marcas = 25, marcas + "a"
    if "altura" in d:
        altura = str(d["altura"])
    else:
        altura, marcas = str(ALTURA_PUESTO.get(pos, 180)), marcas + "h"
    pais = PAIS.get(j["nat"], j["nat"]) or club_pais
    if not j["nat"]:
        marcas += "e"
    media = media_estimada(j, edad, rep, club, bono)
    return "|".join([j["nombre"], pos, str(edad), str(media), pais, "", j["no"], altura, marcas])


FAMA_MINIMA = 12            ## artículos en otras Wikipedias para contar como «destacado»
BONOS_FAMA = (8, 6, 5, 4, 4)  ## sobre la regla general, de más a menos conocido del club


def bonos_por_fama(jugadores, wd):
    """{nombre: bono}: los 3-5 más conocidos del club (Wikidata: artículos en otros idiomas) suben de +4 a +8 sobre la regla;
    sin señal (menos de FAMA_MINIMA) no se toca nada. El más conocido queda además como el mejor del club (ver `main`)."""
    ranking = sorted(jugadores, key=lambda j: -wd.get(j["titulo"], {}).get("fama", 0))
    bonos = {}
    for j, b in zip(ranking, BONOS_FAMA):
        if wd.get(j["titulo"], {}).get("fama", 0) >= FAMA_MINIMA:
            bonos[j["nombre"]] = b
    return bonos


def es_generada(fila_txt):
    """Fila creada por esta herramienta (9 campos y marca «m» de media estimada)."""
    p = fila_txt.split("|")
    return len(p) >= 9 and "m" in p[8]


def validar(jugadores, minimo=18):
    """Problemas de una plantilla: lista de textos (vacía = buena)."""
    p = []
    if not minimo <= len(jugadores) <= 45:
        p.append(f"tamaño {len(jugadores)}")
    if sum(1 for j in jugadores if j["pos"] == "GK") < 2:
        p.append("menos de 2 porteros")
    return p


CUPO = {"GK": 3, "DF": 8, "MF": 8, "FW": 6}
MAXIMO = 26


def recortar(jugadores, maximo=MAXIMO):
    """Plantilla equilibrada de hasta `maximo`: el plantel del juego tiene ~25 plazas y `Reales` rellena EN ORDEN (el sobrante se pierde),
    así que una lista de 40 con los delanteros al final dejaría al club sin delanteros. Se conserva un cupo por línea (por dorsal) y se completa por dorsal."""
    if len(jugadores) <= maximo:
        return sorted(jugadores, key=_dorsal)
    elegidos = []
    for pos, cupo in CUPO.items():
        elegidos += sorted([j for j in jugadores if j["pos"] == pos], key=_dorsal)[:cupo]
    resto = sorted([j for j in jugadores if j not in elegidos], key=_dorsal)
    elegidos += resto[:max(0, maximo - len(elegidos))]
    return sorted(elegidos, key=_dorsal)


def _dorsal(j):
    return int(j["no"]) if str(j["no"]).isdigit() else 99


def _el_mas_conocido_es_el_mejor(filas, jugadores, wd):
    """Si el más conocido del club no es ya el de mayor media, su media pasa a ser la mayor +1 (tope 90)."""
    if len(filas) < 2:
        return filas
    top = max(jugadores, key=lambda j: wd.get(j["titulo"], {}).get("fama", 0))
    if wd.get(top["titulo"], {}).get("fama", 0) < FAMA_MINIMA:
        return filas
    partes = [f.split("|") for f in filas]
    medias = [int(p[3]) for p in partes]
    for p in partes:
        if p[0] == top["nombre"]:
            otros = max(m for q, m in zip(partes, medias) if q[0] != top["nombre"])
            p[3] = str(min(90, max(int(p[3]), otros + 1)))
    return ["|".join(p) for p in partes]


def minimo_de(mapa, liga, nom):
    v = (mapa.get(liga) or {}).get(nom)
    return int(v.get("minimo", 18)) if isinstance(v, dict) else 18


def fuente_de(mapa, liga, nom):
    """(título, idioma) del club en `clubes_wikipedia.json`: cadena = inglesa; {"es": título} = española."""
    v = (mapa.get(liga) or {}).get(nom)
    if isinstance(v, dict):
        return v.get("es"), "es"
    return v, "en"


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
            titulo, idioma = fuente_de(mapa, liga, nom)
            if not titulo:
                continue
            txt = wikitexto(titulo, idioma)
            jug = parsear_plantilla(txt) if txt else []
            problemas = []
            duplicados = 0
            unicos = []
            for j in jug:
                clave = limpiar(j["nombre"]).lower()
                if " " in clave and clave in vistos and vistos[clave] != nom:
                    duplicados += 1   ## el primer club que lo lista se lo queda
                    continue
                vistos[clave] = nom
                unicos.append(j)
            problemas = validar(unicos, minimo_de(mapa, liga, nom)) if unicos else ["sin plantilla en el artículo"]
            unicos = recortar(unicos) if not problemas else unicos
            wd = datos_wikidata([j["titulo"] for j in unicos if j["titulo"]], "eswiki" if idioma == "es" else "enwiki") if unicos else {}
            clave_pack = claves_reales.get(nom, club[0])
            propias = [a for a in t["REALES"].get(clave_pack, []) if not es_generada(a)]
            ya = {limpiar(a.split("|")[0]).lower() for a in propias}
            bonos = bonos_por_fama(unicos, wd)
            nuevos = [fila(j, wd, int(club[3]), liga, nom, bonos.get(j["nombre"], 0)) for j in unicos if limpiar(j["nombre"]).lower() not in ya]
            nuevos = _el_mas_conocido_es_el_mejor(nuevos, unicos, wd)
            informe.append((liga, nom, len(jug), len(propias), len(nuevos), problemas))
            print(f"{liga} {nom:22} {idioma} wiki={len(jug):2} propias={len(propias):2} nuevos={len(nuevos):2} dup={duplicados} {'; '.join(problemas)}")
            if aplicar and not problemas and nuevos:
                t["REALES"][clave_pack] = propias + nuevos
                nuevos_total += len(nuevos)
    if aplicar:
        with open(ruta_segura(PACK), "w", encoding="utf-8") as f:
            json.dump(pack, f, ensure_ascii=False, separators=(",", ":"))
        print("pack actualizado: +", nuevos_total, "jugadores")
    dudosos = [x for x in informe if x[5]]
    print(f"clubes: {len(informe)}; dudosos (no se aplican): {len(dudosos)}")


if __name__ == "__main__":
    main()
