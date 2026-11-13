extends "res://pruebas/banco/base.gd"
## [Banco · grupo «ruta»] «La Ruta», el modo jugador nuevo (13-11): núcleo y guardado.

func rv_club(m: Mundo, o: Jugador) -> Club:
	return m.clubes.get(o.club_id)

## «LA RUTA» DEL MODO JUGADOR (13-11): nivel, talentos, retos, racha, rival,
## toque del entreno y el club elegido al empezar. Con tres países y puestos.
func _probar_carrera_ruta() -> void:
	_titulo("LA RUTA DEL MODO JUGADOR (nivel, talentos, retos, racha y rival)")
	for caso: Array in [[["ARG", "ESP", "ITA"], "DC", 11], [["GER", "BRA", "FRA"], "DFC", 22], [["ENG", "CHI", "ESP"], "POR", 33]]:
		var m := Mundo.new()
		var lista: Array[String] = []
		lista.assign(caso[0])
		m.generar(lista, int(caso[2]))
		m.mi_club_id = ""
		var c := CarreraJugador.crear(m, "Prueba Ruta", String(caso[1]), false, int(caso[2]))
		m.carrera_jugador = c
		var ofertas := CarreraComienzo.pruebas(m, int(caso[2]))
		var paises := {}
		for cl: Club in ofertas:
			paises[cl.pais] = true
		_comprobar(ofertas.size() == 3 and paises.size() == 3, "%s: tres clubes de tres países te ofrecen contrato" % caso[1])
		CarreraComienzo.mudar(c, m, ofertas[2])
		var j := c.jugador(m)
		_comprobar(c.club(m) == ofertas[2] and j.pais == ofertas[2].pais, "  empiezas en el club elegido (%s, %s)" % [ofertas[2].nombre, ofertas[2].pais])
		var rv := CarreraRuta.rival(c, m)
		_comprobar(rv != null and rv.pos == j.pos and rv.club_id != j.club_id, "  tu rival es de tu línea y de otro club de tu liga")
		var retos := CarreraRuta.retos(c, m)
		_comprobar(retos.size() == 3 and CarreraRuta.retos(c, m) == retos, "  tres retos por semana, y no cambian al volver a mirar")
		for reto: Dictionary in retos:
			_comprobar((CarreraRuta.RETOS[String(reto["id"])][2] as Array).has(j.pos), "  el reto «%s» es de tu línea" % CarreraRuta.RETOS[String(reto["id"])][0])
		## Un partidazo: cumple lo que se pueda y da experiencia.
		var antes_nivel := CarreraRuta.nivel(c)
		c.tras_partido(m, {"minutos": 90, "goles": 3, "asist": 1, "nota": 8.6, "titular": true, "encajados": 0, "paradas": 5})
		var ult: Dictionary = c.ruta["ultimo"]
		var hechos := 0
		for h: Dictionary in ult["retos"]:
			hechos += 1 if bool(h["hecho"]) else 0
		_comprobar(hechos == 3 and int(ult["xp"]) > 60, "  con un partidazo se cumplen los tres retos (%d de experiencia)" % int(ult["xp"]))
		_comprobar(int(c.ruta["racha"]) == 1, "  empieza la racha")
		var xp0 := int(c.ruta["xp"]) + CarreraRuta.nivel(c) * 1000
		c.tras_partido(m, {"minutos": 90, "goles": 3, "asist": 1, "nota": 8.6, "titular": true, "encajados": 0, "paradas": 5})
		_comprobar(int(c.ruta["xp"]) + CarreraRuta.nivel(c) * 1000 > xp0, "  los retos ya cumplidos no se cobran dos veces, pero el partido sí da")
		_comprobar(CarreraRuta.nivel(c) > antes_nivel and int(c.ruta["puntos"]) >= 1, "  con dos partidazos subes de nivel y ganas un punto de talento")
		for h2: Dictionary in (c.ruta["ultimo"] as Dictionary)["retos"]:
			_comprobar(not bool(h2["hecho"]), "  (reto repetido sin premio)")
		c.tras_partido(m, {"minutos": 90, "goles": 0, "asist": 0, "nota": 5.0, "titular": true, "encajados": 3})
		_comprobar(int(c.ruta["racha"]) == 0 and int(c.ruta["mejor_racha"]) == 2, "  un mal partido corta la racha (la mejor queda en 2)")
		## Talentos: en cadena dentro de la rama.
		_comprobar(not CarreraTalentos.puede_aprender(c, "pulmones"), "  el segundo talento de una rama pide el primero")
		c.ruta["puntos"] = 3
		_comprobar(CarreraTalentos.aprender(c, m, "ejemplo") and CarreraTalentos.aprender(c, m, "voz") and CarreraTalentos.aprender(c, m, "brazalete"), "  se aprende la rama Líder entera")
		_comprobar(c.capitan and int(c.ruta["puntos"]) == 0 and not CarreraTalentos.aprender(c, m, "instinto"), "  el brazalete te hace capitán y sin puntos no hay más talentos")
		var rel := c.relacion_dt
		CarreraRuta.semana(c, m)
		_comprobar(c.relacion_dt == mini(100, rel + 1), "  «Ejemplo» suma relación con el DT cada semana")
		## El toque del entreno: perfecto = mejora asegurada; una vez por semana.
		c.foco = CarreraPortero.focos_para(j).keys()[0]
		var attr := String(CarreraPortero.focos_para(j)[c.foco][1])
		_comprobar(CarreraRuta.anotar_toque(c, m, 1.0) and not CarreraRuta.anotar_toque(c, m, 0.2), "  el toque se anota una vez por semana")
		var v0 := int(j.atributos[attr])
		c.entrenar(m)
		_comprobar(int(j.atributos[attr]) == v0 + 1, "  con toque perfecto el entreno mejora seguro (%s %d → %d)" % [attr, v0, int(j.atributos[attr])])
		c.entrenar(m)
		_comprobar(int(j.atributos[attr]) == v0 + 1, "  y no se entrena dos veces la misma semana")
		## «Los Momentos»: cuatro jugadas del puesto; la calidad decide el partido.
		var guion := CarreraMomentos.guion(c, m)
		_comprobar(guion.size() == 4 and (CarreraMomentos.GUIONES[j.pos] as Array).has(String(guion[0]["tipo"])) and int(guion[0]["minuto"]) < int(guion[3]["minuto"]),
			"  cuatro jugadas de tu línea, en orden de minuto")
		_comprobar(CarreraMomentos.guion(c, m, 70).size() == 2 and int(CarreraMomentos.guion(c, m, 70)[0]["minuto"]) > 70, "  de suplente, dos jugadas desde que entras")
		var z0 := CarreraMomentos.zona(j, String(guion[0]["tipo"]))
		var a_m := String(CarreraMomentos.TIPOS[String(guion[0]["tipo"])][2])
		var guardado := int(j.atributos[a_m])
		j.atributos[a_m] = 95
		_comprobar(float(CarreraMomentos.zona(j, String(guion[0]["tipo"]))[0]) > float(z0[0]), "  con más atributo la zona perfecta es más ancha")
		j.atributos[a_m] = guardado
		var buenas: Array = []
		var malas: Array = []
		for mo: Dictionary in guion:
			buenas.append(CarreraMomentos.desenlace(String(mo["tipo"]), 1.0))
			malas.append(CarreraMomentos.desenlace(String(mo["tipo"]), 0.1))
		var par_m := [c.club(m), rv_club(m, rv)]
		var bien := CarreraMomentos.resultado(c, m, par_m, buenas)
		var mal := CarreraMomentos.resultado(c, m, par_m, malas)
		_comprobar(float(bien["nota"]) >= 8.0 and float(mal["nota"]) <= 5.0, "  cuatro perfectas dan nota %.1f; cuatro fallos, %.1f" % [float(bien["nota"]), float(mal["nota"])])
		_comprobar(int(bien["goles_local"]) - int(bien["goles_visita"]) > int(mal["goles_local"]) - int(mal["goles_visita"]), "  y el marcador lo nota (%d-%d contra %d-%d)" % [
			int(bien["goles_local"]), int(bien["goles_visita"]), int(mal["goles_local"]), int(mal["goles_visita"])])
		_comprobar(int(bien["goles"]) + int(bien["asist"]) + int(bien["paradas"]) + (1 if j.pos == "DEF" else 0) >= 1 and int(bien["encajados"]) == int(bien["goles_visita"]),
			"  el resumen trae goles, asistencias o paradas, y lo que encajó tu equipo")
		for tipo_m: String in CarreraMomentos.TIPOS:
			if not RutaPizarra.JUGADAS.has(tipo_m):
				_comprobar(false, "  la jugada «%s» no tiene dibujo en la pizarra" % tipo_m)
		## Con la selección: tu equipo es el de paso, sea local o visitante.
		var sel_m := CarreraMomentos.resultado(c, m, [rv_club(m, rv), c.club(m)], buenas, -1, false, rv_club(m, rv))
		_comprobar(int(sel_m["goles_local"]) >= int(sel_m["goles"]) + int(sel_m["asist"]), "  jugando con otro equipo (la selección), tus goles van a su marcador")
		var copa_m := CarreraMomentos.resultado(c, m, par_m, [], -1, true)
		_comprobar(int(copa_m["goles_local"]) != int(copa_m["goles_visita"]), "  en copa no hay empate")
		## Los eventos de la ruta: salen de lo que te pasa y sus efectos se aplican.
		var ids_ev := func() -> Array:
			return CarreraEventosRuta.eventos(c, m).map(func(e: Dictionary) -> String: return String(e["id"]))
		c.energia = 80
		c.ruta["racha"] = 0
		_comprobar(not ids_ev.call().has("ruta_racha") and not ids_ev.call().has("ruta_fundido"), "  sin racha ni cansancio no hay eventos de racha ni de preparador físico")
		c.ruta["racha"] = 3
		c.energia = 20
		_comprobar(ids_ev.call().has("ruta_racha") and ids_ev.call().has("ruta_fundido"), "  con racha de 3 habla la prensa; con 20 de energía te para el preparador")
		c.ruta["ahorros"] = j.sueldo * 20
		var lista_ev := CarreraEventosRuta.eventos(c, m)
		var primo: Dictionary = lista_ev.filter(func(e: Dictionary) -> bool: return String(e["id"]) == "ruta_primo")[0]
		c.eventos.append(primo)
		c.resolver(m, c.eventos.size() - 1, 0)
		_comprobar(CarreraVida.ahorros(c) == j.sueldo * 12, "  prestarle al primo cuesta ocho semanas de sueldo")
		var nivel_ev := CarreraRuta.nivel(c) * 100000 + int(c.ruta["xp"])
		CarreraEventosRuta.aplicar(c, m, {"ruta_xp": 60})
		_comprobar(CarreraRuta.nivel(c) * 100000 + int(c.ruta["xp"]) > nivel_ev, "  la hora extra con el veterano da experiencia")
		for e_r: Dictionary in lista_ev:
			_comprobar((e_r["opciones"] as Array).size() == 2 and String(e_r["texto"]).length() > 30, "  evento «%s» con dos salidas" % e_r["titulo"])
		## En cadena: lo que elegiste trae otro evento semanas después.
		_comprobar(CarreraEventosRuta.semanas_desde(c, m, "bar") == 0 and not ids_ev.call().has("ruta_bar"), "  recién prestado, el bar todavía no da noticias")
		(c.ruta["marcas"] as Dictionary)["bar"] = m.anio * 60 + m.semana - 15
		_comprobar(ids_ev.call().has("ruta_bar"), "  quince semanas después llega «El bar de tu primo»")
		CarreraEventosRuta.aplicar(c, m, {"ruta_marca": "pique"})
		(c.ruta["marcas"] as Dictionary)["pique"] = m.anio * 60 + m.semana - 4
		_comprobar(ids_ev.call().has("ruta_pique"), "  y si contestaste a tu rival en redes, el duelo se calienta")
		CarreraEventosRuta.aplicar(c, m, {"ruta_marca": "duelo_doble"})
		_comprobar(CarreraEventosRuta.tiene_marca(c, "duelo_doble"), "  elegir «vale doble» deja la marca para el cierre del duelo")
		CarreraEventosRuta.quitar_marca(c, "duelo_doble")
		c.ruta["marcas"] = {}
		c.energia = 100
		c.ruta["racha"] = 0
		## Tu vida: el sueldo se ahorra y lo comprado cambia la carrera.
		c.ruta["ahorros"] = 0
		c.ruta["vida"] = {}
		var energia_v := c.energia
		CarreraVida.semana(c, m)
		_comprobar(CarreraVida.ahorros(c) == j.sueldo and not CarreraVida.puede_comprar(c, m, "fisio"), "  cada semana ahorras tu sueldo; con una semana no llega para el fisio")
		c.ruta["ahorros"] = CarreraVida.precio(c, m, "fisio") + CarreraVida.precio(c, m, "coche")
		var rel_v := c.relacion_dt
		_comprobar(CarreraVida.comprar(c, m, "fisio") and CarreraVida.comprar(c, m, "coche") and not CarreraVida.comprar(c, m, "coche") and CarreraVida.ahorros(c) == 0,
			"  compras el fisio y el deportivo, una vez cada uno, y te quedas a cero")
		_comprobar(c.relacion_dt == maxi(0, rel_v - 3), "  el deportivo le sienta mal al DT")
		c.energia = 50
		CarreraVida.semana(c, m)
		_comprobar(c.energia == 56 and CarreraVida.factor_xp(c) < 1.05, "  el fisio devuelve 6 de energía cada semana")
		c.energia = energia_v
		c.relacion_dt = rel_v
		c.ruta["vida"] = {}
		c.ruta["ahorros"] = 0
		## El contrato de botas: llega con la fama, se elige marca y paga por partido.
		c.fama = 5
		_comprobar(CarreraPatrocinio.eventos(c).is_empty() and CarreraPatrocinio.etiqueta(c) == "", "  sin fama no hay marca que te quiera")
		c.fama = 16
		var of_b := CarreraPatrocinio.eventos(c)
		_comprobar(of_b.size() == 1 and (of_b[0]["opciones"] as Array).size() == 2, "  con 15 de fama llega la oferta de botas, con dos marcas")
		c.eventos.append(of_b[0])
		c.hitos["patro_1"] = true
		c.resolver(m, c.eventos.size() - 1, 0)
		_comprobar(CarreraPatrocinio.marca(c) == "rayo" and CarreraPatrocinio.nivel(c) == 1 and CarreraPatrocinio.eventos(c).is_empty(), "  firmas con Rayo I, y no te la vuelven a ofrecer")
		var pb := CarreraPatrocinio.premio(c, {"goles": 2, "asist": 1, "nota": 6.0, "minutos": 90}, false)
		_comprobar(int(pb[0]) == 60 and int(pb[1]) == 270, "  Rayo paga por gol y asistencia (%d XP, %d seguidores)" % [int(pb[0]), int(pb[1])])
		c.fama = 45
		c.eventos.append(CarreraPatrocinio.eventos(c)[0])
		c.resolver(m, c.eventos.size() - 1, 1)
		_comprobar(CarreraPatrocinio.etiqueta(c) == "👟 Roca II" and int(CarreraPatrocinio.premio(c, {"nota": 7.2}, false)[0]) == 37, "  con más fama, Roca II paga un 50 % más por partido de 7")
		c.fama = 5
		c.ruta["fama_ref"] = 5
		c.ruta["patro"] = {}
		## Las ofertas esperan a que te asientes: 15 partidos y nota 6,3.
		c.pj_carrera = 3
		_comprobar(not CarreraRuta.asentado(c), "  con 3 partidos en el club nadie te ofrece nada todavía")
		c.pj_carrera = 3 + CarreraRuta.PARTIDOS_PARA_OFERTA
		c.ruta["pj_llegada"] = 3
		c.stats_temp["notas"] = [6.6, 6.4]
		_comprobar(CarreraRuta.asentado(c), "  con 15 partidos y nota 6,5 ya pueden llegar ofertas")
		c.stats_temp["notas"] = [5.9, 6.0]
		_comprobar(not CarreraRuta.asentado(c), "  y con nota 5,9 no")
		c.ruta["pj_llegada"] = 0
		c.pj_carrera = 3
		## Pulir: un punto por +2 en un atributo; y la fama cuesta más de subir.
		c.ruta["puntos"] = 1
		var a0 := int(j.atributos[attr])
		_comprobar(CarreraTalentos.pulir(c, m, attr) and int(j.atributos[attr]) == a0 + 2 and not CarreraTalentos.pulir(c, m, attr), "  un punto de talento vale por +2 en un atributo")
		j.atributos[attr] = a0
		c.ruta["fama_ref"] = 60
		c.fama = 72
		c.stats_temp["notas"] = [7.0]
		CarreraRuta.semana(c, m)
		_comprobar(c.fama > 60 and c.fama < 68, "  con 60 de fama, de 12 puntos ganados se quedan pocos (%d)" % c.fama)
		c.fama = 5
		c.ruta["fama_ref"] = 5
		## Las misiones del capítulo: al cumplir las tres, un punto de talento.
		var cap := CarreraMisiones.capitulo_en_curso(c)
		_comprobar(cap == "Promesa" and not CarreraMisiones.cobrada(c, cap), "  las misiones empiezan por «Promesa»")
		var puntos0 := int(c.ruta["puntos"])
		_comprobar(CarreraMisiones.revisar(c, m).is_empty(), "  con 3 partidos todavía no se cobran")
		c.pj_carrera = 5
		c.seguidores = 1000
		j.ovr = maxi(j.ovr, 62)
		_comprobar(CarreraMisiones.revisar(c, m) == ["Promesa"] and int(c.ruta["puntos"]) >= puntos0 + 1, "  cumplidas las tres: +1 punto de talento")
		_comprobar(CarreraMisiones.revisar(c, m).is_empty() and CarreraMisiones.cobrada(c, "Promesa"), "  y no se cobran dos veces")
		for mi: Array in CarreraMisiones.MISIONES[CarreraMisiones.capitulo_en_curso(c)]:
			_comprobar(CarreraMisiones.texto(c, m, mi).find("%") < 0, "  misión con su meta: %s" % CarreraMisiones.texto(c, m, mi))
		c.ruta["puntos"] = 0
		## Un atributo no se despega: a 14 de la media deja de subir.
		j.atributos[attr] = mini(99, j.ovr + CarreraRuta.TOPE_SOBRE_MEDIA)
		c.entreno_semana = -1
		c.ruta["toque_semana"] = -1
		CarreraRuta.anotar_toque(c, m, 1.0)
		var tope0 := int(j.atributos[attr])
		c.entrenar(m)
		_comprobar(int(j.atributos[attr]) == tope0, "  un atributo a 14 puntos de tu media ya no sube (ni con toque perfecto)")
		j.atributos[attr] = v0 + 1
		## El techo: entrenando no se pasa de tu mejor potencial + 3.
		var ovr0 := j.ovr
		var pot0 := j.pot
		var t0 := CarreraRuta.techo(c, j)
		j.pot = t0 - 6
		_comprobar(CarreraRuta.techo(c, j) == t0, "  tu techo es el mejor potencial que has tenido (no baja con los años)")
		j.ovr = t0 + CarreraRuta.MARGEN_TECHO
		c.entreno_semana = -1
		var v_t := int(j.atributos[attr])
		c.entrenar(m)
		_comprobar(int(j.atributos[attr]) == v_t and CarreraRuta.en_el_techo(c, j), "  en el techo, entrenar ya no sube atributos")
		j.ovr = ovr0
		j.pot = pot0
		## Guardar y cargar conserva la ruta.
		var c2 := CarreraJugador.desde_dic(JSON.parse_string(JSON.stringify(c.a_dic())))
		_comprobar(CarreraRuta.nivel(c2) == CarreraRuta.nivel(c) and CarreraRuta.tiene(c2, "voz") and (c2.ruta["grada"] as Array).size() == (c.ruta["grada"] as Array).size(),
			"  la ruta se guarda y se carga igual")
		_comprobar(CarreraRuta.texto_grada((c2.ruta["grada"] as Array)[0]) != "", "  la grada tiene algo que decir")
		## Y en disco: la partida entera se guarda, se carga y la ruta vuelve igual.
		CarreraVida.semana(c, m)
		c.ruta["vida"] = {"fisio": true}
		c.ruta["patro"] = {"marca": "roca", "nivel": 2}
		var nombre_g := "prueba_ruta_%s" % String(caso[1]).to_lower()
		_comprobar(Partida.guardar(m, nombre_g), "  la partida con la ruta se guarda en disco")
		var m3 := Partida.cargar(nombre_g)
		Partida.borrar(nombre_g)
		var c3: CarreraJugador = m3.carrera_jugador if m3 != null else null
		_comprobar(c3 != null and c3.jugador(m3) != null and c3.club(m3).nombre == c.club(m).nombre, "  al cargar sigues en tu club (%s)" % c.club(m).nombre)
		if c3 != null:
			_comprobar(CarreraRuta.nivel(c3) == CarreraRuta.nivel(c) and int(c3.ruta["xp"]) == int(c.ruta["xp"]) and CarreraVida.ahorros(c3) == CarreraVida.ahorros(c)
				and CarreraVida.tiene(c3, "fisio") and CarreraPatrocinio.etiqueta(c3) == "👟 Roca II" and CarreraMisiones.cobrada(c3, "Promesa") == CarreraMisiones.cobrada(c, "Promesa")
				and CarreraRuta.retos(c3, m3).size() == 3 and CarreraRuta.rival(c3, m3) != null and CarreraRuta.rival(c3, m3).id == CarreraRuta.rival(c, m).id,
				"  nivel, experiencia, ahorros, compras, botas, misiones, retos y rival vuelven igual")
		c.ruta["vida"] = {}
		c.ruta["patro"] = {}
		c.ruta["ahorros"] = 0
		## Si ya eres mucho mejor que tu liga, el rival se busca en todo el mundo.
		var ovr_r := j.ovr
		j.ovr = 93
		(c.ruta["rival"] as Dictionary).clear()
		var lejos := CarreraRuta.rival(c, m)
		_comprobar(lejos != null and lejos.pos == j.pos and lejos.ovr >= 80 and bool((c.ruta["rival"] as Dictionary)["fuera"]), "  con media 93 tu rival es de los mejores del mundo en tu línea (%s, %d)" % [lejos.nombre, lejos.ovr])
		_comprobar(CarreraRuta.rival(c, m) == lejos, "  y se conserva aunque no juegue en tu liga")
		j.ovr = ovr_r
		(c.ruta["rival"] as Dictionary).clear()
		## Más goles en el simulado, pero solo en el modo jugador.
		m.avanzar_semana(null)
		_comprobar(is_equal_approx(Partido.ctx_factor_goles, CarreraRuta.GOLES_SIMULADO), "  en el modo jugador el simulado convierte un %d %% más" % roundi((CarreraRuta.GOLES_SIMULADO - 1.0) * 100.0))
		var m_dt := Mundo.new()
		m_dt.generar(lista, int(caso[2]))
		m_dt.tomar_el_mando(m_dt.ligas[0].clubes[1].id)
		m_dt.avanzar_semana(null)
		_comprobar(is_equal_approx(Partido.ctx_factor_goles, 1.0), "  y dirigiendo un club, lo de siempre")
		## Estilo, curva y forma (13-11, inspirado en el modo jugador del FC 27, versión propia).
		var m_e := Mundo.new()
		m_e.generar(lista, int(caso[2]) + 1)
		m_e.mi_club_id = ""
		var c_e := CarreraJugador.crear(m_e, "Prueba Estilo", String(caso[1]), true, int(caso[2]))
		m_e.carrera_jugador = c_e
		var j_e := c_e.jugador(m_e)
		var linea_e := CarreraEstilo.de_linea(j_e.pos)
		_comprobar(linea_e.size() == 3, "  tu línea (%s) tiene tres estilos" % j_e.pos)
		var id_e := String(linea_e.keys()[1])
		var attrs_e: Dictionary = linea_e[id_e][2]
		var antes_e := {}
		for k_e: String in attrs_e:
			antes_e[k_e] = int(j_e.atributos[k_e])
		var pot_e := j_e.pot
		CarreraEstilo.aplicar(c_e, m_e, id_e, "tardia")
		var sube_e := true
		for k_e2: String in attrs_e:
			sube_e = sube_e and int(j_e.atributos[k_e2]) == mini(99, int(antes_e[k_e2]) + int(attrs_e[k_e2]))
		_comprobar(sube_e and CarreraEstilo.estilo(c_e) == id_e, "  el estilo «%s» sube sus dos atributos" % linea_e[id_e][0])
		_comprobar(j_e.pot == pot_e + 2 and CarreraRuta.techo(c_e, j_e) == pot_e + 2, "  la curva tardía sube el techo 2 puntos")
		CarreraEstilo.aplicar(c_e, m_e, String(linea_e.keys()[0]), "precoz")
		_comprobar(CarreraEstilo.estilo(c_e) == id_e and j_e.pot == pot_e + 2, "  y se elige una sola vez")
		var fav_e := CarreraEstilo.favorita(c_e, m_e)
		var guion_e := CarreraMomentos.guion(c_e, m_e)
		_comprobar(String(guion_e[0]["tipo"]) == fav_e and guion_e.size() == 4, "  su jugada favorita (%s) abre siempre Los Momentos" % fav_e)
		_comprobar(float(CarreraMomentos.zona(j_e, fav_e, 0, true)[0]) > float(CarreraMomentos.zona(j_e, fav_e)[0]) and float(CarreraMomentos.zona(j_e, fav_e, 3)[0]) >= float(CarreraMomentos.zona(j_e, fav_e, -3)[0]),
			"  la zona de la favorita es más ancha, y la forma la mueve")
		j_e.edad = 18
		_comprobar(not CarreraEstilo._empuja(c_e, j_e) and CarreraEstilo._frena(c_e, j_e), "  curva tardía: a los 18 frena")
		j_e.edad = 24
		_comprobar(CarreraEstilo._empuja(c_e, j_e) and not CarreraEstilo._frena(c_e, j_e), "  y a los 24 empuja")
		c_e.stats_temp["notas"] = [8.0, 7.9, 7.7]
		j_e.moral = 90
		c_e.energia = 90
		_comprobar(CarreraEstilo.forma(c_e, j_e) == 3 and CarreraEstilo.media_de_hoy(c_e, j_e) == j_e.ovr + 3, "  en racha, con ánimo y fresco: forma +3")
		c_e.stats_temp["notas"] = [5.2, 5.5, 5.0]
		j_e.moral = 40
		c_e.energia = 20
		_comprobar(CarreraEstilo.forma(c_e, j_e) == -3, "  mal, hundido y sin piernas: forma −3")
		var c_v := CarreraJugador.desde_dic(JSON.parse_string(JSON.stringify(c_e.a_dic())))
		_comprobar(CarreraEstilo.estilo(c_v) == id_e and CarreraEstilo.curva(c_v) == "tardia", "  estilo y curva se guardan con la partida")
		## El duelo de la temporada.
		c.stats_temp["goles"] = 30
		var d := CarreraRuta.duelo(c, m)
		_comprobar(int(d[0]) > int(d[1]), "  con 30 goles vas ganando el duelo a tu rival")
		## El cierre de temporada: premios con su experiencia, una vez.
		c.stats_temp["pj"] = 32
		c.stats_temp["notas"] = [7.6, 7.4, 7.8]
		c.ovr_inicio = j.ovr - 5
		var fama0 := c.fama
		c.fin_de_temporada(m)
		var t: Dictionary = c.ruta["temporada"]
		var ids: Array = t["premios"]
		_comprobar(bool(t["gano_duelo"]) and int(c.ruta["duelos_ganados"]) == 1 and ids.has("duelo"), "  el cierre apunta el duelo ganado")
		_comprobar(ids.has("revelacion") and ids.has("goleador_club") and ids.has("once_ideal") and ids.has("hierro") and ids.has("salto"),
			"  premios del año: %s" % ", ".join(ids))
		_comprobar(c.fama > fama0 and int(t["pj"]) == 32 and int(t["goles"]) == 30 and int(c.stats_temp["pj"]) == 0, "  el resumen guarda tus números antes de ponerlos a cero")
		_comprobar(CarreraPremios.pendiente(c) and int(CarreraPremios.palmares(c).get("once_ideal", 0)) == 1, "  queda pendiente de enseñar y entra en tu palmarés")
		c.fin_de_temporada(m)
		_comprobar(not ((c.ruta["temporada"] as Dictionary)["premios"] as Array).has("revelacion"), "  la revelación solo se gana el primer año")
	Partido.limpiar_contexto()
