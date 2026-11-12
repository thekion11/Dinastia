class_name CifrasClave
extends RefCounted
## LA BANDA DE CIFRAS CLAVE (12-11): arriba de una pantalla de gestión, de 2 a 4 fichas grandes con lo que hay que saber antes de leer el
## detalle (la caja, el resultado del año, la deuda…). Cada ficha: rótulo pequeño, cifra grande en su color y un filo del mismo color.
## Solo lee lo que le pasan: `fichas` = [[rótulo, cifra, color], …].

## `columnas` > 0: si hay más fichas que eso, van en rejilla de ese ancho (seis cifras en un teléfono tumbado = dos filas de tres).
static func banda(fichas: Array, suave: Color, columnas := 0) -> Container:
	## (12-11) En un teléfono de pie cuatro fichas en fila no caben (se cortaban el rótulo y la cifra): de a dos por fila.
	var h: Container
	var cols := 2 if EscalaMovil.es_vertical() else columnas
	if cols > 0 and fichas.size() > cols:
		var g := GridContainer.new()
		g.columns = cols
		g.add_theme_constant_override("h_separation", 10)
		g.add_theme_constant_override("v_separation", 10)
		h = g
	else:
		h = HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
	h.name = "CifrasClave"
	for f: Array in fichas:
		h.add_child(_ficha(String(f[0]), String(f[1]), f[2] as Color, suave))
	return h

static func _ficha(rotulo: String, cifra: String, color: Color, suave: Color) -> PanelContainer:
	if color.get_luminance() < 0.3:   ## un color de club oscuro (granate, azul marino) no se lee sobre el fondo del menú: se aclara
		color = color.lightened(0.45)
	var caja := PanelContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color, 0.07)
	sb.border_color = Color(color, 0.85)
	sb.border_width_left = 4
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 16
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	caja.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	caja.add_child(v)
	var r := Label.new()
	r.text = rotulo.to_upper()
	r.add_theme_font_size_override("font_size", 11)
	r.add_theme_color_override("font_color", suave)
	r.clip_text = true
	v.add_child(r)
	var c := Label.new()
	c.text = cifra
	c.add_theme_font_size_override("font_size", 26)
	c.add_theme_color_override("font_color", color)
	c.clip_text = true
	v.add_child(c)
	return caja
