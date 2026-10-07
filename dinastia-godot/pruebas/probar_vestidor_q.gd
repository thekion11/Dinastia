extends Node3D
## Verifica que la camiseta pegada por `VestidorQ.vestir()` de verdad se
## anime junto con el cuerpo -el riesgo real de reapuntar `.skeleton` a un
## esqueleto de otro .gltf es que la malla quede en T-pose o se separe del
## cuerpo en vez de seguir "correr".

func _ready() -> void:
	var amb := WorldEnvironment.new()
	var ent := Environment.new()
	ent.background_mode = Environment.BG_COLOR
	ent.background_color = Color(0.05, 0.06, 0.07)
	ent.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ent.ambient_light_color = Color(0.3, 0.3, 0.32)
	ent.ambient_light_energy = 0.6
	add_child(amb)
	amb.environment = ent
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -30, 0)
	luz.light_energy = 1.2
	add_child(luz)
	var cam_f := Camera3D.new()
	cam_f.position = Vector3(0, 1.0, 2.6)
	cam_f.fov = 40
	add_child(cam_f)
	cam_f.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	cam_f.current = true
	var cam_l := Camera3D.new()
	cam_l.position = Vector3(2.6, 1.0, 0)
	cam_l.fov = 40
	add_child(cam_l)
	cam_l.look_at(Vector3(0, 0.9, 0), Vector3.UP)

	var d := FutbolistaQ.crear(1.80, "male")
	add_child(d["nodo"])
	FutbolistaQ.terminar(d, false)
	VestidorQ.vestir(d, Color(0.85, 0.15, 0.1))  # rojo, bien distinto de la piel
	(d["anim"] as AnimationPlayer).play("correr")
	set_meta("cam_l", cam_l)

var _frame := 0
func _process(_d: float) -> void:
	_frame += 1
	if _frame == 20:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/vestidor_q_correr_frente.png")
	if _frame == 22:
		(get_meta("cam_l") as Camera3D).current = true
	if _frame == 24:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/capturas/vestidor_q_correr_lado.png")
		get_tree().quit(0)
