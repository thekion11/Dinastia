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
