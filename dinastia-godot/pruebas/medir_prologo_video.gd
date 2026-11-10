extends Node
## (10-11) IDEA DEL DUEÑO A MEDIR: ¿el prólogo como VÍDEO ya hecho (.ogv, Theora: lo que Godot reproduce de forma nativa; el .mp4 no) sube los FPS frente a la
## animación dibujada por el motor (`PrologoAnimado` + `PrologoArte`)? Mide las dos con las mismas cifras durante 6 s cada una: llamadas de dibujo,
## primitivas, tiempo de proceso (CPU: dibujar o decodificar), memoria estática y de vídeo. El vídeo NO va al repo (regla): se pasa por VIDEO=<ruta .ogv>.
##   VIDEO=/ruta/prologo.ogv xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/medir_prologo_video.tscn
## Las cifras de tiempo por software (llvmpipe) solo sirven para comparar entre sí, nunca como FPS del teléfono.
const SEGUNDOS := 6.0

func _ready() -> void:
	await get_tree().create_timer(0.5).timeout
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var anim := PrologoAnimado.new()
	anim._club = m.mi_club()
	anim._montar_base(self)
	anim._armar(null)
	await _medir("animacion_motor")
	anim.queue_free()
	await get_tree().process_frame
	var ruta := OS.get_environment("VIDEO")
	if ruta != "" and FileAccess.file_exists(ruta):
		var vp := VideoStreamPlayer.new()
		var st := VideoStreamTheora.new()
		st.file = ruta
		vp.stream = st
		vp.expand = true
		vp.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(vp)
		vp.play()
		await _medir("video_ogv")
		print("MEDIDA video_ogv tamaño_archivo %.1f MB" % (FileAccess.get_file_as_bytes(ruta).size() / 1048576.0))
	else:
		print("sin VIDEO=<ruta .ogv>: solo se mide la animación")
	get_tree().quit()

func _medir(nombre: String) -> void:
	await get_tree().create_timer(1.0).timeout   ## que arranque
	var n := 0
	var dib := 0.0
	var prim := 0.0
	var proc := 0.0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(SEGUNDOS * 1000.0):
		await get_tree().process_frame
		n += 1
		dib += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		prim += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	print("MEDIDA %-16s cuadros %4d  dibujo %6.1f  primitivas %8.0f  proceso %6.2f ms  mem_estatica %5.0f MB  vram %5.0f MB" % [nombre, n,
		dib / n, prim / n, proc / n, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])
