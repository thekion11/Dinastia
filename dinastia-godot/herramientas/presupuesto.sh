#!/bin/bash
# Presupuesto de rendimiento del recorrido completo (menú, estadio con cámara de TV, ciudad): corre el benchmark corto
# (`-- --medir`, nucleo/medicion.gd) con límites de equipo modesto (hw_modesto.sh, Compatibilidad) y lo compara con
# herramientas/presupuesto_benchmark.json. ~6 min. Sale con 1 si algún tope se pasa. «FIN. 0 fallos» al final.
cd "$(dirname "$0")/.." || exit 1
DIR="${XDG_DATA_HOME:-$HOME/.local/share}/godot/app_userdata/DINASTIA/mediciones"
SALIDA=$(mktemp)
touch "$SALIDA.marca"
HW_DRIVER=opengl3 HW_NUCLEOS=${HW_NUCLEOS:-0,1,2,3} HW_RES=${HW_RES:-640x360} HW_RAM_MB=${HW_RAM_MB:-8192} \
  herramientas/hw_modesto.sh res://escenas/inicio.tscn -- --medir > "$SALIDA" 2>&1
JSON=$(find "$DIR" -name 'medicion_*.json' -newer "$SALIDA.marca" 2>/dev/null | sort | tail -1)
PICO=$(grep -o 'pico de RAM del proceso: [0-9]*' "$SALIDA" | grep -o '[0-9]*$')
rm -f "$SALIDA" "$SALIDA.marca"
[[ -z "$JSON" ]] && { echo "FALLO: el benchmark no dejó informe"; exit 1; }
python3 herramientas/presupuesto_benchmark.py "$JSON" "${PICO:-0}"
