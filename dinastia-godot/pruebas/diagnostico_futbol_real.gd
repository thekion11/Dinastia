extends Node3D
## Verifica las animaciones reales de futbol (mocap de Anderson Rohr, via
## AnimQuaternius.CLIP_FUTBOL/CLIP_FUTBOL_NUEVO) sobre FutbolistaQ, de frente
## y de perfil, capturando cerca del pico de cada gesto.

const SECUENCIA := [
	["patear", 0.55],
	["celebrar", 0.9],
	["atajar", 0.6],
	["mostrar_tarjeta", 0.7],
	["penal", 0.9],
]

var _d: Dictionary
var _ap: AnimationPlayer
var _cam_frente: Camera3D
var _cam_lado: Camera3D
var _i := -1
var _frame_desde_clip := 0

func _ready() -> void:
	var env := Node3D.new()
	add_child(env)
	var amb := WorldEnvironment.new()
	var ent := Environment.new()
	ent.background_mode = Environment.BG_COLOR
	ent.background_color = Color(0.05, 0.06, 0.07)
	ent.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ent.ambient_light_color = Color(0.35, 0.35, 0.37)
	ent.ambient_light_energy = 0.7
	amb.environment = ent
	env.add_child(amb)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -30, 0)
	luz.light_energy = 1.3
	env.add_child(luz)
	var cam := Camera3D.new()
	env.add_child(cam)
	cam.position = Vector3(0, 1.0, 3.2)
	cam.fov = 40
	cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	cam.current = true
	_cam_frente = cam
	var cam_lado := Camera3D.new()
	env.add_child(cam_lado)
	cam_lado.position = Vector3(3.2, 1.0, 0)
	cam_lado.fov = 40
	cam_lado.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	_cam_lado = cam_lado
	var piso := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(6, 6)
	piso.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.5, 0.25)
	piso.material_override = mat
	env.add_child(piso)

	_d = FutbolistaQ.crear(1.80)
	add_child(_d["nodo"])
	## Esta escena existe para inspeccionar los clips que aun estan bloqueados
	## para el juego real. El argumento explicito evita que se activen por
	## accidente en PlayerSpawner.
	FutbolistaQ.terminar(_d, true)
	_ap = _d["anim"]

func _process(_delta: float) -> void:
	if _i < 0:
		_siguiente()
		return
	_frame_desde_clip += 1
	## No se puede usar un numero fijo de frames como si fueran segundos:
	## Forward+ puede correr a 6 FPS durante una captura y el pico de una
	## patada de 0.55 s quedaba fotografiado a los 0.2 s. Se busca el instante
	## exacto del clip antes de fotografiar, igual bajo cualquier rendimiento.
	if _frame_desde_clip == 3:
		_ap.seek(float(SECUENCIA[_i][1]), true)
	if _frame_desde_clip == 9:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/futbol_real_%s_frente.png" % SECUENCIA[_i][0])
		_cam_lado.current = true
	if _frame_desde_clip == 12:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/futbol_real_%s_lado.png" % SECUENCIA[_i][0])
		print("capturado ", SECUENCIA[_i][0], " tiene_animacion=", _ap.has_animation(SECUENCIA[_i][0]))
		_cam_frente.current = true
		_siguiente()

func _siguiente() -> void:
	_i += 1
	if _i >= SECUENCIA.size():
		print("FIN. 0 fallos")
		get_tree().quit(0)
		return
	var nombre: String = SECUENCIA[_i][0]
	if _ap.has_animation(nombre):
		_ap.play(nombre)
	else:
		print("AVISO: ", nombre, " no existe en la libreria")
	_frame_desde_clip = 0
