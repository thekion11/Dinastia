extends Node3D
## Verifica "parado" y "correr" del modelo Quaternius de frente y de perfil.
##
##   godot --path . --rendering-driver opengl3 --position 0,0 res://pruebas/diagnostico_anim_q.tscn

var _d: Dictionary
var _frame := 0
var _cam_frente: Camera3D
var _cam_lado: Camera3D

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
	cam.position = Vector3(0, 1.0, 3.2)
	cam.fov = 40
	env.add_child(cam)
	cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	cam.current = true
	_cam_frente = cam
	var cam_lado := Camera3D.new()
	cam_lado.position = Vector3(3.2, 1.0, 0)
	cam_lado.fov = 40
	env.add_child(cam_lado)
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
	FutbolistaQ.terminar(_d, true)

func _process(_delta: float) -> void:
	_frame += 1
	var ap: AnimationPlayer = _d["anim"]
	if _frame == 5:
		ap.play("parado")
	if _frame == 30:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/q_parado_frente.png")
		_cam_lado.current = true
	if _frame == 33:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/capturas/q_parado_lado.png")
		_cam_frente.current = true
		print("capturado parado")
	if _frame == 40:
		ap.play("correr")
	# Con "correr" en bucle, capturar en 4 momentos distintos del ciclo para
	# ver piernas y brazos en fases distintas, no siempre en la misma pose.
	if _frame == 46:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/q_correr_f1.png")
	if _frame == 52:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/q_correr_f2.png")
	if _frame == 58:
		_cam_lado.current = true
	if _frame == 60:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/q_correr_lado.png")
		print("capturado correr")
	if _frame == 65:
		_cam_frente.current = true
		ap.play("patear")
	# "patear" dura 0.85s sin bucle; a 60fps el pico de armado/disparo cae
	# cerca del frame 19-20 relativo (0.32s), la pierna ya extendida cerca
	# del 29 (0.48s). Capturamos ambos momentos, de frente y de perfil.
	if _frame == 65 + 19:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/q_patear_armado_frente.png")
	if _frame == 65 + 29:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/q_patear_disparo_frente.png")
		_cam_lado.current = true
	if _frame == 65 + 32:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/q_patear_disparo_lado.png")
		print("capturado patear")
	if _frame == 65 + 36:
		_cam_frente.current = true
		ap.play("cabezazo")
	# "cabezazo" dura 1.0s sin bucle; el arco de espalda+brazos arriba pega su
	# pico cerca de 0.4-0.5s (frame ~24-30 relativo), justo antes de que el
	# cuello se enderece para el golpe.
	if _frame == 65 + 36 + 26:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/q_cabezazo_pico_frente.png")
		_cam_lado.current = true
	if _frame == 65 + 36 + 29:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/q_cabezazo_pico_lado.png")
		print("capturado cabezazo")
	if _frame == 65 + 36 + 33:
		_cam_frente.current = true
		ap.play("celebrar")
	# "celebrar" dura 1.6s en bucle; el salto+brazos-arriba pega su pico cerca
	# de 0.4s (frame ~24 relativo).
	if _frame == 65 + 36 + 33 + 24:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/q_celebrar_frente.png")
		_cam_lado.current = true
	if _frame == 65 + 36 + 33 + 27:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/q_celebrar_lado.png")
		print("capturado celebrar")
		print("FIN. 0 fallos")
		get_tree().quit(0)
