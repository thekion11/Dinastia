#!/usr/bin/env python3
"""M-420 (27-10-2026): LOS BUILDS PÚBLICOS NO LLEVAN DATOS REALES.
Exporta el paquete (`--export-pack`, no hace falta la plantilla de exportación) de cada preset público a un .zip
temporal y comprueba dos cosas:
  1. que no viaja ningún archivo de lo real (caras, pack real, créditos de fotos, listas de futbolistas);
  2. que en ningún archivo aparece, escrito tal cual, el nombre de un futbolista real (los de
     `datos/reales_lista.json` y `datos/creditos_fotos.txt`, que no viajan).
   cd dinastia-godot && python3 herramientas/revisar_build_publico.py [preset ...]
Termina con «FIN BUILD PÚBLICO. N fallos». Lo corre `herramientas/especiales.sh todo`."""
import json
import os
import re
import subprocess
import sys
import tempfile
import zipfile

PRESETS = sys.argv[1:] or ["WindowsLigero", "Web", "Android"]
PROHIBIDOS = re.compile(r"(caras_reales|pack_real|creditos_fotos|reales_lista|caras_biblioteca|biblioteca_caras\.json"
                        r"|tablas\.json\.bak|^pruebas/|\.md$)")
TEXTO = (".json", ".txt", ".cfg", ".gdc", ".gd", ".tres", ".tscn", ".remap", ".csv", ".import")


def nombres_reales() -> list[str]:
    n = set()
    for f in json.load(open("datos/reales_lista.json", encoding="utf-8-sig")):
        n.add(str(f.get("nombre", "")).strip())
    for linea in open("datos/creditos_fotos.txt", encoding="utf-8"):
        if ": foto de " in linea:
            n.add(linea.split(": foto de ")[0].strip())
    ## Solo nombres completos (con espacio y largos): «Pedro» o «Vinícius» solos son nombres de pila corrientes.
    return sorted(x for x in n if " " in x and len(x) >= 9)


def revisar(preset: str, reales: re.Pattern, tmp: str) -> int:
    salida = os.path.join(tmp, preset + ".zip")
    r = subprocess.run(["godot", "--headless", "--path", ".", "--export-pack", preset, salida],
                       capture_output=True, text=True, timeout=900)
    if not os.path.exists(salida):
        print("  FALLO %s: no se pudo exportar (%s)" % (preset, r.stdout[-300:].strip()))
        return 1
    fallos = 0
    with zipfile.ZipFile(salida) as z:
        nombres = z.namelist()
        malos = [x for x in nombres if PROHIBIDOS.search(x) and not x.startswith(".godot/")]
        for x in malos[:10]:
            print("  FALLO %s: viaja %s" % (preset, x))
        fallos += len(malos)
        vistos = {}
        for x in nombres:
            if not x.endswith(TEXTO):
                continue
            texto = z.read(x).decode("utf-8", "ignore")
            for m in reales.finditer(texto):
                vistos.setdefault(m.group(0), x)
        for nom, donde in list(vistos.items())[:10]:
            print("  FALLO %s: el nombre real «%s» está en %s" % (preset, nom, donde))
        fallos += len(vistos)
    print("  %s %s: %d archivos, %d nombres reales encontrados" % ("ok   " if fallos == 0 else "FALLO", preset,
                                                                  len(nombres), len(vistos)))
    os.remove(salida)
    return fallos


def main() -> None:
    lista = nombres_reales()
    reales = re.compile(r"(?<!\w)(" + "|".join(re.escape(x) for x in lista) + r")(?!\w)")
    print("Builds públicos: %s · %d nombres reales a buscar" % (", ".join(PRESETS), len(lista)))
    fallos = 0
    with tempfile.TemporaryDirectory() as tmp:
        for p in PRESETS:
            fallos += revisar(p, reales, tmp)
    print("FIN BUILD PÚBLICO. %d fallos" % fallos)


main()
