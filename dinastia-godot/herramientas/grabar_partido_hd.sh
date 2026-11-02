#!/bin/bash
# GRABA EL PARTIDO COMPLETO EN 1080p (02-11-2026, pedido del dueño: «mucha mejor calidad y nitidez»).
#   herramientas/grabar_partido_hd.sh <carpeta_de_salida>          (el .avi y el .mp4 NUNCA van al repo)
# Sin tarjeta gráfica (Forward+ con lavapipe) tarda ~6-7 h para ~9 min de vídeo; en un PC con GPU, minutos.
# Crea un `override.cfg` temporal (1920x1080, 3D al 100 %, JPEG 0,9), que se borra al terminar.
# Luego, para el .mp4 de alta calidad:  ffmpeg -i partido_hd.avi -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -c:a aac -b:a 160k -movflags +faststart partido_hd.mp4
# (la app admite ~30 MB por archivo: para mandarlo, partirlo; si no, al Drive con herramientas/drive_subir.ps1).
OUT="${1:?uso: grabar_partido_hd.sh <carpeta_de_salida>}"
mkdir -p "$OUT"
cd "$(dirname "$0")/.." || exit 1
printf '[display]\n\nwindow/size/viewport_width=1920\nwindow/size/viewport_height=1080\n\n[rendering]\n\nscaling_3d/scale=1.0\n\n[editor]\n\nmovie_writer/mjpeg_quality=0.9\n' > override.cfg
CEREMONIA=1 RITMO=rapido xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver vulkan --rendering-method forward_plus \
  --fixed-fps 20 --write-movie "$OUT/partido_hd.avi" res://pruebas/video_partido.tscn
rm -f override.cfg
