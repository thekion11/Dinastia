#!/usr/bin/env python3
"""Genera `docs/MAPA_CODIGO.md`, el mapa del código por zonas (idea del dueño, 16-11).

  python3 dinastia-godot/herramientas/mapa_codigo.py              # escribe docs/MAPA_CODIGO.md
  python3 dinastia-godot/herramientas/mapa_codigo.py --comprobar  # código 1 si el archivo subido difiere del generado

No se edita a mano. Por zona: carpeta, puntos de entrada (clases más usadas), cadenas de herencia de
`partir_gd.py` (capas), tamaño en líneas (cerca del tope de 450) y quién usa cada clase.
"""
import os
import re
import sys

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
JUEGO = os.path.join(RAIZ, "dinastia-godot")
SALIDA = os.path.join(RAIZ, "docs", "MAPA_CODIGO.md")
LIMITE = 450
CERCA = 400
TOP = 14

ZONAS = [
    ("Extensión C++", ("dinastia-godot/nativo/src/",)),
    ("La Ruta (modo jugador)", ("dinastia-godot/nucleo/carrera_", "dinastia-godot/ui/carrera/")),
    ("Partido: motor C4 y respaldo", ("dinastia-godot/nucleo/partido", "dinastia-godot/nucleo/motor_",
                                      "dinastia-godot/visor/motor_", "dinastia-godot/visor/league_",
                                      "dinastia-godot/visor/mejoras_c4", "dinastia-godot/visor/partido")),
    ("Club e instalaciones", ("dinastia-godot/nucleo/club", "dinastia-godot/visor/club", "dinastia-godot/visor/casa",
                              "dinastia-godot/visor/estadio", "dinastia-godot/visor/stadium")),
    ("Menús e interfaz", ("dinastia-godot/ui/",)),
    ("Minijuegos", ("dinastia-godot/minijuegos/",)),
    ("Pruebas y banco", ("dinastia-godot/pruebas/",)),
    ("Núcleo: mundo, gestión y datos", ("dinastia-godot/nucleo/",)),
    ("Visor: 3D, cámaras y efectos", ("dinastia-godot/visor/",)),
]

RE_CLASE = re.compile(r"^class_name\s+(\w+)", re.M)
RE_EXT = re.compile(r"^extends\s+(.+?)\s*$", re.M)
RE_IDENT = re.compile(r"[A-Za-z_]\w*")


def listar():
    salida = []
    for base, _dirs, archivos in os.walk(JUEGO):
        rel = os.path.relpath(base, RAIZ).replace(os.sep, "/")
        if any(p in rel for p in ("/terceros", "/addons", "/.godot", "/bin_nativo", "/assets")) or "godot-cpp" in rel:
            continue
        for a in archivos:
            if a.endswith((".gd", ".cpp", ".h")):
                salida.append(rel + "/" + a)
    return sorted(salida)


def leer(ruta):
    with open(os.path.join(RAIZ, ruta), encoding="utf-8", errors="ignore") as f:
        return f.read()


def zona_de(ruta):
    for nombre, prefijos in ZONAS:
        if ruta.startswith(prefijos):
            return nombre
    return "Otros"


def main():
    archivos = listar()
    info = {}
    for ruta in archivos:
        t = leer(ruta)
        n = t.count("\n") + (0 if t.endswith("\n") or not t else 1)
        d = {"lineas": n, "clase": "", "ext": "", "idents": set()}
        if ruta.endswith(".gd"):
            m = RE_CLASE.search(t)
            d["clase"] = m.group(1) if m else ""
            e = RE_EXT.search(t)
            d["ext"] = e.group(1).strip('"') if e else ""
            d["idents"] = set(RE_IDENT.findall(t))
        info[ruta] = d

    por_clase = {d["clase"]: r for r, d in info.items() if d["clase"]}
    usos = {c: 0 for c in por_clase}
    for ruta, d in info.items():
        for c in d["idents"] & usos.keys():
            if por_clase[c] != ruta:
                usos[c] += 1

    # Cadenas de capas: A extiende "res://ruta/b.gd" -> B es la capa base de A.
    base_de = {}
    for ruta, d in info.items():
        if d["ext"].startswith("res://"):
            base_de[ruta] = "dinastia-godot/" + d["ext"][len("res://"):]
    es_base = set(base_de.values())

    def cadena(ruta):
        c = [ruta]
        while c[-1] in base_de and base_de[c[-1]] in info and len(c) < 12:
            c.append(base_de[c[-1]])
        return c

    zonas = {}
    for ruta in archivos:
        zonas.setdefault(zona_de(ruta), []).append(ruta)

    L = ["# MAPA DEL CÓDIGO", "",
         "Generado por `dinastia-godot/herramientas/mapa_codigo.py` (no se edita a mano; el banco falla si difiere).", "",
         "Qué es cada columna: **Usos** = archivos que nombran la clase; **Líneas** = tamaño (tope %d); **Capas** = cadena de herencia "
         "de `partir_gd.py` (la última conserva la ruta y el `class_name`)." % LIMITE, ""]
    total = sum(d["lineas"] for d in info.values())
    L.append("Total: %d archivos (.gd, .cpp, .h), %d líneas, %d clases con nombre." % (len(info), total, len(por_clase)))
    L.append("")
    for nombre, _p in ZONAS:
        rs = zonas.get(nombre, [])
        if not rs:
            continue
        carpetas = sorted({os.path.dirname(r) for r in rs})
        L.append("## " + nombre)
        L.append("")
        L.append("%d archivos, %d líneas. Carpetas: %s." % (len(rs), sum(info[r]["lineas"] for r in rs),
                 ", ".join("`%s`" % c.replace("dinastia-godot/", "") for c in carpetas[:6]) + (" …" if len(carpetas) > 6 else "")))
        L.append("")
        if nombre == "Pruebas y banco":
            L.append("Entradas: `pruebas/banco.gd` (secciones en `pruebas/banco/*.gd`), escenas `*.tscn` lanzadas por `herramientas/banco.sh` y `especiales.sh`.")
            L.append("")
            continue
        punto = [r for r in rs if info[r]["clase"]]
        punto.sort(key=lambda r: (-usos.get(info[r]["clase"], 0), r))
        if nombre == "Extensión C++":
            L.append("Cada función es copia exacta de su gemela GDScript (regla de la extensión). Archivos por tamaño:")
            L.append("")
            for r in sorted(rs, key=lambda r: -info[r]["lineas"])[:TOP]:
                L.append("- `%s` (%d líneas)" % (r.replace("dinastia-godot/", ""), info[r]["lineas"]))
            L.append("")
            continue
        L.append("| Clase | Archivo | Líneas | Usos | Capas |")
        L.append("|---|---|---|---|---|")
        for r in punto[:TOP]:
            ch = cadena(r)
            capas = " ← ".join(os.path.basename(c) for c in ch[1:]) if len(ch) > 1 else ""
            L.append("| `%s` | `%s` | %d | %d | %s |" % (info[r]["clase"], r.replace("dinastia-godot/", ""),
                     info[r]["lineas"], usos.get(info[r]["clase"], 0), capas))
        cerca = sorted((r for r in rs if info[r]["lineas"] >= CERCA), key=lambda r: -info[r]["lineas"])
        if cerca:
            L.append("")
            L.append("Cerca del tope (≥ %d líneas): " % CERCA + ", ".join("`%s` (%d)" % (os.path.basename(r), info[r]["lineas"]) for r in cerca[:10]) + ".")
        L.append("")
    texto = "\n".join(L).rstrip() + "\n"
    if "--comprobar" in sys.argv:
        actual = open(SALIDA, encoding="utf-8").read() if os.path.exists(SALIDA) else ""
        if actual != texto:
            print("docs/MAPA_CODIGO.md no coincide con el generado: correr herramientas/mapa_codigo.py")
            sys.exit(1)
        print("MAPA_CODIGO al día")
        return
    with open(SALIDA, "w", encoding="utf-8") as f:
        f.write(texto)
    print("escrito %s (%d líneas)" % (os.path.relpath(SALIDA, RAIZ), texto.count("\n")))


if __name__ == "__main__":
    main()
