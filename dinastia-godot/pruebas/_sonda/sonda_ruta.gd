extends Node
## SONDA DEL RITMO DE «LA RUTA»: juega N temporadas simuladas con un jugador
## sensato (descansa con menos de 40 de energía, entrena lo más bajo de lo que
## le sirve a su puesto, resuelve la primera opción) y escribe, por temporada,
## media, nivel, capítulo, fama, partidos, goles, nota y energía media.
##   PUESTO=DC TEMPORADAS=6 SEMILLA=7 godot --headless --path . res://pruebas/_sonda/sonda_ruta.tscn
func _ready() -> void:
	var puesto := OS.get_environment("PUESTO") if OS.get_environment("PUESTO") != "" else "DC"
	var n := maxi(1, int(OS.get_environment("TEMPORADAS"))) if OS.get_environment("TEMPORADAS") != "" else 5
	var semilla := int(OS.get_environment("SEMILLA")) if OS.get_environment("SEMILLA") != "" else 7
	var m := Mundo.new()
	m.generar(LigasActivas.para_generar(), semilla)
	m.mi_club_id = ""
	var c := CarreraJugador.crear(m, "Sonda Ruta", puesto, false, semilla)
	m.carrera_jugador = c
	var of := CarreraComienzo.pruebas(m, semilla)
	CarreraComienzo.mudar(c, m, of[semilla % of.size()])
	print("SONDA %s en %s (%s)" % [puesto, c.club(m).nombre, c.club(m).pais])
	for t in n:
		var energia := 0
		var semanas := 0
		var tope := 80
		while m.temporada_en_curso() and tope > 0:
			tope -= 1
			var j := c.jugador(m)
			while not c.eventos.is_empty():
				c.resolver(m, 0, 0)
			if not c.ofertas.is_empty() and (m.clubes.get(String(c.ofertas[0]["club_id"])) as Club).rep > c.club(m).rep + 3:
				c.aceptar_oferta(m, 0)
			var focos := CarreraPortero.focos_para(j)
			if c.energia < 40:
				c.foco = "descanso"
			else:
				var mejor := ""
				for f: String in focos:
					var a := String(focos[f][1])
					if a != "" and j.atributos.has(a) and (mejor == "" or int(j.atributos[a]) < int(j.atributos[String(focos[mejor][1])])):
						mejor = f
				c.foco = mejor
			c.entrenar(m)
			## (16-11) La semana en el orden de la interfaz (`CarreraJugadorUI._cerrar_semana`, camino simulado).
			var titular := c.es_titular(m)
			var antes := CarreraSemana.foto(j)
			var previo: Variant = CarreraSemana.meter_en_el_once(c, m) if titular else null
			CarreraRuta.retos(c, m)
			m.avanzar_semana(null)
			CarreraSemana.soltar_once(c, m, previo)
			if titular:
				var dm := CarreraSemana.lo_del_mundo(j, antes)
				var g := int(dm["goles"])
				var nota := clampf(5.6 + float(j.ovr - 55) * 0.04 + float(g) * 0.9 + randf_range(-0.6, 0.6), 4.0, 9.5)
				c.tras_partido(m, {"minutos": 90, "goles": g, "asist": int(dm["asist"]), "nota": snappedf(nota, 0.1), "titular": true,
					"encajados": randi_range(0, 2), "en_mundo": dm["en_mundo"]})
			c.semana(m)
			energia += c.energia
			semanas += 1
		var j2 := c.jugador(m)
		var s: Dictionary = c.stats_temp
		print("T%d %s | media %d (techo %d) edad %d | nivel %d %s | fama %d rel %d | pj %d goles %d asist %d nota %.2f | energia media %d | talentos %d+%d | premios %s" % [
			t + 1, c.club(m).nombre, j2.ovr, j2.pot, j2.edad, CarreraRuta.nivel(c), CarreraRuta.capitulo(c)[1], c.fama, c.relacion_dt,
			int(s["pj"]), int(s["goles"]), int(s["asist"]), c.nota_media(), energia / maxi(1, semanas), (c.ruta["talentos"] as Dictionary).size(), int(c.ruta["puntos"]),
			""])
		CarreraSemana.cerrar_temporada(c, m)
		## (16-11, R-03) Con quién compites por los premios de nota: la mejor nota de temporada de tu liga (15+ partidos) y la del club (10+).
		var liga := CarreraRuta._liga_de(m, c.club(m))
		var top_liga := 0.0
		var top_club := 0.0
		for cl: Club in (liga.clubes if liga != null else []):
			for o: Jugador in cl.plantilla:
				if o != j2:
					top_liga = maxf(top_liga, o.media_temporada(CarreraPremios.PJ_LIGA))
					if cl == c.club(m):
						top_club = maxf(top_club, o.media_temporada(CarreraPremios.PJ_CLUB))
		print("   ficha del mundo: pj %d goles %d asist %d · hab libres %d · mejor nota rival: club %.2f, liga %.2f" % [j2.partidos, j2.goles, j2.asistencias, CarreraHabilidad.puntos(c), top_club, top_liga])
		print("   premios: %s · misiones cobradas: %s" % [str((c.ruta["temporada"] as Dictionary)["premios"]), str((c.ruta.get("misiones_hechas", {}) as Dictionary).keys())])
		m.nueva_temporada()
	get_tree().quit()
