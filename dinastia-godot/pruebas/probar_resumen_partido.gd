extends Node
## EL RESUMEN DEL DESCANSO Y DEL FINAL, EN EL BANCO (17-11, Auditoría): con tres partidos de tres países jugados enteros con el simulador, las cifras
## del resumen son las REALES del `Partido`, los PASES solo salen si el partido se jugó en el césped (meta «pases»), los goleadores cuadran con el
## marcador y el resumen se monta (final y descanso) sin errores. `correr(padre)` lo usa el banco (grupo «avance»).

var fallos := 0

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO ", msg)

func correr(padre: Node) -> int:
	for cfg: Array in [["BRA", 3], ["ITA", 7], ["MEX", 11]]:
		var m := Mundo.new()
		var ps: Array[String] = [String(cfg[0])]
		m.generar(ps, 720 + int(cfg[1]))
		var liga: Liga = m.ligas[0]
		m.tomar_el_mando(liga.clubes[int(cfg[1]) % liga.clubes.size()].id)
		var mio := m.mi_club()
		var rival: Club = liga.clubes[(int(cfg[1]) + 5) % liga.clubes.size()]
		var p := Partido.new(mio, rival)
		p.preparar()
		while not p.terminado_ya:
			p.simular_minuto()
		var filas := ResumenPartidoCine.estadisticas(p)
		var rotulos: Array = filas.map(func(f: Array) -> String: return String(f[0]))
		_ok(not rotulos.has("Pases"), "%s: sin jugar en el césped no salen pases (ni ceros inventados)" % cfg[0])
		_ok(rotulos.has("Posesión %") and rotulos.has("Faltas") and rotulos.has("Córners"), "%s: salen posesión, faltas y córners" % cfg[0])
		for f: Array in filas:
			if String(f[0]) == "Tiros":
				_ok(int(f[1]) == p.remates_local and int(f[2]) == p.remates_visita, "%s: los tiros son los del partido" % cfg[0])
			if String(f[0]) == "Posesión %":
				_ok(int(f[1]) + int(f[2]) == 100, "%s: la posesión suma 100" % cfg[0])
		var goles_l := 0
		for g: String in ResumenPartidoCine.goleadores(p, p.local):
			goles_l += g.count("'")
		_ok(goles_l == p.goles_local, "%s: los minutos de los goleadores locales (%d) cuadran con su marcador (%d)" % [cfg[0], goles_l, p.goles_local])
		## «Repetición de los goles» (17-11, prueba de extremo a extremo: salía vacía): el filtro «goles» deja exactamente los goles del partido.
		var de_gol := MomentosPartido.lista_de(p, mio).filter(func(m: Dictionary) -> bool: return String(m.get("tipo", "")) == "gol")
		_ok(de_gol.size() == mini(p.goles_local + p.goles_visita, MomentosPartido.MAX), "%s: los momentos de gol son los goles del partido (%d de %d)" % [cfg[0], de_gol.size(), p.goles_local + p.goles_visita])
		## TARJETAS (17-11, Auditoría): las del simulado quedan por equipo y en la crónica; las del 3D (`tarjeta_externa`) también.
		var en_cronica := p.cronica.filter(func(e: Dictionary) -> bool: return String(e.get("tipo", "")) in ["amarilla", "roja"])
		_ok(p.amarillas_local + p.amarillas_visita + p.rojas_local + p.rojas_visita >= en_cronica.size(), "%s: cada tarjeta de la crónica está contada" % cfg[0])
		for f: Array in filas:
			if String(f[0]) == "Tarjetas amarillas":
				_ok(int(f[1]) == p.amarillas_local and int(f[2]) == p.amarillas_visita, "%s: las amarillas del resumen son las del partido" % cfg[0])
		_ok(rotulos.has("Tarjetas amarillas"), "%s: sale la fila de amarillas" % cfg[0])
		var ext: Jugador = null
		for j: Jugador in p.once_visita:
			if ext == null and p.amarillas_hoy(j.id) == 0:
				ext = j   ## uno sin tarjetas hoy
		var antes_a := p.amarillas_visita
		p.tarjeta_externa(ext.id, false)
		p.tarjeta_externa(ext.id, false)   ## la 2.ª amarilla es roja
		_ok(p.amarillas_visita == antes_a + 2 and p.rojas_visita >= 1, "%s: 2 amarillas del 3D = 2 amarillas y 1 roja de la visita" % cfg[0])
		var suyas := ResumenPartidoCine.tarjetas(p, p.visita).filter(func(t: Array) -> bool: return String(t[0]).ends_with("%d'" % p.minuto))
		_ok(suyas.size() == 2 and bool(suyas[1][1]), "%s: las tarjetas del 3D salen en la lista del club con su minuto (amarilla y roja)" % cfg[0])
		p.set_meta("pases", [[312, 280], [270, 221]])
		var con := ResumenPartidoCine.estadisticas(p).map(func(f: Array) -> String: return String(f[0]))
		_ok(con.has("Pases") and con.has("Precisión de pase %"), "%s: jugado en el césped, salen los pases y su precisión" % cfg[0])
		for descanso: bool in [false, true]:
			var raiz := Control.new()
			padre.add_child(raiz)
			ResumenPartidoCine.montar(raiz, p, mio, descanso)
			var hay := false
			for l in raiz.find_children("*", "Label", true, false):
				if (l as Label).text == "%d - %d" % [p.goles_local, p.goles_visita]:
					hay = true
			_ok(hay, "%s: el %s muestra el marcador" % [cfg[0], "descanso" if descanso else "final"])
			raiz.free()
	return fallos
