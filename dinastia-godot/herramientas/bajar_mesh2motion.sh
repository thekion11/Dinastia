#!/bin/bash
# Baja los clips de Mesh2Motion (CC0) que usa `herramientas/hornear_publico_vat.gd`.
# NO van al repositorio (13 MB de .glb; los .glb van por LFS y desde el contenedor
# LFS no sube): se guardan en ~/.cache/dinastia/mesh2motion (o en $M2M_DIR).
# Commit fijado para que el horneado sea reproducible. Licencia: LICENSE-CC0.MD
# del propio repositorio («All 3d models, blend files, rigs, animations — CC0 1.0»).
set -e
DIR="${M2M_DIR:-$HOME/.cache/dinastia/mesh2motion}"
COMMIT=653a9698f5f315523072f1c3ff3496100401317b
BASE="https://raw.githubusercontent.com/scottpetrovic/mesh2motion-app/$COMMIT"
mkdir -p "$DIR"
for f in human-base-animations human-addon-animations human-mocap-animations; do
  [ -s "$DIR/$f.glb" ] || curl -sSfL -o "$DIR/$f.glb" "$BASE/static/animations/$f.glb"
done
curl -sSfL -o "$DIR/LICENSE-CC0.MD" "$BASE/LICENSE-CC0.MD"
ls -la "$DIR"
