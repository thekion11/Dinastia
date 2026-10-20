#!/bin/bash
# Lanza el banco de pruebas EN PARALELO y con vigilancia (8-10-2026; 15-10).
#   herramientas/banco.sh [registro]   (por defecto /tmp/banco.txt)
#   BANCO_PARTES=1 herramientas/banco.sh   → todo en un solo proceso (como antes)
#
# Reparto: las 103 secciones de `pruebas/banco.gd` se dividen entre N procesos
# (uno por núcleo, máx. 4) equilibrados por tiempo (`COSTES` en banco.gd). Cada
# proceso tiene su propia carpeta `user://` (XDG_DATA_HOME) para que los
# guardados de una parte no pisen los de otra.
#
# Qué vigila:
# - Error de sintaxis en un script de pruebas: se corta en el acto.
# - Cuelgue al arrancar (pasa a veces): esa parte se reintenta (hasta 3 veces).
# - Cuelgue a mitad: si un registro no crece en SIN_AVANCE segundos, se corta.
# - «SCRIPT ERROR» durante la ejecución (errores que _comprobar no ve).
#
# Código de salida: 0 = «FIN. 0 fallos» y sin errores de script;
# 1 = fallos o errores de script; 2 = error de sintaxis; 3 = colgado o sin FIN.
cd "$(dirname "$0")/.." || exit 1
LOG="${1:-/tmp/banco.txt}"
SIN_AVANCE="${SIN_AVANCE:-240}"
NUCLEOS=$(nproc 2>/dev/null || echo 1)
N="${BANCO_PARTES:-$(( NUCLEOS < 4 ? NUCLEOS : 4 ))}"
[ "$N" -lt 1 ] && N=1
TMP=$(mktemp -d)
INICIO=$(date +%s)

limpio() { sed 's/\x1b\[[0-9;]*m//g' "$1" 2>/dev/null; }
declare -a PID TAM QUIETO ARRANCO INTENTO

lanzar() {
  local i=$1
  mkdir -p "$TMP/xdg$i"
  if [ "$N" = "1" ]; then
    timeout 1200 godot --headless --path . res://pruebas/banco.tscn > "$TMP/parte$i.txt" 2>&1 &
  else
    BANCO_PARTE="$i/$N" XDG_DATA_HOME="$TMP/xdg$i" \
      timeout 1200 godot --headless --path . res://pruebas/banco.tscn > "$TMP/parte$i.txt" 2>&1 &
  fi
  PID[$i]=$!
  TAM[$i]=0
  QUIETO[$i]=0
  ARRANCO[$i]=0
  INTENTO[$i]=$(( ${INTENTO[$i]:-0} + 1 ))
}

matar_todo() {
  for i in $(seq 0 $((N - 1))); do kill "${PID[$i]}" 2>/dev/null; done
  sleep 1
  for i in $(seq 0 $((N - 1))); do kill -9 "${PID[$i]}" 2>/dev/null; done
}

for i in $(seq 0 $((N - 1))); do lanzar "$i"; done

while :; do
  vivos=0
  sleep 1
  for i in $(seq 0 $((N - 1))); do
    f="$TMP/parte$i.txt"
    if limpio "$f" | grep -qE "Parse Error|Failed to load script \"res://pruebas/"; then
      matar_todo
      echo "ERROR DE SINTAXIS (el banco no puede arrancar):"
      limpio "$f" | grep -E -A1 "Parse Error|Failed to load script" | head -8
      rm -rf "$TMP"
      exit 2
    fi
    kill -0 "${PID[$i]}" 2>/dev/null || continue
    vivos=$((vivos + 1))
    if [ "${ARRANCO[$i]}" = "0" ]; then
      if grep -q "BANCO DE PRUEBAS" "$f" 2>/dev/null; then
        ARRANCO[$i]=1
        QUIETO[$i]=0
      else
        QUIETO[$i]=$(( QUIETO[$i] + 1 ))
        if [ "${QUIETO[$i]}" -ge 90 ]; then
          kill -9 "${PID[$i]}" 2>/dev/null
          if [ "${INTENTO[$i]}" -ge 3 ]; then
            matar_todo
            echo "la parte $i no arrancó en 3 intentos; últimas líneas:"
            tail -5 "$f"
            rm -rf "$TMP"
            exit 3
          fi
          echo "parte $i: colgada al arrancar, se reintenta"
          lanzar "$i"
        fi
        continue
      fi
    fi
    nuevo=$(stat -c %s "$f" 2>/dev/null || echo 0)
    if [ "$nuevo" = "${TAM[$i]}" ]; then
      QUIETO[$i]=$(( QUIETO[$i] + 1 ))
      if [ "${QUIETO[$i]}" -ge "$SIN_AVANCE" ]; then
        matar_todo
        echo "COLGADO: la parte $i no avanzó en $SIN_AVANCE s; últimas líneas:"
        limpio "$f" | grep -v '^\s*$' | tail -8
        rm -rf "$TMP"
        exit 3
      fi
    else
      TAM[$i]=$nuevo
      QUIETO[$i]=0
    fi
  done
  [ "$vivos" = "0" ] && break
done

# Juntar: el registro completo, los fallos, los errores de script y los tiempos.
: > "$LOG"
for i in $(seq 0 $((N - 1))); do
  [ "$N" = "1" ] || echo "######## PARTE $i/$N ########" >> "$LOG"
  cat "$TMP/parte$i.txt" >> "$LOG"
done
fallos=0
sin_fin=""
for i in $(seq 0 $((N - 1))); do
  linea=$(limpio "$TMP/parte$i.txt" | grep -E "===== FIN" | tail -1)
  if [ -z "$linea" ]; then
    sin_fin="$sin_fin $i"
  elif ! echo "$linea" | grep -q "FIN. 0 fallos"; then
    fallos=$(( fallos + $(echo "$linea" | grep -oE '[0-9]+' | head -1) ))
  fi
done
errores=$(limpio "$LOG" | grep -c "^SCRIPT ERROR\|^SHADER ERROR")
segundos=$(( $(date +%s) - INICIO ))
{
  echo "BANCO EN $N PARTES · ${segundos} s · $(limpio "$LOG" | grep -c '^  ok ') comprobaciones"
  limpio "$LOG" | grep -E "^  FALLO " | sed 's/^  FALLO /  - /'
  echo "Secciones más lentas:"
  limpio "$LOG" | awk '/^TIEMPOS:/{t=1;next} t && /^ +[0-9.]+ s  _probar/{print} t && /^$/{t=0}' | sort -rn | head -6
} > "$TMP/resumen.txt"
if [ -n "$sin_fin" ]; then
  cat "$TMP/resumen.txt"
  echo "SIN FIN: las partes$sin_fin se cortaron antes de terminar; últimas líneas:"
  for i in $sin_fin; do limpio "$TMP/parte$i.txt" | grep -v '^\s*$' | tail -6; done
  rm -rf "$TMP"
  exit 3
fi
if [ "$fallos" = "0" ]; then
  echo "===== FIN. 0 fallos =====" >> "$TMP/resumen.txt"
else
  echo "===== FIN. $fallos FALLOS =====" >> "$TMP/resumen.txt"
fi
cp "$TMP/resumen.txt" pruebas/ultimo_resultado.txt
cat "$TMP/resumen.txt"
if [ "$errores" -gt 0 ]; then
  echo "AVISO: $errores «SCRIPT ERROR» o «SHADER ERROR» durante el banco:"
  limpio "$LOG" | grep -A1 "^SCRIPT ERROR\|^SHADER ERROR" | head -10
fi
rm -rf "$TMP"
[ "$fallos" = "0" ] && [ "$errores" = "0" ] && exit 0
exit 1
