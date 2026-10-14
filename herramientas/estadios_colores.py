"""Pone `asientos` (colores de butacas del estadio real) en la tabla ESTADIO_CLUB de
`datos/tablas.json` (base ficticia, claves = nombre ficticio) y de `datos/pack_real.json`
(claves = nombre real) SIN regenerar todo el resto. Uso, desde la carpeta herramientas:
    python3 -I estadios_colores.py
"""
import json, sys
sys.path.insert(0, ".")
import estadios_reales as er
import base_ficticia as bf

def parchear(ruta, clave_de):
    d = json.load(open(ruta, encoding="utf-8"))
    tab = d["tablas"] if "tablas" in d else d
    n = 0
    for nombre, fila in tab.get("ESTADIO_CLUB", {}).items():
        real = clave_de(nombre)
        if real in er.ASIENTOS:
            fila["asientos"] = list(er.ASIENTOS[real])
            n += 1
        if real in er.ESCUDOS:
            fila["escudo"] = list(er.ESCUDOS[real])
    json.dump(d, open(ruta, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
    print(ruta, n, "estadios con colores propios")

inv = {v: k for k, v in bf.CLUBES.items()}
parchear("../dinastia-godot/datos/tablas.json", lambda n: inv.get(n, ""))
parchear("../dinastia-godot/datos/pack_real.json", lambda n: bf.limpiar(n))
