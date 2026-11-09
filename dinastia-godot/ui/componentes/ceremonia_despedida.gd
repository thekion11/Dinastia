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
	var m := PantallaEvento.montar(self, "🎖️", Idiomas.t("Homenaje"))
	var filas: Array = []
	for h: Dictionary in homenajeados:
		filas.append({"j": h["jugador"], "dorsal": int(h["dorsal"]), "propio": true})
	if filas.is_empty():
		var top: Array = leyendas.plantilla.duplicate()
		top.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
		for j: Jugador in top.slice(0, 3):
			filas.append({"j": j, "dorsal": 0, "propio": false})
	var tarjetas := HFlowContainer.new()
	tarjetas.alignment = FlowContainer.ALIGNMENT_CENTER
	tarjetas.add_theme_constant_override("h_separation", 26)
	tarjetas.add_theme_constant_override("v_separation", 26)
	tarjetas.custom_minimum_size = Vector2(900, 0)
	m["cuerpo"].add_child(tarjetas)
	for f: Dictionary in filas:
		tarjetas.add_child(_fila(pr, f))
	var seguir := PantallaEvento.boton(Idiomas.t("Continuar"), true)
	seguir.pressed.connect(func() -> void:
		terminado.emit()
		queue_free())
	m["pie"].add_child(seguir)
	seguir.call_deferred("grab_focus")

func _fila(pr: Principal, f: Dictionary) -> Control:
	var j: Jugador = f["j"]
	var tarjeta := PanelContainer.new()
	var est := Tema.caja(Tema.PANEL, Tema.RADIO_GRANDE, Tema.oro())
	est.set_border_width_all(2)
	est.set_content_margin_all(20)
	est.shadow_color = Color(0, 0, 0, 0.5)
	est.shadow_size = 14
	tarjeta.add_theme_stylebox_override("panel", est)
	var datos := VBoxContainer.new()
	datos.add_theme_constant_override("separation", 6)
	datos.custom_minimum_size = Vector2(240, 0)
	tarjeta.add_child(datos)
	var retrato := pr._retrato(j, 160)
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	retrato.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	datos.add_child(retrato)
	var n := Tema.etiqueta(Tema.TAM_TITULO, Tema.oro(), j.nombre)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	datos.add_child(n)
	var d := Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "%d %s · %s %d · %s" % [j.edad, Idiomas.t("años"), Idiomas.t("Nota"), j.ovr, Idiomas.t(String(j.pos_e))])
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	datos.add_child(d)
	if bool(f["propio"]) and int(f["dorsal"]) > 1:
		var c := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, "👕 %s #%d" % [Idiomas.t("Camiseta retirada"), int(f["dorsal"])])
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		datos.add_child(c)
	return tarjeta
