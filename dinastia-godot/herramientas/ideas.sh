#!/bin/bash
# PRUEBAS DE IDEAS (24-10-2026): cada pruebas/ideas/<nombre>.tscn es independiente del banco.
#   herramientas/ideas.sh <nombre>   → una prueba (sin la extensión)
#   herramientas/ideas.sh todo       → todas las que no empiezan por «_», una tras otra
# Toma el candado /tmp/godot.lock (otros procesos comparten la máquina). Código 0 = todas en «FIN. 0 fallos»
# y sin «SCRIPT ERROR»/«SHADER ERROR».
cd "$(dirname "$0")/.." || exit 1
if [ -z "$1" ]; then echo "uso: ideas.sh <nombre>|todo"; ls pruebas/ideas/*.tscn | grep -v '/_' | xargs -n1 basename | sed 's/.tscn//'; exit 0; fi
if [ "$1" = "todo" ]; then LISTA=$(ls pruebas/ideas/*.tscn | grep -v '/_' | xargs -n1 basename | sed 's/.tscn//'); else LISTA="$1"; fi
CODIGO=0
for N in $LISTA; do
  LOG="/tmp/ideas_$N.txt"
  INICIO=$(date +%s)
  # Corre bajo el candado y vigila el registro: si el script no carga (error de sintaxis) lo mata enseguida.
  flock /tmp/godot.lock bash -c '
    godot --headless --path . "res://pruebas/ideas/'"$N"'.tscn" > "'"$LOG"'" 2>&1 &
    G=$!
    for i in $(seq 1 300); do
      sleep 1
      kill -0 $G 2>/dev/null || break
      if grep -aq "Failed to load script\|Parse Error" "'"$LOG"'"; then kill $G 2>/dev/null; break; fi
    done
    kill $G 2>/dev/null; wait $G 2>/dev/null'
  sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -a "FALLO\|SCRIPT ERROR\|SHADER ERROR" | head -20
  FIN=$(sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -a "===== FIN" | tail -1)
  echo "$N · $(( $(date +%s) - INICIO )) s · ${FIN:-SIN FIN (¿error de sintaxis o cuelgue? mira $LOG)}"
  if ! echo "$FIN" | grep -q "FIN. 0 fallos" || grep -aq "SCRIPT ERROR\|SHADER ERROR" "$LOG"; then CODIGO=1; fi
done
exit $CODIGO
