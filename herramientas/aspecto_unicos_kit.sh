#!/bin/bash
# Repite `aspecto_unicos_kit.py` hasta que ningún uniforme se repita dentro de una liga (lee las firmas con Godot, ~15 s por vuelta).
cd "$(dirname "$0")/.." || exit 1
for i in 1 2 3; do
  python3 herramientas/aspecto_clubes.py > /dev/null 2>&1
  (cd dinastia-godot && REAL=1 timeout 300 godot --headless --path . res://pruebas/herramienta_firmas_kit.tscn 2>&1 | grep -a "^KIT|" > /tmp/firmas_kit.txt)
  SAL=$(python3 herramientas/aspecto_unicos_kit.py /tmp/firmas_kit.txt)
  echo "vuelta $i: $SAL"
  echo "$SAL" | grep -q "(0 nuevas" && break
done
python3 herramientas/aspecto_clubes.py 2>&1 | tail -1
(cd dinastia-godot && python3 ../herramientas/base_ficticia.py 2>&1 | tail -1)
