extends Node3D
## Primer plano de la cara con cada gesto (13-10-2026): neutral, alegre,
## sorpresa, enfado y parpadeo. Salida: pruebas/capturas/expresiones.png (hoja).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 640x640 res://pruebas/captura_expresiones.tscn
const GESTOS := ["neutral", "alegre", "sorpresa", "enfado", "triste"]
var _n := 0
var _raiz: Node3D
var _e: Expresion
var _fotos: Array[Image] = []

func _ready() -> void:
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-30, 20, 0)
	add_child(luz)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.2, 0.22, 0.26)
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.75)
	env.environment.ambient_light_energy = 0.8
	add_child(env)
	_raiz = Node3D.new()
	add_child(_raiz)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var asp := PersonajeDT.aleatorio(rng)
	## ACCESORIOS=1: gafas redondas, pendientes, cadena y ojos azules.
	if OS.get_environment("ACCESORIOS") != "":
		asp.merge({"gafas": OS.get_environment("ACCESORIOS") if OS.get_environment("ACCESORIOS") != "1" else "redondas",
			"pendiente": true, "cadena": true, "ojos": "3f6a9a", "ropa": "polo"}, true)
	PersonajeDT.crear(_raiz, asp)
	var cam := Camera3D.new()
	cam.fov = 18
	add_child(cam)
	var lejos := 2.4 if OS.get_environment("ACCESORIOS") != "" else 1.4
	cam.look_at_from_position(Vector3(0, 1.62, lejos), Vector3(0, 1.6, 0))

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		_e = Expresion.de(_raiz)
		print("ojos con expresión: ", _e.tiene_ojos())
		_e.set("_t_parpadeo", 999.0)
	var k := (_n - 20) / 15
	if _n >= 20 and (_n - 20) % 15 == 0 and k < GESTOS.size():
		_e.poner(GESTOS[k], 0.0)
	if _n >= 20 and (_n - 20) % 15 == 12 and k < GESTOS.size():
		_fotos.append(get_viewport().get_texture().get_image())
	if k >= GESTOS.size():
		var w := _fotos[0].get_width()
		var h := _fotos[0].get_height()
		var hoja := Image.create(w * _fotos.size() / 2, h / 2, false, _fotos[0].get_format())
		for i in _fotos.size():
			var f := _fotos[i]
			f.resize(w / 2, h / 2)
			hoja.blit_rect(f, Rect2i(0, 0, w / 2, h / 2), Vector2i(i * w / 2, 0))
		hoja.save_png("res://pruebas/capturas/expresiones.png")
		get_tree().quit()
