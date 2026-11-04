#!/usr/bin/env python3
"""Compara un informe JSON del benchmark (nucleo/medicion.gd) con herramientas/presupuesto_benchmark.json.
   python3 herramientas/presupuesto_benchmark.py informe.json [pico_ram_mb]
Sale con 1 si alguna parte pasa de sus topes (llamadas, triángulos, memoria, vídeo). El pico de RAM del proceso solo avisa."""
import json, sys, os
aqui = os.path.dirname(os.path.abspath(__file__))
tope = json.load(open(os.path.join(aqui, "presupuesto_benchmark.json"), encoding="utf-8"))
inf = json.load(open(sys.argv[1], encoding="utf-8"))
fallos = 0
vistas = set()
for p in inf["partes"]:
    t = tope["partes"].get(p["parte"])
    if t is None:
        continue
    vistas.add(p["parte"])
    for k, v in t.items():
        ok = p.get(k, 0) <= v
        fallos += 0 if ok else 1
        print("  %-22s %-11s %12s / %-10s %s" % (p["parte"], k, p.get(k), v, "ok" if ok else "FALLO: se pasa del presupuesto"))
for n in tope["partes"]:
    if n not in vistas:
        print("  FALLO: el informe no trae la parte «%s»" % n)
        fallos += 1
## R01 (4-11): el barrido de resolución mide cada escala CON y SIN MSAA y el informe trae su resumen (msaa_35/50/70/100 y sus partes).
for e in ("35", "50", "70", "100"):
    for sufijo in ("", " sin MSAA"):
        n = "estadio MÍNIMA al %s %%%s" % (e, sufijo)
        if n not in [p["parte"] for p in inf["partes"]]:
            print("  FALLO: el informe no trae la parte «%s»" % n)
            fallos += 1
    if ("msaa_" + e) not in inf:
        print("  FALLO: el informe no trae el resumen del MSAA a %s %%" % e)
        fallos += 1
if len(sys.argv) > 2:
    pico = float(sys.argv[2])
    meta = tope["objetivo_pico_ram_mb"]
    print("  pico de RAM del proceso %.0f MB (objetivo %d MB): %s" % (pico, meta, "ok" if pico <= meta else "AVISO: por encima del objetivo (no falla)"))
print("===== FIN. %d fallos =====" % fallos)
sys.exit(1 if fallos else 0)
