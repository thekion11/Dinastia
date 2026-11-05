#!/bin/bash
# MATRIZ DEL BANCO AUTOMÁTICO DE RENDIMIENTO (5-11-2026): corre `pruebas/benchmark/benchmark.tscn` para cada combinación
# escenario × calidad de UN perfil de hardware y deja un CSV por combinación (perf_<escenario>_<calidad>_<perfil>.csv) más el
# resumen y diagnóstico (resumen_<perfil>.md). Sin pedir nada: todo por variables o argumentos.
#
#   herramientas/benchmark_matriz.sh <perfil> [carpeta_de_salida]
#
# Perfiles de hardware (se IMITAN limitando núcleos, hilos del renderizador y resolución; no son GPUs reales):
#   headless   sin gráfica ni ventana (--headless): CPU, motor de los 22, física y memoria. 4 núcleos.
#   modesto    Pentium/Intel HD con 4 GB: 2 núcleos, OpenGL por software (llvmpipe) a 1366x768, pantalla virtual (xvfb).
#   medio      portátil normal: 4 núcleos, OpenGL por software a 1920x1080.
#   movil      teléfono de gama baja: 2 núcleos, OpenGL por software a 1280x576 (pantalla 20:9 reducida).
#   vulkan     Forward+ por software (lavapipe) a 1920x1080, 4 núcleos. Si el equipo no tiene Vulkan se OMITE (no se mide OpenGL
#              haciéndolo pasar por Vulkan).
# Variables: ESCENARIOS ("partido ciudad menu gestion museo minijuego"), CALIDADES ("minima media alta ultra"),
#   DURACION_PARTIDO (60), DURACION_RESTO (20), RAPIDO=1 (8 s y 5 s: para comprobar que todo corre), LIMITE (240 s de pared por ejecución;
#   en llvmpipe los fotogramas son lentos: sube con LIMITE=600), SEMILLA (4711), LIGERO=1 («Partido ligero» encendido), GODOT (binario).
cd "$(dirname "$0")/.." || exit 1
PERFIL=${1:-headless}
SAL=${2:-/tmp/benchmark_$PERFIL}
GODOT=${GODOT:-godot}
ESC=${ESCENARIOS:-"partido ciudad menu gestion museo minijuego"}
CAL=${CALIDADES:-"minima media alta ultra"}
DP=${DURACION_PARTIDO:-60}; DR=${DURACION_RESTO:-20}
if [[ -n "$RAPIDO" ]]; then DP=8; DR=5; fi
LIM=${LIMITE:-240}
mkdir -p "$SAL"
export DINASTIA_SIN_AUTO=1   # que el juego no elija solo la calidad ni escriba user://grafica.cfg
case "$PERFIL" in
  headless) NUC=0-3; NT=4; RES=; DRV=headless ;;
  modesto)  NUC=0,1; NT=2; RES=1366x768; DRV=opengl3 ;;
  medio)    NUC=0-3; NT=4; RES=1920x1080; DRV=opengl3 ;;
  movil)    NUC=0,1; NT=2; RES=1280x576; DRV=opengl3 ;;
  vulkan)   NUC=0-3; NT=4; RES=1920x1080; DRV=vulkan ;;
  *) echo "Perfil desconocido: $PERFIL (headless, modesto, medio, movil, vulkan)"; exit 2 ;;
esac
export LP_NUM_THREADS=$NT
# Fijar núcleos con taskset; si el equipo tiene menos núcleos de los pedidos (p. ej. un runner de 2), se corre sin fijar y se avisa.
TS=(taskset -c "$NUC")
if ! taskset -c "$NUC" true 2>/dev/null; then TS=(); echo "AVISO: este equipo no tiene los núcleos $NUC; el perfil $PERFIL corre sin limitar la CPU"; fi
if [[ "$DRV" != headless ]] && ! command -v xvfb-run >/dev/null; then echo "Falta xvfb-run para el perfil $PERFIL"; exit 2; fi
FALLOS=0
for e in $ESC; do
  for c in $CAL; do
    D=$DR; if [[ "$e" == partido ]]; then D=$DP; fi
    CSV="$SAL/perf_${e}_${c}_${PERFIL}.csv"
    LOG="$SAL/log_${e}_${c}_${PERFIL}.txt"
    ARGS=(--path . res://pruebas/benchmark/benchmark.tscn -- --escenario="$e" --calidad="$c" --duracion="$D" --salida="$CSV" --limite="$LIM" --semilla="${SEMILLA:-4711}" --ligero="${LIGERO:-0}")
    TOPE=$((D + LIM + 60))
    if [[ "$DRV" == headless ]]; then
      timeout $TOPE "${TS[@]}" "$GODOT" --headless "${ARGS[@]}" > "$LOG" 2>&1
    else
      timeout $TOPE xvfb-run -a -s "-screen 0 ${RES}x24" "${TS[@]}" "$GODOT" --rendering-driver "$DRV" --resolution "$RES" "${ARGS[@]}" > "$LOG" 2>&1
    fi
    COD=$?
    METODO=$(grep -a -o "render=[a-z_]*" "$LOG" | head -1)
    # Vulkan que cae a OpenGL: no es la medida pedida, se descarta.
    if [[ "$PERFIL" == vulkan && "$METODO" != "render=forward_plus" ]]; then
      echo "OMITIDO $e/$c: este equipo no tiene Vulkan ($METODO)"; rm -f "$CSV"; continue
    fi
    FILAS=$(( $(wc -l < "$CSV" 2>/dev/null || echo 1) - 1 ))
    ERR=$(grep -a -c "SCRIPT ERROR" "$LOG")
    if [[ $COD -ne 0 || $ERR -gt 0 ]]; then FALLOS=$((FALLOS + 1)); ESTADO="FALLO (código $COD, $ERR SCRIPT ERROR)"; else ESTADO="ok"; fi
    echo "[$PERFIL] $e/$c: $FILAS filas, $METODO · $ESTADO"
  done
done
python3 herramientas/benchmark_resumen.py "$SAL" -o "$SAL/resumen_$PERFIL.md" > /dev/null
echo "[$PERFIL] resumen en $SAL/resumen_$PERFIL.md · $FALLOS ejecuciones con fallo"
[[ $FALLOS -eq 0 ]]
