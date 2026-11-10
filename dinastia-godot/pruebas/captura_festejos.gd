extends Node
## (10-11) Fotos de los festejos por tipo de título con TRES clubes de ligas y colores distintos (regla 34): cada club pasa por dos tipos y
## por todas sus escenas. OUT = carpeta (por defecto /tmp/fotos_festejos). Sale con «FIN. N fallos».
var _fallos := 0

func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout
	await get_tree().process_frame

func _ok(c: bool, que: String) -> void:
	print(("  ok  " if c else "  FALLO  ") + que)
	if not c:
		_fallos += 1

func _ready() -> void:
	var dir := OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/fotos_festejos"
	DirAccess.make_dir_recursive_absolute(dir)
	var p: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	await _esperar(3.0)
	CapasTutorial.poner_activas(false)
	if OS.get_environment("CALIDAD") != "":   ## CALIDAD=0 (mínima, escenas 2D) … 3 (alta); por defecto MEDIA: festejos con modelos 3D
		Calidad.elegida = int(OS.get_environment("CALIDAD"))
	else:
		Calidad.elegida = Calidad.MEDIO
	var tipos := [["liga", "copa"], ["continental", "ascenso"], ["supercopa", "salvacion"]]
	for n in 3:
		var l: Liga = p.mundo.ligas[(n * 3) % p.mundo.ligas.size()]
		var club: Club = l.clubes[(n * 5 + 1) % l.clubes.size()]
		p.mundo.tomar_el_mando(club.id)
		p.mundo.prensa.eventos_vistos.append("directiva:%d" % p.mundo.anio)
		p._refrescar()
		await _esperar(1.0)
		for h in p.get_children():
			if h is EventoDialogo:
				h.queue_free()
		print("club: ", club.nombre, " (", club.pais, ") ", club.color1, "/", club.color2)
		for tipo: String in tipos[n]:
			var ev := EventoCelebracion.mostrar(p, "Título de prueba", tipo, JornadaCelebracion.rival_del_pasillo(p.mundo))
			await _esperar(1.5)
			var escenas := ev.escenas()
			_ok(escenas.size() >= 3 and ev._botones.get_child_count() == escenas.size(), "%s · %s: un botón por escena (%d)" % [club.nombre, tipo, escenas.size()])
			var filtro := OS.get_environment("FILTRO")   ## p. ej. FILTRO=escenario,manteo: solo esas escenas (Forward+ por software es lento)
			for e: String in escenas:
				if filtro != "" and not e in filtro.split(","):
					continue
				ev.ver(e)
				await _esperar(1.6)
				var llamadas := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
				print("  %s/%s: %s · %d llamadas de dibujo · %d jugadores 3D · %d tifos" % [tipo, e, "3D" if ev.vista3d != null else "2D", llamadas,
					(ev.vista3d as FestejoCampo3D).jugadores if ev.vista3d != null else 0, (ev.vista3d as FestejoCampo3D).tifos if ev.vista3d != null else 0])
				get_viewport().get_texture().get_image().save_jpg("%s/%d_%s_%s_%s.jpg" % [dir, n, club.pais, tipo, e], 0.85)
			var op := [""]
			ev.elegido.connect(func(o: String) -> void: op[0] = o)
			(ev._centro.get_child(ev._centro.get_child_count() - 1).get_child(-1) as Button).pressed.emit()
			_ok(op[0] == "seguir", "Continuar cierra el festejo")
			ev.queue_free()
			await _esperar(0.3)
	print("FIN. %d fallos" % _fallos)
	get_tree().quit()
