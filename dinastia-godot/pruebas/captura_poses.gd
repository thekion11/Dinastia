extends Node
## POSES Y EXTREMIDADES (20-11): cada animación del DT (`PersonajeDT.gestos_banda` + las de base) congelada a media duración, de cuerpo entero, de frente
## y de lado, con el mismo cuerpo y luz neutra: para ver brazos que atraviesan el cuerpo, manos mal, rodillas al revés o pies sin apoyar.
## GENERO=male|female, LADO=frente|perfil, SALIDA=<carpeta>.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 2000x760 res://pruebas/captura_poses.tscn
func _ready() -> void:
	var genero := OS.get_environment("GENERO") if OS.get_environment("GENERO") != "" else "male"
	var lado := OS.get_environment("LADO") if OS.get_environment("LADO") != "" else "frente"
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
	we.environment.ambient_light_color = Color(0.75, 0.75, 0.78)
	raiz.add_child(we)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var asp := PersonajeDT.aleatorio(rng)
	asp["cuerpo"] = genero
	asp["ropa"] = "chandal"
	asp["gorra"] = false
	asp["pelo"] = "corto"
	asp["barba"] = false
	var nodos: Array = []
	var nombres: Array[String] = []
	## Una primera pasada para saber qué animaciones hay.
	var d0 := PersonajeDT.crear(raiz, asp, Color(0.8, 0.1, 0.1), Color.WHITE)
	PersonajeDT.gestos_banda(d0)
	var ap0: AnimationPlayer = d0.get("anim")
	for lib in ap0.get_animation_library_list():
		for an in ap0.get_animation_library(lib).get_animation_list():
			nombres.append(("" if lib == &"" else String(lib) + "/") + String(an))
	d0["nodo"].queue_free()
	nombres = nombres.filter(func(n: String) -> bool: return n != "RESET" and not n.ends_with("/RESET"))
	var pedidas := OS.get_environment("SOLO")
	if pedidas != "":
		nombres = nombres.filter(func(n: String) -> bool: return n in pedidas.split(","))
	print("ANIMACIONES ", nombres.size(), " ", nombres)
	var n := nombres.size()
	for i in n:
		var d := PersonajeDT.crear(raiz, asp, Color(0.8, 0.1, 0.1), Color.WHITE)
		PersonajeDT.gestos_banda(d)
		var nodo: Node3D = d["nodo"]
		nodo.position = Vector3(((n - 1) / 2.0 - i) * 1.25, 0, 0)
		nodo.rotation.y = 0.0 if lado == "frente" else PI * 0.5
		var ap: AnimationPlayer = d["anim"]
		ap.play(nombres[i])
		ap.seek(ap.current_animation_length * 0.5, true)
		ap.pause()
		var et := Label3D.new()
		et.text = nombres[i].get_file()
		et.font_size = 40
		et.pixel_size = 0.004
		et.modulate = Color(1, 1, 0.6)
		et.outline_size = 8
		et.no_depth_test = true
		raiz.add_child(et)
		et.position = nodo.position + Vector3(0, -0.12, 0.4)
	var cam := Camera3D.new()
	raiz.add_child(cam)
	cam.fov = 24.0
	var ancho := maxf(n * 1.25, 4.0)
	cam.position = Vector3(0, 0.95, maxf(ancho * 1.05, 7.0))
	cam.look_at(Vector3(0, 0.95, 0), Vector3.UP)
	cam.current = true
	await get_tree().create_timer(2.5).timeout
	await RenderingServer.frame_post_draw
	var carpeta := OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "user://poses"
	DirAccess.make_dir_recursive_absolute(carpeta)
	get_viewport().get_texture().get_image().save_jpg(carpeta.path_join("poses_%s_%s.jpg" % [genero, lado]), 0.92)
	print("FIN")
	get_tree().quit()
