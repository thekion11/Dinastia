#!/usr/bin/env python3
"""COBERTURA DE LÍNEAS de GDScript (18-11-2026). Godot 4.7.2 no la trae, así que se instrumenta el código:

  python3 herramientas/cobertura_lineas.py instrumentar DIR [DIR…]  # inserta `CobLineas.p[N] = 1` antes de cada sentencia de cada `func`
                                                                    # y escribe pruebas/cob_lineas.gd + <TMP>/cob_manifiesto.json
  python3 herramientas/cobertura_lineas.py informe VOLCADO…         # une los volcados (bytes) y escribe docs/04_auditorias/cobertura_lineas_AAAA-MM-DD.md

NO se usa a mano: lo lanza `herramientas/cobertura_lineas.sh`, que restaura el código con git al terminar. Las sentencias que no se
instrumentan (para no romper la sintaxis): lo que está dentro de paréntesis/corchetes/llaves o tras `\\`, `elif`/`else`, los brazos de `match`,
y las funciones de una sola línea. Esas líneas no cuentan ni a favor ni en contra.
"""
import datetime
import json
import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TMP = os.environ.get("COB_TMP", "/tmp/cobertura_lineas")
MANIFIESTO = os.path.join(TMP, "cob_manifiesto.json")
SALTAR = ("elif ", "elif(", "else:", "else ", "func ", "static func ", "class ", "signal ", "enum ", "@", "#", "extends ", "class_name ")


def pelar(linea, en_triple):
    """Devuelve (texto sin cadenas ni comentario, sigue_en_triple)."""
    out = []
    i = 0
    n = len(linea)
    while i < n:
        if en_triple:
            j = linea.find('"""', i)
            if j < 0:
                return "".join(out), True
            i = j + 3
            en_triple = False
            continue
        c = linea[i]
        if linea.startswith('"""', i):
            en_triple = True
            i += 3
            continue
        if c in "\"'":
            q = c
            i += 1
            while i < n and linea[i] != q:
                i += 2 if linea[i] == "\\" else 1
            i += 1
            continue
        if c == "#":
            break
        out.append(c)
        i += 1
    return "".join(out), en_triple


def instrumentar_archivo(ruta, siguiente):
    """Devuelve (texto nuevo, [(idx, linea_original)])."""
    with open(ruta, encoding="utf-8") as f:
        lineas = f.read().split("\n")
    salida = []
    puntos = []
    en_triple = False
    prof = 0
    continua = False
    func_indent = None
    matches = []  # [indent_del_match, indent_de_los_brazos|None]
    for k, linea in enumerate(lineas):
        s = linea.strip()
        indent = len(linea) - len(linea.lstrip("\t"))
        inicio_ok = (not en_triple) and prof == 0 and not continua and s != ""
        if inicio_ok and not s.startswith("#"):
            while func_indent is not None and indent <= func_indent:
                func_indent = None
            while matches and indent <= matches[-1][0]:
                matches.pop()
            es_brazo = False
            if matches:
                if matches[-1][1] is None and indent > matches[-1][0]:
                    matches[-1][1] = indent
                es_brazo = indent == matches[-1][1]
            if s.startswith(("func ", "static func ")):
                func_indent = indent
            elif func_indent is not None and indent > func_indent and not es_brazo and not s.startswith(SALTAR):
                # una sola línea `func f(): …` ya se descartó arriba; aquí solo cuerpos con sangría
                idx = siguiente()
                salida.append("%sCobLineas.p[%d] = 1" % ("\t" * indent, idx))
                puntos.append((idx, k + 1))
            if s.startswith("match ") and s.rstrip().endswith(":"):
                matches.append([indent, None])
        salida.append(linea)
        txt, en_triple = pelar(linea, en_triple)
        for c in txt:
            if c in "([{":
                prof += 1
            elif c in ")]}":
                prof = max(0, prof - 1)
        continua = txt.rstrip().endswith("\\")
    return "\n".join(salida), puntos


def instrumentar(dirs):
    os.makedirs(TMP, exist_ok=True)
    cont = [0]

    def siguiente():
        cont[0] += 1
        return cont[0] - 1

    man = {}
    for d in dirs:
        base = os.path.join(RAIZ, d)
        for raiz, _ds, fs in os.walk(base):
            for f in sorted(fs):
                if not f.endswith(".gd"):
                    continue
                ruta = os.path.join(raiz, f)
                texto, puntos = instrumentar_archivo(ruta, siguiente)
                if not puntos:
                    continue
                with open(ruta, "w", encoding="utf-8", newline="\n") as o:
                    o.write(texto)
                man[os.path.relpath(ruta, RAIZ).replace(os.sep, "/")] = puntos
    total = cont[0]
    gd = ('class_name CobLineas\nextends RefCounted\n## GENERADO por herramientas/cobertura_lineas.py; no se sube.\n'
          'static var p := PackedByteArray()\n\n'
          'static func _static_init() -> void:\n\tp.resize(%d)\n\n'
          'static func volcar() -> void:\n'
          '\tvar ruta := OS.get_environment("COB_SALIDA")\n\tif ruta == "":\n\t\treturn\n'
          '\tvar f := FileAccess.open("%%s.%%d" %% [ruta, OS.get_process_id()], FileAccess.WRITE)\n'
          '\tif f != null:\n\t\tf.store_buffer(p)\n\t\tf.close()\n' % max(total, 1))
    with open(os.path.join(RAIZ, "pruebas", "cob_lineas.gd"), "w", encoding="utf-8", newline="\n") as o:
        o.write(gd)
    with open(MANIFIESTO, "w", encoding="utf-8") as o:
        json.dump({"total": total, "archivos": man}, o)
    print("instrumentadas %d sentencias en %d archivos" % (total, len(man)))


def informe(volcados):
    with open(MANIFIESTO, encoding="utf-8") as f:
        m = json.load(f)
    tot = m["total"]
    vistos = bytearray(tot)
    for v in volcados:
        with open(v, "rb") as f:
            b = f.read()
        for i in range(min(tot, len(b))):
            if b[i]:
                vistos[i] = 1
    filas = []
    for arch, puntos in m["archivos"].items():
        n = len(puntos)
        c = sum(1 for idx, _l in puntos if vistos[idx])
        sin = [l for idx, l in puntos if not vistos[idx]]
        filas.append((arch, n, c, sin))
    n_t = sum(f[1] for f in filas)
    c_t = sum(f[2] for f in filas)
    sal = ["# Cobertura de LÍNEAS (banco completo) — %s\n" % datetime.date.today().isoformat(),
           "Generado por `herramientas/cobertura_lineas.sh` (instrumenta, corre el banco, restaura con git). Cuenta sentencias dentro de funciones; "
           "no cuenta las de varias líneas dentro de paréntesis, `elif`/`else`, brazos de `match` ni funciones de una línea. "
           "Solo lo que ejecuta el BANCO (no las especiales con pantalla).\n",
           "**Total: %d de %d sentencias ejecutadas (%.1f %%)** en %d archivos.\n" % (c_t, n_t, 100.0 * c_t / max(n_t, 1), len(filas)),
           "## Los 30 archivos con más sentencias sin ejecutar\n", "| archivo | sentencias | ejecutadas | % | primeras líneas sin ejecutar |", "|---|---|---|---|---|"]
    for a, n, c, sin in sorted(filas, key=lambda f: -(f[1] - f[2]))[:30]:
        sal.append("| `%s` | %d | %d | %.0f %% | %s |" % (a, n, c, 100.0 * c / n, ", ".join(str(x) for x in sin[:8])))
    sal.append("\n## Todos los archivos\n\n| archivo | sentencias | % |\n|---|---|---|")
    for a, n, c, _s in sorted(filas):
        sal.append("| `%s` | %d | %.0f %% |" % (a, n, 100.0 * c / n))
    destino = os.path.join(RAIZ, "..", "docs", "04_auditorias", "cobertura_lineas_%s.md" % datetime.date.today().isoformat())
    with open(destino, "w", encoding="utf-8") as o:
        o.write("\n".join(sal) + "\n")
    print("TOTAL %d/%d = %.1f %% -> %s" % (c_t, n_t, 100.0 * c_t / max(n_t, 1), os.path.normpath(destino)))


if __name__ == "__main__":
    if len(sys.argv) >= 3 and sys.argv[1] == "instrumentar":
        instrumentar(sys.argv[2:])
    elif len(sys.argv) >= 3 and sys.argv[1] == "informe":
        informe(sys.argv[2:])
    else:
        print(__doc__)
        sys.exit(2)
