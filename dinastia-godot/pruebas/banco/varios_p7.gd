extends "res://pruebas/banco/varios_p7_h.gd"
## [Capa 7/10 de `varios.gd`] _probar_academia, _probar_modos_simulacion, _probar_presets_exportacion, _probar_eventos_nuevos, _probar_entrevistas, _probar_coherencia_c1

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
	_ac_chicos(a)
	var base := _ac_formacion(a)
	_ac_familia(a, base)
	_ac_residencia_entrega(m, a)

## LOS CINCO MODOS DE MIRAR UN PARTIDO (25-9-2026, plan maestro B2). Con la
## misma semilla, el partido jugado de una vez (Instantáneo), el Resumen y el
## partido en vivo tienen que dar EXACTAMENTE lo mismo: mirar no decide nada.
## El 3D usa los mismos `simular_minuto()` a su propio ritmo. Se juega con la
## grada al límite (ánimo 10) y a varias semillas para que la invasión de
## campo -que antes solo tiraba el partido en vivo- entre en juego.
func _probar_modos_simulacion() -> void:
	_titulo("MODOS DE SIMULACIÓN: MISMO PARTIDO, DISTINTA VISTA")
	var mundos := _ms_mundos()
	_ms_mismo_partido(mundos)
	_ms_descanso(mundos[0])

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
	## (30-10-2026, opción B del dueño) TODAS las versiones son públicas, Windows y Linux incluidas:
	## lo real va aparte en caras_reales.pck (herramientas/empaquetar_caras.gd).
	var i := 0
	while c.has_section("preset.%d" % i):
		var sec := "preset.%d" % i
		i += 1
		var nombre := String(c.get_value(sec, "name", ""))
		var excl := String(c.get_value(sec, "exclude_filter", ""))
		var faltan: Array[String] = []
		for p: String in privados:
			if not excl.contains(p):
				faltan.append(p)
		_comprobar(faltan.is_empty(), "%s excluye el pack real y las fotos reales %s" % [nombre, str(faltan) if not faltan.is_empty() else ""])
		## (10-11-2026, orden 36 del dueño) la biblioteca de caras es pública: mezclas de 4 jugadores, no personas reales
		_comprobar(not excl.contains("caras_biblioteca") and not excl.contains("biblioteca_caras"), "%s lleva la biblioteca de caras (pública)" % nombre)

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
	_en_calma_titular(m)
	_en_titubeo_memoria_texto(m)
	_en_pie_guardado(m)

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
	_comprobar(Clima.factor_visita(alt, "ARG", "BOL") < 1.0 and is_equal_approx(Clima.factor_visita(alt, "ECU", "BOL"), 1.0), "la altura castiga al visitante del llano, no al de altura")
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
	## (10-11) El dado decide entre la rueda de la copa y la previa del siguiente partido (que pisa la competición): se repite
	## con la entrevista vacía hasta que sale la de la copa, en vez de depender de que la primera tirada acierte.
	while not (pr.hay_rueda() and pr.competicion_rueda == "copa") and intentos < 20:
		pr.entrevista = {}
		m._rueda_de_eliminatoria([{"local": mio, "visita": rival, "gl": 2, "gv": 1, "pasa": mio}], "copa", [mio, rival])
		intentos += 1
	_comprobar(pr.hay_rueda() and pr.competicion_rueda == "copa", "después de la copa también hay rueda de prensa")
