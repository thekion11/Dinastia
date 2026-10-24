class_name RecorridoClub
extends "res://visor/recorrido_club_p1.gd"
## [Capa 2/2 de `recorrido_club.gd`] sala_decorable, interiores, panel_decorar

## ¿Es una sala del edificio que se puede decorar?
static func sala_decorable(nombre: String) -> bool:
	for f: Array in EdificioClub.PLANTAS:
		for sala: Array in f[2]:
			if String(sala[0]) == nombre:
				return true
	return false

## Las salas del club que decoras: las de la partida o, sin partida, unas
## de usar y tirar (vista previa).
static func interiores() -> InterioresClub:
	var it: Variant = EdificioClub.ctx.get("interiores")
	if it is InterioresClub:
		return it
	var nuevo := InterioresClub.new()
	EdificioClub.ctx["interiores"] = nuevo
	return nuevo

## EL PANEL DE DECORAR (fase 5): paredes, suelo, objetos y tus fotos. Cada
## cambio rehace el edificio al momento (`EdificioClub.reconstruir`).
static func panel_decorar(capa: CanvasLayer, arbol: SceneTree, sala: String) -> PanelContainer:
	var it := interiores()
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	panel.offset_left = -430
	panel.offset_right = -16
	panel.offset_top = -280
	panel.offset_bottom = 280
	panel.add_theme_stylebox_override("panel", CuadroDialogo.estilo_panel())
	var scroll := ScrollContainer.new()
	panel.add_child(scroll)
	var caja := VBoxContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.add_theme_constant_override("separation", 6)
	scroll.add_child(caja)
	var rehacer := func() -> void:
		var e := arbol.get_first_node_in_group("edificio_club") as Node3D
		if e != null:
			EdificioClub.reconstruir(e)
	var t := Label.new()
	t.text = "🎨 " + Idiomas.t("Decorar: %s") % Idiomas.t(sala)
	t.add_theme_font_size_override("font_size", 19)
	caja.add_child(t)
	for que: String in ["pared", "suelo"]:
		var l := Label.new()
		l.text = Idiomas.t("Color de las paredes") if que == "pared" else Idiomas.t("Color del suelo")
		caja.add_child(l)
		var fila := HFlowContainer.new()
		caja.add_child(fila)
		for hex: String in InterioresClub.COLORES:
			var b := Button.new()
			b.custom_minimum_size = Vector2(34, 30)
			b.text = "↺" if hex == "" else "■"
			if hex != "":
				b.add_theme_color_override("font_color", Color(hex))
				b.add_theme_font_size_override("font_size", 22)
			b.tooltip_text = Idiomas.t("Como venía") if hex == "" else hex
			b.pressed.connect(func() -> void:
				it.pintar(sala, que, hex)
				rehacer.call())
			fila.add_child(b)
	var ld := Label.new()
	ld.text = Idiomas.t("Añadir decoración")
	caja.add_child(ld)
	var objs := HFlowContainer.new()
	caja.add_child(objs)
	for clave: String in InterioresClub.CATALOGO:
		var f: Array = InterioresClub.CATALOGO[clave]
		if bool(f[2]) and sala != "Oficina del DT":
			continue
		var b2 := Button.new()
		b2.text = "%s %s" % [String(f[1]), Idiomas.t(String(f[0]))]
		b2.pressed.connect(func() -> void:
			if it.poner(sala, clave):
				rehacer.call())
		objs.add_child(b2)
	var bq := Button.new()
	bq.text = "↩ " + Idiomas.t("Quitar el último objeto")
	bq.pressed.connect(func() -> void:
		it.quitar_ultima(sala)
		rehacer.call())
	caja.add_child(bq)
	var lf := Label.new()
	lf.text = Idiomas.t("Colgar una foto (modo foto)")
	caja.add_child(lf)
	var fotos := ModoFoto.fotos()
	if fotos.is_empty():
		var nf := Label.new()
		nf.text = Idiomas.t("Aún no tienes fotos: sácalas con el 📸 modo foto.")
		nf.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caja.add_child(nf)
	for ruta: String in fotos.slice(0, 6):
		var bf := Button.new()
		bf.text = "🖼 " + ruta.get_file().trim_prefix("foto_").trim_suffix(".png")
		bf.alignment = HORIZONTAL_ALIGNMENT_LEFT
		bf.pressed.connect(func() -> void:
			it.colgar(sala, ruta)
			rehacer.call())
		caja.add_child(bf)
	var bd := Button.new()
	bd.text = "↩ " + Idiomas.t("Descolgar la última foto")
	bd.pressed.connect(func() -> void:
		it.descolgar(sala)
		rehacer.call())
	caja.add_child(bd)
	var cerrar := Button.new()
	cerrar.text = Idiomas.t("Cerrar")
	cerrar.pressed.connect(func() -> void: panel.queue_free())
	caja.add_child(cerrar)
	capa.add_child(panel)
	return panel
