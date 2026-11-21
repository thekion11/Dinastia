#!/bin/bash
# (20-11) Carga TODOS los .gd del proyecto y lista los que no compilan: "COMPILADOS N, FALLAN 0" = bien. Tarda ~1 min.
# Úsalo tras renombrar o partir funciones: el banco no compila todo y un identificador mal renombrado solo falla al cargar ese archivo.
cd "$(dirname "$0")/.."
export XDG_DATA_HOME=$(mktemp -d)
timeout 600 godot --headless --path . res://herramientas/compilar_todo.tscn 2>&1 | grep -E "COMPILADOS|MALO"
