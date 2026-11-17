#!/usr/bin/env python3
"""Auditoría de «parecido real» (17-11): clubes, plantillas, rasgos de aspecto, escudos y uniformes por liga.

Lee `datos/pack_real.json` (solo uso privado), `datos/caras_reales_rasgos.json` y `datos/caras_reales_mallas.json`
y escribe cifras (no impresiones) en `docs/04_auditorias/parecido_real_cifras_2026-11-17.json`.

    python3 herramientas/auditar_parecido_real.py [salida.json]

Criterios (todos medibles):
  - clubes: los de la liga en el pack frente a la cantidad real (CANTIDAD_REAL);
  - plantilla: jugadores reales por club frente a 25 (plantilla de primer equipo; PLANTILLA_REAL);
  - campos: REALES trae «nombre|puesto|edad|media|país[|región]»: NO trae dorsal, altura, pie ni complexión;
  - aspecto: cuántos reales tienen piel/pelo/barba medidos (rasgos o malla) y cuántos usan el promedio del país;
  - escudo y uniforme: proxy de parecido = rasgos propios (figura/emblema/letras en el escudo; diseño de camiseta
    distinto de «liso», pantalón y medias propios, visita con diseño) frente al genérico.
"""
import json
import os
import sys
from collections import Counter, defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ruta_segura import ruta_segura, RAIZ_REPO  # noqa: E402

DATOS = os.path.join(RAIZ_REPO, "dinastia-godot", "datos")
DESTUNLEET = {"0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "7": "t", "8": "b", "9": "g"}
PLANTILLA_REAL = 25
## Cantidad real de clubes de la primera división (temporada 2026/27 conocida; [C] = de memoria, sin verificar hoy).
CANTIDAD_REAL = {"ENG": 20, "ESP": 20, "ITA": 20, "GER": 18, "FRA": 18, "ARG": 30, "BRA": 20, "CHI": 16,
                 "POR": 18, "NED": 18, "MEX": 18, "USA": 30, "TUR": 18, "BEL": 16, "COL": 20, "URU": 16}
GRANDES = ["ENG", "ESP", "ITA", "GER", "FRA", "ARG", "BRA", "CHI"]


def limpiar(s):
    """Quita el leetspeak de las claves del pack y normaliza para comparar."""
    return "".join(DESTUNLEET.get(c, c) for c in s).lower().strip()


def cargar(nombre):
    with open(ruta_segura(os.path.join(DATOS, nombre)), encoding="utf-8-sig") as f:
        return json.load(f)


def _kit_propio(a):
    """Cuántas señales de diseño propio tiene el uniforme de un club (0-4)."""
    k = a.get("kit") or {}
    v = a.get("visita") or {}
    s = 0
    s += a.get("camiseta", "liso") != "liso"
    s += bool(k.get("pant")) and bool(k.get("med"))
    s += bool(v)
    s += (v.get("camiseta", "liso") != "liso") if v else 0
    return s


def _escudo_propio(a):
    """Señales de escudo propio (0-3): patrón no liso, emblema o letras."""
    forma_patron = a.get("escudo") or ["", "liso"]
    return int(forma_patron[1] != "liso") + int(bool(a.get("emblema"))) + int(bool(a.get("letras")))


def auditar():
    pack = cargar("pack_real.json")["tablas"]
    rasgos = {limpiar(k) for k in cargar("caras_reales_rasgos.json")}
    mallas_raw = cargar("caras_reales_mallas.json")
    mallas = {limpiar(k) for k in (mallas_raw if isinstance(mallas_raw, dict) else {})}
    reales = {limpiar(k): v for k, v in pack["REALES"].items()}
    aspecto = {limpiar(k): v for k, v in pack["ASPECTO_CLUB"].items()}
    ligas = dict(pack["PAISES_LIGAS"])
    ligas["CHI"] = {"liga": "Primera Chile", "clubes": pack["DATA_P1"]}   ## Chile vive en DATA_P1/DATA_P2, no en PAISES_LIGAS
    salida = {"fecha": "2026-11-17", "paises": {}, "resumen": {}}
    tot = Counter()
    for cod, d in sorted(ligas.items()):
        clubes = d["clubes"]
        fila = {"liga": d.get("liga", ""), "clubes_pack": len(clubes), "clubes_reales": CANTIDAD_REAL.get(cod),
                "con_plantilla_real": 0, "jugadores_reales": 0, "jugadores_faltan_25": 0,
                "con_rasgos": 0, "con_malla": 0, "sin_dato_aspecto": 0,
                "escudo_propio": 0, "escudo_generico": 0, "kit_completo": 0, "kit_basico": 0, "kit_sin_visita": 0}
        for c in clubes:
            nom = limpiar(c[0])
            plant = reales.get(nom, [])
            if plant:
                fila["con_plantilla_real"] += 1
            for linea in plant:
                p = linea.split("|")
                jn = limpiar(p[0])
                fila["jugadores_reales"] += 1
                if jn in rasgos:
                    fila["con_rasgos"] += 1
                elif jn in mallas:
                    fila["con_malla"] += 1
                else:
                    fila["sin_dato_aspecto"] += 1
            if plant:
                fila["jugadores_faltan_25"] += max(0, PLANTILLA_REAL - len(plant))
            a = aspecto.get(nom)
            if not a:
                fila["escudo_generico"] += 1
                fila["kit_sin_visita"] += 1
                continue
            fila["escudo_propio" if _escudo_propio(a) >= 2 else "escudo_generico"] += 1
            sc = _kit_propio(a)
            if not a.get("visita"):
                fila["kit_sin_visita"] += 1
            fila["kit_completo" if sc >= 3 else "kit_basico"] += 1
        salida["paises"][cod] = fila
        for k, v in fila.items():
            if isinstance(v, int) and k != "clubes_reales":
                tot[k] += v
    salida["resumen"] = dict(tot)
    salida["campos_que_no_trae_REALES"] = ["dorsal", "altura", "pie", "complexion", "barba (salvo rasgos)", "peso"]
    salida["tamano_plantilla_real_en_pack"] = dict(Counter(len(v) for v in reales.values()).most_common())
    return salida


def main():
    destino = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        RAIZ_REPO, "docs", "04_auditorias", "parecido_real_cifras_2026-11-17.json")
    res = auditar()
    with open(ruta_segura(destino), "w", encoding="utf-8") as f:
        json.dump(res, f, ensure_ascii=False, indent=1)
    print("resumen:", res["resumen"])
    print(f"{'liga':5}{'clubes':>7}{'real':>5}{'conPl':>6}{'jug':>5}{'falt25':>7}{'rasg':>5}{'malla':>6}{'sinAsp':>7}{'escP':>5}{'escG':>5}{'kitC':>5}{'kitB':>5}")
    for cod in GRANDES:
        f = res["paises"].get(cod)
        if f:
            print(f"{cod:5}{f['clubes_pack']:7}{f['clubes_reales'] or 0:5}{f['con_plantilla_real']:6}{f['jugadores_reales']:5}"
                  f"{f['jugadores_faltan_25']:7}{f['con_rasgos']:5}{f['con_malla']:6}{f['sin_dato_aspecto']:7}"
                  f"{f['escudo_propio']:5}{f['escudo_generico']:5}{f['kit_completo']:5}{f['kit_basico']:5}")


if __name__ == "__main__":
    main()
