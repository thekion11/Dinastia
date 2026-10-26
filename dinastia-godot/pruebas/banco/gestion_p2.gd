extends "res://pruebas/banco/gestion_p1.gd"
## [Capa 2/3 de `gestion.gd`] _probar_cesiones, _probar_vender, _probar_ojeadores

func _probar_cesiones() -> void:
	_titulo("CESIONES Y CLÁUSULAS: LA LETRA PEQUEÑA")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 5151)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	_comprobar(m.cesiones != null, "tomar el mando crea las cesiones")

	## Ceder a un canterano y que vuelva mejor al cerrar la temporada -la trampa
	## gorda del HTML era que la opcion NUNCA se ejecutaba porque dos resolutores
	## se pisaban; aqui solo hay uno.
	var joven: Jugador = null
	for j in mio.plantilla:
		if j.edad <= Cesiones.EDAD_CANTERANO:
			joven = j
			break
	if joven != null:
		var r := m.cesiones.ceder_canterano(joven)
		_comprobar(not r.has("error"), "se puede ceder a un canterano (%s)" % str(r.get("error", "")))
		_comprobar(m.cesiones.esta_cedido(joven.id), "queda marcado como cedido")
		_comprobar(not mio.plantilla.has(joven), "sale de la plantilla mientras esta cedido")
		var media_antes := joven.ovr
		m.jugar_temporada()
		m.nueva_temporada()
		_comprobar(not m.cesiones.esta_cedido(joven.id), "al cerrar la temporada, la cesion se resuelve sola")
		_comprobar(mio.plantilla.has(joven), "el canterano cedido vuelve a casa")
		_comprobar(joven.ovr >= media_antes, "vuelve con la misma media o mejor (%d -> %d)" % [media_antes, joven.ovr])

	## Clausula de rescision: pactarla, blindarla, y que otro club te la pueda
	## pagar de verdad -sin pasar por la mesa de Mercado.
	var figura: Jugador = mio.plantilla[0]
	for j in mio.plantilla:
		if j.ovr > figura.ovr:
			figura = j
	var monto1 := m.cesiones.pactar_clausula(figura)
	_comprobar(m.cesiones.clausula_de(figura) == monto1, "pactar cláusula queda fijado (%s)" % _dinero_prueba(monto1))
	var monto2 := m.cesiones.blindar(figura)
	_comprobar(monto2 > monto1, "blindar sube la cláusula sobre la pactada (%s -> %s)" % [_dinero_prueba(monto1), _dinero_prueba(monto2)])

	## Un rival con cláusula implicita -sin pactar, la del hash- y caja de sobra
	## para pagarla.
	var rival_j: Jugador = null
	var rival_c: Club = null
	for c: Club in m.clubes.values():
		if c.id == mio.id:
			continue
		for j in c.plantilla:
			if m.cesiones.clausula_de(j) > 0:
				rival_j = j
				rival_c = c
				break
		if rival_j != null:
			break
	if rival_j != null:
		mio.mover_saldo(m.cesiones.coste_de_clausula(rival_j)["total"] + 1000)
		var antes_caja: int = rival_c.saldo
		var rr := m.cesiones.pagar_clausula(rival_j, mio)
		_comprobar(not rr.has("error"), "se puede pagar la clausula de un jugador rival (%s)" % str(rr.get("error", "")))
		_comprobar(rival_j.club_id == mio.id, "el jugador pasa a ser tuyo tras el clausulazo")
		_comprobar(rival_c.saldo > antes_caja, "el club vendido cobra la clausula")

	## Guardado y carga.
	Partida.borrar("_prueba_cesiones")
	_comprobar(Partida.guardar(m, "_prueba_cesiones"), "una partida con cesiones y clausulas se guarda")
	var m2 := Partida.cargar("_prueba_cesiones")
	if m2 != null:
		_comprobar(m2.cesiones.clausula_de(figura) == monto2, "la clausula blindada sobrevive al guardado (%s)" % _dinero_prueba(m2.cesiones.clausula_de(figura)))
	Partida.borrar("_prueba_cesiones")

	## RENOVAR. `pide_para_renovar()` sabia calcular lo que pide cada uno desde
	## hace tiempo y no habia forma de decirle que si.
	var renovable: Jugador = mio.plantilla[0]
	renovable.anios_contrato = 1
	renovable.sueldo = 50000
	renovable.moral = 70
	var pide := m.cantera.pide_para_renovar(renovable)
	_comprobar(pide > renovable.sueldo, "pide mas de lo que cobra para renovar (%d sobre %d)" % [pide, renovable.sueldo])
	var r_ren := m.cantera.renovar(renovable, false)
	_comprobar(r_ren.has("ok"), "se puede renovar a uno tuyo")
	_comprobar(renovable.sueldo == pide, "renovar le deja el sueldo que pedia (%d)" % renovable.sueldo)
	_comprobar(renovable.anios_contrato >= 2 and renovable.anios_contrato <= 4,
		"firma entre dos y cuatro temporadas (%d)" % renovable.anios_contrato)
	## Con clausula acepta un 10% menos: es la unica decision real de la pantalla.
	var otro: Jugador = mio.plantilla[1]
	otro.anios_contrato = 1
	otro.sueldo = 50000
	otro.moral = 70
	var pide2 := m.cantera.pide_para_renovar(otro)
	var r2 := m.cantera.renovar(otro, true)
	_comprobar(otro.sueldo < pide2, "con clausula de salida cobra menos que lo que pedia (%d < %d)" % [otro.sueldo, pide2])
	_comprobar(int(r2.get("clausula", 0)) > 0, "y le queda una clausula puesta (%d)" % int(r2.get("clausula", 0)))
	## Y no se puede renovar a uno ajeno.
	var ajeno: Jugador = null
	for cl: Club in m.ligas[0].clubes:
		if cl != mio:
			ajeno = cl.plantilla[0]
			break
	_comprobar(m.cantera.renovar(ajeno, false).has("error"), "no se puede renovar a un jugador que no es tuyo")

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
