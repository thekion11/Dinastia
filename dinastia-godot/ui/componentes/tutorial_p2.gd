extends "res://ui/componentes/tutorial_p1.gd"
## (Parte 2 de 3 de `tutorial.gd`.)

## ✎: tres filas para elegir la chaqueta, el pelo y la piel del mentor.
func _pintar_panel_aspecto(ctx: Dictionary) -> void:
	for h in _panel_aspecto.get_children():
		h.queue_free()
	for fila: Array in [["ropa", "Chaqueta", PersonaRealista.ROPAS], ["pelo", "Pelo", PersonaRealista.PELOS],
			["piel", "Piel", PersonaRealista.PIELES]]:
		var clave := String(fila[0])
		var opciones: Array = (fila[2] as Dictionary).keys()
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		_panel_aspecto.add_child(h)
		var l := Label.new()
		l.text = String(fila[1])
		l.custom_minimum_size = Vector2(70, 0)
		l.add_theme_font_size_override("font_size", 12)
		l.add_theme_color_override("font_color", COL_SUAVE)
		h.add_child(l)
		var actual := String(_aspecto.get(clave, opciones[0]))
		for op: String in opciones:
			var b := Button.new()
			b.text = op
			b.toggle_mode = true
			b.button_pressed = op == actual
			b.add_theme_font_size_override("font_size", 11)
			b.pressed.connect(func() -> void: cambiar_aspecto(clave, op, ctx))
			h.add_child(b)

func _etiqueta_activa() -> RichTextLabel:
	return _lbl_prologo if _fase == "prologo" else _lbl_texto

func _completar_escritura() -> void:
	var lbl := _etiqueta_activa()
	if lbl != null:
		lbl.visible_characters = -1
	_escribiendo = false

func _terminar(completo: bool) -> void:
	terminado.emit(completo)
	queue_free()

func paso_actual() -> Dictionary:
	return _pasos[_i] if _i < _pasos.size() else {}

func _accion(clave: String) -> void:
	if _principal != null and _principal.has_method("tutorial_accion"):
		_principal.call("tutorial_accion", clave)

func _hacer_por_mi() -> void:
	var paso := paso_actual()
	if paso.has("mostrar"):
		_accion(String(paso["mostrar"]))

func _resumen_misiones() -> String:
	var lineas: Array[String] = []
	for k in _pasos.size():
		if _pasos[k].has("mision"):
			var ok := _cumplidas.has(k)
			lineas.append("[color=#%s]%s  %s[/color]" % [
				(COL_HECHO if ok else COL_SUAVE).to_html(false), "✔" if ok else "·", _pasos[k]["mision"]])
	return "[b]Tu primer día:[/b] %d de %d misiones.\n%s\n\nPuedes repetir esto cuando quieras en [b]AJUSTES → Interfaz[/b]." % [
		_cumplidas.size(), lineas.size(), "\n".join(lineas)]

# --- máquina de escribir -----------------------------------------------------

func _escribir(lbl: RichTextLabel, texto: String) -> void:
	lbl.text = texto
	lbl.visible_characters = 0
	_escribiendo = true

func _puede_dirigir() -> bool:
	if _principal == null or not ("mundo" in _principal):
		return false
	var m: Mundo = _principal.get("mundo")
	return m != null and m.roles != null and m.roles.puede_alinear()

func _hecho(paso: Dictionary) -> bool:
	if not paso.has("hecho") or _principal == null or not _principal.has_method("tutorial_hecho"):
		return false
	return bool(_principal.call("tutorial_hecho", String(paso["hecho"])))

func _pintar_mision() -> void:
	var paso := paso_actual()
	_caja_mision.visible = paso.has("mision")
	_btn_mostrar.visible = paso.has("mostrar") and not _cumplidas.has(_i)
	if not paso.has("mision"):
		return
	var misiones := 0
	var n := 0
	for k in _pasos.size():
		if _pasos[k].has("mision"):
			misiones += 1
			if k <= _i:
				n = misiones
	if _cumplidas.has(_i):
		_lbl_mision.text = Idiomas.t("✔  MISIÓN %d/%d · %s  —  ¡hecho!") % [n, misiones, paso["mision"]]
		_lbl_mision.add_theme_color_override("font_color", COL_HECHO)
	else:
		_lbl_mision.text = Idiomas.t("🎯  MISIÓN %d/%d · %s") % [n, misiones, paso["mision"]]
		_lbl_mision.add_theme_color_override("font_color", COL_ORO)

func _objetivo() -> Control:
	var paso := paso_actual()
	if _fase != "dialogo" or not paso.has("objetivo") or _principal == null or not _principal.has_method("tutorial_objetivo"):
		return null
	var c: Variant = _principal.call("tutorial_objetivo", String(paso["objetivo"]))
	if c is Control and is_instance_valid(c) and (c as Control).is_visible_in_tree():
		return c
	return null

func _poner_sombras(hueco: Rect2, pantalla: Vector2, todo: bool) -> void:
	if todo:
		_sombras[0].position = Vector2.ZERO
		_sombras[0].size = pantalla
		for k in range(1, 4):
			_sombras[k].size = Vector2.ZERO
		return
	var h := hueco
	_sombras[0].position = Vector2.ZERO
	_sombras[0].size = Vector2(pantalla.x, maxf(0.0, h.position.y))
	_sombras[1].position = Vector2(0, h.end.y)
	_sombras[1].size = Vector2(pantalla.x, maxf(0.0, pantalla.y - h.end.y))
	_sombras[2].position = Vector2(0, h.position.y)
	_sombras[2].size = Vector2(maxf(0.0, h.position.x), h.size.y)
	_sombras[3].position = Vector2(h.end.x, h.position.y)
	_sombras[3].size = Vector2(maxf(0.0, pantalla.x - h.end.x), h.size.y)

## Coloca el marco, las sombras y la tarjeta. Se recalcula cada cuadro: el
## control resaltado puede moverse (una fila que se reconstruye, la ventana que
## cambia de tamaño). Sin objetivo, la tarjeta va abajo al centro, como el
## subtítulo de una conversación.
func _colocar() -> void:
	## La tarjeta vuelve a su tamaño mínimo: si no, se queda con el alto del
	## texto más largo que haya mostrado y los pasos cortos flotan en un hueco.
	_tarjeta.reset_size()
	var pantalla := get_viewport_rect().size
	var obj := _objetivo()
	if obj == null:
		_marco.visible = false
		_poner_sombras(Rect2(pantalla * 0.5, Vector2.ZERO), pantalla, true)
		_tarjeta.position = Vector2((pantalla.x - _tarjeta.size.x) * 0.5, maxf(8.0, pantalla.y - _tarjeta.size.y - 28.0))
		return
	var r := obj.get_global_rect().grow(6.0)
	_marco.visible = true
	_marco.position = r.position
	_marco.size = r.size
	## El latido: el borde respira para que el ojo lo encuentre.
	_marco.modulate.a = 0.65 + 0.35 * sin(_t * 5.0)
	_poner_sombras(r, pantalla, false)
	## La tarjeta debajo del objetivo si cabe; si no, encima; si tampoco, al
	## lado. Siempre dentro de la pantalla.
	var ts := _tarjeta.size
	var pos := Vector2(r.position.x, r.end.y + 12.0)
	if pos.y + ts.y > pantalla.y - 8.0:
		pos.y = r.position.y - ts.y - 12.0
	if pos.y < 8.0:
		pos = Vector2(r.end.x + 12.0, r.position.y)
		if pos.x + ts.x > pantalla.x - 8.0:
			pos.x = r.position.x - ts.x - 12.0
	pos.x = clampf(pos.x, 8.0, maxf(8.0, pantalla.x - ts.x - 8.0))
	pos.y = clampf(pos.y, 8.0, maxf(8.0, pantalla.y - ts.y - 8.0))
	_tarjeta.position = pos

func _mostrar(i: int) -> void:
	if i >= _pasos.size():
		_terminar(true)
		return
	_fase = "dialogo"
	_i = clampi(i, 0, _pasos.size() - 1)
	var paso := _pasos[_i]
	var final := bool(paso.get("final", false))
	var texto := String(paso["texto"])
	if final:
		texto = "[i]«%s»[/i]\n\n%s" % [texto, _resumen_misiones()]
	_escribir(_lbl_texto, texto)
	_lbl_progreso.text = "" if final else "%d / %d" % [_i + 1, _pasos.size() - 1]
	_btn_atras.visible = _i > 0 and not final
	_btn_sig.text = Idiomas.t("¡A jugar!") if final else Idiomas.t("Siguiente ▸")
	_btn_extra.visible = final and _puede_dirigir()
	_hecho_al_entrar = _hecho(paso)
	_t_cumplida = -1.0
	_pintar_mision()
	_t = 0.0
	_colocar()

## "Siguiente": completa el texto si se está escribiendo; si no, avanza.
func pulsar_siguiente() -> void:
	if _escribiendo:
		_completar_escritura()
		return
	if bool(paso_actual().get("final", false)):
		_terminar(true)
		return
	_mostrar(_i + 1)

## LA TARJETA DEL MENTOR: retrato, nombre y cargo, lo que dice, y la misión.
func _construir_tarjeta(ctx: Dictionary) -> void:
	var c1 := Color(String(ctx["c1"]))
	_tarjeta = PanelContainer.new()
	_tarjeta.mouse_filter = Control.MOUSE_FILTER_STOP
	var e := StyleBoxFlat.new()
	e.bg_color = Color(COL_FONDO, 0.97)
	e.border_color = c1.lerp(COL_BORDE, 0.35)
	e.set_border_width_all(2)
	e.border_width_top = 4
	e.set_corner_radius_all(12)
	e.shadow_color = Color(0, 0, 0, 0.55)
	e.shadow_size = 14
	e.content_margin_left = 16; e.content_margin_right = 18
	e.content_margin_top = 14; e.content_margin_bottom = 14
	_tarjeta.add_theme_stylebox_override("panel", e)
	var ancho := minf(ANCHO_TARJETA, get_viewport_rect().size.x - 24.0)
	_tarjeta.custom_minimum_size = Vector2(ancho, 0)
	add_child(_tarjeta)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	_tarjeta.add_child(h)
	## EL RETRATO DEL MENTOR: una persona realista en 3D, viva (respira, cambia
	## el peso), con el aspecto que el jugador le haya elegido. Si el modelo no
	## estuviera, la cara dibujada de siempre.
	_marco_cara = PanelContainer.new()
	var em := StyleBoxFlat.new()
	_fondo_retrato = c1.darkened(0.45)
	em.bg_color = _fondo_retrato
	em.border_color = COL_ORO
	em.set_border_width_all(2)
	em.set_corner_radius_all(14)
	_marco_cara.add_theme_stylebox_override("panel", em)
	_marco_cara.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_marco_cara.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(_marco_cara)
	_pintar_retrato(ctx)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var cab := HBoxContainer.new()
	v.add_child(cab)
	var quien := VBoxContainer.new()
	quien.add_theme_constant_override("separation", 0)
	quien.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(quien)
	_lbl_nombre = Label.new()
	_lbl_nombre.text = String(_guion["mentor"]["nombre"])
	_lbl_nombre.add_theme_font_size_override("font_size", 17)
	_lbl_nombre.add_theme_color_override("font_color", COL_ORO)
	quien.add_child(_lbl_nombre)
	_lbl_cargo = Label.new()
	_lbl_cargo.text = String(_guion["mentor"]["cargo"])
	_lbl_cargo.add_theme_font_size_override("font_size", 12)
	_lbl_cargo.add_theme_color_override("font_color", COL_SUAVE)
	quien.add_child(_lbl_cargo)
	if PersonaRealista.disponible():
		var editar := Button.new()
		editar.text = "✎"
		editar.flat = true
		editar.tooltip_text = Idiomas.t("Cambiar el aspecto de %s") % _guion["mentor"]["nombre"]
		editar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		editar.pressed.connect(func() -> void: _panel_aspecto.visible = not _panel_aspecto.visible)
		cab.add_child(editar)
	_lbl_progreso = Label.new()
	_lbl_progreso.add_theme_font_size_override("font_size", 12)
	_lbl_progreso.add_theme_color_override("font_color", COL_SUAVE)
	_lbl_progreso.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	cab.add_child(_lbl_progreso)
	_panel_aspecto = VBoxContainer.new()
	_panel_aspecto.visible = false
	_panel_aspecto.add_theme_constant_override("separation", 4)
	v.add_child(_panel_aspecto)
	_pintar_panel_aspecto(ctx)
	_lbl_texto = RichTextLabel.new()
	_lbl_texto.bbcode_enabled = true
	_lbl_texto.fit_content = true
	_lbl_texto.scroll_active = false
	_lbl_texto.add_theme_font_size_override("normal_font_size", 15)
	_lbl_texto.add_theme_font_size_override("bold_font_size", 15)
	_lbl_texto.add_theme_font_size_override("italics_font_size", 15)
	_lbl_texto.add_theme_color_override("default_color", COL_TEXTO)
	_lbl_texto.add_theme_font_override("bold_font", _negrita())
	_lbl_texto.custom_minimum_size = Vector2(ancho - 150.0, 0)
	_lbl_texto.mouse_filter = Control.MOUSE_FILTER_STOP
	_lbl_texto.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and _escribiendo:
			_completar_escritura())
	v.add_child(_lbl_texto)
	## La misión del paso, como una tarea con su casilla.
	_caja_mision = PanelContainer.new()
	var ms := StyleBoxFlat.new()
	ms.bg_color = Color(COL_ORO, 0.10)
	ms.border_color = Color(COL_ORO, 0.55)
	ms.set_border_width_all(1)
	ms.set_corner_radius_all(6)
	ms.content_margin_left = 10; ms.content_margin_right = 10
	ms.content_margin_top = 6; ms.content_margin_bottom = 6
	_caja_mision.add_theme_stylebox_override("panel", ms)
	v.add_child(_caja_mision)
	_lbl_mision = Label.new()
	_lbl_mision.add_theme_font_size_override("font_size", 13)
	_lbl_mision.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caja_mision.add_child(_lbl_mision)
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 8)
	v.add_child(botones)
	var saltar := Button.new()
	saltar.text = Idiomas.t("Saltar")
	saltar.flat = true
	saltar.add_theme_color_override("font_color", COL_SUAVE)
	saltar.pressed.connect(func() -> void: _terminar(false))
	botones.add_child(saltar)
	var empuje := Control.new()
	empuje.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botones.add_child(empuje)
	_btn_mostrar = Button.new()
	_btn_mostrar.text = Idiomas.t("Muéstramelo")
	_btn_mostrar.pressed.connect(_hacer_por_mi)
	botones.add_child(_btn_mostrar)
	_btn_extra = Button.new()
	_btn_extra.text = Idiomas.t("Ir al partido ▸")
	_btn_extra.visible = false
	_btn_extra.pressed.connect(func() -> void:
		_accion("tab:Partido")
		_terminar(true))
	botones.add_child(_btn_extra)
	_btn_atras = Button.new()
	_btn_atras.text = "◂"
	_btn_atras.tooltip_text = Idiomas.t("Paso anterior")
	_btn_atras.pressed.connect(func() -> void: _mostrar(_i - 1))
	botones.add_child(_btn_atras)
	_btn_sig = Button.new()
	_btn_sig.custom_minimum_size = Vector2(110, 0)
	_btn_sig.pressed.connect(pulsar_siguiente)
	botones.add_child(_btn_sig)
	## Botones con el estilo de los diálogos (13-10-2026).
	for b: Button in [_btn_mostrar, _btn_extra, _btn_atras, _btn_sig]:
		CuadroDialogo.respuesta(b)

func _sonar(nombre: String) -> void:
	if nombre != "" and Sonido.NOMBRES.has(nombre):
		Sonido.toca(nombre)

## "Entrar": si la escena se está escribiendo la completa; si no, pasa al
## primer día con el mentor.
func pulsar_prologo() -> void:
	if _escribiendo:
		_completar_escritura()
		return
	if _fase != "prologo":
		return
	_fase = "dialogo"
	var tw := create_tween()
	tw.tween_property(_prologo, "modulate:a", 0.0, 0.45)
	tw.tween_callback(_prologo.queue_free)
	_tarjeta.visible = true
	_tarjeta.modulate.a = 0.0
	create_tween().tween_property(_tarjeta, "modulate:a", 1.0, 0.45)
	_sonar("abrir")
	_mostrar(0)
