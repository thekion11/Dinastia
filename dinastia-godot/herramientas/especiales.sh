#!/bin/bash
# PRUEBAS ESPECIALES (23-10-2026): lo que el banco NO ve. Cada una es una escena o un script aparte.
#   herramientas/especiales.sh            → las rápidas (≈2 min)
#   herramientas/especiales.sh todo       → con el recorrido de todas las pantallas (+4 min)
# Salida: una línea por prueba (OK / FALLO) y código 0 si todas pasan.
cd "$(dirname "$0")/.." || exit 1
FALLOS=0
LOG=$(mktemp)

pasa() {  # nombre, comando, patrón de éxito
  local t0=$(date +%s)
  timeout 600 bash -c "$2" > "$LOG" 2>&1
  local seg=$(( $(date +%s) - t0 ))
  if grep -q "SCRIPT ERROR" "$LOG" || ! grep -qE "$3" "$LOG"; then
    FALLOS=$((FALLOS + 1)); printf 'FALLO  %-34s %3d s\n' "$1" "$seg"; grep -E "FALLO|SCRIPT ERROR" "$LOG" | head -3
  else
    printf 'OK     %-34s %3d s\n' "$1" "$seg"
  fi
}

# 1. Tamaño del código (norma de 450 líneas)
python3 ../herramientas/revisar_lineas.py --todos > "$LOG" 2>&1
if grep -q "pasan de 450 líneas: 0" "$LOG"; then echo "OK     norma de 450 líneas"; else FALLOS=$((FALLOS + 1)); echo "FALLO  norma de 450 líneas"; head -5 "$LOG"; fi
# 2. Todos los scripts compilan (el banco solo ve los que toca)
pasa "todos los scripts compilan" "godot --headless --path . --script res://pruebas/comprobar_scripts.gd" "FIN. 0 fallos"
# 3. Colisiones del club (paredes, muebles, gente, barreras invisibles)
pasa "colisiones del club" "godot --headless --path . res://pruebas/prueba_colisiones_club.tscn" "FIN. 0 fallos"
# 4. Partido con el motor real (acta = césped) y control del equipo
pasa "partido con motor real" "godot --headless --path . res://pruebas/prueba_partido_motor.tscn" "0 fallos"
pasa "control del equipo" "godot --headless --path . res://pruebas/prueba_control_equipo.tscn" "0 fallos"
# 5. Modos de juego y menú de la ciudad a pie
pasa "modos de juego" "godot --headless --path . res://pruebas/prueba_modos.tscn" "0 fallos"
pasa "menú ciudad a pie" "godot --headless --path . res://pruebas/prueba_menu_ciudad_pie.tscn" "0 fallos"
# 6. Todas las pantallas y botones de la interfaz (lento)
if [ "$1" = "todo" ]; then
  pasa "recorrido de todas las pantallas" "godot --headless --path . res://pruebas/recorrido_pantallas.tscn" "RECORRIDO: [0-9]+ pantallas"
fi
rm -f "$LOG"
[ "$FALLOS" -eq 0 ] && echo "ESPECIALES: todo en orden" || echo "ESPECIALES: $FALLOS con fallos"
exit $([ "$FALLOS" -eq 0 ] && echo 0 || echo 1)
