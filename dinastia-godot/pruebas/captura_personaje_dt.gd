extends Node3D
## EL PERSONAJE MODIFICABLE (26-9-2026): seis aspectos en fila (cuerpos,
## ropas y accesorios distintos) y un primer plano de la cabeza.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_personaje_dt.tscn
var _n := 0
var _cam: Camera3D

const ASPECTOS := [
	{"ropa": "traje", "gafas": "ver", "reloj": true},
	{"ropa": "chandal", "complexion": 0.8, "barriga": 0.9, "pelo": "calvo", "barba": true, "gorra": true},
	{"cuerpo": "female", "altura": 1.68, "ropa": "abrigo", "c_ropa": "6a1b2a", "pelo": "melena", "color_pelo": "7a5230", "bufanda": true},
	{"ropa": "polo", "c_ropa": "1565c0", "complexion": -0.8, "hombros": -0.5, "altura": 1.92, "gafas": "sol"},
	{"ropa": "sudadera", "c_ropa": "455a64", "auriculares": true, "pelo": "rizado", "piel": "6b4028"},
	{"ropa": "camisa", "c_ropa": "2e3f2a", "c_ropa2": "cfe0f5", "hombros": 1.0, "complexion": 0.5, "cabeza": 0.6, "piernas": 1.0},
]

func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.2, 0.22, 0.26)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.72)
	env.environment = e
	add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-35, 20, 0)
	sol.light_energy = 1.2
	add_child(sol)
	for i in ASPECTOS.size():
		var raiz := Node3D.new()
		raiz.position = Vector3((i - 2.5) * 0.9, 0, 0)
		add_child(raiz)
		PersonajeDT.crear(raiz, ASPECTOS[i], Color("c62828"), Color.WHITE)
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.position = Vector3(0, 1.05, 3.4)
	_cam.look_at(Vector3(0, 0.95, 0), Vector3.UP)

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/personaje_dt.png")
		_cam.position = Vector3(-2.25 + 0.25, 1.5, 0.8)
		_cam.look_at(Vector3(-2.25, 1.45, 0), Vector3.UP)
	if _n == 16:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/personaje_dt_cara.png")
		_cam.position = Vector3(-2.25 + 0.6, 1.0, 1.9)
		_cam.look_at(Vector3(-2.25, 0.85, 0), Vector3.UP)
	if _n == 22:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/personaje_dt_abrigo.png")
		get_tree().quit()
