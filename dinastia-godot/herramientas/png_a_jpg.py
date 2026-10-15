"""Convierte a JPG (calidad 90) las capturas PNG nuevas y borra el PNG.

Lo llama `herramientas/captura.sh` al terminar. A la vista es casi igual y
pesa ~5 veces menos (el historial del repo crecía sobre todo por capturas).
Las imágenes con transparencia real se dejan en PNG.

    python3 -I herramientas/png_a_jpg.py <marca> <carpeta> [<carpeta>...]

Solo toca los PNG modificados después del archivo <marca>.
"""
import os
import sys

from PIL import Image


def convertir(ruta: str) -> str | None:
    img = Image.open(ruta)
    if img.mode in ("RGBA", "LA", "P"):
        rgba = img.convert("RGBA")
        if rgba.getextrema()[3][0] < 255:
            return None
        img = rgba
    destino = os.path.splitext(ruta)[0] + ".jpg"
    img.convert("RGB").save(destino, "JPEG", quality=90, optimize=True)
    os.remove(ruta)
    return destino


def main() -> int:
    marca = os.path.getmtime(sys.argv[1])
    for carpeta in sys.argv[2:]:
        for raiz, _, archivos in os.walk(carpeta):
            for nombre in sorted(archivos):
                ruta = os.path.join(raiz, nombre)
                if not nombre.lower().endswith(".png") or os.path.getmtime(ruta) < marca:
                    continue
                antes = os.path.getsize(ruta)
                destino = convertir(ruta)
                if destino is None:
                    print(f"  (con transparencia, se queda en PNG) {ruta}")
                else:
                    print(f"  {destino}  {antes // 1024} KB -> {os.path.getsize(destino) // 1024} KB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
