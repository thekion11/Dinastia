#!/usr/bin/env python3
"""PERFIL POR SENTENCIAS DE UNA FUNCIÓN GDScript (10-11-2026, arranque del menú). Instrumenta EN EL SITIO (revertir con `git checkout -- <archivo>`) las sentencias de primer nivel de las funciones
indicadas: antes de cada una guarda la hora y, justo antes de la siguiente (o al final), imprime `PROF archivo:línea ms` si tardó más del umbral. Sirve para ver dónde se va el tiempo de un montaje
(`pruebas/medir_arranque_menu.tscn`). No sirve para funciones con `return` en medio (esa salida no se mide) ni con `yield`/`await` (mide hasta el primer `await`).
   python3 herramientas/perfil_sentencias.py <archivo.gd> <funcion> [<funcion>...]   [--umbral=MS]
"""
import re, sys
from ruta_segura import ruta_segura
args = [a for a in sys.argv[1:] if not a.startswith("--")]
umbral = 5
for a in sys.argv[1:]:
    if a.startswith("--umbral="):
        umbral = int(a.split("=")[1])
archivo, funciones = args[0], args[1:]
ruta = ruta_segura(archivo)
lineas = open(ruta, encoding="utf-8").read().split("\n")
out, i, n = [], 0, 0
nombre = archivo.split("/")[-1]
while i < len(lineas):
    ln = lineas[i]
    m = re.match(r"^(static )?func (\w+)\(", ln)
    if m and m.group(2) in funciones:
        out.append(ln)
        i += 1
        # cuerpo: hasta la siguiente línea sin sangría que no esté vacía ni sea comentario
        cuerpo = []
        while i < len(lineas) and (lineas[i].startswith("\t") or lineas[i].strip() == ""):
            cuerpo.append(lineas[i])
            i += 1
        previo = None
        for k, c in enumerate(cuerpo):
            es_inicio = c.startswith("\t") and not c.startswith("\t\t") and c.strip() and not c.strip().startswith(("#", ")", "]", "}", "else", "elif"))
            if es_inicio:
                if previo is not None:
                    out.append("\tif Time.get_ticks_usec() - _t%d > %d: print('PROF %s:%d %%d ms' %% ((Time.get_ticks_usec() - _t%d) / 1000))" % (previo[0], umbral * 1000, nombre, previo[1], previo[0]))
                n += 1
                out.append("\tvar _t%d := Time.get_ticks_usec()" % n)
                previo = (n, i - len(cuerpo) + k + 1)
            out.append(c)
        if previo is not None:
            # al final del cuerpo (antes de líneas vacías finales)
            while out and out[-1].strip() == "":
                out.pop()
            out.append("\tif Time.get_ticks_usec() - _t%d > %d: print('PROF %s:%d %%d ms' %% ((Time.get_ticks_usec() - _t%d) / 1000))" % (previo[0], umbral * 1000, nombre, previo[1], previo[0]))
            out.append("")
        continue
    out.append(ln)
    i += 1
open(ruta, "w", encoding="utf-8").write("\n".join(out))
print("instrumentadas", n, "sentencias en", archivo)
