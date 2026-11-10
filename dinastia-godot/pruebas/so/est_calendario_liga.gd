extends BaseSO
## ESTÁNDAR · calendario y reglas de la liga en un mundo real generado: cada club juega una vez por jornada, cada pareja se enfrenta dos
## veces (ida y vuelta, una de local y otra de visita), la temporada completa deja la tabla cuadrada (partidos, goles a favor = en contra,
## puntos = 3·victorias + empates) y una sanción resta de verdad.
func _nombre() -> String:
	return "est_calendario_liga"

func _probar() -> void:
	_titulo("ESTÁNDAR · calendario y tabla de la liga [%s]" % sistema())
	var m := _mundo(20261105)
	var revisadas := 0
	for l: Liga in m.ligas:
		if l.clubes.size() < 4 or l.clubes.size() % 2 != 0 or l.formato != null:   ## (10-11) las ligas con formato propio (zonas, grupos, playoffs: Argentina, Egipto, MLS) no son un todos-contra-todos doble: sus fases tienen sus propias pruebas
			continue
		revisadas += 1
		var n := l.clubes.size()
		var una_vuelta := n > Liga.UNA_VUELTA_DESDE   ## (10-11) más de 20 clubes: una sola vuelta (Liga.UNA_VUELTA_DESDE)
		var esperadas := (n - 1) if una_vuelta else 2 * (n - 1)
		_comprobar(l.jornadas() == esperadas, "%s (%d clubes): %d jornadas = %s" % [l.nombre, n, l.jornadas(), "n−1 (una vuelta)" if una_vuelta else "2·(n−1)"])
		var parejas := {}
		var repetido_en_jornada := false
		var contra_si_mismo := false
		for jornada: Array in l.calendario:
			var vistos := {}
			for par: Array in jornada:
				var a: Club = par[0]
				var b: Club = par[1]
				contra_si_mismo = contra_si_mismo or a == b
				repetido_en_jornada = repetido_en_jornada or vistos.has(a.id) or vistos.has(b.id)
				vistos[a.id] = true
				vistos[b.id] = true
				parejas["%s>%s" % [a.id, b.id]] = int(parejas.get("%s>%s" % [a.id, b.id], 0)) + 1
			repetido_en_jornada = repetido_en_jornada or vistos.size() != n
		_comprobar(not contra_si_mismo, "%s: nadie juega contra sí mismo" % l.nombre)
		_comprobar(not repetido_en_jornada, "%s: en cada jornada juegan todos los clubes exactamente una vez" % l.nombre)
		var ida_vuelta := parejas.size() == (n * (n - 1) / 2 if una_vuelta else n * (n - 1))
		for k in parejas:
			ida_vuelta = ida_vuelta and parejas[k] == 1
		_comprobar(ida_vuelta, "%s: %s (%d cruces)" % [l.nombre, "cada pareja se enfrenta una vez" if una_vuelta else "cada pareja juega una vez de local y otra de visita", parejas.size()])
		var sancionado := l.clubes[0].id
		l.sancionar(sancionado, 3)
		_comprobar(int(l.tabla_puntos[sancionado]["pts"]) == -3 and int(l.tabla_puntos[sancionado]["sancion"]) == 3, "%s: sancionar(3) deja −3 puntos y lo anota" % l.nombre)
		var tabla := l.jugar_temporada()
		var pj := 0
		var gf := 0
		var gc := 0
		var pts := 0
		var empates := 0
		var victorias := 0
		for f: Dictionary in tabla:
			pj += int(f["pj"])
			gf += int(f["gf"])
			gc += int(f["gc"])
			pts += int(f["pts"]) + int(f["sancion"])
			empates += int(f["e"])
			victorias += int(f["g"])
			_comprobar(int(f["g"]) + int(f["e"]) + int(f["p"]) == int(f["pj"]) and int(f["pj"]) == esperadas, "%s: G+E+P = PJ = %d en %s" % [l.nombre, esperadas, (f["club"] as Club).nombre])
		_comprobar(pj == n * esperadas, "%s: %d partidos jugados en total" % [l.nombre, pj])
		_comprobar(gf == gc, "%s: goles a favor (%d) = goles en contra (%d)" % [l.nombre, gf, gc])
		_comprobar(pts == l.puntos_victoria * victorias + empates, "%s: puntos = %d·victorias + empates (%d)" % [l.nombre, l.puntos_victoria, pts])
		_comprobar(gf >= pj / 2 and gf <= pj * 5, "%s: %d goles en %d partidos (rango creíble)" % [l.nombre, gf, pj / 2])
		var ordenada := true
		for i in range(1, tabla.size()):
			ordenada = ordenada and int(tabla[i - 1]["pts"]) >= int(tabla[i]["pts"])
		_comprobar(ordenada, "%s: la tabla sale ordenada por puntos" % l.nombre)
		if revisadas >= 3:
			break
	_comprobar(revisadas >= 2, "se revisaron %d ligas" % revisadas)
