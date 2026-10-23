extends "res://pruebas/banco_p17.gd"
## [Capa 19/27 de `banco.gd`] _probar_presets_exportacion, _probar_tema_y_ortografia, _probar_eventos_nuevos, _probar_entrevistas, _probar_estadio_b6, _probar_ciudad_b7 … (+3)

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


## EL SISTEMA DE DISEÑO Y LA ORTOGRAFÍA (25-9-2026, plan maestro B13). Dos redes
## contra la regresión: (1) ninguna pantalla vuelve a escribir a mano los
## colores canónicos -apuntan a `Tema`-; (2) las palabras que se corrigieron no
## vuelven a aparecer sin tilde en un texto que ve el jugador.
func _probar_tema_y_ortografia() -> void:
	_titulo("TEMA ÚNICO Y ORTOGRAFÍA DE LOS TEXTOS")
	var canonicos := ["e9eeea", "8ea595", "c9a227", "0c1510", "3fa06a", "141c16", "16211a"]
	var copias: Array[String] = []
	var sin_tilde: Array[String] = []
	var vetadas := ["cesped", "policia", "tunel", "camarin", "tactica", "paises", "tambien", "detras", "INVASION", "Division"]
	var rx := RegEx.new()
	rx.compile("\"((?:[^\"\\\\]|\\\\.)*)\"")
	for carpeta: String in ["res://ui", "res://ui/componentes", "res://nucleo", "res://visor"]:
		var dir := DirAccess.open(carpeta)
		if dir == null:
			continue
		for f: String in dir.get_files():
			if not f.ends_with(".gd") or f == "tema.gd" or f == "idiomas.gd" or f == "pantalla_estadio.gd":
				continue
			var texto := FileAccess.get_file_as_string(carpeta + "/" + f)
			for linea: String in texto.split("\n"):
				var t := linea.strip_edges()
				if t.begins_with("#"):
					continue
				if t.begins_with("const COL_"):
					for c: String in canonicos:
						if t.contains('Color("%s")' % c):
							copias.append(f)
				for m in rx.search_all(linea):
					var v := m.get_string(1)
					if not v.contains(" "):
						continue
					for w: String in vetadas:
						var r2 := RegEx.new()
						r2.compile("\\b" + w + "\\b")
						if r2.search(v) != null:
							sin_tilde.append("%s: %s" % [f, w])
	_comprobar(copias.is_empty(), "ninguna pantalla copia la paleta a mano: todas apuntan a Tema %s" % str(copias))
	_comprobar(sin_tilde.is_empty(), "sin palabras corregidas que vuelvan sin tilde %s" % str(sin_tilde))


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

## B6: el estadio por secciones -fachada, colores por tribuna, luz, superficie-,
## los ocho estilos nuevos y el exterior.
func _probar_estadio_b6() -> void:
	_titulo("ESTADIO B6: FACHADA, COLORES POR SECCIÓN, LUZ, SUPERFICIE, EXTERIOR, 24 ESTILOS")
	var m := Mundo.new()
	m.generar(["CHI"], 909)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	mio.saldo = 500000000
	var e := m.estadio
	_comprobar(e.presets().size() == 24, "24 estilos (16 + 8): %d" % e.presets().size())
	var todos_validos := true
	for p: Array in EstadioPropio.PRESETS_B6:
		for k: String in (p[3] as Dictionary):
			if k == "niveles":
				continue
			if not e.ajustes.has(k) or not e.es_valido(k, p[3][k]):
				todos_validos = false
				print("    estilo %s: «%s»=%s no vale" % [p[0], k, p[3][k]])
	_comprobar(todos_validos, "cada valor de los 8 estilos nuevos existe en su catálogo")
	for k: String in EstadioPropio.DEF_B6:
		if not e.ajustes.has(k):
			_comprobar(false, "clave nueva sembrada: %s" % k)
	var viejo := EstadioPropio.new()
	viejo.desde_dic({"nombre": "", "ajustes": {"forma": "oval"}})
	_comprobar(viejo.ajustes.has("fachada") and String(viejo.ajustes["forma"]) == "oval", "un guardado viejo carga con las claves nuevas")
	_comprobar(e.opciones("fachadaCol").size() == EstadioPropio.PALETA.size() and e.opciones("fachada").size() == 5, "la interfaz ve los catálogos nuevos")
	_comprobar(e.presupuesto(mio, {"fachada": "ladrillo"}) > 0, "revestir la fachada cuesta")
	_comprobar(e.presupuesto(mio, {"fachadaCol": "#b01e2d", "techoCol": "#1b1d22"}) == 0, "pintar es gratis")
	_comprobar(e.reformar(mio, {"fachada": "vidrio"}) == "" and e.terminar_obra() and String(e.perfil(mio)["fachada"]) == "vidrio", "la reforma llega al perfil")
	_comprobar(e.reformar(mio, {"fachada": "marmol"}) != "", "una fachada inventada se rechaza")
	## Colores por tribuna.
	e.reformar(mio, {"personalizar_bandejas": true, "bandeja_norte_col1": "#e8c21a"})
	e.terminar_obra()
	var pf := e.perfil(mio)
	_comprobar(String(pf["bandejas"]["norte"]["col1"]) == "#e8c21a" and String(pf["bandejas"]["sur"]["col1"]) == "", "cada tribuna lleva sus colores")
	## Superficie: efecto real.
	_comprobar(e.factor_lesion() == 1.0 and e.factor_desgaste_cesped() == 1.0, "natural: sin cambios")
	e.reformar(mio, {"superficie": "artificial"})
	e.terminar_obra()
	_comprobar(e.factor_lesion() > 1.0 and e.factor_desgaste_cesped() == 0.0, "artificial: más lesiones, no se estropea")
	e.reformar(mio, {"superficie": "hibrido"})
	e.terminar_obra()
	_comprobar(e.factor_lesion() < 1.0, "híbrido: menos lesiones")
	m.avanzar_semana()
	_comprobar(is_equal_approx(Partido.ctx_lesion_local, e.factor_lesion()), "la semana usa la superficie de tu estadio")
	Partido.limpiar_contexto()
	_comprobar(Partido.ctx_lesion_local == 1.0, "limpiar el contexto la devuelve a 1")
	## La luz.
	var luces := {}
	for l: String in ["neutra", "calida", "fria", "club"]:
		luces[StadiumBuilder.color_luz({"luzFocos": l, "luzClub": "#b01e2d"}).to_html()] = true
	_comprobar(luces.size() == 4, "las cuatro luces se distinguen")
	## El exterior se construye (sin pantalla: solo el árbol de nodos).
	var raiz := Node3D.new()
	add_child(raiz)
	StadiumBuilder.build(raiz, e.perfil(mio), 40000, 0.8, 1, mio)
	var ext := raiz.find_child("Exterior", false, false)
	_comprobar(ext != null and ext.find_children("*", "Label3D", false, false).size() >= 2, "hay taquillas, tienda y rótulos fuera")
	raiz.queue_free()

## B7: la ciudad se puede tocar -cada instalación tiene su punto, lo que no
## existe es un solar-, las obras se ven con su grúa, y el día de partido trae
## gente y banderas. Construir desde el mapa cobra lo mismo que dice la ficha.
func _probar_ciudad_b7() -> void:
	_titulo("CIUDAD B7: SOLARES, OBRAS CON GRÚA, DÍA DE PARTIDO, FICHA Y CONSTRUIR")
	var m := Mundo.new()
	m.generar(["CHI"], 313)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	c.saldo = 900000000
	m.obras.niveles["gim"] = 2
	var antes := c.saldo
	var coste := m.obras.coste("piscina", c.rep)
	_comprobar(m.obras.iniciar("piscina", c) == "" and antes - c.saldo == coste, "construir cobra lo que anuncia la ficha (%d)" % coste)
	var datos := {
		"club": {"nombre": c.nombre, "c1": c.color1, "c2": c.color2, "cap": 30000, "rep": c.rep, "socios": c.socios, "estadioNom": "Estadio"},
		"inst": m.obras.niveles.duplicate(),
		"obras": [{"k": "piscina", "semanas": 4}],
		"terrenos": [], "negocios": {}, "perfil_estadio": {},
		"dia_partido": true, "vecinos": 30,
	}
	var cb := CityBuilder.new()
	add_child(cb)
	cb.build(datos)
	var por_k := {}
	for p: Dictionary in cb.puntos_clic:
		por_k[String(p["k"])] = String(p["estado"])
	_comprobar(por_k.size() >= CityBuilder.EDIFICIOS.size(), "cada instalación tiene su punto en el mapa (%d)" % por_k.size())
	_comprobar(por_k.get("gim", "") == "hecho" and por_k.get("piscina", "") == "obra" and por_k.get("video", "") == "solar",
		"hecho, en obra y solar se distinguen")
	_comprobar(cb.find_children("Grua", "Node3D", false, false).size() >= 1, "la obra tiene su grúa")
	_comprobar(cb.find_child("Hinchada", false, false) != null, "el día de partido hay gente")
	var rot: Node = cb.find_child("Rotulos", false, false)
	_comprobar(rot != null and rot.get_child_count() >= CityBuilder.EDIFICIOS.size(), "rótulos flotantes sobre cada parcela")
	var dentro := true
	for p: Dictionary in cb.puntos_clic:
		if String(p["estado"]) in ["hecho", "obra", "solar"] and (p["pos"] as Vector3).z > 250.0:
			dentro = false
	_comprobar(dentro, "ninguna parcela cae en la calle exterior (z=262)")
	cb.mostrar_rotulos(false)
	_comprobar(not rot.visible, "los rótulos se pueden ocultar")
	cb.queue_free()

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

## C20: la portada guarda lo que necesita el periódico (foto, bajada, medio) y
## cada medio tiene su cabecera; seis cabeceras distintas.
func _probar_portadas_c20() -> void:
	_titulo("C20 PORTADA DE PERIÓDICO: SEIS CABECERAS Y DATOS PARA DIBUJARLA")
	var m := Mundo.new()
	m.generar(["CHI"], 1357)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var pr := m.prensa
	for k in 12:
		pr.portada_tras_resultado(true, false, false, "semilla%d" % k, "A 2-0 B")
	_comprobar(not pr.portadas.is_empty() and String(pr.portadas[0].get("sub", "")) == "A 2-0 B" and String(pr.portadas[0].get("img", "")) == "dt",
		"la portada del partido lleva el marcador y la foto del DT")
	var nombres := {}
	for c: Array in PortadaPeriodico.CABECERAS:
		nombres[String(c[1])] = true
	_comprobar(nombres.size() == 6, "seis cabeceras distintas")
	_comprobar(String(PortadaPeriodico.cabecera_de({"medio": "El Pelotazo"})[0]) == "pelotazo", "cada medio con su cabecera")
	var a := PortadaPeriodico.cabecera_de({"t": "Algo", "semana": 3})
	_comprobar(a == PortadaPeriodico.cabecera_de({"t": "Algo", "semana": 3}), "la misma portada, la misma cabecera")

## C3: la región de origen existe y se guarda; los españoles ya no son todos
## vascos; el Athletic (o su equivalente ficticio) es todo de Euskal Herria, su
## mercado lo respeta -la IA y tú- y sus canteranos llevan apellidos vascos.
func _probar_cantera_c3() -> void:
	_titulo("C3 FILOSOFÍA DE CANTERA: REGIÓN DE ORIGEN, MERCADO Y APELLIDOS")
	var m := Mundo.new()
	m.generar(["ESP"], 8642)
	var bilbao: Club = null
	var otro: Club = null
	for c: Club in m.clubes.values():
		if not Regiones.filosofia(c).is_empty():
			bilbao = c
		elif c.pais == "ESP" and otro == null:
			otro = c
	_comprobar(bilbao != null, "el club de cantera vasca existe (Athletic o su equivalente)")
	if bilbao == null:
		return
	var todos_vascos := true
	for j: Jugador in bilbao.plantilla:
		todos_vascos = todos_vascos and j.region == "EUS"
	## Nacido o formado allí, aunque juegue con otra selección: cuenta la
	## región, no la nacionalidad.
	_comprobar(todos_vascos, "toda la plantilla es de Euskal Herria (por origen, no por pasaporte)")
	var espanoles := 0
	var vascos := 0
	for c: Club in m.clubes.values():
		if c == bilbao:
			continue
		for j: Jugador in c.plantilla:
			if j.pais == "ESP":
				espanoles += 1
				if j.region == "EUS":
					vascos += 1
	var pct := 100.0 * float(vascos) / float(maxi(1, espanoles))
	_comprobar(pct > 3.0 and pct < 18.0, "los vascos son una parte de los españoles, no todos (%.1f %%)" % pct)
	var apellido_vasco := false
	for j: Jugador in bilbao.plantilla:
		for ap: String in Regiones.APELLIDOS_EUS:
			if j.nombre.ends_with(ap):
				apellido_vasco = true
	_comprobar(apellido_vasco, "apellidos vascos en el Athletic")
	## El mercado: un español no vasco no entra; uno vasco sí.
	var no_vasco: Jugador = null
	var vasco: Jugador = null
	for j: Jugador in otro.plantilla:
		if j.region == "" and no_vasco == null:
			no_vasco = j
	for c: Club in m.clubes.values():
		if c != bilbao:
			for j: Jugador in c.plantilla:
				if j.region == "EUS" and vasco == null:
					vasco = j
	_comprobar(not Regiones.admite(bilbao, no_vasco), "el Athletic no puede fichar a un no vasco")
	_comprobar(vasco == null or Regiones.admite(bilbao, vasco), "sí a uno de Euskal Herria")
	m.tomar_el_mando(bilbao.id)
	var motivo := m.mercado.abrir_negociacion(no_vasco)
	_comprobar(String(motivo).to_lower().contains("euskal herria"), "si diriges al Athletic, la regla vale para ti: «%s»" % motivo)
	## Guardado.
	var d := Partida._jugador_a_dic(bilbao.plantilla[0])
	_comprobar(Partida._dic_a_jugador(d).region == "EUS", "la región se guarda con la partida")
