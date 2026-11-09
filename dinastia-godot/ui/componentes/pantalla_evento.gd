class_name PantallaEvento
extends RefCounted
## EL MARCO DE LOS EVENTOS A PANTALLA COMPLETA (9-11, regla del dueño: los eventos —aviso del partido de despedida, homenaje…— ocupan toda la pantalla).
## Pone fondo (verde profundo con brillo central y viñeta), filetes dorados arriba y abajo, cabecera (icono + título + subtítulo), un CUERPO centrado y un PIE de
## botones. Se monta dentro de una CanvasLayer; quien lo usa solo rellena `cuerpo` y `pie`. Todo con `Tema`, así que sigue la paleta y la escala de texto.

## Devuelve {"cuerpo": VBoxContainer, "pie": HBoxContainer}.
static func montar(capa: CanvasLayer, icono: String, titulo: String, subtitulo: String = "") -> Dictionary:
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_STOP   ## bloquea lo de debajo: es un evento, no un diálogo
	capa.add_child(raiz)
	var fondo := ColorRect.new()
	fondo.color = Tema.FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(fondo)
	raiz.add_child(_radial(Color("2a5a3d"), Color(0.05, 0.09, 0.07, 0.0), Vector2(0.5, 0.42), 0.9))   ## brillo verde detrás del título
	raiz.add_child(_radial(Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.62), Vector2(0.5, 0.5), 0.85))   ## viñeta
	for arriba: bool in [true, false]:
		var filete := ColorRect.new()
		filete.color = Color(Tema.oro(), 0.85)
		filete.set_anchors_preset(Control.PRESET_TOP_WIDE if arriba else Control.PRESET_BOTTOM_WIDE)
		filete.custom_minimum_size = Vector2(0, 4)
		if arriba:
			filete.offset_bottom = 4
		else:
			filete.offset_top = -4
		filete.mouse_filter = Control.MOUSE_FILTER_IGNORE
		raiz.add_child(filete)
	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado: String in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, 72)
	margen.add_theme_constant_override("margin_top", 44)
	margen.add_theme_constant_override("margin_bottom", 40)
	raiz.add_child(margen)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	margen.add_child(col)
	var cab := Tema.etiqueta(Tema.TAM_TITULO + 24, Tema.oro(), "%s  %s" % [icono, titulo])
	cab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cab.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	cab.add_theme_constant_override("shadow_offset_y", 3)
	col.add_child(cab)
	if subtitulo != "":
		var sub := Tema.etiqueta(Tema.TAM_DESTACADO + 2, Tema.SUAVE, subtitulo)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(sub)
	var linea := ColorRect.new()
	linea.color = Color(Tema.oro(), 0.35)
	linea.custom_minimum_size = Vector2(0, 2)
	col.add_child(linea)
	var centro := CenterContainer.new()
	centro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(centro)
	var cuerpo := VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 18)
	centro.add_child(cuerpo)
	var pie := HBoxContainer.new()
	pie.alignment = BoxContainer.ALIGNMENT_CENTER
	pie.add_theme_constant_override("separation", 16)
	col.add_child(pie)
	raiz.modulate.a = 0.0   ## entra con un fundido corto
	raiz.create_tween().tween_property(raiz, "modulate:a", 1.0, 0.35)
	return {"cuerpo": cuerpo, "pie": pie}

## Un botón grande de pie de evento. `principal` lo resalta en dorado.
static func boton(texto: String, principal: bool = false) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(230, 54)
	b.add_theme_font_size_override("font_size", Tema.letra(18))
	if not principal:
		var base := Tema.caja(Tema.TARJETA, Tema.RADIO, Color(1, 1, 1, 0.28))
		var sobre := base.duplicate() as StyleBoxFlat
		sobre.bg_color = Color("22312a")
		b.add_theme_stylebox_override("normal", base)
		b.add_theme_stylebox_override("hover", sobre)
		b.add_theme_stylebox_override("focus", sobre)
		b.add_theme_stylebox_override("pressed", sobre)
	if principal:
		var normal := Tema.caja(Color("2b5a3c"), Tema.RADIO, Tema.oro())
		normal.set_border_width_all(2)
		var encima := normal.duplicate() as StyleBoxFlat
		encima.bg_color = Color("37724b")
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", encima)
		b.add_theme_stylebox_override("focus", encima)
		b.add_theme_stylebox_override("pressed", encima)
	return b

static func _radial(centro: Color, borde: Color, punto: Vector2, radio: float) -> TextureRect:
	var g := Gradient.new()
	g.colors = PackedColorArray([centro, borde])
	g.offsets = PackedFloat32Array([0.0, 1.0])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = punto
	t.fill_to = punto + Vector2(radio * 0.5, radio * 0.5)
	t.width = 512
	t.height = 288
	var r := TextureRect.new()
	r.texture = t
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
