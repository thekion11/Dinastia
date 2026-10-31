#!/bin/bash
# COMPILAR LA EXTENSIÓN NATIVA (30-10-2026). Descarga godot-cpp (oficial, licencia MIT) en el
# commit probado dentro de nativo/godot-cpp (no va al repositorio) y compila bin_nativo/ para
# Linux y Windows (debug para el editor y las pruebas, release para el juego exportado).
#   herramientas/compilar_nativo.sh            todo
#   herramientas/compilar_nativo.sh linux      solo Linux
# Windows se compila desde Linux con mingw-w64 (apt-get install mingw-w64).
# Tras compilar: pruebas/probar_nativo.tscn debe terminar en «FIN. 0 fallos».
set -e
cd "$(dirname "$0")/../nativo"
COMMIT_GODOT_CPP=e103d34
if [ ! -d godot-cpp ]; then
  git clone -q https://github.com/godotengine/godot-cpp godot-cpp
fi
git -C godot-cpp fetch -q --depth 1 origin "$COMMIT_GODOT_CPP" 2>/dev/null || true
git -C godot-cpp checkout -q "$COMMIT_GODOT_CPP"
PLATAFORMAS="${1:-linux windows}"
for p in $PLATAFORMAS; do
  for t in template_debug template_release; do
    scons -j"$(nproc)" GODOT_CPP=godot-cpp platform="$p" target="$t" api_version=4.7
  done
done
ls -la ../bin_nativo/
