#!/usr/bin/env python3
"""TABLA prueba × sistema (5-11-2026) para el resumen del CI de plataformas. Lee los registros de `pruebas_so.py` (una línea
«OK|FALLO <nombre> <n> s …») o los marcadores del juego («OK|FALLO <nombre> [<sistema>]») y escribe una tabla Markdown.

  python3 herramientas/tabla_so.py windows=registro_windows.txt web=registro_web.txt linux=registro_linux.txt
Cada argumento es «sistema=archivo». Sin esos archivos o sin la prueba en un sistema, la celda queda «—» (no corrió o no aplica).
Código de salida 1 si alguna celda es FALLO.
"""
import os, re, sys

LISTA = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "pruebas", "so", "LISTA.txt")


def nombres():
    return [l.split("|")[0].strip() for l in open(LISTA, encoding="utf-8") if l.strip() and not l.startswith("#")]


def leer(ruta):
    res = {}
    txt = re.sub(r"\x1b\[[0-9;]*m", "", open(ruta, encoding="utf-8", errors="replace").read())
    for m in re.finditer(r"^(OK|FALLO)\s+(\w+)(?:\s+\[(\w+)\]|\s+\d+ s)", txt, re.M):
        res[m.group(2)] = m.group(1)   # el último gana (un reintento)
    return res


def main():
    cols = []
    for a in sys.argv[1:]:
        if "=" in a:
            sis, ruta = a.split("=", 1)
            cols.append((sis, leer(ruta) if os.path.exists(ruta) else {}))
    if not cols:
        print("uso: tabla_so.py sistema=archivo ...")
        return 2
    filas = nombres()
    print("| prueba | " + " | ".join(s for s, _ in cols) + " |")
    print("|---|" + "---|" * len(cols))
    malos = 0
    for n in filas:
        celdas = []
        for _, r in cols:
            v = r.get(n)
            malos += v == "FALLO"
            celdas.append({"OK": "✅", "FALLO": "❌"}.get(v, "—"))
        print("| %s | %s |" % (n, " | ".join(celdas)))
    tot = ["%s %d/%d" % (s, sum(v == "OK" for v in r.values()), len(filas)) for s, r in cols]
    print("\n**Total:** " + " · ".join(tot) + (" · ❌ hay fallos" if malos else ""))
    return 1 if malos else 0


if __name__ == "__main__":
    sys.exit(main())
