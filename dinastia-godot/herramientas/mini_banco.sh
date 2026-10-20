#!/bin/bash
# MINI BANCO (20-10-2026): corre solo un grupo de pruebas del banco (GRUPOS en
# pruebas/banco.gd) o una sección, en un proceso y en segundos.
#   herramientas/mini_banco.sh partido      → el grupo «partido»
#   herramientas/mini_banco.sh _probar_x    → solo esa sección
#   herramientas/mini_banco.sh              → lista los grupos
# Código 0 = «FIN. 0 fallos» y sin «SCRIPT ERROR» ni «SHADER ERROR». Antes de SUBIR, el banco
# entero (herramientas/banco.sh) sigue siendo obligatorio.
cd "$(dirname "$0")/.." || exit 1
if [ -z "$1" ]; then
  echo "Grupos:"; sed -n '/^const GRUPOS/,/^}/p' pruebas/banco.gd | grep -o '^	"[a-z_]*"' | tr -d '\t"' | sed 's/^/  /'
  exit 0
fi
LOG="${2:-/tmp/mini_banco.txt}"
if [[ "$1" == _probar_* ]]; then VAR=BANCO_SOLO; else VAR=BANCO_GRUPO; fi
INICIO=$(date +%s)
env $VAR="$1" timeout 900 godot --headless --path . res://pruebas/banco.tscn > "$LOG" 2>&1
sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -a "FALLO\|SCRIPT ERROR\|SHADER ERROR" | head -20
FIN=$(sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -a "===== FIN" | tail -1)
echo "$1 · $(( $(date +%s) - INICIO )) s · ${FIN:-SIN FIN (¿colgado o error de sintaxis?)}"
if echo "$FIN" | grep -q "FIN. 0 fallos" && ! grep -aq "SCRIPT ERROR\|SHADER ERROR" "$LOG"; then exit 0; fi
exit 1
