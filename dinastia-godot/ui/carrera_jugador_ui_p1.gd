extends Control
## [Capa 1/2 de `carrera_jugador_ui.gd`] _limpiar, _st, _panel, _lbl, _boton, _crear … (+18)

## LA CARRERA DE JUGADOR, SU PANTALLA. Desde el 13-11-2026 es «LA RUTA»: la
## estética y las pantallas viven en `ui/carrera/` (`RutaEstilo`, `RutaHoy`,
## `RutaYo`, `RutaCamino`, `RutaCrear`, `RutaToque`, `RutaResumen`); aquí queda
## lo que mueve la carrera: crear, cerrar la semana, jugar, la selección y el
## retiro.

const GUARDADO := "carrera_jugador"

static var mundo: Mundo
static var nombre_pedido := ""

var carrera: CarreraJugador
var _cuerpo: Control
var _msg := ""
var _puesto := "DC"
var _zurdo := false
var _campo_nombre: LineEdit
var _pestana := "hoy"

func _limpiar() -> void:
	for n in _cuerpo.get_children():
		_cuerpo.remove_child(n)
		n.queue_free()

## Crea el mundo y a tu futbolista (todavía en el club que pone el núcleo).
func _fundar() -> void:
	var nombre := _campo_nombre.text.strip_edges() if _campo_nombre != null else ""
	if nombre == "":
		nombre = "Tomás Aravena"
	var m := Mundo.new()
	Escudo.limpiar_cache()
	Cara.limpiar_cache()
	m.generar(LigasActivas.para_generar(), 0)
	m.mi_club_id = ""
	m.carrera_jugador = CarreraJugador.crear(m, nombre, _puesto, _zurdo, int(Time.get_unix_time_from_system()))
	mundo = m
	carrera = m.carrera_jugador

## Firma por `destino` (o se queda donde lo puso el núcleo) y empieza la ruta.
func _firmar(destino: Club) -> void:
	CarreraComienzo.mudar(carrera, mundo, destino)
	_msg = Idiomas.t("Firmaste con %s. Dorsal %d.") % [Nombres.visible(carrera.club(mundo).nombre), carrera.jugador(mundo).dorsal]
	_pestana = "hoy"
	(self as CarreraJugadorUI)._pintar_semana()

## De una vez (pruebas y herramientas): funda y firma sin elegir club.
func _crear() -> void:
	_fundar()
	_firmar(null)

## Paso 2 de la creación: tres clubes de tres países te ofrecen contrato.
func _buscar_club() -> void:
	_fundar()
	var ofertas := CarreraComienzo.pruebas(mundo, hash(carrera.jugador_id))
	if ofertas.is_empty():
		_firmar(null)
	else:
		RutaCrear.pintar_ofertas(self, ofertas)

func _hay_guardada() -> bool:
	for d: Dictionary in Partida.listar():
		if String(d.get("nombre", "")) == GUARDADO:
			return true
	return false

func _salir() -> void:
	get_tree().change_scene_to_file("res://escenas/inicio.tscn")

func _pintar_crear() -> void:
	RutaCrear.pintar(self)

func _guardar() -> void:
	_msg = "Carrera guardada." if Partida.guardar(mundo, GUARDADO) else "No se pudo guardar."
	(self as CarreraJugadorUI)._pintar_semana()

func _cerrar_seleccion(res: Dictionary) -> void:
	var nombre := String(carrera.convocatoria.get("nombre", "tu selección"))
	var rival := String(carrera.convocatoria.get("rival", ""))
	carrera.tras_seleccion(res)
	if mundo.selecciones != null:
		mundo.selecciones._anotar_resultado("%s %d - %d %s" % [nombre, int(res.get("goles_local", 0)), int(res.get("goles_visita", 0)), rival])
	_msg = Idiomas.t("🌎 %s %d - %d %s · tu nota %.1f") % [nombre, int(res.get("goles_local", 0)), int(res.get("goles_visita", 0)), rival, float(res.get("nota", 6.0))]
	if int(res.get("goles", 0)) > 0:
		_msg += " · " + Idiomas.t("¡%d gol(es) con la selección!") % int(res["goles"])
	Partida.guardar(mundo, GUARDADO)
	(self as CarreraJugadorUI)._pintar_semana()

## El partido con la selección, en «Los Momentos».
func _momentos_seleccion() -> void:
	var eq := carrera.equipos_seleccion(mundo)
	if eq.size() < 2:
		return
	var mo := RutaMomentos.abrir(self, [eq[0], eq[1]], -1, false, eq[0])
	mo.terminado.connect(func(res: Dictionary) -> void: _cerrar_seleccion(res))

## El partido con la selección: clubes de paso, tú del lado de tu país.
func _jugar_seleccion() -> void:
	var eq := carrera.equipos_seleccion(mundo)
	if eq.size() < 2:
		return
	var pj = load("res://ui/partido_jugable.gd").abrir(self, mundo, carrera, eq[0], eq[1], 240.0, -1, eq[0])
	pj.terminado.connect(func(res: Dictionary) -> void: _cerrar_seleccion(res))

func _simular_seleccion() -> void:
	var j := carrera.jugador(mundo)
	var g := 1 if j != null and randf() < (0.35 if j.pos == "DEL" else 0.12) else 0
	_cerrar_seleccion({"goles": g, "goles_local": g + randi_range(0, 2), "goles_visita": randi_range(0, 2), "nota": 6.5 + g})

func _ser_entrenador(c: Club) -> void:
	## Respaldo de la partida de entrenador que hubiera.
	var previa := Partida.cargar("partida")
	if previa != null:
		Partida.guardar(previa, "partida_respaldo")
	if not carrera.pasar_a_entrenador(mundo, c):
		return
	Partida.guardar(mundo, GUARDADO)
	Partida.guardar(mundo, "partida")
	PedidoPartida.mundo_a_cargar = mundo
	get_tree().change_scene_to_file("res://escenas/principal.tscn")

func _retiro_final() -> void:
	carrera.retirado = true
	Partida.guardar(mundo, GUARDADO)
	_salir()

func _pintar_retiro() -> void:
	RutaCrear.pintar_retiro(self)

func _nueva_temporada() -> void:
	mundo.nueva_temporada()
	_msg = "Nueva temporada. Un año más."
	Partida.guardar(mundo, GUARDADO)
	(self as CarreraJugadorUI)._pintar_semana()

# ---------------------------------------------------------------- jugar

## Si esta semana hay copa, manda la copa (como en el modo entrenador): es a
## partido único, con prórroga y penales (`CarreraCopa`).
func _partido_de_la_semana(club: Club) -> Array:
	var cp := CarreraCopa.partido(mundo, club)
	return cp if not cp.is_empty() else CarreraJugador.partido_de_la_semana(mundo, club)

## Cierra la semana: el partido (jugado o simulado), el mundo y lo que te pasa.
## El aviso de la semana une varias frases con «·»: cada una se traduce por
## su plantilla ANTES de meterle los números (el texto ya montado no casa con
## el diccionario y en otros idiomas salía en castellano).
func _cerrar_semana(res: Dictionary, ya_entrenado := false) -> void:
	var m := mundo
	var j := carrera.jugador(m)
	var club := carrera.club(m)
	var par := _partido_de_la_semana(club)
	if not ya_entrenado:
		_msg = carrera.entrenar(m)
	var titular := carrera.es_titular(m)
	var es_copa := CarreraCopa.es_copa(m, par)
	if bool(res.get("sin_minutos", false)):
		res = {}
	if not res.is_empty() and not par.is_empty():
		var p := Partido.new(par[0], par[1])
		p.goles_local = int(res["goles_local"])
		p.goles_visita = int(res["goles_visita"])
		## La tanda del césped va al acta: la copa la lee con `penales()`.
		var pen: Array = res.get("penales", [])
		if es_copa and p.goles_local == p.goles_visita and pen.size() == 2:
			p.penales_externos(int(pen[0]), int(pen[1]))
		m.avanzar_semana(p)
		carrera.tras_partido(m, res)
		carrera.partidos_jugables += 1
		_msg += "  ·  " + Idiomas.t("Final %d-%d, tu nota %.1f (%d').") % [p.goles_local, p.goles_visita, float(res["nota"]), int(res.get("minutos", 90))]
		if bool(res.get("sustituido", false)):
			_msg += " " + Idiomas.t("El DT te cambió.")
		if es_copa:
			_msg += " " + CarreraCopa.texto_penales(p, club)
	else:
		var goles_antes := j.goles if j != null else 0
		var gc_antes := CarreraPortero.goles_en_contra(m, club)
		## La copa simulada también se decide con prórroga y penales; tus goles
		## son los del cruce (la liga de tu club se simula aparte esa semana).
		var copa_p: Partido = null
		if es_copa:
			copa_p = Partido.new(par[0], par[1])
			CarreraCopa.simular(copa_p)
		var g_copa := (j.goles - goles_antes) if j != null else 0
		m.avanzar_semana(copa_p)
		if copa_p != null:
			_msg += "  ·  " + Idiomas.t("Copa: %s %d-%d %s.") % [Nombres.visible(copa_p.local.nombre), copa_p.goles_local,
				copa_p.goles_visita, Nombres.visible(copa_p.visita.nombre)]
			var tp := CarreraCopa.texto_penales(copa_p, club)
			if tp != "":
				_msg += " " + tp
		if titular and not par.is_empty() and j != null:
			var g := g_copa if es_copa else j.goles - goles_antes
			## La nota del simulado: la de tu nivel, más lo que marcaste (el
			## portero, por lo que encajó: `CarreraPortero.nota_simulada`).
			var nota := clampf(5.6 + float(j.ovr - 55) * 0.04 + float(g) * 0.9 + randf_range(-0.6, 0.6), 4.0, 9.5)
			var gc := CarreraPortero.goles_en_contra(m, club) - gc_antes
			if copa_p != null:
				gc = copa_p.goles_visita if copa_p.local == club else copa_p.goles_local
			if j.es_portero():
				nota = CarreraPortero.nota_simulada(j, gc, randf_range(-0.5, 0.5))
			j.goles -= g
			carrera.tras_partido(m, {"minutos": 90, "goles": g, "asist": 0, "nota": snappedf(nota, 0.1), "titular": true, "encajados": gc})
			_msg += "  ·  " + Idiomas.t("Jugaste (simulado): %d gol(es), nota %.1f.") % [g, nota]
		elif not titular and not par.is_empty() and j != null and j.disponible():
			## Suplente simulado: a veces entras un rato.
			var entra := carrera.minuto_entrada_suplente(j.es_portero())
			if entra >= 0:
				var minutos := 90 - entra
				var g2 := 1 if randf() < float(minutos) / 90.0 * (0.25 if j.pos == "DEL" else (0.0 if j.es_portero() else 0.08)) else 0
				var nota2 := clampf(5.8 + float(j.ovr - 55) * 0.03 + float(g2) * 0.9 + randf_range(-0.4, 0.4), 4.5, 9.0)
				carrera.tras_partido(m, {"minutos": minutos, "goles": g2, "asist": 0, "nota": snappedf(nota2, 0.1), "titular": false})
				_msg += "  ·  " + Idiomas.t("Entraste en el %d' (simulado): nota %.1f.") % [entra, nota2]
			else:
				_msg += "  ·  " + Idiomas.t("No saliste del banco.")
	var nuevos := carrera.semana(m)
	if carrera.aviso_agenda != "":
		_msg += "  ·  " + carrera.aviso_agenda
	if not nuevos.is_empty():
		_msg += "  ·  " + Idiomas.t("¡%s!") % Idiomas.t(String(nuevos[0]["titulo"]))
	if not m.temporada_en_curso():
		carrera.fin_de_temporada(m)
		_msg += "  ·  " + Idiomas.t("Terminó la temporada.")
	Partida.guardar(m, GUARDADO)
	(self as CarreraJugadorUI)._pintar_semana()

func _jugar_partido() -> void:
	var club := carrera.club(mundo)
	var par := _partido_de_la_semana(club)
	if par.is_empty():
		return
	_msg = carrera.entrenar(mundo)
	var pj = load("res://ui/partido_jugable.gd").abrir(self, mundo, carrera, par[0], par[1], 240.0, -1, null, CarreraCopa.es_copa(mundo, par))
	pj.terminado.connect(func(res: Dictionary) -> void: _cerrar_semana(res, true))

## «LOS MOMENTOS»: el partido en tus jugadas clave (`RutaMomentos`). Titular,
## las cuatro; suplente, las dos últimas si el DT te hace entrar.
func _jugar_momentos() -> void:
	var club := carrera.club(mundo)
	var par := _partido_de_la_semana(club)
	var yo := carrera.jugador(mundo)
	if par.is_empty() or yo == null or not yo.disponible():
		return
	_msg = carrera.entrenar(mundo)
	var minuto := -1
	if not carrera.es_titular(mundo):
		minuto = carrera.minuto_entrada_suplente(yo.es_portero())
		if minuto < 0:
			_msg += "  ·  " + Idiomas.t("Calentaste toda la segunda parte, pero el DT no te hizo entrar.")
			_cerrar_semana({"sin_minutos": true}, true)
			return
	var mo := RutaMomentos.abrir(self, par, minuto, CarreraCopa.es_copa(mundo, par))
	mo.terminado.connect(func(res: Dictionary) -> void: _cerrar_semana(res, true))

## Suplente: el DT decide si entras y cuándo. Si entras, juegas desde ese
## minuto; si no, la semana se cierra con el partido visto desde el banco.
func _ir_al_banco() -> void:
	var club := carrera.club(mundo)
	var par := _partido_de_la_semana(club)
	if par.is_empty():
		return
	_msg = carrera.entrenar(mundo)
	var yo := carrera.jugador(mundo)
	var minuto := carrera.minuto_entrada_suplente(yo != null and yo.es_portero())
	if minuto < 0:
		_msg += "  ·  " + Idiomas.t("Calentaste toda la segunda parte, pero el DT no te hizo entrar.")
		_cerrar_semana({"sin_minutos": true}, true)
		return
	var pj = load("res://ui/partido_jugable.gd").abrir(self, mundo, carrera, par[0], par[1], 240.0, minuto, null, CarreraCopa.es_copa(mundo, par))
	pj.terminado.connect(func(res: Dictionary) -> void: _cerrar_semana(res, true))
