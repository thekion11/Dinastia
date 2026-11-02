#!/usr/bin/env python3
"""Ajusta UN preset de export_presets.cfg para una versión (solo en el CI, sobre la copia del
runner; nunca se sube). Uso:
  ajustar_presets.py <preset> <carpeta_res_iconos> [--armv7] [--aab] [--version=<sufijo>]
Pone los iconos de la variante (marca_iconos.py) y, en Android, la arquitectura y el nombre."""
import re, sys

preset, carpeta = sys.argv[1], sys.argv[2]
armv7 = "--armv7" in sys.argv
aab = "--aab" in sys.argv
sufijo = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--version=")), "")
CAMBIOS = {
    "application/icon": '"%s/icono_1024.png"' % carpeta,
    "launcher_icons/main_192x192": '"%s/icono_256.png"' % carpeta,
    "launcher_icons/adaptive_foreground_432x432": '"%s/adaptivo_primero.png"' % carpeta,
    "launcher_icons/adaptive_background_432x432": '"%s/adaptivo_fondo.png"' % carpeta,
}
if armv7:
    CAMBIOS["architectures/armeabi-v7a"] = "true"
    CAMBIOS["architectures/arm64-v8a"] = "false"
if aab:   # paquete para Google Play: compilación con Gradle + formato AAB
    CAMBIOS["gradle_build/use_gradle_build"] = "true"
    CAMBIOS["gradle_build/export_format"] = "1"
if sufijo:
    CAMBIOS["version/name"] = '"1.0%s"' % sufijo
    CAMBIOS["application/product_version"] = '"1.0%s"' % sufijo

lineas = open("export_presets.cfg", encoding="utf-8").read().split("\n")
dentro, vistos, existe = False, 0, False
for i, l in enumerate(lineas):
    if l.startswith("[preset.") and not l.endswith(".options]"):
        dentro = False
    m = re.match(r'name="(.*)"', l)
    if m and not l.startswith("["):
        dentro = (m.group(1) == preset)
        existe = existe or dentro
    if dentro and "=" in l:
        k = l.split("=", 1)[0]
        if k in CAMBIOS:
            lineas[i] = "%s=%s" % (k, CAMBIOS[k]); vistos += 1
if not existe:
    sys.exit("No encontré el preset «%s» en export_presets.cfg" % preset)
open("export_presets.cfg", "w", encoding="utf-8").write("\n".join(lineas))
print("preset %s: %d ajustes (%s)" % (preset, vistos, "armv7" if armv7 else "iconos"))
