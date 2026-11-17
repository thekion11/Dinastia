class_name EscaparatePie
extends RefCounted
## EL PIE DEL ESCAPARATE (17-11-2026, segunda ronda): a la izquierda las ayudas del APARATO que se usa (mando: R2 / A confirma y Cuadrado / B vuelve; teclado: Intro y Esc),
## en medio los botones de Avanzar / Jugar partido / Saltar partido / Partido jugado (los de `BotonesAvance`, que siguen siendo la ÚNICA forma de jugar el partido del día: se
## mudan aquí desde el menú de siempre y conservan su lógica), y a la derecha Mensajes (con su contador), Ayuda, el chip de objetivos (antes una caja flotante) y la hora.
## El buscador ya no está aquí: vive en «Base de datos» de la barra.

static func _boton(texto: String, al_pulsar: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", Tema.letra(13))
	b.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.pressed.connect(al_pulsar)
	return b

static func crear(p: Principal) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 52
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0, 0, 0, 0.55)
	st.border_color = Color(EscaparateBarra.color_de(p.mundo.mi_club()), 0.9)
	st.border_width_top = 2
	st.content_margin_left = 16
	st.content_margin_right = 16
	panel.add_theme_stylebox_override("panel", st)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	panel.add_child(fila)
	var ayudas := HBoxContainer.new()
	ayudas.add_theme_constant_override("separation", 14)
	if Mando.hay_mando():
		ayudas.add_child(PieMando._chip("R2 / A", Idiomas.t("Confirmar")))
		ayudas.add_child(PieMando._chip("Cuadrado / B", Idiomas.t("Atrás")))
	elif not DisplayServer.is_touchscreen_available():
		ayudas.add_child(PieMando._chip(Idiomas.t("Intro"), Idiomas.t("Confirmar")))
		ayudas.add_child(PieMando._chip(Idiomas.t("Esc"), Idiomas.t("Atrás")))
	fila.add_child(ayudas)
	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hueco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(hueco)
	## Avanzar / Jugar / Saltar / Partido jugado: los mismos botones, ahora aquí
	if p._botones != null:
		if p._botones.get_parent() != null:
			p._botones.get_parent().remove_child(p._botones)
		p._botones.alignment = BoxContainer.ALIGNMENT_END
		p._botones.size_flags_horizontal = Control.SIZE_SHRINK_END
		if p._buscador != null and p._buscador.get_parent() == p._botones:
			p._botones.remove_child(p._buscador)   ## el buscador vive en «Base de datos»
		fila.add_child(p._botones)
		_botones_grandes(p)
	var sin_leer := 0
	var bandeja: Variant = p.get("_bandeja")
	if bandeja is Array:
		for x: Dictionary in bandeja:
			if not bool(x.get("leida", false)):
				sin_leer += 1
	sin_leer += int(InformeSemana.resumen(p)["graves"])   ## (17-11) los avisos urgentes del informe de la semana (contratos, puntos sin gastar…) cuentan en Mensajes
	var msg := _boton("✉ " + Idiomas.t("Mensajes") + ("  (%d)" % sin_leer if sin_leer > 0 else ""), func() -> void: TableroInicio.abrir(p, "Correo"))
	if sin_leer > 0:
		msg.add_theme_color_override("font_color", Tema.oro())
	fila.add_child(msg)
	fila.add_child(_boton("? " + Idiomas.t("Ayuda"), func() -> void: TableroInicio.abrir(p, "Glosario")))
	for po in p.find_children("*", "PanelObjetivos", true, false):   ## la caja flotante de objetivos pasa a un chip del pie
		var obj := po as PanelObjetivos
		var pend := int(obj.get("_pendientes"))
		if pend > 0:
			fila.add_child(_boton("🎯 %d" % pend, func() -> void:
				obj.visible = true
				obj._plegado = false
				obj._aplicar_plegado()
				p.move_child(obj, p.get_child_count() - 1)))
		break
	var h := Time.get_time_dict_from_system()
	var reloj := Label.new()
	reloj.text = "%02d:%02d" % [int(h["hour"]), int(h["minute"])]
	reloj.add_theme_font_size_override("font_size", Tema.letra(13))
	fila.add_child(reloj)
	return panel

## Avanzar / Jugar / Saltar / Partido jugado como botones de la maqueta (rojo el principal).
static func _botones_grandes(p: Principal) -> void:
	for clave: String in ["b_avanzar", "b_jugar", "b_saltar", "b_temporada", "b_jugado"]:
		var b: Variant = p._guia.nodos.get(clave)
		if not is_instance_valid(b):
			continue
		var bt := b as Button
		bt.custom_minimum_size = Vector2(200, 40)
		bt.size_flags_horizontal = Control.SIZE_SHRINK_END
		bt.add_theme_font_size_override("font_size", Tema.letra(18))
		var rojo := clave in ["b_avanzar", "b_jugar"]
		var n := StyleBoxFlat.new()
		n.bg_color = Color("c8102e") if rojo else Color("243656")
		n.content_margin_left = 18; n.content_margin_right = 18
		var hv := n.duplicate() as StyleBoxFlat
		hv.bg_color = n.bg_color.lightened(0.14)
		for estado: String in ["normal", "pressed"]:
			bt.add_theme_stylebox_override(estado, n)
		for estado: String in ["hover", "focus", "hover_pressed"]:
			bt.add_theme_stylebox_override(estado, hv)
