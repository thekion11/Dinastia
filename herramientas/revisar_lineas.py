#!/usr/bin/env python3
"""Revisa la norma de tamaño del código (23-10-2026) en TODO el juego.

  python3 herramientas/revisar_lineas.py            # resumen y los 25 mayores
  python3 herramientas/revisar_lineas.py --todos    # lista todos los que pasan del límite
  python3 herramientas/revisar_lineas.py --nuevos   # solo archivos añadidos/cambiados en la rama (código 1 si alguno pasa)

Norma (23-10, decidida por el dueño): ningún script pasa de 450 líneas, ni nuevo ni existente.
Excepción declarada (EXCEPCIONES): el archivo que genera una herramienta (se parte en el generador).
"""
import subprocess, sys

LIM_NUEVO = 450
LIM_FINAL = 450
EXCEPCIONES = {"dinastia-godot/nucleo/dialogos_ciudad.gd"}  # lo genera herramientas/dialogos_ciudad.py

def archivos(solo_nuevos):
    if solo_nuevos:
        out = subprocess.check_output(["git", "diff", "--name-only", "--diff-filter=AM", "origin/main...HEAD"]).decode()
    else:
        out = subprocess.check_output(["git", "ls-files", "*.gd"]).decode()
    return [f for f in out.split("\n") if f.endswith(".gd") and f not in EXCEPCIONES]

def lineas(f):
    try:
        return sum(1 for _ in open(f, encoding="utf-8", errors="ignore"))
    except OSError:
        return 0

def lineas_en_main(f):
    r = subprocess.run(["git", "show", f"origin/main:{f}"], capture_output=True)
    return None if r.returncode else r.stdout.count(b"\n")

def main():
    nuevos = "--nuevos" in sys.argv
    datos = sorted(((lineas(f), f) for f in archivos(nuevos)), reverse=True)
    if nuevos:
        ## Falla si un archivo nuevo pasa del límite o si uno grande CRECE.
        malos = []
        for n, f in datos:
            antes = lineas_en_main(f)
            if n > LIM_NUEVO and (antes is None or n > antes):
                malos.append((n, f, antes))
        for n, f, antes in malos:
            print(f"{n:6d}  {f}  ({'nuevo' if antes is None else 'crece desde %d' % antes}; límite {LIM_NUEVO})")
        sys.exit(1 if malos else 0)
    p600 = [d for d in datos if d[0] > LIM_NUEVO]
    p1500 = [d for d in datos if d[0] > LIM_FINAL]
    print(f"{len(datos)} scripts, {sum(n for n, _ in datos)} líneas")
    print(f"pasan de {LIM_NUEVO} líneas: {len(p600)}")
    for n, f in (p600 if "--todos" in sys.argv else datos[:25]):
        print(f"{n:6d}  {f}")

if __name__ == "__main__":
    main()
