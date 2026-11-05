#!/usr/bin/env python3
"""Valida las rutas que reciben las herramientas por línea de comandos o desde archivos de datos.

Canoniza la ruta (`os.path.realpath`: resuelve «..» y enlaces) y exige que quede dentro de un directorio permitido:
  - el directorio desde el que se lanza la herramienta,
  - la raíz del repositorio,
  - el directorio temporal del sistema,
  - los que se listen en la variable de entorno DINASTIA_RUTAS_PERMITIDAS (separados por `os.pathsep`; p. ej. la
    carpeta del Drive con los datos de origen).
Si no, lanza ValueError. Es la mitigación estándar contra «path traversal» (SonarCloud S8707 / S2083 / S6549).

    from ruta_segura import ruta_segura
    with open(ruta_segura(sys.argv[1])) as f: ...
"""
import os
import tempfile

RAIZ_REPO = os.path.realpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))


def _bases():
    bases = [os.path.realpath(os.getcwd()), RAIZ_REPO, os.path.realpath(tempfile.gettempdir())]
    for extra in os.environ.get("DINASTIA_RUTAS_PERMITIDAS", "").split(os.pathsep):
        if extra:
            bases.append(os.path.realpath(extra))
    return bases


def ruta_segura(ruta):
    """Devuelve la ruta canónica (str) si está dentro de un directorio permitido; si no, ValueError."""
    resuelta = os.path.realpath(os.fspath(ruta))
    for base in _bases():
        if resuelta == base or resuelta.startswith(base + os.sep):
            return resuelta
    raise ValueError(f"la ruta {str(ruta)!r} queda fuera de los directorios permitidos (ver DINASTIA_RUTAS_PERMITIDAS)")
