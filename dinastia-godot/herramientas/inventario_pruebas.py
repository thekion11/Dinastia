#!/usr/bin/env python3
"""INVENTARIO DE PRUEBAS (5-11-2026). Recorre `pruebas/` y `especiales.sh`, clasifica cada prueba por familia y marca lo frágil (depende del
sistema, sin aserciones, con esperas fijas, duplicada, lenta). Salida: Markdown en `docs/04_auditorias/inventario_pruebas_AAAA-MM-DD.md`.

  python3 herramientas/inventario_pruebas.py            # imprime el resumen
  python3 herramientas/inventario_pruebas.py --escribir # además reescribe el informe (la sección «Gestión» a mano se conserva)
"""
import collections, datetime, glob, os, re, sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
P = os.path.join(RAIZ, "pruebas")
FAMILIAS = ["comunes", "estándar", "errores", "integración", "visualización", "funciones", "rendimiento", "captura / diagnóstico (sin veredicto)"]

REGLAS = [  # primera que encaja
    ("rendimiento", r"medir|fps|rend_|presupuesto|rendimiento|mem_|memoria|ahorro|cache|caché|oclusion|optimiz|a4_rend|latencia"),
    ("visualización", r"captura|visual|foto|retrato|render|pantallazo|imagen|textura|vis_|hoja|album|contacto|galeria"),
    ("errores", r"limite|límite|fosiles|corrupt|danad|dañ|absurd|caos|robust|ruido_arreglos|fallos|invalid|ausente|roto|rafaga|err_|estres|estrés|abus|sabotaje|malos"),
    ("integración", r"flujo|recorrido|e2e|principal|ciclo|nativo|cruzad|integr|guion|f[0-9][a-z]?_|aud4_|movil|arranque_|menu_ciudad|motor|arena|largo_plazo|fugas"),
    ("funciones", r"unidad|nucleo_sueltos|formula|puro|matem|fun_|_unit|geometr|siglas|codigos|ordinal"),
    ("comunes", r"arranque|menu|idioma|guardado|ajustes|tutorial|com_|inicio|entrada|prologo|atajos|teclado|accesib"),
]

SISTEMA = {  # marca → patrón en el código
    "ruta /tmp": r"/t" "mp/",   # partido en dos para que el escáner no lo lea como uso de /tmp aquí
    "xvfb / pantalla": r"xvfb|DisplayServer\.(?!get_name\(\) == \"headless\")",
    "variable de entorno": r"OS\.get_environment\(",
    "OS.get_name / has_feature": r"OS\.get_name|OS\.has_feature",
    "ruta absoluta del disco": r"globalize_path|OS\.get_executable_path|OS\.get_user_data_dir",
    "renderizador / Vulkan": r"RenderingServer\.get_current|vulkan|forward_plus|opengl|RENDER_TOTAL",
    "audio": r"AudioServer|AudioStreamPlayer|Sonido\.|Musica\.",
    "hilos": r"Thread\.new|WorkerThreadPool|Mutex",
    "red": r"HTTPRequest|TCPServer|StreamPeerTCP",
    "mayúsculas en nombres de archivo": r"\.to_lower\(\)|\.to_upper\(\)|casecmp",
}


def familia(ruta, texto):
    n = os.path.relpath(ruta, P).lower()
    sin_veredicto = not re.search(r"_comprobar\(|assert\(|\bFALLO\b|_malo\(", texto)
    if sin_veredicto and re.search(r"captura|foto|retrato|diagnostico|diagnóstico|medir|sonda|hoja|album|galeria|_pers_|_captura", n):
        return "captura / diagnóstico (sin veredicto)"
    for fam, pat in REGLAS:
        if re.search(pat, n):
            return fam
    return "estándar"


def leer(r):
    try:
        return open(r, encoding="utf-8", errors="replace").read()
    except OSError:
        return ""


def main():
    escribir = "--escribir" in sys.argv
    especiales = leer(os.path.join(RAIZ, "herramientas", "especiales.sh"))
    esc_regs = set(re.findall(r"res://pruebas/([\w/]+)\.tscn", especiales))
    ## Todo lo que puede lanzar una prueba: scripts de herramientas, flujos del CI y los propios bancos (un nombre citado en cualquiera cuenta).
    bancos_py = "".join(leer(r) for r in glob.glob(os.path.join(RAIZ, "herramientas", "*.*")) + glob.glob(os.path.join(RAIZ, "..", ".github", "workflows", "*.yml"))
                        + glob.glob(os.path.join(RAIZ, "pruebas", "*.gd")) + glob.glob(os.path.join(RAIZ, "pruebas", "banco", "*.gd")))
    filas = []
    for gd in sorted(glob.glob(P + "/**/*.gd", recursive=True)):
        rel = os.path.relpath(gd, P).replace("\\", "/")
        if rel.startswith(("_sonda", "capturas")) or "/arena/" in "/" + rel and False:
            continue
        txt = leer(gd)
        if not re.search(r"extends\s+(Node|BaseIdea|BaseSO|\"res://pruebas|SceneTree|Control|Node3D|\"res://nucleo/banco)", txt) and "func _probar" not in txt:
            continue
        escena = os.path.exists(gd[:-3] + ".tscn")
        base = rel[:-3]
        asercion = len(re.findall(r"_comprobar\(|assert\(|_ok\(|_chequear\(|_verificar\(|_malo\(|\bFALLO\b", txt))
        filas.append(dict(rel=rel, base=base, lineas=txt.count("\n") + 1, aserciones=asercion, escena=escena,
                          registrada=(base in esc_regs) or rel.startswith(("banco/", "so/")) or (os.path.basename(base) in bancos_py),
                          fam=familia(gd, txt), txt=txt))
    fams = collections.Counter(f["fam"] for f in filas)
    lista_tscn = len(glob.glob(P + "/**/*.tscn", recursive=True))
    sin_aserciones = [f for f in filas if f["aserciones"] == 0 and f["lineas"] > 15 and not f["rel"].startswith("banco/") and not f["fam"].startswith("captura")]
    sin_registrar = [f for f in filas if f["escena"] and not f["registrada"] and not f["rel"].startswith(("captura", "_", "capturas")) and not f["fam"].startswith("captura")]
    esperas = [f for f in filas if re.search(r"create_timer\([0-9.]+\)|OS\.delay_msec|OS\.delay_usec|wait_time\s*=", f["txt"]) and f["aserciones"] > 0]
    sist = {k: [f for f in filas if re.search(p, f["txt"])] for k, p in SISTEMA.items()}
    lentas = [m.group(1) for m in re.finditer(r'pasa "([^"]+)" "([^"]*)"', especiales)
              if "LIMITE_S=" in m.group(2) or "RECORRIDO" in m.group(2)]
    duplicadas = collections.defaultdict(list)
    for f in filas:
        k = re.sub(r"\s+", " ", re.sub(r"##.*|#.*", "", f["txt"]))[:600]
        if len(k) > 300:
            duplicadas[hash(k)].append(f["rel"])
    dups = [v for v in duplicadas.values() if len(v) > 1]
    secciones = len(re.findall(r"^func _probar_", "".join(leer(g) for g in glob.glob(P + "/banco/*.gd")), re.M))
    n_comp = sum(f["aserciones"] for f in filas)
    out = []
    w = out.append
    w("# Inventario de pruebas — %s\n" % datetime.date.today().isoformat())
    w("Generado por `herramientas/inventario_pruebas.py --escribir` (análisis estático del código; los tiempos son los medidos en el contenedor del 5-11). "
      "La sección «Gestión» del final es a mano y se conserva al regenerar.\n")
    w("## 1. Resumen\n")
    w("- **%d scripts de prueba** (%d escenas `.tscn` en `pruebas/`), con ~%d aserciones; el banco tiene **%d secciones** (`func _probar_*`) en `pruebas/banco/`; `especiales.sh` lanza %d escenas." % (len(filas), lista_tscn, n_comp, secciones, len(esc_regs)))
    w("- Reparto por familia (clasificación por nombre y contenido; una prueba puede rozar varias, se cuenta en la primera que encaja):\n")
    w("| familia | scripts | qué cubre |\n|---|---|---|")
    desc = {"comunes": "arranque, menús, idiomas, guardado, ajustes, entrada", "estándar": "reglas, economía, calendario, datos, mundo, partido simulado",
            "errores": "límites, absurdos, corrupción, entradas inválidas, ráfagas", "integración": "recorridos de punta a punta, nativo, escenas completas, móvil",
            "visualización": "capturas, texturas, retratos, referencias", "funciones": "funciones puras de `nucleo/`", "rendimiento": "triángulos, llamadas, memoria, nodos, caché", "captura / diagnóstico (sin veredicto)": "escenas que sacan fotos o miden y solo imprimen: sirven a una persona, no al CI"}
    for fam in FAMILIAS:
        w("| %s | %d | %s |" % (fam, fams.get(fam, 0), desc[fam]))
    w("")
    w("## 2. Dónde vive cada cosa\n")
    w("- `pruebas/banco.gd` + `pruebas/banco/*.gd` — el BANCO (sin ventana, un proceso, en paralelo por grupos): %d secciones. Lo corre `banco.sh`." % secciones)
    w("- `pruebas/ideas/*.tscn` — ideas y auditorías, una escena por prueba (`BaseIdea`): %d. Las que cuelgan de `especiales.sh` son las «especiales»." % len(glob.glob(P + "/ideas/*.tscn")))
    w("- `pruebas/bancos/*.tscn` — banco especializado por área (fase 2 de la megarreforma): %d." % len(glob.glob(P + "/bancos/*.tscn")))
    w("- `pruebas/so/` — **pruebas por sistema** (5-11): `BaseSO`, marcador «OK/FALLO nombre [sistema]», `LISTA.txt` (nombre|familia|sistemas|escena|requiere) y lanzador `herramientas/pruebas_so.py`: %d." % len(glob.glob(P + "/so/*.tscn")))
    w("- `pruebas/*.tscn` sueltas (`prueba_*`, `auditoria_*`, `probar_*`, `captura_*`, `a4_*`): %d." % len(glob.glob(P + "/*.tscn")))
    w("- `pruebas/visual/` — 20 pantallas contra referencias JPG (necesita Vulkan). `pruebas/partidas_viejas/` — guardados de versiones viejas. `pruebas/arena/` — arena aislada.\n")
    w("## 3. Dependen del sistema (cuántos scripts)\n")
    w("| dependencia | scripts | riesgo en Windows / Web / Android |\n|---|---|---|")
    riesgo = {"ruta /tmp": "Windows no tiene `/tmp`; usar `user://` o `OS.get_user_data_dir()`", "xvfb / pantalla": "solo Linux con xvfb; Windows/Android tienen pantalla propia",
              "variable de entorno": "Web y Android no tienen variables de entorno: los parámetros no llegan", "OS.get_name / has_feature": "ya sabe de sistema; revisar que no se SALTE nada",
              "ruta absoluta del disco": "Web no tiene disco real; Android sólo la carpeta privada", "renderizador / Vulkan": "Web/móvil usan Compatibilidad; Forward+ no existe",
              "audio": "Web arranca el audio tras un gesto del usuario; Android puede no tener salida en CI", "hilos": "Web exporta sin hilos por defecto",
              "red": "Web no abre sockets TCP; Android pide permiso", "mayúsculas en nombres de archivo": "Windows/macOS no distinguen mayúsculas, Linux/Android/Web sí"}
    for k, v in sist.items():
        w("| %s | %d | %s |" % (k, len(v), riesgo[k]))
    w("")
    for k in ("ruta /tmp", "variable de entorno", "xvfb / pantalla"):
        nombres = ", ".join("`%s`" % f["rel"] for f in sist[k][:14])
        w("- **%s** (%d): %s%s" % (k, len(sist[k]), nombres, " …" if len(sist[k]) > 14 else ""))
    w("\n## 4. Lo débil\n")
    w("- **Sin aserciones** (más de 15 líneas y ninguna comprobación; solo imprimen o miden): %d. %s" % (len(sin_aserciones), ", ".join("`%s`" % f["rel"] for f in sin_aserciones[:25])))
    w("- **Con esperas fijas** (`create_timer(N)`, `delay_msec`) y aserciones: %d — frágiles según la velocidad de la máquina. %s" % (len(esperas), ", ".join("`%s`" % f["rel"] for f in esperas[:25])))
    w("- **Con escena pero sin lanzar** (ni en `especiales.sh` ni en un banco): %d. %s" % (len(sin_registrar), ", ".join("`%s`" % f["rel"] for f in sin_registrar[:30])))
    w("- **Posibles duplicadas** (mismo código salvo comentarios): %d grupos. %s" % (len(dups), "; ".join("/".join("`%s`" % x for x in g[:3]) for g in dups[:8])))
    w("- **Lentas conocidas**: %s. El bloque «todo» de `especiales.sh` añade ~9 min (recorrido de pantallas, balance a largo plazo, visuales con Vulkan)." % (", ".join(lentas[:10]) or "ninguna marcada"))
    w("")
    w("## 5. Huecos que cubren las pruebas nuevas (`pruebas/so/`)\n")
    w("Ver `docs/04_auditorias/cobertura_pruebas_2026-11-05.md` (tabla familia × sistema).\n")
    texto = "\n".join(out)
    print(texto[:3500])
    if escribir:
        ruta = os.path.join(RAIZ, "..", "docs", "04_auditorias", "inventario_pruebas_2026-11-05.md")
        previo = leer(ruta)
        gest = previo[previo.index("## Gestión"):] if "## Gestión" in previo else "## Gestión\n\n(a mano)\n"
        open(ruta, "w", encoding="utf-8", newline="\n").write(texto + "\n" + gest)
        print("escrito", os.path.normpath(ruta))


if __name__ == "__main__":
    main()
