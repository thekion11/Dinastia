class_name PantallaAvanzarPiezas
extends RefCounted
## LAS PIEZAS DE LA PANTALLA «AVANZAR» (maqueta, 17-11-2026): la celda del calendario (franja con el número y el día de la semana, cuerpo con los símbolos
## circulares de los eventos y la ficha con el escudo de tu club), los símbolos, la marca de «visto» y las ayudas de teclas. Medidas de `.dia`, `.ico` y `.kbd` de la maqueta.

const ANCHO_CELDA := 161.0
const ALTO_CELDA := 100.0
const TILDE := '<path d="M5 12l5 5 9-10"/>'

static func _caja(bg: Color, borde := Color(0, 0, 0, 0), grosor := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = borde
	s.set_border_width_all(grosor)
	return s

## Una celda vacía; `pintar` le pone fecha, símbolos y estado.
static func celda(escudo: Texture2D) -> Dictionary:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(ANCHO_CELDA, ALTO_CELDA)
	panel.size = Vector2(ANCHO_CELDA, ALTO_CELDA)
	panel.pivot_offset = Vector2(ANCHO_CELDA, ALTO_CELDA) * 0.5
	var franja := Panel.new()
	franja.position = Vector2.ZERO
	franja.size = Vector2(ANCHO_CELDA, 22)
	panel.add_child(franja)
	var num := EstiloAvanzar.etiqueta("", 14, Color("cfd7ee"), true)
	num.position = Vector2(8, -1)
	num.size = Vector2(90, 22)
	panel.add_child(num)
	var sem := EstiloAvanzar.etiqueta("", 11, Color("8b9bb8"))
	sem.position = Vector2(ANCHO_CELDA - 62, 2)
	sem.size = Vector2(54, 18)
	sem.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(sem)
	var visto := TextureRect.new()
	visto.texture = EstiloAvanzar.icono("campana", Color.WHITE, 2)   ## se cambia en `pintar` por el tilde; aquí solo se reserva el sitio
	visto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visto.position = Vector2(ANCHO_CELDA - 82, 4)
	visto.size = Vector2(14, 14)
	visto.visible = false
	panel.add_child(visto)
	var simbolos := HBoxContainer.new()
	simbolos.position = Vector2(0, 22)
	simbolos.size = Vector2(ANCHO_CELDA, 76)
	simbolos.alignment = BoxContainer.ALIGNMENT_CENTER
	simbolos.add_theme_constant_override("separation", 6)
	simbolos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(simbolos)
	var ficha := TextureRect.new()
	ficha.texture = escudo
	ficha.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ficha.position = Vector2(ANCHO_CELDA - 30, 26)
	ficha.size = Vector2(24, 28)
	ficha.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ficha.visible = false
	panel.add_child(ficha)
	return {"panel": panel, "franja": franja, "num": num, "sem": sem, "visto": visto, "simbolos": simbolos, "ficha": ficha}

static func _tilde() -> Texture2D:
	var k := "tilde_verde"
	if not EstiloAvanzar._cache.has(k):
		var img := Image.new()
		img.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="28" height="28" fill="none" stroke="#3fb27f" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">%s</svg>' % TILDE)
		EstiloAvanzar._cache[k] = ImageTexture.create_from_image(img)
	return EstiloAvanzar._cache[k]

## Pinta una celda: `fecha` = diccionario de `Time` (day, month, weekday), `estado` = «pasado», «hoy» o «futuro», `eventos` = los del día (máx. 2 símbolos y «+N»).
static func pintar(c: Dictionary, fecha: Dictionary, estado: String, eventos: Array, acento: Color, primera: bool) -> void:
	var panel: Panel = c["panel"]
	var hoy := estado == "hoy"
	var borde := acento
	if hoy and not eventos.is_empty():
		borde = EstiloAvanzar.color_de(String(EstiloAvanzar.ficha(eventos[0])[1]))
	## Pizarra oscura translúcida como la maqueta; la del día actual, apenas más clara y con el borde del color del tipo (sin cambiar de tamaño).
	panel.add_theme_stylebox_override("panel", _caja(Color(0.63, 0.68, 0.84, 0.46) if hoy else Color(0.5, 0.56, 0.74, 0.34), borde if hoy else Color("0a1120"), 3 if hoy else 1))
	(c["franja"] as Panel).add_theme_stylebox_override("panel", _caja(borde if hoy else Color(0.039, 0.055, 0.118, 0.94)))
	var dia := int(fecha["day"])
	var txt := str(dia)
	if primera or dia == 1:
		txt += " " + Idiomas.t(String(Principal.MESES_LARGOS[int(fecha["month"]) - 1])).left(3)
	(c["num"] as Label).text = txt
	(c["num"] as Label).add_theme_color_override("font_color", Color.WHITE if hoy else Color("cfd7ee"))
	(c["sem"] as Label).text = Idiomas.t(String(Principal.DIAS_LARGOS[(int(fecha["weekday"]) + 6) % 7])).left(3).to_upper()
	(c["sem"] as Label).add_theme_color_override("font_color", Color(1, 1, 1, 0.8) if hoy else Color("8b9bb8"))
	var v: TextureRect = c["visto"]
	v.texture = _tilde()
	v.visible = estado == "pasado"
	panel.modulate.a = 0.55 if estado == "pasado" else 1.0
	panel.z_index = 2 if hoy else 0
	panel.scale = Vector2.ONE
	(c["ficha"] as TextureRect).visible = hoy
	var sim: HBoxContainer = c["simbolos"]
	for h in sim.get_children():
		h.free()
	for i in mini(eventos.size(), 2):
		sim.add_child(simbolo(eventos[i], 34, estado == "futuro"))
	if eventos.size() > 2:
		sim.add_child(EstiloAvanzar.etiqueta("+%d" % (eventos.size() - 2), 12, Color("52607d"), true))

## El círculo con el icono de trazo del tipo de evento (colores --t-* de la maqueta).
static func simbolo(ev: Dictionary, px: int, tenue := false) -> Control:
	var clave := String(EstiloAvanzar.ficha(ev)[1])
	var col := EstiloAvanzar.color_de(clave)
	var p := Panel.new()
	p.custom_minimum_size = Vector2(px, px)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var s := StyleBoxFlat.new()
	s.bg_color = Color(col, 0.55 if tenue else 1.0)
	s.set_corner_radius_all(px / 2)
	p.add_theme_stylebox_override("panel", s)
	var t := TextureRect.new()
	t.texture = EstiloAvanzar.icono(String(EstiloAvanzar.ICONO_DE.get(clave, "alerta")), Color.WHITE, 38, 2.0)
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.offset_left = px * 0.2; t.offset_right = -px * 0.2; t.offset_top = px * 0.2; t.offset_bottom = -px * 0.2
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(t)
	return p

## Una tecla de las ayudas («Espacio avanzar · N siguiente evento»).
static func tecla(texto: String) -> Label:
	var l := EstiloAvanzar.etiqueta(texto, 11, EstiloAvanzar.SUAVE)
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.border_color = EstiloAvanzar.SUAVE
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	s.content_margin_left = 5
	s.content_margin_right = 5
	l.add_theme_stylebox_override("normal", s)
	return l
