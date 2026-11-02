#!/usr/bin/env python3
"""Iconos por VERSIÓN del juego (2-11-2026): un color por sistema y una intensidad por variante.
  Windows = azul · Linux = rojo · Android = verde · Web = turquesa
  Variante potente (completa) = color fuerte · variante ligera/antigua = color suave
  Con caras reales (--caras) = BORDE DORADO.
Uso:  marca_iconos.py <variante> <carpeta_salida> [--caras]      (genera icono_1024/512/256.png y adaptivo_primero/fondo.png para Android)
      marca_iconos.py --hoja <salida.png>                       (hoja con todas, para revisar)
Se ejecuta en el CI justo antes de exportar. Las copias de `.github/iconos/` (192 px y la hoja) son las que
muestra el resumen de cada ejecución: si cambias colores aquí, regéneralas (ver .github/iconos/LEEME.txt)."""
import sys
from PIL import Image, ImageDraw

# variante: (color de fondo, color del aro)
VARIANTES = {
    "windows":        ("#0A5CFF", "#063AA6"),   # azul fuerte
    "windows-ligero": ("#8DB6FF", "#5E8BD6"),   # azul suave
    "linux":          ("#E01E1E", "#8F0F0F"),   # rojo fuerte
    "android":        ("#0DAA4A", "#06692C"),   # verde fuerte (arm64: la potente)
    "android-armv7":  ("#8EDDA7", "#5BB27A"),   # verde suave (móviles antiguos)
    "web":            ("#14B8C4", "#0B7882"),   # turquesa
}
ORO, ORO_OSCURO = "#F2C230", "#9A7208"
LOGO = "assets/logo/logo_1024.png"

def _redondeado(tam, radio, rel):
    m = Image.new("L", (tam, tam), 0)
    ImageDraw.Draw(m).rounded_rectangle((rel, rel, tam - 1 - rel, tam - 1 - rel), radio, fill=255)
    return m

def icono(variante, caras=False, tam=1024):
    fondo, aro = VARIANTES[variante]
    s = 2  # supermuestreo para bordes suaves
    T = tam * s
    img = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    r = int(T * 0.22)
    if caras:   # borde dorado doble (dorado + línea oscura fina)
        d.rounded_rectangle((0, 0, T - 1, T - 1), r, fill=ORO_OSCURO)
        d.rounded_rectangle((T * 0.012, T * 0.012, T * 0.988, T * 0.988), r, fill=ORO)
        d.rounded_rectangle((T * 0.045, T * 0.045, T * 0.955, T * 0.955), int(r * .88), fill=ORO_OSCURO)
        m = int(T * 0.055)
    else:
        d.rounded_rectangle((0, 0, T - 1, T - 1), r, fill=aro)
        m = int(T * 0.03)
    d.rounded_rectangle((m, m, T - 1 - m, T - 1 - m), int(r * .8), fill=fondo)
    logo = Image.open(LOGO).convert("RGBA")
    lado = int(T * 0.95)
    logo = logo.resize((lado, lado), Image.LANCZOS)
    img.alpha_composite(logo, ((T - lado) // 2, (T - lado) // 2))
    return img.resize((tam, tam), Image.LANCZOS)

def adaptivo(variante, caras=False, tam=432):
    """Android adaptable: primero (logo en la zona segura, fondo transparente) y fondo (color; con
    caras, borde dorado dentro del círculo visible)."""
    fondo, _ = VARIANTES[variante]
    s = 2; T = tam * s
    bg = Image.new("RGBA", (T, T), ORO if caras else fondo)
    if caras:
        d = ImageDraw.Draw(bg); c = T / 2; r = T * 0.30
        d.ellipse((c - r, c - r, c + r, c + r), fill=fondo)
    fg = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    lado = int(T * 0.56)
    fg.alpha_composite(Image.open(LOGO).convert("RGBA").resize((lado, lado), Image.LANCZOS), ((T - lado) // 2, (T - lado) // 2))
    return fg.resize((tam, tam), Image.LANCZOS), bg.resize((tam, tam), Image.LANCZOS)

def main():
    a = sys.argv[1:]
    if a and a[0] == "--hoja":
        n = len(VARIANTES)
        hoja = Image.new("RGBA", (n * 270, 2 * 270 + 10), (30, 30, 36, 255))
        for fila, caras in enumerate((False, True)):
            for i, v in enumerate(VARIANTES):
                hoja.alpha_composite(icono(v, caras, 256), (i * 270 + 7, fila * 270 + 5))
        hoja.convert("RGB").save(a[1]); return
    if len(a) < 2 or a[0] not in VARIANTES:
        sys.exit("uso: marca_iconos.py <%s> <carpeta> [--caras]" % "|".join(VARIANTES))
    import os
    os.makedirs(a[1], exist_ok=True)
    base = icono(a[0], "--caras" in a, 1024)
    for t in (1024, 512, 256):
        base.resize((t, t), Image.LANCZOS).save(os.path.join(a[1], "icono_%d.png" % t))
    fg, bg = adaptivo(a[0], "--caras" in a)
    fg.save(os.path.join(a[1], "adaptivo_primero.png")); bg.save(os.path.join(a[1], "adaptivo_fondo.png"))
    print("iconos de", a[0], "(con borde dorado)" if "--caras" in a else "", "→", a[1])

main()
