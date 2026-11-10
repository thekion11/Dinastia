extends Node
## (10-11) Las vallas LED con el texto en atlas (`VallasLed.atlas_siempre`) o en rótulos sueltos: llamadas de dibujo y foto con la cámara
## del vuelo de la presentación (alta, fuera del estadio) y con una cámara de juego (lateral, alta), en varios estadios.
##   OUT=carpeta ATLAS=0|1 CLUBES="L1verpool,R0ma,R1ver Plate" herramientas/captura.sh res://pruebas/medir_vallas.tscn
const CAMS := {"vuelo": [Vector3(-97, 55, -36), Vector3(0, 0, 0)], "juego": [Vector3(-62, 26, 8), Vector3(0, 0, 4)]}

func _ready() -> void:
	var dir := OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/vallas"
	DirAccess.make_dir_recursive_absolute(dir)
	Datos.usar_base_real(true)
	Calidad.elegida = int(OS.get_environment("CALIDAD")) if OS.get_environment("CALIDAD") != "" else Calidad.MEDIO
	VallasLed.atlas_siempre = OS.get_environment("ATLAS") != "0"
	var m := Mundo.new()
	m.generar(["ENG", "ITA", "ARG"], 2026)
	var lista := OS.get_environment("CLUBES") if OS.get_environment("CLUBES") != "" else "L1verpool,R0ma,R1ver Plate"
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
		cam.fov = 50.0
		cam.far = 900.0
		raiz.add_child(cam)
		for _f in 90:   ## el atlas se pinta unos fotogramas después de montar
			await get_tree().process_frame
		for k: String in CAMS:
			cam.global_position = CAMS[k][0]
			cam.look_at(CAMS[k][1], Vector3.UP)
			cam.make_current()
			for _f in 10:
				await get_tree().process_frame
			print("VALLAS %s %s atlas=%s: %d llamadas" % [nombre, k, VallasLed.atlas_siempre, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
			get_viewport().get_texture().get_image().save_jpg("%s/%s_%s_%s.jpg" % [dir, nombre.validate_filename(), k, "atlas" if VallasLed.atlas_siempre else "rotulos"], 0.9)
		raiz.queue_free()
		await get_tree().process_frame
	VallasLed.atlas_siempre = true
	print("FIN")
	get_tree().quit()
