class_name CapitulosSelector
extends RefCounted
## Menú «Capítulos»: la lista de temporadas con documental guardado (ver `CapitulosTemporadas`); tocar un año lo proyecta otra vez.
static func abrir(p: Principal) -> void:
	var anios := CapitulosTemporadas.anios(p.mundo)
	if anios.is_empty():
		Aviso.mostrar(p, "vida", "📚", Idiomas.t("Aún no hay capítulos"),
			Idiomas.t("El documental de cada temporada se guarda aquí al cerrarla."))
		return
	var capa := CanvasLayer.new()
	capa.layer = 55
	p.add_child(capa)
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.6)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(centro)
	var panel := PanelContainer.new()
	var est := Tema.caja(Tema.PANEL, Tema.RADIO_GRANDE, Tema.oro())
	est.set_border_width_all(2)
	est.content_margin_left = 22
	est.content_margin_right = 22
	est.content_margin_top = 18
	est.content_margin_bottom = 18
	est.shadow_color = Color(0, 0, 0, 0.5)
	est.shadow_size = 14
	panel.add_theme_stylebox_override("panel", est)
	centro.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var titulo := Tema.etiqueta(Tema.TAM_DESTACADO + 2, Tema.oro(), Idiomas.t("📚 Capítulos de cada temporada"))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(titulo)
	## Hasta 40 años guardados: la lista se desliza dentro de un alto máximo (60 % de la ventana) y no se sale de la pantalla.
	var desliza := ScrollContainer.new()
	desliza.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	desliza.custom_minimum_size = Vector2(360, minf(float(anios.size()) * 44.0, p.get_viewport_rect().size.y * 0.6))
	col.add_child(desliza)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 6)
	desliza.add_child(lista)
	for anio: int in anios:
		var a := anio
		var b := Button.new()
		b.text = "🎬 %s %d" % [Idiomas.t("Temporada"), a]
		b.custom_minimum_size = Vector2(0, 38)
		b.pressed.connect(func() -> void:
			var caps := CapitulosTemporadas.reconstruir(p.mundo, a)
			capa.queue_free()
			load("res://ui/componentes/documental_temporada.gd").abrir(p, caps, p._retrato))
		lista.add_child(b)
	var cerrar := Button.new()
	cerrar.text = Idiomas.t("Cerrar")
	cerrar.custom_minimum_size = Vector2(0, 38)
	cerrar.pressed.connect(capa.queue_free)
	col.add_child(cerrar)
