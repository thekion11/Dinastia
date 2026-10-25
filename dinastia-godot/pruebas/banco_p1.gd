extends Node
## [Capa 1/27 de `banco.gd`] _linea, _titulo, _parte_de, _cerrar, _ready, _comprobar … (+3)

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
	"_probar_staff",
	"_probar_obras",
	"_probar_roles_y_federacion",
	"_probar_estadio",
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
	"_probar_minijuegos",
	"_probar_leyes_pais",
	"_probar_incumplir_ley",
	"_probar_b6_formas_led",
	"_probar_region_reales",
	"_probar_tunel_navegable",
	"_probar_edificio_club",
	"_probar_personal_estadio",
	"_probar_sancion_dt",
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
	"_probar_porque_moral",
	"_probar_partido_abandonado",
	"_probar_no_atravesar_paredes",
	"_probar_paridad_idiomas",
]

var _fallos: Array[String] = []
var _tiempos: Array = []
var _lineas: Array[String] = []

## Segundos medidos (15-10-2026) de las secciones lentas; el resto cuenta 0,4 s.
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
		"_probar_no_atravesar_paredes", "_probar_minijuegos", "_probar_optimizacion"],
	"estadio": ["_probar_estadio", "_probar_estadio_b6", "_probar_b6_formas_led", "_probar_tunel_navegable",
		"_probar_edificio_club", "_probar_personal_estadio", "_probar_interiores_club", "_probar_galeria_club",
		"_probar_reforma_con_obra", "_probar_guinos_estadio", "_probar_vallas_led", "_probar_ola_grada"],
	"gestion": ["_probar_piel_por_pais", "_probar_capitan_votado", "_probar_finanzas", "_probar_mercado", "_probar_directiva", "_probar_staff", "_probar_obras",
		"_probar_cantera", "_probar_cesiones", "_probar_negociacion", "_probar_contratos_c9", "_probar_economia",
		"_probar_leyes_pais", "_probar_incumplir_ley", "_probar_vender", "_probar_ojeadores"],
	"competicion": ["_probar_calendario", "_probar_copa", "_probar_continental", "_probar_selecciones",
		"_probar_ascensos", "_probar_temporadas"],
	"textos": ["_probar_paridad_idiomas", "_probar_narracion_traducida", "_probar_tema_y_ortografia", "_probar_carga_de_ui", "_probar_palabras_prohibidas", "_probar_glifos_idiomas"],
}

const COSTES := {
	"_probar_guardado_seguro": 1.5, "_probar_fisica_motor": 8.0, "_probar_faltas_puntos": 1.5, "_probar_vallas_led": 0.5, "_probar_palabras_prohibidas": 1.0, "_probar_capitan_votado": 2.0, "_probar_glifos_idiomas": 0.5, "_probar_nombres_repetidos": 2.0, "_probar_marcas_y_escudos": 4.0, "_probar_faros_coches": 0.3, "_probar_modulos": 1.0, "_probar_piel_por_pais": 0.5, "_probar_ola_grada": 0.3, "_probar_dificultad_cpu": 1.5, "_probar_motor_libre": 27.3, "_probar_logros": 16.4, "_probar_cantera": 12.5,
	"_probar_selecciones": 9.1, "_probar_temporadas": 8.7, "_probar_finanzas": 5.1,
	"_probar_ciudad_b7": 4.2, "_probar_copa": 3.6, "_probar_cesiones": 3.2,
	"_probar_aspecto_y_audio": 3.1, "_probar_pulso_de_roles": 3.1, "_probar_estadio_b6": 2.6,
	## Coste mínimo a propósito: va la última en el reparto y no mueve a las demás
	## (`_probar_motor_libre` depende del estado que dejan las secciones previas de
	## su proceso; ver el HALLAZGO en CLAUDE.md). Mide ~0,5 s.
	"_probar_prorroga_y_penales": 0.01,
}
var _reparto: Array = []

## M-240 (20-10): la política es ficticia y no se atribuye religión a nadie. Se
## vigila que no se cuelen políticos o partidos reales ni religiones en los textos
## del juego (código y narración). El calendario (fiestas como el Ramadán) es la
## única excepción: habla de fechas, no de personas.
const PROHIBIDAS_POLITICA := "PSOE|Bolsonaro|Trump|Biden|Boric|Milei|Lula|Macron|Pinochet|Maduro|peronismo|peronista|kirchnerismo|kirchnerista|franquismo|chavismo|chavista"
const PROHIBIDAS_RELIGION := "católico|católica|musulmán|musulmana|evangélico|evangélica|judío|judía|protestante|budista|ateo|atea"

## NO SE ATRAVIESAN PAREDES (17-10-2026, caza de bugs): con un coche del
## tráfico encima, antes se podía entrar caminando en un edificio.
class _ExpPared extends ExploradorCiudad:
	var pared_x := 5.0
	var movil_encima := false
	func libre_obst(p: Vector3, radio: float) -> bool:
		return p.x + radio < pared_x
	func _choca_moviles(_p: Vector3, _radio: float) -> bool:
		return movil_encima
	func _choca_circulos(_p: Vector3, _radio: float) -> bool:
		return false

func _linea(t: String) -> void:
	_lineas.append(t)
	print(t)

func _titulo(t: String) -> void:
	_linea("")
	_linea("===== %s =====" % t)

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
	for tt: Array in _tiempos.slice(0, 12):
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
	for i in SECCIONES.size():
		## La carga de la interfaz va en todas: es barata y si falla, mejor saberlo ya.
		if i > 0 and _parte_de(i, total) != mia:
			continue
		## BANCO_SOLO=_probar_x (20-10-2026): solo esa sección (para diagnosticar).
		var solo := OS.get_environment("BANCO_SOLO")
		if solo != "" and SECCIONES[i] != solo:
			continue
		var grupo := OS.get_environment("BANCO_GRUPO")
		if grupo != "" and not (GRUPOS.get(grupo, []) as Array).has(SECCIONES[i]):
			continue
		var t0 := Time.get_ticks_msec()
		call(SECCIONES[i])
		_tiempos.append([Time.get_ticks_msec() - t0, SECCIONES[i]])
	_cerrar()

func _comprobar(condicion: bool, que: String) -> void:
	if condicion:
		_linea("  ok    %s" % que)
	else:
		_fallos.append(que)
		_linea("  FALLO %s" % que)

# ---------------------------------------------------------------------------

func _probar_datos() -> void:
	_titulo("DATOS EXPORTADOS DEL HTML")
	_comprobar(Datos.cargado, "el JSON de tablas carga")
	_linea("  %d tablas disponibles" % Datos.cuantas())
	for t in ["DATA_P1", "DATA_P2", "PAISES_LIGAS", "POSD", "FORMS", "NOMBRES", "APELLIDOS", "RASGOS"]:
		_comprobar(Datos.tiene(t), "esta la tabla %s" % t)
	## El CONTENIDO de las tablas, no solo su presencia. Que una tabla exista no
	## significa que traiga lo que dice su nombre: el script de exportacion tenia
	## una variable llamada NOMBRES que tapaba a la constante NOMBRES del juego, y
	## se exportaron los nombres de las TABLAS como si fueran nombres de pila.
	## Todos los futbolistas se llamaban "VALOR_PIVOTE Ahumada" y el banco daba
	## cero fallos, porque comprobaba que la tabla estuviera, no que sirviera.
	var pila: Array = Datos.tabla("NOMBRES")
	var apes: Array = Datos.tabla("APELLIDOS")
	_comprobar(pila.size() > 20 and not String(pila[0]).is_empty(), "NOMBRES trae una lista larga (%d)" % pila.size())
	_comprobar(not String(pila[0]).to_upper() == String(pila[0]), "NOMBRES trae nombres de pila, no constantes en mayusculas (%s)" % pila[0])
	_comprobar(apes.size() > 20, "APELLIDOS trae una lista larga (%d)" % apes.size())
	var p1: Array = Datos.tabla("DATA_P1")
	_comprobar(p1.size() > 10 and p1[0].size() >= 5, "DATA_P1 trae filas de club completas")
	_comprobar(int(p1[0][3]) > 0 and int(p1[0][4]) > 0, "las filas de club traen reputacion y aforo")

	## El leetspeak tiene que deshacerse solo donde toca.
	_comprobar(Nombres.limpiar("C0lo-C0lo") == "Colo-Colo", "descensurar: C0lo-C0lo -> Colo-Colo")
	_comprobar(Nombres.limpiar("B0ca Juni0rs") == "Boca Juniors", "descensurar: B0ca Juni0rs -> Boca Juniors")
	_comprobar(Nombres.limpiar("Racing 1904") == "Racing 1904", "descensurar NO toca los anos sueltos")

func _probar_repetibilidad() -> void:
	_titulo("REPETIBILIDAD (lo que el HTML no puede hacer)")
	var a := Mundo.new()
	a.generar(["CHI"], 12345)
	var b := Mundo.new()
	b.generar(["CHI"], 12345)
	_comprobar(a.cuantos_jugadores() == b.cuantos_jugadores(), "misma semilla, mismo numero de jugadores")
	var ja := a.jugadores()
	var jb := b.jugadores()
	var iguales := true
	for i in mini(ja.size(), jb.size()):
		if ja[i].nombre != jb[i].nombre or ja[i].ovr != jb[i].ovr:
			iguales = false
			break
	_comprobar(iguales, "misma semilla, mismos jugadores uno a uno")
	## Desde la fase 4 las plantillas de ARRANQUE son fijas (sembradas con el
	## nombre del club): lo que cambia con la semilla es el mundo que corre,
	## empezando por los resultados de la primera jornada.
	var c := Mundo.new()
	c.generar(["CHI"], 999)
	var res_a := str(a.ligas[0].jugar_jornada()) + str(a.ligas[0].jugar_jornada())
	var res_c := str(c.ligas[0].jugar_jornada()) + str(c.ligas[0].jugar_jornada())
	_comprobar(res_a != res_c, "otra semilla, otro mundo (otros resultados)")

func _probar_mundo() -> void:
	_titulo("GENERACION DEL MUNDO")
	var m := Mundo.new()
	m.generar([], 7)
	_linea("  %d clubes, %d jugadores, %d ligas" % [m.clubes.size(), m.cuantos_jugadores(), m.ligas.size()])
	_comprobar(m.clubes.size() > 300, "se generan mas de 300 clubes")
	_comprobar(m.ligas.size() >= 20, "se generan al menos 20 ligas")
	var sin_plantilla := 0
	var sin_portero := 0
	var media_mala := 0
	for c: Club in m.clubes.values():
		if c.plantilla.size() < 18:
			sin_plantilla += 1
		var porteros := 0
		for j in c.plantilla:
			if j.es_portero():
				porteros += 1
			if j.ovr < 40 or j.ovr > 96:
				media_mala += 1
		if porteros == 0:
			sin_portero += 1
	_comprobar(sin_plantilla == 0, "ningun club se queda sin plantilla (%d)" % sin_plantilla)
	_comprobar(sin_portero == 0, "todos los clubes tienen portero (%d sin)" % sin_portero)
	_comprobar(media_mala == 0, "ninguna media fuera de [40,96] (%d)" % media_mala)
	## El once tiene que salir completo incluso con la enfermeria llena: en el
	## HTML esto no estaba al principio y un club sin once dejaba el partido a
	## medias y reventaba la jornada entera.
	var uno: Club = m.clubes.values()[0]
	for j in uno.plantilla:
		j.lesion = 5
	var once := uno.once()
	_comprobar(once.size() == 11, "sale un once de 11 aunque esten todos lesionados (%d)" % once.size())

	## La edad tiene que pesar en la media. Sin el castigo del HTML a los menores
	## de 20 salian canteranos de 17 anos con media 96 y 223 millones de valor,
	## que en un manager es lo mismo que decirle al jugador que no se lo crea.
	var media_joven := 0.0
	var n_joven := 0
	var media_pico := 0.0
	var n_pico := 0
	var cracks_ninos := 0
	for c: Club in m.clubes.values():
		for j in c.plantilla:
			if j.edad <= 19:
				media_joven += float(j.ovr); n_joven += 1
				if j.ovr >= 90:
					cracks_ninos += 1
			elif j.edad >= 25 and j.edad <= 29:
				media_pico += float(j.ovr); n_pico += 1
	media_joven /= float(maxi(n_joven, 1))
	media_pico /= float(maxi(n_pico, 1))
	_linea("  media de los menores de 20: %.1f   |   de los 25-29: %.1f" % [media_joven, media_pico])
	_comprobar(media_joven < media_pico, "los chicos son peores que los de su mejor edad")
	_comprobar(cracks_ninos == 0, "no hay ninos de 19 con media 90+ (%d)" % cracks_ninos)

	## Y el reparto por puestos: ningun club puede quedarse sin una demarcacion.
	var incompletos := 0
	for c: Club in m.clubes.values():
		var tiene := {}
		for j in c.plantilla:
			tiene[Datos.grupo(j.pos_e)] = true
		if tiene.size() < 4:
			incompletos += 1
	_comprobar(incompletos == 0, "todos los clubes tienen las cuatro lineas (%d sin)" % incompletos)
