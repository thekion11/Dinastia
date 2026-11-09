class_name CamisetasRetiradas
extends RefCounted
## LAS CAMISETAS RETIRADAS EN LA HISTORIA DEL CLUB (9-11): una tarjeta por dorsal retirado en el partido de despedida (`Prensa.dorsales_retirados`),
## con el número grande en dorado, el nombre y el año. null si todavía no hay ninguna.
static func crear(m: Mundo) -> Control:
	if m == null or m.prensa == null or m.prensa.dorsales_retirados.is_empty():
		return null
	var caja := VBoxContainer.new()
	var t := Label.new()
	t.text = "👕 " + Idiomas.t("CAMISETAS RETIRADAS")
	t.add_theme_font_size_override("font_size", 12)
	t.add_theme_color_override("font_color", Tema.ORO)
	caja.add_child(t)
	var flujo := HFlowContainer.new()
	flujo.add_theme_constant_override("h_separation", 8)
	flujo.add_theme_constant_override("v_separation", 8)
	caja.add_child(flujo)
	for e: Dictionary in m.prensa.dorsales_retirados:
		var tarjeta := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Tema.TARJETA
		sb.border_color = Color(Tema.ORO, 0.6)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(6)
		sb.set_content_margin_all(8)
		tarjeta.add_theme_stylebox_override("panel", sb)
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		tarjeta.add_child(col)
		var n := Label.new()
		n.text = "#%d" % int(e.get("dorsal", 0))
		n.add_theme_font_size_override("font_size", 28)
		n.add_theme_color_override("font_color", Tema.ORO)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(n)
		var d := Label.new()
		d.text = "%s\n%d" % [String(e.get("nombre", "")), int(e.get("anio", 0))]
		d.add_theme_font_size_override("font_size", 11)
		d.add_theme_color_override("font_color", Tema.SUAVE)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(d)
		flujo.add_child(tarjeta)
	return caja
