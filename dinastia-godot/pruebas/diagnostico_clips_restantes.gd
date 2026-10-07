extends Node3D
## LOS CLIPS DE MOCAP QUE NADIE USABA (25-9-2026): pone al jugador en el
## momento de cada clip a dos alturas (35% y 65% de su duración), de frente,
## y deja una foto por pose en `/tmp` para armar una hoja de contactos. Además
## imprime cuánto se desplaza la pelvis en X -para saber a qué lado se tira el
## portero en cada atajada-.

const CLIPS := ["15_Goalkeeper_Save_01_ue5", "16_Goalkeeper_Save_02_ue5", "17_Goalkeeper_Save_03_ue5",
	"12_Goal_Celebration_01_ue5", "14_Goal_Celebration_03_ue5", "18_Defending_01_ue5", "19_Defending_02_ue5",
	"07_Throw_In_ue5", "08_Side_Foot_Kick_ue5", "01_Dribble_01_ue5", "21_Yellow_And_Red_Card_ue5", "11_Penalty_Kick_02_ue5"]
const FRACS := [0.35, 0.65]

var _d: Dictionary
var _ap: AnimationPlayer
var _esq: Skeleton3D
var _i := 0
var _j := 0
var _espera := 0

func _ready() -> void:
	var amb := WorldEnvironment.new()
	var ent := Environment.new()
	ent.background_mode = Environment.BG_COLOR
	ent.background_color = Color(0.08, 0.09, 0.1)
	ent.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ent.ambient_light_color = Color(0.5, 0.5, 0.5)
	amb.environment = ent
	add_child(amb)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -30, 0)
	add_child(luz)
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 1.0, 4.2)
	cam.fov = 45
	cam.look_at(Vector3(0, 0.8, 0), Vector3.UP)
	cam.current = true
	_d = FutbolistaQ.crear(1.8, "male")
	add_child(_d["nodo"])
	FutbolistaQ.terminar(_d, false)
	_ap = _d["anim"]
	_esq = AnimQuaternius._buscar_esqueleto(_d["nodo"])

func _process(_dl: float) -> void:
	if _espera > 0:
		_espera -= 1
		if _espera == 0:
			var nombre := "%s_%d" % [CLIPS[_i], _j]
			get_viewport().get_texture().get_image().save_png("/tmp/claude-0/clips/%s.png" % nombre)
			var pel := _esq.find_bone("pelvis")
			print("POSE %s pelvis %s" % [nombre, _esq.get_bone_global_pose(pel).origin])
			_j += 1
			if _j >= FRACS.size():
				_j = 0
				_i += 1
			if _i >= CLIPS.size():
				get_tree().quit()
		return
	var lib := AnimationLibrary.new()
	var a: Animation = AnimQuaternius.cargar_futbol_global(CLIPS[_i], _esq, str(_ap.get_path_to(_esq)))
	if a == null:
		print("NO CARGA ", CLIPS[_i])
		_i += 1
		return
	if _ap.has_animation_library("diag"):
		_ap.remove_animation_library("diag")
	lib.add_animation("c", a)
	_ap.add_animation_library("diag", lib)
	_ap.play("diag/c")
	_ap.seek(a.length * FRACS[_j], true)
	_ap.pause()
	if _j == 0:
		print("CLIP %s dur %.2f" % [CLIPS[_i], a.length])
	_espera = 3
