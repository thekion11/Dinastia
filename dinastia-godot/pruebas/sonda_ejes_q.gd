extends Node3D
## Sonda de ejes: antes de escribir una animacion de verdad para el esqueleto
## Quaternius, prueba UN desvio de 40 grados en X sobre unos pocos huesos
## clave (muslo, rodilla, tobillo, brazo) y captura, para saber que signo y
## que eje mueve cada cosa hacia donde se espera -exactamente lo que
## AnimMixamo ya tuvo que hacer para el otro esqueleto ("el signo se
## comprobo renderizando").
##
##   godot --path . --rendering-driver opengl3 --position 0,0 res://pruebas/sonda_ejes_q.tscn

var _d: Dictionary
var _esq: Skeleton3D
var _frame := 0
var _cam: Camera3D
var _cam_lado: Camera3D

const PRUEBAS := [
	["thigh_l", Vector3(40, 0, 0), "muslo_x40"],
	["calf_l", Vector3(60, 0, 0), "rodilla_x60"],
	["foot_l", Vector3(30, 0, 0), "tobillo_x30"],
	["upperarm_l", Vector3(40, 0, 0), "brazo_x40"],
	["upperarm_l", Vector3(0, 0, 40), "brazo_z40"],
]

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
	_cam = Camera3D.new()
	_cam.position = Vector3(0, 1.0, 3.0)
	_cam.fov = 35
	env.add_child(_cam)
	_cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	_cam.current = true
	_cam_lado = Camera3D.new()
	_cam_lado.position = Vector3(3.0, 1.0, 0)
	_cam_lado.fov = 35
	env.add_child(_cam_lado)
	_cam_lado.look_at(Vector3(0, 0.9, 0), Vector3.UP)

	_d = FutbolistaQ.crear(1.80)
	add_child(_d["nodo"])
	FutbolistaQ.terminar(_d)
	_esq = _d["esqueleto"]

func _process(_delta: float) -> void:
	_frame += 1
	var paso := _frame / 15
	var sub := _frame % 15
	if paso >= PRUEBAS.size():
		print("FIN. 0 fallos")
		get_tree().quit(0)
		return
	if sub == 1:
		## Reponer TODOS los huesos de prueba a su reposo antes de aplicar la
		## siguiente -si no, las pruebas se acumulan una sobre otra (ej. la
		## rodilla quedaria doblada Y con el muslo de la prueba anterior
		## todavia encima) y la lectura sale confusa.
		for t2: Array in PRUEBAS:
			var idx2 := _esq.find_bone(String(t2[0]))
			_esq.set_bone_pose_rotation(idx2, _esq.get_bone_rest(idx2).basis.get_rotation_quaternion())
		var t: Array = PRUEBAS[paso]
		var nombre := String(t[0])
		var grados: Vector3 = t[1]
		var idx := _esq.find_bone(nombre)
		var reposo := _esq.get_bone_rest(idx).basis.get_rotation_quaternion()
		var desvio := Quaternion.from_euler(Vector3(deg_to_rad(grados.x), deg_to_rad(grados.y), deg_to_rad(grados.z)))
		_esq.set_bone_pose_rotation(idx, reposo * desvio)
		_cam.current = true
	if sub == 8:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/sonda_%s.png" % String(PRUEBAS[paso][2]))
		print("capturado ", PRUEBAS[paso][2])
		_cam_lado.current = true
	if sub == 12:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/sonda_%s_lado.png" % String(PRUEBAS[paso][2]))
