#!/bin/bash
# Lanza una escena de captura con el renderizador que verá el jugador de PC.
#   herramientas/captura.sh res://pruebas/captura_x.tscn [--compat] [--png]
#   (variables de la escena como siempre: CARAS=... MOMENTO=... delante)
#
# REGLA (15-10-2026, pedida por el usuario): lo visual se revisa en FORWARD+,
# que es lo que usa el juego en PC. Hasta esa fecha todas las capturas salían
# con Compatibility (opengl3) y no se veía lo mismo que el jugador.
#   --compat  Compatibility: solo para revisar móvil, web o el «motor ligero».
#   --png     no convertir a JPG (por defecto, las capturas nuevas pasan a JPG
#             calidad 90: ~5 veces menos peso en el repositorio).
#
# Sin GPU, Forward+ corre con lavapipe (Vulkan por software, más lento):
#   apt-get install -y mesa-vulkan-drivers
cd "$(dirname "$0")/.." || exit 1
ESCENA=""
COMPAT=0
PNG=0
for a in "$@"; do
  case "$a" in
    --compat) COMPAT=1 ;;
    --png) PNG=1 ;;
    *) ESCENA="$a" ;;
  esac
done
if [ -z "$ESCENA" ]; then
  echo "uso: herramientas/captura.sh res://pruebas/captura_x.tscn [--compat] [--png]"
  exit 2
fi
if [ "$COMPAT" = "1" ]; then
  MOTOR=(--rendering-driver opengl3)
  echo "Renderizador: COMPATIBILITY (móvil/web/motor ligero)"
else
  if ! ls /usr/share/vulkan/icd.d/*.json > /dev/null 2>&1; then
    echo "FALTA VULKAN: instala mesa-vulkan-drivers (apt-get install -y mesa-vulkan-drivers)."
    echo "Usa --compat solo si de verdad quieres revisar móvil, web o el motor ligero."
    exit 3
  fi
  MOTOR=(--rendering-driver vulkan --rendering-method forward_plus)
  echo "Renderizador: FORWARD+ (PC)"
fi
MARCA=$(mktemp)
xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . "${MOTOR[@]}" \
  --resolution "${RESOLUCION:-1920x1080}" "$ESCENA"
codigo=$?
if [ "$PNG" = "0" ]; then
  python3 -I herramientas/png_a_jpg.py "$MARCA" pruebas
fi
rm -f "$MARCA"
exit $codigo
