#!/bin/bash
# PRUEBAS ESPECIALES (23-10-2026): lo que el banco NO ve. Cada una es una escena o un script aparte.
#   herramientas/especiales.sh            → las rápidas (≈2 min)
#   herramientas/especiales.sh todo       → con el recorrido de todas las pantallas y el balance a largo plazo (+9 min)
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
# 5b. Las texturas de ruido en segundo plano son las de NoiseTexture2D, byte a byte (30-10)
pasa "ruidos en segundo plano" "godot --headless --path . res://pruebas/probar_ruidos_fondo.tscn" "FIN. 0 fallos"
pasa "textura del balón" "godot --headless --path . --script res://pruebas/probar_balon_textura.gd" "FIN. 0 fallos"
# 6. Todas las pantallas y botones de la interfaz (lento)
if [ "$1" = "todo" ]; then
  # Balance del mundo a largo plazo (10 temporadas x 3 semillas, ~3,5 min) y rendimiento en 20 (~1,5 min)
  pasa "balance en 10 temporadas" "godot --headless --path . res://pruebas/ideas/eq_diez_temporadas.tscn" "FIN. 0 fallos"
  pasa "rendimiento en 20 temporadas" "EQ_MODO=rendimiento godot --headless --path . res://pruebas/ideas/eq_diez_temporadas.tscn" "FIN. 0 fallos"
  pasa "recorrido de todas las pantallas" "godot --headless --path . res://pruebas/recorrido_pantallas.tscn" "RECORRIDO: [0-9]+ pantallas"
  # 20 pantallas clave contra sus referencias (pruebas/visual/visual.gd; ~1,5 min). Necesita Vulkan
  # (lavapipe sin GPU); sin él se salta. Tras un cambio visual QUERIDO: herramientas/visual.sh referencias.
  if ls /usr/share/vulkan/icd.d/*.json > /dev/null 2>&1; then
    pasa "pruebas visuales (20 pantallas)" "RESOLUCION=1280x720 herramientas/captura.sh res://pruebas/visual/visual.tscn" "FIN. 0 fallos"
  else
    echo "SALTADA pruebas visuales (sin Vulkan: apt-get install -y mesa-vulkan-drivers)"
  fi
fi
rm -f "$LOG"
[ "$FALLOS" -eq 0 ] && echo "ESPECIALES: todo en orden" || echo "ESPECIALES: $FALLOS con fallos"
exit $([ "$FALLOS" -eq 0 ] && echo 0 || echo 1)
