#!/usr/bin/env python3
"""Hojas de contacto de un directorio de JPG: `hoja_contacto.py carpeta [por_hoja=6]` -> carpeta/hoja_N.jpg
(2 columnas, cada foto con su nombre debajo)."""
import os as _os, sys as _sys
_sys.path.insert(0, _os.path.join(_os.path.dirname(_os.path.abspath(__file__)), "..", "..", "herramientas"))
from ruta_segura import ruta_segura
import sys, glob, os
from PIL import Image, ImageDraw, ImageFont
carpeta = ruta_segura(sys.argv[1])
por = int(sys.argv[2]) if len(sys.argv) > 2 else 6
fotos = sorted(f for f in glob.glob(os.path.join(carpeta, "[0-9]*.jpg")))
cols, ancho = 2, 960
try:
    fuente = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 22)
except OSError:
    fuente = ImageFont.load_default()
for h in range(0, len(fotos), por):
    grupo = fotos[h:h + por]
    filas = (len(grupo) + cols - 1) // cols
    alto = 540 + 34
    hoja = Image.new("RGB", (cols * ancho, filas * alto), (20, 20, 24))
    d = ImageDraw.Draw(hoja)
    for i, f in enumerate(grupo):
        im = Image.open(f).convert("RGB").resize((ancho, 540))
        x, y = (i % cols) * ancho, (i // cols) * alto
        hoja.paste(im, (x, y))
        d.text((x + 10, y + 544), os.path.basename(f)[:-4], fill=(235, 235, 235), font=fuente)
    salida = os.path.join(carpeta, "hoja_%d.jpg" % (h // por + 1))
    hoja.save(salida, quality=88)
    print(salida)
