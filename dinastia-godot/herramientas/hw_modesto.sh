#!/bin/bash
# Imita un equipo modesto (Pentium/2 núcleos, 4 GB, gráfica integrada) en este contenedor.
#   herramientas/hw_modesto.sh res://pruebas/medir_partido.tscn [-- medio|alto|ultra]
# Método (docs/04_auditorias/rendimiento_120fps.md):
#  - CPU: taskset a 2 núcleos (HW_NUCLEOS, por defecto 0,1) y LP_NUM_THREADS=2 (hilos de llvmpipe).
#  - RAM: cgroup v1 de memoria a 4 GB (HW_RAM_MB) si /sys/fs/cgroup/memory es escribible; si no, solo se mide el pico (VmHWM).
#  - Gráfica: Vulkan por software (lavapipe) o GL (llvmpipe) a 1366x768 (HW_RES). NO es una Intel UHD: sirve para
#    comparar versiones del código (llamadas de dibujo, triángulos, ms de CPU), no para certificar FPS absolutos.
cd "$(dirname "$0")/.." || exit 1
ESC=${1:-res://pruebas/medir_partido.tscn}; shift
NUC=${HW_NUCLEOS:-0,1}; RAM=${HW_RAM_MB:-4096}; RES=${HW_RES:-1366x768}; DRV=${HW_DRIVER:-vulkan}
export LP_NUM_THREADS=$(echo "$NUC" | tr ',' '\n' | wc -l)
G=/sys/fs/cgroup/memory/dinastia_hw
if mkdir -p $G 2>/dev/null && echo $((RAM*1024*1024)) > $G/memory.limit_in_bytes 2>/dev/null; then
  echo $$ > $G/cgroup.procs; echo "[hw] cgroup memoria ${RAM} MB"
else echo "[hw] sin cgroup de memoria (solo se informa el pico)"; fi
xvfb-run -a -s "-screen 0 1920x1080x24" stdbuf -oL -eL taskset -c "$NUC" godot --path . --rendering-driver "$DRV" --resolution "$RES" "$ESC" "$@" 2>&1 &
PID=$!; PICO=0; sleep 3
while kill -0 $PID 2>/dev/null; do
  for q in $(pgrep -f "godot --path"); do
    H=$(awk '/VmHWM/{print $2}' /proc/$q/status 2>/dev/null); [[ -n "$H" ]] && [[ "$H" -gt "$PICO" ]] && PICO=$H
  done
  sleep 1
done
wait $PID 2>/dev/null
echo "[hw] pico de RAM del proceso: $((PICO/1024)) MB"
