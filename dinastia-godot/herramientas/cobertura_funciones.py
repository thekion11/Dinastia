#!/usr/bin/env python3
"""COBERTURA POR FUNCIONES de `nucleo/` (6-11-2026). Godot 4.7.2 no trae cobertura de líneas para GDScript (no hay `--coverage` en `godot --help`) y no se ha verificado
ninguna herramienta de terceros que la dé, así que se mide lo que sí se puede de forma estática y repetible: de cada función de `nucleo/*.gd`, ¿su NOMBRE aparece en alguna
prueba de `pruebas/`? («mencionada» ≠ «bien comprobada», pero una función que ninguna prueba nombra seguro que no está comprobada.)

  python3 herramientas/cobertura_funciones.py                 # resumen y las 15 peores
  python3 herramientas/cobertura_funciones.py --escribir      # además escribe docs/04_auditorias/cobertura_funciones_AAAA-MM-DD.md
No cuenta las funciones privadas (`_x`), las del motor (`_ready`…), ni las que son meros ganchos de señales.
"""
import datetime, glob, os, re, sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FUNC = re.compile(r"^(?:static )?func ([a-z][A-Za-z0-9_]*)\(", re.M)


def leer(r):
    with open(r, encoding="utf-8", errors="replace") as f:
        return f.read()


def main():
    pruebas = "\n".join(leer(g) for g in glob.glob(os.path.join(RAIZ, "pruebas", "**", "*.gd"), recursive=True))
    nombres_en_pruebas = set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", pruebas))
    filas = []
    for g in sorted(glob.glob(os.path.join(RAIZ, "nucleo", "*.gd"))):
        fs = set(FUNC.findall(leer(g)))
        if not fs:
            continue
        cub = {f for f in fs if f in nombres_en_pruebas}
        filas.append((os.path.relpath(g, RAIZ).replace("\\", "/"), len(fs), len(cub), sorted(fs - cub)))
    tot = sum(f[1] for f in filas)
    cub = sum(f[2] for f in filas)
    sal = ["# Cobertura por funciones de `nucleo/` — %s\n" % datetime.date.today().isoformat(),
           "Generado por `herramientas/cobertura_funciones.py --escribir`. **No es cobertura de líneas** (Godot 4.7.2 no la ofrece para GDScript): mide qué funciones públicas de `nucleo/` "
           "tienen su nombre en alguna prueba. Una función que ninguna prueba nombra seguro que no está comprobada; una nombrada puede estarlo mal.\n",
           "**Total: %d de %d funciones públicas nombradas por alguna prueba (%.0f %%)** en %d archivos.\n" % (cub, tot, 100.0 * cub / max(tot, 1), len(filas)),
           "## Los 25 archivos con más funciones sin nombrar\n", "| archivo | funciones | nombradas | % | sin nombrar (hasta 6) |", "|---|---|---|---|---|"]
    for a, n, c, sin in sorted(filas, key=lambda f: -(f[1] - f[2]))[:25]:
        sal.append("| `%s` | %d | %d | %.0f %% | %s |" % (a, n, c, 100.0 * c / n, ", ".join("`%s`" % s for s in sin[:6])))
    sal.append("\n## Todos los archivos\n\n| archivo | funciones | % |\n|---|---|---|")
    for a, n, c, _ in sorted(filas, key=lambda f: (f[2] / f[1], f[0])):
        sal.append("| `%s` | %d | %.0f %% |" % (a, n, 100.0 * c / n))
    texto = "\n".join(sal) + "\n"
    print("\n".join(sal[:3]))
    for a, n, c, sin in sorted(filas, key=lambda f: -(f[1] - f[2]))[:15]:
        print("%-38s %3d funciones, %3d nombradas (%.0f %%)" % (a, n, c, 100.0 * c / n))
    if "--escribir" in sys.argv:
        ruta = os.path.join(RAIZ, "..", "docs", "04_auditorias", "cobertura_funciones_%s.md" % datetime.date.today().isoformat())
        with open(ruta, "w", encoding="utf-8", newline="\n") as f:
            f.write(texto)
        print("escrito", os.path.normpath(ruta))


if __name__ == "__main__":
    main()
