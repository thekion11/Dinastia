#!/usr/bin/env python3
"""Saca de `docs/03_estado/ESTADO_MEJORAS.md` las ideas POSTERGADAS o INCOMPLETAS (PARCIAL, PENDIENTE, 🔒 DUEÑO, SIN VERIFICAR)
y las vuelca en `docs/03_estado/ideas_pendientes.csv`, con la fase del plan a la que tocan (docs/01_metodo/METODO.md).

  python3 herramientas/tablero_ideas.py          # reescribe el CSV y muestra el resumen

El registro de origen se actualiza a mano al cerrar una idea; este script solo lo lee.
"""
import csv
import re
from collections import Counter

ORIGEN = "docs/03_estado/ESTADO_MEJORAS.md"
SALIDA = "docs/03_estado/ideas_pendientes.csv"
## sección del registro -> (nombre, fase del plan)
SECCIONES = {
    "A": ("Estadios y entorno", "F5 club ampliado / pulido"),
    "B": ("Público y ambiente", "F6 pulido"),
    "C": ("Camisetas, escudos y marcas", "F6 pulido"),
    "D": ("Jugadores, caras, cuerpos y animaciones", "F6 pulido"),
    "E": ("Partido: física, IA, controles, cámara", "F6 pulido (motor)"),
    "F": ("Ciudad, vehículos, metro, interiores", "F3 vida en 3D"),
    "G": ("Gestión del club", "F4 personas"),
    "H": ("Carrera de Jugador", "F3 vida en 3D"),
    "I": ("Interfaz, menús, accesibilidad", "F1 entrada al juego"),
    "J": ("Audio y música", "dueño"),
    "K": ("Idiomas y textos", "F6 pulido (traducciones)"),
    "L": ("Rendimiento y optimización", "F6 pulido (rendimiento)"),
    "M": ("Datos y contenido", "F4 personas"),
    "N": ("Código y arquitectura", "F0 cimientos"),
    "O": ("Pruebas y herramientas", "F0 cimientos"),
    "P": ("Repositorio, build y legal", "dueño"),
    "Q": ("Móvil, táctil y mando", "F1 entrada al juego"),
    "R": ("Pasada 3 (mezcla)", "F6 pulido"),
}


def main():
    sec = ""
    filas = []
    for linea in open(ORIGEN, encoding="utf-8"):
        m = re.match(r"^### ([A-R])\. ", linea)
        if m:
            sec = m.group(1)
            continue
        m = re.match(r"^\| (M-\d+) \| (P\d) \| (.*?) \| (HECHO|PARCIAL|PENDIENTE|🔒 DUEÑO|SIN VERIFICAR)[^|]* \| (.*) \|\s*$", linea)
        if m and sec:
            ident, prio, punto, estado, nota = m.groups()
            if estado == "HECHO":
                continue
            nombre, fase = SECCIONES.get(sec, ("?", "?"))
            if estado.startswith("🔒"):
                fase = "dueño"
            filas.append([ident, sec, nombre, prio, estado, punto.strip(), nota.strip().replace("\n", " ")[:220], fase])
    filas.sort(key=lambda f: (f[3], f[1], f[0]))
    with open(SALIDA, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["id", "seccion", "area", "prioridad", "estado", "idea", "lo_que_falta", "fase"])
        w.writerows(filas)
    print(f"{len(filas)} ideas abiertas -> {SALIDA}")
    print("por estado:", dict(Counter(f[4] for f in filas)))
    print("por prioridad:", dict(sorted(Counter(f[3] for f in filas).items())))
    print("por fase:", dict(Counter(f[7] for f in filas).most_common()))


if __name__ == "__main__":
    main()
