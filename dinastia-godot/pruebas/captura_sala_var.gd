extends Control
## LA SALA VAR POR DENTRO: un campo mínimo con jugadores y la sala abierta
## encima, con los monitores mirando ese campo.
var _n := 0
var _mundo: Node3D

func _ready() -> void:
	var vc := SubViewportContainer.new()
	vc.set_anchors_preset(Control.PRESET_FULL_RECT)
	vc.stretch = true
	add_child(vc)
	var vp := SubViewport.new()
	vp.size = Vector2i(1600, 900)
	vc.add_child(vp)
	_mundo = Node3D.new()
	vp.add_child(_mundo)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.4, 0.6, 0.85)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.7)
	env.environment = e
	_mundo.add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 30, 0)
	_mundo.add_child(sol)
	var cesped := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 110)
	cesped.mesh = pm
	var mc := StandardMaterial3D.new()
	mc.albedo_color = Color(0.18, 0.5, 0.22)
	cesped.material_override = mc
	_mundo.add_child(cesped)
	for i in 6:
		var d := FutbolistaQ.crear(1.8, "male")
		var r: Node3D = d["nodo"]
		r.position = Vector3(-6.0 + i * 2.4, 0, 30.0 + (i % 2) * 3.0)
		_mundo.add_child(r)
		FutbolistaQ.terminar(d, true)
		VestidorQ.vestir_equipacion(d, Color("c62828") if i % 2 == 0 else Color("1565c0"), Color.WHITE, "liso", Color("c68d68"), Color(0.1, 0.08, 0.06))
		(d["anim"] as AnimationPlayer).play("correr")
	var cam := Camera3D.new()
	cam.position = Vector3(30, 20, 30)
	_mundo.add_child(cam)
	cam.look_at(Vector3(0, 0, 30), Vector3.UP)

func _process(_d: float) -> void:
	_n += 1
	if _n == 5:
		var sv := SalaVAR.abrir(self, _mundo.get_world_3d(), Vector3(0, 0, 31), 67, "Posible fuera de juego en el gol")
		set_meta("sv", sv)
	if _n > 5 and has_meta("sv"):
		var sv2: Variant = get_meta("sv")
		if is_instance_valid(sv2):
			var t: float = (sv2 as Node).get("_t")
			if t > 2.0 and not has_meta("uno"):
				set_meta("uno", true)
				get_viewport().get_texture().get_image().save_png("res://pruebas/sala_var.png")
			if t > 5.6 and not has_meta("dos"):
				set_meta("dos", true)
				get_viewport().get_texture().get_image().save_png("res://pruebas/sala_var_decision.png")
				get_tree().quit()
