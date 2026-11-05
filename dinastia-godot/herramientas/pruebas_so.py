#!/usr/bin/env python3
"""PRUEBAS POR SISTEMA (5-11-2026). Corre el subconjunto de `pruebas/so/LISTA.txt` en el sistema donde está (Linux, Windows, macOS;
Web y Android las ejecuta el CI de plataformas con el mismo marcador). Cada prueba imprime «OK|FALLO <nombre> [<sistema>]».

  python3 herramientas/pruebas_so.py --lista                  # las pruebas, su familia y sistemas
  python3 herramientas/pruebas_so.py                          # todas las que aplican a este sistema (en paralelo con -j N)
  python3 herramientas/pruebas_so.py --familia errores        # una familia: comunes estandar errores integracion visualizacion funciones rendimiento
  python3 herramientas/pruebas_so.py com_idiomas_nueve_sin_vacios   # una sola
  python3 herramientas/pruebas_so.py --crear                  # crea las escenas .tscn que falten (dos líneas)
  python3 herramientas/pruebas_so.py --sistema web --lista    # qué correría en Web (para el CI de plataformas)
  python3 herramientas/pruebas_so.py --requiere headless      # solo las que no necesitan pantalla (CI de plataformas: Windows sin GPU)
  python3 herramientas/pruebas_so.py --sincronia              # LISTA.txt y especiales.sh dicen lo mismo
  python3 herramientas/pruebas_so.py --marcadores < salida.txt  # revisa un registro y dice qué falló o falta por sistema

LISTA.txt: nombre|familia|sistemas|escena|requiere     (sistemas: «todos» o lista con comas; requiere: headless | pantalla | vulkan (Forward+) | compat (OpenGL) | hw (hw_modesto.sh))
Variables: GODOT (ejecutable; por defecto «godot»). Sin separadores de ruta propios: todo con os.path.
"""
import concurrent.futures, os, re, shutil, subprocess, sys, tempfile, threading, time

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LISTA = os.path.join(RAIZ, "pruebas", "so", "LISTA.txt")
FAMILIAS = ["comunes", "estandar", "errores", "integracion", "visualizacion", "funciones", "rendimiento"]


def sistema_actual():
    return {"linux": "linux", "win32": "windows", "darwin": "macos"}.get(sys.platform, sys.platform)


def leer():
    filas = []
    for l in open(LISTA, encoding="utf-8"):
        l = l.strip()
        if not l or l.startswith("#"):
            continue
        n, fam, sis, esc, req = [x.strip() for x in l.split("|")]
        filas.append(dict(nombre=n, familia=fam, sistemas=set(sis.split(",")), escena=esc, requiere=req))
    return filas


def aplica(f, sis):
    return "todos" in f["sistemas"] or sis in f["sistemas"]


def crear_escenas(filas):
    for f in filas:
        ruta = os.path.join(RAIZ, f["escena"].replace("res://", ""))
        gd = ruta[:-5] + ".gd"
        if not os.path.exists(gd):
            print("FALTA el script", gd)
            continue
        if not os.path.exists(ruta):
            rel = f["escena"][:-5] + ".gd"
            open(ruta, "w", encoding="utf-8", newline="\n").write(
                '[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="%s" id="1"]\n\n[node name="T" type="Node"]\nscript = ExtResource("1")\n' % rel)
            print("creada", ruta)


def correr(f, sis, godot):
    t0 = time.time()
    env = dict(os.environ)
    env["XDG_DATA_HOME"] = tempfile.mkdtemp()   # user:// propio, como en el CI
    cmd = [godot, "--headless", "--path", RAIZ, f["escena"]]
    if f["requiere"] in ("pantalla", "vulkan", "compat", "hw"):
        if f["requiere"] in ("vulkan", "hw") and sis == "linux" and not os.path.isdir("/usr/share/vulkan/icd.d"):
            return f, "FALLO", "requiere Vulkan (lavapipe: apt-get install mesa-vulkan-drivers) y no está", time.time() - t0
        res = os.environ.get("RESOLUCION", "960x540")
        motor = {"vulkan": ["--rendering-driver", "vulkan", "--rendering-method", "forward_plus"], "hw": ["--rendering-driver", "vulkan", "--rendering-method", "forward_plus"],
                 "compat": ["--rendering-driver", "opengl3"]}.get(f["requiere"], [])
        cmd = [godot, "--path", RAIZ] + motor + ["--resolution", res, f["escena"]]
        if f["requiere"] == "hw" and sis == "linux":
            cmd = ["bash", os.path.join(RAIZ, "herramientas", "hw_modesto.sh"), f["escena"]]
            env["HW_DRIVER"] = "opengl3"   # el equipo modesto usa Compatibilidad; Forward+ pasa de los 4 GB del cgroup y lo mata el sistema
        elif sis == "linux" and shutil.which("xvfb-run"):
            cmd = ["xvfb-run", "-a", "-s", "-screen 0 1920x1080x24"] + cmd
    tope = int(os.environ.get("PRUEBA_SO_TOPE", "300"))
    kw = {"start_new_session": True} if os.name != "nt" else {}
    proc = subprocess.Popen(cmd, cwd=RAIZ, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, env=env, encoding="utf-8", errors="replace", **kw)
    lineas = []

    def leer():
        for l in proc.stdout:
            lineas.append(l)
    hilo = threading.Thread(target=leer, daemon=True)
    hilo.start()
    motivo = ""
    while proc.poll() is None:
        time.sleep(0.5)
        # Un script que no compila no llega a abrir la escena y nunca termina: se corta en cuanto aparece el error.
        if any("Failed to load script" in l or "Parse Error" in l for l in lineas[-60:]):
            motivo = "el script no compila"
        elif time.time() - t0 > tope:
            motivo = "tiempo agotado (%d s)" % tope
        if motivo:
            if os.name != "nt":
                os.killpg(proc.pid, 9)   # también los hijos (xvfb-run → godot): si no, siguen vivos
            else:
                proc.kill()
            break
    hilo.join(5)
    out = re.sub(r"\x1b\[[0-9;]*m", "", "".join(lineas))
    if motivo:
        det = [l for l in out.splitlines() if "SCRIPT ERROR" in l or "Parse Error" in l][:3]
        return f, "FALLO", motivo + " " + " | ".join(det), time.time() - t0
    shutil.rmtree(env["XDG_DATA_HOME"], ignore_errors=True)
    m = re.search(r"^(OK|FALLO) %s \[(\w+)\]" % re.escape(f["nombre"]), out, re.M)
    malo = "SCRIPT ERROR" in out
    if m and m.group(1) == "OK" and not malo:
        return f, "OK", m.group(0), time.time() - t0
    det = [l for l in out.splitlines() if "FALLO" in l or "SCRIPT ERROR" in l][:4]
    return f, "FALLO", " | ".join(det) or "sin marcador (¿error de sintaxis?)", time.time() - t0


def reimportar_si_hace_falta(godot):
    """Una clase nueva (class_name) no existe para Godot hasta reimportar (como mini_banco.sh, M-389)."""
    cache = os.path.join(RAIZ, ".godot", "global_script_class_cache.cfg")
    ultima = max((os.path.getmtime(os.path.join(d, f)) for c in ("nucleo", "ui", "visor", "pruebas") for d, _, fs in os.walk(os.path.join(RAIZ, c)) for f in fs if f.endswith(".gd")), default=0)
    if not os.path.exists(cache) or ultima > os.path.getmtime(cache):
        subprocess.run([godot, "--headless", "--import", "--path", RAIZ], capture_output=True, timeout=900)
        os.utime(cache, None) if os.path.exists(cache) else None


def revisar_marcadores(filas):
    """Lee el registro por la entrada estándar (`pruebas_so.py --marcadores < registro.txt`): así no se abre ninguna ruta dada por el usuario."""
    txt = sys.stdin.read()
    vistos = {}
    for m in re.finditer(r"^(OK|FALLO) (\w+) \[(\w+)\]", txt, re.M):
        vistos[(m.group(2), m.group(3))] = m.group(1)
    sistemas = sorted({s for (_, s) in vistos})
    mal = 0
    for f in filas:
        for s in sistemas:
            if not aplica(f, s):
                continue
            v = vistos.get((f["nombre"], s))
            if v != "OK":
                mal += 1
                print("%-8s %-40s [%s]" % (v or "FALTA", f["nombre"], s))
    print("marcadores: %d sistemas %s, %d con problema" % (len(sistemas), sistemas, mal))
    return 1 if mal else 0


def main():
    a = sys.argv[1:]
    filas = leer()
    sis = sistema_actual()
    fam = None
    jobs = 2
    if "--sistema" in a:
        sis = a[a.index("--sistema") + 1]
    if "--familia" in a:
        fam = a[a.index("--familia") + 1]
    req = a[a.index("--requiere") + 1] if "--requiere" in a else None
    if "-j" in a:
        jobs = int(a[a.index("-j") + 1])
    if "--crear" in a:
        crear_escenas(filas)
        return 0
    if "--sincronia" in a:
        sh = open(os.path.join(RAIZ, "herramientas", "especiales.sh"), encoding="utf-8").read()
        mal = [f["nombre"] for f in filas if aplica(f, "linux") and ('"so: %s"' % f["nombre"]) not in sh]
        sobran = [n for n in re.findall(r'pasa "so: (\w+)"', sh) if n not in {f["nombre"] for f in filas}]
        sin_escena = [f["nombre"] for f in filas if not os.path.exists(os.path.join(RAIZ, f["escena"].replace("res://", "")))]
        print("sincronía LISTA.txt ↔ especiales.sh: faltan en especiales.sh %s · sobran %s · sin escena %s" % (mal, sobran, sin_escena))
        return 1 if (mal or sobran or sin_escena) else 0
    if "--marcadores" in a:
        return revisar_marcadores(filas)
    nombres = [x for x in a if x in {f["nombre"] for f in filas}]
    sel = [f for f in filas if aplica(f, sis) and (not fam or f["familia"] == fam) and (not nombres or f["nombre"] in nombres) and (not req or f["requiere"] == req)]
    if "--lista" in a:
        for f in sel:
            print("%-14s %-42s %-22s %s" % (f["familia"], f["nombre"], ",".join(sorted(f["sistemas"])), f["requiere"]))
        print("%d pruebas para %s" % (len(sel), sis))
        return 0
    godot = os.environ.get("GODOT", "godot")
    crear_escenas(filas)
    reimportar_si_hace_falta(godot)
    fallos = 0
    with concurrent.futures.ThreadPoolExecutor(jobs) as ex:
        for f, est, det, seg in ex.map(lambda x: correr(x, sis, godot), sel):
            fallos += est != "OK"
            print("%-6s %-42s %3d s  %s" % (est, f["nombre"], seg, "" if est == "OK" else det))
    print("PRUEBAS POR SISTEMA [%s]: %d pruebas, %d fallos" % (sis, len(sel), fallos))
    return 1 if fallos else 0


if __name__ == "__main__":
    sys.exit(main())
