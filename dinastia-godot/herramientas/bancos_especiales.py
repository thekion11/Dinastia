#!/usr/bin/env python3
"""LOS BANCOS ESPECIALIZADOS (4-11-2026, megarreforma pedida por el dueño: «más de 30, modulares y ultra detallados aunque
tarden más»). FASE 1: un lanzador común y un CATÁLOGO que reparte TODO lo que ya se prueba (las ~194 secciones del banco y
las ~185 pruebas especiales) en bancos por ÁREA, cada uno corrible solo. FASE 2 (en curso, por bancos): cada banco suma
pruebas nuevas y más finas en `pruebas/bancos/<banco>.gd` (si existe, se corre también).

  python3 herramientas/bancos_especiales.py --lista            # los bancos, qué cubren y cuántas pruebas tiene cada uno
  python3 herramientas/bancos_especiales.py partido_reglas      # uno (o varios) por nombre
  python3 herramientas/bancos_especiales.py --todos             # todos, uno detrás de otro (largo)
  python3 herramientas/bancos_especiales.py --sin_banco          # pruebas que todavía no caen en ningún banco (debe dar 0)

Un banco = secciones del banco (`BANCO_SOLO=a,b,c`, un proceso) + pruebas especiales (cada una con su patrón de éxito, como
en `especiales.sh`) + su escena propia de la fase 2. Salida por banco y «===== FIN. N fallos =====» al final.
El banco de RENDIMIENTO va aparte: `herramientas/banco_rendimiento.py`.
"""
import os, re, subprocess, sys, time

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

## banco → (qué cubre, patrón sobre el NOMBRE de la sección/prueba y su comando). Gana el PRIMERO que encaja.
BANCOS = [
    ("pruebas_por_sistema", "pruebas nuevas por sistema (pruebas/so/): comunes, estándar, errores, integración, visualización, funciones y rendimiento",
     r"^so: |pruebas/so/|pruebas_so\.py"),
    ("arranque", "arranque, entrada, prólogo, modos y menú de inicio",
     r"carga_de_ui|globo|onb_arranque|f1e_|f1m_|f1p_|banco_inicio|entrada_comun|modos de juego|s7b_bloqueo|zz_alt|f0r_reloj|carga_diferida|pantalla_carga|partidas viejas"),
    ("determinismo", "huellas de igualdad, semillas y repetibilidad",
     r"repetibilidad|igualdad|bug_semilla|simetria|dos armados|estadio y ciudad por partes|nativo|C\+\+"),
    ("datos_mundo", "datos del mundo, clubes, base ficticia y real, países",
     r"_datos$|_mundo$|reales|base_ficticia|cubierta_nombres|auditoría de datos|auditoría de clubes|paises|Países|region_reales|jugadores_fijos|plantillas_fijas|nombres_repetidos|palabras_prohibidas|builds públicos|aspecto de los clubes|marcas_y_escudos|escudos|piel_por_pais"),
    ("calendario_competiciones", "calendario, ligas, copas, continentales, selecciones, ascensos",
     r"calendario|_copa|continental|selecciones|ascensos|bilbao|tanda|prorroga|cop_|f0d_tablas|trofeos por competición|palmarés|seguir clubes"),
    ("partido_reglas", "reglas del partido: faltas, tarjetas, ventaja, fuera de juego, penales, árbitros",
     r"arbitros|faltas|ventaja|disc_amarillas|amarillas|pmot_faltas|penales|sancion|barrida"),
    ("partido_ia", "IA del partido: táctica, presión, pases, líneas, plan, pizarra",
     r"_partidos$|dificultad_cpu|perfiles_ayuda|arreglos_partido|tactica|presion|linea_prevista|pase_mejora|estilo_club|pizarra|reacciona|partido simulado|cifras del partido|motor: el mejor|motor_libre|modos_simulacion|ideas_simulacion|lanzamiento_tactica|League-Soccer|s3p_salida|timing_disparo|colocacion|marcaje|tiro_limpio|tiro_fallido|imagen_mental|apoyo_fuerzas|ancla_enjambre|_regiones$|_traza|_descarga$|saque_seguro|saque_ofrece|entrada_momento|_adaptacion$"),
    ("partido_fisica", "física del balón y los cuerpos, colisiones, interpolación",
     r"fisica|s3f_|interpolación|primer_toque|colisiones|no_atravesar|cuerpos cruzados|estres_tirolibre"),
    ("partido_porteros", "porteros: paradas, salidas, saques",
     r"portero|cpor_|guardia del portero"),
    ("partido_jugable", "partido jugable: control, mando, táctil, cámara, repetición",
     r"control del equipo|pmot_control|triángulo|táctil|tactil|perfiles_mando|foco_mando|teclado_pantalla|pcam_|repetición|motor jugable|motor real|motor con usuario|eleccion_partido|pcar_tiro|s7d_doble|HUD y cámara|p6_alcance|p6_resolucion3d"),
    ("partido_presentacion", "previa, transmisión, estadísticas, narración, ceremonias",
     r"previa|puente3d|transmision|narracion|informe_rival|ceremonia|celebracion|tribuna_real|rotulo_y_sala|abandonado|banquillo|pie_habil|notas$"),
    ("plantel_cantera", "plantel, cantera, academia, ojeadores, cesiones",
     r"cantera|academia|ojeadores|cesiones|filtros_plantel|capitan|clau_descenso"),
    ("mercado_contratos", "mercado, fichajes, contratos, negociación, agentes",
     r"mercado|vender|negociacion|contratos|precontratos|mc_|pc_primer|mesa_agente|carrera_salidas"),
    ("economia", "finanzas, banco, economía, precios, auspicios, viajes, deudas",
     r"finanzas|_banco$|economia|precios|auspicio|viaje|cierre_anio|deudas|desa_sin_dinero|moneda|marca$|portafolio|cajero|pago con tarjeta|cartera|a4_gestion_cruzado"),
    ("club_directiva", "directiva, roles, federación, instituciones, leyes, política",
     r"directiva|roles|federacion|instituciones|licencia|leyes|incumplir|politica|consejeros|fundar_club|pulso_de_roles|tribunal|asamblea"),
    ("vestuario_moral", "vestuario, moral, charlas, necesidades, staff",
     r"vestuario|moral|charla|necesidades|staff|pint_|plan_costumbre"),
    ("entrenamiento_lesiones", "entrenamiento, medicina, lesiones, habilidades, maestrías",
     r"entrenamiento|entren|medicina|lesion|habilidades|maestrias|ent1_|práctica|dominadas"),
    ("prensa_redes", "prensa, entrevistas, redes, documental, eventos de despacho",
     r"prensa|entrevistas|redes|documental|portadas|eventos|r6b_|red_apagon|trad_prensa"),
    ("carrera_dt", "carrera del DT, vida, logros, desafíos, retos, mentor",
     r"carrera|vida_dt|logros|desafios|desa_|retos|mentor|dinastias|historia_c4|resumen de carrera|pcar_agenda|s7x_"),
    ("guardado", "guardado, carga, ranuras, autoguardado, exportar/importar",
     r"guardado|exim_|exportar|salir"),
    ("idiomas", "9 idiomas, traducciones, glifos, textos largos y cortados",
     r"idioma|traduc|glifos|paridad|alemán|castellano|trad_|siglas|tema_y_ortografia|fnt_|m462|carteles_3d"),
    ("menu_navegacion", "menús, panel lateral, atajos, pantallas, recorrido",
     r"menu|menú|atajos|pantallas|ampliada|funciones_escondidas|editor|compara_clubes|s2p_|bandeja|datos de las tarjetas|f0p_principal|recorrido|ayuda_en_menu|insignia|interfaz_limite|largo_plazo_ui|actualizador|aud4_movil_|aud4_arranque|aud4_primer_contacto|aud4_teclado"),
    ("accesibilidad_tutorial", "accesibilidad, tutorial, guía, lector, avisos",
     r"accesibilidad|tutorial|lector|avisos visuales|lectura de pantalla|tut_|s7t_|modo_streamer|deshacer"),
    ("estadio_3d", "estadio en 3D: grada, vallas, túnel, edificio del club, obras",
     r"estadio|grada|vallas|vomitorios|tunel|edificio_club|personal_estadio|interiores_club|galeria_club|reforma|obras|fundir|ola_grada|b6_|guinos|p3_grada|f0m_visor_estadio|textura del césped|pasto|a4_museo"),
    ("ciudad_construccion", "ciudad: construcción, módulos, rellenos, oclusión, ciudad grande",
     r"ciudad_b7|ciudad_grande|rellenos_ciudad|modulos|optimizacion|f0m_visor_ciudad|zonas_vista|entorno_oclusion|texturas en disco|cierre_ciudad|escala_movil|p4_mobiliario|construir y soltar|ciudad en marcha"),
    ("ciudad_vida", "vida en la ciudad: peatones, comercios, parques, casas",
     r"peaton|rotulos_cartel|comercio|parque|cancha_patos|habitantes|salas_comercio|ropero|ciudad_animo|redes_ciudad|_ciudad$|expendedora|peluches|luces_calle|ciudad a pie|a4_interiores|carteles 3D perezosos|a4_rotulos|a4_ciudad_noche|a4_sirena|a4_lluvia|a4_comercios"),
    ("ciudad_transporte", "transporte: tráfico, metro, bus, tren, teleférico, sirenas, paraderos",
     r"tráfico|trafico|tre_coches|metro|bus|tren|teleférico|teleferico|sirenas|emergencias|paradero|app Red|peaje|semaforo|senales|tarjeta_transporte|faros_coches|p6_boton_e|a4_pasajeros"),
    ("personajes_3d", "personajes 3D: cuerpos, caras, pelo, ropa, animaciones",
     r"personaje|cara|pelo|kit|camiseta|clips del futbolista|galeria_kit|disenos_kit|visor_pequenos|visor_efectos|módulos del visor|f0m_visor_datos|f9_"),
    ("audio", "sonido, música, ruidos, buses de audio",
     r"sonido|audio|ruidos|ruido de registros|aspecto_y_audio"),
    ("minijuegos", "minijuegos y retos jugables",
     r"minijuego|retro 5v5|penales en partido|tiro libre"),
    ("mundo_largo_plazo", "temporadas largas: balance, rendimiento en 10-20 temporadas",
     r"temporadas|balance en|rendimiento en 20|simular temporada"),
    ("calidad_grafica", "calidad gráfica, rendimiento adaptativo, presupuestos, ahorro",
     r"calidad|rendimiento_adaptativo|presupuesto|ahorro|contador de FPS|caché horneada|textura del balón|arena de pruebas|troceo|caché en disco|visual|p6_alcance|p6_resolucion"),
    ("codigo_y_auditorias", "compilación, norma de líneas, auditoría técnica, registros",
     r"compilan|auditoría técnica|reg_registro|f0m_nucleo|nucleo_sueltos|lanzamiento|presets_exportacion|logo|codigo"),
    ("ideas_documento", "las ideas del documento original (lotes) y ejemplos sueltos",
     r"ideas_|guion|coherencia_c1|cantera_c3|charlas_c6|contratos_c9|calendario_c13|politica_c15|portadas_c20"),
]


CON_PANTALLA = {"estadio_3d"}   ## bancos que corren con xvfb + OpenGL (llvmpipe) en vez de --headless

def especiales():
    """[(nombre, comando, patrón)] de especiales.sh (todas, también las del bloque «todo»)."""
    out = []
    for l in open(os.path.join(RAIZ, "herramientas", "especiales.sh"), encoding="utf-8"):
        m = re.match(r'\s*pasa "((?:[^"\\]|\\.)*)" "((?:[^"\\]|\\.)*)" "((?:[^"\\]|\\.)*)"', l)
        if m and "$" not in m.group(1):
            out.append((m.group(1), m.group(2).replace('\\"', '"'), m.group(3)))
    return out


def secciones():
    s = open(os.path.join(RAIZ, "pruebas", "banco.gd"), encoding="utf-8").read()
    i = s.index("const SECCIONES := ["); j = s.index("]", i)
    return re.findall(r'"(_probar_\w+)"', s[i:j])


def repartir():
    reparto = {b[0]: {"secciones": [], "especiales": []} for b in BANCOS}
    sueltas = []
    for sec in secciones():
        b = next((x[0] for x in BANCOS if re.search(x[2], sec, re.I)), None)
        (reparto[b]["secciones"].append(sec) if b else sueltas.append(sec))
    for nombre, cmd, pat in especiales():
        b = next((x[0] for x in BANCOS if re.search(x[2], nombre, re.I) or re.search(x[2], cmd, re.I)), None)
        (reparto[b]["especiales"].append((nombre, cmd, pat)) if b else sueltas.append(nombre))
    return reparto, sueltas


def correr_banco(nombre, r):
    fallos = 0
    t0 = time.time()
    print("\n== BANCO %s — %s" % (nombre, next(b[1] for b in BANCOS if b[0] == nombre)))
    if r["secciones"]:
        env = dict(os.environ, BANCO_SOLO=",".join(r["secciones"]))
        p = subprocess.run(["godot", "--headless", "--path", RAIZ, "res://pruebas/banco.tscn"], env=env, capture_output=True, text=True, timeout=1800)
        out = re.sub(r"\x1b\[[0-9;]*m", "", p.stdout + p.stderr)
        malas = [l for l in out.splitlines() if "FALLO" in l or "SCRIPT ERROR" in l]
        ok = "FIN. 0 fallos" in out and not any("SCRIPT ERROR" in l for l in malas)
        fallos += 0 if ok else 1
        print("  %-5s %d secciones del banco" % ("ok" if ok else "FALLO", len(r["secciones"])))
        for l in malas[:6]:
            print("        " + l.strip()[:160])
    for n, cmd, pat in r["especiales"]:
        p = subprocess.run(["bash", "-c", "timeout 600 bash -c '%s'" % cmd.replace("'", "'\\''")], cwd=RAIZ, capture_output=True, text=True)
        out = p.stdout + p.stderr
        ok = re.search(pat, out) is not None and "SCRIPT ERROR" not in out
        fallos += 0 if ok else 1
        print("  %-5s %s" % ("ok" if ok else "FALLO", n))
        if not ok:
            for l in [x for x in out.splitlines() if "FALLO" in x or "SCRIPT ERROR" in x][:3]:
                print("        " + l.strip()[:160])
    propia = os.path.join(RAIZ, "pruebas", "bancos", nombre + ".tscn")
    if os.path.exists(propia):
        ## Los que leen los datos de los MultiMesh (transformaciones y colores de butacas, gente, pelo…) necesitan pantalla: sin ella el motor no los guarda.
        orden = (["xvfb-run", "-a", "godot", "--rendering-driver", "opengl3", "--resolution", "640x360"] if nombre in CON_PANTALLA else ["godot", "--headless"]) + ["--path", RAIZ, "res://pruebas/bancos/%s.tscn" % nombre]
        p = subprocess.run(orden, capture_output=True, text=True, timeout=1800)
        out = p.stdout + p.stderr
        ok = "FIN. 0 fallos" in out and "SCRIPT ERROR" not in out
        fallos += 0 if ok else 1
        print("  %-5s pruebas propias del banco (fase 2)" % ("ok" if ok else "FALLO"))
        for l in [x for x in out.splitlines() if "FALLO" in x or "SCRIPT ERROR" in x][:6]:
            print("        " + l.strip()[:160])
    print("  · %s: %d s, %d fallos" % (nombre, time.time() - t0, fallos))
    return fallos


def main():
    reparto, sueltas = repartir()
    if "--lista" in sys.argv or len(sys.argv) == 1:
        for b, desc, _ in BANCOS:
            r = reparto[b]
            propia = os.path.exists(os.path.join(RAIZ, "pruebas", "bancos", b + ".tscn"))
            print("%-26s %3d secciones + %3d especiales%s  · %s" % (b, len(r["secciones"]), len(r["especiales"]), " + propias" if propia else "", desc))
        print("\n%d bancos · %d pruebas sin banco" % (len(BANCOS), len(sueltas)))
        return 0
    if "--sin_banco" in sys.argv:
        for s in sueltas:
            print("SIN BANCO: " + s)
        print("===== FIN. %d fallos =====" % len(sueltas))
        return 1 if sueltas else 0
    nombres = [b[0] for b in BANCOS] if "--todos" in sys.argv else [a for a in sys.argv[1:] if not a.startswith("--")]
    fallos = 0
    for n in nombres:
        if n not in reparto:
            print("FALLO banco desconocido: " + n)
            fallos += 1
            continue
        fallos += correr_banco(n, reparto[n])
    print("\n===== FIN. %d fallos =====" % fallos)
    return 1 if fallos else 0


if __name__ == "__main__":
    sys.exit(main())
