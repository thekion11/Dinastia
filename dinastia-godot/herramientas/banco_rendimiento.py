#!/usr/bin/env python3
"""BANCO EXTRA DE RENDIMIENTO (3-11-2026, pedido del dueño: «además de los 30 nuevos, un banco de rendimiento»).

Junta en un solo sitio las mediciones de rendimiento que antes vivían sueltas y las compara con topes guardados en
`herramientas/banco_rendimiento.json`: si algo EMPEORA más de lo permitido, falla. Cada sección es un módulo que se puede
correr sola. Sin GPU (llvmpipe) los FPS y los milisegundos de dibujo no valen: se comparan llamadas de dibujo, triángulos,
memoria, nodos y tiempos de CPU (carga, apertura de pantallas, guardado), que sí son comparables entre versiones.

  python3 herramientas/banco_rendimiento.py                 # todas las secciones (~10 min)
  python3 herramientas/banco_rendimiento.py partido_minima  # una o varias, por nombre
  python3 herramientas/banco_rendimiento.py --medir [...]   # mide y REESCRIBE los topes (valor actual + margen)
  python3 herramientas/banco_rendimiento.py --lista          # las secciones y qué miden

Salida: una tabla por sección (valor, tope, ok/FALLO) y al final «===== FIN. N fallos =====».
"""
import json, os, re, subprocess, sys, tempfile, shutil

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOPES = os.path.join(RAIZ, "herramientas", "banco_rendimiento.json")
XVFB = ["xvfb-run", "-a", "-s", "-screen 0 1280x720x24"]
GL = ["--rendering-driver", "opengl3", "--resolution", "1280x720"]


def correr(cmd, env_extra=None, timeout=900, cwd=None):
    env = dict(os.environ)
    env.update(env_extra or {})
    try:
        r = subprocess.run(cmd, cwd=cwd or RAIZ, env=env, capture_output=True, text=True, timeout=timeout)
        return r.stdout + r.stderr
    except subprocess.TimeoutExpired as e:
        return (e.stdout or "") + "\nTIEMPO AGOTADO"


def num(patron, texto, todos=False, grupo=1):
    m = re.findall(patron, texto)
    if not m:
        return None
    vals = [float(x[grupo - 1] if isinstance(x, tuple) else x) for x in m]
    return vals if todos else vals[-1]


# --- secciones: cada una devuelve {métrica: valor} -------------------------------------------------------------

def menu_memoria():
    """Memoria del menú con el .pck precompilado (como el juego exportado): al cargar la escena y en el primer fotograma."""
    pck = os.path.join(tempfile.gettempdir(), "banco_rend_menu.pck")
    mem = os.path.join(tempfile.gettempdir(), "banco_rend_mem.gd")
    shutil.copy(os.path.join(RAIZ, "..", "herramientas", "compilacion_menu", "mem3.gd.txt"), mem)
    correr(["godot", "--headless", "--path", RAIZ, "--export-pack", "Windows", pck], timeout=1200)
    out = correr(["godot", "--headless", "--main-pack", pck, "--script", mem], cwd=tempfile.gettempdir(), timeout=300)
    for f in (pck, mem):
        if os.path.exists(f):
            os.remove(f)
    return {"carga_escena_mb": num(r"tras load\(principal\.tscn\)\s+(\d+) MB", out),
            "primer_fotograma_mb": num(r"1er fotograma\s+(\d+) MB", out)}


def _arena(calidad):
    out = correr(XVFB + ["godot", "--path", RAIZ] + GL + ["res://pruebas/arena/arena.tscn"],
                 {"ARENA": "partido", "ESTADIO": "1", "CAMARAS": "1", "DURACION": "12", "CALIDAD": calidad, "SEMILLA": "7"})
    return {"llamadas": num(r"\n\s+llamadas\s+([\d.]+)", out), "triangulos": num(r"\n\s+triangulos\s+([\d.]+)", out),
            "objetos": num(r"\n\s+objetos\s+([\d.]+)", out), "vram_mb": num(r"\n\s+vram_mb\s+([\d.]+)", out)}


def partido_minima():
    """El partido entero (22 + árbitros + estadio) en calidad MÍNIMA, una cámara de TV: llamadas, triángulos, objetos y vídeo."""
    return _arena("minima")


def partido_media():
    """Lo mismo en calidad MEDIA."""
    return _arena("media")


def prologo():
    """El prólogo en MÍNIMA sin render (CPU): tiempo de carga, cuadro más largo, memoria y nodos; y con render, llamadas."""
    cpu = correr(["godot", "--headless", "--path", RAIZ, "res://pruebas/medir_prologo.tscn"], {"CALIDAD": "minimo"})
    gl = correr(XVFB + ["godot", "--path", RAIZ] + GL + ["res://pruebas/medir_prologo.tscn"], {"CALIDAD": "minimo"}, timeout=1500)
    mems = num(r"mem_estatica\s+(\d+) MB", cpu, todos=True) or [None]
    nodos = num(r"nodos\s+(\d+)", cpu, todos=True) or [None]
    dib = [d for d in (num(r"dibujo\s+(\d+)", gl, todos=True) or []) if d > 0]
    return {"carga_ms": num(r"carga_prologo_ms (\d+)", cpu), "cuadro_largo_ms": num(r"cuadro más largo durante la carga: (\d+) ms", cpu),
            "mem_pico_mb": max(mems) if mems[0] is not None else None, "nodos_max": max(nodos) if nodos[0] is not None else None,
            "llamadas_max": max(dib) if dib else None}


def aperturas():
    """Cada pantalla del menú (134) se abre en menos del tope; se guarda la peor (sin GPU)."""
    out = correr(["godot", "--headless", "--path", RAIZ, "res://pruebas/recorrido_pantallas.tscn"], {"RECORRIDO_MS_MAX": "99999"})
    return {"peor_ms": num(r"la peor (\d+) ms", out), "pantallas": num(r"RECORRIDO: (\d+) pantallas", out)}


def guardado():
    """Guardar el mundo ENTERO: lo que bloquea el hilo principal (el resto va en segundo plano) y el total."""
    out = correr(["godot", "--headless", "--path", RAIZ, "res://pruebas/zz_medir_guardado.tscn"], {"PAISES": "TODOS"}, timeout=1200)
    return {"hilo_principal_ms": num(r"segundo plano #\d+: hilo principal (\d+) ms", out),
            "total_ms": num(r"segundo plano #\d+: hilo principal \d+ ms[^·]*· total (\d+) ms", out)}


def equipo_modesto():
    """El recorrido completo (menú, estadio con cámara de TV, ciudad) con límites de equipo modesto (presupuesto.sh)."""
    out = correr(["bash", "herramientas/presupuesto.sh"], timeout=1500)
    return {"fallos_presupuesto": num(r"FIN\. (\d+) fallos", out)}


SECCIONES = {"menu_memoria": menu_memoria, "partido_minima": partido_minima, "partido_media": partido_media,
             "prologo": prologo, "aperturas": aperturas, "guardado": guardado, "equipo_modesto": equipo_modesto}
## Margen al reescribir topes con --medir: lo que puede empeorar antes de fallar (las métricas de fallos, 0).
MARGEN = 1.10
SIN_MARGEN = {"fallos_presupuesto", "pantallas"}
## Métricas donde MÁS es mejor (no pueden bajar del tope): el número de pantallas recorridas.
MAYOR_MEJOR = {"pantallas"}


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    medir = "--medir" in sys.argv
    if "--lista" in sys.argv:
        for k, f in SECCIONES.items():
            print("%-16s %s" % (k, f.__doc__))
        return 0
    elegidas = args or list(SECCIONES)
    topes = json.load(open(TOPES, encoding="utf-8")) if os.path.exists(TOPES) else {}
    fallos = 0
    for nombre in elegidas:
        if nombre not in SECCIONES:
            print("FALLO sección desconocida: %s" % nombre)
            fallos += 1
            continue
        print("\n== %s — %s" % (nombre, SECCIONES[nombre].__doc__))
        vals = SECCIONES[nombre]()
        tope_s = topes.setdefault(nombre, {})
        for metrica, v in vals.items():
            if v is None:
                print("  FALLO %-22s sin medida (la prueba no imprimió el dato)" % metrica)
                fallos += 1
                continue
            if medir:
                tope_s[metrica] = v if metrica in SIN_MARGEN else round(v * (1 / MARGEN if metrica in MAYOR_MEJOR else MARGEN), 1)
            t = tope_s.get(metrica)
            if t is None:
                print("  ¿?    %-22s %10.1f  (sin tope: córrelo con --medir)" % (metrica, v))
                continue
            ok = v >= t if metrica in MAYOR_MEJOR else v <= t
            fallos += 0 if ok else 1
            print("  %-5s %-22s %10.1f   tope %10.1f" % ("ok" if ok else "FALLO", metrica, v, t))
    if medir:
        json.dump(topes, open(TOPES, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        print("\nTopes reescritos en herramientas/banco_rendimiento.json (valor actual × %.2f)." % MARGEN)
    print("\n===== FIN. %d fallos =====" % fallos)
    return 1 if fallos else 0


if __name__ == "__main__":
    sys.exit(main())
