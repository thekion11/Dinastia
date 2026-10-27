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
# 2b. Las auditorías de datos y de clubes (base ficticia y real; ~9 s cada una; catálogo M-413, 27-10-2026)
pasa "auditoría de datos" "godot --headless --path . res://pruebas/auditoria_datos.tscn" "0 hallazgos"
pasa "auditoría de clubes" "godot --headless --path . res://pruebas/auditoria_clubes.tscn" "FIN. 0 fallos"
# 2c. Las partidas guardadas de versiones viejas siguen abriendo (1094, 27-10)
pasa "partidas viejas abren" "godot --headless --path . res://pruebas/ideas/sav_fosiles.tscn" "FIN. 0 fallos"
# 3. Colisiones del club (paredes, muebles, gente, barreras invisibles)
pasa "colisiones del club" "godot --headless --path . res://pruebas/prueba_colisiones_club.tscn" "FIN. 0 fallos"
# 4. Partido con el motor real (acta = césped) y control del equipo
pasa "partido con motor real" "godot --headless --path . res://pruebas/prueba_partido_motor.tscn" "0 fallos"
pasa "control del equipo" "godot --headless --path . res://pruebas/prueba_control_equipo.tscn" "0 fallos"
# 5. Modos de juego y menú de la ciudad a pie
pasa "modos de juego" "godot --headless --path . res://pruebas/prueba_modos.tscn" "0 fallos"
pasa "menú ciudad a pie" "godot --headless --path . res://pruebas/prueba_menu_ciudad_pie.tscn" "0 fallos"
# 5b. Pruebas viejas que nadie lanzaba y siguen pasando (reutilizadas el 27-10, orden 14 del dueño)
pasa "contador de FPS" "godot --headless --path . res://pruebas/prueba_contador_fps.tscn" "FIN CONTADOR FPS. 0 fallos"
pasa "dominadas" "godot --headless --path . res://pruebas/prueba_dominadas.tscn" "DOMINADAS: 0 fallos"
pasa "minijuegos nuevos" "godot --headless --path . res://pruebas/prueba_minijuegos_nuevos.tscn" "FIN MINIJUEGOS NUEVOS. 0 fallos"
pasa "motor jugable (unidad)" "godot --headless --path . res://pruebas/prueba_motor_jugable.tscn" "FIN MOTOR. 0 fallos"
# 5c. Movimiento suave y vida de la ciudad (27-10, orden del líder: que el tirón de los vehículos no vuelva a romperse sin que se note; ~1 min)
pasa "tráfico, metro y bus suaves" "godot --headless --path . res://pruebas/ideas/pmov_suavidad_trafico.tscn" "FIN. 0 fallos"
pasa "tráfico: derecha y adelantar" "godot --headless --path . res://pruebas/ideas/tra_adelantar_y_derecha.tscn" "FIN. 0 fallos"
pasa "emergencias y sirenas" "godot --headless --path . res://pruebas/ideas/emerg_servicios.tscn" "FIN. 0 fallos"
pasa "el tráfico cede a las sirenas" "godot --headless --path . res://pruebas/ideas/emerg_cede_paso.tscn" "FIN. 0 fallos"
pasa "estación y trenes" "godot --headless --path . res://pruebas/ideas/tre_estacion.tscn" "FIN. 0 fallos"
pasa "teleférico" "godot --headless --path . res://pruebas/ideas/tre_teleferico.tscn" "FIN. 0 fallos"
pasa "aspecto de los clubes" "godot --headless --path . res://pruebas/ideas/asp_clubes.tscn" "FIN. 0 fallos"
pasa "trofeos por competición" "godot --headless --path . res://pruebas/ideas/tro_recetas.tscn" "FIN. 0 fallos"
pasa "palmarés en la historia del club" "godot --headless --path . res://pruebas/ideas/pal_clubes.tscn" "FIN. 0 fallos"
# 6. Todas las pantallas y botones de la interfaz (lento)
if [ "$1" = "todo" ]; then
  # Balance del mundo a largo plazo (10 temporadas x 3 semillas, ~3,5 min) y rendimiento en 20 (~1,5 min)
  pasa "balance en 10 temporadas" "godot --headless --path . res://pruebas/ideas/eq_diez_temporadas.tscn" "FIN. 0 fallos"
  pasa "rendimiento en 20 temporadas" "EQ_MODO=rendimiento godot --headless --path . res://pruebas/ideas/eq_diez_temporadas.tscn" "FIN. 0 fallos"
  # El motor del partido nota la calidad y la pizarra (sonda_motor_dt con umbrales, M-414; 6 partidos por escenario, ~7 min)
  pasa "motor: el mejor gana al peor" "ESCENARIO=calidad N=6 godot --headless --path . res://pruebas/sonda_motor_dt.tscn" "UMBRALES: 0 fallos"
  pasa "motor: la pizarra se nota" "ESCENARIO=tactica N=6 godot --headless --path . res://pruebas/sonda_motor_dt.tscn" "UMBRALES: 0 fallos"
  # M-467: todas las pantallas en alemán; los textos se encogen (TextoQueCabe) y no quedan más de 4 cortados (~3 min)
  pasa "textos largos en alemán" "RECORRIDO_IDIOMA=de RECORRIDO_LARGOS=/tmp/largos_de.json RECORRIDO_CORTADOS_MAX=4 godot --headless --path . res://pruebas/recorrido_pantallas.tscn" "FIN LARGOS. 0 fallos"
  # M-420: los presets públicos (paquete exportado) no llevan archivos ni nombres de lo real (~3 min)
  pasa "builds públicos sin datos reales" "python3 herramientas/revisar_build_publico.py" "FIN BUILD PÚBLICO. 0 fallos"
  pasa "ceremonia de carrera" "godot --headless --path . res://pruebas/prueba_carrera_ceremonia.tscn" "FIN. 0 fallos"
  pasa "práctica" "godot --headless --path . res://pruebas/prueba_practica.tscn" "FIN PRÁCTICA. 0 fallos"
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
