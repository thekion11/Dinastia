extends BaseIdea
## A4-INT · EL PRIMER CONTACTO EN EL MÓVIL, de punta a punta (2400×1080 a 400 ppp, calidad MÍNIMA; castellano y alemán): intro → idioma → modo → país → club → entrada → personaje → (Principal: tutorial, primera semana).
## En cada etapa: tiempo que tarda en estar lista, que no esté en blanco, sin botones < 7 mm ni controles fuera de la pantalla. Todo con el dedo (se confirma cada etapa como lo haría el toque).
var _vistas: Array[String] = []
var _resultado: Dictionary = {}
var _cancelado := false

func _frames(n: int = 2) -> void:
	for i in n:
		await get_tree().process_frame

func _nuevo(estado: Dictionary = {}) -> OrquestadorEntrada:
	_vistas.clear()
	_resultado = {}
	_cancelado = false
	OrquestadorEntrada.estado_inicial = estado
	var o := OrquestadorEntrada.new()
	o.cambiar_escena = false
	o.duracion_fundido = 0.0
	o.etapa_cambiada.connect(func(k: String) -> void: _vistas.append(k))
	o.partida_lista.connect(func(r: Dictionary) -> void: _resultado = r)
	o.cancelado.connect(func() -> void: _cancelado = true)
	add_child(o)
	o._empezar()
	return o

func _probar() -> void:
	_titulo("AUDITORÍA 4 · PRIMER CONTACTO EN EL MÓVIL")
	_respaldar_user()
	OrquestadorMundo.ranura_al_salir = ""
	OrquestadorMundo.sin_prologo = true
	OrquestadorEntrada.ruta_prefs = "user://aud4_entrada_prueba.cfg"
	OrquestadorMundo.ruta_preferencias = "user://aud4_preferencias_prueba.cfg"
	var calidad_antes := Calidad.elegida
	var idioma_antes := Idiomas.idioma
	Calidad.elegida = Calidad.MINIMO
	for idi: String in ["es", "de"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(OrquestadorEntrada.ruta_prefs))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(OrquestadorMundo.ruta_preferencias))
		AyudaMovil.poner(Vector2i(2400, 1080), get_window())
		Idiomas.idioma = idi
		var respuestas := {
			"idioma": {"idioma": idi},
			"modo": {"modo": "creador"},
			"pais": {"pais": "CHI"},
			"config": {"nombre_club": "Club Móvil", "color1": "#112233", "color2": "ddeeff", "estadio": "Estadio Móvil", "casa": "casa", "fps": 60, "mascota": "Firulais", "densidad": "alta"},
			"entrada": {"entrada": {"tipo": "reemplazar"}},
			"personaje": {"personaje": {"nombre": "Ana Móvil", "aspecto": {"cuerpo": "female"}}},
		}
		var o := _nuevo({"dificultad": "facil"})
		var tiempos := {}
		for _i in 12:
			if not _resultado.is_empty() or _cancelado:
				break
			var k := o.etapa_actual()
			var t0 := Time.get_ticks_msec()
			await _frames(8)
			var p := o.pantalla_actual()
			if p == null:
				break
			var ms := Time.get_ticks_msec() - t0
			tiempos[k] = ms
			var visibles := p.find_children("*", "Control", true, false).filter(func(x: Node) -> bool: return (x as Control).is_visible_in_tree()).size()
			var pr := AyudaMovil.problemas(p, EscalaMovil.alto_toque(p))
			var graves := pr.filter(func(x: String) -> bool: return x.begins_with("toque") or x.begins_with("botón fuera") or x.begins_with("botón por debajo") or x.begins_with("texto fuera") or x.begins_with("texto por debajo"))
			_comprobar(visibles >= 3, "%s · %s: la etapa no está en blanco (%d controles visibles, %d ms)" % [idi, k, visibles, ms])
			_comprobar(graves.is_empty(), "%s · %s: toques y bordes: %d %s" % [idi, k, graves.size(), str(graves.slice(0, 4))])
			_linea("      %s · %s: %d textos recortados %s" % [idi, k, pr.filter(func(x: String) -> bool: return x.begins_with("cortado")).size(), str(pr.filter(func(x: String) -> bool: return x.begins_with("cortado")).slice(0, 2))])
			var t1 := Time.get_ticks_msec()
			p.emit_signal("terminado", (respuestas.get(k, {}) as Dictionary).duplicate(true))
			await _frames(2)
			tiempos[k + "_confirmar"] = Time.get_ticks_msec() - t1
		_comprobar(not _resultado.is_empty(), "%s: se llega a la partida lista (etapas: %s)" % [idi, ", ".join(_vistas)])
		_linea("      %s: tiempos (ms) %s" % [idi, str(tiempos)])
		var peor := 0
		for k2: String in tiempos:
			peor = maxi(peor, int(tiempos[k2]))
		_comprobar(peor < 20000, "%s: ningún paso tarda más de 20 s (el peor %d ms)" % [idi, peor])
		o.queue_free()
		await _frames(4)
		AyudaMovil.quitar(get_window())
	Calidad.elegida = calidad_antes
	Idiomas.idioma = idioma_antes
	PedidoPartida.mundo_pregenerado = null
	DirAccess.remove_absolute(ProjectSettings.globalize_path(OrquestadorEntrada.ruta_prefs))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(OrquestadorMundo.ruta_preferencias))
	_restaurar_user()
