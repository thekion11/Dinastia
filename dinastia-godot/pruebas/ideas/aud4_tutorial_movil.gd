extends BaseIdea
## A4-INT · el TUTORIAL en el móvil (2400×1080 a 400 ppp, MÍNIMA; castellano y alemán): en cada paso la tarjeta del mentor cabe en la pantalla, sus botones miden ≥ 7 mm y NO tapa el control que hay que tocar
## (ni se solapa con él más de un 10 %); además, que Principal esté listo con el tutorial puesto en un tiempo razonable.
func _frames(n: int = 2) -> void:
	for i in n:
		await get_tree().process_frame

func _probar() -> void:
	_titulo("AUDITORÍA 4 · TUTORIAL EN EL MÓVIL")
	_respaldar_user()
	var idioma_antes := Idiomas.idioma
	var calidad_antes := Calidad.elegida
	Calidad.elegida = Calidad.MINIMO
	var m := _mundo(20261104)
	for idi: String in ["es", "de"]:
		PedidoPartida.mundo_pregenerado = m
		AyudaMovil.poner(Vector2i(2400, 1080), get_window())
		_fijar_idioma(idi)
		CapasTutorial.poner_activas(true)
		PedidoPartida.tutorial_pedido = true   ## como si fuera la primera carrera
		var t0 := Time.get_ticks_msec()
		var p: Principal = load("res://escenas/principal.tscn").instantiate()
		add_child(p)
		await _frames(10)
		var ms := Time.get_ticks_msec() - t0
		_comprobar(ms < 20000, "%s: Principal con el tutorial listo en %d ms" % [idi, ms])
		var tut: Tutorial = null
		for t in get_tree().root.find_children("*", "Tutorial", true, false):
			tut = t as Tutorial
		if tut == null:
			_linea("      %s: no hay tutorial activo en esta partida (se omite)" % idi)
			p.queue_free()
			await _frames(4)
			AyudaMovil.quitar(get_window())
			continue
		var alto := EscalaMovil.alto_toque(p)
		var vp := get_viewport().get_visible_rect()
		## El PRÓLOGO (el mentor se presenta y se elige el aspecto): sus botones también miden ≥ 7 mm y caben.
		await _frames(6)
		var pr0 := AyudaMovil.problemas(tut, alto).filter(func(x: String) -> bool: return x.begins_with("toque") or x.begins_with("botón") or x.begins_with("texto fuera") or x.begins_with("texto por debajo"))
		_comprobar(pr0.is_empty(), "%s · prólogo del tutorial: %d problemas %s" % [idi, pr0.size(), str(pr0.slice(0, 4))])
		for k in 12:
			if tut.fase() != "prologo":
				break
			tut.pulsar_prologo()
			await _frames(4)
		_comprobar(tut.fase() == "dialogo", "%s · el prólogo termina con un toque a «Continuar» (fase %s)" % [idi, tut.fase()])
		var pasos: Array = tut.get("_pasos")
		var mal: Array[String] = []
		var n_obj := 0
		for i in pasos.size():
			tut.call("_mostrar", i)
			await _frames(4)
			var tarjeta: Control = tut.get("_tarjeta")
			if tarjeta == null or not tarjeta.is_visible_in_tree():
				continue
			var r := tarjeta.get_global_rect()
			if r.position.x < -1.0 or r.position.y < -1.0 or r.end.x > vp.size.x + 1.0 or r.end.y > vp.size.y + 1.0:
				mal.append("paso %d: tarjeta fuera de la pantalla %s" % [i, str(r)])
			for pr: String in AyudaMovil.problemas(tarjeta, alto):
				if pr.begins_with("toque") or pr.begins_with("botón"):
					mal.append("paso %d: %s" % [i, pr])
			var obj: Variant = tut.call("_objetivo")
			if OS.get_environment("TUT_DBG") != "":
				var o2: Variant = p.tutorial_objetivo(String((pasos[i] as Dictionary).get("objetivo", ""))) if (pasos[i] as Dictionary).has("objetivo") else null
				print("DBG paso ", i, " objetivo=", (pasos[i] as Dictionary).get("objetivo", "-"), " -> ", o2, " visible=", (o2 as Control).is_visible_in_tree() if o2 is Control else "-", " fase=", tut.fase(), " tarjeta=", r)
			if obj is Control:
				n_obj += 1
				var ro := (obj as Control).get_global_rect()
				var inter := r.intersection(ro)
				if ro.get_area() > 1.0 and inter.get_area() > ro.get_area() * 0.1:
					mal.append("paso %d: la tarjeta tapa el %d %% de lo que hay que tocar" % [i, int(100.0 * inter.get_area() / ro.get_area())])
		_comprobar(mal.is_empty(), "%s: %d pasos (%d con objetivo): %d problemas %s" % [idi, pasos.size(), n_obj, mal.size(), str(mal.slice(0, 5))])
		tut.call("_terminar", false)
		p.queue_free()
		await _frames(4)
		AyudaMovil.quitar(get_window())
	CapasTutorial.poner_activas(false)
	Calidad.elegida = calidad_antes
	Idiomas.idioma = idioma_antes
	PedidoPartida.mundo_pregenerado = null
	_restaurar_user()
