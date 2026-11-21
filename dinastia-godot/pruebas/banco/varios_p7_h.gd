extends "res://pruebas/banco/varios_p6.gd"
## [Capa de `varios_p7.gd`, 21-11 refactor de forma] Secciones de la ACADEMIA y de los MODOS DE
## SIMULACIÓN. Cada sección recibe lo que comparte (la academia, el mundo, la base del chico); el
## orden de las comprobaciones y los textos son los de antes.


## ACADEMIA, parte 1: arranque, los seis chicos de 10 a 15 y los candidatos.
func _ac_chicos(a: Academia) -> void:
	var edades := {}
	for ch in a.chicos:
		edades[int(ch["edad"])] = true
	_comprobar(edades.size() == 6 and edades.has(10) and edades.has(15), "de 10 a 15 años, uno por edad")
	_comprobar(a.candidatos.size() == Academia.CANDIDATOS_POR_TEMPORADA, "y %d candidatos para captar" % a.candidatos.size())


## ACADEMIA, parte 2: dos gemelos de laboratorio (mismo chico, formaciones opuestas). Devuelve la base.
func _ac_formacion(a: Academia) -> Dictionary:
	## Dos gemelos de laboratorio: mismo chico, dos formaciones opuestas.
	var base: Dictionary = a.chicos[0].duplicate(true)
	base["nivel"] = 30.0; base["techo"] = 80; base["fisico"] = 45.0; base["nota"] = 5.0; base["animo"] = 70.0
	base["personalidad"] = {"disciplina": 50.0, "liderazgo": 40.0, "temple": 40.0, "ambicion": 40.0}
	var bien: Dictionary = base.duplicate(true)
	bien.merge({"plan": "tecnico", "dieta": "deportiva", "estudios": "futbol", "molde": "disciplina"}, true)
	var mal: Dictionary = base.duplicate(true)
	mal.merge({"plan": "descanso", "dieta": "libre", "estudios": "estudios", "molde": "liderazgo"}, true)
	for sem in 76:
		bien["lesion"] = 0
		mal["lesion"] = 0
		a._semana_de(bien)
		a._semana_de(mal)
	_linea("  dos temporadas: bien formado nivel %.1f / físico %.0f / nota %.1f   |   mal formado nivel %.1f / físico %.0f / nota %.1f" % [
		float(bien["nivel"]), float(bien["fisico"]), float(bien["nota"]),
		float(mal["nivel"]), float(mal["fisico"]), float(mal["nota"])])
	_comprobar(float(bien["nivel"]) > float(mal["nivel"]) + 3.0, "entrenar técnico, comer bien y priorizar el fútbol hace crecer más")
	_comprobar(float(bien["fisico"]) > float(mal["fisico"]) + 10.0, "el plan de nutricionista desarrolla el cuerpo más que el comedor libre")
	_comprobar(float(bien["nota"]) < float(mal["nota"]), "pero priorizar el fútbol hunde las notas y priorizar el colegio las sube")
	_comprobar(float(bien["nivel"]) < 80.0, "y nadie supera su techo (%.1f < 80)" % float(bien["nivel"]))
	_comprobar(float(mal["personalidad"]["liderazgo"]) > 70.0, "el molde forja carácter: liderazgo de 40 a %.0f" % float(mal["personalidad"]["liderazgo"]))
	_comprobar(a.rasgo_dominante(mal) == "liderazgo", "y ese carácter domina")
	_comprobar(a.techo_al_entregar(bien) > a.techo_al_entregar(mal), "la formación sube el techo con el que llega (%d contra %d)" % [
		a.techo_al_entregar(bien), a.techo_al_entregar(mal)])
	return base


## ACADEMIA, parte 3: la familia saca al chico con notas hundidas, tras el aviso del colegio.
func _ac_familia(a: Academia, base: Dictionary) -> void:
	## La familia: con notas hundidas, primero avisa el colegio y luego se lo llevan.
	var flojo: Dictionary = base.duplicate(true)
	flojo.merge({"id": "flojo", "nota": 3.0, "estudios": "futbol", "aviso_notas": false}, true)
	a.chicos.append(flojo)
	var hubo_aviso := false
	var se_fue := false
	for sem in 150:
		for s2 in a.procesar_semana():
			if String(s2["id"]) == "flojo":
				hubo_aviso = hubo_aviso or String(s2["tipo"]) == "aviso"
				se_fue = se_fue or String(s2["tipo"]) == "abandono"
		if se_fue:
			break
	_comprobar(hubo_aviso and se_fue, "con notas hundidas avisa el colegio y la familia acaba sacándolo")
	_comprobar(a.chico("flojo").is_empty(), "y deja de estar en la academia")


## ACADEMIA, parte 4: la residencia cuesta, captar respeta el cupo, la entrega a los 16 y el guardado.
func _ac_residencia_entrega(m: Mundo, a: Academia) -> void:
	## La residencia cuesta: la semana descuenta la caja.
	var c := m.mi_club()
	var antes := c.saldo
	a.procesar_semana()
	_comprobar(c.saldo < antes, "la residencia se paga cada semana (%s)" % Eco.dinero(antes - c.saldo))

	## Captar: cuesta, ocupa plaza y respeta el cupo.
	var n_antes := a.chicos.size()
	var err := a.captar(0)
	_comprobar(err == "" and a.chicos.size() == n_antes + 1, "captar a un candidato lo trae a la residencia %s" % err)
	while a.chicos.size() < Academia.CUPO:
		a.chicos.append(a._nuevo_chico(10))
	_comprobar(a.captar(0) != "", "con la residencia llena no se capta a nadie más")

	_ac_entrega_guardado(m, a)


## ACADEMIA, parte 5: la entrega a los 16 (pasa al plantel) y el guardado de la academia.
func _ac_entrega_guardado(m: Mundo, a: Academia) -> void:
	var c := m.mi_club()
	## Entrega: a los 16 pasa al plantel como Jugador de verdad.
	var chico15: Dictionary = {}
	for ch in a.chicos:
		if int(ch["edad"]) == 15:
			chico15 = ch
	if chico15.is_empty():
		chico15 = a.chicos[0]
		chico15["edad"] = 15
	chico15["personalidad"]["liderazgo"] = 92.0
	var nombre15 := String(chico15["nombre"])
	var de14: Dictionary = a._nuevo_chico(14)
	a.chicos.append(de14)
	_comprobar(a.entregar(String(de14["id"])) != "", "no se puede entregar a uno de 14")
	while c.plantilla.size() >= Cantera.TOPE_PLANTEL:
		c.plantilla.pop_back()
	var entregados := a.fin_de_temporada()
	var nuevo: Jugador = null
	for j in entregados:
		if j.nombre == nombre15:
			nuevo = j
	_comprobar(nuevo != null, "al cumplir 16 pasa al primer equipo")
	if nuevo != null:
		_comprobar(c.plantilla.has(nuevo) and nuevo.edad == 16, "con 16 años y dentro de la plantilla")
		_comprobar(nuevo.pot >= nuevo.ovr and nuevo.ovr >= 40, "media %d, proyección %d" % [nuevo.ovr, nuevo.pot])
		_comprobar(nuevo.rasgo == "lider", "el carácter que forjaste es su rasgo (%s)" % nuevo.rasgo)
		_comprobar(m.cantera.es_canterano(nuevo), "y cuenta como canterano de la casa")
		_comprobar(a.chico(String(chico15["id"])).is_empty(), "y deja la academia")
	_comprobar(a.candidatos.size() == Academia.CANDIDATOS_POR_TEMPORADA, "la temporada nueva trae otra tanda de candidatos")

	## El guardado se la lleva entera.
	var ids: Array[String] = []
	for ch in a.chicos:
		ids.append(String(ch["id"]))
	var foto := Partida.instantanea(m)
	var m2 := Partida.desde_instantanea(foto)
	var ids2: Array[String] = []
	if m2 != null and m2.academia != null:
		for ch in m2.academia.chicos:
			ids2.append(String(ch["id"]))
	_comprobar(ids2 == ids, "guardar y cargar conserva a los %d chicos" % ids.size())


## MODOS, parte 0: un mundo por camino, idénticos (misma semilla).
func _ms_mundos() -> Array[Mundo]:
	## Un mundo por camino, idénticos (misma semilla): un partido le cambia a
	## los jugadores el físico, las lesiones y las tarjetas, así que reusar los
	## mismos clubes haría que el segundo camino jugara con otro plantel.
	var mundos: Array[Mundo] = []
	for via in 3:
		var mv := Mundo.new()
		mv.generar(["CHI"], 77)
		mundos.append(mv)
	return mundos


## MODOS, parte 1: el mismo partido, de las tres vías, en 40 semillas (y la invasión de campo).
func _ms_mismo_partido(mundos: Array[Mundo]) -> void:
	var iguales := 0
	var invasiones := 0
	var semillas := 40
	for k in semillas:
		var huellas: Array[String] = []
		for via in 3:
			var l := mundos[via].ligas[0]
			var a: Club = l.clubes[k % l.clubes.size()]
			var b: Club = l.clubes[(k + 3) % l.clubes.size()]
			Azar.sembrar(9000 + k)
			var p := Partido.new(a, b)
			_jugar_via(via, p, a)
			huellas.append("%d-%d|%d|%s" % [p.goles_local, p.goles_visita, p.cronica.size(), str(p.invasion_ya)])
			if via == 0 and p.invasion_ya:
				invasiones += 1
		if huellas[0] == huellas[1] and huellas[1] == huellas[2]:
			iguales += 1
		elif iguales == k:
			print("    distinto en la semilla %d: %s" % [9000 + k, str(huellas)])
	_comprobar(iguales == semillas, "Instantáneo, Resumen y En vivo dan el mismo partido en %d de %d semillas" % [iguales, semillas])
	_comprobar(invasiones > 0, "la invasión de campo sigue pudiendo ocurrir, ahora en cualquier modo (%d de %d)" % [invasiones, semillas])


## MODOS, parte 2: EL DESCANSO NO BLOQUEA (28-9-2026): el reloj se para en el 45 y el partido termina.
func _ms_descanso(mh: Mundo) -> void:
	## EL DESCANSO NO BLOQUEA (28-9-2026, informe externo: "después de la charla
	## del medio tiempo no deja continuar"). Se juega con el reloj real: se
	## para en el 45, se da la charla, se sale y el partido termina.
	var lh := mh.ligas[0]
	var ph := Partido.new(lh.clubes[0], lh.clubes[1])
	var vh := PartidoVivo.new()
	vh.con_3d = false
	vh.abrir(ph, lh.clubes[0], mh.vestuario)
	var vueltas := 0
	## Una lesión propia para el reloj a propósito (hay que mover el banco):
	## la prueba reanuda como lo haría el jugador.
	var reanudar := func() -> void:
		if int(vh.get("_velocidad")) == 0 and not bool(vh.get("_entretiempo")):
			vh.call("_poner_velocidad", 2)
	while ph.minuto < 45 and vueltas < 8000:   ## (4-11) cada _process avanza como mucho 0,25 s: tras segundo plano el delta no se traga el partido
		reanudar.call()
		vh._process(1.0)
		vueltas += 1
	vh._process(1.0)   ## (4-11) con el tope de 0,25 s por fotograma el reloj llega al 45' sin dar el paso que lo detiene: un fotograma más
	var parado := bool(vh.get("_entretiempo"))
	var min_parado := ph.minuto
	for _i in 20:
		vh._process(1.0)
	_comprobar(parado and ph.minuto == min_parado, "el reloj se para en el descanso (%d')" % min_parado)
	vh.call("_dar_charla", String(Vestuario.TONOS.keys()[0]))
	vh.call("_salir_segunda")
	vueltas = 0
	while not ph.terminado_ya and vueltas < 20000:
		reanudar.call()
		vh._process(1.0)
		vueltas += 1
	_comprobar(ph.terminado_ya, "tras la charla y salir a la segunda parte, el partido llega al final")
	vh.free()


## Juega el partido de una vía hasta el final: 0 instantáneo, 1 resumen, 2 en vivo sin 3D.
func _jugar_via(via: int, p: Partido, a: Club) -> void:
	match via:
		0:
			p.preparar()
			p.fijar_hinchada(a, 10)
			while not p.terminado_ya:
				p.simular_minuto()
		1:
			p.preparar()
			p.fijar_hinchada(a, 10)
			var capa := Control.new()
			var r := ResumenPartido.mostrar(capa, p, a, false, true)
			r.free()
			capa.free()
		2:
			## El partido en vivo sin 3D, saltado al final.
			p.fijar_hinchada(a, 10)
			var vivo := PartidoVivo.new()
			vivo.con_3d = false
			vivo.abrir(p, a)
			vivo.call("_hasta_el_final")
			vivo.free()


## ENTREVISTAS, parte 1: la rueda con periodista, la respuesta en calma y el titular de mañana.
func _en_calma_titular(m: Mundo) -> void:
	var pr := m.prensa
	pr.abrir_rueda(true, false)
	var e := pr.entrevista
	_comprobar(String(e.get("periodista", "")) != "", "pregunta un periodista con nombre")
	_comprobar(not String(e["pregunta"]).begins_with("Prensa:"), "la pregunta ya no la firma «Prensa»")
	var todas_con_tono := true
	for g: Array in [Prensa._GANE, Prensa._EMPATE, Prensa._PERDI]:
		for q: Dictionary in g:
			for o: Dictionary in q["opciones"]:
				todas_con_tono = todas_con_tono and String(o.get("tono", "")) in ["calma", "soberbia", "evasiva"]
	_comprobar(todas_con_tono, "cada respuesta del guion tiene tono")
	pr.cola_rueda.clear()   ## (cuántas preguntas «del momento» trae la rueda se sortea: aquí se prueba solo la primera)
	## Calma y a tiempo: se cierra, sin repregunta, y deja titular pendiente.
	## (La opción en calma no siempre es la 0: la pregunta se sortea con `Azar`, así que se busca por su tono.)
	var calma0 := 0
	for i in (e["opciones"] as Array).size():
		if String(e["opciones"][i]["tono"]) == "calma":
			calma0 = i
	var r := pr.responder(calma0, 2.0)
	_comprobar(not bool(r["sigue"]) and not pr.hay_rueda(), "respuesta en calma cierra la rueda")
	_comprobar(not pr.titular_pendiente.is_empty(), "queda un titular para mañana")
	var tit := pr.publicar_titular_pendiente()
	_comprobar(tit != "" and String(pr.portadas[0]["t"]) == tit, "el titular sale en la hemeroteca")
	_comprobar(pr.memoria.has(String(e["periodista"])), "el periodista recuerda la frase")


## ENTREVISTAS, parte 2: el titubeo trae repregunta, la evasiva cierra, la memoria devuelve la frase
## y el texto libre se clasifica por tono.
func _en_titubeo_memoria_texto(m: Mundo) -> void:
	var pr := m.prensa
	## Titubeo: repregunta el mismo periodista.
	pr.abrir_rueda(false, true)
	pr.cola_rueda.clear()
	var per := String(pr.entrevista["periodista"])
	var calma_i := 0
	for i in (pr.entrevista["opciones"] as Array).size():
		if String(pr.entrevista["opciones"][i]["tono"]) == "calma":
			calma_i = i
	var funa0 := pr.funa
	var r := pr.responder(calma_i, Prensa.TITUBEO_SEG + 1.0)
	_comprobar(bool(r["titubeo"]) and bool(r["sigue"]), "tardar en contestar trae repregunta")
	_comprobar(pr.hay_rueda() and String(pr.entrevista["periodista"]) == per and int(pr.entrevista["paso"]) == 1, "repregunta el mismo, una sola vez")
	_comprobar(pr.funa > funa0 or funa0 >= 98, "el titubeo se nota en la calle")
	var evasiva_i := 1
	for i in (pr.entrevista["opciones"] as Array).size():
		if String(pr.entrevista["opciones"][i]["tono"]) == "evasiva":
			evasiva_i = i
	r = pr.responder(evasiva_i, 1.0)   ## evasiva, pero ya no hay tercera pregunta
	_comprobar(not bool(r["sigue"]) and not pr.hay_rueda(), "tras la repregunta se cierra aunque evadas")
	## Memoria: soberbia hoy, derrota la semana que viene -> te la devuelven.
	pr.memoria.clear()
	for f: Array in Prensa.PERIODISTAS:
		pr.memoria[String(f[0])] = {"frase": "Que se preparen los de arriba", "tono": "soberbia", "fecha": pr._fecha() - 1}
	pr.abrir_rueda(false, false)
	_comprobar(bool(pr.entrevista.get("memoria", false)) and String(pr.entrevista["pregunta"]).contains("Que se preparen"), "la frase soberbia vuelve tras perder")
	## Texto libre.
	_comprobar(pr.clasificar_respuesta("Sin comentarios") == "evasiva", "texto: «sin comentarios» es evasiva")
	_comprobar(pr.clasificar_respuesta("Somos los mejores y que se preparen") == "soberbia", "texto: soberbia")
	_comprobar(pr.clasificar_respuesta("Confío en el grupo, trabajaremos toda la semana") == "calma", "texto: calma")
	_comprobar(pr.clasificar_respuesta("ok") == "evasiva", "texto: dos letras no es respuesta")
	var arb0 := pr.enojo_arbitral
	r = pr.responder_texto("El árbitro nos robó, ustedes no saben nada", 1.0)
	_comprobar(String(r["tono"]) == "soberbia" and pr.enojo_arbitral >= arb0 + 2, "hablar de árbitros con soberbia los enoja")
	if pr.hay_rueda():
		pr.responder(0, 1.0)


## ENTREVISTAS, parte 3: el pie de campo (con el marcador) y el guardado de la prensa.
func _en_pie_guardado(m: Mundo) -> void:
	var pr := m.prensa
	## Pie de campo.
	var moral0 := m.mi_club().plantilla[0].moral
	var pie := pr.pie_de_campo(true, false, 2, 0)
	_comprobar((pie["opciones"] as Array).size() == 3 and String(pie["pregunta"]).contains("2-0"), "a pie de campo: pregunta con el marcador")
	var rp := pr.responder_pie(0)
	_comprobar(rp["tono"] == "calma" and pr.pie.is_empty() and m.mi_club().plantilla[0].moral >= moral0, "a pie de campo: responder mueve y cierra")
	pr.pie_de_campo(false, false, 0, 1)
	_comprobar(String(pr.responder_pie(-1)["tono"]) == "evasiva", "a pie de campo: pasar de largo")
	## Se guarda y se carga.
	var d := Partida._prensa_a_dic(pr)
	_comprobar(d.has("memoria") and d.has("titular_pendiente"), "memoria y titular se guardan")
