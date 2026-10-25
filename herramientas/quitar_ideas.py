#!/usr/bin/env python3
"""Quita del plan las ideas del dueño que ya tienen una prueba del banco que las comprueba de verdad.
   python3 herramientas/quitar_ideas.py 5 6 7 ...   (borra las líneas «- N. …» de docs/PLAN_DEL_LUNES.md)"""
import re, sys
p = "docs/PLAN_DEL_LUNES.md"
ids = {int(x) for x in sys.argv[1:]}
L = open(p, encoding="utf-8").read().split("\n")
out, quitadas = [], []
for l in L:
    m = re.match(r"- (\d+)\. ", l)
    if m and int(m.group(1)) in ids:
        quitadas.append(int(m.group(1)))
        continue
    out.append(l)
open(p, "w", encoding="utf-8").write("\n".join(out))
print("quitadas", len(quitadas), sorted(quitadas))
print("no estaban", sorted(ids - set(quitadas)))
