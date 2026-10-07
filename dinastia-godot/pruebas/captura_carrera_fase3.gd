extends Node
## LA CARRERA DE JUGADOR v2 (MEGAPLAN fase 3), en fotos: la convocatoria, el
## partido con la selección, la entrada desde el banco y el retiro.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_carrera_fase3.tscn
var _n := 0
var _ui: CarreraJugadorUI
var _pj: PartidoJugable

func _ready() -> void:
	CarreraJugadorUI.mundo = null
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)

func _foto(nombre: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % nombre)

func _process(_d: float) -> void:
	_n += 1
	var m := CarreraJugadorUI.mundo
	if _n == 15:
		_ui._crear()
	if _n == 30:
		var yo := _ui.carrera.jugador(CarreraJugadorUI.mundo)
		yo.ovr = 90
		CarreraJugadorUI.mundo.semana = Selecciones.SEMANAS_FIFA[0]
		_ui.carrera.revisar_convocatoria(CarreraJugadorUI.mundo)
		_ui._pintar_semana()
	if _n == 40:
		_foto("carrera_convocado")
		var eq := _ui.carrera.equipos_seleccion(m)
		_pj = PartidoJugable.abrir(_ui, m, _ui.carrera, eq[0], eq[1], 60.0, -1, eq[0])
		_pj.motor.autopiloto = true
	if _n == 120:
		_foto("carrera_seleccion")
		_pj.queue_free()
		var club := _ui.carrera.club(m)
		var par := _ui._partido_de_la_semana(club)
		if par.size() == 2:
			_pj = PartidoJugable.abrir(_ui, m, _ui.carrera, par[0], par[1], 60.0, 55)
	if _n == 140:
		_foto("carrera_banco")
		if is_instance_valid(_pj):
			_pj.queue_free()
		_ui.carrera.retiro_anunciado = true
		_ui.carrera.pj_carrera = 312
		_ui.carrera.goles_carrera = 98
		_ui.carrera.caps = 41
		_ui.carrera.goles_sel = 12
		_ui.carrera.fama = 70
		_ui._pintar_retiro()
	if _n == 150:
		_foto("carrera_retiro")
		get_tree().quit()
