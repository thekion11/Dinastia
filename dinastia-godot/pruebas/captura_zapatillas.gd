extends Node3D
## Las zapatillas de la gente de cerca (`PeatonQ.calzar`): tres sentados como en
## el metro y tres de pie, vistos de cerca a la altura de los pies.
##   herramientas/captura.sh res://pruebas/captura_zapatillas.tscn
func _ready() -> void:
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0.4, 0.75, 3.0)
	cam.look_at(Vector3(0.4, 0.35, 0), Vector3.UP)
	cam.fov = 50
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 30, 0)
	sol.shadow_enabled = true
	add_child(sol)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.5, 0.55, 0.6)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.85, 0.85)
	env.ambient_light_energy = 0.6
	we.environment = env
	add_child(we)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(20, 20)
	suelo.mesh = pm
	suelo.material_override = Mini3D.mat(Color(0.25, 0.27, 0.3), 0.9)
	add_child(suelo)
	var rng := RandomNumberGenerator.new()
	for i in 6:
		rng.seed = 40 + i * 7
		var sentado := i < 3
		var deporte: Array = [Color(0.2, 0.4, 0.7), Color(0.1, 0.1, 0.12)] if i == 2 or i == 5 else []
		Mini3D.sala_deportiva = false
		var x := -1.4 + float(i % 3) * 1.1 + (0.5 if not sentado else 0.0)
		var d := Mini3D.persona(self, rng, Vector3(x, 0, -0.4 if sentado else -1.6), deporte)
		Mini3D.sala_deportiva = true
		if d.is_empty():
			continue
		var n: Node3D = d["nodo"]
		n.rotation.y = 0.5
		if sentado:
			Mini3D.caja(self, Vector3(x, 0.22, -0.55), Vector3(0.6, 0.44, 0.5), Mini3D.mat(Color(0.55, 0.1, 0.12), 0.7))
			var cadera := InteriorInstalacion._altura_cadera(n)
			if cadera > 0.0:
				n.position.y = 0.44 + 0.08 - cadera * 0.99
		Mini3D.anim(d, "sentado" if sentado else "parado", "")
	for k in 40:
		await get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/zapatillas.png")
		print("FOTO zapatillas")
	get_tree().quit()
