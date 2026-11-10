extends Node
## (10-11) Reproduce la rueda de prensa que salta sola tras 6 semanas, con 3 clubes de 3 países (ARG, USA, CHI). Foto de la sala con la
## cámara de la rueda. OUT=carpeta. CLUBES=«A,B,C» para otros. Imprime la posición del DT y de los periodistas.
const POR_DEFECTO := ["Riestra Sur", "Montana Rocosa", "U. Andina"]
var _dir := ""

func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout
	await get_tree().process_frame

func _ready() -> void:
	_dir = OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/fotos_rueda_semanas"
	DirAccess.make_dir_recursive_absolute(_dir)
	var nombres: Array = OS.get_environment("CLUBES").split(",") if OS.get_environment("CLUBES") != "" else POR_DEFECTO
	if OS.get_environment("MESA") == "0":   ## antes/después de la mesa larga (R7/R8): MESA=0 vuelve al atril
		RuedaPrensaMesa.activa = false
	var p: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	await _esperar(3.0)
	CapasTutorial.poner_activas(false)
	for i in nombres.size():
		var c: Club = null
		for x: Club in p.mundo.clubes.values():
			if x.nombre == String(nombres[i]):
				c = x
		if c == null:
			print("NO ENCONTRADO ", nombres[i])
			continue
		p.mundo.tomar_el_mando(c.id)
		for s in 6:
			p.mundo.avanzar_semana()
		p.mundo.prensa.abrir_rueda(true, false)
		p._refrescar()
		await _esperar(1.0)
		if p._rueda_pop == null:
			p._abrir_rueda_pantalla_completa(p.mundo.prensa.entrevista)
		if OS.get_environment("PRONTO") != "":   ## la entrada del DT (R8): tres fotos en los primeros ~3 s
			for k in 3:
				await _esperar(0.6)
				for h in p.get_children():
					if h is EventoPantallaCompleta:
						h.queue_free()
				await _esperar(0.15)
				get_viewport().get_texture().get_image().save_jpg("%s/%d_%s_entra%d.jpg" % [_dir, i, c.pais, k], 0.88)
		await _esperar(5.0)
		for h in p.get_children():   ## un evento (inicio de temporada…) puede taparla: fuera antes de la foto
			if h is EventoPantallaCompleta or ((h.get_script() as Script) != null and (h.get_script() as Script).get_global_name() == &"PortadaPeriodico"):
				h.queue_free()   ## (y la portada del periódico de la semana: sin cerrarla se apilaban y sumaban llamadas de un club a otro)
		await _esperar(1.0)
		get_viewport().get_texture().get_image().save_jpg("%s/%d_%s.jpg" % [_dir, i, c.pais], 0.88)
		var ll: Array[int] = []
		for _f in 30:
			await get_tree().process_frame
			ll.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		ll.sort()
		print("LLAMADAS %s mesa=%s: min %d · mediana %d · máx %d · escenas de rueda vivas %d · SubViewport %d" % [c.pais, RuedaPrensaMesa.activa, ll[0], ll[15], ll[29],
			get_tree().root.find_children("*", "RuedaPrensaEscena3D", true, false).size(), get_tree().root.find_children("*", "SubViewport", true, false).size()])
		## FOTOS=n: n fotos más, cada 2,5 s (pasan por los planos de la rotación: frontal, medio, general, tres cuartos).
		for k in int(OS.get_environment("FOTOS")) if OS.get_environment("FOTOS") != "" else 0:
			await _esperar(2.5)
			get_viewport().get_texture().get_image().save_jpg("%s/%d_%s_%d.jpg" % [_dir, i, c.pais, k + 1], 0.88)
		var esc: Node = p._rueda_pop._escena if p._rueda_pop != null else null
		if esc != null:
			var dt: Node3D = esc.get("_dt_3d").get("nodo") if not (esc.get("_dt_3d") as Dictionary).is_empty() else null
			print("CLUB %s (%s) · DT 3D en %s" % [c.nombre, c.pais, str(dt.global_position) if dt != null else "—(retrato)"])
		while p._rueda_pop != null:
			p._responder(0)
			await _esperar(0.4)
		for h in p.get_children():
			if h is EventoPantallaCompleta or ((h.get_script() as Script) != null and (h.get_script() as Script).get_global_name() == &"PortadaPeriodico"):
				h.queue_free()   ## (y la portada del periódico de la semana: sin cerrarla se apilaban y sumaban llamadas de un club a otro)
	print("FIN")
	get_tree().quit()
