extends Node3D
## GALERÍA DE MASCOTAS (26-9-2026): los 17 animales en fila, de frente, para
## revisar cabezas, guantes, patas y colas de una vez.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_mascotas.tscn
var _n := 0
var _cam: Camera3D

func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.72, 0.9)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.75, 0.78)
	env.environment = e
	add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, 25, 0)
	sol.light_energy = 1.1
	add_child(sol)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 20)
	suelo.mesh = pm
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.2, 0.45, 0.18)
	suelo.material_override = ms
	add_child(suelo)
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	var clubes: Array = m.ligas[0].clubes
	var animales: Array = MascotaQ.ANIMALES.keys()
	for i in animales.size():
		var c: Club = clubes[i % clubes.size()]
		var fila := i / 9
		var col := i % 9
		var x := (col - 4) * 1.6 + (0.8 if fila == 1 else 0.0)
		var z := -fila * 2.6
		var mas := MascotaQ.crear(self, c, String(animales[i]), Vector3(x, 0, z), 0.0)
		if mas != null:
			(mas.get_node("Animador") as Node).set_process(false)
			var ap: AnimationPlayer = mas.find_children("*", "AnimationPlayer", true, false)[0]
			if ap.has_animation("parado"):
				ap.play("parado")
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.position = Vector3(0, 2.6, 9.5)
	_cam.look_at(Vector3(0, 1.4, -1.0), Vector3.UP)

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		get_viewport().get_texture().get_image().save_png("res://pruebas/mascotas.png")
		_cam.position = Vector3(-3.2, 1.9, 2.4)
		_cam.look_at(Vector3(-4.8, 1.6, 0.0), Vector3.UP)
	if _n == 14:
		get_viewport().get_texture().get_image().save_png("res://pruebas/mascotas_cerca.png")
		_cam.position = Vector3(-2.0, 1.5, -2.2)
		_cam.look_at(Vector3(-4.8, 1.1, 0.0), Vector3.UP)
	if _n == 20:
		get_viewport().get_texture().get_image().save_png("res://pruebas/mascotas_espalda.png")
		get_tree().quit()
