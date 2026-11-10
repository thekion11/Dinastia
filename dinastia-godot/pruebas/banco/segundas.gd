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
	_comprobar(not ReglasAscenso.tiene("CHI") and not ReglasAscenso.tiene("ARG"), "Chile y Argentina usan las reglas generales")
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
