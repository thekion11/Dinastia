#!/usr/bin/env python3
"""RESUMEN Y DIAGNÓSTICO de los CSV del banco automático de rendimiento (pruebas/benchmark/benchmark_manager.gd).

  python3 herramientas/benchmark_resumen.py perf_log.csv                       # un CSV
  python3 herramientas/benchmark_resumen.py carpeta_con_csv/ [-o resumen.md]    # todos los perf_*.csv de la carpeta
  python3 herramientas/benchmark_resumen.py --base antes/ despues/              # compara dos carpetas (regresiones)

Nombre esperado de cada CSV: perf_<escenario>_<calidad>_<perfil>.csv (el perfil es opcional). Lo que NO esté en ese formato se lee igual.
Solo cuenta la fase «juego» (se descartan «carga» y «calentar»). Sin GPU (llvmpipe/headless) los FPS y los ms de dibujo NO valen como
absolutos: el diagnóstico los marca «(sin GPU)» y se fija en CPU, motor, física, memoria y lo que se le pide a la gráfica.
Código de salida: 0 siempre salvo con --falla-en-alertas (1 si hay alguna alerta ALTA).
"""
import csv, glob, os, re, statistics, sys

# Topes del diagnóstico (ajustables). El presupuesto de 120 FPS del proyecto (orden 19) son 8,3 ms por fotograma.
TOPE_MOTOR_PASO_MS = 4.0          # el motor de los 22 corre 60 veces por segundo de juego: pasar de 4 ms/paso se come casi el 25 % del cuadro
TOPE_MOTOR_P95_MS = 8.0
TOPE_CUADRO_P99_MS = 33.4         # el 1 % peor de los cuadros: por debajo de 30 FPS se nota como tirón
TOPE_MEM_MB = 2048.0              # un equipo de 4 GB con el sistema operativo no aguanta mucho más
TOPE_FUGA_MB_MIN = 20.0           # crecimiento de memoria estática durante la medición
TOPE_LLAMADAS = 1500.0
TOPE_TRIANGULOS = 2_000_000.0


def pct(vals, p):
    if not vals:
        return 0.0
    v = sorted(vals)
    return v[min(len(v) - 1, int(round(p / 100.0 * (len(v) - 1))))]


def leer(ruta):
    with open(ruta, newline="", encoding="utf-8") as f:
        filas = list(csv.DictReader(f))
    return filas


def col(filas, nombre):
    out = []
    for r in filas:
        try:
            out.append(float(r[nombre]))
        except (KeyError, ValueError):
            pass
    return out


def pendiente_mb_min(filas):
    """Pendiente de la memoria estática (mínimos cuadrados) en MB por minuto."""
    t = col(filas, "t")
    m = col(filas, "mem_estatica_mb")
    if len(t) < 10 or len(t) != len(m):
        return 0.0
    mt, mm = statistics.fmean(t), statistics.fmean(m)
    den = sum((x - mt) ** 2 for x in t)
    return 60.0 * sum((x - mt) * (y - mm) for x, y in zip(t, m)) / den if den > 0 else 0.0


def resumir(ruta):
    filas = leer(ruta)
    juego = [r for r in filas if r.get("fase") == "juego"]
    carga = [r for r in filas if r.get("fase") == "carga"]
    nombre = os.path.basename(ruta)
    m = re.match(r"perf_([a-z]+)_([a-z]+)(?:_(.+))?\.csv$", nombre)
    esc = juego[0]["escenario"] if juego else (m.group(1) if m else "?")
    cal = juego[0]["calidad"] if juego else (m.group(2) if m else "?")
    perfil = (m.group(3) if m and m.group(3) else "-")
    r = {"archivo": nombre, "escenario": esc, "calidad": cal, "perfil": perfil, "filas": len(juego), "alertas": []}
    if len(juego) < 30:
        r["alertas"].append(("ALTA", "menos de 30 fotogramas medidos: la escena no llegó a correr (revisar el registro de la ejecución)"))
        return r
    ms = col(juego, "ms_fotograma")
    dur = sum(ms) / 1000.0
    r["segundos"] = dur
    r["carga_s"] = sum(col(carga, "ms_fotograma")) / 1000.0
    r["fps_medio"] = len(ms) / dur if dur > 0 else 0.0
    r["fps_p1"] = 1000.0 / pct(ms, 99)           # «1 % low»: los FPS del 1 % peor de los cuadros
    r["fps_min"] = 1000.0 / max(ms)
    r["ms_p50"], r["ms_p95"], r["ms_p99"], r["ms_max"] = pct(ms, 50), pct(ms, 95), pct(ms, 99), max(ms)
    r["cpu_ms"] = statistics.fmean(col(juego, "ms_proceso"))
    ticks = sum(col(juego, "ticks_fisica"))
    r["fisica_ms_tick"] = sum(col(juego, "ms_fisica_medido")) / ticks if ticks else 0.0
    pasos = sum(col(juego, "pasos_motor"))
    por_paso = [float(x["ms_motor"]) / int(float(x["pasos_motor"])) for x in juego if float(x["pasos_motor"]) > 0]
    r["motor_ms_paso"] = sum(col(juego, "ms_motor")) / pasos if pasos else 0.0
    r["motor_p95"] = pct(por_paso, 95)
    r["motor_max"] = max(por_paso) if por_paso else 0.0
    r["motor_ms_jugador"] = r["motor_ms_paso"] / 22.0
    r["mem_mb"] = statistics.fmean(col(juego, "mem_estatica_mb"))
    r["mem_pico_mb"] = max(col(juego, "mem_pico_mb"))
    r["fuga_mb_min"] = pendiente_mb_min(juego)
    r["llamadas"] = statistics.fmean(col(juego, "llamadas"))
    r["triangulos"] = statistics.fmean(col(juego, "triangulos"))
    r["objetos"] = statistics.fmean(col(juego, "objetos"))
    r["nodos"] = statistics.fmean(col(juego, "nodos"))
    r["vram_mb"] = max(col(juego, "vram_mb"))
    r["con_render"] = r["llamadas"] > 0
    al = r["alertas"]
    sufijo = "" if r["con_render"] else " (sin GPU)"
    if r["escenario"] == "partido" and pasos:
        if r["motor_ms_paso"] > TOPE_MOTOR_PASO_MS:
            al.append(("ALTA", "el motor de los 22 jugadores tarda %.2f ms por paso (tope %.1f): optimizar colocación/marcaje/IA (%.3f ms por jugador)" % (r["motor_ms_paso"], TOPE_MOTOR_PASO_MS, r["motor_ms_jugador"])))
        if r["motor_p95"] > TOPE_MOTOR_P95_MS:
            al.append(("MEDIA", "picos del motor: p95 %.1f ms y máximo %.1f ms por paso (suele ser una decisión pesada puntual: balón dividido, córner, repetición)" % (r["motor_p95"], r["motor_max"])))
    if r["ms_p99"] > TOPE_CUADRO_P99_MS and r["con_render"]:
        al.append(("ALTA", "el 1 %% peor de los fotogramas pasa de %.0f ms (%.0f FPS de 1%% low): tirones" % (r["ms_p99"], r["fps_p1"])))
    elif r["ms_max"] > 250.0:
        al.append(("MEDIA", "un fotograma de %.0f ms (congelación puntual)%s" % (r["ms_max"], sufijo)))
    if r["mem_pico_mb"] > TOPE_MEM_MB:
        al.append(("ALTA", "memoria estática pico %.0f MB (tope %.0f): no cabe en un equipo de 4 GB" % (r["mem_pico_mb"], TOPE_MEM_MB)))
    if r["fuga_mb_min"] > TOPE_FUGA_MB_MIN:
        al.append(("ALTA", "la memoria sube %.0f MB por minuto durante la medición: posible fuga (nodos/recursos que no se liberan)" % r["fuga_mb_min"]))
    if r["con_render"]:
        if r["llamadas"] > TOPE_LLAMADAS:
            al.append(("MEDIA", "%.0f llamadas de dibujo por fotograma (tope %.0f): agrupar mallas/MultiMesh o recortar visibilidad" % (r["llamadas"], TOPE_LLAMADAS)))
        if r["triangulos"] > TOPE_TRIANGULOS:
            al.append(("MEDIA", "%.1f M triángulos por fotograma (tope %.0f M): LOD o menos geometría fuera de cámara" % (r["triangulos"] / 1e6, TOPE_TRIANGULOS / 1e6)))
    return r


def f(x, d=1):
    return ("%." + str(d) + "f") % x


def tabla(rs):
    cab = "| escenario | calidad | perfil | FPS medio | FPS 1% low | cuadro p99 (ms) | motor ms/paso | física ms/tick | mem MB (pico) | fuga MB/min | llamadas | triáng. (M) | nodos |\n|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n"
    out = cab
    for r in rs:
        if "fps_medio" not in r:
            out += "| %s | %s | %s | sin datos | | | | | | | | | |\n" % (r["escenario"], r["calidad"], r["perfil"])
            continue
        gpu = "" if r["con_render"] else "*"
        out += "| %s | %s | %s | %s%s | %s%s | %s | %s | %s | %s (%s) | %s | %s | %s | %s |\n" % (
            r["escenario"], r["calidad"], r["perfil"], f(r["fps_medio"]), gpu, f(r["fps_p1"]), gpu, f(r["ms_p99"]),
            f(r["motor_ms_paso"], 2) if r["escenario"] == "partido" else "–", f(r["fisica_ms_tick"], 3), f(r["mem_mb"], 0), f(r["mem_pico_mb"], 0),
            f(r["fuga_mb_min"]), f(r["llamadas"], 0), f(r["triangulos"] / 1e6, 2), f(r["nodos"], 0))
    return out + "\n\\* sin GPU (headless/llvmpipe): los FPS solo comparan versiones, no máquinas.\n"


def diagnostico(rs):
    out = "## Diagnóstico\n\n"
    todas = [(a[0], r, a[1]) for r in rs for a in r["alertas"]]
    if not todas:
        return out + "Sin alertas: todo dentro de los topes (motor, cuadros, memoria, dibujo).\n"
    orden = {"ALTA": 0, "MEDIA": 1}
    for sev, r, txt in sorted(todas, key=lambda x: orden[x[0]]):
        out += "- **%s** · %s/%s/%s: %s\n" % (sev, r["escenario"], r["calidad"], r["perfil"], txt)
    return out


def comparar(a, b):
    """Regresiones de b respecto a a (mismo escenario+calidad+perfil)."""
    clave = lambda r: (r["escenario"], r["calidad"], r["perfil"])
    base = {clave(r): r for r in a if "fps_medio" in r}
    out = "## Comparación con la base\n\n| escenario/calidad/perfil | métrica | antes | ahora | cambio |\n|---|---|---:|---:|---:|\n"
    n = 0
    for r in b:
        k = clave(r)
        if k not in base or "fps_medio" not in r:
            continue
        for met, peor_si_sube, etiqueta in (("motor_ms_paso", True, "motor ms/paso"), ("ms_p99", True, "cuadro p99 ms"), ("mem_pico_mb", True, "memoria pico MB"),
                                            ("llamadas", True, "llamadas"), ("triangulos", True, "triángulos"), ("fps_medio", False, "FPS medio")):
            x, y = base[k][met], r[met]
            if x <= 0:
                continue
            d = (y - x) / x * 100.0
            if (peor_si_sube and d > 10.0) or (not peor_si_sube and d < -10.0):
                out += "| %s/%s/%s | %s | %s | %s | %+.0f %% |\n" % (k[0], k[1], k[2], etiqueta, f(x, 2), f(y, 2), d)
                n += 1
    return out + ("\nSin regresiones de más del 10 %.\n" if n == 0 else "")


def cargar(ruta):
    if os.path.isdir(ruta):
        archivos = sorted(glob.glob(os.path.join(ruta, "**", "perf_*.csv"), recursive=True)) or sorted(glob.glob(os.path.join(ruta, "**", "*.csv"), recursive=True))
    else:
        archivos = [ruta]
    return [resumir(a) for a in archivos]


def main(argv):
    salida, base, falla, rutas = None, None, False, []
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "-o":
            salida = argv[i + 1]; i += 1
        elif a == "--base":
            base = argv[i + 1]; i += 1
        elif a == "--falla-en-alertas":
            falla = True
        else:
            rutas.append(a)
        i += 1
    if not rutas:
        print(__doc__)
        return 2
    rs = [r for ruta in rutas for r in cargar(ruta)]
    texto = "# Rendimiento automático\n\n" + tabla(rs) + "\n" + diagnostico(rs)
    if base:
        texto += "\n" + comparar(cargar(base), rs)
    print(texto)
    if salida:
        with open(salida, "w", encoding="utf-8") as fh:
            fh.write(texto)
    return 1 if falla and any(a[0] == "ALTA" for r in rs for a in r["alertas"]) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
