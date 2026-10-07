extends Node3D
## LOS ESTADIOS SEGÚN EL REAL DE CADA CLUB (26-9-2026): seis clubes que
## representan a uno real, cada uno con la arquitectura de su estadio.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_estadios_reales.tscn
const CLUBES_BASE := ["Riachuelo AC", "Precordillera", "Isar FC", "Castellana CF", "Borsigplatz FC", "Núñez Athletic"]
## GUINOS=1: los estadios cuyo rasgo dibuja algo (fase 4, E9).
const CLUBES_GUINOS := ["Precordillera", "Cobre Atacama", "Ligure Blu", "Punta Carretas", "Köpenick FC", "Navigli FC", "Misti FC", "Yarra FC"]
var CLUBES: Array = CLUBES_GUINOS if OS.get_environment("GUINOS") == "1" else CLUBES_BASE
var _m: Mundo
var _i := -1
var _n := 0
var _raiz: Node3D
var _cam: Camera3D

func _ready() -> void:
	_m = Mundo.new()
	_m.generar(["CHI", "ARG", "ESP", "GER", "URU", "ITA", "PER", "AUS"], 77)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.72, 0.9)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.72)
	env.environment = e
	add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, -30, 0)
	sol.light_energy = 1.2
	add_child(sol)
	_cam = Camera3D.new()
	_cam.far = 1200.0
	add_child(_cam)
	_siguiente()

func _club(nombre: String) -> Club:
	for c: Club in _m.clubes.values():
		if c.nombre == nombre:
			return c
	return null

func _siguiente() -> void:
	_i += 1
	if _raiz != null:
		_raiz.queue_free()
	if _i >= CLUBES.size():
		get_tree().quit()
		return
	var c := _club(CLUBES[_i])
	_raiz = Node3D.new()
	add_child(_raiz)
	if c != null:
		var est := c.perfil_estadio()
		print("ESTADIO ", c.nombre, " «", est.get("apodo", ""), "»", " ", est.get("forma"), " ", est.get("niveles"), " ", est.get("techo"), " ", est.get("rasgo", ""))
		StadiumBuilder.build_pitch(_raiz, est, c)
		StadiumBuilder.build(_raiz, est, c.estadio_aforo, 0.8, 7, c)
	_cam.position = Vector3(-150, 70, 175)
	_cam.look_at(Vector3(0, 5, 0), Vector3.UP)
	_n = 0

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		get_viewport().get_texture().get_image().save_png(("res://pruebas/capturas/estadio_guino_%d.png" if OS.get_environment("GUINOS") == "1" else "res://pruebas/capturas/estadio_real_%d.png") % _i)
		_siguiente()
