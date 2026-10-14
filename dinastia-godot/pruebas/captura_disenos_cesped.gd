extends Node3D
## TODOS LOS DISEÑOS DE CÉSPED vistos desde arriba, para comprobar que se leen
## (14-10-2026, «¿se perdieron los diseños de pasto?»).
##   xvfb-run -a godot --path . --rendering-driver vulkan --resolution 1280x720 res://pruebas/captura_disenos_cesped.tscn
const DISENOS := ["rayas", "rayasH", "damero", "damGrande", "circular", "diagonal", "espiga", "cruz", "abanico", "rombos", "mitades", "liso"]
var _n := 0
var _cam: Camera3D
var _fotos: Array[Image] = []
var _raiz: Node3D

func _montar(i: int) -> void:
	if is_instance_valid(_raiz):
		_raiz.queue_free()
	_raiz = Node3D.new()
	add_child(_raiz)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.6
	_raiz.add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-60, 30, 0)
	_raiz.add_child(sol)
	StadiumBuilder.build_pitch(_raiz, {"cesped": DISENOS[i], "cespedClaro": "#2f8043", "cespedOscuro": "#3b9c53"})

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	_cam = Camera3D.new()
	_cam.fov = 40.0
	add_child(_cam)
	_cam.position = Vector3(0, 125, 0.01)
	_cam.look_at(Vector3(0, 0, 0), Vector3.UP)
	_cam.current = true
	_montar(0)

func _process(_d: float) -> void:
	_n += 1
	var i := _n / 8
	if _n % 8 == 6 and _fotos.size() <= i and i < DISENOS.size():
		var img := get_viewport().get_texture().get_image()
		img.resize(320, 180)
		_fotos.append(img)
	if _n % 8 == 0 and i < DISENOS.size():
		_montar(i)
	if i >= DISENOS.size() and _fotos.size() >= DISENOS.size():
		var hoja := Image.create(320 * 4, 180 * 3, false, _fotos[0].get_format())
		for k in _fotos.size():
			hoja.blit_rect(_fotos[k], Rect2i(0, 0, 320, 180), Vector2i((k % 4) * 320, (k / 4) * 180))
		hoja.save_png("res://pruebas/capturas/disenos_cesped.png")
		print("HOJA guardada")
		get_tree().quit()
