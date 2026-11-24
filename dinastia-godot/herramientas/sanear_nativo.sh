#!/bin/bash
# EXTENSIÓN SANEADA (17-11-2026, orden de Auditoría): compila la extensión C++ con AddressSanitizer + UBSan (solo Linux, depuración, en
# bin_nativo_saneada/), la pone en lugar de la de depuración normal, corre probar_nativo, igualdad_motor y un partido entero de C4
# (sonda_goles_c4 con N=1) con la libasan precargada, y SIEMPRE devuelve la normal. Informe: los avisos de ASan/UBSan que nombran
# nuestras fuentes (nativo/src); las fugas propias de Godot (no instrumentado) no cuentan.
#   herramientas/sanear_nativo.sh           compila y prueba
#   SIN_COMPILAR=1 herramientas/sanear_nativo.sh
set -u
cd "$(dirname "$0")/.."
RAIZ="$(pwd)"
## Sin scons o sin godot-cpp (contenedor nuevo, CI sin la cadena de C++): no se puede compilar la saneada; se salta SIN fallo (herramientas/compilar_nativo.sh baja godot-cpp).
if [[ -z "${SIN_COMPILAR:-}" ]] && { ! command -v scons >/dev/null || [[ ! -d nativo/godot-cpp ]]; }; then
  echo "SANEADA: saltada (falta scons o nativo/godot-cpp). SANEADA: 0 líneas de aviso"
  exit 0
fi
if [[ -z "${SIN_COMPILAR:-}" ]]; then
  (cd nativo && scons -j"$(nproc)" GODOT_CPP=godot-cpp platform=linux target=template_debug api_version=4.7 SANITIZAR=1) || { echo "SANEADA: no compila"; exit 1; }
fi
NORMAL=bin_nativo/libdinastia.linux.template_debug.x86_64.so
SANA=bin_nativo_saneada/libdinastia.linux.template_debug.x86_64.so
[[ -f "$SANA" ]] || { echo "SANEADA: falta $SANA"; exit 1; }
RESPALDO="$(mktemp)"
cp "$NORMAL" "$RESPALDO"
trap 'cp "$RESPALDO" "$RAIZ/$NORMAL"; rm -f "$RESPALDO"' EXIT
cp "$SANA" "$NORMAL"
LOG="$(mktemp -d)"
## Godot abre las extensiones con RTLD_DEEPBIND (incompatible con ASan): una capa precargada antes de libasan la quita.
gcc -shared -fPIC -o "$LOG/sin_deepbind.so" herramientas/sanear/sin_deepbind.c -ldl || { echo "SANEADA: no compila la capa"; exit 1; }
LIBASAN="$LOG/sin_deepbind.so:$(gcc -print-file-name=libasan.so)"
export ASAN_OPTIONS="verify_asan_link_order=0:detect_leaks=1:halt_on_error=0:log_path=$LOG/asan"
export UBSAN_OPTIONS="print_stacktrace=1:halt_on_error=0:log_path=$LOG/ubsan"
for e in probar_nativo igualdad_motor; do
  LD_PRELOAD="$LIBASAN" timeout 1800 godot --headless --path . "res://pruebas/$e.tscn" > "$LOG/$e.txt" 2>&1
  echo "SANEADA $e: $(grep -E 'FIN\.|HUELLA' "$LOG/$e.txt" | tail -1)"
done
LD_PRELOAD="$LIBASAN" N=1 timeout 1800 godot --headless --path . res://pruebas/_sonda/sonda_goles_c4.tscn > "$LOG/partido.txt" 2>&1
echo "SANEADA partido C4: $(grep -E 'RESUMEN' "$LOG/partido.txt" | cut -c1-80)"
PROPIOS=0
for f in "$LOG"/asan* "$LOG"/ubsan* "$LOG"/*.txt; do
  [[ -f "$f" ]] || continue
  n=$(grep -cE "nativo/src/|runtime error" "$f" || true)
  if [[ "$n" -gt 0 ]]; then
    PROPIOS=$((PROPIOS + n))
    echo "---- $f"; grep -E -B2 -A12 "nativo/src/|runtime error" "$f" | head -60
  fi
done
echo "SANEADA: $PROPIOS líneas de aviso en nuestras fuentes (registros en $LOG)"
[[ "$PROPIOS" -eq 0 ]]
