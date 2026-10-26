extends BaseIdea
## pint: la charla del personal del club varía (hora, semana) y las preguntas
## nuevas de oficio contestan con datos de la partida.

func _probar() -> void:
	_titulo("PINT · CHARLA DEL PERSONAL")
	var m := _mundo(2500)
	var c := m.mi_club()
	_comprobar(c != null, "hay un club al mando")
	for clave: String in RecorridoClub.SALUDOS:
		var base := String(RecorridoClub.SALUDOS[clave])
		var vistos := {}
		for s in 6:
			vistos[RecorridoCharla.saludo(clave, base, s, 12.0)] = true
		_comprobar(vistos.size() >= 3, "%s saluda de al menos 3 maneras según la semana (%d)" % [clave, vistos.size()])
		_comprobar(RecorridoCharla.saludo(clave, base, -1, -1.0) == Idiomas.t(base), "%s sin partida usa el saludo base" % clave)
	_comprobar(RecorridoCharla.saludo("conserje", "x", 3, 22.0) != RecorridoCharla.saludo("conserje", "x", 3, 7.0),
		"el conserje saluda distinto de noche y de madrugada")
	for clave: String in RecorridoCharla.PREGUNTAS:
		_comprobar(not RecorridoClub.PREGUNTA_OFICIO.has(clave), "%s: la pregunta nueva no pisa otra" % clave)
		var r := RecorridoClub.respuesta_oficio(clave, m)
		_comprobar(r != "" and r != Idiomas.t("Hoy no sé qué decirle, míster.") and not r.contains("%"),
			"%s contesta algo propio: %s" % [clave, r])
	## La prensa cambia con la confianza.
	c.confianza = 90
	var alta := RecorridoClub.respuesta_oficio("prensa", m)
	c.confianza = 10
	var baja := RecorridoClub.respuesta_oficio("prensa", m)
	_comprobar(alta != baja, "la prensa cuenta otra cosa con la confianza baja")
	_comprobar(RecorridoClub._ultima_mala, "y con confianza baja es mala noticia")
	var rival := RecorridoCharla._rival(m, c)
	if rival != null:
		_comprobar(RecorridoClub.respuesta_oficio("chofer", m).contains(rival.nombre), "el chófer nombra al próximo rival")
