#!/bin/bash
# Lanza el banco de pruebas con vigilancia de arranque (etapa 3, 8-10-2026).
# A veces Godot se queda colgado al iniciar, antes de imprimir nada: si a los
# 90 s el registro no avanzó, se mata y se reintenta (hasta 3 veces). El
# primer intento va con --verbose para poder ver dónde se cuelga.
#   herramientas/banco.sh [registro]   (por defecto /tmp/banco.txt)
cd "$(dirname "$0")/.." || exit 1
LOG="${1:-/tmp/banco.txt}"
for intento in 1 2 3; do
  extra=""
  [ "$intento" = "1" ] && extra="--verbose"
  timeout 1200 godot --headless $extra --path . res://pruebas/banco.tscn > "$LOG" 2>&1 &
  pid=$!
  arranco=0
  for s in $(seq 1 90); do
    sleep 1
    if grep -q "BANCO DE PRUEBAS" "$LOG" 2>/dev/null; then arranco=1; break; fi
    kill -0 $pid 2>/dev/null || break
  done
  if [ "$arranco" = "0" ] && kill -0 $pid 2>/dev/null; then
    echo "intento $intento: colgado al arrancar; últimas líneas:"
    tail -5 "$LOG"
    cp "$LOG" "$LOG.colgado$intento"
    kill $pid 2>/dev/null; sleep 1; kill -9 $pid 2>/dev/null
    continue
  fi
  wait $pid
  grep -E "===== FIN|FALLO" "$LOG" | tail -5
  exit 0
done
echo "el banco no arrancó en 3 intentos"
exit 1
