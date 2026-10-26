extends BaseIdea
## EL PORQUÉ DEL RESULTADO (26-10-2026, sesión 5, fila 4 de la propuesta). Tras cada partido, tres causas
## legibles sacadas de lo que pasó de verdad (`RastroPartido` + `CausasPartido`): momentum, forma, plantilla,
## clima, táctica rival, cansancio, árbitro, eficacia, lesiones. Se prueba cada causa con un partido
## preparado, que el rastro no cambia ningún resultado, 60 partidos de verdad y las dos pantallas.

func _probar() -> void:
	var m := _mundo(5151)
	var yo := m.mi_club()
	var rival: Club = m.ligas[0].clubes[1]
	Partido.limpiar_contexto()
	Partido.ctx_club_id = yo.id
	_titulo("CAUSAS: el rastro no cambia nada del partido")
	var a := _jugar(777)
	var b := _jugar(777)
	_comprobar(a == b, "el mismo partido, en dos mundos iguales, da lo mismo (%s / %s)" % [a, b])
	var pz := Partido.new(yo, rival)
	pz.preparar()
	var estado: int = Azar._rng.state
	pz.rastro.al_preparar(pz)
	pz.gol.emit(yo, pz.once_local[9], 10, null)
	CausasPartido.de(pz, yo)
	_comprobar(Azar._rng.state == estado, "mirar el rastro y sacar las causas no gasta ni un número del azar de la partida")
	_titulo("CAUSAS: cada una sale de un dato")
	## Forma: tu once en racha, el suyo por los suelos.
	var p := Partido.new(yo, rival)
	p.preparar()
	for j in p.once_local:
		j.forma = 92
	for j in p.once_visita:
		j.forma = 35
	p.rastro.al_preparar(p)
	_comprobar(_hay(p, 0, "forma", 1), "la forma: llegabas mejor → causa a favor (%s)" % _texto(p, 0, "forma"))
	_comprobar(_hay(p, 1, "forma", -1), "y vista desde el rival, en contra")
	## Roja a uno tuyo en el 20'.
	p.minuto = 20
	p.tarjeta_externa(p.once_local[3].id, true)
	_comprobar(_hay(p, 0, "arbitro", -1), "una roja tuya en el 20' → «jugamos con uno menos» (%s)" % _texto(p, 0, "arbitro"))
	## El árbitro decide por su cuenta: la frase y, en el mismo minuto, su tarjeta.
	var p2 := Partido.new(yo, rival)
	p2.preparar()
	p2.minuto = 30
	p2.decision_arbitral.emit("🟨 X saca otra amarilla: ", 30)
	p2.tarjeta.emit(p2.once_local[2], false, 30)
	p2.minuto = 50
	p2.decision_arbitral.emit("⚽ Penal cobrado en contra.", 50)
	p2.gol.emit(rival, p2.once_visita[9], 50, null)
	_comprobar(p2.rastro.arbitraje.size() == 2 and bool(p2.rastro.arbitraje[0]["contra_local"]) and String(p2.rastro.arbitraje[1]["tipo"]) == "penal",
		"las decisiones del árbitro quedan apuntadas contra quien fueron (%d)" % p2.rastro.arbitraje.size())
	_comprobar(_hay(p2, 0, "arbitro", -1), "y explican: %s" % _texto(p2, 0, "arbitro"))
	## Momentum: un cuarto de hora de llegadas y dos goles tuyos dentro.
	var p3 := Partido.new(yo, rival)
	p3.preparar()
	for mi in range(55, 70, 2):
		p3.minuto = mi
		p3.remate_externo(true, p3.once_local[9].id, "atajada")
	p3.minuto = 61
	p3.gol_externo(true, p3.once_local[9].id, "")
	p3.minuto = 66
	p3.gol_externo(true, p3.once_local[10].id, "")
	var tr := p3.rastro.tramo_dominante(15)
	_comprobar(int(tr["neto"]) >= 8 and int(tr["desde"]) >= 50 and int(tr["desde"]) <= 56, "el tramo dominante se encuentra (%d'-%d', neto %d)" % [tr["desde"], tr["hasta"], tr["neto"]])
	_comprobar(_hay(p3, 0, "momentum", 1), "y explica: %s" % _texto(p3, 0, "momentum"))
	## Clima: lluvia de invierno en la simulación.
	var p4 := Partido.new(yo, rival)
	p4.fijar_clima({"clave": "lluvia", "calor": false, "altura": false, "texto": "Lluvia", "estacion": "invierno"})
	p4.preparar()
	_comprobar(p4.clima < 0.97 and _hay(p4, 0, "clima", 0), "la lluvia traba el partido para los dos (%s)" % _texto(p4, 0, "clima"))
	## Lo mismo jugado en el motor del 3D: el clima no pesa allí, no se cuenta.
	p4.motor_externo = true
	p4.simular_minuto()
	_comprobar(p4.rastro.con_motor and not _hay(p4, 0, "clima", 0) and not _hay(p4, 0, "localia", 1),
		"con el motor del 3D no se cuentan ni el clima ni la localía (no los modela)")
	## El plan del rival en el 60': se encerró y no le marcaste.
	var p5 := Partido.new(yo, rival)
	p5.preparar()
	p5.plan_activado[rival.id] = "ganando:cerrojo"
	_comprobar(_hay(p5, 0, "tactica", -1), "el cerrojo del rival que le salió (%s)" % _texto(p5, 0, "tactica"))
	p5.minuto = 80
	p5.gol_externo(true, p5.once_local[9].id, "")
	_comprobar(_hay(p5, 0, "tactica", 1), "y si le marcaste igual, a tu favor (%s)" % _texto(p5, 0, "tactica"))
	## La pizarra del rival: todo al ataque y la línea arriba contra tu pizarra de siempre.
	var t_antes := rival.tactica.duplicar()
	rival.tactica.mentalidad = Tactica.Mentalidad.OFENSIVA
	rival.tactica.linea = Tactica.Nivel.ALTO
	rival.tactica.ritmo = Tactica.Nivel.ALTO
	var p6 := Partido.new(yo, rival)
	p6.preparar()
	_comprobar(_texto(p6, 0, "tactica").contains("4-3-3") or _texto(p6, 0, "tactica").contains(rival.tactica.formacion), "la pizarra distinta del rival cuenta (%s)" % _texto(p6, 0, "tactica"))
	rival.tactica = t_antes
	## Lesión de uno tuyo.
	p5.lesion.emit(p5.once_local[4], 3, 40)
	_comprobar(_hay(p5, 0, "lesion", -1), "una lesión tuya (%s)" % _texto(p5, 0, "lesion"))
	_titulo("CAUSAS: 60 partidos de verdad")
	var tres := 0
	var distintas := 0
	var coherentes := 0
	var decididos := 0
	var claves := {}
	for k in 60:
		var c: Club = m.ligas[0].clubes[2 + k % 10]
		var pp := Partido.new(yo, c) if k % 2 == 0 else Partido.new(c, yo)
		pp.simular()
		var cs := CausasPartido.de(pp, yo)
		if cs.size() == 3:
			tres += 1
		var vistas := {}
		for x: Dictionary in cs:
			vistas[x["clave"]] = true
			claves[x["clave"]] = int(claves.get(x["clave"], 0)) + 1
		if vistas.size() == cs.size():
			distintas += 1
		var mios := pp.goles_local if pp.local == yo else pp.goles_visita
		var suyos := pp.goles_visita if pp.local == yo else pp.goles_local
		if mios != suyos and not cs.is_empty():
			decididos += 1
			if int(cs[0]["signo"]) == signi(mios - suyos):
				coherentes += 1
	_linea("  (causas que salieron: %s)" % str(claves))
	_comprobar(tres == 60, "siempre tres causas (%d de 60)" % tres)
	_comprobar(distintas == 60, "nunca dos del mismo tipo")
	_comprobar(float(coherentes) >= 0.85 * float(decididos), "la primera explica el resultado: a favor si ganaste, en contra si perdiste (%d de %d)" % [coherentes, decididos])
	_comprobar(claves.size() >= 6, "salen causas variadas (%d tipos)" % claves.size())
	_titulo("CAUSAS: en el resumen y en el partido en vivo")
	var pr := Partido.new(yo, rival)
	pr.preparar()
	var padre := Control.new()
	add_child(padre)
	var res := ResumenPartido.mostrar(padre, pr, yo, false, false)
	var caja := res.find_child("PorQue", true, false)
	_comprobar(caja != null and caja.get_child_count() == 3, "el resumen enseña «🔎 POR QUÉ» con tres filas")
	if caja != null and caja.get_child_count() > 0:
		var fila := caja.get_child(0)
		_comprobar((fila.get_child(2) as Label).text.length() > 10, "con su texto: %s" % (fila.get_child(2) as Label).text)
	padre.queue_free()
	var pv := Partido.new(yo, rival)
	var vivo := PartidoVivo.new()
	vivo.con_3d = false
	add_child(vivo)
	vivo.abrir(pv, yo)
	while not pv.terminado_ya:
		pv.simular_minuto()
	var texto := vivo._cronica.get_parsed_text()
	_comprobar(texto.contains(Idiomas.t("🔎 POR QUÉ")), "y el final del partido en vivo/3D también")
	vivo.queue_free()

## Un mundo nuevo y un partido entero con una semilla: su marcador y sus remates.
func _jugar(semilla: int) -> String:
	var m := _mundo(9090)
	Partido.ctx_club_id = m.mi_club_id
	Azar.sembrar(semilla)
	var p := Partido.new(m.mi_club(), m.ligas[0].clubes[3])
	p.simular()
	return "%d-%d r%d/%d" % [p.goles_local, p.goles_visita, p.remates_local, p.remates_visita]

func _hay(p: Partido, mio: int, clave: String, signo: int) -> bool:
	for c: Dictionary in CausasPartido.candidatas(p, mio):
		if String(c["clave"]) == clave and int(c["signo"]) == signo:
			return true
	return false

func _texto(p: Partido, mio: int, clave: String) -> String:
	for c: Dictionary in CausasPartido.candidatas(p, mio):
		if String(c["clave"]) == clave:
			return String(c["texto"])
	return "—"
