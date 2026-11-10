class_name TarjetaPortada
extends RefCounted
## LA TARJETA DE LA PORTADA de un menú del riel (icono, título, descripción y dato). Sale de `PantallaMenu` para que ese archivo no pase de 450 líneas.

static func crear(pm: PantallaMenu, sub: Dictionary, i: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(pm._ancho_tarjeta, pm._alto_tarjeta)
	b.clip_contents = true
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0, 0, 0, 0.5)
	st.border_color = Color(1, 1, 1, 0.16)   ## borde de 1 px ~10-15 % más claro que el fondo de la tarjeta
	st.set_border_width_all(1)
	st.set_corner_radius_all(16)
	st.shadow_color = Color(0, 0, 0, 0.45); st.shadow_size = 14; st.shadow_offset = Vector2(0, 6)   ## (10-11) sombra más larga hacia abajo
	var enc := st.duplicate() as StyleBoxFlat
	enc.bg_color = Color(pm._color(2), 0.22)
	enc.border_color = pm._color(2).lightened(0.2)
	enc.shadow_offset = Vector2(0, 10); enc.shadow_size = 20   ## al pasar por encima se «levanta»
	var barra := ColorRect.new(); barra.color = Color(pm._color(2), 0.7); barra.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)   ## el filo de color (antes un borde inferior de 4 px)
	barra.offset_left = 14; barra.offset_right = -14; barra.offset_top = -4; barra.offset_bottom = -1; barra.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(barra)
	ProfundidadUI.brillo(b)   ## (10-11, estética) brillo arriba y filo de luz
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", enc)
	b.add_theme_stylebox_override("focus", enc)
	b.add_theme_stylebox_override("pressed", enc)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 18; v.offset_right = -18; v.offset_top = 14; v.offset_bottom = -12
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var fila := HBoxContainer.new()
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(fila)
	var ic := IconosUI.control(String(sub.get("icono", "•")), 38)   ## (10-11) emoji o icono dibujado (Ajustes → Pantalla)
	fila.add_child(ic)
	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hueco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(hueco)
	if sub.has("accion"):
		var tag := Label.new()
		tag.text = Idiomas.t("▶ ABRIR")
		tag.add_theme_font_size_override("font_size", 11)
		tag.add_theme_color_override("font_color", pm._color(2).lightened(0.3))
		fila.add_child(tag)
	var t := Label.new()
	t.text = String(sub["label"])
	t.add_theme_font_size_override("font_size", 20)
	t.add_theme_color_override("font_color", Color.WHITE)
	v.add_child(t)
	var d := Label.new()
	d.text = String(sub.get("desc", ""))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.add_theme_font_size_override("font_size", 13)
	d.add_theme_color_override("font_color", Color(1, 1, 1, 0.78))
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(d)
	var dato := MenuLateral.dato(pm._p, sub)
	if dato != "":
		var dl := Label.new()
		dl.text = dato
		dl.add_theme_font_size_override("font_size", 14)
		dl.add_theme_color_override("font_color", pm._color(2).lightened(0.25))
		v.add_child(dl)
	for n in v.find_children("*", "Control", true, false):
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	## Crece un poco al pasar por encima.
	b.mouse_entered.connect(func() -> void:
		b.pivot_offset = b.size / 2.0
		b.create_tween().tween_property(b, "scale", Vector2(1.03, 1.03), 0.12))
	b.mouse_exited.connect(func() -> void: b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.12))
	b.pressed.connect(pm.elegir.bind(i))
	return b
