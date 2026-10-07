extends Node
## EL PÚBLICO DE CERCA (29-9-2026): el partido jugable en un córner, que es
## donde la cámara queda más pegada a la grada. Corta a propósito: dos fotos.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_grada_cerca.tscn
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
	if _n == 10:
		_ui._crear()
	if _n == 20:
		var club := _ui.carrera.club(CarreraJugadorUI.mundo)
		var par := _ui._partido_de_la_semana(club)
		_pj = PartidoJugable.abrir(_ui, CarreraJugadorUI.mundo, _ui.carrera, par[0], par[1], 60.0)
		var m := _pj.motor
		var d := MotorJugable.dir_ataque(bool(m.usuario["es_local"]))
		m._empezar_saque("corner", bool(m.usuario["es_local"]), Vector3(33.7, 0.11, 52.2 * d))
	if _n == 70:
		_pj.motor.apunte["fuerza"] = 0.6
		_foto("grada_cerca_corner")
	if _n == 71:
		_pj.motor._lanzar_usuario(0.6)
		_pj.motor.autopiloto = true
	if _n == 110:
		_foto("grada_cerca_juego")
		get_tree().quit()
