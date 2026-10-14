#!/bin/bash
# Lanza el banco de pruebas con vigilancia (etapa 3, 8-10-2026; ampliado 14-10).
#   herramientas/banco.sh [registro]   (por defecto /tmp/banco.txt)
#
# Qué vigila:
# - Error de sintaxis en un script de pruebas: Godot lo imprime y se queda
#   esperando para siempre. Se corta en el acto y se muestra el error.
# - Cuelgue al arrancar (pasa a veces, antes de imprimir nada): si a los 90 s
#   no salió el título, se mata y se reintenta (hasta 3 veces). El primer
#   intento va con --verbose para poder ver dónde se cuelga.
# - Cuelgue a mitad: si el registro no crece en SIN_AVANCE segundos, se corta.
# - «SCRIPT ERROR» durante la ejecución (errores que _comprobar no ve).
#
# Código de salida: 0 = «FIN. 0 fallos» y sin errores de script;
# 1 = fallos o errores de script; 2 = error de sintaxis; 3 = colgado o sin FIN.
cd "$(dirname "$0")/.." || exit 1
LOG="${1:-/tmp/banco.txt}"
SIN_AVANCE="${SIN_AVANCE:-240}"

limpio() { sed 's/\x1b\[[0-9;]*m//g' "$LOG" 2>/dev/null; }
matar() { kill "$1" 2>/dev/null; sleep 1; kill -9 "$1" 2>/dev/null; }

for intento in 1 2 3; do
  extra=""
  [ "$intento" = "1" ] && extra="--verbose"
  timeout 1200 godot --headless $extra --path . res://pruebas/banco.tscn > "$LOG" 2>&1 &
  pid=$!
  arranco=0
  tam=0
  quieto=0
  while kill -0 $pid 2>/dev/null; do
    sleep 1
    if limpio | grep -qE "Parse Error|Failed to load script \"res://pruebas/"; then
      matar $pid
      echo "ERROR DE SINTAXIS (el banco no puede arrancar):"
      limpio | grep -E -A1 "Parse Error|Failed to load script" | head -8
      exit 2
    fi
    if [ "$arranco" = "0" ]; then
      if grep -q "BANCO DE PRUEBAS" "$LOG" 2>/dev/null; then
        arranco=1
      else
        quieto=$((quieto + 1))
        [ "$quieto" -ge 90 ] && break
        continue
      fi
    fi
    nuevo=$(stat -c %s "$LOG" 2>/dev/null || echo 0)
    if [ "$nuevo" = "$tam" ]; then
      quieto=$((quieto + 1))
      if [ "$quieto" -ge "$SIN_AVANCE" ]; then
        matar $pid
        echo "COLGADO: el registro no avanzó en $SIN_AVANCE s; últimas líneas:"
        limpio | grep -v '^\s*$' | tail -8
        exit 3
      fi
    else
      tam=$nuevo
      quieto=0
    fi
  done
  if [ "$arranco" = "0" ] && kill -0 $pid 2>/dev/null; then
    echo "intento $intento: colgado al arrancar; últimas líneas:"
    tail -5 "$LOG"
    cp "$LOG" "$LOG.colgado$intento"
    matar $pid
    continue
  fi
  wait $pid
  limpio | grep -E "===== FIN|FALLO|^  - " | tail -12
  errores=$(limpio | grep -c "^SCRIPT ERROR")
  if [ "$errores" -gt 0 ]; then
    echo "AVISO: $errores «SCRIPT ERROR» durante el banco:"
    limpio | grep -A1 "^SCRIPT ERROR" | head -10
  fi
  if ! limpio | grep -q "===== FIN"; then
    echo "SIN FIN: el banco se cortó antes de terminar; últimas líneas:"
    limpio | grep -v '^\s*$' | tail -8
    exit 3
  fi
  limpio | grep -q "===== FIN. 0 fallos" && [ "$errores" = "0" ] && exit 0
  exit 1
done
echo "el banco no arrancó en 3 intentos"
exit 3
