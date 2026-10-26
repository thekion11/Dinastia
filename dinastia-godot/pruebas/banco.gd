extends "res://pruebas/banco/nucleo.gd"

## Banco de pruebas del nucleo, sin ventana y sin nadie mirando.
##
##     godot --headless --path . res://pruebas/banco.tscn
##
## Es el equivalente del harness de Chrome del HTML, y comprueba lo mismo: que
## nada revienta al simular temporadas enteras. Pero puede comprobar dos cosas
## mas que aquel no podia:
##
##  1. REPETIBILIDAD. Con semilla, dos mundos iguales dan resultados iguales. El
##     HTML usa Math.random() sin semilla y eso alli es imposible de comprobar.
##  2. DISTRIBUCION. Como la migracion no se puede verificar por huella (el HTML
##     no es reproducible ni consigo mismo), se verifica que las CURVAS caigan
##     donde tienen que caer: goles por partido, valores, sueldos. Si una
##     formula se porta mal, la curva se mueve aunque no reviente nada.
##
## Devuelve 0 si todo va bien y 1 si algo falla, para poder encadenarlo.
##
## PARTIDO POR GRUPOS (26-10-2026): cada grupo de `GRUPOS` vive en su propio archivo,
## `pruebas/banco/<grupo>.gd` (con sus capas `<grupo>_pN.gd` si pasa de 450 líneas), que extiende
## `banco/base.gd` (utilidades comunes) y este a `banco/nucleo.gd`. Lo que no es de ningún grupo
## está en «ideas» (`_probar_ideas_*`) o «varios». Este archivo solo es el CORREDOR: el orden
## (`SECCIONES`), los grupos, los costes y el reparto. Con BANCO_GRUPO solo se carga el archivo de
## ese grupo (y el de otro grupo si le presta alguna sección), así que el mini banco compila menos.
##
## SECCIÓN NUEVA: la función `_probar_x` va en el archivo de su grupo (`ARCHIVOS`) y su nombre en
## `SECCIONES` (y en `GRUPOS` si es de uno). Si falta alguna de las dos cosas, el banco lo dice
## como FALLO en la primera sección, así que no se puede olvidar sin que se note.


const SECCIONES := [
	"_probar_carga_de_ui",
	"_probar_datos",
	"_probar_repetibilidad",
	"_probar_mundo",
	"_probar_reales",
	"_probar_base_ficticia",
	"_probar_cubierta_nombres",
	"_probar_calendario",
	"_probar_partidos",
	"_probar_previa",
	"_probar_arbitros",
	"_probar_pie_habil",
	"_probar_banquillo",
	"_probar_finanzas",
	"_probar_mercado",
	"_probar_notas",
	"_probar_directiva",
	"_probar_banco",
	"_probar_necesidades_con_efecto",
	"_probar_staff",
	"_probar_obras",
	"_probar_roles_y_federacion",
	"_probar_estadio",
	"_probar_rendimiento_adaptativo",
	"_probar_puente3d",
	"_probar_tactica_en_movimiento",
	"_probar_copa",
	"_probar_continental",
	"_probar_selecciones",
	"_probar_pulso_de_roles",
	"_probar_cantera",
	"_probar_cesiones",
	"_probar_desafios",
	"_probar_fundar_club",
	"_probar_logros",
	"_probar_ascensos",
	"_probar_vender",
	"_probar_ojeadores",
	"_probar_negociacion",
	"_probar_consejeros",
	"_probar_bilbao_solo_local",
	"_probar_guardado",
	"_probar_guardado_seguro",
	"_probar_fisica_motor",
	"_probar_faltas_puntos",
	"_probar_vallas_led",
	"_probar_ola_grada",
	"_probar_dificultad_cpu",
	"_probar_temporadas",
	"_probar_economia",
	"_probar_sala_de_prensa",
	"_probar_auspicio",
	"_probar_eras_y_precios",
	"_probar_analitica_y_academias",
	"_probar_habilidades",
	"_probar_carrera_por_dentro",
	"_probar_editor",
	"_probar_ciudad",
	"_probar_ideas_del_documento",
	"_probar_ideas_instalaciones_y_marca",
	"_probar_ideas_personas_y_negocios",
	"_probar_ideas_eventos_de_despacho",
	"_probar_ideas_premios_y_memoria_del_club",
	"_probar_ideas_roles_y_carrera",
	"_probar_ideas_directiva_calendario_y_rivalidades",
	"_probar_ideas_simulacion_del_partido",
	"_probar_ideas_club_y_calendario_de_pretemporada",
	"_probar_ideas_dinero_ciudad_y_lesiones",
	"_probar_ideas_tribunal_antidopaje_y_asamblea",
	"_probar_ideas_medicina_y_vestuario",
	"_probar_ideas_entrenamiento_prensa_y_dueno",
	"_probar_ideas_lote_a1",
	"_probar_ideas_lote_a2",
	"_probar_ideas_lote_a3",
	"_probar_ideas_lote_a4",
	"_probar_ideas_lote_b1",
	"_probar_ideas_lote_b2",
	"_probar_ideas_lote_b3",
	"_probar_ideas_lote_b4",
	"_probar_aspecto_y_audio",
	"_probar_marca",
	"_probar_tutorial",
	"_probar_moneda",
	"_probar_academia",
	"_probar_modos_simulacion",
	"_probar_presets_exportacion",
	"_probar_tema_y_ortografia",
	"_probar_eventos_nuevos",
	"_probar_entrevistas",
	"_probar_estadio_b6",
	"_probar_ciudad_b7",
	"_probar_coherencia_c1",
	"_probar_portadas_c20",
	"_probar_cantera_c3",
	"_probar_instituciones_c5_c8",
	"_probar_charlas_c6_c7",
	"_probar_licencia_c7",
	"_probar_tanda_c",
	"_probar_calendario_c13",
	"_probar_politica_c15",
	"_probar_palabras_prohibidas",
	"_probar_capitan_votado",
	"_probar_glifos_idiomas",
	"_probar_nombres_repetidos",
	"_probar_marcas_y_escudos",
	"_probar_faros_coches",
	"_probar_modulos",
	"_probar_piel_por_pais",
	"_probar_historia_c4",
	"_probar_contratos_c9",
	"_probar_vida_dt",
	"_probar_maestrias",
	"_probar_habilidades_en_resultados",
	"_probar_motor_libre",
	"_probar_portafolio_futbol",
	"_probar_jugadores_fijos",
	"_probar_disenos_kit",
	"_probar_guinos_estadio",
	"_probar_plantillas_fijas",
	"_probar_mesa_agente",
	"_probar_ciudad_animo",
	"_probar_ciudad_grande",
	"_probar_redes_ciudad",
	"_probar_cartera_dt",
	"_probar_cajero",
	"_probar_expendedora_balon",
	"_probar_parque_lleno",
	"_probar_cancha_patos",
	"_probar_comercio_lleno",
	"_probar_minijuegos",
	"_probar_leyes_pais",
	"_probar_incumplir_ley",
	"_probar_b6_formas_led",
	"_probar_region_reales",
	"_probar_tunel_navegable",
	"_probar_edificio_club",
	"_probar_personal_estadio",
	"_probar_sancion_dt",
	"_probar_peluches",
	"_probar_interiores_club",
	"_probar_galeria_club",
	"_probar_reforma_con_obra",
	"_probar_optimizacion",
	"_probar_dinastias",
	"_probar_documental",
	"_probar_tribuna_real",
	"_probar_narracion_traducida",
	"_probar_rotulo_y_sala",
	"_probar_transmision_y_estadisticas",
	"_probar_arreglos_partido_motor",
	"_probar_tanda_top25b",
	"_probar_prorroga_y_penales",
	"_probar_informe_rival",
	"_probar_logo",
	"_probar_porque_moral",
	"_probar_partido_abandonado",
	"_probar_no_atravesar_paredes",
	"_probar_paridad_idiomas",
]

## Dónde vive cada grupo, en el orden en que se buscan las secciones.
const ARCHIVOS := {
	"partido": "res://pruebas/banco/partido.gd",
	"guardado": "res://pruebas/banco/guardado.gd",
	"ciudad": "res://pruebas/banco/ciudad.gd",
	"estadio": "res://pruebas/banco/estadio.gd",
	"gestion": "res://pruebas/banco/gestion.gd",
	"competicion": "res://pruebas/banco/competicion.gd",
	"textos": "res://pruebas/banco/textos.gd",
	"ideas": "res://pruebas/banco/ideas.gd",
	"varios": "res://pruebas/banco/varios.gd",
}

var _tiempos: Array = []

## Segundos medidos (ver COSTES, 26-10) de las secciones lentas; el resto cuenta 0,4 s.
## Si una sección se alarga mucho, actualizar con el resumen TIEMPOS del final.
## MINI BANCOS (20-10-2026): grupos de secciones por situación, para probar
## solo lo que se tocó en segundos (`herramientas/mini_banco.sh <grupo>`, o
## BANCO_GRUPO=<grupo>). Antes de SUBIR sigue mandando el banco entero.
const GRUPOS := {
	"partido": ["_probar_partidos", "_probar_previa", "_probar_arbitros", "_probar_tactica_en_movimiento",
		"_probar_puente3d", "_probar_fisica_motor", "_probar_faltas_puntos", "_probar_transmision_y_estadisticas",
		"_probar_arreglos_partido_motor", "_probar_prorroga_y_penales", "_probar_partido_abandonado", "_probar_tanda_c",
		"_probar_notas", "_probar_dificultad_cpu"],
	"guardado": ["_probar_guardado", "_probar_guardado_seguro", "_probar_partido_abandonado", "_probar_repetibilidad"],
	"ciudad": ["_probar_modulos", "_probar_faros_coches", "_probar_ciudad", "_probar_ciudad_b7", "_probar_ciudad_animo", "_probar_ciudad_grande",
		"_probar_redes_ciudad", "_probar_cartera_dt", "_probar_cajero", "_probar_expendedora_balon", "_probar_parque_lleno", "_probar_cancha_patos", "_probar_comercio_lleno", "_probar_no_atravesar_paredes", "_probar_minijuegos", "_probar_optimizacion"],
	"estadio": ["_probar_estadio", "_probar_estadio_b6", "_probar_b6_formas_led", "_probar_tunel_navegable",
		"_probar_edificio_club", "_probar_personal_estadio", "_probar_interiores_club", "_probar_galeria_club",
		"_probar_reforma_con_obra", "_probar_guinos_estadio", "_probar_vallas_led", "_probar_ola_grada",
		"_probar_rendimiento_adaptativo"],
	"gestion": ["_probar_piel_por_pais", "_probar_capitan_votado", "_probar_finanzas", "_probar_mercado", "_probar_directiva", "_probar_staff", "_probar_obras",
		"_probar_cantera", "_probar_cesiones", "_probar_negociacion", "_probar_contratos_c9", "_probar_economia",
		"_probar_leyes_pais", "_probar_incumplir_ley", "_probar_vender", "_probar_ojeadores"],
	"competicion": ["_probar_calendario", "_probar_copa", "_probar_continental", "_probar_selecciones",
		"_probar_ascensos", "_probar_temporadas"],
	"textos": ["_probar_paridad_idiomas", "_probar_narracion_traducida", "_probar_tema_y_ortografia", "_probar_carga_de_ui", "_probar_palabras_prohibidas", "_probar_glifos_idiomas"],
}

const COSTES := {
	## 26-10: TODOS los que pasan de 1 s, medidos en el banco entero (4 partes, máquina cargada:
	## lo que cuenta es la proporción). Con los de antes (15-10) una parte acababa 40 s después
	## que otra; con estos, el reparto sale parejo. Rehacer con el resumen TIEMPOS si se desequilibra.
	"_probar_motor_libre": 137.9, "_probar_cantera": 97.5, "_probar_logros": 95.3, "_probar_selecciones": 83.7,
	"_probar_finanzas": 62.9, "_probar_pulso_de_roles": 58.6, "_probar_roles_y_federacion": 46.2,
	"_probar_temporadas": 38.9, "_probar_guardado": 29.5, "_probar_arbitros": 29.2, "_probar_fisica_motor": 28.6,
	"_probar_cubierta_nombres": 27.1, "_probar_base_ficticia": 26.2, "_probar_partidos": 23.0, "_probar_copa": 23.0,
	"_probar_continental": 20.7, "_probar_cesiones": 18.6, "_probar_dificultad_cpu": 17.4,
	"_probar_ideas_directiva_calendario_y_rivalidades": 15.0, "_probar_faltas_puntos": 14.4, "_probar_ciudad_b7": 13.9,
	"_probar_ideas_eventos_de_despacho": 13.3, "_probar_mundo": 12.7, "_probar_ideas_premios_y_memoria_del_club": 11.7,
	"_probar_desafios": 11.2, "_probar_documental": 10.5, "_probar_fundar_club": 9.1, "_probar_ideas_lote_b4": 8.8,
	"_probar_ascensos": 6.9, "_probar_ojeadores": 6.8, "_probar_habilidades_en_resultados": 6.8,
	"_probar_modos_simulacion": 6.5, "_probar_ideas_lote_a2": 6.1, "_probar_ideas_lote_a3": 6.1,
	"_probar_ideas_lote_a1": 5.4, "_probar_repetibilidad": 4.8, "_probar_pie_habil": 4.4,
	"_probar_palabras_prohibidas": 3.8, "_probar_aspecto_y_audio": 3.8, "_probar_transmision_y_estadisticas": 3.4,
	"_probar_marcas_y_escudos": 3.4, "_probar_banquillo": 3.2, "_probar_historia_c4": 3.0, "_probar_estadio_b6": 3.0,
	"_probar_tanda_c": 2.9, "_probar_eventos_nuevos": 2.7, "_probar_guardado_seguro": 2.7,
	"_probar_eras_y_precios": 2.6, "_probar_estadio": 2.6, "_probar_puente3d": 2.6, "_probar_directiva": 2.6,
	"_probar_carga_de_ui": 2.5, "_probar_ciudad_animo": 2.3, "_probar_consejeros": 2.3, "_probar_calendario": 2.3,
	"_probar_tunel_navegable": 2.2, "_probar_porque_moral": 2.1, "_probar_ideas_lote_a4": 2.1, "_probar_mercado": 2.0,
	"_probar_editor": 1.9, "_probar_notas": 1.9, "_probar_reales": 1.8, "_probar_vender": 1.5, "_probar_banco": 1.4,
	"_probar_ideas_lote_b2": 1.4, "_probar_previa": 1.3, "_probar_staff": 1.3, "_probar_tema_y_ortografia": 1.3,
	"_probar_auspicio": 1.3, "_probar_sancion_dt": 1.2, "_probar_negociacion": 1.1, "_probar_capitan_votado": 1.0,
	## Coste mínimo a propósito: va la última en el reparto y no mueve a las demás
	## (`_probar_motor_libre` depende del estado que dejan las secciones previas de
	## su proceso; ver el HALLAZGO en CLAUDE.md). Mide ~0,5 s.
	"_probar_prorroga_y_penales": 0.01,
}
var _reparto: Array = []
## Nodo de grupo que tiene cada sección (se rellena al cargar).
var _donde := {}

## Reparto entre procesos equilibrado por tiempo: la sección más lenta que
## queda va al proceso con menos carga. Determinista: todos los procesos
## calculan el mismo reparto.
func _parte_de(i: int, total: int) -> int:
	if _reparto.size() != SECCIONES.size():
		_reparto.resize(SECCIONES.size())
		var orden: Array = range(1, SECCIONES.size())
		orden.sort_custom(func(a: int, b: int) -> bool:
			var ca := float(COSTES.get(SECCIONES[a], 0.4))
			var cb := float(COSTES.get(SECCIONES[b], 0.4))
			return ca > cb if ca != cb else a < b)
		var carga: Array = []
		carga.resize(total)
		carga.fill(0.0)
		for j: int in orden:
			var menos := 0
			for k in total:
				if float(carga[k]) < float(carga[menos]):
					menos = k
			_reparto[j] = menos
			carga[menos] = float(carga[menos]) + float(COSTES.get(SECCIONES[j], 0.4))
	return int(_reparto[i])

func _cerrar() -> void:
	## Las secciones más lentas, para saber dónde mirar si el banco se alarga.
	_tiempos.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) > int(b[0]))
	var suma := 0
	for tt: Array in _tiempos:
		suma += int(tt[0])
	_linea("")
	_linea("TIEMPOS: %d secciones, %.1f s" % [_tiempos.size(), suma / 1000.0])
	for tt: Array in _tiempos.slice(0, 40):
		_linea("  %6.1f s  %s" % [int(tt[0]) / 1000.0, String(tt[1])])
	_linea("")
	if _fallos.is_empty():
		_linea("===== FIN. 0 fallos =====")
	else:
		_linea("===== FIN. %d FALLOS =====" % _fallos.size())
		for f in _fallos:
			_linea("  - %s" % f)
	## Por partes, cada proceso deja la suya en `user://` (aislado) y `banco.sh` las junta.
	var ruta_res := "user://banco_resultado.txt" if OS.get_environment("BANCO_PARTE") != "" \
		else "res://pruebas/ultimo_resultado.txt"
	var salida := FileAccess.open(ruta_res, FileAccess.WRITE)
	if salida != null:
		salida.store_string("\n".join(_lineas))
		salida.close()
	get_tree().quit(0 if _fallos.is_empty() else 1)

## Carga los nodos de grupo que hacen falta: todos en el banco entero; con BANCO_GRUPO, el de ese
## grupo primero y otro solo si le presta una sección. Comprueba que SECCIONES y los archivos casan.
func _cargar_grupos(necesarias: Array) -> void:
	var nombres: Array = ARCHIVOS.keys()
	var grupo := OS.get_environment("BANCO_GRUPO")
	if grupo != "" and ARCHIVOS.has(grupo):
		nombres.erase(grupo)
		nombres.push_front(grupo)
	var todas := necesarias.size() == SECCIONES.size()
	var huerfanas: Array = []
	for g: String in nombres:
		var falta := false
		for s: String in necesarias:
			falta = falta or not _donde.has(s)
		if not falta and not todas and (not necesarias.is_empty() or _donde.size() > 0):
			break
		var nodo: Node = (load(String(ARCHIVOS[g])) as GDScript).new()
		nodo.name = "grupo_" + g
		add_child(nodo)
		for met: Dictionary in nodo.get_script().get_script_method_list():
			var n := String(met["name"])
			if n.begins_with("_probar_") and not _donde.has(n) and SECCIONES.has(n):
				_donde[n] = nodo
			elif n.begins_with("_probar_") and not SECCIONES.has(n) and (met["args"] as Array).is_empty() and not _es_ayudante(n) and not huerfanas.has(n):
				huerfanas.append(n)
	if todas:
		var sin_archivo: Array = SECCIONES.filter(func(s: String) -> bool: return not _donde.has(s))
		## Solo dejan línea si fallan: así el recuento de «ok» del banco no cambia.
		if not sin_archivo.is_empty():
			_comprobar(false, "cada sección de SECCIONES vive en un archivo de grupo %s" % str(sin_archivo))
		if not huerfanas.is_empty():
			_comprobar(false, "cada `_probar_*` sin argumentos de los grupos está en SECCIONES (si no, nunca corre) %s" % str(huerfanas))

## Partes de una sección grande (`_probar_guardado_1`…): no van solas en SECCIONES.
func _es_ayudante(n: String) -> bool:
	for s: String in SECCIONES:
		if n.begins_with(s + "_") and n.trim_prefix(s + "_").is_valid_int():
			return true
	return false

func _ready() -> void:
	## Lo que queda entre partidas (`Meta`) va a un archivo propio del banco:
	## si no, cada corrida llenaría el álbum de verdad con sobres de prueba.
	Meta.ruta = "user://meta_banco.json"
	if FileAccess.file_exists(Meta.ruta):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.ruta))
	_titulo("BANCO DE PRUEBAS DEL NUCLEO")
	## El banco se escribió contra los datos REALES (Colo-Colo, Vidal, las
	## equipaciones archivadas...) y así sigue: se corre con el pack real
	## encima. La base ficticia -la que se publica- tiene su propia sección,
	## `_probar_base_ficticia()`, que deja el pack puesto otra vez al salir.
	## La preferencia del jugador (`user://ajustes.cfg`) no se toca.
	Datos.usar_base_real(true)
	## PRIMERO, Y BARATO: que las tres escenas raíz compilen. Si algo rompió la
	## interfaz -el error exacto que costó un juego que no arrancaba el 25-9-,
	## mejor saberlo en el primer segundo que después de 15 minutos de banco.
	## Cada sección se cronometra (el resumen sale al final) y, con
	## BANCO_PARTE=i/N, este proceso corre solo su parte: `herramientas/banco.sh`
	## lanza N a la vez (uno por núcleo) y junta los resultados.
	var parte := OS.get_environment("BANCO_PARTE")
	var mia := 0
	var total := 1
	if parte.contains("/"):
		mia = int(parte.get_slice("/", 0))
		total = maxi(1, int(parte.get_slice("/", 1)))
	## BANCO_SOLO=_probar_x (20-10-2026): solo esa sección (para diagnosticar).
	var solo := OS.get_environment("BANCO_SOLO")
	var grupo := OS.get_environment("BANCO_GRUPO")
	var mias: Array = []
	for i in SECCIONES.size():
		## La carga de la interfaz va en todas: es barata y si falla, mejor saberlo ya.
		if i > 0 and _parte_de(i, total) != mia:
			continue
		if solo != "" and SECCIONES[i] != solo:
			continue
		if grupo != "" and GRUPOS.has(grupo) and not (GRUPOS[grupo] as Array).has(SECCIONES[i]):
			continue
		mias.append(SECCIONES[i])
	## Un grupo que solo es archivo («ideas», «varios»): todas las secciones que viven en él.
	if grupo != "" and not GRUPOS.has(grupo) and ARCHIVOS.has(grupo):
		_cargar_grupos([])
		mias = mias.filter(func(s: String) -> bool: return _donde.has(s) and (_donde[s] as Node).name == "grupo_" + grupo)
	## Sin filtro de grupo ni sección se cargan TODOS los grupos (también en cada parte del
	## banco entero), para que la comprobación de SECCIONES ↔ archivos corra siempre.
	if _donde.is_empty():
		_cargar_grupos(SECCIONES if solo == "" and grupo == "" else mias)
	for s: String in mias:
		if not _donde.has(s):
			_fallos.append("la sección %s no está en ningún archivo de grupo" % s)
			_linea("  FALLO la sección %s no está en ningún archivo de grupo" % s)
			continue
		var t0 := Time.get_ticks_msec()
		(_donde[s] as Node).call(s)
		_tiempos.append([Time.get_ticks_msec() - t0, s])
	_cerrar()
