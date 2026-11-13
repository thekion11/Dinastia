#!/usr/bin/env python3
"""CAZA DE PRUEBAS FRÁGILES (5/6-11-2026). Corre cada prueba especial varias veces y lista las que CAMBIAN de resultado:
  (a) en limpio: cada ejecución con su carpeta `user://` vacía (como el CI);
  (b) con CARGA de CPU: 2×nproc bucles ocupando la máquina mientras corre (lo que hace fallar a las que cuentan fotogramas o esperan un tiempo);
  (c) con la carpeta SUCIA (--sucia): las pruebas de su parte corren una detrás de otra compartiendo la MISMA carpeta `user://` y el resultado se compara con el aislado
      (detecta pruebas que dependen de que alguien deje, o no deje, guardados/ajustes).
Una prueba es FRÁGIL si su resultado (OK/FALLO) no es el mismo en todas las ejecuciones o difiere entre modos.

  python3 herramientas/cazar_fragiles.py --parte 2/6 -n 3            # la parte 2 del reparto del CI, 3 veces en limpio y 3 con carga
  python3 herramientas/cazar_fragiles.py "tráfico" "p6_" -n 5         # las que contengan esos textos (regex)
  python3 herramientas/cazar_fragiles.py --parte 0/6 --sucia          # comparar sucia contra aislada
  --sin-carga | --solo-carga   limita los modos · -j N pruebas a la vez (por defecto 1: la carga ya satura la máquina) · --max M  solo las M primeras
Salida: una línea por prueba (OK=todas bien, FRÁGIL=cambia, FALLA=siempre falla) y, al final, un resumen. No desactiva ni toca ninguna prueba.
"""
import os, re, shutil, subprocess, sys, tempfile

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "herramientas"))
import bancos_especiales as be


def cargar_maquina(procesos):
    """2×nproc bucles ocupados. Devuelve la función que los para."""
    ps = [subprocess.Popen([sys.executable, "-c", "while True: pass"]) for _ in range(procesos)]
    return lambda: [p.kill() for p in ps]


def correr(cmd, patron, xdg):
    env = dict(os.environ, XDG_DATA_HOME=xdg)
    try:
        p = subprocess.run(["bash", "-c", "timeout 600 bash -c '%s'" % cmd.replace("'", "'\\''")], cwd=RAIZ, env=env, capture_output=True, text=True, errors="replace", timeout=700)
        sal = re.sub(r"\x1b\[[0-9;]*m", "", p.stdout + p.stderr)
    except subprocess.TimeoutExpired:
        return "FALLO", "tiempo agotado"
    if "SCRIPT ERROR" in sal or not re.search(patron, sal):
        det = [l.strip()[:110] for l in sal.splitlines() if "FALLO" in l or "SCRIPT ERROR" in l][:2]
        return "FALLO", " | ".join(det)
    return "OK", ""


def elegir(args):
    todas = be.especiales()
    parte = None
    if "--parte" in args:
        parte = args[args.index("--parte") + 1]
    filtros = [a for a in args if not a.startswith("-") and a != parte and not a.isdigit()]
    if parte:
        i, n = (int(x) for x in parte.split("/"))
        mapa = {}
        ruta = os.path.join(RAIZ, "herramientas", "especiales_reparto.txt")
        if os.path.exists(ruta):
            for l in open(ruta, encoding="utf-8"):
                if not l.startswith("#"):
                    p, _, nombre = l.rstrip("\n").split("\t", 2)
                    mapa[nombre] = int(p)
        todas = [t for k, t in enumerate(todas) if mapa.get(t[0], k % n) == i]
    if filtros:
        todas = [t for t in todas if any(re.search(f, t[0], re.I) for f in filtros)]
    return todas


def main():
    a = sys.argv[1:]
    n = int(a[a.index("-n") + 1]) if "-n" in a else 3
    maximo = int(a[a.index("--max") + 1]) if "--max" in a else 10**9
    lista = elegir([x for x in a if x not in ("-n", "--max") and not (x.isdigit() and a[a.index(x) - 1] in ("-n", "--max", "-j"))])[:maximo]
    modos = [] if "--solo-carga" in a else ["limpio"]
    if "--sin-carga" not in a:
        modos.append("carga")
    sucia = "--sucia" in a
    nproc = os.cpu_count() or 2
    print("%d pruebas · %d ejecuciones por modo · modos %s%s" % (len(lista), n, modos, " + sucia" if sucia else ""), flush=True)
    frag = fall = 0
    carpeta_sucia = tempfile.mkdtemp() if sucia else None
    for nombre, cmd, patron in lista:
        res = {}
        det = ""
        for modo in modos:
            parar = cargar_maquina(2 * nproc) if modo == "carga" else None
            try:
                for _ in range(n):
                    xdg = tempfile.mkdtemp()
                    r, d = correr(cmd, patron, xdg)
                    shutil.rmtree(xdg, ignore_errors=True)
                    res.setdefault(modo, []).append(r)
                    det = det or d
            finally:
                if parar:
                    parar()
        if sucia:
            r, d = correr(cmd, patron, carpeta_sucia)
            res["sucia"] = [r]
            det = det or d
        todos = {x for v in res.values() for x in v}
        if todos == {"OK"}:
            est = "OK"
        elif todos == {"FALLO"}:
            est = "FALLA"
            fall += 1
        else:
            est = "FRÁGIL"
            frag += 1
        resumen = " ".join("%s=%s" % (m, "".join("." if x == "OK" else "X" for x in v)) for m, v in res.items())
        print("%-7s %-60s %s %s" % (est, nombre[:60], resumen, det if est != "OK" else ""), flush=True)
    if carpeta_sucia:
        shutil.rmtree(carpeta_sucia, ignore_errors=True)
    print("CAZA: %d examinadas, %d frágiles, %d fallan siempre" % (len(lista), frag, fall))
    return 1 if frag else 0


if __name__ == "__main__":
    sys.exit(main())
