extends "res://pruebas/banco/base.gd"
## [Banco · grupo «fases_finales»] Egipto (grupos de campeonato y descenso), Argentina (zonas y playoffs) y la MLS (conferencias y playoffs) (sesión 6, 10-11).

func _liga_de(m: Mundo, pais: String) -> Liga:
	for l: Liga in m.ligas:
		if l.pais == pais and l.division() == 1:
			return l
	return null

## Guarda y vuelve a abrir la liga a medias: el estado de la fase final tiene que sobrevivir.
func _recargar(m: Mundo, l: Liga) -> Liga:
	var d: Dictionary = JSON.parse_string(JSON.stringify(Partida._liga_a_dic(l)))
	return Partida._dic_a_liga(d, m)

func _unicos(a: Array) -> int:
	var d := {}
	for x in a:
		d[x] = true
	return d.size()

func _probar_fases_finales_egipto() -> void:
	_titulo("FASES FINALES · EGIPTO: CAMPEONATO (7) Y DESCENSO (14)")
	for semilla: int in [801, 802]:
		Azar.sembrar(semilla)
		var m := Mundo.new()
		m.generar(["EGY", "CHI", "ESP"], semilla)
		var l := _liga_de(m, "EGY")
		_comprobar(l.clubes.size() == 21 and l.formato != null and l.formato.f1 == 21, "%d: 21 clubes a una vuelta (%d fechas)" % [semilla, l.formato.f1 if l.formato else 0])
		_comprobar(l.jornadas() == 21 + l.formato.extra and l.jornadas() <= 38, "la liga ya cuenta la fase final (%d fechas)" % l.jornadas())
		while l.jornada_actual < 24:
			l.jugar_jornada()
		var g: Array = l.formato.estado["grupos"]
		_comprobar(g[0].size() == 7 and g[1].size() == 14, "tras la fase regular: 7 al campeonato y 14 al descenso")
		var l2 := _recargar(m, l)
		_comprobar(l2.jornada_actual == l.jornada_actual and l2.formato.estado["grupos"][0] == g[0] and l2.calendario[24].size() == l.calendario[24].size(), "guardar y abrir a mitad de la fase final conserva los grupos y el calendario")
		l2.jugar_temporada()
		l.jugar_temporada()
		var t := l.tabla()
		var campeon: Club = t[0]["club"]
		_comprobar(g[0].has(campeon.id), "%d: el campeón (%s) sale del grupo del campeonato" % [semilla, campeon.nombre])
		var bajan: Array = t.slice(t.size() - l.plazas_descenso)
		_comprobar(bajan.all(func(f: Dictionary) -> bool: return (g[1] as Array).has((f["club"] as Club).id)), "los %d que bajan salen del grupo del descenso" % l.plazas_descenso)
		var tabla_recargada := l2.tabla()
		_comprobar((tabla_recargada[0]["club"] as Club).id == campeon.id, "la liga recargada llega al mismo campeón")
		var pj_a := int(l.tabla_puntos[g[0][0]]["pj"])
		var pj_b := int(l.tabla_puntos[g[1][0]]["pj"])
		_comprobar(pj_a == 21 - 1 + 12 and pj_b == 21 - 1 + 13, "partidos: %d en el campeonato (20+12) y %d en el descenso (20+13)" % [pj_a, pj_b])

func _probar_fases_finales_argentina() -> void:
	_titulo("FASES FINALES · ARGENTINA: ZONAS Y PLAYOFFS A PARTIDO ÚNICO")
	for semilla: int in [811, 812]:
		Azar.sembrar(semilla)
		var m := Mundo.new()
		m.generar(["ARG", "CHI", "ESP"], semilla)
		var l := _liga_de(m, "ARG")
		_comprobar(l.clubes.size() == 30 and l.formato != null and l.formato.f1 == 16 and l.jornadas() == 20, "%d: 30 clubes, 16 fechas de zona y 4 de playoffs (%d en total)" % [semilla, l.jornadas()])
		var z := ZonasLiga.de(l)
		_comprobar(z.size() == 30 and z[l.clubes[0].id] == 0 and z[l.clubes[1].id] == 1 and z[l.clubes[2].id] == 1 and z[l.clubes[4].id] == 0, "zonas reales: el primero (Boca) en la A; el segundo y el tercero (River y Racing) en la B; el quinto (Independiente) en la A")
		var en_a := 0
		for id: String in z:
			en_a += 1 if int(z[id]) == 0 else 0
		_comprobar(en_a == 15, "15 clubes por zona (%d)" % en_a)
		while l.jornada_actual < 16:
			l.jugar_jornada()
		var pj_zona := int(l.tabla_puntos[l.clubes[0].id]["pj"])
		_comprobar(pj_zona == 15 or pj_zona == 14, "cada club jugó sus partidos de zona (%d)" % pj_zona)
		_comprobar(l.calendario[16].size() == 8, "octavos: 8 cruces (%d)" % l.calendario[16].size())
		var pts_antes := {}
		for id: String in l.tabla_puntos:
			pts_antes[id] = int(l.tabla_puntos[id]["pts"])
		l.jugar_jornada()
		var intacta := true
		for id: String in l.tabla_puntos:
			intacta = intacta and int(l.tabla_puntos[id]["pts"]) == int(pts_antes[id])
		_comprobar(intacta, "los playoffs no tocan la tabla de la fase regular")
		_comprobar(l.calendario[17].size() == 4, "cuartos: 4 cruces (%d)" % l.calendario[17].size())
		var l2 := _recargar(m, l)
		_comprobar(l2.jornada_actual == 17 and l2.calendario[17].size() == 4 and l2.calendario[17][0][0].id == l.calendario[17][0][0].id, "guardar y abrir en cuartos conserva el cuadro")
		l.jugar_temporada()
		l2.jugar_temporada()
		_comprobar(l.orden_final.size() == 30 and l2.orden_final.size() == 30 and _unicos(l2.orden_final) == 30 and _unicos(l.orden_final) == 30, "%d: el orden final trae a los 30 sin repetir, también recargando (campeón %s)" % [semilla, (l.tabla()[0]["club"] as Club).nombre])
		_comprobar(String(l2.formato.estado["rondas"][3]["c"][0]["g"]) == String(l2.orden_final[0]), "la liga recargada también coloca a su campeón primero")
		var rondas: Array = l.formato.estado["rondas"]
		_comprobar(rondas.size() == 4 and rondas[3]["c"].size() == 1 and String(rondas[3]["c"][0]["g"]) == String(l.orden_final[0]), "cuatro rondas y el campeón gana la final (%s)" % str(rondas.map(func(r: Dictionary) -> String: return String(r["n"]))))
		var fin_ids: Array = [rondas[3]["c"][0]["a"], rondas[3]["c"][0]["b"]]
		_comprobar(fin_ids.has(l.orden_final[0]) and fin_ids.has(l.orden_final[1]), "el subcampeón es el otro finalista")

func _probar_fases_finales_mls() -> void:
	_titulo("FASES FINALES · MLS: CONFERENCIAS, WILD CARD Y ELIMINATORIAS AL MEJOR DE 3")
	for semilla: int in [821, 822]:
		Azar.sembrar(semilla)
		var m := Mundo.new()
		m.generar(["USA", "CHI", "ESP"], semilla)
		var l := _liga_de(m, "USA")
		_comprobar(l.clubes.size() == 30 and l.formato != null and l.formato.f1 == 31 and l.jornadas() == 38, "%d: 30 clubes, 31 fechas (30 de conferencia y 1 interconferencia) y 7 de playoffs (%d)" % [semilla, l.jornadas()])
		var conf := ZonasLiga.de(l)
		var este := 0
		for id: String in conf:
			este += 1 if int(conf[id]) == 0 else 0
		_comprobar(conf.size() == 30 and este == 15 and conf[l.clubes[0].id] == 0 and conf[l.clubes[1].id] == 1, "conferencias reales: 15 Este y 15 Oeste (Inter Miami en el Este, LAFC en el Oeste)")
		while l.jornada_actual < 31:
			l.jugar_jornada()
		_comprobar(l.calendario[31].size() == 2, "Wild Card: 8.º contra 9.º en cada conferencia (%d partidos)" % l.calendario[31].size())
		l.jugar_jornada()
		_comprobar(l.calendario[32].size() == 8, "Ronda 1: 8 series (%d partidos el primer día)" % l.calendario[32].size())
		l.jugar_jornada()
		_comprobar(l.calendario[33].size() == 8, "juego 2 de la Ronda 1 (%d)" % l.calendario[33].size())
		var l2 := _recargar(m, l)
		_comprobar(l2.jornada_actual == l.jornada_actual and l2.calendario[33].size() == 8, "guardar y abrir en plena serie conserva el cuadro")
		l.jugar_temporada()
		l2.jugar_temporada()
		var rondas: Array = l.formato.estado["rondas"]
		_comprobar(rondas.size() == 5 and rondas[4]["c"].size() == 1, "cinco rondas hasta la MLS Cup (%d)" % rondas.size())
		var series_ok := true
		for c: Dictionary in rondas[1]["c"]:
			var ga := 0
			for x: Array in c["r"]:
				ga += 1 if int(x[0]) > int(x[1]) else 0
			series_ok = series_ok and (c["r"] as Array).size() in [2, 3] and (ga == 2 or (c["r"] as Array).size() - ga == 2)
		_comprobar(series_ok, "las series al mejor de 3 terminan 2-0 o 2-1")
		_comprobar(l.orden_final.size() == 30 and String(rondas[4]["c"][0]["g"]) == String(l.orden_final[0]), "%d: campeón de la MLS Cup %s" % [semilla, (l.tabla()[0]["club"] as Club).nombre])
		_comprobar(l2.orden_final.size() == 30 and String(l2.formato.estado["rondas"][4]["c"][0]["g"]) == String(l2.orden_final[0]), "la liga recargada también coloca a su campeón primero")

func _probar_fases_finales_europa() -> void:
	_titulo("FASES FINALES · BÉLGICA, ESCOCIA, DINAMARCA, SUIZA Y AUSTRIA: GRUPOS FINALES")
	## país, clubes, fechas de la fase regular, fechas de la fase final, partidos del grupo de arriba, ¿puntos a la mitad?
	for caso: Array in [["BEL", 16, 30, 6, 35, true], ["SCO", 12, 33, 5, 38, false], ["DEN", 12, 22, 10, 32, false], ["SUI", 12, 33, 5, 38, false], ["AUT", 12, 22, 10, 32, false]]:
		var pais := String(caso[0])
		Azar.sembrar(830 + pais.length() + int(caso[1]))
		var m := Mundo.new()
		m.generar([pais, "CHI", "ESP"], 830 + int(caso[1]))
		var l := _liga_de(m, pais)
		_comprobar(l.clubes.size() == int(caso[1]) and l.formato != null and l.formato.f1 == int(caso[2]) and l.jornadas() == int(caso[2]) + int(caso[3]) and l.jornadas() <= 38,
			"%s: %d clubes, %d fechas de fase regular y %d de grupos finales (%d en total)" % [pais, l.clubes.size(), int(caso[2]), int(caso[3]), l.jornadas()])
		while l.jornada_actual < int(caso[2]):
			l.jugar_jornada()
		var g: Array = l.formato.estado["grupos"]
		var total := 0
		for x: Array in g:
			total += x.size()
		_comprobar(g[0].size() == 6 and total == int(caso[1]), "%s: 6 clubes al grupo del campeonato y %d grupos en total" % [pais, g.size()])
		var mitad_ok := true
		for id: String in g[0]:
			var d: Dictionary = l.tabla_puntos[id]
			var original := 3 * int(d["g"]) + int(d["e"])
			mitad_ok = mitad_ok and (int(d["pts"]) == (original + 1) / 2 if bool(caso[5]) else int(d["pts"]) == original)
		_comprobar(mitad_ok, "%s: los puntos %s" % [pais, "se parten por la mitad (hacia arriba)" if bool(caso[5]) else "se arrastran enteros"])
		var l2 := _recargar(m, l)
		l2.jugar_jornada()
		l.jugar_temporada()
		var t := l.tabla()
		_comprobar(g[0].has((t[0]["club"] as Club).id) and (g[0] as Array).has(String(l.orden_final[0])), "%s: el campeón (%s) sale del grupo de arriba" % [pais, (t[0]["club"] as Club).nombre])
		var bajan: Array = t.slice(t.size() - l.plazas_descenso)
		_comprobar(bajan.all(func(f: Dictionary) -> bool: return (g.back() as Array).has((f["club"] as Club).id)), "%s: los %d que bajan salen del grupo de abajo" % [pais, l.plazas_descenso])
		var pj := int(l.tabla_puntos[g[0][0]]["pj"])
		_comprobar(pj == int(caso[4]), "%s: el grupo de arriba juega %d partidos (%d)" % [pais, int(caso[4]), pj])
		_comprobar(l2.jornada_actual == int(caso[2]) + 1 and l2.formato.estado["grupos"][0] == g[0], "%s: guardar y abrir en la fase final conserva los grupos" % pais)

func _probar_fases_finales_grecia() -> void:
	_titulo("FASES FINALES · GRECIA: PLAY-OFFS DE CAMPEONATO, DE EUROPA Y PLAY-OUTS DEL DESCENSO")
	for semilla: int in [841, 842]:
		Azar.sembrar(semilla)
		var m := Mundo.new()
		m.generar(["GRE", "CHI", "ESP"], semilla)
		var l := _liga_de(m, "GRE")
		_comprobar(l.clubes.size() == 14 and l.formato != null and l.formato.f1 == 26 and l.jornadas() == 36, "%d: 14 clubes, 26 fechas de fase regular y 10 de play-offs (%d en total)" % [semilla, l.jornadas()])
		while l.jornada_actual < 26:
			l.jugar_jornada()
		var g: Array = l.formato.estado["grupos"]
		_comprobar(g.size() == 3 and g[0].size() == 4 and g[1].size() == 4 and g[2].size() == 6, "grupos de 4, 4 y 6 clubes (%s)" % str(g.map(func(x: Array) -> int: return x.size())))
		var mitad_ok := true
		for id: String in g[0] + g[1] + g[2]:
			var d: Dictionary = l.tabla_puntos[id]
			mitad_ok = mitad_ok and int(d["pts"]) == (3 * int(d["g"]) + int(d["e"]) + 1) / 2
		_comprobar(mitad_ok, "todos entran con la mitad de los puntos (hacia arriba)")
		var l2 := _recargar(m, l)
		_comprobar(l2.jornada_actual == 26 and l2.formato.estado["grupos"][2] == g[2], "guardar y abrir en la fase final conserva los tres grupos")
		l.jugar_temporada()
		var t := l.tabla()
		_comprobar(g[0].has((t[0]["club"] as Club).id) and l.orden_final.size() == 14, "%d: el campeón (%s) sale del play-off de campeonato" % [semilla, (t[0]["club"] as Club).nombre])
		var bajan: Array = t.slice(t.size() - 2)
		_comprobar(bajan.all(func(f: Dictionary) -> bool: return (g[2] as Array).has((f["club"] as Club).id)), "los 2 que bajan salen del play-out")
		_comprobar(int(l.tabla_puntos[g[0][0]]["pj"]) == 32 and int(l.tabla_puntos[g[2][0]]["pj"]) == 36, "partidos: 26+6 arriba y 26+10 en el play-out")
		_comprobar(l.formato.secciones(l).size() == 3, "la ficha muestra los tres grupos")
