extends Node
## LA GUÍA DE CONTROLES DEL PORTERO (26-10-2026, prefijo cpor): Carrera de un
## portero, partido jugable con la cámara real; foto sin balón y con el balón
## en sus manos (la guía de abajo debe ser la del portero, no la de campo).
##   herramientas/captura.sh res://pruebas/cpor_captura_guia.tscn
var _n := 0
var _ui: CarreraJugadorUI
var _pj: PartidoJugable

func _ready() -> void:
	PartidoJugable.con_ceremonia = false
	CarreraJugadorUI.mundo = null
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)

func _foto(nombre: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % nombre)

func _process(_d: float) -> void:
	_n += 1
	if _n == 20:
		_ui._crear()
		_ui.carrera = CarreraJugador.crear(CarreraJugadorUI.mundo, "Prueba Portero", "POR", false, 99)
	if _n == 60:
		var club := _ui.carrera.club(CarreraJugadorUI.mundo)
		var par := _ui._partido_de_la_semana(club)
		_pj = PartidoJugable.abrir(_ui, CarreraJugadorUI.mundo, _ui.carrera, par[0], par[1], 60.0)
		_pj.motor.autopiloto = true
	if _n == 200:
		_pj.motor.autopiloto = false
		print("USUARIO portero: ", bool(_pj.motor.usuario.get("por", false)))
	if _n == 260:
		_foto("cpor_guia_sin_balon")
		print("GUIA: ", _pj._ayuda.text)
	if _n == 270:
		var m := _pj.motor
		m.poseedor = m.usuario
		m.balon.position = m.pos(m.usuario) + Vector3(0, 1.0, 0)
		m.vel_balon = Vector3.ZERO
	if _n == 290:
		_foto("cpor_guia_con_balon")
		print("GUIA: ", _pj._ayuda.text)
		get_tree().quit()
