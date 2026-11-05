extends "res://pruebas/so/vis_partido_base.gd"
## RENDIMIENTO · lo que el partido le PIDE a la gráfica (llamadas de dibujo, triángulos, objetos y memoria de vídeo), no el tiempo de fotograma
## (que depende de la máquina y en --headless tiene un suelo de 6,9 ms). Cámara real del partido en calidad MEDIA y MÍNIMA; el tope es el de cada sistema
## (móvil más estricto). Se lanza con `herramientas/hw_modesto.sh` (2 núcleos, 4 GB, 1366x768) para parecerse a un equipo modesto.
## Valores medidos el 2-11 (docs/04_auditorias/rendimiento_120fps.md): MEDIO ≈ 824 llamadas · ~0,82 M triángulos en Compatibilidad.
func _nombre() -> String:
	return "ren_partido_presupuesto"

func _medir(n: int) -> Dictionary:
	var ll := 0.0
	var tr := 0.0
	var ob := 0.0
	for i in n:
		await get_tree().process_frame
		ll += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		tr += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		ob += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	return {"llamadas": ll / n, "triangulos": tr / n, "objetos": ob / n, "video_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0}

func _probar() -> void:
	_titulo("RENDIMIENTO · presupuesto del partido, %s [%s]" % [_metodo(), sistema()])
	_comprobar(DisplayServer.get_name() != "headless", "se mide con pantalla: --headless no dibuja y todo daría 0")
	await _montar_partido()
	var med: Dictionary = await _medir(40)
	print("  MEDICION medio: llamadas %.0f · triángulos %.0f · objetos %.0f · vídeo %.0f MB" % [med["llamadas"], med["triangulos"], med["objetos"], med["video_mb"]])
	var tope_ll := float(por_so({"movil": 1000, "web": 1100, "defecto": 1500}))
	var tope_tr := float(por_so({"movil": 1.0e6, "web": 1.2e6, "defecto": 1.8e6}))
	var tope_vram := float(por_so({"movil": 400, "web": 400, "defecto": 900}))
	_comprobar(float(med["llamadas"]) > 50.0, "se dibuja algo: %.0f llamadas (si da 0, no hay renderizador)" % med["llamadas"])
	_comprobar(float(med["llamadas"]) <= tope_ll, "llamadas de dibujo %.0f ≤ %.0f (tope de %s)" % [med["llamadas"], tope_ll, sistema()])
	_comprobar(float(med["triangulos"]) <= tope_tr, "triángulos %.0f ≤ %.0f" % [med["triangulos"], tope_tr])
	_comprobar(float(med["video_mb"]) <= tope_vram, "memoria de vídeo %.0f MB ≤ %.0f MB" % [med["video_mb"], tope_vram])
	var estatica := OS.get_static_memory_usage() / 1048576.0
	_comprobar(estatica < float(por_so({"movil": 1500, "web": 1500, "defecto": 3500})), "memoria estática del proceso %.0f MB" % estatica)
	## El nivel MÍNIMO no puede pedir MÁS que el medio.
	vista.queue_free()
	await _frames(3)
	Calidad.elegida = Calidad.MINIMO
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	var par := m.proximo_partido()
	vista = VistaEstadio.new()
	add_child(vista)
	vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))
	var n := 0
	while n < CALENTAR:
		await get_tree().process_frame
		for k in ["_intro", "_ceremonia"]:
			var x: Variant = vista.get(k)
			if x != null and is_instance_valid(x) and x.activa:
				x.terminar()
		n += 1
	var mini: Dictionary = await _medir(40)
	print("  MEDICION mínimo: llamadas %.0f · triángulos %.0f" % [mini["llamadas"], mini["triangulos"]])
	_comprobar(float(mini["llamadas"]) <= float(med["llamadas"]) * 1.05, "MÍNIMO no pide más llamadas que MEDIO (%.0f ≤ %.0f)" % [mini["llamadas"], med["llamadas"]])
	_comprobar(float(mini["triangulos"]) <= float(med["triangulos"]) * 1.05, "MÍNIMO no pide más triángulos que MEDIO")
	vista.queue_free()
	await _frames(2)
