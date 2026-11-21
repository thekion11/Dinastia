extends "res://pruebas/banco/base.gd"
## [Banco · grupo «ruta_ciclo»] La Ruta jugada COMO LA JUEGA LA INTERFAZ (16-11, informe AAA cap. 7): la carrera por
## JSON de verdad (no un diccionario en memoria), la semana en el orden de la pantalla (retos → avanzar el mundo →
## tras_partido), una temporada entera hasta el arranque de la siguiente con el futbolista vivo, los premios contra un
## rival mejor (no se ganan) y los cambios de club. Cada caso en otro país, otro club y otro puesto.

func _nueva(paises: Array, puesto: String, semilla: int, cual := 1) -> Array:
	var m := Mundo.new()
	var lista: Array[String] = []
	lista.assign(paises)
	m.generar(lista, semilla)
	m.mi_club_id = ""
	var c := CarreraJugador.crear(m, "Prueba Ciclo", puesto, false, semilla)
	m.carrera_jugador = c
	var of := CarreraComienzo.pruebas(m, semilla)
	CarreraComienzo.mudar(c, m, of[cual % of.size()])
	return [m, c]

## La semana simulada, en el orden de `CarreraJugadorUI._cerrar_semana` (con nota fija: el banco no tira dados).
func _semana(c: CarreraJugador, m: Mundo, nota := 7.0) -> Dictionary:
	var j := c.jugador(m)
	while not c.eventos.is_empty():
		c.resolver(m, 0, c.eventos[0]["opciones"].size() - 1)   ## la última opción: la más tranquila (no te cede ni te lleva fuera)
	c.foco = "descanso" if c.energia < 40 else c.foco
	c.entrenar(m)
	var titular := c.es_titular(m)
	var antes := CarreraSemana.foto(j)
	var previo: Variant = CarreraSemana.meter_en_el_once(c, m) if titular else null
	var retos: Array = CarreraRuta.retos(c, m).duplicate(true)
	var semana_retos := int(c.ruta["retos_semana"])
	m.avanzar_semana(null)
	CarreraSemana.soltar_once(c, m, previo)
	var dm := CarreraSemana.lo_del_mundo(j, antes)
	if titular:
		c.tras_partido(m, {"minutos": 90, "goles": int(dm["goles"]), "asist": int(dm["asist"]), "nota": nota, "titular": true,
			"encajados": 1, "en_mundo": dm["en_mundo"]})
	c.semana(m)
	return {"titular": titular, "retos": retos, "semana_retos": semana_retos, "dm": dm, "previo": previo, "antes": antes}

func _suma_notas(m: Mundo) -> Vector2:
	var t := Vector2.ZERO
	for cl: Club in m.clubes.values():
		for o: Jugador in cl.plantilla:
			t += o.nota_temp
	return t

## IDA Y VUELTA POR JSON: lo que se guarda vuelve con su tipo (enteros como enteros), y seguir o «cargar y seguir» dan lo mismo.
func _probar_ruta_ida_vuelta_json() -> void:
	_titulo("LA RUTA POR JSON (guardar, cargar y seguir: lo mismo)")
	for caso: Array in [[["FRA", "ARG", "ENG"], "MC", 41], [["ITA", "BRA", "GER"], "POR", 52]]:
		_ida_vuelta_caso(caso)

## Un caso de ida y vuelta (una carrera por JSON, ya cargada y jugada en los dos mundos).
func _ida_vuelta_caso(caso: Array) -> void:
	var par := _nueva(caso[0], String(caso[1]), int(caso[2]))
	var m: Mundo = par[0]
	var c: CarreraJugador = par[1]
	for _i in 5:
		_semana(c, m)
	c.stats_temp["vallas"] = 2
	if m.copa != null:
		m.ajustes_competicion["copa_sede"] = c.club(m).id
		m.copa.sede_final_id = c.club(m).id
	var foto: Dictionary = JSON.parse_string(JSON.stringify(Partida.instantanea(m)))
	var m2 := Partida.desde_instantanea(foto)
	var c2: CarreraJugador = m2.carrera_jugador if m2 != null else null
	_comprobar(c2 != null and c2.jugador(m2) != null, "%s en %s: la carrera vuelve del JSON con su futbolista" % [caso[1], c.club(m).nombre])
	if c2 == null:
		return
	var tipos := true
	for k: String in ["pj", "titular", "goles", "asist", "vallas"]:
		tipos = tipos and typeof(c2.stats_temp[k]) == TYPE_INT and int(c2.stats_temp[k]) == int(c.stats_temp[k])
	_comprobar(tipos and is_equal_approx(c2.nota_media(), c.nota_media()), "  partidos, goles, asistencias y porterías de la temporada vuelven enteros (%d pj, %d goles)" % [int(c2.stats_temp["pj"]), int(c2.stats_temp["goles"])])
	_comprobar(_suma_notas(m2).is_equal_approx(_suma_notas(m)) and _suma_notas(m).y > 0.0, "  la nota de la temporada de todo el mundo vuelve igual (R-03: %d partidos con nota)" % int(_suma_notas(m).y))
	_comprobar(m2._entreno_mundo != null and m._entreno_mundo != null and m2._entreno_mundo._subidas == m._entreno_mundo._subidas,
		"  el entrenamiento del mundo vuelve con su tope de subidas (G-04: %d con subidas)" % (m._entreno_mundo._subidas.size() if m._entreno_mundo != null else -1))
	_comprobar(m.copa == null or (m2.copa != null and m2.copa.sede_final_id == m.copa.sede_final_id and m2.ajustes_competicion == m.ajustes_competicion),
		"  la sede de la final y los ajustes de competición vuelven también en La Ruta (G-03)")
	## Seguir en los dos mundos: el original y el cargado juegan la misma semana.
	Azar._rng.state = int(String(foto["azar"]))   ## el azar es global: cada mundo sigue desde el mismo estado
	m.avanzar_semana(null)
	Azar._rng.state = int(String(foto["azar"]))
	m2.avanzar_semana(null)
	var g1 := 0
	var g2 := 0
	for cl: Club in m.clubes.values():
		for o: Jugador in cl.plantilla:
			g1 += o.goles * 7 + o.ovr
	for cl2: Club in m2.clubes.values():
		for o2: Jugador in cl2.plantilla:
			g2 += o2.goles * 7 + o2.ovr
	var dif: Array = []
	for cl4: Club in m.clubes.values():
		var cl5: Club = m2.clubes.get(cl4.id)
		for o4: Jugador in cl4.plantilla:
			var o5: Jugador = null
			for x: Jugador in (cl5.plantilla if cl5 != null else []):
				if x.id == o4.id:
					o5 = x
			if dif.size() < 4 and (o5 == null or o5.goles != o4.goles or o5.ovr != o4.ovr):
				dif.append("%s %s %d/%d g%d/%d" % [cl4.nombre, o4.nombre, o4.ovr, o5.ovr if o5 else -1, o4.goles, o5.goles if o5 else -1])
	_comprobar(g1 == g2, "  seguir o cargar y seguir dan la misma semana (%d / %d) %s" % [g1, g2, str(dif)])

## UNA SEMANA EN EL ORDEN DE LA INTERFAZ: los retos que viste son los que se juegan, y el partido se anota UNA vez.
func _probar_ruta_semana_interfaz() -> void:
	_titulo("LA SEMANA DE LA RUTA COMO LA JUEGA LA PANTALLA")
	for caso: Array in [[["ESP", "CHI", "ITA"], "DC", 63], [["GER", "ARG", "FRA"], "DFC", 74]]:
		var par := _nueva(caso[0], String(caso[1]), int(caso[2]), 0)
		var m: Mundo = par[0]
		var c: CarreraJugador = par[1]
		var j := c.jugador(m)
		var cl := c.club(m)
		c.relacion_dt = 100
		c.energia = 100
		## Que la carrera te dé titular aunque el once automático no te lleve (R-05): se baja tu nivel hasta que el once te deja fuera.
		var forzado := false
		for _k in 30:
			if c.es_titular(m) and not cl.once().has(j):
				forzado = true
				break
			var guardados := j.atributos.duplicate()
			var ovr_g := j.ovr
			for z: String in j.atributos:
				j.atributos[z] = maxi(30, int(j.atributos[z]) - 1)
			j.ovr = j.media_en(j.pos_e)
			if not c.es_titular(m):
				j.atributos = guardados
				j.ovr = ovr_g
				break
		var pj0 := j.partidos
		var n0 := j.nota_temp.y
		var w := _semana(c, m)
		var ultimo: Dictionary = c.ruta.get("ultimo", {})
		var ids_vistos := (w["retos"] as Array).map(func(r: Dictionary) -> String: return String(r["id"]))
		var ids_jugados := (ultimo.get("retos", []) as Array).map(func(r: Dictionary) -> String: return String(r["id"]))
		_comprobar(bool(w["titular"]) and ids_vistos == ids_jugados and int(ultimo.get("semana_retos", -1)) == int(w["semana_retos"]),
			"%s en %s: los retos que viste antes de jugar son los que se cobran (R-02)" % [caso[1], cl.nombre])
		_comprobar(int(c.stats_temp["pj"]) == 1 and j.partidos - pj0 == 1 and is_equal_approx(j.nota_temp.y - n0, 1.0),
			"  el partido cuenta UNA vez en tu carrera y en tu ficha del mundo (R-05: %d partido(s), %d nota(s))" % [j.partidos - pj0, int(j.nota_temp.y - n0)])
		_comprobar(not forzado or bool((w["dm"] as Dictionary)["en_mundo"]), "  titular para la carrera = en el once del simulado (R-05, forzado: %s)" % str(forzado))
		_comprobar(cl.once_elegido.is_empty(), "  y después el club vuelve a su once automático")
		_comprobar(int(c.stats_temp["goles"]) == int((w["dm"] as Dictionary)["goles"]) and int(c.stats_temp["asist"]) == int((w["dm"] as Dictionary)["asist"]),
			"  tus goles y asistencias son los del simulado (%d y %d; las asistencias antes llegaban a 0)" % [int(c.stats_temp["goles"]), int(c.stats_temp["asist"])])
		## Un llamador que NO fija los retos antes (retos viejos de otra semana): se usan los de hoy, no los viejos ya cumplidos.
		c.ruta["retos_semana"] = int(c.ruta["retos_semana"]) - 7
		for r: Dictionary in c.ruta["retos"]:
			r["hecho"] = true
		c.tras_partido(m, {"minutos": 90, "goles": 3, "asist": 2, "nota": 9.0, "titular": true})
		_comprobar(int((c.ruta["ultimo"] as Dictionary)["semana_retos"]) == m.anio * 60 + m.semana, "  sin la llamada previa, los retos del partido son los de la semana, no unos viejos")

## UNA TEMPORADA ENTERA y el arranque de la siguiente, con el futbolista vivo.
func _probar_ruta_temporada_completa() -> void:
	_titulo("UNA TEMPORADA DE LA RUTA, DE PRINCIPIO A FIN")
	var par := _nueva(["ENG", "BRA", "ESP"], "ED", 85, 2)
	var m: Mundo = par[0]
	var c: CarreraJugador = par[1]
	var tope := 80
	while m.temporada_en_curso() and tope > 0:
		tope -= 1
		_semana(c, m, 7.2)
	var j := c.jugador(m)
	var pj := int(c.stats_temp["pj"])
	_comprobar(tope > 0 and j != null, "la temporada termina y el futbolista sigue en %s" % (c.club(m).nombre if c.club(m) != null else "—"))
	_comprobar(pj > 5 and j.partidos < 2 * pj + 4, "  la ficha del mundo no cuenta tus partidos dos veces (%d en la carrera, %d en el mundo)" % [pj, j.partidos])
	CarreraSemana.cerrar_temporada(c, m)
	_comprobar(not CierreTorneos.hay_pendientes(m), "  la copa y el continental a medias se cierran ANTES de tus premios (R-09)")
	_comprobar(CarreraPremios.pendiente(c) and int((c.ruta["temporada"] as Dictionary)["pj"]) == pj, "  el cierre de tu temporada queda para enseñarlo (%s)" % str((c.ruta["temporada"] as Dictionary)["premios"]))
	var notas_fin := _suma_notas(m).y
	m.nueva_temporada()
	var j2 := c.jugador(m)
	_comprobar(j2 != null and j2 == j and c.club(m) != null and m.temporada_en_curso(), "  arranca la temporada siguiente y sigues siendo tú (%d años)" % (j2.edad if j2 != null else -1))
	_comprobar(int(c.stats_temp["pj"]) == 0 and int(c.stats_temp["vallas"]) == 0 and _suma_notas(m).y < notas_fin * 0.02,
		"  la temporada nueva empieza de cero (tuya, y la nota de todo el mundo: %d de %d, las supercopas del arranque)" % [int(_suma_notas(m).y), int(notas_fin)])
	var w := _semana(c, m)
	_comprobar(int(c.stats_temp["pj"]) == (1 if bool(w["titular"]) else 0), "  y la primera semana de la siguiente se juega sin problemas")
	## Retirado, el mundo ya no lo protege (revisión de R-01).
	c.retirado = true
	j2.edad = 39
	m.nueva_temporada()
	_comprobar(c.jugador(m) == null, "  ya retirado, el mundo deja de protegerlo y se va con 40 años (revisión de R-01)")
	c.retirado = false

## PREMIOS QUE SE DISPUTAN: con un rival mejor, no se ganan (y sin él, sí). Fama de los premios sin freno, duelo doble, economía de puntos.
func _probar_ruta_premios_rivales() -> void:
	_titulo("LOS PREMIOS DE LA RUTA CONTRA UN RIVAL MEJOR")
	var ganancia := {}
	for caso: Array in [[["ARG", "ITA", "FRA"], "DC", 96], [["BRA", "ESP", "GER"], "POR", 107]]:
		var par := _nueva(caso[0], String(caso[1]), int(caso[2]))
		var m: Mundo = par[0]
		var c: CarreraJugador = par[1]
		var j := c.jugador(m)
		var club := c.club(m)
		var liga := CarreraRuta._liga_de(m, club)
		for cl: Club in m.clubes.values():
			for o: Jugador in cl.plantilla:
				o.nota_temp = Vector2.ZERO
				o.goles = 0
				o.asistencias = 0
		j.ovr = 90
		c.temporadas = [{"anio": 1}]   ## no es la primera temporada (sin «Revelación»)
		var notas: Array = []
		for _i in 30:
			notas.append(8.0)
		c.stats_temp = {"pj": 30, "titular": 30, "goles": 20, "asist": 12, "notas": notas, "vallas": 12}
		var solo := CarreraPremios.ganados(c, m, false)
		var esperan := ["goleador_club", "mejor_club", "goleador_liga", "asistidor_liga", "mvp_liga", "mundial"] + (["portero_liga", "muro"] if j.es_portero() else [])
		var faltan := esperan.filter(func(id: String) -> bool: return not solo.has(id))
		_comprobar(faltan.is_empty(), "%s en %s: sin nadie mejor, los premios se ganan (faltan %s)" % [caso[1], club.nombre, str(faltan)])
		## Un compañero y un rival de otro club de tu liga, mejores que tú en cada cosa.
		var comp: Jugador = null
		for o: Jugador in club.plantilla:
			if o != j and (comp == null or o.es_portero() == j.es_portero()):
				comp = o
		var rival: Jugador = null
		for cl2: Club in liga.clubes:
			for o2: Jugador in (cl2.plantilla if cl2 != club else []):
				if rival == null or (o2.es_portero() == j.es_portero() and not rival.es_portero() == j.es_portero()):
					rival = o2
		comp.goles = 21
		comp.nota_temp = Vector2(8.5 * 20.0, 20.0)
		var con_comp := CarreraPremios.ganados(c, m, false)
		_comprobar(not con_comp.has("goleador_club") and not con_comp.has("mejor_club"), "  con un compañero que marca más y tiene mejor nota: ni goleador ni mejor del club (%s)" % ", ".join(con_comp))
		comp.goles = 0
		comp.nota_temp = Vector2(9.5 * 5.0, 5.0)
		_comprobar(CarreraPremios.ganados(c, m, false).has("mejor_club"), "  uno con 9,5 en solo 5 partidos no compite (pide 10)")
		comp.nota_temp = Vector2.ZERO
		rival.goles = 25
		rival.asistencias = 15
		rival.nota_temp = Vector2(8.6 * 28.0, 28.0)
		var con_rival := CarreraPremios.ganados(c, m, false)
		for id: String in ["goleador_liga", "asistidor_liga", "mvp_liga", "portero_liga", "mundial"]:
			_comprobar(not con_rival.has(id), "  con %s mejor en tu liga, no ganas «%s»" % [rival.nombre, CarreraPremios.PREMIOS[id][0]])
		rival.goles = 0
		rival.asistencias = 0
		rival.nota_temp = Vector2.ZERO
		## El mundial contra alguien de OTRA liga.
		var lejos: Jugador = null
		for cl3: Club in m.clubes.values():
			if not liga.clubes.has(cl3) and not cl3.plantilla.is_empty():
				lejos = cl3.plantilla[0]
				break
		lejos.nota_temp = Vector2(9.2 * 30.0, 30.0)
		lejos.goles = 30
		_comprobar(not CarreraPremios.ganados(c, m, false).has("mundial"), "  con %s (otra liga) mejor que tú, no eres el mejor del mundo" % lejos.nombre)
		lejos.nota_temp = Vector2.ZERO
		lejos.goles = 0
		if j.es_portero():
			c.stats_temp["vallas"] = 3
			c.vallas_invictas = 60
			_comprobar(not CarreraPremios.ganados(c, m, false).has("muro"), "  el Guante pide 10 porterías a cero ESTA temporada, no en la carrera (R-04)")
		## R-07: la fama de los premios no se frena.
		c.fama = 80
		c.ruta["fama_ref"] = 80
		CarreraPremios.fama_entera(c, 10)
		c.stats_temp["notas"] = [7.0]
		CarreraRuta.semana(c, m)
		_comprobar(c.fama >= 89, "  con fama 80, los +10 de un premio se quedan enteros (%d; antes quedaba 81)" % c.fama)
		## R-11: el duelo doble es de una temporada aunque no haya duelo.
		CarreraEventosRuta.aplicar(c, m, {"ruta_marca": "duelo_doble"})
		c.stats_temp["pj"] = 0
		CarreraRuta.cerrar_duelo(c, m)
		_comprobar(not CarreraEventosRuta.tiene_marca(c, "duelo_doble"), "  sin partidos, la marca del duelo doble no pasa a la temporada siguiente (R-11)")
		ganancia[String(caso[1])] = _media_por_puntos(c, m, j)
	var d := float(ganancia.get("DC", 0.0))
	var p := float(ganancia.get("POR", 0.0))
	_comprobar(d > 0.0 and p > 0.0 and p / d > 0.8 and p / d < 1.25, "con los mismos puntos de habilidad, portero y delantero suben la media parecido (R-08: %.2f y %.2f)" % [p, d])

## La media (con decimales) que sube gastando 60 puntos de habilidad a nivel 10 con todo a 65, comprando lo que más rinde.
## Comprueba de paso que +1 de zona cuesta lo mismo tenga la zona 1, 2 o 6 habilidades.
func _media_por_puntos(c: CarreraJugador, m: Mundo, j: Jugador) -> float:
	var e := PesosPuesto.de(j.pos_e)
	var pesos := {}
	for i in (e[0] as PackedStringArray).size():
		pesos[e[0][i]] = e[1][i]
	for z: String in j.atributos:
		j.atributos[z] = 65
	c.ruta.erase("detalle")
	c.ruta["nivel"] = 10
	c.ruta["hab_nivel"] = 10
	var dd := CarreraHabilidad.detalle(c, j)
	for h0: String in dd:
		dd[h0] = 65   ## todas las habilidades a 65: el precio no cambia de tramo a mitad de zona
	## +1 de cada zona comprando una vez cada habilidad suya: lo pagado es el precio de la zona (antes, n veces el de una habilidad).
	var cuadra := true
	var cifras: Array = []
	for z2: String in j.atributos:
		var lista := CarreraHabilidad.de_zona(z2)
		if lista.size() != 1 and lista.size() != 2 and lista.size() != 6:
			continue
		var precio := CarreraHabilidad.precio_zona(c, j, String(lista[0][0]))
		c.ruta["hab"] = 1000
		for par2: Array in lista:
			CarreraHabilidad.subir(c, m, String(par2[0]))
		var pagado := 1000 - CarreraHabilidad.puntos(c)
		cifras.append("%s %d" % [z2, pagado])
		cuadra = cuadra and int(j.atributos[z2]) == 66 and absf(float(pagado) - precio) <= 1.0
	_comprobar(cuadra, "  %s: +1 de zona cuesta su precio de zona, tenga 1, 2 o 6 habilidades (R-08: %s)" % [j.pos_e, ", ".join(cifras)])
	for z6: String in j.atributos:
		j.atributos[z6] = 65
	for h6: String in dd:
		dd[h6] = 65
	c.ruta.erase("pulidos")
	var antes := 0.0
	for z3: String in pesos:
		antes += float(pesos[z3]) * float(j.atributos.get(z3, 0))
	c.ruta["hab"] = 60
	for _i in 200:
		var mejor := ""
		var rinde := 0.0
		for z4: String in pesos:
			for par4: Array in CarreraHabilidad.de_zona(z4):
				var h := String(par4[0])
				var r := float(pesos[z4]) / float(CarreraHabilidad.de_zona(z4).size()) / float(CarreraHabilidad.coste(c, j, h))
				if CarreraHabilidad.puede_subir(c, m, h) and r > rinde:
					rinde = r
					mejor = h
		if mejor == "":
			break
		CarreraHabilidad.subir(c, m, mejor)
	var despues := 0.0
	for z5: String in pesos:
		despues += float(pesos[z5]) * float(CarreraHabilidad._promedio(CarreraHabilidad.detalle(c, j), CarreraHabilidad.de_zona(z5)))
	return despues - antes

## CAMBIOS DE CLUB: cesión con vuelta, sin brazalete al irte, sin fichar donde no cabes, sin ofertas repetidas; la selección
## no mueve el mundo; y los textos con nombres se traducen.
func _probar_ruta_traspasos() -> void:
	_titulo("LA RUTA: CESIÓN, TRASPASO, SELECCIÓN Y TEXTOS")
	var par := _nueva(["ITA", "CHI", "ENG"], "MCO", 118, 2)
	var m: Mundo = par[0]
	var c: CarreraJugador = par[1]
	var j := c.jugador(m)
	var grande := c.club(m)
	for cl0: Club in m.clubes.values():
		if cl0.pais == grande.pais and cl0.rep > grande.rep:
			grande = cl0
	CarreraComienzo.mudar(c, m, grande)   ## del más grande de su país siempre hay a dónde cederte
	var casa := c.club(m)
	c.capitan = true
	c.pj_carrera = 40
	var hay := not CarreraTraspasos.destinos_cesion(c, m).is_empty()
	_comprobar(hay and CarreraTraspasos.ceder(c, m), "cedido desde %s a un club más modesto que te acepta" % casa.nombre)
	if hay:
		_comprobar(c.club(m) != casa and not c.capitan and int(c.ruta["pj_llegada"]) == 40 and CarreraTraspasos.cedido(c), "  cedido a %s: sin brazalete y recién llegado (R-06, R-10)" % c.club(m).nombre)
		c.fin_de_temporada(m)
		_comprobar(c.club(m) == casa and not CarreraTraspasos.cedido(c), "  a final de temporada vuelves a %s (R-06)" % casa.nombre)
	## Un destino sin sitio en el plantel no ficha; una oferta repetida no se ofrece.
	var lleno: Club = null
	for cl: Club in m.clubes.values():
		if cl != casa and cl.pais != casa.pais:
			lleno = cl
			break
	while lleno.plantilla.size() < Cantera.TOPE_PLANTEL:
		lleno.plantilla.append(m.crear_jugador(lleno, "MED", "MC", 25, 60))
	c.ofertas = [{"club_id": lleno.id, "sueldo": 100, "semanas": 3}]
	_comprobar(not c.aceptar_oferta(m, 0) and c.club(m) == casa and c.ofertas.is_empty(), "  %s con el plantel lleno (%d) no te puede fichar (R-14)" % [lleno.nombre, lleno.plantilla.size()])
	var libre: Club = null
	for cl2: Club in m.clubes.values():
		if cl2 != casa and cl2 != lleno and CarreraTraspasos.destino_valido(m, cl2, j):
			libre = cl2
			break
	c.ofertas = [{"club_id": libre.id, "sueldo": 100, "semanas": 3}]
	_comprobar(CarreraTraspasos.filtrar(c, m, j, [libre, lleno]).is_empty(), "  un club que ya te hizo oferta (o que no te cabe) no repite (R-14)")
	c.capitan = true
	_comprobar(c.aceptar_oferta(m, 0) and c.club(m) == libre and not c.capitan, "  fichas por %s y el brazalete se queda en tu club de antes (R-10)" % libre.nombre)
	## La selección no toca el azar ni los ids del mundo (R-13).
	c.convocatoria = {"pais": j.pais, "nombre": "Selección de prueba", "rival": "Croacia"}
	var azar0 := Azar._rng.state
	var seq0: int = m._seq_jugador
	var eq := c.equipos_seleccion(m)
	_comprobar(eq.size() == 2 and Azar._rng.state == azar0 and m._seq_jugador == seq0 and (eq[1] as Club).plantilla.size() >= 11,
		"  los equipos de la selección se arman sin mover el azar ni el contador del mundo (R-13)")
	c.convocatoria = {}
	## Los textos con nombres: se traduce la plantilla y después se ponen los nombres (R-12).
	var antes_i := Idiomas.idioma
	Idiomas.idioma = "en"
	var ev := c._ev("x", "Vuelves a %s", "Un periodista te pregunta si te ves de titular en %s.", [], false, {"titulo_datos": [libre.nombre], "texto_datos": [libre.nombre]})
	var tit := CarreraEventosRuta.texto(ev, "titulo")
	var txt := CarreraEventosRuta.texto(ev, "texto")
	_comprobar(tit.contains(libre.nombre) and not tit.begins_with("Vuelves") and txt.contains(libre.nombre) and not txt.begins_with("Un periodista"),
		"  en inglés, «%s» y «%s»" % [tit, txt])
	Idiomas.idioma = antes_i
