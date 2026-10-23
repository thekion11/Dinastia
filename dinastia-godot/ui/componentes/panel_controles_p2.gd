extends "res://ui/componentes/panel_controles_p1.gd"
## (Parte 2 de 3 de `panel_controles.gd`.)

func _etiquetas_mando() -> void:
	var et := {}
	var filas: Array = []
	if _pestana.begins_with("p"):
		filas = (ControlFC.MANUAL[int(_pestana.substr(1))] as Array)[2]
	else:
		## Fuera del manual: lo de cada acción en su forma corta.
		for a: String in Mando.MAPA:
			if a in ["jugar_arriba", "jugar_abajo", "jugar_izquierda", "jugar_derecha"] or a.begins_with("jugar_fili_"):
				continue
			filas.append([_nombres_disp(String(Mando.MAPA[a][0])).get_slice(" · ", 0).get_slice(" (", 0), [a], ""])
	for f: Array in filas:
		var fichas: Array = f[1]
		var nombre := Idiomas.t(String(f[0])).get_slice(" (", 0).get_slice(" / ", 0)
		var ultima: String = fichas[fichas.size() - 1] if not fichas.is_empty() else ""
		if dispositivo == "teclado":
			var ff := ultima.trim_prefix("mant:").trim_prefix("2x:")
			if Mando.MAPA.has(ff):
				for k: int in Mando.teclas_de(ff):
					if not et.has(str(k)):
						et[str(k)] = nombre
			continue
		for pz: String in ControlFC.piezas_de(ultima):
			if pz != "" and not et.has(pz):
				et[pz] = nombre
	## Los botones que no salen en la sección, con su papel general.
	if dispositivo == "teclado":
		for a: String in ["jugar_arriba", "jugar_izquierda", "jugar_abajo", "jugar_derecha"]:
			for k: int in Mando.teclas_de(a):
				if not et.has(str(k)):
					et[str(k)] = Idiomas.t("Moverse")
		for k2: int in [KEY_KP_8, KEY_KP_4, KEY_KP_6, KEY_KP_2]:
			if not et.has(str(k2)):
				et[str(k2)] = Idiomas.t("Filigranas")
	else:
		if not et.has("LS"):
			et["LS"] = Idiomas.t("Moverse")
		if not et.has("RS"):
			et["RS"] = Idiomas.t("Filigranas")
	if dispositivo != "teclado":
		for a: String in Mando.MAPA:
			for pz: String in ControlFC.piezas_de(a):
				if pz != "" and not et.has(pz):
					et[pz] = _nombres_disp(Idiomas.t(String(Mando.MAPA[a][0]))).get_slice(" · ", 0).get_slice(" (", 0)
	## Los sticks hacen dos cosas: moverse / filigranas y, al hundirlos, otra.
	if dispositivo != "teclado":
		if not _pestana.begins_with("p") or not et.has("LS") or String(et["LS"]).begins_with("Pedir"):
			et["LS"] = Idiomas.t("Moverse · hundir: pedir")
		if not _pestana.begins_with("p") or not et.has("RS") or String(et["RS"]).begins_with("Autopase"):
			et["RS"] = Idiomas.t("Filigranas · hundir: sombrero")
	_mando.etiquetas = et
	_mando.iluminadas = []
	_mando.teclas_iluminadas = []
	_mando.queue_redraw()

## Las filas entran una detrás de otra, deslizándose.
func _entrada_escalonada() -> void:
	var i := 0
	for h in _contenido.get_children():
		var c := h as Control
		if c == null:
			continue
		c.modulate.a = 0.0
		var tw := c.create_tween()
		tw.tween_interval(0.018 * float(mini(i, 18)))
		tw.tween_property(c, "modulate:a", 1.0, 0.18)
		i += 1

# ------------------------------------------------------------------ pintar

func _pintar() -> void:
	for h in _contenido.get_children():
		_contenido.remove_child(h)
		h.queue_free()
	_fila_activa = null
	_selector.visible = false
	for k: String in _items_menu:
		var b: Button = _items_menu[k]
		b.add_theme_color_override("font_color", Color("ffd23f") if k == _pestana else Tema.TEXTO)
		b.add_theme_color_override("font_focus_color", Color("ffd23f") if k == _pestana else Color.WHITE)
	if _items_menu.has(_pestana):
		_mover_pastilla_menu.call_deferred(_items_menu[_pestana])
	_mover_pastilla_disp()
	for n in find_children("*", "Label", true, false):
		if n.has_meta("pistas"):
			(n as Label).text = _pistas()
	_mando.dispositivo = "teclado" if dispositivo == "teclado" else dispositivo
	if _pestana.begins_with("p"):
		_pintar_parte(int(_pestana.substr(1)))
	else:
		match _pestana:
			"filigranas": _pintar_filigranas()
			"asignar": _pintar_asignar()
			"ayudas": _pintar_ayudas()
	_etiquetas_mando()
	_entrada_escalonada()
	_scroll.scroll_vertical = 0

func _montar_cabecera(col: VBoxContainer) -> void:
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 16)
	col.add_child(cab)
	var tit := VBoxContainer.new()
	tit.add_theme_constant_override("separation", 0)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(tit)
	var t := Tema.etiqueta(34, Tema.ORO, Idiomas.t("CONTROLES"))
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	t.add_theme_constant_override("shadow_offset_y", 2)
	tit.add_child(t)
	tit.add_child(Tema.etiqueta(14, Tema.SUAVE, Idiomas.t("Configuración clásica (tirar con ◯ / B), como en FC 26 · todo se puede cambiar")))
	## Selector de dispositivo: la pastilla dorada se desliza al elegido.
	var selector := Control.new()
	selector.custom_minimum_size = Vector2(390, 44)
	selector.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cab.add_child(selector)
	var marco := Panel.new()
	marco.add_theme_stylebox_override("panel", _estilo(Color(0, 0, 0, 0.35), 22, Color(1, 1, 1, 0.1)))
	marco.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	selector.add_child(marco)
	_pastilla_disp = Panel.new()
	_pastilla_disp.add_theme_stylebox_override("panel", _estilo(Tema.ORO.darkened(0.35), 18, Tema.ORO))
	_pastilla_disp.size = Vector2(126, 36)
	_pastilla_disp.position = Vector2(4, 4)
	selector.add_child(_pastilla_disp)
	var fila := HBoxContainer.new()
	fila.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fila.add_theme_constant_override("separation", 0)
	selector.add_child(fila)
	for par: Array in [["ps", "PlayStation"], ["xbox", "Xbox"], ["teclado", "⌨ Teclado"]]:
		var b := Button.new()
		b.text = String(par[1])
		b.flat = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 15)
		b.set_meta("sin_sonido", true)
		var clave: String = par[0]
		b.pressed.connect(func() -> void:
			if dispositivo != clave:
				dispositivo = clave
				_sonar("menu_seccion")
				_pintar()
				_mover_pastilla_disp())
		b.focus_entered.connect(_sonar.bind("menu_mover"))
		fila.add_child(b)
		_chips_disp[clave] = b
	_mover_pastilla_disp.call_deferred()

func _secciones() -> Array:
	var r: Array = []
	for i in ControlFC.MANUAL.size():
		var parte: Array = ControlFC.MANUAL[i]
		r.append(["p%d" % i, str(i + 1), String(parte[1]), CORTOS[i] if i < CORTOS.size() else String(parte[0])])
	r.append(["filigranas", "7", "✨", "Filigranas"])
	r.append(["asignar", "", "🎮", "Asignar botones"])
	r.append(["ayudas", "", "⚙", "Ayudas y esquema"])
	return r

func _enfocar_primera_fila() -> void:
	for h in _contenido.get_children():
		if h.has_meta("fila"):
			(h as Control).grab_focus()
			return

func _ir_a(clave: String) -> void:
	if clave == _pestana:
		_enfocar_primera_fila()
		return
	_pestana = clave
	_escuchando = ""
	_sonar("menu_seccion")
	_pintar()
	_enfocar_primera_fila.call_deferred()

func _montar_menu(cuerpo: HBoxContainer) -> void:
	var caja := PanelContainer.new()
	caja.custom_minimum_size = Vector2(214, 0)
	caja.add_theme_stylebox_override("panel", _estilo(Color(Tema.PANEL, 0.82), Tema.RADIO_GRANDE))
	cuerpo.add_child(caja)
	var envoltura := Control.new()
	caja.add_child(envoltura)
	_pastilla_menu = Panel.new()
	_pastilla_menu.add_theme_stylebox_override("panel", _estilo(Tema.ORO.darkened(0.55), Tema.RADIO, Tema.ORO))
	_pastilla_menu.size = Vector2(190, 40)
	envoltura.add_child(_pastilla_menu)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 4)
	_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	envoltura.add_child(_menu)
	var rot := Tema.etiqueta(11, Tema.SUAVE, Idiomas.t("MANUAL DE CONTROLES"))
	_menu.add_child(rot)
	for s: Array in _secciones():
		if String(s[0]) == "asignar":
			var sep := HSeparator.new()
			_menu.add_child(sep)
			_menu.add_child(Tema.etiqueta(11, Tema.SUAVE, Idiomas.t("AJUSTES")))
		var b := Button.new()
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 40)
		b.add_theme_font_size_override("font_size", 13)
		b.text = ("%s  %s   %s" % [s[2], s[1], Idiomas.t(String(s[3]))]) if String(s[1]) != "" else ("%s   %s" % [s[2], Idiomas.t(String(s[3]))])
		b.clip_text = true
		b.set_meta("sin_sonido", true)
		var clave: String = s[0]
		b.pressed.connect(func() -> void: _ir_a(clave))
		b.focus_entered.connect(func() -> void:
			_sonar("menu_mover")
			_mover_pastilla_menu(b))
		b.mouse_entered.connect(func() -> void: b.grab_focus())
		_menu.add_child(b)
		_items_menu[clave] = b
	_menu.add_child(Control.new())

func _montar_centro(cuerpo: HBoxContainer) -> void:
	var caja := PanelContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.add_theme_stylebox_override("panel", _estilo(Color(Tema.PANEL, 0.86), Tema.RADIO_GRANDE))
	cuerpo.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	caja.add_child(v)
	_titulo = Tema.etiqueta(22, Tema.TEXTO, "")
	v.add_child(_titulo)
	_subtitulo = Tema.etiqueta(12, Tema.SUAVE, "")
	_subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_subtitulo)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = false
	v.add_child(_scroll)
	var capa := Control.new()
	capa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	capa.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.add_child(capa)
	## El selector dorado que se desliza detrás de la fila con el foco.
	_selector = Panel.new()
	var es := _estilo(Color(Tema.ORO, 0.16), Tema.RADIO, Color(Tema.ORO, 0.9))
	es.set_border_width_all(0)
	es.border_width_left = 4
	_selector.add_theme_stylebox_override("panel", es)
	_selector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selector.visible = false
	capa.add_child(_selector)
	_contenido = VBoxContainer.new()
	_contenido.add_theme_constant_override("separation", 2)
	capa.add_child(_contenido)
	_contenido.resized.connect(func() -> void:
		capa.custom_minimum_size = Vector2(0, _contenido.size.y)
		_contenido.size.x = capa.size.x)
	capa.resized.connect(func() -> void: _contenido.size.x = capa.size.x)

func _montar_mando(cuerpo: HBoxContainer) -> void:
	var caja := PanelContainer.new()
	caja.custom_minimum_size = Vector2(450, 0)
	caja.add_theme_stylebox_override("panel", _estilo(Color(Tema.PANEL, 0.7), Tema.RADIO_GRANDE))
	cuerpo.add_child(caja)
	var v := VBoxContainer.new()
	caja.add_child(v)
	v.add_child(Tema.etiqueta(11, Tema.SUAVE, Idiomas.t("ASÍ SE VE TU MANDO")))
	_mando = DibujoMando.new()
	_mando.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_mando.custom_minimum_size = Vector2(400, 300)
	v.add_child(_mando)
	var leyenda := Tema.etiqueta(12, Tema.SUAVE, Idiomas.t("Gíralo con el ratón. En dorado, los botones de la combinación elegida."))
	leyenda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(leyenda)

func _cerrar_dialogo(con_sonido := true) -> void:
	if _dialogo == null:
		return
	if con_sonido:
		_sonar("menu_atras")
	var d := _dialogo
	_dialogo = null
	var tw := d.create_tween()
	tw.tween_property(d, "modulate:a", 0.0, 0.12)
	tw.tween_callback(d.queue_free)
	if _fila_activa != null and is_instance_valid(_fila_activa):
		_fila_activa.grab_focus.call_deferred()

## Un diálogo de confirmación con zoom de entrada; el primer botón tiene el foco.
func _preguntar(titulo: String, texto: String, botones: Array) -> void:
	_sonar("aviso")
	_dialogo = Control.new()
	_dialogo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialogo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dialogo)
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.0)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialogo.add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialogo.add_child(centro)
	var caja := PanelContainer.new()
	var est := _estilo(Tema.TARJETA, Tema.RADIO_GRANDE, Tema.ORO)
	est.set_border_width_all(2)
	est.shadow_color = Color(0, 0, 0, 0.6)
	est.shadow_size = 18
	est.content_margin_left = 26
	est.content_margin_right = 26
	est.content_margin_top = 20
	est.content_margin_bottom = 20
	caja.add_theme_stylebox_override("panel", est)
	caja.custom_minimum_size = Vector2(520, 0)
	centro.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	caja.add_child(v)
	v.add_child(Tema.etiqueta(22, Tema.ORO, titulo))
	var t := Tema.etiqueta(14, Tema.TEXTO, texto)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	fila.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(fila)
	var primero: Button = null
	for par: Array in botones:
		var b := Button.new()
		b.text = String(par[0])
		b.custom_minimum_size = Vector2(0, 40)
		b.add_theme_font_size_override("font_size", 15)
		b.set_meta("sin_sonido", true)
		var accion: Callable = par[1]
		b.focus_entered.connect(_sonar.bind("menu_mover"))
		b.pressed.connect(func() -> void:
			_sonar("menu_aceptar")
			_cerrar_dialogo(false)
			if accion.is_valid():
				accion.call())
		fila.add_child(b)
		if primero == null:
			primero = b
	caja.pivot_offset = Vector2(260, 80)
	caja.scale = Vector2(0.9, 0.9)
	caja.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(velo, "color:a", 0.55, 0.2)
	tw.tween_property(caja, "modulate:a", 1.0, 0.18)
	tw.tween_property(caja, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if primero != null:
		primero.grab_focus.call_deferred()

func _pedir_restaurar() -> void:
	_preguntar(Idiomas.t("¿Restaurar de fábrica?"), Idiomas.t("Se vuelve a la configuración clásica de FC con todas las ayudas por defecto. Después puedes guardar o descartar."),
		[[Idiomas.t("↺  Restaurar"), func() -> void:
			Mando.restaurar()
			_marcar_cambio(Idiomas.t("Controles de fábrica (sin guardar todavía)."))
			_pintar()], [Idiomas.t("Cancelar"), Callable()]])

func cerrar() -> void:
	_sonar("menu_atras")
	cerrado.emit()
	set_process_input(false)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.tween_callback(queue_free)

func _guardar(y_salir: bool) -> void:
	Mando.guardar()
	Mando.aplicar()
	_foto = {"propio": Mando.propio.duplicate(true), "esquema": Mando.esquema, "ayudas": Mando.ayudas.duplicate()}
	_cambios = false
	_sin_guardar.visible = false
	_sonar("guardado")
	_aviso.text = Idiomas.t("✔ Controles guardados.")
	if y_salir:
		cerrar()

func _descartar() -> void:
	Mando.propio = (_foto["propio"] as Dictionary).duplicate(true)
	Mando.esquema = String(_foto["esquema"])
	Mando.ayudas = (_foto["ayudas"] as Dictionary).duplicate()
	Mando.guardar()
	Mando.aplicar()
	_cambios = false
	cerrar()

func _volver() -> void:
	if _cambios:
		_preguntar(Idiomas.t("Tienes cambios sin guardar"), Idiomas.t("¿Qué quieres hacer con ellos?"),
			[[Idiomas.t("💾  Guardar y salir"), func() -> void: _guardar(true)],
			[Idiomas.t("Descartar"), _descartar],
			[Idiomas.t("Seguir editando"), Callable()]])
		return
	cerrar()

# ------------------------------------------------------------------ guardar

func _pedir_guardar() -> void:
	if not _cambios:
		_sonar("menu_aceptar")
		_aviso.text = Idiomas.t("No hay cambios que guardar.")
		return
	_preguntar(Idiomas.t("¿Guardar los cambios?"), Idiomas.t("¿Seguro que quieres guardar la nueva configuración de controles? Se usará en todos los partidos."),
		[[Idiomas.t("💾  Sí, guardar"), func() -> void: _guardar(false)], [Idiomas.t("Cancelar"), Callable()]])

func _pie(que: String) -> void:
	match que:
		"restaurar": _pedir_restaurar()
		"volver": _volver()
		"guardar": _pedir_guardar()

func _montar_pie(col: VBoxContainer) -> void:
	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 10)
	col.add_child(pie)
	_aviso = Tema.etiqueta(13, Tema.SUAVE, "")
	_aviso.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_aviso.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pie.add_child(_aviso)
	_sin_guardar = Tema.etiqueta(13, Tema.ORO, Idiomas.t("● Cambios sin guardar"))
	_sin_guardar.visible = false
	_sin_guardar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pie.add_child(_sin_guardar)
	var ayuda := Tema.etiqueta(12, Tema.SUAVE, "")
	ayuda.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ayuda.set_meta("pistas", true)
	pie.add_child(ayuda)
	for par: Array in [["↺  Restaurar", "restaurar"], ["↩  Volver", "volver"], ["💾  Guardar", "guardar"]]:
		var b := Button.new()
		b.text = Idiomas.t(String(par[0]))
		b.custom_minimum_size = Vector2(140, 40)
		b.add_theme_font_size_override("font_size", 15)
		b.set_meta("sin_sonido", true)
		var que: String = par[1]
		if que == "guardar":
			b.add_theme_stylebox_override("normal", _estilo(Tema.ACENTO.darkened(0.3), Tema.RADIO, Tema.ACENTO))
			b.add_theme_stylebox_override("hover", _estilo(Tema.ACENTO.darkened(0.1), Tema.RADIO, Tema.ACENTO.lightened(0.3)))
		b.focus_entered.connect(_sonar.bind("menu_mover"))
		b.pressed.connect(_pie.bind(que))
		pie.add_child(b)
