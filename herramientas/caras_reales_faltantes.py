#!/usr/bin/env python3
"""Caras reales, cuarta pasada: los jugadores que siguen sin foto.

Las pasadas anteriores (`caras_reales_*.ps1`) solo miraban la propiedad P18
(imagen) de Wikidata. Quedaron ~900 jugadores sin foto: 573 porque su ficha de
Wikidata no tiene imagen, y el resto por errores de red (429, DNS) o por no
encontrar la ficha. Esta pasada:

  1. reintenta Wikidata (búsqueda + P18) para los que fallaron por error;
  2. si no hay P18, mira la imagen principal del artículo de Wikipedia
     (es, en, pt, fr, it, de) cuyo texto diga que es futbolista;
  3. acepta SOLO imágenes alojadas en Commons con licencia libre (CC0, CC BY,
     CC BY-SA, dominio público). Las imágenes "fair use" viven en la Wikipedia
     local, no en Commons, así que se descartan solas;
  4. baja una miniatura de 1280 px a `recursos/caras_reales/` y actualiza
     `datos/caras_reales_reporte.json` (autor y licencia incluidos, para los
     créditos).

Después hay que pasar, en este orden:
    python3 herramientas/caras_reales_recortar.py
    python3 herramientas/caras_reales_puntos.py yunet.onnx

Uso:
    python3 herramientas/caras_reales_faltantes.py [--max N]

Necesita salida a internet hacia *.wikipedia.org, www.wikidata.org,
commons.wikimedia.org y upload.wikimedia.org. Va despacio a propósito (una
llamada por segundo y espera larga si Wikimedia responde 429).
"""
import json
import os
import re
import sys
import time
import unicodedata
import urllib.parse
import urllib.request

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "dinastia-godot")
REPORTE = os.path.join(RAIZ, "datos", "caras_reales_reporte.json")
FOTOS = os.path.join(RAIZ, "recursos", "caras_reales")
LOG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "caras_reales_faltantes_log.txt")
AGENTE = "DinastiaFutbolManagerBot/1.0 (proyecto personal de aficionado, uso no comercial)"
IDIOMAS = ["es", "en", "pt", "fr", "it", "de"]
PALABRAS = ["futbolista", "footballer", "soccer", "futebolista", "footballeur", "calciatore", "fußballspieler", "fussballspieler"]
LIBRES = re.compile(r"^(cc0|cc[ -]by([ -]sa)?([ -]\d(\.\d)?)?|public domain|pd.*|dominio público)", re.I)
PAUSA = 1.0


def log(msg: str) -> None:
    print(msg)
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(time.strftime("%H:%M:%S ") + msg + "\n")


def pedir(url: str, binario: bool = False):
    for intento in range(5):
        time.sleep(PAUSA)
        try:
            req = urllib.request.Request(url, headers={"User-Agent": AGENTE})
            with urllib.request.urlopen(req, timeout=30) as r:
                datos = r.read()
                return datos if binario else json.loads(datos.decode("utf-8"))
        except urllib.error.HTTPError as e:
            if e.code == 429:
                espera = 30 * (intento + 1)
                log(f"  429: espero {espera} s")
                time.sleep(espera)
                continue
            if e.code == 404:
                return None
            raise
        except (urllib.error.URLError, TimeoutError):
            time.sleep(5 * (intento + 1))
    return None


def normal(s: str) -> str:
    s = unicodedata.normalize("NFKD", s)
    return "".join(c for c in s if not unicodedata.combining(c)).lower().strip()


def api(host: str, **p) -> dict:
    p["format"] = "json"
    return pedir(f"https://{host}/w/api.php?" + urllib.parse.urlencode(p)) or {}


def p18_wikidata(nombre: str):
    """(qid, archivo) del primer futbolista con imagen que se llame así."""
    r = api("www.wikidata.org", action="wbsearchentities", search=nombre, language="es", type="item", limit=8)
    ids = [x["id"] for x in r.get("search", [])]
    if not ids:
        return None, None
    ents = api("www.wikidata.org", action="wbgetentities", ids="|".join(ids), props="claims").get("entities", {})
    for qid in ids:
        cl = ents.get(qid, {}).get("claims", {})
        oficios = [c["mainsnak"].get("datavalue", {}).get("value", {}).get("id") for c in cl.get("P106", [])]
        if "Q937857" not in oficios:  # futbolista
            continue
        for c in cl.get("P18", []):
            archivo = c["mainsnak"].get("datavalue", {}).get("value")
            if archivo:
                return qid, archivo
        return qid, None
    return None, None


def imagen_wikipedia(nombre: str):
    """Archivo de la imagen principal de un artículo que hable de un futbolista."""
    for idioma in IDIOMAS:
        host = f"{idioma}.wikipedia.org"
        r = api(host, action="query", list="search", srsearch=nombre, srlimit=3)
        for hit in r.get("query", {}).get("search", []):
            if normal(nombre) not in normal(hit["title"]) and normal(hit["title"]) not in normal(nombre):
                continue
            q = api(host, action="query", prop="pageimages|extracts", titles=hit["title"], piprop="name",
                    exintro=1, explaintext=1, exchars=600, redirects=1)
            for pag in q.get("query", {}).get("pages", {}).values():
                texto = normal(pag.get("extract", ""))
                if pag.get("pageimage") and any(p in texto for p in PALABRAS):
                    return pag["pageimage"]
    return None


def datos_commons(archivo: str):
    """(url 1280 px, licencia, autor, ancho, alto) si está en Commons y es libre."""
    r = api("commons.wikimedia.org", action="query", titles="File:" + archivo, prop="imageinfo",
            iiprop="url|extmetadata|size", iiurlwidth=1280)
    for pag in r.get("query", {}).get("pages", {}).values():
        if "imageinfo" not in pag:
            return None  # no está en Commons: puede ser "fair use" local
        ii = pag["imageinfo"][0]
        meta = ii.get("extmetadata", {})
        lic = meta.get("LicenseShortName", {}).get("value", "")
        if not LIBRES.match(lic.strip()):
            return None
        autor = re.sub(r"<[^>]+>", "", meta.get("Artist", {}).get("value", "desconocido")).strip()
        return ii.get("thumburl") or ii["url"], lic, autor[:120], ii.get("width", 0), ii.get("height", 0)
    return None


def main() -> None:
    limite = int(sys.argv[sys.argv.index("--max") + 1]) if "--max" in sys.argv else 10 ** 9
    reporte = json.load(open(REPORTE, encoding="utf-8-sig"))
    os.makedirs(FOTOS, exist_ok=True)
    hechos = nuevos = 0
    for fila in reporte:
        if fila.get("encontrado") or hechos >= limite:
            continue
        hechos += 1
        nombre = fila["nombre"]
        try:
            qid, archivo = p18_wikidata(nombre)
            if not archivo:
                archivo = imagen_wikipedia(nombre)
            info = datos_commons(archivo) if archivo else None
            if not info:
                fila["nota"] = "4a pasada: sin imagen libre"
                log(f"- {nombre}: sin imagen libre")
                continue
            url, lic, autor, ancho, alto = info
            ext = ".png" if url.lower().endswith(".png") else ".jpg"
            rel = "recursos/caras_reales/" + re.sub(r"[^\w.-]", "_", nombre.replace(" ", "_")) + ext
            datos = pedir(url, binario=True)
            if not datos:
                fila["nota"] = "4a pasada: descarga fallida"
                continue
            with open(os.path.join(RAIZ, rel), "wb") as f:
                f.write(datos)
            fila.update({"encontrado": True, "qid": qid, "licencia": lic, "autor": autor,
                         "ancho": ancho, "alto": alto, "archivo": rel, "nota": "4a pasada"})
            nuevos += 1
            log(f"+ {nombre}: {lic} · {autor}")
        except Exception as e:  # noqa: BLE001 - seguir con el siguiente
            fila["nota"] = f"4a pasada: error {e}"[:120]
            log(f"! {nombre}: {e}")
        if hechos % 25 == 0:
            json.dump(reporte, open(REPORTE, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    json.dump(reporte, open(REPORTE, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    log(f"Listo: {nuevos} fotos nuevas de {hechos} buscados.")


if __name__ == "__main__":
    main()
