#!/usr/bin/env python3
"""RASGOS DE CARA POR PAÍS (10-11, encargo del dueño «uniformes y caras», parte 2). Ajusta, con las caras REALES ya medidas (`caras_reales_rasgos.json` y
`caras_reales_mallas.json`), cómo son los futbolistas de cada país: tono de piel, color de pelo, barba y calvicie. El resultado, `datos/rasgos_pais.json`, son
solo PROPORCIONES por país (sin nombres ni fotos de nadie) y lo usa `CaraPrior` para dar una cara coherente a los jugadores de los que no hay foto.
También MIDE cuánto mejora frente a los modelos anteriores (validación cruzada: la tabla de cada pliegue no ve a los jugadores que evalúa).
    python3 herramientas/rasgos_por_pais.py            # ajusta y escribe datos/rasgos_pais.json
    python3 herramientas/rasgos_por_pais.py --medir    # solo la medición antes/después
"""
import colorsys
import json
import os
import random
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATOS = os.path.join(RAIZ, "dinastia-godot", "datos")
PIELES = ["#f5d0b0", "#f0c39b", "#e0ab80", "#d7a377", "#b97f4f", "#8a5a34", "#6b4529", "#4e3320"]
PELOS = ["#231a14", "#3d2a19", "#6b4a2a", "#c8a05a", "#1a1a1a", "#4a3a2a", "#8a6a3a", "#d8d8d8"]   # los de `Cara.PELOS` (modelo viejo, al azar)
CLASES_PELO = ["negro", "castano_oscuro", "castano", "rubio", "claro_o_canoso", "pelirrojo"]
BARBAS = [0, 2, 3, 4, 5]   # sin barba, perilla, mosca, candado con sombra, sombra de barba (las que salen en las fotos); el resto del catálogo no se usa
UNLEET = {"0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "8": "b", "9": "g"}
SUAVIZADO = 10.0   # peso (en jugadores) de la media mundial al estimar un país


def limpiar(n: str) -> str:
    s = ""
    for i, c in enumerate(n):
        if c in UNLEET and ((i > 0 and n[i - 1].isalpha()) or (i + 1 < len(n) and n[i + 1].isalpha())):
            s += UNLEET[c]
        else:
            s += c
    return s


def rgb(h: str):
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (1, 3, 5))


def piel_idx(h: str) -> int:
    c = rgb(h)
    return min(range(len(PIELES)), key=lambda i: sum((a - b) ** 2 for a, b in zip(c, rgb(PIELES[i]))))


def clase_pelo(h: str) -> str:
    r, g, b = rgb(h)
    hh, s, v = colorsys.rgb_to_hsv(r, g, b)
    lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
    if s < 0.18 and lum > 0.42:
        return "claro_o_canoso"
    if lum < 0.10:
        return "negro"
    if lum < 0.20:
        return "castano_oscuro"
    if 0.0 <= hh * 360 < 25 and s > 0.55 and lum > 0.25:
        return "pelirrojo"
    if lum > 0.40 and 35 <= hh * 360 <= 70:
        return "rubio"
    return "castano"


def cargar():
    """Lista de {pais, edad, piel, pelo, barba, calvo} de los jugadores con cara medida."""
    pk = json.load(open(os.path.join(DATOS, "pack_real.json"), encoding="utf-8"))["tablas"]["REALES"]
    ras = json.load(open(os.path.join(DATOS, "caras_reales_rasgos.json"), encoding="utf-8"))
    mal = json.load(open(os.path.join(DATOS, "caras_reales_mallas.json"), encoding="utf-8"))
    out = []
    for lista in pk.values():
        for s in lista:
            nombre, _pos, edad, _ovr, pais = s.split("|")[:5]
            n = limpiar(nombre)
            r = ras.get(n)
            m = mal.get(n)
            if r is None and m is None:
                continue
            rec = {"pais": pais, "edad": int(edad), "piel": None, "pelo": None, "barba": None, "calvo": False}
            if m is not None:
                if m.get("s"):
                    rec["piel"] = piel_idx(m["s"])
                h = m.get("h")
                if isinstance(h, dict):
                    rec["calvo"] = bool(h.get("calvo"))
                    if h.get("c") and not rec["calvo"]:
                        rec["pelo"] = clase_pelo(h["c"])
            if r is not None:
                if r.get("piel"):
                    rec["piel"] = piel_idx(r["piel"])
                if r.get("peloC"):
                    rec["pelo"] = clase_pelo(r["peloC"])
                if "barba" in r:
                    rec["barba"] = int(r["barba"])
            out.append(rec)
    return out


def probs(cuentas: dict, claves: list, base: dict, peso: float) -> dict:
    n = sum(cuentas.get(k, 0) for k in claves)
    return {k: (cuentas.get(k, 0) + peso * base[k]) / (n + peso) for k in claves}


def ajustar(recs: list) -> dict:
    """{'*': mundial, pais: {...}} con piel (8), pelo (clases), barba (BARBAS), calvo (prob.) y `veterano_calvo` (calvo a partir de 31 años)."""
    def contar(rs):
        c = {"n": len(rs), "piel": {}, "pelo": {}, "barba": {}, "calvo": [0, 0], "calvo_vet": [0, 0]}
        for r in rs:
            if r["piel"] is not None:
                c["piel"][r["piel"]] = c["piel"].get(r["piel"], 0) + 1
            if r["pelo"] is not None:
                c["pelo"][r["pelo"]] = c["pelo"].get(r["pelo"], 0) + 1
            if r["barba"] is not None:
                b = r["barba"] if r["barba"] in BARBAS else 0
                c["barba"][b] = c["barba"].get(b, 0) + 1
            if r["pelo"] is not None or r["calvo"]:
                k = "calvo_vet" if r["edad"] >= 31 else "calvo"
                c[k][0] += 1 if r["calvo"] else 0
                c[k][1] += 1
        return c

    mundo = contar(recs)
    plano = {
        "piel": {i: 1.0 / len(PIELES) for i in range(len(PIELES))},
        "pelo": {k: 1.0 / len(CLASES_PELO) for k in CLASES_PELO},
        "barba": {b: 1.0 / len(BARBAS) for b in BARBAS},
    }
    glob = {
        "piel": probs(mundo["piel"], list(range(len(PIELES))), plano["piel"], 1.0),
        "pelo": probs(mundo["pelo"], CLASES_PELO, plano["pelo"], 1.0),
        "barba": probs(mundo["barba"], BARBAS, plano["barba"], 1.0),
    }
    g_calvo = (mundo["calvo"][0] + 0.5) / (mundo["calvo"][1] + 5.0)
    g_calvo_v = (mundo["calvo_vet"][0] + 0.5) / (mundo["calvo_vet"][1] + 5.0)
    tabla = {"*": {"n": mundo["n"], "piel": [glob["piel"][i] for i in range(len(PIELES))], "pelo": {k: glob["pelo"][k] for k in CLASES_PELO},
                   "barba": {str(b): glob["barba"][b] for b in BARBAS}, "calvo": g_calvo, "calvo_vet": g_calvo_v}}
    for pais in sorted({r["pais"] for r in recs}):
        c = contar([r for r in recs if r["pais"] == pais])
        tabla[pais] = {
            "n": c["n"],
            "piel": [probs(c["piel"], list(range(len(PIELES))), glob["piel"], SUAVIZADO)[i] for i in range(len(PIELES))],
            "pelo": probs(c["pelo"], CLASES_PELO, glob["pelo"], SUAVIZADO),
            "barba": {str(b): p for b, p in probs(c["barba"], BARBAS, glob["barba"], SUAVIZADO).items()},
            "calvo": (c["calvo"][0] + SUAVIZADO * g_calvo) / (c["calvo"][1] + SUAVIZADO),
            "calvo_vet": (c["calvo_vet"][0] + SUAVIZADO * g_calvo_v) / (c["calvo_vet"][1] + SUAVIZADO),
        }
    return tabla


# ---- MEDICIÓN: probabilidad media de acertar el rasgo REAL de cada jugador con cada modelo -------------------------------------------------------------------
TONO_MEDIO = {"CHI": 2.8, "ARG": 1.8, "URU": 1.9, "PAR": 2.9, "BOL": 3.6, "PER": 3.6, "ECU": 3.6, "COL": 3.7, "VEN": 3.6, "MEX": 3.2, "BRA": 4.0, "USA": 3.0,
              "ESP": 1.7, "ITA": 1.7, "GER": 1.3, "ENG": 2.0, "FRA": 3.0, "JPN": 1.7, "KOR": 1.5, "AUS": 1.7, "KSA": 3.4, "EGY": 3.8, "MAR": 3.6, "RSA": 5.2,
              "POR": 2.4, "NED": 2.0, "BEL": 2.3, "CRO": 1.6, "DEN": 1.6}
RUBIOS = {"GER": 0.32, "ENG": 0.26, "AUS": 0.22, "USA": 0.16, "FRA": 0.12, "ITA": 0.08, "ESP": 0.07, "ARG": 0.09, "URU": 0.09, "CHI": 0.06, "BRA": 0.05,
          "JPN": 0.0, "KOR": 0.0, "NED": 0.3, "DEN": 0.35, "BEL": 0.2, "CRO": 0.15, "POR": 0.04}


def modelo_publico(pais: str, rnd: random.Random) -> dict:
    """El modelo anterior de la base pública (`Cara._piel_y_pelo_del_pais`) + barba al azar 0-7 (`_look_base`)."""
    medio = TONO_MEDIO.get(pais, 3.5)
    campana = sum(rnd.random() for _ in range(3)) / 3.0
    ip = min(max(int(round(medio + (campana - 0.5) * 7.0)), 0), 7)
    r = rnd.random()
    rub = RUBIOS.get(pais, 0.06)
    if ip <= 2 and r < rub:
        pelo = "rubio"
    else:
        pelo = rnd.choice(["negro", "castano_oscuro", "negro", "castano_oscuro", "castano", "negro"])
    return {"piel": ip, "pelo": pelo, "barba": rnd.randrange(8), "calvo": False}


def modelo_real_sin_foto(_pais: str, rnd: random.Random) -> dict:
    """Lo que recibía un jugador real SIN foto en la base real: todo al azar (`_look_base`: piel de 8 tonos a partes iguales, barba 0-7, pelo de `PELOS`)."""
    c = rnd.choice(PELOS)
    clase = clase_pelo(c)
    return {"piel": rnd.randrange(8), "pelo": clase, "barba": rnd.randrange(8), "calvo": False}


def modelo_nuevo(tabla: dict, pais: str, edad: int, rnd: random.Random) -> dict:
    t = tabla.get(pais, tabla["*"])
    ip = rnd.choices(range(len(PIELES)), weights=t["piel"])[0]
    pelo = rnd.choices(CLASES_PELO, weights=[t["pelo"][k] for k in CLASES_PELO])[0]
    barba = int(rnd.choices(list(t["barba"]), weights=list(t["barba"].values()))[0])
    calvo = rnd.random() < (t["calvo_vet"] if edad >= 31 else t["calvo"])
    return {"piel": ip, "pelo": pelo, "barba": barba, "calvo": calvo}


def acierta(pred: dict, r: dict) -> dict:
    """1 si el rasgo previsto coincide con el real (piel: ±1 tono; barba: igual de «con/sin barba» y, si hay, del mismo tipo)."""
    out = {}
    if r["piel"] is not None:
        out["piel_pm1"] = 1.0 if abs(pred["piel"] - r["piel"]) <= 1 else 0.0
        out["piel_exacta"] = 1.0 if pred["piel"] == r["piel"] else 0.0
    if r["pelo"] is not None:
        out["pelo"] = 1.0 if pred["pelo"] == r["pelo"] else 0.0
    if r["barba"] is not None:
        rb = r["barba"] if r["barba"] in BARBAS else 0
        out["barba_con_sin"] = 1.0 if (pred["barba"] == 0) == (rb == 0) else 0.0
        out["barba_tipo"] = 1.0 if (pred["barba"] if pred["barba"] in BARBAS else -1) == rb else 0.0
    out["calvo"] = 1.0 if bool(pred["calvo"]) == bool(r["calvo"]) else 0.0
    if all(k in out for k in ("piel_pm1", "pelo", "barba_con_sin")):   # «cara coherente»: piel (±1 tono), color de pelo y con/sin barba, las tres bien
        out["coherente"] = out["piel_pm1"] * out["pelo"] * out["barba_con_sin"]
    return out


def medir(recs: list, pliegues: int = 5, muestras: int = 40) -> dict:
    rnd = random.Random(7)
    res = {m: {} for m in ("real_sin_foto (antes)", "publico (antes)", "nuevo (después)")}
    cuenta = {m: {} for m in res}
    orden = list(range(len(recs)))
    rnd.shuffle(orden)
    for f in range(pliegues):
        prueba = [recs[i] for k, i in enumerate(orden) if k % pliegues == f]
        tabla = ajustar([recs[i] for k, i in enumerate(orden) if k % pliegues != f])
        for r in prueba:
            for nombre, fn in (("real_sin_foto (antes)", lambda p, e: modelo_real_sin_foto(p, rnd)), ("publico (antes)", lambda p, e: modelo_publico(p, rnd)),
                               ("nuevo (después)", lambda p, e: modelo_nuevo(tabla, p, e, rnd))):
                for _ in range(muestras):
                    for k, v in acierta(fn(r["pais"], r["edad"]), r).items():
                        res[nombre][k] = res[nombre].get(k, 0.0) + v
                        cuenta[nombre][k] = cuenta[nombre].get(k, 0) + 1
    return {m: {k: res[m][k] / cuenta[m][k] for k in res[m]} for m in res}


def main() -> int:
    recs = cargar()
    print("jugadores con cara medida:", len(recs), "· países:", len({r["pais"] for r in recs}))
    m = medir(recs)
    claves = ["piel_pm1", "pelo", "barba_con_sin", "barba_tipo", "coherente"]
    print("%-24s" % "% de acierto" + "".join("%15s" % k for k in claves))
    for nombre, v in m.items():
        print("%-24s" % nombre + "".join("%14.1f%%" % (100.0 * v.get(k, 0.0)) for k in claves))
    if "--medir" in sys.argv:
        return 0
    tabla = ajustar(recs)
    with open(os.path.join(DATOS, "rasgos_pais.json"), "w", encoding="utf-8") as f:
        json.dump(tabla, f, ensure_ascii=False, indent=1, sort_keys=True)
    print("escrito datos/rasgos_pais.json (%d países)" % (len(tabla) - 1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
