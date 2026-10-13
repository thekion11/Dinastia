extends Node3D
## Fila de 8 peatones de cuerpo entero (13-10-2026): calzado, complexión,
## ojos y ropa. Salida: pruebas/capturas/peatones_fila.png
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x700 res://pruebas/captura_peatones_fila.tscn
var _n := 0
var _ds: Array = []

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
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(30, 10)
	suelo.mesh = pm
	add_child(suelo)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(OS.get_environment("SEMILLA")) if OS.get_environment("SEMILLA") != "" else 11
	for i in 8:
		var d := PeatonQ.crear(rng)
		if d.is_empty():
			continue
		add_child(d["nodo"])
		(d["nodo"] as Node3D).position = Vector3((i - 3.5) * 0.95, 0, 0)
		_ds.append(d)
	var cam := Camera3D.new()
	cam.fov = 30
	add_child(cam)
	cam.look_at_from_position(Vector3(0, 1.0, 6.2), Vector3(0, 0.95, 0))

func _process(_d: float) -> void:
	_n += 1
	if _n == 2:
		for d: Dictionary in _ds:
			PeatonQ.terminar(d)
			var ap: AnimationPlayer = d["anim"]
			var cual := OS.get_environment("ANIM") if OS.get_environment("ANIM") != "" else "parado"
			if ap.has_animation(cual):
				ap.play(cual)
	if _n == 4 and OS.get_environment("MEDIR") != "":
		for d: Dictionary in _ds:
			var e: Skeleton3D = d["esqueleto"]
			print("MANO ", "mujer" if d["mujer"] else "hombre", " ", e.get_bone_global_rest(e.find_bone("hand_l")).origin, " ", e.get_bone_global_rest(e.find_bone("lowerarm_l")).origin)
	if _n == 4:
		var e0: Skeleton3D = _ds[0]["esqueleto"]
		print("BRAZO peatón 0: ", e0.get_bone_pose_scale(e0.find_bone("upperarm_l")))
		for mi: MeshInstance3D in (_ds[0]["nodo"] as Node).find_children("*", "MeshInstance3D", true, false):
			var m := mi.get_surface_override_material(0) if mi.mesh != null and mi.get_surface_override_material_count() > 0 else null
			if m is ShaderMaterial and String((m as ShaderMaterial).shader.resource_path).contains("equipacion"):
				for k in ["usa_reposo", "largo", "civil", "holgura", "alisar"]:
					print("  ", mi.name, " ", k, "=", (m as ShaderMaterial).get_shader_parameter(k))
	if _n == 3 and OS.get_environment("PRUEBA_ESCALA") != "":
		var esq: Skeleton3D = _ds[0]["esqueleto"]
		var i := esq.find_bone("upperarm_l")
		esq.set_bone_pose_scale(i, Vector3(1, 0.5, 0.5))
	if _n == 20 and OS.get_environment("PRUEBA_ESCALA") != "":
		var esq2: Skeleton3D = _ds[0]["esqueleto"]
		print("ESCALA tras animar: ", esq2.get_bone_pose_scale(esq2.find_bone("upperarm_l")))
	if _n == 30:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/peatones_fila.png")
		get_tree().quit()
