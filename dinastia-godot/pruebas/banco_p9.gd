extends "res://pruebas/banco_p8.gd"
## (Parte 9 de 25 de `banco.gd`.)

func _probar_fundar_club() -> void:
	_titulo("CREAR TU CLUB: FUNDAR DE CERO")
	var m := Mundo.new()
	m.generar([], 6001)

	## En Chile tiene que tomar el colista de ASCENSO, no de Primera.
	var segunda: Liga = null
	for l: Liga in m.ligas:
		if l.pais == "CHI" and l.division() == 2:
			segunda = l
			break
	_comprobar(segunda != null, "el mundo trae la Primera B de Chile")
	var peor_antes: Club = null
	if segunda != null:
		for c: Club in segunda.clubes:
			if peor_antes == null or c.rep < peor_antes.rep:
				peor_antes = c
	var club := m.fundar_club("Deportivo Prueba", "CHI")
	_comprobar(club != null, "fundar_club() devuelve el club fundado")
	if club != null:
		_comprobar(club.nombre == "Deportivo Prueba", "el club queda con el nombre elegido")
		_comprobar(club.rep == Mundo.REP_FUNDACION, "la reputación de fundación es %d (%d)" % [Mundo.REP_FUNDACION, club.rep])
		_comprobar(club.color1 == "#1e4030" and club.color2 == "#c9a227", "los colores son los del escudo del juego")
		_comprobar(club.division == 2, "sigue en Ascenso -se refunda el club, no se lo asciende")
		_comprobar(club.plantilla.size() >= 18, "el plantel se rehizo entero (%d fichas)" % club.plantilla.size())
		_comprobar(peor_antes != null and club.id == peor_antes.id, "fundar toma al colista real de Ascenso, no cualquiera")
		_comprobar(m.mi_club_id == club.id, "tomar_el_mando() ya se hizo solo: no hace falta un paso más")
		_comprobar(segunda.clubes.has(club), "el club fundado sigue en el calendario de su liga -mismo objeto, no uno nuevo")

	## Fuera de Chile no hay Ascenso: toma el más flojo de la única división.
	var esp: Liga = null
	for l: Liga in m.ligas:
		if l.pais == "ESP":
			esp = l
			break
	if esp != null:
		var peor_esp: Club = esp.clubes[0]
		for c: Club in esp.clubes:
			if c.rep < peor_esp.rep:
				peor_esp = c
		var club2 := m.fundar_club("Fundado FC", "ESP")
		_comprobar(club2 != null and club2.id == peor_esp.id,
			"fuera de Chile toma el más flojo de su única división")

	## Guardado: nombre, colores, reputación y plantel nuevo sobreviven.
	Partida.borrar("_prueba_fundar")
	_comprobar(Partida.guardar(m, "_prueba_fundar"), "una partida con un club fundado se guarda")
	var m2 := Partida.cargar("_prueba_fundar")
	if m2 != null and club != null:
		var recargado: Club = m2.clubes.get(club.id)
		_comprobar(recargado != null and recargado.nombre == "Deportivo Prueba" and recargado.rep == Mundo.REP_FUNDACION,
			"el club fundado vuelve igual al cargar")
	Partida.borrar("_prueba_fundar")

func _probar_ascensos() -> void:
	_titulo("ASCENSOS, DESCENSOS Y PREMIOS")
	var m := Mundo.new()
	m.generar(["CHI"], 4040)
	m.mi_club_id = m.ligas[0].clubes[0].id
	var primera := m.ligas[0]
	var segunda := m.ligas[1]
	_comprobar(primera.division() == 1 and segunda.division() == 2, "las dos divisiones estan marcadas")
	m.jugar_temporada()

	var t1 := primera.tabla()
	var t2 := segunda.tabla()
	var campeon: Club = t1[0]["club"]
	var caja_antes := campeon.saldo
	var rep_antes := campeon.rep
	var ultimo: Club = t1[t1.size() - 1]["club"]
	var penultimo: Club = t1[t1.size() - 2]["club"]
	var primero_b: Club = t2[0]["club"]
	var segundo_b: Club = t2[1]["club"]
	var n1 := primera.clubes.size()
	var n2 := segunda.clubes.size()

	var resumen := m.nueva_temporada()
	_linea("  campeon: %s   suben: %s, %s   bajan: %s, %s" % [
		campeon.nombre, primero_b.nombre, segundo_b.nombre, ultimo.nombre, penultimo.nombre])
	_comprobar(campeon.saldo > caja_antes, "el campeon cobra el premio")
	_comprobar(campeon.rep == rep_antes + 1, "ganar la liga sube la reputacion del club")

	## Lo que de verdad hay que comprobar: que los clubes CAMBIAN de lista, no
	## solo de etiqueta. Mover la etiqueta sin mover la lista deja a un club
	## descendido jugando en primera y cobrando de segunda.
	_comprobar(segunda.clubes.has(ultimo) and segunda.clubes.has(penultimo), "los dos ultimos estan ahora en segunda")
	_comprobar(primera.clubes.has(primero_b) and primera.clubes.has(segundo_b), "los dos primeros de segunda estan ahora en primera")
	_comprobar(not primera.clubes.has(ultimo), "el descendido ya no esta en primera")
	_comprobar(ultimo.division == 2 and primero_b.division == 1, "la division del club acompana al cambio de liga")
	_comprobar(primera.clubes.size() == n1 and segunda.clubes.size() == n2,
		"las dos ligas conservan su tamano (%d y %d)" % [primera.clubes.size(), segunda.clubes.size()])

	## Y el castigo economico del descenso, que es el que de verdad duele.
	var f_abajo := Finanzas.new(ultimo)
	var f_arriba := Finanzas.new(primero_b)
	_linea("  television: el descendido cobra %s, el ascendido %s" % [
		_dinero(f_abajo.derechos_tv()), _dinero(f_arriba.derechos_tv())])
	_comprobar(f_abajo.derechos_tv() < f_arriba.derechos_tv() or ultimo.rep > primero_b.rep + 8,
		"bajar de division cuesta dinero de television")

	## El calendario nuevo tiene que incluir a los recien llegados.
	_comprobar(primera.jornadas() > 0 and primera.emparejamiento_de(primero_b).size() == 2,
		"el ascendido tiene partido en el calendario nuevo")

func _probar_vender() -> void:
	_titulo("VENDER: TRANSFERIBLES, OFERTAS ENTRANTES Y RESCISIÓN")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 5151)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	var mk := m.mercado

	## Listar transferible: marca, castiga la moral una vez, no dos.
	var j: Jugador = mio.plantilla[0]
	var moral_antes := j.moral
	mk.listar_transferible(j)
	_comprobar(j.transferible, "listar transferible marca al jugador")
	_comprobar(j.moral == clampi(moral_antes - 8, 10, 99), "listar transferible castiga la moral")
	var moral_tras_listar := j.moral
	mk.listar_transferible(j)
	_comprobar(j.moral == moral_tras_listar, "listar dos veces no castiga dos veces")

	## El sorteo semanal: en 100 intentos, con un pais entero de posibles
	## compradores detras, tiene que caer al menos una oferta.
	var intentos := 0
	while mk.ofertas_recibidas.is_empty() and intentos < 100:
		mk.buscar_oferta_por_mi_jugador()
		intentos += 1
	_comprobar(not mk.ofertas_recibidas.is_empty(), "cae al menos una oferta en 100 semanas (%d intentos)" % intentos)
	if mk.ofertas_recibidas.is_empty():
		return
	var o: Dictionary = mk.ofertas_recibidas[0]
	var jugador_ofertado: Jugador = o["jugador"]
	var club_comprador: Club = o["club"]
	_comprobar(jugador_ofertado.club_id == mio.id, "la oferta es por un jugador que sigue siendo tuyo")
	_comprobar(club_comprador.id != mio.id, "el comprador nunca eres tu mismo")

	## Rechazar: la oferta desaparece, el jugador sigue en casa.
	var total_antes := mk.ofertas_recibidas.size()
	mk.responder_oferta(0, false)
	_comprobar(mk.ofertas_recibidas.size() == total_antes - 1, "rechazar quita la oferta de la lista")
	_comprobar(jugador_ofertado.club_id == mio.id, "rechazar no mueve al jugador")

	## Aceptar: el dinero se mueve, el jugador cambia de casa.
	intentos = 0
	while mk.ofertas_recibidas.is_empty() and intentos < 100:
		mk.buscar_oferta_por_mi_jugador()
		intentos += 1
	if mk.ofertas_recibidas.is_empty():
		_comprobar(false, "cae una segunda oferta para probar la aceptacion")
		return
	var o2: Dictionary = mk.ofertas_recibidas[0]
	var vendido: Jugador = o2["jugador"]
	var comprador2: Club = o2["club"]
	var saldo_mio_antes := mio.saldo
	var saldo_comprador_antes := comprador2.saldo
	var monto2 := int(o2["monto"])
	mk.responder_oferta(0, true)
	_comprobar(vendido.club_id == comprador2.id, "aceptar mueve al jugador al comprador")
	_comprobar(not mio.plantilla.has(vendido), "el vendido sale de tu plantilla")
	_comprobar(mio.saldo == saldo_mio_antes + monto2, "el dinero de la venta entra a tu caja")
	_comprobar(comprador2.saldo == saldo_comprador_antes - monto2, "el dinero sale de la caja del comprador")
	_comprobar(not vendido.transferible, "vendido, ya no queda transferible")

	## Rescision: mismo camino que usa la ficha (`_rescindir` en principal.gd),
	## repetido aqui a mano porque ese metodo vive en la UI y el banco es
	## headless. El finiquito sale de `Cantera.coste_rescision()`, que ya
	## portaba la formula pero nadie la llamaba desde ningun boton.
	var antes_plantel := mio.plantilla.size()
	var rescindido: Jugador = mio.plantilla[0]
	var coste: Dictionary = m.cantera.coste_rescision(rescindido)
	var total := int(coste["total"])
	var saldo_antes_resc := mio.saldo
	mio.mover_saldo(-total)
	mio.soltar(rescindido)
	rescindido.club_id = ""
	_comprobar(mio.plantilla.size() == antes_plantel - 1, "rescindir saca al jugador de la plantilla (%d -> %d)" % [antes_plantel, mio.plantilla.size()])
	_comprobar(mio.saldo == saldo_antes_resc - total, "rescindir paga el finiquito y la comision (%s)" % _dinero(total))
	_comprobar(not mio.plantilla.has(rescindido), "el rescindido no aparece dos veces ni queda huerfano en la lista")

	## Guardado: una oferta pendiente tiene que sobrevivir a cargar.
	mk.listar_transferible(mio.plantilla[0])
	intentos = 0
	while mk.ofertas_recibidas.is_empty() and intentos < 150:
		mk.buscar_oferta_por_mi_jugador()
		intentos += 1
	var pendientes_antes := mk.ofertas_recibidas.size()
	if pendientes_antes > 0:
		Partida.guardar(m, "__prueba_vender__")
		var m2 := Partida.cargar("__prueba_vender__")
		_comprobar(m2.mercado.ofertas_recibidas.size() == pendientes_antes, "vuelven las mismas ofertas pendientes al cargar (%d)" % m2.mercado.ofertas_recibidas.size())
		if m2.mercado.ofertas_recibidas.size() > 0:
			var oc: Dictionary = m2.mercado.ofertas_recibidas[0]
			_comprobar(oc["jugador"] is Jugador and oc["club"] is Club, "la oferta cargada resuelve jugador y club como objetos reales")
		Partida.borrar("__prueba_vender__")
	else:
		_linea("  (sin ofertas pendientes que guardar tras 150 intentos: no se prueba el guardado)")

func _probar_ojeadores() -> void:
	_titulo("RED DE OJEADORES CON NOMBRE Y SESGO")
	var m := Mundo.new()
	m.generar(["CHI", "ARG", "ESP"], 6262)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var oj := m.ojeadores
	var mio := m.mi_club()

	## Sin jefe de ojeadores contratado, no se cubre ni un pais.
	_comprobar(oj.max_paises() == 0, "sin jefe de ojeadores, la red cubre 0 paises")
	var motivo := oj.alternar_pais("ARG")
	_comprobar(motivo != "", "no se puede cubrir un pais sin jefe de ojeadores (%s)" % motivo)

	## Contratado, el tope sube por escalones -[0,2,4,6]-. El coste crece con el
	## cuadrado del nivel, así que sin caja de sobra la subida de 4 a 5 fallaba
	## por falta de fondos y el nivel se quedaba corto sin que el propio
	## `subir()` lo contara como fallo -devuelve un motivo, no revienta-.
	mio.mover_saldo(2000000000)
	for i in Staff.NIVEL_MAX:
		m.staff.subir("ojeador", mio)
	_comprobar(m.staff.nivel("ojeador") == Staff.NIVEL_MAX, "el jefe de ojeadores llega al nivel maximo (%d)" % m.staff.nivel("ojeador"))
	## La tabla del HTML solo llega a nivel 3 -[0,2,4,6][G.staff.ojo]-, pero el
	## cuerpo tecnico de Godot sube hasta NIVEL_MAX=5 en los seis puestos por
	## igual: `max_paises()` recorta a 3 antes de indexar, así que el tope no
	## sigue subiendo pasado ese punto -mejor recortar a lo que el HTML sí
	## definió que inventar dos escalones que no existen en el original-.
	_comprobar(oj.max_paises() == Ojeadores.MAX_PAISES_POR_NIVEL[mini(Staff.NIVEL_MAX, 3)], "el tope de paises sigue la tabla del nivel, recortada a 3 (%d)" % oj.max_paises())

	## Contratar dos paises: queda registrado, con nombre y sesgo de verdad.
	_comprobar(oj.alternar_pais("ARG") == "", "se contrata un ojeador en ARG")
	_comprobar(oj.alternar_pais("ESP") == "", "se contrata un ojeador en ESP")
	_comprobar(oj.cubre("ARG") and oj.cubre("ESP"), "las dos coberturas quedan activas")
	_comprobar(String(oj.ojeadores["ARG"]["nombre"]) != "", "el ojeador de ARG tiene nombre")
	_comprobar(Ojeadores.SESGOS.has(oj.ojeadores["ARG"]["sesgo"]), "el sesgo del ojeador de ARG es uno de los cuatro conocidos")

	## Retirar la cobertura la deshace del todo.
	_comprobar(oj.alternar_pais("ESP") == "", "se puede retirar una cobertura")
	_comprobar(not oj.cubre("ESP") and not oj.ojeadores.has("ESP"), "al retirar ESP no queda ni la red ni el ojeador")

	## Cuanto se conoce a un jugador ajeno: tuyo=3, mismo pais que el tuyo sin
	## cobertura=1.5, pais cubierto=nivel*0.9, y ojeado siempre 3 sin importar
	## lo demas.
	var mio_j: Jugador = mio.plantilla[0]
	_comprobar(oj.nivel_de(mio_j) == 3.0, "un jugador propio se conoce del todo")
	var rival_arg: Jugador = null
	var rival_local: Jugador = null
	var rival_lejano: Jugador = null
	for c: Club in m.clubes.values():
		if c.id == mio.id or c.plantilla.is_empty():
			continue
		if c.pais == "ARG" and rival_arg == null:
			rival_arg = c.plantilla[0]
		elif c.pais == mio.pais and rival_local == null:
			rival_local = c.plantilla[0]
		elif c.pais != "ARG" and c.pais != mio.pais and rival_lejano == null:
			rival_lejano = c.plantilla[0]
	if rival_arg != null:
		_comprobar(oj.nivel_de(rival_arg) == float(Staff.NIVEL_MAX) * 0.9, "un pais cubierto da nivel*0.9 (%.1f)" % oj.nivel_de(rival_arg))
	if rival_local != null:
		_comprobar(oj.nivel_de(rival_local) == 1.5, "tu propio pais sin cobertura extra da 1.5 (%.1f)" % oj.nivel_de(rival_local))
	if rival_lejano != null:
		_comprobar(oj.nivel_de(rival_lejano) == 0.0, "un pais ajeno y sin cubrir da 0 (%.1f)" % oj.nivel_de(rival_lejano))
		var txt := oj.ovr_texto(rival_lejano)
		_comprobar(txt.find("-") >= 0, "sin conocerlo la media sale en rango, no exacta (%s)" % txt)
		_comprobar(oj.ovr_texto(rival_lejano) == txt, "el rango es estable: no cambia entre llamadas para el mismo jugador")

		## "MERCADO A CIEGAS": con el modo activado, ni el rango numerico se ve
		## -solo una palabra de ESCALA_CIEGA-, y esa palabra tambien es estable.
		oj.modo_ciego = true
		var palabra := oj.ovr_texto(rival_lejano)
		_comprobar(palabra.find("-") < 0 and not palabra.is_valid_int(), "en modo ciego se ve una palabra, no un rango (%s)" % palabra)
		var nombres_escala: Array[String] = []
		for fila: Array in Ojeadores.ESCALA_CIEGA:
			nombres_escala.append(String(fila[1]))
		_comprobar(nombres_escala.has(palabra), "la palabra es una de las siete de ESCALA_CIEGA (%s)" % palabra)
		_comprobar(oj.ovr_texto(rival_lejano) == palabra, "la palabra tambien es estable entre llamadas")
		_comprobar(oj.ovr_texto(mio_j) == str(mio_j.ovr), "en modo ciego, un jugador propio sigue mostrando su numero real")
		oj.modo_ciego = false

	## Ojear paga, revela para siempre y sube el contador del ojeador del pais
	## -solo si ese pais tiene ojeador de verdad, como en el HTML-.
	if rival_arg != null:
		var informes_antes := int(oj.ojeadores["ARG"]["informes"])
		var presupuesto_antes := oj.presupuesto
		var saldo_antes := mio.saldo
		var problema2 := oj.ojear(rival_arg)
		_comprobar(problema2 == "", "ojear a un rival funciona (%s)" % problema2)
		_comprobar(m.ojeados.has(rival_arg.id), "el jugador ojeado queda marcado en mundo.ojeados")
		_comprobar(oj.nivel_de(rival_arg) == 3.0, "ojeado, se conoce del todo")
		_comprobar(oj.ovr_texto(rival_arg) == str(rival_arg.ovr), "ojeado, la media sale exacta")
		_comprobar(oj.presupuesto < presupuesto_antes or mio.saldo < saldo_antes, "ojear gasta de verdad, del presupuesto de ojeo o de la caja")
		_comprobar(oj.ojear(rival_arg) == "ya está ojeado", "no se puede ojear dos veces al mismo jugador")
		_comprobar(int(oj.ojeadores["ARG"]["informes"]) == informes_antes + 1, "el ojeador de ARG suma un informe mas (%d -> %d)" % [informes_antes, int(oj.ojeadores["ARG"]["informes"])])

	## El humor baja si se ignoran mas informes de los que se usan, y a cero
	## el ojeador renuncia y se pierde la cobertura de su pais.
	var o_arg: Dictionary = oj.ojeadores.get("ARG", {})
	if not o_arg.is_empty():
		o_arg["ignorados"] = 100
		o_arg["informes"] = 10
		o_arg["humor"] = 3
		oj.procesar_semana()
		_comprobar(not oj.cubre("ARG"), "un ojeador ignorado sistematicamente renuncia y se pierde la cobertura")

	## Guardado y carga: la red, los ojeadores y el presupuesto vuelven igual.
	oj.alternar_pais("ARG")
	var presupuesto_guardado := oj.presupuesto
	var paises_guardados := oj.red.keys()
	_comprobar(Partida.guardar(m, "__prueba_ojeadores__"), "una partida con red de ojeadores se guarda")
	var m2 := Partida.cargar("__prueba_ojeadores__")
	_comprobar(m2 != null, "esa partida se recarga")
	if m2 != null:
		_comprobar(m2.ojeadores.presupuesto == presupuesto_guardado, "vuelve el mismo presupuesto de ojeo")
		_comprobar(m2.ojeadores.red.keys() == paises_guardados, "vuelve la misma cobertura de paises")
		_comprobar(m2.ojeados.has(rival_arg.id) if rival_arg != null else true, "vuelven los jugadores ya ojeados")
	Partida.borrar("__prueba_ojeadores__")
