extends "res://pruebas/banco/varios_p12.gd"
## [Capa 13 de `varios.gd`, 10-11] _probar_finalissima

## (10-11) La FINALISSIMA: campeón de Europa contra campeón de América, el año de los dos torneos, sin tocar el azar del juego.
func _probar_finalissima() -> void:
	_titulo("FINALISSIMA: CAMPEÓN DE EUROPA CONTRA CAMPEÓN DE AMÉRICA")
	_comprobar(Finalissima.toca(2028) and not Finalissima.toca(2027) and not Finalissima.toca(2030), "toca el año de la Eurocopa y la Copa América (2028 sí; 2027 y 2030 no)")
	for caso: Array in [[["ARG", "ESP"], "Argentina", 2028], [["MEX", "FRA"], "Francia", 2032]]:
		var m := Mundo.new()
		var paises: Array[String] = []
		paises.assign(caso[0])
		m.generar(paises, 77)
		m.tomar_el_mando(m.ligas[0].clubes[4].id)
		var s := m.selecciones
		s.cargo.ofrecer(String(caso[1]), s.fuerza(String(caso[1])), 800)
		s.cargo.responder(m, true)
		var estado: int = Azar._rng.state
		var f := Finalissima.jugar(s, m, int(caso[2]))
		_comprobar(not f.is_empty() and String(f["campeon"]) != String(f["rival"]) and Azar._rng.state == estado,
			"%d: campeona %s (final %s %d-%d) sin tocar el azar del juego" % [int(caso[2]), String(f.get("campeon", "")), String(f.get("local", "")), int(f.get("gl", 0)), int(f.get("gv", 0))])
		_comprobar(int(f.get("gl", 0)) != int(f.get("gv", 0)) or (f.get("penales", []) as Array).size() == 2, "con empate se decide por penaltis")
		_comprobar(Finalissima.jugar(s, m, int(caso[2])).is_empty() and s.finalissimas.size() == 1, "no se juega dos veces el mismo año")
		var mia := Nombres.limpiar(String(caso[1]))
		var jugo := Nombres.limpiar(String(f["campeon"])) == mia or Nombres.limpiar(String(f["rival"])) == mia
		var apuntada := s.cargo.historial.any(func(h: Dictionary) -> bool: return String(h["torneo"]) == Finalissima.NOMBRE)
		_comprobar(jugo == apuntada, "%s: en tu historial de seleccionador solo si tu selección la jugó (%s)" % [String(caso[1]), "la jugó" if jugo else "no la jugó"])
		var otro := Selecciones.new(m)
		otro.desde_dic(JSON.parse_string(JSON.stringify(s.a_dic())))
		_comprobar(otro.finalissimas.size() == 1 and String((otro.finalissimas[0] as Dictionary)["campeon"]) == String(f["campeon"]), "la Finalissima se guarda con la partida")

## (10-11) El fútbol de los JUEGOS OLÍMPICOS: 16 selecciones sub-23 (hasta 3 mayores) por cupos de confederación, sin tocar el azar del juego.
func _probar_olimpicos() -> void:
	_titulo("JUEGOS OLÍMPICOS: SUB-23 CON TRES MAYORES")
	_comprobar(Olimpicos.toca(2028) and Olimpicos.toca(2032) and not Olimpicos.toca(2030) and not Olimpicos.toca(2024), "cada cuatro años desde 2028")
	for caso: Array in [[["BRA", "ITA"], 2028], [["JPN", "NGA", "ENG"], 2032]]:
		var m := Mundo.new()
		var paises: Array[String] = []
		paises.assign(caso[0])
		m.generar(paises, 303)
		m.tomar_el_mando(m.ligas[0].clubes[2].id)
		var s := m.selecciones
		var nombres := Olimpicos.participantes(s)
		var sin_rep := {}
		for n: String in nombres:
			sin_rep[n] = true
		_comprobar(nombres.size() == Olimpicos.PLAZAS and sin_rep.size() == Olimpicos.PLAZAS, "%s: 16 selecciones distintas (%s…)" % [", ".join(caso[0]), ", ".join(nombres.slice(0, 4))])
		var pais_nombre := String((Datos.tabla("PAIS_SELECCION") as Dictionary).get(String((caso[0] as Array)[0]), ""))
		if nombres.has(pais_nombre):
			var eq := Olimpicos.equipo(s, m, pais_nombre, int(caso[1]))
			var mayores := eq.plantilla.filter(func(j: Jugador) -> bool: return j.edad > Olimpicos.EDAD_MAX and not j.id.begins_with(eq.id)).size()
			_comprobar(mayores <= Olimpicos.MAYORES and eq.nombre.ends_with("Sub-23") and eq.id.ends_with("_sub23"), "%s: como mucho %d mayores de 23 (%d) y su propio id" % [eq.nombre, Olimpicos.MAYORES, mayores])
		var estado: int = Azar._rng.state
		var f := Olimpicos.jugar(s, m, int(caso[1]))
		_comprobar(not f.is_empty() and String(f["oro"]) != String(f["plata"]) and Azar._rng.state == estado, "%d: oro %s, plata %s (%s) sin tocar el azar del juego" % [int(caso[1]), String(f.get("oro", "")), String(f.get("plata", "")), String(f.get("final", ""))])
		_comprobar(Olimpicos.jugar(s, m, int(caso[1])).is_empty() and s.olimpicos.size() == 1 and s.cargo.historial.is_empty(), "no se repite el mismo año y no cuenta como seleccionador")
		var otro := Selecciones.new(m)
		otro.desde_dic(JSON.parse_string(JSON.stringify(s.a_dic())))
		_comprobar(otro.olimpicos.size() == 1, "los Juegos se guardan con la partida")
