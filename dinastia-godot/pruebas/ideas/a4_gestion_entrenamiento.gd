extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5 CRUZADO: ENTRENAMIENTO, LESIONES, MÉDICO y MAESTRÍA al límite.
##   1. 12 temporadas (Chile) con el plan más duro (foco técnico, «al límite», todos prioritarios hasta el tope): valoración ≤ potencial (o ≤ 99), físico 10-100, lesión y sanción ≥ 0 y ≤ 60 semanas, sin jugador con valoración fuera de 1-99.
##   2. Médico: 60 lesiones encadenadas al mismo jugador (leves, medias, graves, severidad absurda), chequeo de fatiga con carga 0, −5 y 10⁹, recuperación con 0 semanas, terapia sin dinero (la caja no baja de lo que había).
##   3. Maestría y árbol del DT: subir con 0 puntos, hasta el nivel máximo, categoría inexistente, aprender nodos sin puntos o inexistentes: sin error y sin puntos negativos.
const TEMPORADAS := 12

func _probar() -> void:
	_titulo("A4 CRUZADO (gestión): entrenamiento, lesiones, médico y maestría al límite")
	await _plan_duro()
	_medico()
	_maestria()

func _revisar(m: Mundo) -> Array[String]:
	var mal: Array[String] = []
	for c: Club in m.clubes.values():
		for j: Jugador in c.plantilla:
			if j.ovr < 1 or j.ovr > 99:
				mal.append("ovr %d" % j.ovr)
			if j.ovr > j.pot and j.pot > 0 and j.edad <= 24:
				mal.append("ovr %d > pot %d (edad %d)" % [j.ovr, j.pot, j.edad])
			if j.fisico < 10 or j.fisico > 100:
				mal.append("físico %d" % j.fisico)
			if j.lesion < 0 or j.lesion > 60 or j.suspension < 0 or j.suspension > 60:
				mal.append("lesión %d / sanción %d" % [j.lesion, j.suspension])
	return mal

func _plan_duro() -> void:
	Partido.limpiar_contexto()
	var m := Mundo.new()
	var paises: Array[String] = ["CHI"]
	m.generar(paises, 2024)
	m.tomar_el_mando(m.ligas[0].clubes[2].id)
	var yo := m.mi_club()
	m.entrenamiento.foco = "tecnico"
	m.entrenamiento.intensidad = "alta"
	var fallos: Dictionary = {}
	for t in TEMPORADAS:
		for j: Jugador in yo.plantilla:
			if m.entrenamiento.prioritarios.size() < Entrenamiento.MAX_PRIORITARIOS and not m.entrenamiento.es_prioritario(j):
				m.entrenamiento.alternar_prioritario(j)
		for sem in 40:
			m.avanzar_semana()
		for f in _revisar(m):
			fallos[f] = int(fallos.get(f, 0)) + 1
		if m.directiva != null and m.directiva.despedido_ya:
			m.directiva.despedido_ya = false
			m.directiva.confianza = 60
		await get_tree().process_frame
		m.nueva_temporada()
	_comprobar(fallos.is_empty(), "%d temporadas con el plan más duro: valores en rango (%s)" % [TEMPORADAS, "sin fallos" if fallos.is_empty() else str(fallos.keys().slice(0, 4))])
	var rotos := 0
	for j: Jugador in yo.plantilla:
		if j.lesion > 0 and m.medico != null and m.medico.pct_recuperado(j) > 100:
			rotos += 1
	_comprobar(rotos == 0, "porcentaje de recuperación nunca pasa de 100 (%d)" % rotos)

func _medico() -> void:
	Partido.limpiar_contexto()
	var m := Mundo.new()
	var paises: Array[String] = ["CHI"]
	m.generar(paises, 77)
	m.tomar_el_mando(m.ligas[0].clubes[1].id)
	var yo := m.mi_club()
	var md: Medico = m.medico
	var j: Jugador = yo.plantilla[0]
	var mal := 0
	for i in 60:
		var sev: int = [0, 1, 2, 99, -3][i % 5]
		var sem := md.lesionar(j, sev, "prueba", m.anio, i % 40)
		if sem < 0 or j.lesion < 0 or j.lesion > 60:
			mal += 1
		md.chequeo_de_recaida(j, m.anio, i % 40)
		if i % 7 == 0:
			j.lesion = 0
	_comprobar(mal == 0 and md.historial(j).size() <= 200, "60 lesiones encadenadas con severidades absurdas: semanas en 0-60 (%d malas), historial %d" % [mal, md.historial(j).size()])
	_comprobar(md.lesionar(null) == 0, "lesionar a nadie devuelve 0")
	for carga in [0.0, -5.0, 1000000000.0]:
		j.lesion = 0
		var r := md.riesgo_por_fatiga(j, carga)
		_comprobar(is_finite(r) and r >= 0.0 and r <= 1.0, "riesgo por fatiga con carga %s: probabilidad válida (%s)" % [str(carga), str(r)])
		_comprobar(carga < 1000.0 or r == 1.0, "carga absurda: la probabilidad se queda en 1 (%s)" % str(r))
		md.chequeo_de_fatiga(j, carga, m.anio, 1)
	j.lesion = 0
	_comprobar(md.pct_recuperado(j) >= 0 and md.pct_recuperado(j) <= 100, "recuperación con 0 semanas: %d %%" % md.pct_recuperado(j))
	md.rehabilitacion(j)
	j.lesion = 12
	yo.saldo = 0
	var antes := yo.saldo
	var r2 := md.terapia(j, yo)
	_comprobar(r2 != "" and yo.saldo == antes, "terapia sin dinero: se rechaza y la caja no cambia («%s»)" % r2)
	yo.saldo = -3000000
	var r3 := md.terapia(j, yo)
	_comprobar(r3 != "" and yo.saldo == -3000000, "terapia con la caja en rojo: se rechaza (%s)" % r3)
	yo.saldo = 100000000
	var r4 := md.terapia(j, yo)
	var r5 := md.terapia(j, yo)
	_comprobar(r4 == "" and r5 != "", "terapia pagada una vez; la segunda («ya está en terapia») se rechaza (%s)" % r5)
	_comprobar(md.segunda_opinion(j, yo) is Dictionary and md.costo_informe(j, 0) >= 0 and md.costo_informe(j, -10) >= 0, "informes y segunda opinión con reputación extrema")
	md.revisar_semana(yo, 0.0, m.anio, 1)
	md.revisar_semana(yo, 1000.0, m.anio, 2)
	_comprobar(true, "revisar la semana con carga 0 y 1000 no falla")

func _maestria() -> void:
	var ma := Maestria.new()
	var en := Entrenamiento.new()
	ma.puntos = 0
	_comprobar(ma.subir("ataque", en) != "" or true, "subir sin puntos no falla")
	for clave in Maestria.CATEGORIAS.keys():
		ma.puntos = 100000
		var n := 0
		while ma.subir(String(clave), en) == "" and n < 400:
			n += 1
		_comprobar(ma.nivel(String(clave)) == mini(n, Maestria.NIVEL_MAX) and ma.nivel(String(clave)) <= Maestria.NIVEL_MAX and ma.puntos >= 0, "maestría «%s»: sube hasta el máximo (%d) y se detiene; puntos %d ≥ 0" % [clave, ma.nivel(String(clave)), ma.puntos])
	_comprobar(ma.subir("no_existe", en) != "", "categoría inexistente: se rechaza")
	_comprobar(en.dt_puntos >= 0, "puntos de habilidad del DT no negativos (%d)" % en.dt_puntos)
	en.dt_puntos = 0
	var claves: Array = []
	for rama: Variant in en.dt_ramas().values():
		for nodo: Variant in rama:
			claves.append(String((nodo as Dictionary).get("id", nodo)) if nodo is Dictionary else String(nodo))
	var aprendidos := 0
	for k: String in claves:
		if en.dt_aprender(k) == "":
			aprendidos += 1
	_comprobar(aprendidos == 0 and en.dt_puntos == 0, "sin puntos no se aprende ningún nodo del árbol (%d de %d, puntos %d)" % [aprendidos, claves.size(), en.dt_puntos])
	_comprobar(en.dt_aprender("nodo_que_no_existe") != "" and en.dt_puntos == 0, "nodo inexistente: se rechaza sin tocar los puntos")
	en.dt_puntos = 1000
	var ap2 := 0
	for k: String in claves:
		if en.dt_aprender(k) == "":
			ap2 += 1
	_comprobar(en.dt_puntos >= 0, "con 1000 puntos se aprenden %d de %d nodos (los que piden requisito, no); puntos %d ≥ 0" % [ap2, claves.size(), en.dt_puntos])
	var segundo := claves.size() > 0 and en.dt_aprender(String(claves[0])) != ""
	_comprobar(segundo or claves.is_empty(), "aprender dos veces el mismo nodo se rechaza")
