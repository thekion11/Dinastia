#!/bin/bash
# TURNO DE GODOT con 3 plazas (antes: 1 sola, /tmp/godot.lock, y la cola llegaba a 20 procesos esperando 6 min).
#   herramientas/turno.sh <comando...>   (también en /tmp/aud/turno.sh en la sesión principal)
# Toma la primera plaza libre de /tmp/godot_plaza.{1,2,3}; si las tres están ocupadas espera a cualquiera.
while true; do
  for i in 1 2 3; do
    exec 9>/tmp/godot_plaza.$i
    if flock -n 9; then "$@"; R=$?; flock -u 9; exit $R; fi
  done
  sleep 2
done
