#!/usr/bin/env python3
"""REPARTO DE LAS ESPECIALES POR TIEMPO MEDIDO (5-11-2026). Lee los registros del CI (`### ⚪ Pruebas especiales, parte i/N`: una línea «OK|FALLO nombre N s»
por prueba) y reparte las pruebas entre N partes con el algoritmo «la más larga a la parte menos cargada» (LPT). Escribe `herramientas/especiales_reparto.txt`:
una línea `parte<TAB>segundos<TAB>nombre` por prueba, y `# N=<partes>` arriba. `especiales.sh` lo usa si ESPECIALES_PARTE="i/N" tiene esa N; una prueba que no esté
en el archivo (nueva) cae en el reparto por turnos de siempre.

  python3 herramientas/repartir_especiales.py registro0.txt registro1.txt ...     # tantas partes como se quiera con --partes N (por defecto 6)
Los registros pueden ser el log completo del job (con marcas de tiempo al principio de cada línea) o el artefacto `especiales-registro-N`.
"""
import os, re, sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SALIDA = os.path.join(RAIZ, "herramientas", "especiales_reparto.txt")
LINEA = re.compile(r"^(?:\S+Z )?(?:OK|FALLO)\s+(.+?)\s+(\d+) s\s*$")


def leer(rutas):
    t = {}
    for r in rutas:
        with open(r, encoding="utf-8", errors="replace") as f:
            for l in f:
                m = LINEA.match(l.rstrip("\n"))
                if m:
                    t[m.group(1).strip()] = max(int(m.group(2)), t.get(m.group(1).strip(), 0))
    return t


def repartir(tiempos, n):
    partes = [[0, []] for _ in range(n)]
    for nombre, seg in sorted(tiempos.items(), key=lambda kv: (-kv[1], kv[0])):
        p = min(range(n), key=lambda i: (partes[i][0], i))
        partes[p][0] += max(seg, 1)
        partes[p][1].append((nombre, seg))
    return partes


def main():
    a = sys.argv[1:]
    n = 6
    if "--partes" in a:
        i = a.index("--partes")
        n = int(a[i + 1])
        del a[i:i + 2]
    t = leer(a)
    if not t:
        print("sin pruebas en los registros")
        return 1
    partes = repartir(t, n)
    with open(SALIDA, "w", encoding="utf-8", newline="\n") as f:
        f.write("# N=%d  (generado por herramientas/repartir_especiales.py a partir de los registros del CI; parte<TAB>segundos<TAB>nombre)\n" % n)
        for i, (_, lista) in enumerate(partes):
            for nombre, seg in lista:
                f.write("%d\t%d\t%s\n" % (i, seg, nombre))
    print("%d pruebas en %d partes (minutos de pruebas por parte): %s" % (len(t), n, " ".join("%.1f" % (p[0] / 60.0) for p in partes)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
