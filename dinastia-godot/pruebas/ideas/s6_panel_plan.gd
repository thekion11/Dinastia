extends BaseIdea
## SESIÓN 6 (26-10-2026), filas 19-21: el panel de planificación bajo el plantel
## pinta los tres bloques, sus avisos salen traducidos y «Ofrecer» manda la oferta.

func _texto(tam: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	return l

func _probar() -> void:
	_titulo("S6: PANEL DE PLANIFICACIÓN (filas 19-21)")
	var m := _mundo(2222)
	for i in 9:
		m.avanzar_semana()
	var mio := m.mi_club()
	mio.once()[0].anios_contrato = 1
	PanelPlanificacion.abiertos = {"plan": true, "tablon": true, "termo": true}
	var lista := VBoxContainer.new()
	add_child(lista)
	PanelPlanificacion.pintar(lista, m, _texto, Callable())
	var textos := ""
	for l in lista.find_children("*", "Label", true, false):
		textos += (l as Label).text + "\n"
	var botones := lista.find_children("*", "Button", true, false)
	var titulos := ""
	for b in botones:
		titulos += (b as Button).text + "\n"
	_comprobar(titulos.contains("PLANIFICADOR DE PLANTILLA") and titulos.contains("TABLÓN DE LA LIGA") and titulos.contains("BANQUILLOS CALIENTES"), "los tres bloques")
	_comprobar(textos.contains("Vence el contrato de %s" % mio.once()[0].nombre), "el aviso del titular con el contrato acabando")
	_comprobar(textos.contains(" busca ") and textos.contains("presión"), "el tablón y el termómetro tienen filas")
	var ofrecer: Button = null
	for b in botones:
		if (b as Button).text.begins_with("Ofrecer a "):
			ofrecer = b
	if ofrecer != null:
		var antes := m.mercado.ofertas_recibidas.size()
		ofrecer.pressed.emit()
		_comprobar(m.mercado.ofertas_recibidas.size() == antes + 1 and ofrecer.disabled, "«Ofrecer» deja la oferta en la bandeja")
	else:
		_comprobar(textos.contains(" busca "), "(ningún jugador tuyo encaja hoy en el tablón: sin botón)")
	## En inglés, las frases del planificador.
	Idiomas.idioma = "en"
	var a := {"tipo": "verano", "grupo": "DEL", "n": 2, "vencen": 3, "retiro": 1, "nivel": 1}
	var fr := PanelPlanificacion.frase_aviso(a)
	Idiomas.idioma = "es"
	_comprobar(fr.contains("short of forwards") and fr.contains("Contracts expiring: 3"), "traducido: «%s»" % fr)
	lista.queue_free()
