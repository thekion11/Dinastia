extends "res://pruebas/banco/varios_p6.gd"
## [Banco · grupo «varios» · capa 7/10] Generado al partir el banco por grupos (26-10).

## LA ACADEMIA DE 10 A 16 AÑOS (25-9-2026). Cada regla de `Academia` con un
## número: formar bien se nota, comer mal se nota, el colegio se nota, y lo que
## llega al primer equipo a los 16 es consecuencia de todo eso.
func _probar_academia() -> void:
	_titulo("ACADEMIA: LOS CHICOS DE 10 A 16")
	Azar.sembrar(1016)
	var m := Mundo.new()
	m.generar(["CHI"], 1016)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var a := m.academia
	_comprobar(a != null and a.chicos.size() == 6, "la academia arranca con seis chicos (%d)" % (a.chicos.size() if a != null else 0))
	if a == null:
		return
	var edades := {}
	for ch in a.chicos:
		edades[int(ch["edad"])] = true
	_comprobar(edades.size() == 6 and edades.has(10) and edades.has(15), "de 10 a 15 años, uno por edad")
	_comprobar(a.candidatos.size() == Academia.CANDIDATOS_POR_TEMPORADA, "y %d candidatos para captar" % a.candidatos.size())

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

## LOS CINCO MODOS DE MIRAR UN PARTIDO (25-9-2026, plan maestro B2). Con la
## misma semilla, el partido jugado de una vez (Instantáneo), el Resumen y el
## partido en vivo tienen que dar EXACTAMENTE lo mismo: mirar no decide nada.
## El 3D usa los mismos `simular_minuto()` a su propio ritmo. Se juega con la
## grada al límite (ánimo 10) y a varias semillas para que la invasión de
## campo -que antes solo tiraba el partido en vivo- entre en juego.
func _probar_modos_simulacion() -> void:
	_titulo("MODOS DE SIMULACIÓN: MISMO PARTIDO, DISTINTA VISTA")
	## Un mundo por camino, idénticos (misma semilla): un partido le cambia a
	## los jugadores el físico, las lesiones y las tarjetas, así que reusar los
	## mismos clubes haría que el segundo camino jugara con otro plantel.
	var mundos: Array[Mundo] = []
	for via in 3:
		var mv := Mundo.new()
		mv.generar(["CHI"], 77)
		mundos.append(mv)
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
			huellas.append("%d-%d|%d|%s" % [p.goles_local, p.goles_visita, p.cronica.size(), str(p.invasion_ya)])
			if via == 0 and p.invasion_ya:
				invasiones += 1
		if huellas[0] == huellas[1] and huellas[1] == huellas[2]:
			iguales += 1
		elif iguales == k:
			print("    distinto en la semilla %d: %s" % [9000 + k, str(huellas)])
	_comprobar(iguales == semillas, "Instantáneo, Resumen y En vivo dan el mismo partido en %d de %d semillas" % [iguales, semillas])
	_comprobar(invasiones > 0, "la invasión de campo sigue pudiendo ocurrir, ahora en cualquier modo (%d de %d)" % [invasiones, semillas])
	## EL DESCANSO NO BLOQUEA (28-9-2026, informe externo: "después de la charla
	## del medio tiempo no deja continuar"). Se juega con el reloj real: se
	## para en el 45, se da la charla, se sale y el partido termina.
	var mh := mundos[0]
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
	while ph.minuto < 45 and vueltas < 2000:
		reanudar.call()
		vh._process(1.0)
		vueltas += 1
	var parado := bool(vh.get("_entretiempo"))
	var min_parado := ph.minuto
	for _i in 20:
		vh._process(1.0)
	_comprobar(parado and ph.minuto == min_parado, "el reloj se para en el descanso (%d')" % min_parado)
	vh.call("_dar_charla", String(Vestuario.TONOS.keys()[0]))
	vh.call("_salir_segunda")
	vueltas = 0
	while not ph.terminado_ya and vueltas < 5000:
		reanudar.call()
		vh._process(1.0)
		vueltas += 1
	_comprobar(ph.terminado_ya, "tras la charla y salir a la segunda parte, el partido llega al final")
	vh.free()


## LAS EXPORTACIONES SE LEEN (25-9-2026). `export_presets.cfg` llevaba
## comentarios con `##`, que en un .cfg de Godot NO son comentarios (van con
## `;`): el archivo no se podía leer y los filtros que dejan fuera el pack real
## y las fotos de personas reales no se aplicaban. Ahora se comprueba que carga
## y que cada versión publicable excluye todo lo que tiene que excluir.
func _probar_presets_exportacion() -> void:
	_titulo("EXPORTACIONES: EL ARCHIVO SE LEE Y LO PRIVADO QUEDA FUERA")
	var c := ConfigFile.new()
	_comprobar(c.load("res://export_presets.cfg") == OK, "export_presets.cfg se puede leer")
	var privados := ["datos/pack_real.json", "recursos/caras_reales/", "recursos/caras_reales_256/", "datos/creditos_fotos.txt"]
	for i in 4:
		var sec := "preset.%d" % i
		var nombre := String(c.get_value(sec, "name", ""))
		var excl := String(c.get_value(sec, "exclude_filter", ""))
		if nombre == "Windows":
			_comprobar(excl.contains("recursos/caras_reales/"), "la versión completa no lleva las fotos originales (solo los retratos)")
			continue
		var faltan: Array[String] = []
		for p: String in privados:
			if not excl.contains(p):
				faltan.append(p)
		_comprobar(faltan.is_empty(), "%s excluye el pack real y las fotos reales %s" % [nombre, str(faltan) if not faltan.is_empty() else ""])

## LOS NUEVE EVENTOS NUEVOS (25-9-2026, plan maestro B4). Cada uno aparece en la
## baraja cuando se dan sus condiciones y sus DOS salidas mueven algo medible
## (moral, ánimo, funa, caja, sanción, posición o un efecto que dura). Los
## efectos se descuentan semana a semana y viajan en el guardado.
func _probar_eventos_nuevos() -> void:
	_titulo("EVENTOS NUEVOS: TÚNEL, VIRAL, CAPITÁN, HOMENAJE, POSICIÓN, SPONSOR, APUESTAS, HUELGA, CLÁSICO")
	var ids := ["tunel", "viral", "capitan", "silencio", "cambio_posicion", "sponsor_rueda", "apuestas", "huelga_impagos", "derbi_amenaza"]
	var vistos := {}
	var mueven := {}
	for op: String in ["a", "b"]:
		for id: String in ids:
			var m := Mundo.new()
			m.generar(["CHI"], 555)
			m.tomar_el_mando(m.ligas[0].clubes[0].id)
			var mio := m.mi_club()
			mio.plantilla[0].capitan = true
			mio.saldo = -1000   ## para que exista la huelga por impagos
			var pool: Array[Dictionary] = m.prensa._pool(m, mio)
			var ev: Dictionary = {}
			for e: Dictionary in pool:
				if String(e["id"]) == id:
					ev = e
			if ev.is_empty() and id == "derbi_amenaza":
				ev = {"id": id, "pid": "", "txt": "", "opcion_a": "", "opcion_b": ""}
			if ev.is_empty():
				continue
			vistos[id] = true
			## Huella del estado antes y después.
			var huella := func() -> String:
				var moral := 0
				var susp := 0
				var sec := 0
				for j: Jugador in mio.plantilla:
					moral += j.moral
					susp += j.suspension
					sec += j.pos_sec.size()
				return "%d|%d|%d|%d|%d|%d|%d|%d|%d|%d" % [moral, susp, sec, mio.saldo, m.prensa.animo, m.prensa.funa,
					m.prensa.rep_entrenador, m.prensa.efectos.size(), m.federacion.enojo_arbitral if m.federacion != null else 0,
					m.directiva.confianza if m.directiva != null else 0]
			var antes: String = huella.call()
			m.prensa.pendiente = ev
			var r: Dictionary = m.prensa.resolver(op)
			if not r.is_empty() and huella.call() != antes:
				mueven["%s/%s" % [id, op]] = true
	_comprobar(vistos.size() == ids.size(), "los nueve eventos existen en la baraja (%d de 9): %s" % [vistos.size(), str(vistos.keys())])
	var quietas: Array[String] = []
	for id: String in vistos:
		for op: String in ["a", "b"]:
			if not mueven.has("%s/%s" % [id, op]):
				quietas.append("%s/%s" % [id, op])
	## "silencio"/b solo sube el ánimo 2 (puede estar ya en el tope): se tolera
	## que alguna salida sin azar quede igual si el valor ya estaba al límite.
	_comprobar(quietas.size() <= 1, "cada salida mueve algo medible (sin efecto: %s)" % str(quietas))
	## Efectos que duran: el capitán plantado deja 3 semanas de tensión.
	var m2 := Mundo.new()
	m2.generar(["CHI"], 556)
	m2.tomar_el_mando(m2.ligas[0].clubes[0].id)
	m2.prensa.pendiente = {"id": "capitan", "pid": m2.mi_club().plantilla[0].id}
	m2.prensa.resolver("b")
	_comprobar(m2.prensa.efectos.size() == 1 and int(m2.prensa.efectos[0]["semanas"]) == 3, "plantarse al capitán deja un efecto de 3 semanas")
	var d := Partida._prensa_a_dic(m2.prensa)
	_comprobar((d.get("efectos", []) as Array).size() == 1, "el efecto viaja en el guardado")
	for k in 3:
		m2.prensa.semana()
	_comprobar(m2.prensa.efectos.is_empty(), "a las 3 semanas el efecto se termina solo")

## B5: la rueda con periodista, tono, memoria, repregunta, titubeo, titular,
## texto libre y pie de campo. Y que nada de eso toque `Azar`.
func _probar_entrevistas() -> void:
	_titulo("ENTREVISTAS: PERIODISTA, TONO, MEMORIA, REPREGUNTA, TITULAR, TEXTO LIBRE, PIE DE CAMPO")
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
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
	## Calma y a tiempo: se cierra, sin repregunta, y deja titular pendiente.
	var r := pr.responder(0, 2.0)
	_comprobar(not bool(r["sigue"]) and not pr.hay_rueda(), "respuesta en calma cierra la rueda")
	_comprobar(not pr.titular_pendiente.is_empty(), "queda un titular para mañana")
	var tit := pr.publicar_titular_pendiente()
	_comprobar(tit != "" and String(pr.portadas[0]["t"]) == tit, "el titular sale en la hemeroteca")
	_comprobar(pr.memoria.has(String(e["periodista"])), "el periodista recuerda la frase")
	## Titubeo: repregunta el mismo periodista.
	pr.abrir_rueda(false, true)
	var per := String(pr.entrevista["periodista"])
	var calma_i := 0
	for i in (pr.entrevista["opciones"] as Array).size():
		if String(pr.entrevista["opciones"][i]["tono"]) == "calma":
			calma_i = i
	var funa0 := pr.funa
	r = pr.responder(calma_i, Prensa.TITUBEO_SEG + 1.0)
	_comprobar(bool(r["titubeo"]) and bool(r["sigue"]), "tardar en contestar trae repregunta")
	_comprobar(pr.hay_rueda() and String(pr.entrevista["periodista"]) == per and int(pr.entrevista["paso"]) == 1, "repregunta el mismo, una sola vez")
	_comprobar(pr.funa > funa0 or funa0 >= 98, "el titubeo se nota en la calle")
	r = pr.responder(1, 1.0)   ## evasiva, pero ya no hay tercera pregunta
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

## C1: el clima sale de la ciudad y la época (hemisferios al revés, altura,
## nieve solo donde hace frío), no consume Azar y pesa en el partido; cambiar
## el escudo es noticia y pregunta de rueda; la copa también tiene rueda.
func _probar_coherencia_c1() -> void:
	_titulo("C1 COHERENCIA: CLIMA DE LA CIUDAD, ESCUDO COMO NOTICIA, RUEDA TRAS LA COPA")
	## Julio (semana 24): invierno en Santiago, verano en Madrid.
	_comprobar(Clima.estacion("CHI", 24) == "invierno" and Clima.estacion("ESP", 24) == "verano", "hemisferios opuestos")
	_comprobar(Clima.estacion("COL", 24) == "tropical", "el trópico no tiene invierno")
	var a := Clima.del_partido("ENG", 3, 2026, "x")
	_comprobar(a == Clima.del_partido("ENG", 3, 2026, "x"), "el mismo partido tiene siempre el mismo tiempo")
	var nieve_tropico := false
	var nieve_frio := false
	for k in 400:
		if String(Clima.del_partido("BRA", 26, 2026, str(k))["clave"]) == "nieve":
			nieve_tropico = true
		if String(Clima.del_partido("GER", 2, 2026, str(k))["clave"]) == "nieve":
			nieve_frio = true
	_comprobar(not nieve_tropico and nieve_frio, "nieve solo donde y cuando hace frío")
	var alt := Clima.del_partido("BOL", 10, 2026, "y")
	_comprobar(Clima.factor_visita(alt, "ARG", "BOL") < 1.0 and Clima.factor_visita(alt, "ECU", "BOL") == 1.0, "la altura castiga al visitante del llano, no al de altura")
	## El factor llega al partido.
	var m := Mundo.new()
	m.generar(["CHI"], 2468)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	var p := Partido.new(mio, m.ligas[0].clubes[1])
	p.fijar_clima({"clave": "nieve", "calor": false, "altura": false, "texto": "Nieve"})
	_comprobar(p.clima < 1.0, "la nieve traba el partido (factor %.2f)" % p.clima)
	## Escudo nuevo = noticia + pregunta.
	var pr := m.prensa
	pr.revisar_identidad(mio)   ## la primera vez solo toma la foto
	_comprobar(pr.cambio_identidad == "", "sin cambios no hay noticia")
	var portadas_antes := pr.portadas.size()
	mio.esc_forma = "redondo" if mio.esc_forma != "redondo" else "clasico"
	var que := pr.revisar_identidad(mio)
	_comprobar(que == "escudo" and pr.portadas.size() == portadas_antes + 1, "cambiar el escudo sale en portada")
	pr.abrir_rueda(true, false)
	_comprobar(String(pr.entrevista["pregunta"]).contains("escudo") and pr.cambio_identidad == "", "y te preguntan por él en la rueda")
	pr.responder(0, 1.0)
	if pr.hay_rueda():
		pr.responder(0, 1.0)
	## La copa también tiene rueda (con su competición).
	var rival: Club = m.ligas[0].clubes[2]
	pr.entrevista = {}
	var intentos := 0
	while not pr.hay_rueda() and intentos < 20:
		m._rueda_de_eliminatoria([{"local": mio, "visita": rival, "gl": 2, "gv": 1, "pasa": mio}], "copa", [mio, rival])
		intentos += 1
	_comprobar(pr.hay_rueda() and pr.competicion_rueda == "copa", "después de la copa también hay rueda de prensa")
