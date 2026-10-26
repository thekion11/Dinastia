extends BaseIdea
## SESIÓN 6 (26-10-2026), fila 20 de la propuesta s4: el tablón de necesidades de
## la liga. Cada club de la IA de tu país dice qué línea le falta, y ofrecerle a
## uno de los tuyos que encaja manda una oferta real a tu bandeja.

func _probar() -> void:
	_titulo("S6: TABLÓN DE NECESIDADES DE LA LIGA (fila 20)")
	var m := _mundo(2020)
	var mio := m.mi_club()
	var tab := TablonLiga.necesidades(m)
	var bien := not tab.is_empty()
	var ordenado := true
	for i in tab.size():
		var c: Club = tab[i]["club"]
		bien = bien and c != mio and c.pais == mio.pais and TablonLiga.LINEAS.has(String(tab[i]["grupo"]))
		if i > 0:
			ordenado = ordenado and int(tab[i - 1]["presupuesto"]) >= int(tab[i]["presupuesto"])
	_comprobar(bien, "el tablón trae %d clubes de la IA de tu país, cada uno con una línea" % tab.size())
	_comprobar(ordenado, "los de más dinero primero")
	## Un club al que se le van los porteros: pide portero porque está corto.
	var otro: Club = tab[0]["club"]
	var porteros: Array[Jugador] = []
	for j: Jugador in otro.plantilla:
		if j.pos == "POR":
			porteros.append(j)
	for j: Jugador in porteros.slice(1):
		otro.plantilla.erase(j)
	var n := TablonLiga.necesidad(otro)
	_comprobar(String(n["grupo"]) == "POR" and String(n["motivo"]) == "corto", "con un solo portero, %s pide portero (%s)" % [otro.nombre, str(n.get("grupo"))])
	## Ofrecerle un portero tuyo que encaja.
	var mi_por: Jugador = null
	for j: Jugador in mio.plantilla:
		if j.pos == "POR":
			mi_por = j
	mi_por.ovr = int(n["media_min"]) + 4
	mi_por.edad = 26
	mi_por.valor = int(float(n["presupuesto"]) * 0.5)
	var antes := m.mercado.ofertas_recibidas.size()
	var r := TablonLiga.ofrecer(m, mi_por, otro)
	_comprobar(bool(r["ok"]) and m.mercado.ofertas_recibidas.size() == antes + 1 and int(r["monto"]) <= int(n["presupuesto"]),
		"ofrecerle tu portero manda una oferta real a tu bandeja (%d)" % int(r["monto"]))
	_comprobar(not bool(TablonLiga.ofrecer(m, mi_por, otro)["ok"]), "no repite oferta por el mismo jugador")
	var mi_del: Jugador = null
	for j: Jugador in mio.plantilla:
		if j.pos == "DEL":
			mi_del = j
	_comprobar(String(TablonLiga.ofrecer(m, mi_del, otro)["motivo"]) == "busca otra línea", "un delantero no le sirve: «busca otra línea»")
	var flojo: Jugador = mio.plantilla.filter(func(x: Jugador) -> bool: return x.pos == "POR" and x != mi_por)[0]
	flojo.ovr = int(n["media_min"]) - 5
	_comprobar(String(TablonLiga.motivo_rechazo(n, flojo)) == "le falta nivel", "uno por debajo de su media: «le falta nivel»")
	## Aceptar la oferta: el portero se va de verdad.
	var idx := m.mercado.ofertas_recibidas.size() - 1
	var caja_antes := mio.saldo
	m.mercado.responder_oferta(idx, true)
	_comprobar(mi_por.club_id == otro.id and mio.saldo > caja_antes, "aceptada, el portero ficha por %s y cobras" % otro.nombre)
