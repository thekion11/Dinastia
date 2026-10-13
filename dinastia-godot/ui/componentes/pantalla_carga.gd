class_name PantallaCarga
extends ColorRect
## PANTALLA DE CARGA CON CONSEJOS (informe de diseño, 13-10-2026: «el salto a la
## ciudad no debe congelar el juego sin explicación»). Construir la ciudad o el
## estadio tarda varios segundos y, mientras, la pantalla parecía colgada. Esto
## se pone ENCIMA, se deja pintar dos fotogramas y recién entonces se empieza a
## construir; al acabar se quita con un fundido.
static func mostrar(padre: Node, mensaje: String) -> PantallaCarga:
	var n := PantallaCarga.new()
	n.color = Color(0.04, 0.06, 0.05, 1.0)
	n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	n.z_index = 200
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
	t.add_theme_color_override("font_color", Color(0.85, 0.95, 0.88))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(t)
	var c := Label.new()
	c.text = consejo()
	c.add_theme_font_size_override("font_size", 16)
	c.add_theme_color_override("font_color", Color(0.6, 0.7, 0.64))
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c.custom_minimum_size = Vector2(560, 0)
	caja.add_child(c)
	padre.add_child(n)
	return n

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
