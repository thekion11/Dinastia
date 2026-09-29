#!/usr/bin/env python3
"""Monta el vídeo promocional a partir de los tramos de `pruebas/video_promo.gd`.

Cada tramo es un AVI (MJPEG, 1280x720, 25 fps) que escribe el grabador de Godot
en `pruebas/capturas/promo/`. Esto los une en orden, con un fundido a negro
corto entre tramos, y sale un MP4 H.264 liviano para mandar por chat.

    python3 herramientas/montar_promo.py [salida.mp4]

Necesita ffmpeg; si no está en el PATH usa el de `imageio_ffmpeg`.
"""
import os
import shutil
import subprocess
import sys

ORDEN = ["portada", "hub", "menus", "plantel", "fichaje", "partido", "prensa",
         "sorteo", "casa", "telefono", "ciudad", "carrera", "jugable", "idiomas", "cierre"]
FUNDIDO = 0.35  # segundos de fundido de entrada y de salida en cada tramo


def ffmpeg() -> str:
    ruta = shutil.which("ffmpeg")
    if ruta:
        return ruta
    import imageio_ffmpeg  # type: ignore
    return imageio_ffmpeg.get_ffmpeg_exe()


def duracion(ff: str, archivo: str) -> float:
    salida = subprocess.run([ff, "-i", archivo], capture_output=True, text=True).stderr
    for linea in salida.splitlines():
        if "Duration:" in linea:
            h, m, s = linea.split("Duration:")[1].split(",")[0].strip().split(":")
            return int(h) * 3600 + int(m) * 60 + float(s)
    return 0.0


def main() -> None:
    raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    carpeta = os.path.join(raiz, "pruebas", "capturas", "promo")
    destino = sys.argv[1] if len(sys.argv) > 1 else os.path.join(carpeta, "DINASTIA_promo.mp4")
    ff = ffmpeg()
    tramos: list[str] = []
    for n in ORDEN:
        ## Los tramos 3D pesados vienen en partes: `_p0`, `_p1`...
        if os.path.exists(os.path.join(carpeta, n + "_p0.avi")):
            k = 0
            while os.path.exists(os.path.join(carpeta, f"{n}_p{k}.avi")):
                tramos.append(os.path.join(carpeta, f"{n}_p{k}.avi"))
                k += 1
        elif os.path.exists(os.path.join(carpeta, n + ".avi")):
            tramos.append(os.path.join(carpeta, n + ".avi"))
    if not tramos:
        sys.exit("No hay tramos grabados en " + carpeta)
    entradas: list[str] = []
    filtros: list[str] = []
    for i, t in enumerate(tramos):
        d = duracion(ff, t)
        entradas += ["-i", t]
        ## Entre las partes de un mismo tramo no hay fundido: es corrido.
        nombre = os.path.basename(t)[:-4]
        base, _, parte = nombre.rpartition("_p")
        es_parte = base != "" and parte.isdigit()
        primera = not es_parte or parte == "0"
        ultima = not es_parte or not os.path.exists(os.path.join(carpeta, f"{base}_p{int(parte) + 1}.avi"))
        fundido = ""
        if primera:
            fundido += f",fade=t=in:st=0:d={FUNDIDO}"
        if ultima:
            fundido += f",fade=t=out:st={max(0.0, d - FUNDIDO):.3f}:d={FUNDIDO}"
        filtros.append(f"[{i}:v]fps=25,scale=1280:720,setsar=1{fundido}[v{i}]")
    concat = "".join(f"[v{i}]" for i in range(len(tramos)))
    filtros.append(f"{concat}concat=n={len(tramos)}:v=1:a=0[salida]")
    cmd = [ff, "-y", *entradas, "-filter_complex", ";".join(filtros), "-map", "[salida]",
           "-c:v", "libx264", "-preset", "medium", "-crf", "24", "-pix_fmt", "yuv420p",
           "-movflags", "+faststart", destino]
    subprocess.run(cmd, check=True)
    print(f"Listo: {destino}  ({len(tramos)} tramos)")


if __name__ == "__main__":
    main()
