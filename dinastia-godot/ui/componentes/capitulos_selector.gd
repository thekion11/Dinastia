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
	centro.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.custom_minimum_size = Vector2(340, 0)
	panel.add_child(col)
	var titulo := Label.new()
	titulo.text = Idiomas.t("📚 Capítulos de cada temporada")
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(titulo)
	for anio: int in anios:
		var a := anio
		var b := Button.new()
		b.text = "🎬 %s %d" % [Idiomas.t("Temporada"), a]
		b.pressed.connect(func() -> void:
			var caps := CapitulosTemporadas.reconstruir(p.mundo, a)
			capa.queue_free()
			load("res://ui/componentes/documental_temporada.gd").abrir(p, caps, p._retrato))
		col.add_child(b)
	var cerrar := Button.new()
	cerrar.text = Idiomas.t("Cerrar")
	cerrar.pressed.connect(capa.queue_free)
	col.add_child(cerrar)
