extends Node
## LA CARRERA DE JUGADOR, EN FOTOS (29-9-2026, mapa de metas 18): la creación,
## el hub de la semana y el partido jugable (en piloto automático unos
## segundos, y un córner apuntando).
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_carrera_jugador.tscn
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
	if _n == 20:
		_foto("carrera_crear")
		_ui._crear()
	if _n == 60:
		_foto("carrera_hub")
		var club := _ui.carrera.club(CarreraJugadorUI.mundo)
		var par := _ui._partido_de_la_semana(club)
		_pj = PartidoJugable.abrir(_ui, CarreraJugadorUI.mundo, _ui.carrera, par[0], par[1], 60.0)
		## Unos segundos en piloto automático para que haya juego.
		_pj.motor.autopiloto = true
	if _n == 200:
		_foto("partido_jugable_1")
	if _n == 230:
		## Un córner para el equipo del jugador, lanzado por él.
		var m := _pj.motor
		m.autopiloto = false
		var d := MotorJugable.dir_ataque(bool(m.usuario["es_local"]))
		m._empezar_saque("corner", bool(m.usuario["es_local"]), Vector3(33.7, 0.11, 52.2 * d))
	if _n == 300:
		_pj.motor.apunte["fuerza"] = 0.6
		_foto("partido_jugable_corner")
	if _n == 310:
		_pj.motor._lanzar_usuario(0.6)
		_pj.motor.autopiloto = true
	if _n == 360:
		_foto("partido_jugable_2")
	if _n == 370:
		var m2 := _pj.motor
		m2.autopiloto = false
		m2.lanza_usuario["penal"] = true
		var d2 := MotorJugable.dir_ataque(bool(m2.usuario["es_local"]))
		m2._empezar_saque("penal", bool(m2.usuario["es_local"]), Vector3(0, 0.11, (52.5 - 11.0) * d2))
	if _n == 440:
		_foto("partido_jugable_penal")
	if _n == 441:
		_pj.motor._lanzar_usuario(0.7)
		_pj._simular_resto()
	if _n == 460:
		_foto("partido_jugable_final")
		_pj._cerrar()
	if _n == 490:
		_foto("carrera_hub_tras_partido")
		get_tree().quit()
