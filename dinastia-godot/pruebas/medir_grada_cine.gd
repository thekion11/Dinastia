extends Node
## (10-11, orden 36) QUÉ PESA EN EL PLANO DE CELEBRACIÓN: el estadio de cada club con la cámara a ras de césped ((-9, 2, -55) mirando al
## campo, la del gol medida en Mill0narios). Llamadas y triángulos del plano y lo que quita apagar cada pieza grande (tribunas, público…).
##   CLUBES="Mill0narios,B0ca Juni0rs,Int3r" godot --path . res://pruebas/medir_grada_cine.tscn
const RS := RenderingServer
func _ready() -> void:
	Datos.usar_base_real(true)
	Calidad.elegida = int(OS.get_environment("CALIDAD")) if OS.get_environment("CALIDAD") != "" else Calidad.MEDIO
	var m := Mundo.new()
	m.generar(["COL", "ARG", "ITA"], 2026)
	var lista := OS.get_environment("CLUBES") if OS.get_environment("CLUBES") != "" else "Mill0narios,B0ca Juni0rs,Int3r"
	for nombre: String in lista.split(","):
		var club: Club = null
		for c: Club in m.clubes.values():
			if c.nombre == nombre:
				club = c
		if club == null:
			continue
		var raiz := Node3D.new()
		add_child(raiz)
		var sol := DirectionalLight3D.new()
		sol.rotation_degrees = Vector3(-50, -30, 0)
		sol.shadow_enabled = Calidad.sombra_solar(Calidad.elegida)
		raiz.add_child(sol)
		await StadiumBuilder.build(raiz, club.perfil_estadio(), 60000, 0.85, 7, club)
		var cam := Camera3D.new()
		cam.name = "CineGol"
		cam.fov = 38.0
		cam.far = 700.0
		raiz.add_child(cam)
		cam.global_position = Vector3(-9, 2, -55)
		cam.look_at(Vector3(0, 6, 0), Vector3.UP)
		cam.make_current()
		for _f in 20:
			await get_tree().process_frame
		var ll := RS.get_rendering_info(RS.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var tri := RS.get_rendering_info(RS.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		print("PLANO %s: %d llamadas · %d triángulos" % [nombre, ll, tri])
		get_viewport().get_texture().get_image().save_jpg("/tmp/grada_%s.jpg" % nombre.validate_filename(), 0.85)
		if OS.get_environment("DESGLOSE") != "":
			for h: Node in raiz.get_children():
				if not h is Node3D or not (h as Node3D).visible:
					continue
				(h as Node3D).visible = false
				for _f in 3:
					await get_tree().process_frame
				var dl := ll - RS.get_rendering_info(RS.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
				var dt := tri - RS.get_rendering_info(RS.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
				(h as Node3D).visible = true
				if dl >= 8 or dt >= 30000:
					print("   -%4d llamadas  -%7d triángulos  %s [%s]" % [dl, dt, h.name, h.get_class()])
		raiz.queue_free()
		await get_tree().process_frame
	print("FIN")
	get_tree().quit()
