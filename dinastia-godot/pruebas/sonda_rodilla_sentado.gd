extends Node
## La pose "sentado" salio con las piernas invisibles/mal dobladas -el
## usuario lo noto de inmediato ("se ven feas las piernas?")-. En vez de
## seguir adivinando el signo de la rodilla a ojo, se barre un rango de
## valores con el muslo YA fijo en 90 (horizontal) y se mira cual de verdad
## deja la pantorrilla colgando hacia el piso -mismo metodo que ya uso este
## proyecto para el hueso de la espalda (`diagnostico_espalda_sola.gd`), no
## prueba y error sobre el juego real.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/sonda_rodilla_sentado.tscn

const VALORES := [-150.0, -120.0, -100.0, -80.0, -70.0]

var _esq: Skeleton3D
var _frame := 0
var _idx := 0

func _ready() -> void:
	var d: Dictionary = FutbolistaQ.crear(1.85, "male")
	add_child(d["nodo"])
	FutbolistaQ.terminar(d, true)
	_esq = d["esqueleto"]

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-45, -35, 0)
	sol.light_energy = 1.3
	add_child(sol)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.68, 0.85)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.65, 0.7)
	env.ambient_light_energy = 0.6
	we.environment = env
	add_child(we)

	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(2.2, 1.0, 0.0)
	cam.look_at(Vector3(0, 0.7, 0), Vector3.UP)
	cam.current = true

func _aplicar(muslo: float, rodilla: float) -> void:
	var i_m := _esq.find_bone("thigh_l")
	var i_r := _esq.find_bone("calf_l")
	var reposo_m := _esq.get_bone_rest(i_m).basis.get_rotation_quaternion()
	var reposo_r := _esq.get_bone_rest(i_r).basis.get_rotation_quaternion()
	_esq.set_bone_pose_rotation(i_m, reposo_m * Quaternion.from_euler(Vector3(deg_to_rad(muslo), 0, 0)))
	_esq.set_bone_pose_rotation(i_r, reposo_r * Quaternion.from_euler(Vector3(deg_to_rad(rodilla), 0, 0)))

func _process(_d: float) -> void:
	_frame += 1
	if _frame == 5:
		_aplicar(90.0, VALORES[_idx])
	if _frame == 8:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/sonda_rodilla_%d.png" % int(VALORES[_idx]))
		print("rodilla=%.0f -> sonda_rodilla_%d.png" % [VALORES[_idx], int(VALORES[_idx])])
		_idx += 1
		if _idx >= VALORES.size():
			print("FIN. 0 fallos")
			get_tree().quit()
		else:
			_frame = 4
