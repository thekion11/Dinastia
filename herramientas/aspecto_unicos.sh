#!/bin/bash
# Repite `aspecto_unicos.py` hasta que ninguna firma de escudo se repita (usa Godot para leer las firmas reales; ~1 min por vuelta).
cd "$(dirname "$0")/.." || exit 1
for i in 1 2 3 4; do
  (cd dinastia-godot && python3 ../herramientas/base_ficticia.py > /dev/null 2>&1)
  (cd dinastia-godot && timeout 300 godot --headless --path . res://pruebas/herramienta_firmas_escudos.tscn 2>&1 | grep -a "^SIG|" > /tmp/firmas_base.txt)
  (cd dinastia-godot && REAL=1 timeout 300 godot --headless --path . res://pruebas/herramienta_firmas_escudos.tscn 2>&1 | grep -a "^SIG|" > /tmp/firmas_real.txt)
  SAL=$(python3 herramientas/aspecto_unicos.py /tmp/firmas_base.txt /tmp/firmas_real.txt)
  echo "vuelta $i: $SAL"
  echo "$SAL" | grep -q "(0 nuevos" && break
done
(cd dinastia-godot && python3 ../herramientas/base_ficticia.py 2>&1 | tail -1)
