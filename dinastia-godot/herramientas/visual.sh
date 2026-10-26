#!/bin/bash
# PRUEBAS VISUALES (26-10-2026): 20 pantallas clave contra sus referencias (ver pruebas/visual/visual.gd).
#   herramientas/visual.sh              → compara; código 0 = «FIN. 0 fallos»
#   herramientas/visual.sh referencias  → rehace las referencias (después de un cambio visual QUERIDO)
# Necesita Vulkan (lavapipe sin GPU, como captura.sh). Las que cambian quedan en /tmp/visual/.
cd "$(dirname "$0")/.." || exit 1
LOG=/tmp/visual_registro.txt
[ "$1" = "referencias" ] && export VISUAL=referencias
# capturas [idioma] [resolución]: solo guarda las 20 en /tmp/visual/capturas/ (revisión a ojo).
[ "$1" = "capturas" ] && export VISUAL=capturas VISUAL_IDIOMA="${2:-es}" RES_VISUAL="${3:-1280x720}"
RESOLUCION=${RES_VISUAL:-1280x720} "$PWD/herramientas/turno.sh" herramientas/captura.sh res://pruebas/visual/visual.tscn > "$LOG" 2>&1
sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -a "CAPTURA\|REFERENCIA\|CAMBIÓ\|igual \|Cambiaron\|Referencias\|AVISO\|SCRIPT ERROR\|===== FIN"
sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -aq "FIN. 0 fallos" && ! grep -aq "SCRIPT ERROR" "$LOG"
