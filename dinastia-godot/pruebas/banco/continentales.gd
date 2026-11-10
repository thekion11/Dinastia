extends "res://pruebas/banco/continentales_p1.gd"
## (Parte 2 de 2 de `continentales.gd`.)

func _probar_continentales_intercontinental() -> void:
	_titulo("CONTINENTALES · COPA INTERCONTINENTAL")
	for caso: Array in [[95, "JPN"], [96, "EGY"], [97, "MEX"]]:
		Azar.sembrar(int(caso[0]))
		var cinco := _clubes_de_prueba(5, String(caso[1]), String(caso[1]))
		var t := Continental.crear("interc")
		_comprobar(t is CopaIntercontinental and t.es_fifa(), "%s: la fábrica crea la Copa Intercontinental" % caso[1])
		t.preparar(cinco)
		_comprobar(t.huecos().size() == 3 and t.nombre_de_ronda() == "Challenger Cup y Derbi de las Américas", "%s: tres rondas (%s)" % [caso[1], t.nombre_de_ronda()])
		var r1 := t.jugar_ronda()
		_comprobar(r1.size() == 2 and r1[0]["etiqueta"] == "Challenger Cup" and r1[1]["etiqueta"] == "Derbi de las Américas", "%s: Asia-África es la Challenger Cup y las Américas, el Derbi" % caso[1])
		_comprobar(r1[0]["local"] == cinco[0] and r1[0]["visita"] == cinco[1] and r1[1]["local"] == cinco[2] and r1[1]["visita"] == cinco[3], "los cruces salen del orden de los campeones")
		_comprobar(t.vivos.size() == 3 and t.vivos[2] == cinco[4], "el campeón de Europa espera sin jugar")
		var r2 := t.jugar_ronda()
		_comprobar(r2.size() == 1 and t.nombre_de_ronda() == "Final" and t.vivos.has(cinco[4]), "semifinal entre los dos ganadores y final contra Europa")
		var r3 := t.jugar_ronda()
		_comprobar(t.campeon != null and r3[0]["local"] != null and t.historial.size() == 3, "%s: campeón %s" % [caso[1], t.campeon.nombre if t.campeon else "-"])
	## Con menos de cinco campeones continentales también se juega.
	Azar.sembrar(98)
	var tres := Continental.crear("interc")
	tres.preparar(_clubes_de_prueba(3, "T", "AUS"))
	_jugar_hasta_el_final(tres)
	_comprobar(tres.campeon != null, "con tres campeones: hay Copa Intercontinental igual")

func _probar_continentales_fifa_en_la_temporada() -> void:
	_titulo("CONTINENTALES · LOS TORNEOS DE LA FIFA ENTRAN EN EL CALENDARIO")
	var mundo_chico: Array[String] = ["CHI", "ARG", "BRA", "ESP", "ENG", "ITA", "JPN", "MEX", "EGY", "MAR"]
	for caso: Array in [["BRA", 101], ["ENG", 102]]:
		var m := Mundo.new()
		m.generar(mundo_chico, int(caso[1]))
		var mio: Club = null
		for c: Club in m.clubes.values():
			if c.pais == String(caso[0]) and c.division == 1 and (mio == null or c.rep > mio.rep):
				mio = c
		m.tomar_el_mando(mio.id)
		_comprobar(not m.continentales.has("mundial") and not m.continentales.has("interc"), "%s: el primer año no hay torneos de la FIFA (aún no hay campeones)" % caso[0])
		_cerrar_torneos(m, m.continentales.keys())
		var campeones := 0
		for k: String in Continental.PRINCIPALES:
			if m.continentales.has(k) and (m.continentales[k] as Continental).campeon != null:
				campeones += 1
		var previos := m.continentales
		FifaClubes.sumar(m, previos)
		var mundial: Continental = m.continentales.get("mundial")
		_comprobar(mundial != null, "%s: con %d campeones continentales se arma el Mundial de Clubes" % [caso[0], campeones])
		if mundial == null:
			continue
		_linea("  %s: Mundial de Clubes con %d clubes (%s)" % [caso[0], mundial.participantes.size(), mundial.formato])
		_comprobar(mundial.participantes.size() >= 8, "%s: hay al menos 8 clubes (%d)" % [caso[0], mundial.participantes.size()])
		var campeon_ucl: Club = previos["ucl"].campeon if previos.has("ucl") else null
		_comprobar(campeon_ucl == null or mundial.participa(campeon_ucl), "el campeón de Europa está en el Mundial")
		var repetidos := 0
		var vistos := {}
		for c: Club in mundial.participantes:
			if vistos.has(c.id):
				repetidos += 1
			vistos[c.id] = true
		_comprobar(repetidos == 0, "%s: ningún club repetido" % caso[0])
		var interc: Continental = m.continentales.get("interc")
		_comprobar(interc != null and interc.participantes.size() == 5, "%s: y la Copa Intercontinental con los 5 campeones (%d)" % [caso[0], interc.participantes.size() if interc else 0])
		if interc != null:
			_comprobar(interc.participantes[4] == previos["ucl"].campeon and interc.participantes[0] == previos["asia"].campeon, "%s: Europa espera la final y Asia abre el cuadro" % caso[0])
		## Un guardado a mitad del Mundial conserva el torneo y su clase.
		mundial.jugar_ronda()
		var dic := Partida._continentales_a_dic(m.continentales)
		_comprobar(dic.has("mundial") and dic.has("interc") and String(dic["mundial"].get("formato", "")) == mundial.formato, "%s: el guardado trae los dos torneos y su formato" % caso[0])
		var avance := m.semana
		var jugados_fifa := 0
		for sem in 12:
			var antes := mundial.ronda
			m.avanzar_semana()
			if mundial.ronda > antes:
				jugados_fifa += 1
		_comprobar(jugados_fifa >= 3, "%s: el Mundial avanza solo con las semanas del calendario (%d rondas en 12 semanas desde la %d)" % [caso[0], jugados_fifa, avance])
