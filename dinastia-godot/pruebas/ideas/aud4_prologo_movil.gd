extends BaseIdea
## A4-INT · EL PRÓLOGO 3D EN EL MÓVIL (2400×1080 a 400 ppp, MÍNIMA, modo táctil; castellano y alemán): la presentación, los diálogos del mentor y del personal, la pregunta de la directiva, la sala de prensa y el «Saltar el prólogo»:
## botones ≥ 7 mm, nada fuera de la pantalla, y los diálogos no se solapan con los controles táctiles para andar.
var _p: PrologoDT
var _e: ExploradorCiudad
var _m: Mundo

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _graves(raiz: Node, alto: float) -> Array:
	return AyudaMovil.problemas(raiz, alto).filter(func(x: String) -> bool: return x.begins_with("toque") or x.begins_with("botón fuera") or x.begins_with("botón por debajo") or x.begins_with("texto fuera") or x.begins_with("texto por debajo"))

func _terminar_charla() -> void:
	for i in 12:
		if not _p.dialogo.visible:
			return
		_p._hablar()

func _solape(a: Control, b: Control) -> float:
	var i := a.get_global_rect().intersection(b.get_global_rect())
	return i.get_area()

func _probar() -> void:
	_titulo("AUDITORÍA 4 · PRÓLOGO 3D EN EL MÓVIL")
	_respaldar_user()
	var idioma_antes := Idiomas.idioma
	var calidad_antes := Calidad.elegida
	Calidad.elegida = Calidad.MINIMO
	OS.set_environment("TACTIL", "1")
	OrquestadorMundo.sin_prologo = false
	for idi: String in ["es", "de"]:
		AyudaMovil.poner(Vector2i(2400, 1080), get_window())
		Idiomas.idioma = idi
		_m = _mundo(4242)
		PedidoPartida.mundo_pregenerado = _m
		PedidoPartida.modo_elegido = "dt"
		PedidoPartida.dt_nombre_elegido = "Míster Prueba"
		PrologoDT.rapido = true
		var t0 := Time.get_ticks_msec()
		_p = (load("res://escenas/prologo.tscn") as PackedScene).instantiate()
		add_child(_p)
		for i in 400:
			await get_tree().process_frame
			if _p._listo:
				break
		var ms := Time.get_ticks_msec() - t0
		_comprobar(_p._listo, "%s: el prólogo construye la ciudad y arranca (%d ms; sin dibujar)" % [idi, ms])
		if not _p._listo:
			_p.queue_free()
			continue
		_e = _p.explorador
		var alto := EscalaMovil.alto_toque(_p)
		await _frames(10)
		var g := _graves(_p, alto)
		_comprobar(g.is_empty(), "%s · arranque (presentación): %d problemas %s" % [idi, g.size(), str(g.slice(0, 4))])
		## Diálogo del mentor (paso 0).
		_comprobar(_p.dialogo.visible, "%s · el mentor te recibe hablando" % idi)
		g = _graves(_p.dialogo, alto)
		_comprobar(g.is_empty(), "%s · diálogo del mentor: %d problemas %s" % [idi, g.size(), str(g.slice(0, 4))])
		## Controles táctiles para andar: ¿tapa el diálogo el pad o los botones?
		_terminar_charla()
		await _frames(30)   ## tras el primer diálogo (que es modal) aparecen los controles para andar
		var botones_andar: Array = []
		if is_instance_valid(_e._boton_e):
			for bb in _e._boton_e.get_parent().get_children():
				if bb is Button and (bb as Button).is_visible_in_tree():
					botones_andar.append(bb)
		var mandos: Array = _p.find_children("*", "MandoTactil", true, false)
		_linea("      %s: al andar hay %d botones táctiles (cámara, E, Salir) y el mando MandoTactil ×%d" % [idi, botones_andar.size(), mandos.size()])
		_comprobar(botones_andar.size() >= 2 and not mandos.is_empty(), "%s · el modo táctil muestra los botones y la palanca para andar" % idi)
		var pequenos := botones_andar.filter(func(x: Button) -> bool: return x.size.y < alto - 1.5)
		_comprobar(pequenos.is_empty(), "%s · botones de andar ≥ 7 mm (%d más pequeños)" % [idi, pequenos.size()])
		g = _graves(_e._boton_e.get_parent(), alto)
		_comprobar(g.is_empty(), "%s · botones de andar dentro de la pantalla: %s" % [idi, str(g.slice(0, 3))])
		## Llegar al mentor y a la puerta.
		_e.cuerpo.position = _p.mentor.position + Vector3(0, 0, 0.8)
		await _frames(2)
		_e.cuerpo.position = _p.destino
		await _frames(3)
		g = _graves(_p, alto)
		_comprobar(g.is_empty(), "%s · en la puerta: %d problemas %s" % [idi, g.size(), str(g.slice(0, 3))])
		_terminar_charla()
		_e._entrar_al_estadio()
		await _frames(3)
		for clave: String in ["vestuario", "tunel", "campo", "utileria", "enfermeria"]:
			var i := PrologoPasos.indice(clave)
			if _p.paso_i != i:
				break
			var paso: Dictionary = PrologoPasos.PASOS[i]
			_e._planta = int(paso["planta"])
			_e.cuerpo.position = _p.destino
			await _frames(4)
			if _p.dialogo.visible:
				g = _graves(_p, alto)
				_comprobar(g.is_empty(), "%s · sala «%s»: diálogo %d problemas %s" % [idi, clave, g.size(), str(g.slice(0, 3))])
			_terminar_charla()
			await _frames(2)
		## La pregunta de la directiva.
		var i_pres := PrologoPasos.indice("presidente")
		if _p.paso_i == i_pres:
			_e._planta = int(PrologoPasos.PASOS[i_pres]["planta"])
			_e.cuerpo.position = _p.destino
			await _frames(4)
			_terminar_charla()
			await _frames(3)
			if is_instance_valid(_p.hud._directiva):
				g = _graves(_p.hud._directiva, alto)
				_comprobar(g.is_empty(), "%s · pregunta de la directiva: %d problemas %s" % [idi, g.size(), str(g.slice(0, 4))])
				_p._responder_directiva(0)
				await _frames(2)
				_p._hablar()
				await _frames(2)
		## Sala de vídeo y sala de PRENSA (la presentación con tres respuestas).
		for clave2: String in ["video", "prensa"]:
			var i2 := PrologoPasos.indice(clave2)
			if _p.paso_i != i2:
				break
			_e._planta = int(PrologoPasos.PASOS[i2]["planta"])
			_e.cuerpo.position = _p.destino
			await _frames(5)
			_terminar_charla()
			await _frames(4)
			if clave2 == "prensa" and is_instance_valid(_p.prensa):
				g = _graves(_p.prensa, alto)
				_comprobar(g.is_empty(), "%s · sala de prensa (presentación): %d problemas %s" % [idi, g.size(), str(g.slice(0, 4))])
				_comprobar(_p.prensa._botones.get_child_count() >= 2, "%s · la sala de prensa ofrece sus respuestas (%d botones)" % [idi, _p.prensa._botones.get_child_count()])
				for b2: Button in _p.prensa._botones.get_children():
					b2.pressed.emit()
				await _frames(3)
		## «Saltar el prólogo».
		_p.hud.pedir_saltar()
		await _frames(6)
		g = _graves(_p.hud._confirmar if is_instance_valid(_p.hud._confirmar) else _p.hud, alto)
		_comprobar(g.is_empty(), "%s · confirmar «saltar el prólogo»: %d problemas %s" % [idi, g.size(), str(g.slice(0, 3))])
		_p.queue_free()
		await _frames(4)
		AyudaMovil.quitar(get_window())
	OS.set_environment("TACTIL", "")
	OrquestadorMundo.sin_prologo = true
	Calidad.elegida = calidad_antes
	Idiomas.idioma = idioma_antes
	PedidoPartida.mundo_pregenerado = null
	PrologoDT.rapido = false
	_restaurar_user()
