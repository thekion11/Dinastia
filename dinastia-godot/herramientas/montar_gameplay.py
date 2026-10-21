#!/usr/bin/env python3
"""Monta el VÍDEO DE GAMEPLAY (21-10-2026) con los tramos grabados por
pruebas/video_partido.tscn y pruebas/video_gameplay.tscn (VG_TRAMO=...).

    python3 herramientas/montar_gameplay.py <carpeta_con_los_avi>

Sale en dos partes de menos de 29 MB (el chat admite 30 MB por archivo):
  dinastia_gameplay_1_partido.mp4  · el partido entero, jugado con el mando
  dinastia_gameplay_2_resto.mp4    · gestión, estadio a pie, ciudad, Carrera de Jugador, minijuegos
Cada tramo lleva delante una tarjeta de título. Sonido AAC (el de la grabación:
música, grada y efectos). Los .avi y .mp4 NUNCA van al repositorio."""
import os
import subprocess
import sys
from PIL import Image, ImageDraw, ImageFont

FF = "/usr/bin/ffmpeg"
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT2 = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
W, H = 960, 540
LIMITE_MB = 28.5
D = sys.argv[1] if len(sys.argv) > 1 else "."

PARTES = {
    "1_partido": [
        ("t_ini", "DINASTÍA · GAMEPLAY REAL", [
            "Todo lo que se ve es el juego, grabado con su sonido.",
            "Un partido entero (90' a ritmo normal: ~6 min, como un partido de FC)",
            "jugado con el mando por un bot que pulsa los mismos botones que una persona."]),
        ("partido", None, None),
    ],
    "2_resto": [
        ("t_ini2", "DINASTÍA · EL RESTO DEL JUEGO", ["Gestión · estadio a pie · ciudad · Carrera de Jugador · minijuegos"]),
        ("t_gestion", "1 · LA GESTIÓN", ["Plantel, táctica, entrenamiento, camarín, mercado, finanzas,", "menús laterales, semana, prensa y móvil"]),
        ("gestion", None, None),
        ("t_estadio", "2 · EL ESTADIO", ["Por fuera con su entorno, y a pie: vestuario, túnel, césped", "y a sentarse en la grada"]),
        ("estadio", None, None),
        ("t_ciudad", "3 · LA CIUDAD", ["A pie, corriendo, en primera persona y conduciendo", "con tres cámaras, de día y de noche"]),
        ("ciudad", None, None),
        ("t_carrera", "4 · CARRERA DE JUGADOR", ["Crear al jugador y su partido: ceremonia, córner y penal propios"]),
        ("carrera", None, None),
        ("t_mini", "5 · MINIJUEGOS", ["La sala de Mi Vida: malabares"]),
        ("mini", None, None),
        ("t_fin", "DINASTÍA", ["Fin del recorrido. Listo para evaluar."]),
    ],
}


def tarjeta(nombre, titulo, lineas):
    im = Image.new("RGB", (W, H), (7, 18, 12))
    d = ImageDraw.Draw(im)
    d.rectangle([0, H - 6, W, H], fill=(201, 242, 75))
    f1 = ImageFont.truetype(FONT, 50)
    f2 = ImageFont.truetype(FONT2, 22)
    w = d.textlength(titulo, font=f1)
    y0 = 190 - len(lineas) * 10
    d.text(((W - w) / 2, y0), titulo, font=f1, fill=(255, 215, 120))
    for i, l in enumerate(lineas):
        w = d.textlength(l, font=f2)
        d.text(((W - w) / 2, y0 + 90 + i * 34), l, font=f2, fill=(220, 230, 225))
    ruta = os.path.join(D, nombre + ".png")
    im.save(ruta)
    return ruta


def run(args):
    subprocess.run([FF, "-y", "-hide_banner", "-loglevel", "error"] + args, check=True)


def intermedio(nombre, titulo, lineas):
    """Cada pieza a H.264 de alta calidad, mismo formato, para unirlas sin recodificar."""
    out = os.path.join(D, "i_" + nombre + ".mp4")
    comun = ["-c:v", "libx264", "-preset", "veryfast", "-crf", "14", "-pix_fmt", "yuv420p", "-r", "25",
             "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-ac", "2"]
    if titulo is not None:
        png = tarjeta(nombre, titulo, lineas)
        run(["-loop", "1", "-i", png, "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo", "-t", "4",
             "-vf", f"scale={W}:{H},fade=in:0:10,fade=out:90:10"] + comun + [out])
    else:
        avi = os.path.join(D, nombre + ".avi")
        run(["-i", avi, "-vf", f"scale={W}:{H}:flags=lanczos", "-af", "aresample=48000"] + comun + [out])
    return out


def duracion(ruta):
    r = subprocess.run(["/usr/bin/ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", ruta],
                       capture_output=True, text=True, check=True)
    return float(r.stdout.strip())


for parte, piezas in PARTES.items():
    trozos = [intermedio(n, t, l) for n, t, l in piezas if t is not None or os.path.exists(os.path.join(D, n + ".avi"))]
    lista = os.path.join(D, f"lista_{parte}.txt")
    with open(lista, "w") as f:
        for t in trozos:
            f.write("file '%s'\n" % os.path.abspath(t))
    unido = os.path.join(D, f"unido_{parte}.mp4")
    run(["-f", "concat", "-safe", "0", "-i", lista, "-c", "copy", unido])
    dur = duracion(unido)
    audio_k = 80
    video_k = int(LIMITE_MB * 8 * 1024 / dur) - audio_k - 6
    final = os.path.join(D, f"dinastia_gameplay_{parte}.mp4")
    log = os.path.join(D, f"pase_{parte}")
    base = ["-i", unido, "-c:v", "libx264", "-preset", "slow", "-b:v", f"{video_k}k", "-pix_fmt", "yuv420p",
            "-passlogfile", log]
    run(base + ["-pass", "1", "-an", "-f", "mp4", "/dev/null"])
    run(base + ["-pass", "2", "-c:a", "aac", "-b:a", f"{audio_k}k", "-movflags", "+faststart", final])
    print("OK %s  %.0f s  %d kbps  %.1f MB" % (final, dur, video_k, os.path.getsize(final) / 1048576))
