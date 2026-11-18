extends Node
## LOS TONOS DE PIEL (18-11): retratos de cerca de personajes del juego (los mismos que el mentor del prólogo) con luz neutra, uno por tono de
## `PersonajeDT.PIELES`, para ver si el naranja/rojo de las capturas del prólogo viene del modelo o de la luz. SALIDA=<carpeta>.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x540 res://pruebas/captura_pieles.tscn
func _ready() -> void:
	var raiz := Node3D.new()
	add_child(raiz)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-35, 25, 0)
	raiz.add_child(sol)
	var we := WorldEnvironment.new()
	we.environment = Environment.new()
	we.environment.background_mode = Environment.BG_COLOR
	we.environment.background_color = Color(0.5, 0.52, 0.55)
	we.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	we.environment.ambient_light_color = Color(0.7, 0.7, 0.72)
	raiz.add_child(we)
	var n := PersonajeDT.PIELES.size()
	var paso := 0.9
	for i in n:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7 + i
		var asp := PersonajeDT.aleatorio(rng)
		asp["piel"] = PersonajeDT.PIELES[i]
		asp["ropa"] = "traje"
		asp["gorra"] = false
		var nodo := Node3D.new()
		raiz.add_child(nodo)
		nodo.position = Vector3((i - (n - 1) / 2.0) * paso, 0, 0)
		nodo.rotation.y = PI
		PersonajeDT.crear(nodo, asp, Color(0.8, 0.1, 0.1), Color.WHITE)
	var cam := Camera3D.new()
	raiz.add_child(cam)
	cam.position = Vector3(0, 1.62, -5.2)
	cam.fov = 38
	cam.look_at(Vector3(0, 1.58, 0), Vector3.UP)
	cam.rotation.y = PI if false else cam.rotation.y
	cam.current = true
	await get_tree().create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	var carpeta := OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "user://pieles"
	DirAccess.make_dir_recursive_absolute(carpeta)
	get_viewport().get_texture().get_image().save_jpg(carpeta.path_join("pieles.jpg"), 0.92)
	print("FIN")
	get_tree().quit()
