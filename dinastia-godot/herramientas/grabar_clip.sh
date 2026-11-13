#!/bin/bash
# GRABA UN CLIP CORTO DEL PARTIDO REAL (13-11-2026) SIN GPU NI PC DEL DUEÑO: modo Compatibility (el del móvil), que en este tipo de
# contenedor TERMINA (Forward+ con lavapipe se cuelga compilando shaders y cuesta ~40 veces el tiempo real; esto, ~4-12 veces).
#   herramientas/grabar_clip.sh <carpeta_de_salida> [segundos_de_vídeo=30] [ancho=1280] [alto=720] [fps=20]
# Variables: RITMO=rapido|normal (minutos de partido por segundo de vídeo), CEREMONIA=1 (con la ceremonia de entrada).
# Salida: <carpeta>/clip.avi (MJPEG, grande) y <carpeta>/clip.mp4 (H.264, ligero). Ni .avi ni .mp4 van al repo (regla del proyecto).
# Usa `--quit-after` (fotogramas) para que Godot cierre bien el AVI. La escena es `pruebas/video_partido.tscn` (la misma del vídeo de gameplay).
OUT="${1:?uso: grabar_clip.sh <carpeta_de_salida> [segundos] [ancho] [alto] [fps]}"
SEG="${2:-30}"; W="${3:-1280}"; H="${4:-720}"; FPS="${5:-20}"
mkdir -p "$OUT"
cd "$(dirname "$0")/.." || exit 1
FOTOGRAMAS=$((SEG * FPS))
printf '[display]\n\nwindow/size/viewport_width=%s\nwindow/size/viewport_height=%s\n\n[editor]\n\nmovie_writer/mjpeg_quality=0.85\n' "$W" "$H" > override.cfg
RITMO="${RITMO:-rapido}" xvfb-run -a -s "-screen 0 ${W}x${H}x24" godot --path . --rendering-driver opengl3 --resolution "${W}x${H}" \
  --fixed-fps "$FPS" --quit-after "$FOTOGRAMAS" --write-movie "$OUT/clip.avi" res://pruebas/video_partido.tscn
rm -f override.cfg
if command -v ffmpeg >/dev/null; then
  ffmpeg -loglevel error -y -i "$OUT/clip.avi" -c:v libx264 -preset veryfast -crf 24 -pix_fmt yuv420p -movflags +faststart "$OUT/clip.mp4" && echo "listo: $OUT/clip.mp4"
fi
