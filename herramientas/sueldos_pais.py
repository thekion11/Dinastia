#!/usr/bin/env python3
"""Rehace la tabla FACTOR de dinastia-godot/nucleo/sueldos_pais.gd a partir de la sonda de sueldos.

Uso (desde la raíz del repositorio):
  cd dinastia-godot && godot --headless --path . res://pruebas/_sonda/sonda_sueldos_todos.tscn > /tmp/sueldos.txt
  python3 herramientas/sueldos_pais.py /tmp/sueldos.txt

OJO: la sonda hay que correrla con la tabla VACÍA (FACTOR := {}) para medir los sueldos sin escalar;
con la tabla puesta mide el resultado (todas las medianas deben quedar cerca del objetivo).
Cada línea de la sonda: «SUELDOS <país> clubes <n> mediana <pct> max <pct> rojo <n>».
"""
import re
import sys

from ruta_segura import ruta_segura

OBJETIVO = 28      # % de los ingresos que debe ser la masa salarial mediana de la liga
UMBRAL = 34        # por debajo de esto la liga se deja como está
SUELO = 0.10       # ningún país cobra menos que esto del sueldo «mundial»
DESTINO = "dinastia-godot/nucleo/sueldos_pais.gd"


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    medianas = {}
    with open(ruta_segura(sys.argv[1]), encoding="utf-8") as f:
        for linea in f:
            p = linea.split()
            if len(p) >= 6 and p[0] == "SUELDOS":
                medianas[p[1]] = int(p[5])
    factores = {k: max(SUELO, round(OBJETIVO / v, 2)) for k, v in sorted(medianas.items()) if v > UMBRAL}
    items = ['"%s": %s' % (k, v) for k, v in factores.items()]
    lineas = [", ".join(items[i:i + 10]) + "," for i in range(0, len(items), 10)]
    with open(DESTINO, encoding="utf-8") as f:
        texto = f.read()
    nuevo, n = re.subn(r"const FACTOR := \{\n.*?\n\}", "const FACTOR := {\n\t" + "\n\t".join(lineas) + "\n}", texto, flags=re.S)
    if n != 1:
        print("No encuentro el bloque FACTOR en", DESTINO)
        return 1
    with open(DESTINO, "w", encoding="utf-8") as f:
        f.write(nuevo)
    print("países medidos", len(medianas), "· con factor", len(factores))
    return 0


if __name__ == "__main__":
    sys.exit(main())
