#!/bin/bash
# COMPILAR LA EXTENSIÓN NATIVA (30-10-2026). Descarga godot-cpp (oficial, licencia MIT) en el
# commit probado dentro de nativo/godot-cpp (no va al repositorio) y compila bin_nativo/ para
# Linux y Windows (debug para el editor y las pruebas, release para el juego exportado).
#   herramientas/compilar_nativo.sh            todo
#   herramientas/compilar_nativo.sh linux      solo Linux
#   herramientas/compilar_nativo.sh android    Android arm64 (necesita ANDROID_NDK_ROOT; lo hace el CI, 31-10)
#   ARCH=arm64 herramientas/compilar_nativo.sh linux   Linux arm64 (el CI lo compila en una máquina ARM para la prueba)
# Windows se compila desde Linux con mingw-w64 (apt-get install mingw-w64).
#   herramientas/compilar_nativo.sh tracy      Linux con Tracy (5-11): clona wolfpld/tracy v0.13.0 en nativo/tracy (no va al repo) y deja
#                                              bin_nativo_tracy/ (ignorado). Pasos: docs/04_auditorias/tracy_2026-11-05.md
# Tras compilar: pruebas/probar_nativo.tscn debe terminar en «FIN. 0 fallos».
set -e
cd "$(dirname "$0")/../nativo"
COMMIT_GODOT_CPP=e103d34
if [[ ! -d godot-cpp ]]; then
  git clone -q https://github.com/godotengine/godot-cpp godot-cpp
fi
git -C godot-cpp fetch -q --depth 1 origin "$COMMIT_GODOT_CPP" 2>/dev/null || true
git -C godot-cpp checkout -q "$COMMIT_GODOT_CPP"
if [[ "$1" = "tracy" ]]; then
  [[ -d tracy ]] || git clone -q -b v0.13.0 --single-branch --depth 1 https://github.com/wolfpld/tracy.git tracy
  for t in template_debug template_release; do
    scons -j"$(nproc)" GODOT_CPP=godot-cpp platform=linux target="$t" api_version=4.7 tracy=yes TRACY_PATH=tracy
  done
  ls -la ../bin_nativo_tracy/; exit 0
fi
PLATAFORMAS="${1:-linux windows}"
for p in $PLATAFORMAS; do
  for t in template_debug template_release; do
    if [[ "$p" = "android" ]]; then
      ## Con ANDROID_HOME vacío godot-cpp usa ANDROID_NDK_ROOT (el NDK que haya, sin fijar versión).
      scons -j"$(nproc)" GODOT_CPP=godot-cpp platform=android arch=arm64 target="$t" api_version=4.7 ANDROID_HOME=
    else
      scons -j"$(nproc)" GODOT_CPP=godot-cpp platform="$p" target="$t" api_version=4.7 ${ARCH:+arch=$ARCH}
    fi
  done
done
ls -la ../bin_nativo/
