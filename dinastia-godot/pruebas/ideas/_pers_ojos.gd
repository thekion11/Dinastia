extends Node3D
## Diagnóstico (agente pers): primer plano de dos peatones con cara de
## biblioteca; al de la derecha se le esconden los globos de los ojos.
var _n := 0
var _ds: Array = []
var _cam: Camera3D

func _ready() -> void:
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-35, 25, 0)
	add_child(luz)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.6, 0.66)
	env.environment.ambient_light_color = Color(0.8, 0.8, 0.85)
	env.environment.ambient_light_energy = 0.7
	add_child(env)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 8:
		var d := PeatonQ.crear(rng)
		add_child(d["nodo"])
		(d["nodo"] as Node3D).position = Vector3((i - 3.5) * 0.95, 0, 0)
		_ds.append(d)
	_cam = Camera3D.new()
	add_child(_cam)

func _process(_d: float) -> void:
	_n += 1
	if _n == 2:
		for d: Dictionary in _ds:
			PeatonQ.terminar(d)
			var ap: AnimationPlayer = d["anim"]
			if ap.has_animation(OS.get_environment("ANIM") if OS.get_environment("ANIM") != "" else "parado"):
				ap.play(OS.get_environment("ANIM") if OS.get_environment("ANIM") != "" else "parado")
		for mi: MeshInstance3D in (_ds[7]["nodo"] as Node).find_children("Eyes", "MeshInstance3D", true, false):
			mi.visible = false
		## Entre P5 (x 1,425) y P7 (x 3,325), de frente y a la altura de los ojos.
		_cam.fov = 14
		_cam.look_at_from_position(Vector3(2.375, 1.66, 4.2), Vector3(2.375, 1.66, 0))
	if _n == 30:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/pers_ojos.png")
		get_tree().quit()
