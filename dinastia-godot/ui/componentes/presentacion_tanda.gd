class_name PresentacionTanda
extends PanelContainer
## LA PRESENTACIÓN DE LA TANDA (semana 4 del plan, «Partido III: espectáculo», 27-10-2026): mientras los
## jugadores van al círculo central, la tele enseña quién tira y en qué orden, los cinco de cada equipo, con el
## escudo y el nombre del club arriba. Se va sola a los `DURA` segundos (antes de que se tire el primero).

const DURA := 3.6

## `orden_*`: los nombres de los cinco primeros lanzadores de cada equipo, en orden.
static func crear(padre: Control, local: Club, visita: Club, orden_local: Array, orden_visita: Array) -> PresentacionTanda:
	var p := PresentacionTanda.new()
	p.add_theme_stylebox_override("panel", Tema.caja(Color(0.03, 0.05, 0.12, 0.9), Tema.RADIO_GRANDE, Color(1, 1, 1, 0.18)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var t := Tema.etiqueta(14, Tema.ORO, Idiomas.t("LOS LANZADORES"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 28)
	v.add_child(h)
	h.add_child(_columna(local, orden_local))
	h.add_child(_columna(visita, orden_visita))
	padre.add_child(p)
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	Animar.aparecer(p, 0.25, 0.3)
	var tw := p.create_tween()
	tw.tween_interval(DURA)
	tw.tween_property(p, "modulate:a", 0.0, 0.35)
	tw.tween_callback(p.queue_free)
	return p

static func _columna(club: Club, nombres: Array) -> VBoxContainer:
	var c := VBoxContainer.new()
	c.add_theme_constant_override("separation", 3)
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 8)
	var esc := TextureRect.new()
	esc.texture = Escudo.textura(club, 28)
	esc.custom_minimum_size = Vector2(28, 28)
	esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cab.add_child(esc)
	cab.add_child(Tema.etiqueta(16, Tema.TEXTO, Nombres.visible(club.nombre)))
	c.add_child(cab)
	for i in mini(5, nombres.size()):
		c.add_child(Tema.etiqueta(14, Color(1, 1, 1, 0.85), "%d.  %s" % [i + 1, String(nombres[i])]))
	return c
