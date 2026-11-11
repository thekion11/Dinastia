#!/usr/bin/env python3
"""Informe de DIVERSIÓN de los tres motores del partido (11-11-2026, sesión 11).
   python3 herramientas/informe_tres_motores.py registro1.txt [registro2.txt …] > tablas.md
Lee las líneas «TRES_JSON {…}» que escribe `dinastia-godot/pruebas/comparar_tres_motores.tscn` (una por partido y motor) y saca
tablas por variante: «siempre», «league» y cada configuración del «combinado» (sus piezas que NO son de League, p. ej.
«combinado[locomocion=siempre]»). Medias por partido; la columna n es el número de partidos."""
import json, sys, collections
from ruta_segura import ruta_segura

def variante(r):
    if r["motor"] != "combinado":
        return r["motor"]
    piezas = dict(p.split("=") for p in r.get("piezas", "").split(", ") if "=" in p)
    cambios = [f"{k}={v}" for k, v in piezas.items() if v != "league"]
    return "combinado" if not cambios else "combinado[" + ",".join(cambios) + "]"

def media(xs):
    return sum(xs) / len(xs) if xs else 0.0

def main(rutas):
    filas = collections.defaultdict(list)
    for ruta in rutas:
        for linea in open(ruta_segura(ruta), encoding="utf-8", errors="replace"):
            if linea.startswith("TRES_JSON "):
                r = json.loads(linea[len("TRES_JSON "):])
                filas[variante(r)].append(r)
    orden = sorted(filas, key=lambda v: (v not in ("siempre", "league", "combinado"), v))
    def col(nombre, f, dec=1):
        return (nombre, lambda rs: round(media([f(r) for r in rs]), dec))
    tipos = ["jugada", "contra", "parado", "cabeza", "lejos", "penal"]
    bloques = [
        ("Acción y ocasiones (por partido)", [
            col("goles", lambda r: r["goles"], 2), col("tiros", lambda r: r["tiros"]), col("tiros de área", lambda r: r["tiros_area"]),
            col("ocasiones claras", lambda r: r["ocasiones"], 2), col("paradas del portero", lambda r: r["paradas_portero"]),
            col("tiros al palo", lambda r: r["palos"], 2), col("tiros fuera", lambda r: r["fallos"])]),
        ("Regates y duelos (por partido)", [
            col("regates", lambda r: r["regates"]), col("regates logrados", lambda r: r["regates_ok"]),
            col("duelos (hombro, dividido, agarrón)", lambda r: r["duelos"]), col("robos en duelo (≤ 2,5 m)", lambda r: r["robos_duelo"]),
            col("pérdidas a distancia", lambda r: r["perdidas_otras"])]),
        ("Pases encadenados", [
            col("pases", lambda r: r["pases"]), col("acierto de pase %", lambda r: 100.0 * r["pases_ok"] / max(r["pases"], 1)),
            col("cadenas", lambda r: r["cadenas"]), col("pases por cadena (media)", lambda r: r["cadena_media"], 2),
            col("cadena más larga (media de máximos)", lambda r: r["cadena_max"]), col("cadenas de 5+ pases", lambda r: r["cadenas_5"], 2)]),
        ("Goles: variedad (goles por partido de cada tipo)", [col(t, (lambda t: lambda r: r["goles_tipo"][t])(t), 2) for t in tipos]),
        ("Marcador y ritmo", [
            col("cambios de resultado", lambda r: r["cambios_resultado"], 2), col("remontadas", lambda r: r["remontadas"], 2),
            col("juego seguido medio (s)", lambda r: r["juego_seguido_medio"]), col("juego seguido máximo (s)", lambda r: r["juego_seguido_max"]),
            col("% del tiempo en juego", lambda r: r["pct_juego"]), col("paradas del juego (saques)", lambda r: r["paradas_de_juego"])]),
        ("Coste de CPU del motor", [
            col("µs por paso (30 Hz)", lambda r: r["us_paso"]), col("ms por partido", lambda r: r["ms_partido"], 0),
            col("paso más caro (µs)", lambda r: r["us_max"], 0)]),
    ]
    print(f"Partidos por variante: " + ", ".join(f"{v} = {len(filas[v])}" for v in orden) + "\n")
    for titulo, cols in bloques:
        print(f"### {titulo}\n")
        print("| medida | " + " | ".join(orden) + " |")
        print("|---|" + "---:|" * len(orden))
        for nombre, f in cols:
            print(f"| {nombre} | " + " | ".join(str(f(filas[v])) for v in orden) + " |")
        print()
    print("### Partidos jugados\n")
    vistos = {}
    for v in orden:
        for r in filas[v]:
            vistos.setdefault(r["k"], {"p": r["partido"], "m": {}})["m"][v] = r["marcador"]
    print("| # | partido | " + " | ".join(orden) + " |")
    print("|---|---|" + "---|" * len(orden))
    for k in sorted(vistos):
        print(f"| {k + 1} | {vistos[k]['p']} | " + " | ".join(vistos[k]["m"].get(v, "") for v in orden) + " |")

if __name__ == "__main__":
    main(sys.argv[1:])
