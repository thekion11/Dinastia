extends "res://pruebas/banco/varios_p9.gd"
## [Capa de `varios_p10.gd`, 21-11 refactor de forma] Secciones de CALENDARIO: EVENTOS, VARIAS SEMANAS
## Y «HITO». Lo que comparten (la vista, el club y la liga) va en un diccionario; el orden de las
## comprobaciones y los textos son los de antes.


## CALENDARIO, parte 1: la vista de varias semanas (liga, copa, continental y mercado).
func _ef_vista(m: Mundo) -> Dictionary:
	var mio := m.mi_club()
	var liga := m.liga_de(mio)
	var sem := EventosFecha.semanas(m)
	_comprobar(sem.size() == EventosFecha.VISTA, "la vista trae %d semanas (%d)" % [EventosFecha.VISTA, sem.size()])
	var seguidas := true
	var cuenta := {"liga": 0, "copa": 0, "conti": 0, "mercado_cierra": 0}
	for i in sem.size():
		if int(sem[i]["k"]) != i or int(sem[i]["semana"]) != m.semana + i:
			seguidas = false
		for e: Dictionary in sem[i]["eventos"]:
			if cuenta.has(e["tipo"]):
				cuenta[e["tipo"]] += 1
			if e["tipo"] == "liga" and (not (e["rival"] is Club) or e["rival"] == mio or e["etiqueta"] != "J%d" % (i + 1)):
				seguidas = false
	_comprobar(seguidas and cuenta["liga"] == EventosFecha.VISTA, "una semana tras otra, cada una con su partido de liga y el rival (%d)" % cuenta["liga"])
	var copa_viva := m.copa != null and m.copa.en_curso() and m.copa.vivos.has(m.club_de_la_copa())
	_comprobar((cuenta["copa"] == 1) == copa_viva, "la copa sale en la semana 4 si sigues vivo (%d, vivo %s)" % [cuenta["copa"], str(copa_viva)])
	var conti := m.mi_continental()
	## (10-11) Cada torneo tiene SU calendario (`FormatosConti`): sale un evento por cada semana de la vista en que le toca jugar.
	var esperados := 0
	if conti != null and conti.en_curso():
		for i in EventosFecha.VISTA:
			if conti.semanas().has(m.semana + i):
				esperados += 1
	_comprobar(cuenta["conti"] == esperados and esperados >= 1, "el continental sale en las semanas en que juega su torneo si tu club juega uno (%d de %d)" % [cuenta["conti"], esperados])
	_comprobar(cuenta["mercado_cierra"] == 1, "el cierre del mercado (semana %d) sale en las 6 semanas" % Mundo.VENTANA_VERANO)
	return {"liga": liga, "sem": sem, "conti": conti}


## CALENDARIO, parte 2: la copa y el continental llevan nombre de competición y, la primera ronda, rival.
func _ef_nombres(m: Mundo, st: Dictionary) -> void:
	var sem: Array = st["sem"]
	var conti: Variant = st["conti"]
	## La copa y el continental llevan nombre de competición y, la primera ronda, rival.
	for s: Dictionary in sem:
		for e: Dictionary in s["eventos"]:
			if e["tipo"] == "copa":
				_comprobar(String(e["texto"]).begins_with(m.copa.nombre) and e["rival"] is Club, "copa: «%s» con rival" % e["texto"])
			if e["tipo"] == "conti":
				_comprobar(String(e["texto"]).begins_with(conti.nombre), "continental: «%s»" % e["texto"])


## CALENDARIO, parte 3: la apertura del mercado de invierno.
func _ef_mercado(m: Mundo) -> void:
	## Apertura del mercado de invierno.
	m.semana = Mundo.VENTANA_INVIERNO_INI - 2
	var ab := false
	for s: Dictionary in EventosFecha.semanas(m):
		for e: Dictionary in s["eventos"]:
			if e["tipo"] == "mercado_abre":
				ab = int(s["semana"]) == Mundo.VENTANA_INVIERNO_INI and int(e["dia"]) == 0
	_comprobar(ab, "el mercado abre el lunes de la semana %d" % Mundo.VENTANA_INVIERNO_INI)


## CALENDARIO, parte 4: el fin de temporada y el «Hito» (hasta qué día y por qué evento se detiene).
func _ef_fin_hito(m: Mundo, liga: Liga) -> void:
	## Fin de temporada: la última jornada lleva el evento y la vista no pasa de ahí.
	m.semana = 30
	liga.jornada_actual = liga.jornadas() - 3
	var fin := EventosFecha.semanas(m)
	var tipos_fin := (fin[fin.size() - 1]["eventos"] as Array).map(func(e: Dictionary) -> String: return String(e["tipo"]))
	_comprobar(fin.size() == 3 and tipos_fin.has("fin"), "la vista acaba en la última jornada, con «Fin de temporada» (%d semanas)" % fin.size())
	## «Hito»: hasta qué día y por qué evento.
	m.semana = 1
	liga.jornada_actual = 0
	var h0 := EventosFecha.hito(m, 0)
	_comprobar(h0["tipo"] == "liga" and int(h0["dia"]) == 5, "el hito de un lunes de liga es el partido del sábado (%s)" % h0["texto"])
	m.semana = Mundo.VENTANA_VERANO
	var h6 := EventosFecha.hito(m, 6)
	_comprobar(h6["tipo"] != "mercado_cierra" and int(h6["dia"]) == 6, "el domingo del cierre del mercado ya pasó: el hito sigue en la semana que viene")
	m.semana = Mundo.VENTANA_INVIERNO_INI - 1
	var hab := EventosFecha.hito(m, 6)
	_comprobar(hab["tipo"] == "mercado_abre", "el domingo antes de abrir el mercado, el hito es su apertura (%s)" % hab["texto"])


## CALENDARIO, parte 5: los próximos eventos en orden de fecha, la fila que los pinta y la vista de semanas.
func _ef_proximos(m: Mundo) -> void:
	var ordenados := true
	var previo := -1
	m.semana = 1
	for e: Dictionary in EventosFecha.proximos(m, 0, 12):
		var clave := int(e["k"]) * 10 + int(e["dia"])
		if clave < previo:
			ordenados = false
		previo = clave
	_comprobar(ordenados, "los próximos eventos salen en orden de fecha")
	## La fila de próximos y la vista de varias semanas se pintan.
	var caja := HBoxContainer.new()
	add_child(caja)
	FilaProximos.pintar(m, caja)
	_comprobar(caja.get_child_count() == 2 + 2 * FilaProximos.CUANTOS, "la fila pinta rótulo, botón 📅 y %d eventos (%d nodos)" % [FilaProximos.CUANTOS, caja.get_child_count()])
	caja.queue_free()
	var vista := CalendarioSemanas.mostrar(self, m, 0)
	var tira: Node = vista._centro.get_child(2)
	_comprobar(tira.get_child_count() == EventosFecha.VISTA, "la vista de varias semanas pinta una columna por semana (%d)" % tira.get_child_count())
	vista.queue_free()
