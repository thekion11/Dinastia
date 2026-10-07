extends Node3D
## Igual que `diagnostico_mocap_origen.gd` pero para las 5 acciones a la vez
## -referencia visual de CADA clip de origen, sin FutbolistaQ ni
## AnimQuaternius, para comparar contra `futbol_real_*_lado.png` accion por
## accion, tal como pidio el usuario: "deben ser identicos los movimientos".

const SECUENCIA := [
	["09_Power_Kick_ue5", "patear", 0.55],
	["13_Goal_Celebration_02_ue5", "celebrar", 0.9],
	["15_Goalkeeper_Save_01_ue5", "atajar", 0.6],
	["20_Yellow_Card_ue5", "mostrar_tarjeta", 0.7],
	["10_Penalty_Kick_01_ue5", "penal", 0.9],
]

var _ap: AnimationPlayer
var _origen: Node3D
var _cam: Camera3D
var _i := -1
var _frame_desde_clip := 0

func _ready() -> void:
	var mundo := WorldEnvironment.new()
	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = Color(0.05, 0.06, 0.07)
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color(0.42, 0.42, 0.44)
	ambiente.ambient_light_energy = 0.8
	mundo.environment = ambiente
	add_child(mundo)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	luz.light_energy = 1.4
	add_child(luz)
	var piso := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(6.0, 6.0)
	piso.mesh = plano
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.20, 0.50, 0.25)
	piso.material_override = mat
	add_child(piso)
	_cam = Camera3D.new()
	_cam.position = Vector3(3.2, 1.1, 0.0)
	_cam.fov = 40.0
	add_child(_cam)
	_cam.look_at(Vector3(0.0, 0.9, 0.0), Vector3.UP)
	_cam.current = true

func _process(_delta: float) -> void:
	if _i < 0:
		_siguiente()
		return
	_frame_desde_clip += 1
	if _frame_desde_clip == 3:
		_ap.seek(float(SECUENCIA[_i][2]), true)
	if _frame_desde_clip == 9:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/mocap_origen_%s_lado.png" % SECUENCIA[_i][1])
		print("capturado origen ", SECUENCIA[_i][1])
		_siguiente()

func _siguiente() -> void:
	if _origen != null:
		_origen.queue_free()
		_origen = null
	_i += 1
	if _i >= SECUENCIA.size():
		print("FIN. 0 fallos")
		get_tree().quit(0)
		return
	var archivo: String = SECUENCIA[_i][0]
	var packed: PackedScene = load("res://assets/characters/quaternius/anims_futbol/%s.fbx" % archivo)
	_origen = packed.instantiate()
	add_child(_origen)
	_ap = _buscar_ap(_origen)
	_ap.play("clip")
	_frame_desde_clip = 0

func _buscar_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for hijo in n.get_children():
		var encontrado := _buscar_ap(hijo)
		if encontrado != null:
			return encontrado
	return null
