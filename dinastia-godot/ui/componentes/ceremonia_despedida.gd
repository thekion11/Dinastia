class_name CeremoniaDespedida
extends CanvasLayer
## LA CEREMONIA DEL HOMENAJE (9-11): tras el partido de despedida, una tarjeta de gala con los HOMENAJEADOS de tu club (con su camiseta retirada) y, si no hay,
## con las tres mayores Leyendas de la noche. Se cierra con «Continuar». Todo con retratos del juego (`Principal._retrato`, caras ficticias).
signal terminado

## `homenajeados`: [{jugador, dorsal}] de tu club; `leyendas`: el club de las Leyendas (para completar con sus mejores).
static func mostrar(pr: Principal, homenajeados: Array, leyendas: Club) -> CeremoniaDespedida:
	var c := CeremoniaDespedida.new()
	c.layer = 59
	pr.add_child(c)
	c._montar(pr, homenajeados, leyendas)
	return c

func _montar(pr: Principal, homenajeados: Array, leyendas: Club) -> void:
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.78)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Tema.PANEL
	sb.border_color = Tema.ORO
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(22)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 16
	panel.add_theme_stylebox_override("panel", sb)
	centro.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.custom_minimum_size = Vector2(520, 0)
	panel.add_child(col)
	var t := Label.new()
	t.text = "🎖️ " + Idiomas.t("Homenaje")
	t.add_theme_font_size_override("font_size", 26)
	t.add_theme_color_override("font_color", Tema.ORO)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	var filas: Array = []
	for h: Dictionary in homenajeados:
		filas.append({"j": h["jugador"], "dorsal": int(h["dorsal"]), "propio": true})
	if filas.is_empty():
		var top: Array = leyendas.plantilla.duplicate()
		top.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
		for j: Jugador in top.slice(0, 3):
			filas.append({"j": j, "dorsal": 0, "propio": false})
	for f: Dictionary in filas:
		col.add_child(_fila(pr, f))
	var seguir := Button.new()
	seguir.text = Idiomas.t("Continuar")
	seguir.pressed.connect(func() -> void:
		terminado.emit()
		queue_free())
	col.add_child(seguir)

func _fila(pr: Principal, f: Dictionary) -> Control:
	var j: Jugador = f["j"]
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	var retrato := pr._retrato(j, 72)
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fila.add_child(retrato)
	var datos := VBoxContainer.new()
	fila.add_child(datos)
	var n := Label.new()
	n.text = j.nombre
	n.add_theme_font_size_override("font_size", 20)
	n.add_theme_color_override("font_color", Tema.ORO)
	datos.add_child(n)
	var d := Label.new()
	d.add_theme_color_override("font_color", Tema.SUAVE)
	d.text = "%d %s · %s %d · %s" % [j.edad, Idiomas.t("años"), Idiomas.t("Nota"), j.ovr, Idiomas.t(String(j.pos_e))]
	datos.add_child(d)
	if bool(f["propio"]) and int(f["dorsal"]) > 1:
		var c := Label.new()
		c.text = "👕 %s #%d" % [Idiomas.t("Camiseta retirada"), int(f["dorsal"])]
		c.add_theme_color_override("font_color", Tema.TEXTO)
		datos.add_child(c)
	return fila
