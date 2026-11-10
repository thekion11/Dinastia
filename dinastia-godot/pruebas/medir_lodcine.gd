extends Node
## (10-11) LodCine antes/después, sin depender de que haya un gol: el estadio de cada club con una cámara de celebración a ras de césped
## ((-9, 2, -55) mirando al centro, como el plano medido en Mill0narios). Llamadas de dibujo y foto con la bandera apagada y encendida.
##   OUT=carpeta CLUBES="Mill0narios,B0ca Juni0rs,Int3r" herramientas/captura.sh res://pruebas/medir_lodcine.tscn
func _ready() -> void:
	var dir := OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/lodcine"
	DirAccess.make_dir_recursive_absolute(dir)
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
			print("no está ", nombre)
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
		for act: bool in [false, true]:
			LodCine.activo = act
			for _f in 20:
				await get_tree().process_frame
			var ll := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
			var ap := 0
			for v: Node in raiz.find_children("LodCine", "", true, false):
				ap += (v as LodCine)._apagadas.size()
			print("LODCINE %s %s: %d llamadas, %d piezas apagadas" % [nombre, "SÍ" if act else "NO", ll, ap])
			get_viewport().get_texture().get_image().save_jpg("%s/%s_%s.jpg" % [dir, nombre.validate_filename(), "si" if act else "no"], 0.9)
		raiz.queue_free()
		await get_tree().process_frame
	LodCine.activo = true
	print("FIN")
	get_tree().quit()
