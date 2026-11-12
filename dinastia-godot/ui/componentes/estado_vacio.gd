class_name EstadoVacio
extends RefCounted
## EL ESTADO VACÍO DE UNA PANTALLA DEL MENÚ (12-11-2026). Al partir las pestañas en pantallas completas, las que todavía no tienen datos
## (rivales o goleadores en una partida nueva) eran una línea gris arriba y el resto del panel en negro. Esto pone, centrado, un icono
## grande, qué pasa y qué lo llenará. Es puro: recibe los colores ya resueltos y no conoce `Principal`. Los textos llegan ya traducidos.

static func crear(icono: String, titulo: String, pista: String, col_texto: Color, col_suave: Color, alto := 260.0) -> Control:
	var v := VBoxContainer.new()
	v.name = "EstadoVacio"
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.custom_minimum_size = Vector2(0, alto)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	var ic := IconosUI.control(icono, 56)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ic.modulate = Color(1, 1, 1, 0.55)
	v.add_child(ic)
	var t := Label.new()
	t.text = titulo
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 16)
	t.add_theme_color_override("font_color", col_texto)
	v.add_child(t)
	var p := Label.new()
	p.text = pista
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.custom_minimum_size = Vector2(240, 0)
	p.add_theme_font_size_override("font_size", 12)
	p.add_theme_color_override("font_color", col_suave)
	v.add_child(p)
	return v
