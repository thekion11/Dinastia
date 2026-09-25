extends Node3D
## Primer plano de la mano derecha, parado, para juzgar la pose relajada del
## dedo indice de verdad -a esta distancia no se alcanza a ver bien.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/diagnostico_mano.tscn

var _d: Dictionary
var _frame := 0

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
	cam.fov = 25
	env.add_child(cam)
	cam.current = true
	_cam = cam

	_d = Futbolista.crear(1.80)
	add_child(_d["nodo"])
	Futbolista.terminar(_d)

func _process(_delta: float) -> void:
	_frame += 1
	if _frame == 5:
		(_d["anim"] as AnimationPlayer).play("parado")
	if _frame == 20:
		var esq: Skeleton3D = _d["esqueleto"]
		var idx := esq.find_bone("mixamorig_RightHand")
		var pos: Vector3 = esq.global_transform * esq.get_bone_global_pose(idx).origin
		_cam.global_position = pos + Vector3(0.35, 0.15, 0.35)
		_cam.look_at(pos, Vector3.UP)
	if _frame == 25:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/mano_cerca.png")
		print("capturado")
		print("FIN. 0 fallos")
		get_tree().quit(0)

var _cam: Camera3D
