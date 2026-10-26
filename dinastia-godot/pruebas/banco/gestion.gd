extends "res://pruebas/banco/gestion_p2.gd"
## [Banco · grupo «gestion» · capa 3/3] Generado al partir el banco por grupos (26-10).


func _probar_negociacion() -> void:
	_titulo("LA MESA DE NEGOCIACIÓN")
	var m := Mundo.new()
	m.generar(["CHI", "ARG", "ESP"], 7373)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	mio.mover_saldo(300000000)
	var mk := m.mercado

	## Buscar un objetivo claro: alguien de otro club, no del tuyo.
	var objetivo: Jugador = null
	for c: Club in m.clubes.values():
		if c.id != mio.id and not c.plantilla.is_empty():
			objetivo = c.plantilla[0]
			break
	_comprobar(objetivo != null, "hay un objetivo para negociar")
	if objetivo == null:
		return

	var motivo := mk.abrir_negociacion(objetivo)
	_comprobar(motivo == "", "se abre la mesa (%s)" % motivo)
	_comprobar(mk.negociacion != null, "queda una mesa abierta")
	var n := mk.negociacion
	_comprobar(n.pedido == mk.valor_pedido(objetivo), "el pedido inicial coincide con valor_pedido()")
	_comprobar(n.fijo == int(round(float(n.pedido) * 0.7 / 1000.0)) * 1000, "la oferta fija de salida es el 70% del pedido")

	## Ajustes: pct, sueldo, años, fijo se mueven en la direccion pedida.
	var pct_antes := n.pct
	n.ajustar("pct", 1)
	_comprobar(n.pct == pct_antes + 5, "ajustar pct sube de 5 en 5 (%d -> %d)" % [pct_antes, n.pct])
	n.ajustar("pct", -10)
	_comprobar(n.pct == 0, "pct no baja de 0 (%d)" % n.pct)
	var fijo_antes := n.fijo
	n.ajustar("fijo", 1)
	_comprobar(n.fijo > fijo_antes, "ajustar fijo al alza sube el fijo")
	var anios_antes := n.anios
	n.ajustar("anios", 1)
	_comprobar(n.anios == anios_antes + 1, "ajustar anios suma de a uno")

	## Con una oferta a proposito muy baja, el club pide mas -no cierra a la primera.
	n.fijo = 1000
	n.cuotas = 0; n.bonos = 0; n.pct = 0; n.opaco = 0
	var r1 := n.enviar_oferta()
	_comprobar(String(r1.get("tipo", "")) in ["club_pide_mas", "rival_traspaso", "rota"], "una oferta muy baja no cierra (%s)" % String(r1.get("tipo", "")))
	_comprobar(n.ronda >= 2 or n.estado != "abierta", "la ronda avanza o la mesa se corta")

	## Se abandona y se abre una mesa nueva, esta vez generosa de verdad, hasta
	## que cierre o se agote un limite de intentos -hay azar de por medio: rival
	## que se lleva el fichaje, o el jugador que pide mas rondas-.
	mk.cerrar_negociacion()
	_comprobar(mk.negociacion == null, "cerrar_negociacion vacía la mesa")

	var cerrado := false
	var intentos_apertura := 0
	while not cerrado and intentos_apertura < 12:
		intentos_apertura += 1
		## Otro objetivo cada vez, por si el anterior quedo con "no_negociar_hasta"
		## o se lo llevo un rival.
		var obj2: Jugador = null
		for c2: Club in m.clubes.values():
			if c2.id != mio.id and not c2.plantilla.is_empty():
				var candidato: Jugador = c2.plantilla[Azar.ent(0, c2.plantilla.size() - 1)]
				if candidato.club_id != mio.id and (candidato.no_negociar_hasta == 0 or m.semana >= candidato.no_negociar_hasta):
					obj2 = candidato
					break
		if obj2 == null:
			break
		if mk.abrir_negociacion(obj2) != "":
			continue
		var n2 := mk.negociacion
		## Oferta generosa: fijo por encima del pedido, ficha por encima de lo
		## que pediria, prima de cuatro semanas -respuestaDelJugador() la exige
		## para dar puntos extra-, y un contrato de tres temporadas.
		n2.fijo = int(float(n2.pedido) * 1.05)
		n2.sueldo = int(float(n2.sueldo) * 1.5)
		n2.firma = n2.sueldo * 5
		for intento_ronda in 8:
			var res := n2.enviar_oferta()
			var tipo := String(res.get("tipo", ""))
			if tipo == "cerrado":
				cerrado = true
				var jugador_fichado := obj2
				_comprobar(jugador_fichado.club_id == mio.id, "el fichado pasa a ser tuyo")
				_comprobar(mio.plantilla.has(jugador_fichado), "aparece en tu plantilla")
				_comprobar(m.vestuario.rol_plantel(jugador_fichado) == n2.rol, "el rol pactado queda escrito en Vestuario")
				_comprobar(jugador_fichado.anios_contrato == n2.anios, "los anios pactados quedan escritos")
				break
			elif tipo in ["rota", "rival_traspaso", "rival_firma", "jugador_rota", "cerrada"]:
				break
			## club_pide_mas o jugador_no: se sigue insistiendo con la misma oferta generosa.
	_comprobar(cerrado, "una oferta generosa termina cerrando un fichaje en un numero razonable de intentos")

	## Cuotas, bonos, porcentaje y clausula: se pactan de verdad a traves de
	## Cesiones.registrar_compromisos(), no con una copia propia de esa logica.
	var obj3: Jugador = null
	for c3: Club in m.clubes.values():
		if c3.id != mio.id and not c3.plantilla.is_empty():
			obj3 = c3.plantilla[0]
			break
	if obj3 != null and mk.abrir_negociacion(obj3) == "":
		var n3 := mk.negociacion
		n3.fijo = int(float(n3.pedido) * 1.1)
		n3.cuotas = 500000
		n3.bonos = 300000
		n3.pct = 20
		n3.clausula = true
		n3.sueldo = int(float(n3.sueldo) * 1.6)
		n3.firma = n3.sueldo * 5
		var cerrado3 := false
		for intento3 in 10:
			var res3 := n3.enviar_oferta()
			var tipo3 := String(res3.get("tipo", ""))
			if tipo3 == "cerrado":
				cerrado3 = true
				var hay_cuota := false
				for cu: Dictionary in m.cesiones.cuotas:
					if String(cu.get("jugador", "")) == obj3.nombre:
						hay_cuota = true
				_comprobar(hay_cuota, "las cuotas pactadas quedan registradas en Cesiones")
				_comprobar(m.cesiones.bonos.has(obj3.id), "el bono pactado queda registrado en Cesiones")
				_comprobar(m.cesiones.clausula_de(obj3) > 0, "la clausula pactada queda registrada en Cesiones")
				var pend := m.cesiones.porcentaje_pendiente(obj3.id)
				_comprobar(not pend.is_empty() and int(pend.get("pct", 0)) == 20, "el 20%% de venta futura queda pactado en Cesiones")
				## Cesiones.movimiento lleva escrito desde hace tiempo y nadie lo
				## escuchaba: se conecta ahora en tomar_el_mando(), directo al
				## libro de Mundo -sin pantalla de por medio-.
				_comprobar(not m.libro_financiero.is_empty(), "los pagos de la mesa quedan anotados en el libro financiero (%d)" % m.libro_financiero.size())
				break
			elif tipo3 in ["rota", "rival_traspaso", "rival_firma", "jugador_rota", "cerrada"]:
				break
		if not cerrado3:
			_linea("  (esta mesa en particular no cerro por azar -rival o jugador-, no se prueban cuotas/bonos/pct/clausula esta vez)")

func _probar_economia() -> void:
	_titulo("ECONOMIA (las curvas del HTML, sin retocar)")
	## El valor es exponencial sobre la media, no lineal: es lo que hace que
	## fichar a un 90 sea una decision de club y no una compra mas.
	var valores := {}
	for ovr in [60, 70, 80, 90]:
		var j := Jugador.new()
		j.ovr = ovr
		j.pot = ovr
		j.edad = 26
		j.anios_contrato = 3
		j.tasar()
		valores[ovr] = j.valor
		_linea("  media %d -> valor %s, sueldo %s" % [ovr, _dinero(j.valor), _dinero(j.sueldo)])
	_comprobar(valores[70] > valores[60] * 2, "de 60 a 70 el valor mas que se duplica")
	_comprobar(valores[80] > valores[70] * 2, "de 70 a 80 el valor mas que se duplica")
	_comprobar(valores[90] > valores[80] * 2, "de 80 a 90 el valor mas que se duplica")
	## La edad manda: el mismo 78 no vale lo mismo a los 19 que a los 34.
	var joven := Jugador.new(); joven.ovr = 78; joven.pot = 90; joven.edad = 19; joven.anios_contrato = 4; joven.tasar()
	var viejo := Jugador.new(); viejo.ovr = 78; viejo.pot = 78; viejo.edad = 34; viejo.anios_contrato = 4; viejo.tasar()
	_linea("  mismo 78: a los 19 vale %s, a los 34 vale %s" % [_dinero(joven.valor), _dinero(viejo.valor)])
	_comprobar(joven.valor > viejo.valor * 4, "la joya de 19 vale mucho mas que el veterano de 34")
	## Y la caja de los clubes tambien es exponencial sobre la reputacion.
	_linea("  caja de referencia: rep 60 -> %s | rep 70 -> %s | rep 88 -> %s" % [
		_dinero(int(Eco.ref_caja(60))), _dinero(int(Eco.ref_caja(70))), _dinero(int(Eco.ref_caja(88)))])
	_comprobar(Eco.ref_caja(88) > Eco.ref_caja(70) * 5.0, "un grande maneja mucha mas caja que uno medio")

## M-237 (20-10): sin capitán, el vestuario vota la cinta.
func _probar_capitan_votado() -> void:
	_titulo("M-237: EL VESTUARIO VOTA AL CAPITÁN")
	var m := Mundo.new()
	m.generar(["CHI"], 3737)
	var c: Club = m.ligas[0].clubes[0]
	m.tomar_el_mando(c.id)
	for j: Jugador in c.plantilla:
		j.capitan = false
	var noticias: Array = []
	m.vestuario.noticia.connect(func(t: String, b: String) -> void: noticias.append([t, b]))
	var v := m.vestuario.votar_capitan(c)
	var g: Jugador = v.get("ganador")
	var suma := 0
	for n: int in (v["votos"] as Dictionary).values():
		suma += n
	_comprobar(g != null and suma == c.plantilla.size(), "votan todos (%d votos) y sale un ganador" % suma)
	var mas_jovenes := 0
	for j: Jugador in c.plantilla:
		if j.edad < g.edad:
			mas_jovenes += 1
	_comprobar(mas_jovenes * 2 >= c.plantilla.size(), "gana alguien con peso: %s, %d años (mayor que la mitad del plantel)" % [g.nombre, g.edad])
	m.vestuario.semana(1)
	var capitanes := c.plantilla.filter(func(j: Jugador) -> bool: return j.capitan)
	_comprobar(capitanes.size() == 1, "tras la semana hay exactamente un capitán")
	_comprobar(noticias.any(func(x: Array) -> bool: return String(x[0]).contains("capitán")), "y sale la noticia de la votación")
	m.vestuario.semana(2)
	_comprobar(c.plantilla.filter(func(j: Jugador) -> bool: return j.capitan).size() == 1, "con capitán ya no se vuelve a votar")

## M-335 (20-10): la letra del juego tiene TODOS los caracteres que usan las
## traducciones (ą ł ż del polaco, ğ ş ı İ del turco, ç à del catalán...). Una
## letra que falta sale como un cuadrado vacío.
## M-331 (20-10): con las bolsas de nombres por país, un mundo no se llena de
## tocayos. Se mide cuántos nombres completos se repiten en tres ligas.
## M-059 y M-062 (20-10): en un mundo grande, ninguna marca de patrocinio sale
## más del doble de la media, y los escudos (forma + dibujo + colores + iniciales
## o símbolo) no se repiten entre clubes.
## M-175 (20-10): de noche los coches llevan faros y se avivan al frenar.
func _probar_piel_por_pais() -> void:
	_titulo("PIEL Y PELO SEGÚN EL PAÍS (jugadores inventados)")
	var medias := {}
	var rubios := {}
	for pais: String in ["GER", "BRA", "JPN", "RSA"]:
		var suma := 0.0
		var rub := 0
		for k in 400:
			var j := Jugador.new()
			j.id = "pp_%s_%d" % [pais, k]
			j.pais = pais
			j.edad = 24
			var l := Cara.look_de(j)
			suma += float(Cara.PIELES.find(String(l["piel"])))
			if String(l["peloC"]) in ["#c8a05a", "#8a6a3a"]:
				rub += 1
		medias[pais] = suma / 400.0
		rubios[pais] = rub
	_comprobar(float(medias["GER"]) < float(medias["BRA"]) and float(medias["BRA"]) < float(medias["RSA"]), "la piel sigue el país: GER %.1f < BRA %.1f < RSA %.1f (índice de tono)" % [medias["GER"], medias["BRA"], medias["RSA"]])
	_comprobar(int(rubios["GER"]) > 40 and int(rubios["JPN"]) == 0, "rubios: %d de 400 en GER, %d en JPN" % [rubios["GER"], rubios["JPN"]])
	_comprobar(float(medias["BRA"]) > 1.5 and float(medias["BRA"]) < 6.0, "y dentro de un país hay variedad (BRA de media %.1f)" % medias["BRA"])


func _probar_contratos_c9() -> void:
	_titulo("C9: CONTRATOS Y JORNADA LABORAL")
	_comprobar(Contratos.JORNADA.size() == 24, "los 24 países tienen su jornada legal")
	## Chile: 44 horas hasta el 26 de abril de 2026, 42 después, 40 en 2028.
	var sem_marzo := 8
	var sem_junio := 20
	_comprobar(Contratos.horas("CHI", 2026, sem_marzo) == 44 and Contratos.horas("CHI", 2026, sem_junio) == 42, "Chile pasa de 44 a 42 horas en abril de 2026")
	_comprobar(Contratos.horas("CHI", 2028, sem_junio) == 40, "y llega a 40 en 2028")
	_comprobar(Contratos.horas("COL", 2026, sem_junio) == 44 and Contratos.horas("COL", 2026, 30) == 42, "Colombia baja a 42 en julio de 2026")
	_comprobar(Contratos.horas("FRA", 2026, 10) == 35 and Contratos.horas("MEX", 2026, 10) == 48, "Francia 35, México 48")
	_comprobar(Contratos.factor_estructura("FRA", 2026, 10) > 1.0 and Contratos.factor_estructura("MEX", 2026, 10) < 1.0, "menos horas legales, estructura más cara")
	var m := Mundo.new()
	m.generar(["CHI"], 5154)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	var j := c.plantilla[0]
	j.edad = 17
	_comprobar(Contratos.ajustar_anios(j, 5) == 3, "un menor de 18 no firma por más de 3 años (FIFA)")
	j.edad = 25
	_comprobar(Contratos.ajustar_anios(j, 7) == 5 and Contratos.ajustar_anios(j, 0) == 1, "entre 1 y 5 años para el resto")
	var noticias: Array = []
	m.contratos.noticia.connect(func(t: String, _b: String) -> void: noticias.append(t))
	for s in range(1, 30):
		m.contratos.semana(c, 2026, s)
	_comprobar(noticias.size() == 1, "el cambio de jornada de abril sale una vez en las noticias")
	var jugadores_menores := 0
	for cl: Club in m.clubes.values():
		for x: Jugador in cl.plantilla:
			if x.edad < 18 and x.anios_contrato > 3:
				jugadores_menores += 1
	_comprobar(jugadores_menores == 0, "ningún menor del mundo generado tiene más de 3 años de contrato")

## LAS REGLAS DE CADA PAÍS (7-10-2026): cada club con las de su liga.
func _jug_ley(id: String, pais: String, pos: String, ovr: int, edad: int = 26) -> Jugador:
	var j := Jugador.new()
	j.id = id
	j.nombre = id
	j.pais = pais
	j.pos = pos
	j.pos_e = {"POR": "POR", "DEF": "DFC", "MED": "MC", "DEL": "DC"}[pos]
	j.ovr = ovr
	j.edad = edad
	return j

func _probar_leyes_pais() -> void:
	_titulo("LEYES POR PAÍS: CUPOS Y JUVENILES SEGÚN LA LIGA DEL CLUB")
	## Chile: 6 extranjeros en el plantel, 5 en cancha y un sub-21 en el once.
	var c := Club.new("chi_test", "Prueba CHI")
	c.pais = "CHI"
	var lineas := ["POR", "DEF", "DEF", "DEF", "DEF", "MED", "MED", "MED", "DEL", "DEL", "DEL"]
	for k in 11:
		c.plantilla.append(_jug_ley("e%d" % k, "ARG" if k < 7 else "CHI", lineas[k], 80 if k < 7 else 70))
	for k in 6:
		c.plantilla.append(_jug_ley("b%d" % k, "CHI", lineas[(k % 10) + 1], 65, 19 if k == 0 else 27))
	for j: Jugador in c.plantilla:
		j.club_id = c.id
	var once := c.once()
	var de_fuera := 0
	var sub21 := false
	for j: Jugador in once:
		if j.pais != "CHI":
			de_fuera += 1
		if j.edad <= 21:
			sub21 = true
	_comprobar(once.size() == 11 and de_fuera <= 5 and sub21, "Chile: once con %d extranjeros (máx. 5) y sub-21 = %s" % [de_fuera, sub21])
	_comprobar(LeyesPais.motivo_fichaje(c, _jug_ley("nuevo", "URU", "DEL", 75)) != "", "Chile: con 7 extranjeros no se ficha otro")
	_comprobar(LeyesPais.motivo_fichaje(c, _jug_ley("local", "CHI", "DEL", 75)) == "", "Chile: un chileno siempre cabe")
	## España: cuentan los extracomunitarios, no los europeos.
	var e := Club.new("esp_test", "Prueba ESP")
	e.pais = "ESP"
	for k in 3:
		e.plantilla.append(_jug_ley("br%d" % k, "BRA", "MED", 75))
	_comprobar(LeyesPais.motivo_fichaje(e, _jug_ley("arg", "ARG", "DEL", 75)) != "", "España: el cuarto extracomunitario no entra")
	_comprobar(LeyesPais.motivo_fichaje(e, _jug_ley("fra", "FRA", "DEL", 75)) == "", "España: un francés no ocupa cupo")
	## Brasil: sin tope en el plantel, 9 en cancha.
	var b := Club.new("bra_test", "Prueba BRA")
	b.pais = "BRA"
	for k in 12:
		b.plantilla.append(_jug_ley("x%d" % k, "URU", "MED", 75))
	_comprobar(LeyesPais.motivo_fichaje(b, _jug_ley("otro", "ARG", "DEL", 75)) == "", "Brasil: sin tope de extranjeros en el plantel")
	## Cada liga tiene su resumen para la pantalla de Federación.
	_comprobar(LeyesPais.resumen("MEX").size() >= 3 and LeyesPais.resumen("ZZZ").is_empty(), "resumen de reglas por país")
	var sin_ley := 0
	for p in ["CHI", "ARG", "BRA", "URU", "PAR", "PER", "ECU", "COL", "VEN", "BOL", "ESP", "ENG", "ITA", "GER", "FRA", "JPN", "KOR", "KSA", "EGY", "MAR", "RSA", "AUS", "MEX", "USA"]:
		if LeyesPais.reglas(p).is_empty() or not Contratos.JORNADA.has(p):
			sin_ley += 1
	_comprobar(sin_ley == 0, "los 24 países del juego tienen reglas de liga y jornada (%d sin)" % sin_ley)

## INCUMPLIR LA LEY SE PAGA (7-10-2026): multas que crecen y, desde la
## tercera alineación indebida, puntos menos.
func _probar_incumplir_ley() -> void:
	_titulo("LEYES POR PAÍS: INCUMPLIR A CAMBIO DE MULTAS")
	var m := Mundo.new()
	m.generar(["CHI"], 7311)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mi := m.mi_club()
	mi.saldo = 500000000
	## Seis extranjeros en el once elegido (Chile permite 5 en cancha).
	var once := mi.once()
	var ids: Array[String] = []
	for k in once.size():
		if k >= 1 and k <= 7:
			once[k].pais = "ARG"
		ids.append(once[k].id)
	mi.once_elegido = ids
	var cuenta := 0
	for j: Jugador in mi.once():
		if j.pais != "CHI":
			cuenta += 1
	_comprobar(cuenta <= 5, "cumpliendo, el once se corrige solo (%d extranjeros)" % cuenta)
	mi.ley_politica = "incumplir"
	var cuenta2 := 0
	for j: Jugador in mi.once():
		if j.pais != "CHI":
			cuenta2 += 1
	var elegido := 0
	for k in once.size():
		if once[k].pais != "CHI":
			elegido += 1
	_comprobar(cuenta2 == elegido and cuenta2 > 5, "incumpliendo, sale el once que elegiste (%d extranjeros)" % cuenta2)
	var liga: Liga = null
	for l: Liga in m.ligas:
		if l.clubes.has(mi):
			liga = l
	var pts0 := int(liga.tabla_puntos[mi.id]["pts"])
	var s0 := mi.saldo
	m.federacion.revisar_leyes_pais(m, mi)
	var multa1 := s0 - mi.saldo
	m.federacion.revisar_leyes_pais(m, mi)
	var multa2 := s0 - mi.saldo - multa1
	m.federacion.revisar_leyes_pais(m, mi)
	_comprobar(multa1 > 0 and multa2 > multa1, "la multa crece al reincidir (%d → %d)" % [multa1, multa2])
	_comprobar(int(liga.tabla_puntos[mi.id]["pts"]) == pts0 - 3, "a la tercera alineación indebida, 3 puntos menos")
	_comprobar(int(m.federacion.infracciones_de(m.anio)["alin"]) == 3, "las infracciones se cuentan por temporada")
	## Plantel: incumpliendo se puede fichar por encima del cupo.
	var j_ext := Jugador.new()
	j_ext.pais = "BRA"
	_comprobar(m.federacion.puede_fichar_extranjero(mi, j_ext) == "", "incumpliendo, el mercado te deja pasarte del cupo")
	mi.ley_politica = "cumplir"
	_comprobar(m.federacion.puede_fichar_extranjero(mi, j_ext) != "", "cumpliendo, no (7 extranjeros, cupo 6)")
	mi.ley_politica = "incumplir"
	_comprobar(Partida._dic_a_club(Partida._club_a_dic(mi)).ley_politica == "incumplir", "la política se guarda con la partida")
