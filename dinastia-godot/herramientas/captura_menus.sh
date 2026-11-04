#!/bin/bash
# Recorrido con fotos del menú nuevo (Forward+ 1920x1080) + hojas de contacto. Fuera del repo.
#   herramientas/captura_menus.sh [carpeta_salida]   (por defecto /tmp/fotos_menus)
cd "$(dirname "$0")/.." || exit 1
export OUT="${1:-/tmp/fotos_menus}"
rm -rf "$OUT"; mkdir -p "$OUT"
herramientas/captura.sh res://pruebas/captura_menus_dueno.tscn
python3 -I herramientas/hoja_contacto.py "$OUT" 6
