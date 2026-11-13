extends "res://pruebas/banco/base.gd"
## [Banco · grupo «segundas»] Segundas divisiones con su cantidad real y ascensos/descensos reales (sesión 6, 10-11).

func _club_de(m: Mundo, pais: String, division: int) -> Club:
	var mejor: Club = null
	for c: Club in m.clubes.values():
		if c.pais == pais and c.division == division and (mejor == null or c.rep > mejor.rep):
			mejor = c
	return mejor

func _probar_segundas_divisiones() -> void:
	_titulo("SEGUNDAS DIVISIONES: CANTIDAD REAL, ASCENSOS Y DESCENSOS REALES")
	var paises: Array[String] = ["ENG", "CHI", "ESP"]
	var m := Mundo.new()
	m.generar(paises, 601)
	var eng1: Liga = null
	var eng2: Liga = null
	for l: Liga in m.ligas:
		if l.pais == "ENG" and l.division() == 1:
			eng1 = l
		if l.pais == "ENG" and l.division() == 2:
			eng2 = l
	_comprobar(eng1 != null and eng2 != null, "Inglaterra tiene Primera y Segunda")
	_comprobar(eng1.clubes.size() == 20 and eng2.clubes.size() == 24, "20 clubes en la Premier y 24 en la Championship (%d y %d)" % [eng1.clubes.size(), eng2.clubes.size()])
	## Con más de 20 clubes se juega a UNA vuelta (`Liga.UNA_VUELTA_DESDE`): 23 jornadas. A doble vuelta serían 46 y la temporada de TODO el
	## mundo, que arranca el 1 de febrero (`Calendario.INICIO`), llegaría hasta el 20 de diciembre en vez de acabar a fines de octubre.
	_comprobar(eng2.jornadas() == 23, "24 clubes = 23 jornadas a una vuelta (%d)" % eng2.jornadas())
	_comprobar(eng1.plazas_descenso == 3, "en la Premier bajan 3 (%d)" % eng1.plazas_descenso)
	var sin_division := 0
	for c: Club in eng2.clubes:
		if c.division != 2 or c.pais != "ENG":
			sin_division += 1
	_comprobar(sin_division == 0, "todos los clubes de la Championship están en la división 2 (%d mal)" % sin_division)
	var chi := m.ligas.filter(func(l: Liga) -> bool: return l.pais == "CHI")
	_comprobar(chi.size() == 2 and (chi[1] as Liga).division() == 2, "Chile conserva su Primera B (%d ligas)" % chi.size())
	## No hay un solo club repetido ni de ida y vuelta entre ligas.
	var vistos := {}
	var repes := 0
	for l: Liga in m.ligas:
		for c: Club in l.clubes:
			if vistos.has(c.id):
				repes += 1
			vistos[c.id] = true
	_comprobar(repes == 0, "ningún club está en dos ligas (%d)" % repes)
	## Una temporada entera: cuánto dura y cómo cierra.
	m.tomar_el_mando(_club_de(m, "ENG", 1).id)
	var semanas := 0
	while m.temporada_en_curso() and semanas < 80:
		m.avanzar_semana()
		semanas += 1
	_linea("  temporada de %d semanas (ENG1 %d jornadas, ENG2 %d, ESP2 %d jornadas)" % [semanas, eng1.jornadas(), eng2.jornadas(), (m.ligas.filter(func(l: Liga) -> bool: return l.pais == "ESP" and l.division() == 2).size())])
	_comprobar(semanas == eng1.jornadas() and semanas == 38, "la temporada sigue durando 38 semanas, las de una liga de 20 (%d)" % semanas)
	_comprobar(semanas < 52, "y cabe en el año del juego (52 semanas): %d" % semanas)
	var bajan_esperados: Array[Club] = []
	var t1 := eng1.tabla()
	for i in 3:
		bajan_esperados.append(t1[t1.size() - 1 - i]["club"])
	var t2 := eng2.tabla()
	var directos: Array[Club] = [t2[0]["club"], t2[1]["club"]]
	var resumen := m.nueva_temporada()
	var bajaron := bajan_esperados.all(func(c: Club) -> bool: return c.division == 2 and eng2.clubes.has(c))
	_comprobar(bajaron, "los tres últimos de la Premier bajan a la Championship")
	_comprobar(directos.all(func(c: Club) -> bool: return c.division == 1 and eng1.clubes.has(c)), "los dos primeros de la Championship suben directos")
	var ph: Dictionary = resumen.get("playoff_ascenso", {})
	_comprobar(not ph.is_empty() and ph["participantes"].size() == 4 and (ph["ganador"] as Club).division == 1, "el playoff de 3.º a 6.º da el tercer ascenso (%s)" % [(ph["ganador"] as Club).nombre if not ph.is_empty() else "-"])
	_comprobar(eng1.clubes.size() == 20 and eng2.clubes.size() == 24, "siguen 20 y 24 clubes tras los cambios (%d y %d)" % [eng1.clubes.size(), eng2.clubes.size()])
	var suben_eng := (resumen["suben"] as Array).filter(func(c: Club) -> bool: return c.pais == "ENG").size()
	var bajan_eng := (resumen["bajan"] as Array).filter(func(c: Club) -> bool: return c.pais == "ENG").size()
	_comprobar(suben_eng == 3 and bajan_eng == 3, "suben 3 y bajan 3 en Inglaterra (%d y %d)" % [suben_eng, bajan_eng])
	var suben_chi := (resumen["suben"] as Array).filter(func(c: Club) -> bool: return c.pais == "CHI").size()
	_comprobar(suben_chi == 2, "Chile sigue con la regla de siempre: suben 2 (%d)" % suben_chi)
	## La temporada siguiente se juega con las ligas nuevas.
	m.avanzar_semana()
	_comprobar(eng1.tabla().size() == 20 and eng2.tabla().size() == 24, "las tablas de la temporada nueva están completas")

func _probar_segundas_reglas() -> void:
	_titulo("SEGUNDAS DIVISIONES: PLAYOFF DE ASCENSO Y PROMOCIÓN DE GER Y FRA")
	Partido.limpiar_contexto()   ## (13-11) el resultado dependía de lo que hubiera simulado la sección anterior del mismo proceso
	var m := Mundo.new()
	m.generar(["ENG"] as Array[String], 602)
	var eng2: Liga = m.ligas.filter(func(l: Liga) -> bool: return l.division() == 2)[0]
	var cuatro: Array[Club] = []
	for i in 4:
		cuatro.append(eng2.clubes[i])
	var cuentan := {}
	for i in 6:
		Azar.sembrar(700 + i)
		var g := AscensosPais.playoff_de_ascenso(m, cuatro)
		_comprobar(cuatro.has(g), "el ganador del playoff es uno de los cuatro (semilla %d)" % (700 + i))
		cuentan[g.id] = true
	_comprobar(cuentan.size() >= 2, "no gana siempre el mismo (%d distintos de 6)" % cuentan.size())
	## Reglas por país: los cinco grandes tienen las suyas y los demás no.
	for pais in ["ENG", "ESP", "ITA", "GER", "FRA"]:
		_comprobar(ReglasAscenso.tiene(pais) and int(ReglasAscenso.de(pais)["directos"]) == 2, "%s tiene reglas reales (2 directos)" % pais)
	_comprobar(not ReglasAscenso.tiene("CHI") and ReglasAscenso.tiene("ARG") and ReglasAscenso.tiene("BRA") and ReglasAscenso.tiene("MEX"), "Chile usa las reglas generales; Argentina, Brasil y México tienen las suyas")
	_comprobar(int(ReglasAscenso.de("MEX")["bajan"]) == 0, "México: circuito cerrado, no baja nadie")
	_comprobar(int(ReglasAscenso.de("GER")["bajan"]) == 2 and ReglasAscenso.de("GER").get("relegacion", false), "Alemania: bajan 2 y el 16.º juega la promoción")
	## La promoción real (GER/FRA) sobre dos tablas inventadas: el 16.º contra el 3.º, y los que bajan y suben son los mismos.
	var t1: Array = []
	var t2: Array = []
	var arriba: Array[Club] = []
	var abajo: Array[Club] = []
	for c: Club in m.clubes.values():
		(arriba if c.division == 1 else abajo).append(c)
	for c: Club in arriba:
		t1.append({"club": c})
	for c: Club in abajo:
		t2.append({"club": c})
	var bajan: Array[Club] = []
	var suben: Array[Club] = []
	var resumen := {}
	Azar.sembrar(710)
	AscensosPais._reales(m, t1, t2, ReglasAscenso.de("GER"), bajan, suben, resumen)
	_comprobar(bajan.size() == suben.size() and bajan.size() >= 2 and bajan.size() <= 3, "bajan y suben los mismos (%d y %d)" % [bajan.size(), suben.size()])
	_comprobar(resumen.has("promocion") and bajan[0] == t1[t1.size() - 1]["club"] and suben[0] == t2[0]["club"], "baja el último y sube el primero, y hubo promoción")

## Las cinco primeras de Europa tienen su segunda con la cantidad real de clubes y sus reglas de ascenso (paso 3).
func _probar_segundas_cinco_grandes() -> void:
	_titulo("SEGUNDAS DIVISIONES: ENG, ESP, ITA, GER Y FRA")
	var esperado := {"ENG": [20, 24], "ESP": [20, 22], "ITA": [20, 20], "GER": [18, 18], "FRA": [18, 18]}
	var paises: Array[String] = []
	for p: String in esperado:
		paises.append(p)
	var m := Mundo.new()
	m.generar(paises, 611)
	for pais: String in esperado:
		var l1: Liga = null
		var l2: Liga = null
		for l: Liga in m.ligas:
			if l.pais == pais and l.division() == 1:
				l1 = l
			elif l.pais == pais and l.division() == 2:
				l2 = l
		_comprobar(l1 != null and l2 != null and l1.clubes.size() == esperado[pais][0] and l2.clubes.size() == esperado[pais][1], "%s: %d clubes en Primera y %d en Segunda (%d y %d)" % [pais, esperado[pais][0], esperado[pais][1], l1.clubes.size() if l1 else 0, l2.clubes.size() if l2 else 0])
		_comprobar(l1 != null and l1.plazas_descenso == int(ReglasAscenso.de(pais)["bajan"]), "%s: bajan %d de Primera" % [pais, int(ReglasAscenso.de(pais)["bajan"])])
	var nombres := {}
	var repes := 0
	for c: Club in m.clubes.values():
		if nombres.has(c.nombre):
			repes += 1
		nombres[c.nombre] = true
	_comprobar(repes == 0, "ningún nombre de club repetido en el mundo (%d)" % repes)
	## Una temporada con los cinco países y su cierre: todos los cambios cuadran.
	m.tomar_el_mando(_club_de(m, "FRA", 1).id)
	var guard := 0
	while m.temporada_en_curso() and guard < 80:
		m.avanzar_semana()
		guard += 1
	var resumen := m.nueva_temporada()
	for pais: String in esperado:
		var suben := (resumen["suben"] as Array).filter(func(c: Club) -> bool: return c.pais == pais).size()
		var bajan := (resumen["bajan"] as Array).filter(func(c: Club) -> bool: return c.pais == pais).size()
		_comprobar(suben == bajan and suben >= 2 and suben <= 3, "%s: suben %d y bajan %d" % [pais, suben, bajan])
	for l: Liga in m.ligas:
		if esperado.has(l.pais):
			var n: int = esperado[l.pais][0 if l.division() == 1 else 1]
			_comprobar(l.clubes.size() == n, "%s división %d sigue con %d clubes (%d)" % [l.pais, l.division(), n, l.clubes.size()])

## Argentina, Brasil y México (paso 4): sus segundas y sus reglas propias (México, sin ascensos ni descensos).
func _probar_segundas_latinoamerica() -> void:
	_titulo("SEGUNDAS DIVISIONES: ARGENTINA, BRASIL Y MÉXICO")
	var esperado := {"ARG": [30, 36, 2, 2], "BRA": [20, 20, 4, 4], "MEX": [18, 16, 0, 0]}
	var paises: Array[String] = []
	for p: String in esperado:
		paises.append(p)
	var m := Mundo.new()
	m.generar(paises, 621)
	for pais: String in esperado:
		var l1: Liga = null
		var l2: Liga = null
		for l: Liga in m.ligas:
			if l.pais == pais and l.division() == 1:
				l1 = l
			elif l.pais == pais and l.division() == 2:
				l2 = l
		_comprobar(l1 != null and l2 != null and l1.clubes.size() == esperado[pais][0] and l2.clubes.size() == esperado[pais][1], "%s: %d en Primera y %d en la segunda (%d y %d)" % [pais, esperado[pais][0], esperado[pais][1], l1.clubes.size() if l1 else 0, l2.clubes.size() if l2 else 0])
		_comprobar(l2 != null and l2.jornadas() <= 38, "%s: la segunda no alarga la temporada (%d jornadas)" % [pais, l2.jornadas() if l2 else 0])
	m.tomar_el_mando(_club_de(m, "BRA", 1).id)
	var guard := 0
	while m.temporada_en_curso() and guard < 80:
		m.avanzar_semana()
		guard += 1
	_comprobar(guard <= 38, "la temporada con las tres sigue en 38 semanas o menos (%d)" % guard)
	var resumen := m.nueva_temporada()
	for pais: String in esperado:
		var suben := (resumen["suben"] as Array).filter(func(c: Club) -> bool: return c.pais == pais).size()
		var bajan := (resumen["bajan"] as Array).filter(func(c: Club) -> bool: return c.pais == pais).size()
		_comprobar(suben == esperado[pais][2] and bajan == esperado[pais][3], "%s: suben %d y bajan %d (esperado %d y %d)" % [pais, suben, bajan, esperado[pais][2], esperado[pais][3]])
	for l: Liga in m.ligas:
		if esperado.has(l.pais):
			var n: int = esperado[l.pais][0 if l.division() == 1 else 1]
			_comprobar(l.clubes.size() == n, "%s división %d sigue con %d clubes (%d)" % [l.pais, l.division(), n, l.clubes.size()])
	_comprobar(not (resumen.get("playoff_ascenso", {}) as Dictionary).is_empty(), "el segundo ascenso de Argentina sale del playoff")

## Portugal, Países Bajos y Turquía: sus segundas (con filiales «B» y «Jong» como en la realidad) y sus reglas.
func _probar_segundas_pbt() -> void:
	_titulo("SEGUNDAS DIVISIONES: PORTUGAL, PAÍSES BAJOS Y TURQUÍA")
	var esperado := {"POR": [18, 18, 2, 2], "NED": [18, 20, 2, 1], "TUR": [18, 20, 3, 2]}
	var paises: Array[String] = []
	for p: String in esperado:
		paises.append(p)
	var m := Mundo.new()
	m.generar(paises, 631)
	for pais: String in esperado:
		var l1: Liga = null
		var l2: Liga = null
		for l: Liga in m.ligas:
			if l.pais == pais and l.division() == 1:
				l1 = l
			elif l.pais == pais and l.division() == 2:
				l2 = l
		_comprobar(l1 != null and l2 != null and l1.clubes.size() == esperado[pais][0] and l2.clubes.size() == esperado[pais][1], "%s: %d en Primera y %d en la segunda (%d y %d)" % [pais, esperado[pais][0], esperado[pais][1], l1.clubes.size() if l1 else 0, l2.clubes.size() if l2 else 0])
		_comprobar(l1 != null and l1.plazas_descenso == int(esperado[pais][2]) and int(ReglasAscenso.de(pais)["directos"]) == int(esperado[pais][3]), "%s: bajan %d y suben %d directos" % [pais, int(esperado[pais][2]), int(esperado[pais][3])])
		_comprobar(l2 != null and l2.jornadas() <= 38, "%s: la segunda no alarga la temporada (%d jornadas)" % [pais, l2.jornadas() if l2 else 0])
	var nombres := {}
	var repes := 0
	for c: Club in m.clubes.values():
		if nombres.has(c.nombre):
			repes += 1
		nombres[c.nombre] = true
	_comprobar(repes == 0, "ningún nombre de club repetido (%d)" % repes)
	m.tomar_el_mando(_club_de(m, "TUR", 1).id)
	var guard := 0
	while m.temporada_en_curso() and guard < 80:
		m.avanzar_semana()
		guard += 1
	var resumen := m.nueva_temporada()
	for pais: String in esperado:
		var suben := (resumen["suben"] as Array).filter(func(c: Club) -> bool: return c.pais == pais).size()
		var bajan := (resumen["bajan"] as Array).filter(func(c: Club) -> bool: return c.pais == pais).size()
		_comprobar(suben == bajan and suben == int(esperado[pais][2]), "%s: suben %d y bajan %d" % [pais, suben, bajan])

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
		var copa_m := CarreraMomentos.resultado(c, m, par_m, [], -1, true)
		_comprobar(int(copa_m["goles_local"]) != int(copa_m["goles_visita"]), "  en copa no hay empate")
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
