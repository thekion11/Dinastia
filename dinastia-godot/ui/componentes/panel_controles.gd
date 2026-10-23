class_name PanelControles
extends "res://ui/componentes/panel_controles_p2.gd"
## [Capa 3/3 de `panel_controles.gd`] _montar, filas_de_acciones, _cambiar_seccion, _input

# ------------------------------------------------------------------ montaje

func _montar() -> void:
	Mando.registrar()
	dispositivo = ControlFC.dispositivo_detectado()
	if dispositivo == "teclado":
		dispositivo = "xbox"
	_foto = {"propio": Mando.propio.duplicate(true), "esquema": Mando.esquema, "ayudas": Mando.ayudas.duplicate()}
	## Fondo vivo.
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SHADER_FONDO
	sm.shader = sh
	fondo.material = sm
	add_child(fondo)
	for tipo: String in ["bokeh", "motas"]:
		var fp := FondoParticulas.new(tipo)
		fp.color = Tema.ORO.lerp(Color.WHITE, 0.4) if tipo == "motas" else Tema.ACENTO.lerp(Color.WHITE, 0.2)
		add_child(fp)
		fp.ajustar_area(get_viewport_rect().size)
	## Todo el contenido, con márgenes.
	_raiz = Control.new()
	_raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.offset_left = 28
	_raiz.offset_right = -28
	_raiz.offset_top = 18
	_raiz.offset_bottom = -16
	add_child(_raiz)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 10)
	_raiz.add_child(col)
	_montar_cabecera(col)
	var cuerpo := HBoxContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 14)
	col.add_child(cuerpo)
	_montar_menu(cuerpo)
	_montar_centro(cuerpo)
	_montar_mando(cuerpo)
	_montar_pie(col)
	_pintar()
	## Entrada: aparece y sube un poco.
	_raiz.modulate.a = 0.0
	_raiz.position.y += 16.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_raiz, "modulate:a", 1.0, 0.28)
	tw.tween_property(_raiz, "position:y", _raiz.position.y - 16.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	(_items_menu[_pestana] as Control).grab_focus.call_deferred()

## Cuántas filas de acción reasignable tiene la sección «Asignar botones».
func filas_de_acciones() -> int:
	var n := 0
	for g: Array in GRUPOS:
		for a: String in g[1]:
			if Mando.MAPA.has(a):
				n += 1
	return n

func _cambiar_seccion(paso: int) -> void:
	var lista := _secciones()
	var i := 0
	for k in lista.size():
		if String(lista[k][0]) == _pestana:
			i = k
	i = wrapi(i + paso, 0, lista.size())
	_ir_a(String(lista[i][0]))
	(_items_menu[_pestana] as Control).grab_focus()

# ------------------------------------------------------------------ entrada

func _input(ev: InputEvent) -> void:
	if _dialogo != null:
		if ev.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_cerrar_dialogo()
		return
	if _escuchando == "":
		if ev.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_volver()
			return
		## Cambiar de sección: LB/RB (o L1/R1) y Re Pág / Av Pág.
		var izq := (ev is InputEventJoypadButton and (ev as InputEventJoypadButton).pressed and (ev as InputEventJoypadButton).button_index == JOY_BUTTON_LEFT_SHOULDER) \
			or (ev is InputEventKey and (ev as InputEventKey).pressed and (ev as InputEventKey).keycode == KEY_PAGEUP)
		var der := (ev is InputEventJoypadButton and (ev as InputEventJoypadButton).pressed and (ev as InputEventJoypadButton).button_index == JOY_BUTTON_RIGHT_SHOULDER) \
			or (ev is InputEventKey and (ev as InputEventKey).pressed and (ev as InputEventKey).keycode == KEY_PAGEDOWN)
		if izq or der:
			get_viewport().set_input_as_handled()
			_cambiar_seccion(-1 if izq else 1)
		## Con el foco en el menú, «derecha» entra en la tabla.
		elif ev.is_action_pressed("ui_right") and get_viewport().gui_get_focus_owner() in _items_menu.values():
			get_viewport().set_input_as_handled()
			_enfocar_primera_fila()
		elif ev.is_action_pressed("ui_left") and get_viewport().gui_get_focus_owner() != null and _contenido.is_ancestor_of(get_viewport().gui_get_focus_owner()):
			get_viewport().set_input_as_handled()
			(_items_menu[_pestana] as Control).grab_focus()
		return
	var vale := (ev is InputEventKey and (ev as InputEventKey).pressed and not (ev as InputEventKey).echo) \
		or (ev is InputEventJoypadButton and (ev as InputEventJoypadButton).pressed)
	if not vale:
		return
	get_viewport().set_input_as_handled()
	var accion := _escuchando
	if ev is InputEventKey and (ev as InputEventKey).keycode == KEY_DELETE:
		_escuchando = ""
		_aviso.text = ""
		_sonar("menu_atras")
		_repintar_conservando(accion)
		return
	_escuchando = ""
	Mando.reasignar(accion, ev)
	_marcar_cambio(Idiomas.t("«%s» ahora es: %s") % [Idiomas.t(String(Mando.MAPA[accion][0])), Mando.texto_de(accion)])
	if is_inside_tree():
		_repintar_conservando(accion)
