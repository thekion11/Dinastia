extends Node3D
## Verifica el retarget GLOBAL horneado (`AnimQuaternius.cargar_futbol_global`)
## sobre FutbolistaQ, jugando "patear"/"celebrar"/"atajar"/"mostrar_tarjeta"/
## "penal" via el nuevo camino, capturando de frente y de perfil en el pico
## de cada gesto -mismo patron que `diagnostico_futbol_real.gd`, pero
## reproduciendo directo desde `cargar_futbol_global()` en vez de pasar por
## `AnimQuaternius.construir()`, para aislar el resultado del horneado de
## cualquier otra cosa.

const SECUENCIA := [
	["09_Power_Kick_ue5", "patear", 0.55],
	["13_Goal_Celebration_02_ue5", "celebrar", 0.9],
	["15_Goalkeeper_Save_01_ue5", "atajar", 0.6],
	["20_Yellow_Card_ue5", "mostrar_tarjeta", 0.7],
	["10_Penalty_Kick_01_ue5", "penal", 0.9],
]

var _d: Dictionary
var _ap: AnimationPlayer
var _cam_frente: Camera3D
var _cam_lado: Camera3D
var _esq: Skeleton3D
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
	FutbolistaQ.terminar(_d)
	_ap = _d["anim"]
	_esq = _d["esqueleto"]

func _process(_delta: float) -> void:
	if _i < 0:
		_siguiente()
		return
	_frame_desde_clip += 1
	if _frame_desde_clip == 3:
		_ap.seek(float(SECUENCIA[_i][2]), true)
	if _frame_desde_clip == 5:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/futbol_global_%s_frente.png" % SECUENCIA[_i][1])
		_cam_lado.current = true
	if _frame_desde_clip == 8:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/capturas/futbol_global_%s_lado.png" % SECUENCIA[_i][1])
		print("capturado ", SECUENCIA[_i][1])
		_cam_frente.current = true
		_siguiente()

func _siguiente() -> void:
	_i += 1
	if _i >= SECUENCIA.size():
		print("FIN. 0 fallos")
		get_tree().quit(0)
		return
	var archivo: String = SECUENCIA[_i][0]
	var nombre: String = SECUENCIA[_i][1]
	var anim: Animation = AnimQuaternius.cargar_futbol_global(archivo, _esq, str(_ap.get_path_to(_esq)))
	if anim == null:
		print("AVISO: ", archivo, " no genero animacion")
		_frame_desde_clip = 0
		return
	if _ap.has_animation_library("_global"):
		_ap.remove_animation_library("_global")
	var lib := AnimationLibrary.new()
	lib.add_animation(nombre, anim)
	_ap.add_animation_library("_global", lib)
	_ap.play("_global/%s" % nombre)
	_frame_desde_clip = 0
