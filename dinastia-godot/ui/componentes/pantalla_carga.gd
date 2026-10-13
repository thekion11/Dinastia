class_name PantallaCarga
extends ColorRect
## PANTALLA DE CARGA CON CONSEJOS (informe de diseño, 13-10-2026: «el salto a la
## ciudad no debe congelar el juego sin explicación»). Construir la ciudad o el
## estadio tarda varios segundos y, mientras, la pantalla parecía colgada. Esto
## se pone ENCIMA, se deja pintar dos fotogramas y recién entonces se empieza a
## construir; al acabar se quita con un fundido.
##
## Pulido (13-10-2026): fondo en degradado con los colores del club, su escudo
## grande y tenue detrás, tres puntos que laten y el consejo en una tarjeta.

## El club para teñir la pantalla (lo fija quien la abre, si lo sabe).
static var club: Club = null

var _puntos: Array[ColorRect] = []
var _t := 0.0

static func mostrar(padre: Node, mensaje: String) -> PantallaCarga:
	var n := PantallaCarga.new()
	var c1 := Color(club.color1) if club != null else Color(0.12, 0.3, 0.2)
	n.color = Color(0.03, 0.04, 0.04, 1.0)
	n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	n.z_index = 200
	## Degradado: el color del club, muy oscuro, sube desde abajo.
	var fondo := TextureRect.new()
	var g := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, Color(0.03, 0.04, 0.04))
	## Si el color del club es casi negro, el segundo color (si no, un verde).
	var tono := c1 if c1.get_luminance() > 0.12 else (Color(club.color2) if club != null and Color(club.color2).get_luminance() > 0.12 else Color(0.2, 0.45, 0.3))
	gr.set_color(1, tono.darkened(0.7))
	g.gradient = gr
	g.fill_from = Vector2(0.5, 0.0)
	g.fill_to = Vector2(0.5, 1.0)
	fondo.texture = g
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_SCALE
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.add_child(fondo)
	## El escudo, grande y tenue, como marca de agua.
	if club != null:
		var esc := TextureRect.new()
		esc.texture = Escudo.textura(club, 256)
		esc.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		esc.offset_left = -170
		esc.offset_right = 170
		esc.offset_top = -230
		esc.offset_bottom = 110
		esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		esc.modulate = Color(1, 1, 1, 0.07)
		esc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		n.add_child(esc)
	var caja := VBoxContainer.new()
	caja.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	caja.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caja.grow_vertical = Control.GROW_DIRECTION_BOTH
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_theme_constant_override("separation", 18)
	n.add_child(caja)
	var t := Label.new()
	t.text = mensaje
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", Color(0.92, 0.95, 0.92))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(t)
	## Tres puntos que laten (el juego no está colgado).
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 10)
	caja.add_child(fila)
	for i in 3:
		var p := ColorRect.new()
		p.custom_minimum_size = Vector2(9, 9)
		p.color = Color(1.0, 0.82, 0.35)
		fila.add_child(p)
		n._puntos.append(p)
	## El consejo en una tarjeta, con el mismo estilo que los diálogos.
	var tarjeta := PanelContainer.new()
	tarjeta.add_theme_stylebox_override("panel", CuadroDialogo.estilo_panel())
	tarjeta.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var v := VBoxContainer.new()
	tarjeta.add_child(v)
	v.add_child(CuadroDialogo.placa(Idiomas.t("Consejo")))
	var c := Label.new()
	var txt := consejo().trim_prefix(Idiomas.t("Consejo: "))
	c.text = txt.substr(0, 1).to_upper() + txt.substr(1)
	c.add_theme_font_size_override("font_size", 17)
	c.add_theme_color_override("font_color", Color(0.86, 0.88, 0.86))
	c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c.custom_minimum_size = Vector2(520, 0)
	v.add_child(c)
	caja.add_child(tarjeta)
	padre.add_child(n)
	return n

func _process(delta: float) -> void:
	_t += delta
	for i in _puntos.size():
		_puntos[i].modulate.a = 0.35 + 0.65 * maxf(0.0, sin(_t * 5.0 - float(i) * 0.9))

static func consejo() -> String:
	var l := [
		Idiomas.t("Consejo: los días de partido el estadio se llena más si el equipo viene ganando."),
		Idiomas.t("Consejo: el Centro médico acelera la recuperación entre partidos."),
		Idiomas.t("Consejo: pulsa V al pasear para cambiar a primera persona."),
		Idiomas.t("Consejo: entra en las casas y los bares; la gente de la ciudad tiene cosas que contarte."),
		Idiomas.t("Consejo: la Academia juvenil mejora el potencial de los canteranos."),
		Idiomas.t("Consejo: de noche las ventanas se encienden y las farolas alumbran la calle."),
	]
	return String(l[randi() % l.size()])

## Quita la pantalla con un fundido corto.
func cerrar() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)
