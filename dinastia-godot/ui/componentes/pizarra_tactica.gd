class_name PizarraTactica
extends RefCounted
## LA PIZARRA TÁCTICA (25-9-2026, repaso estético con Soccer Manager delante).
## Antes eran textos sueltos sobre un verde plano ("DC 81 / Núñez"). Ahora es
## un campo con sus líneas y cada titular es una ficha: su cara, un anillo con
## la media, la pastilla del puesto en el color de su línea (portero, defensa,
## medio, delantero) y el apellido. Fuera de su puesto natural, la ficha lleva
## el borde en rojo -el error que más se comete y el que menos se ve en una
## lista-. Pulsar una ficha abre al jugador.
##
## Las posiciones salen de la tabla `FORMS` (porcentajes de campo), las mismas
## con las que el motor arma el once.

const ALTO := 380
const COL_POS := {"POR": Color("d9a400"), "DEF": Color("2f7fd0"), "MED": Color("2f9a5e"), "DEL": Color("e07b2a")}
## El rojo queda reservado para "fuera de su puesto": los delanteros van en
## naranja para que no se confundan.

static func pintar(raiz: Control, c: Club, ficha: Callable) -> void:
	var forms: Dictionary = Datos.tabla("FORMS")
	if not forms.has(c.tactica.formacion):
		return
	var slots: Array = (forms[c.tactica.formacion] as Dictionary)["s"]
	var once := c.once()
	var campo := CampoDibujado.new()
	campo.custom_minimum_size = Vector2(0, ALTO)
	campo.clip_contents = true
	raiz.add_child(campo)
	for i in slots.size():
		if i >= once.size():
			break
		var s: Array = slots[i]
		var j: Jugador = once[i]
		var natural := j.pos_e == String(s[0]) or j.pos_sec.has(String(s[0]))
		var f := _ficha_jugador(j, String(s[0]), natural, c, ficha)
		f.anchor_left = float(s[1]) / 100.0
		f.anchor_right = f.anchor_left
		## La tabla va de ~20 (área rival) a 94 (tu portería): se comprime para
		## que la ficha del portero no se salga por abajo.
		f.anchor_top = 0.11 + clampf(float(s[2]) / 100.0, 0.0, 1.0) * 0.76
		f.anchor_bottom = f.anchor_top
		f.offset_left = -38
		f.offset_right = 38
		f.offset_top = -38
		f.offset_bottom = 40
		campo.add_child(f)

static func _ficha_jugador(j: Jugador, puesto: String, natural: bool, c: Club, ficha: Callable) -> Control:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 1)
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	## La cara con el anillo de la media encima, en su esquina.
	var cara_caja := Control.new()
	cara_caja.custom_minimum_size = Vector2(76, 46)
	cara_caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(cara_caja)
	var fondo := Panel.new()
	var e := StyleBoxFlat.new()
	e.bg_color = Color(0, 0, 0, 0.35)
	e.set_corner_radius_all(23)
	e.set_border_width_all(2)
	e.border_color = Color(1, 1, 1, 0.25) if natural else Color("d0463c")
	fondo.add_theme_stylebox_override("panel", e)
	fondo.position = Vector2(15, 0)
	fondo.size = Vector2(46, 46)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cara_caja.add_child(fondo)
	var cara := TextureRect.new()
	cara.texture = Cara.textura(j, c.color1, c.color2, 42)
	cara.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cara.position = Vector2(17, 2)
	cara.size = Vector2(42, 42)
	cara.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cara_caja.add_child(cara)
	var nota := Anillo.crear(j.ovr, 99.0, Color("3fa06a") if j.ovr >= 75 else (Color("c9a227") if j.ovr >= 62 else Color("d0463c")), 26.0)
	nota.position = Vector2(50, -4)
	cara_caja.add_child(nota)
	## La pastilla del puesto, en el color de su línea.
	var pastilla := PanelContainer.new()
	var ep := StyleBoxFlat.new()
	ep.bg_color = COL_POS.get(Datos.grupo(puesto), Color("555555"))
	if not natural:
		ep.bg_color = Color("d0463c")
	ep.set_corner_radius_all(6)
	ep.content_margin_left = 6; ep.content_margin_right = 6
	pastilla.add_theme_stylebox_override("panel", ep)
	pastilla.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pastilla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(pastilla)
	var lp := Label.new()
	lp.text = puesto
	lp.add_theme_font_size_override("font_size", 10)
	lp.add_theme_color_override("font_color", Color.WHITE)
	pastilla.add_child(lp)
	var partes := j.nombre.split(" ")
	var nom := Label.new()
	nom.text = String(partes[partes.size() - 1])
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.add_theme_font_size_override("font_size", 11)
	nom.add_theme_color_override("font_color", Color("f2f5f3"))
	nom.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	nom.add_theme_constant_override("outline_size", 3)
	nom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(nom)
	## Pulsable entera: un botón transparente por encima.
	var b := Button.new()
	b.flat = true
	b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = "%s · %s · media %d%s" % [j.nombre, j.pos_e, j.ovr, "" if natural else " · FUERA DE SU PUESTO"]
	if ficha.is_valid():
		b.pressed.connect(func() -> void: ficha.call(j))
	var raiz := Control.new()
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.add_child(caja)
	raiz.add_child(b)
	return raiz

## El campo: césped a franjas y sus líneas (medio campo, círculo, áreas).
class CampoDibujado:
	extends Control
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color("16402a"))
		for k in 8:
			if k % 2 == 0:
				draw_rect(Rect2(0, size.y * k / 8.0, size.x, size.y / 8.0), Color(1, 1, 1, 0.03))
		var linea := Color(1, 1, 1, 0.28)
		var m := 10.0
		var campo := Rect2(m, m, size.x - m * 2, size.y - m * 2)
		draw_rect(campo, linea, false, 2.0)
		draw_line(Vector2(m, size.y * 0.5), Vector2(size.x - m, size.y * 0.5), linea, 2.0)
		draw_arc(size * 0.5, size.y * 0.1, 0, TAU, 48, linea, 2.0)
		var ancho_area := campo.size.x * 0.56
		var alto_area := campo.size.y * 0.15
		for arriba: bool in [true, false]:
			var y := m if arriba else size.y - m - alto_area
			draw_rect(Rect2((size.x - ancho_area) * 0.5, y, ancho_area, alto_area), linea, false, 2.0)
			var chica_a := campo.size.x * 0.26
			var chica_h := campo.size.y * 0.06
			var y2 := m if arriba else size.y - m - chica_h
			draw_rect(Rect2((size.x - chica_a) * 0.5, y2, chica_a, chica_h), linea, false, 2.0)
