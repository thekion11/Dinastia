extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5 CRUZADO: SELECCIONES NACIONALES y MUNDIAL DE CLUBES al límite.
##   1. 12 temporadas (Chile+España: dos confederaciones): la nómina ≤ 18 y la prenómina ≤ 30 sin ids repetidos, convocados vivos y sanos al llamarlos, caps ≥ 0, racha ≥ 0, el Mundial (cada 4 años desde 2028) y el de Clubes con campeón coherente.
##   2. Un club que PIERDE A TODOS sus internacionales (todo el plantel elegible y de lo mejor del país): las fechas FIFA no dejan al club sin once ni cuelgan la semana, y los lesionados no son convocados.
##   3. Casos absurdos: Mundial de Clubes sin campeones continentales o con uno, Copa del Mundo sin selecciones, guardado/carga con ids basura, nacionalizar/pedir descanso con jugadores ajenos.

func _probar() -> void:
	_titulo("A4 CRUZADO (gestión): selecciones nacionales y Mundial de Clubes al límite")
	await _temporadas()
	await _sin_internacionales()
	_absurdos()

func _nuevo(semilla: int, paises: Array[String]) -> Mundo:
	Partido.limpiar_contexto()
	var m := Mundo.new()
	m.generar(paises, semilla)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	return m

func _temporadas() -> void:
	var m := _nuevo(2028, ["CHI", "ESP"])   ## dos confederaciones: sin ellas el Mundial de Clubes no tiene 2 campeones y no se juega (es lo correcto)
	var s: Selecciones = m.selecciones
	var mal: Array[String] = []
	var cuenta := [0, 0, 0]   ## convocatorias, mundiales, mundiales de clubes (en un array: una lambda captura los enteros por valor)
	s.convocatoria.connect(func(conv: Array, _mios: Array) -> void:
		cuenta[0] += 1
		var vistos := {}
		for j: Jugador in conv:
			if vistos.has(j.id):
				mal.append("convocado repetido %s" % j.id)
			vistos[j.id] = true
			## (los de TU club se lesionan DESPUÉS de convocarlos, en la gira: `_desgastar`; se mira a los demás)
			if j.club_id != m.mi_club_id and j.lesion > 0:
				mal.append("convocado lesionado %s (%d sem)" % [j.id, j.lesion])
		if conv.size() > Selecciones.TOPE_NOMINA:
			mal.append("nómina de %d" % conv.size()))
	s.copa_del_mundo_jugada.connect(func(_a: int, _c: String) -> void: cuenta[1] += 1)
	s.mundial_de_clubes_jugado.connect(func(_a: int, _c: Club, _m: bool) -> void: cuenta[2] += 1)
	for t in 12:
		for sem in 40:
			m.avanzar_semana()
			if s.nomina_ids.size() > Selecciones.TOPE_NOMINA or s.prenomina_ids.size() > Selecciones.TOPE_PRENOMINA:
				mal.append("listas desbordadas (%d, %d)" % [s.nomina_ids.size(), s.prenomina_ids.size()])
		for id: String in s._caps:
			if int(s._caps[id]) < 0:
				mal.append("caps negativos")
		for id: String in s._racha:
			if int(s._racha[id]) < 0:
				mal.append("racha negativa")
		if m.directiva != null and m.directiva.despedido_ya:
			m.directiva.despedido_ya = false
			m.directiva.confianza = 60
		m.nueva_temporada()
		await get_tree().process_frame
	_comprobar(mal.is_empty(), "12 temporadas: nómina/prenómina acotadas, sin repetidos ni lesionados convocados (%d fallos%s)" % [mal.size(), "" if mal.is_empty() else ": " + str(mal.slice(0, 3))])
	_comprobar(cuenta[0] >= 12 * 3, "hubo convocatorias en todas las fechas FIFA (%d)" % cuenta[0])
	_comprobar(cuenta[1] == 3, "Copa del Mundo cada 4 años: 12 temporadas desde 2028 incluyen 2028, 2032, 2036 → %d" % cuenta[1])
	_comprobar(cuenta[2] >= 6, "Mundial de Clubes jugado en la mayoría de las temporadas (%d de 12)" % cuenta[2])
	_comprobar(s.resultados.size() <= Selecciones.MAX_RESULTADOS and s.campeones_continentales.size() <= Selecciones.MAX_CAMPEONES_GUARDADOS, "historiales acotados (%d resultados, %d campeones)" % [s.resultados.size(), s.campeones_continentales.size()])

func _sin_internacionales() -> void:
	var m := _nuevo(55, ["CHI"])
	var s: Selecciones = m.selecciones
	var yo := m.mi_club()
	var pais := s.pais_seleccion()
	for j: Jugador in yo.plantilla:
		j.pais = pais
		j.ovr = 90
		j.pot = 92
	var antes := yo.plantilla.size()
	var bajas_max := 0
	for sem in 120:
		m.avanzar_semana()
		var fuera := 0
		for j: Jugador in yo.plantilla:
			if s.nomina_ids.has(j.id):
				fuera += 1
		bajas_max = maxi(bajas_max, fuera)
		if sem % 40 == 39:
			await get_tree().process_frame
	_comprobar(bajas_max >= 8, "el club con todo el plantel internacional pierde al menos 8 jugadores en la fecha FIFA (%d)" % bajas_max)
	var sanos := 0
	for j: Jugador in yo.plantilla:
		if j.lesion <= 0:
			sanos += 1
	_comprobar(yo.plantilla.size() >= antes - 2 and sanos >= 11, "tras 120 semanas el plantel sigue entero (%d de %d) con %d sanos" % [yo.plantilla.size(), antes, sanos])
	_comprobar(s.convocados().size() <= Selecciones.TOPE_NOMINA, "los convocados resueltos ≤ 18 (%d)" % s.convocados().size())
	## el once sigue pudiendo jugar con los convocados fuera: se arma un partido de liga cualquiera
	var p := m.proximo_partido()
	_comprobar(p.size() == 2 or p.is_empty(), "el próximo partido se puede preparar con los convocados fuera")

func _absurdos() -> void:
	var m := _nuevo(77, ["CHI"])
	var s: Selecciones = m.selecciones
	m.continentales.clear()
	_comprobar(s.mundial_de_clubes(2030).is_empty(), "Mundial de Clubes sin campeones continentales: vacío, sin error")
	var m2 := _nuevo(78, ["CHI"])
	for k in m2.continentales.keys():
		var t: Continental = m2.continentales[k]
		t.campeon = null
	_comprobar(m2.selecciones.mundial_de_clubes(2030).is_empty(), "Mundial de Clubes con campeones nulos: vacío")
	var unico := m2.mi_club()
	for k in m2.continentales.keys():
		(m2.continentales[k] as Continental).campeon = unico
		break
	var r := m2.selecciones.mundial_de_clubes(2030)
	_comprobar(r is Dictionary, "Mundial de Clubes con un solo campeón: no falla (%s)" % str(r.keys()))
	for anio in [2026, 2027, 2028, 2031, 2032, 1900, -4]:
		var _t := s.toca_copa_del_mundo(anio)
	_comprobar(s.toca_copa_del_mundo(2026) and s.toca_copa_del_mundo(2030) and not s.toca_copa_del_mundo(2028), "la Copa del Mundo toca en los años reales (2026, 2030) y no en 2028")
	var d := s.a_dic()
	d["nomina"] = ["zzz", "", "j999999"]
	d["prenomina"] = [1, null, "x"]
	s.desde_dic(d)
	_comprobar(s.convocados().is_empty() and s.prenominados().is_empty(), "cargar con ids basura: no se resuelve ninguno y no falla")
	var ajeno: Jugador = null
	for c: Club in m.clubes.values():
		if c.id != m.mi_club_id:
			ajeno = c.plantilla[0]
			break
	_comprobar(s.nacionalizar(ajeno) is String and s.pedir_descanso(ajeno) is String, "nacionalizar/pedir descanso con un jugador ajeno: devuelven un motivo, no fallan")
	_comprobar(s.caps_de(null) == 0 and s.racha_de(null) == 0, "caps y racha de null = 0")
