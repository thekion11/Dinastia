extends Node3D
## Diagnostico: reproduce SOLO Futbolista.crear()+terminar()+"parado", sin la
## escena del sorteo ni Vestidor por medio, para saber si el brazo estirado que
## se ve en el presentador del sorteo es un bug del catalogo Mixamo compartido
## (afectaria tambien a los 22 del campo) o algo propio de esa escena.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##         res://pruebas/captura_parado_aislado.tscn

var _n := 0
var _esq: Skeleton3D
var _ap: AnimationPlayer

func _ready() -> void:
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -30, 0)
	luz.light_energy = 1.3
	add_child(luz)
	var amb := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.06, 0.07)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.3, 0.32)
	env.ambient_light_energy = 0.6
	amb.environment = env
	add_child(amb)
	var cam := Camera3D.new()
	cam.fov = 42.0
	add_child(cam)
	cam.current = true
	cam.position = Vector3(0, 1.2, 3.2)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)

	var d := Futbolista.crear(1.78)
	var raiz: Node3D = d["nodo"]
	raiz.position = Vector3.ZERO
	raiz.rotation.y = deg_to_rad(-32.0)
	add_child(raiz)
	Futbolista.terminar(d)
	var modelo: Node3D = d["modelo"]
	Vestidor.vestir(modelo, "", Color(0.52, 0.40, 0.33), Color(0.14, 0.11, 0.09),
		Color(0.12, 0.13, 0.19, 1.0))
	_esq = d["esqueleto"]
	_ap = d["anim"]
	if _ap.has_animation("parado"):
		_ap.play("parado")

func _process(_d: float) -> void:
	_n += 1
	if _n == 20:
		for n: String in ["mixamorig_Hips", "mixamorig_Spine", "mixamorig_Spine1",
				"mixamorig_Spine2", "mixamorig_Neck", "mixamorig_Head",
				"mixamorig_LeftShoulder", "mixamorig_LeftArm", "mixamorig_LeftForeArm",
				"mixamorig_RightShoulder", "mixamorig_RightArm", "mixamorig_RightForeArm"]:
			var i := _esq.find_bone(n)
			print(n, " pose=", _esq.get_bone_pose_rotation(i).get_euler(),
				" global_pos=", _esq.global_transform * _esq.get_bone_global_pose(i).origin)
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/parado_aislado.png")
		print("capturado aislado")
		get_tree().quit()
