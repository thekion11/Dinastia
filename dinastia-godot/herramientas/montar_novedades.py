#!/usr/bin/env python3
"""Monta el vídeo de novedades (MEGA AUDITORÍA 2) con los tramos de
pruebas/capturas/nov/*.avi + dos tarjetas de título hechas con Pillow.
Salida: pruebas/capturas/nov/dinastia_novedades.mp4 (NO se sube al repo: LFS prohibido)."""
import subprocess, sys, os
from PIL import Image, ImageDraw, ImageFont
FF = "/usr/local/lib/python3.11/dist-packages/imageio_ffmpeg/binaries/ffmpeg-linux-x86_64-v7.0.2"
D = "pruebas/capturas/nov"
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

def tarjeta(nombre, titulo, lineas):
    im = Image.new("RGB", (1280, 720), (8, 14, 12))
    d = ImageDraw.Draw(im)
    f1 = ImageFont.truetype(FONT, 72)
    f2 = ImageFont.truetype(FONT, 30)
    w = d.textlength(titulo, font=f1)
    d.text(((1280 - w) / 2, 220), titulo, font=f1, fill=(255, 215, 120))
    for i, l in enumerate(lineas):
        w = d.textlength(l, font=f2)
        d.text(((1280 - w) / 2, 340 + i * 46), l, font=f2, fill=(220, 230, 225))
    im.save(f"{D}/{nombre}.png")

tarjeta("t_ini", "DINASTÍA", ["Novedades de la MEGA AUDITORÍA 2", "Partido · conducción · menús · minijuegos"])
tarjeta("t_fin", "Y SIGUE", ["Pendiente: LOD de ojos y pelo, VAR que anula, más idiomas", "Todo lo que se ve es el juego real"])
partes = []
for n in ["t_ini"]:
    out = f"{D}/{n}.mp4"
    subprocess.run([FF, "-y", "-loglevel", "error", "-loop", "1", "-i", f"{D}/{n}.png", "-t", "3", "-r", "20",
                    "-vf", "scale=1280:720,format=yuv420p", "-c:v", "libx264", "-crf", "30", out], check=True)
    partes.append(out)
for n in ["partido", "conduccion", "menus", "minijuegos"]:
    out = f"{D}/{n}.mp4"
    subprocess.run([FF, "-y", "-loglevel", "error", "-i", f"{D}/{n}.avi", "-r", "20",
                    "-vf", "scale=1280:720,format=yuv420p", "-c:v", "libx264", "-crf", "30", "-preset", "medium", out], check=True)
    partes.append(out)
out = f"{D}/t_fin.mp4"
subprocess.run([FF, "-y", "-loglevel", "error", "-loop", "1", "-i", f"{D}/t_fin.png", "-t", "3", "-r", "20",
                "-vf", "scale=1280:720,format=yuv420p", "-c:v", "libx264", "-crf", "30", out], check=True)
partes.append(out)
lista = f"{D}/lista.txt"
with open(lista, "w") as f:
    for p in partes:
        f.write("file '%s'\n" % os.path.abspath(p))
final = f"{D}/dinastia_novedades.mp4"
subprocess.run([FF, "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", lista, "-c", "copy", final], check=True)
print("OK", final, os.path.getsize(final) // 1024, "KB")
