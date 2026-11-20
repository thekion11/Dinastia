extends Node
## ALINEACIÓN DE PERSONAJES (20-11): todos los cortes de pelo (`PersonajeDT.CORTES`) o todas las ropas (`PersonajeDT.ROPAS`) en una fila, con el mismo cuerpo y luz
## neutra, para ver cuáles no tienen sentido, cuál no queda bien en el cuerpo y qué extremidades fallan. MODO=cortes|ropas, GENERO=male|female, TONO=e0b08a, SALIDA=<carpeta>.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 2000x560 res://pruebas/captura_cortes_ropas.tscn
func _ready() -> void:
	var modo := OS.get_environment("MODO") if OS.get_environment("MODO") != "" else "cortes"
	var genero := OS.get_environment("GENERO") if OS.get_environment("GENERO") != "" else "male"
	var tono := OS.get_environment("TONO") if OS.get_environment("TONO") != "" else "e0b08a"
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
	var lista: Array = PersonajeDT.CORTES if modo == "cortes" else PersonajeDT.ROPAS.map(func(r: Array) -> String: return String(r[0]))
	## PARTE=0|1: la mitad de la lista (a cabezas llenas caben 5 en pantalla, PARTE=0,1,2; las ropas, todas en cuerpo entero).
	var ini := 0
	var fin := lista.size()
	var parte := OS.get_environment("PARTE")
	if modo == "cortes" and parte != "":
		ini = 5 * int(parte)
		fin = mini(ini + 5, lista.size())
	var n := fin - ini
	for i0 in n:
		var i := i0 + ini
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		var asp := PersonajeDT.aleatorio(rng)
		asp["cuerpo"] = genero
		asp["piel"] = tono
		asp["gorra"] = false
		asp["gafas"] = ""
		asp["barba"] = false
		asp["tatuaje"] = 0
		asp["color_pelo"] = "4a3020"
		if modo == "cortes":
			asp["pelo"] = lista[i]
			asp["ropa"] = "polo"
		else:
			asp["ropa"] = lista[i]
			asp["pelo"] = "corto"
		var nodo := Node3D.new()
		raiz.add_child(nodo)
		nodo.position = Vector3(((n - 1) / 2.0 - i0) * (0.75 if modo == "cortes" else 1.0), 0, 0)   ## de izquierda a derecha en el orden de la lista, mirando a la cámara
		nodo.rotation.y = 0.0
		PersonajeDT.crear(nodo, asp, Color(0.8, 0.1, 0.1), Color.WHITE)
		var et := Label3D.new()
		et.text = String(lista[i])
		et.font_size = 48
		et.pixel_size = 0.0022
		et.modulate = Color(1, 1, 0.6)
		et.outline_size = 8
		et.no_depth_test = true
		raiz.add_child(et)
		et.position = nodo.position + Vector3(0, 1.28 if modo == "cortes" else -0.15, 0.3)
	var cam := Camera3D.new()
	raiz.add_child(cam)
	if modo == "cortes":
		cam.fov = 17.0
		cam.position = Vector3(0, 1.62, 3.6)
		cam.look_at(Vector3(0, 1.62, 0), Vector3.UP)
	else:
		cam.fov = 26.0
		cam.position = Vector3(0, 0.9, 15)
		cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	cam.current = true
	await get_tree().create_timer(2.5).timeout
	await RenderingServer.frame_post_draw
	var carpeta := OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "user://cortes"
	DirAccess.make_dir_recursive_absolute(carpeta)
	get_viewport().get_texture().get_image().save_jpg(carpeta.path_join("%s_%s%s.jpg" % [modo, genero, parte]), 0.92)
	print("FIN")
	get_tree().quit()
