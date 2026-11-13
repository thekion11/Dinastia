extends RefCounted
## [Banco · grupo «ruta», ayudante] Lo que pidió el dueño el 13-11 por la noche: experiencia por los trofeos del
## club, bono por racha, premios de la liga (goleador, asistidor, portero, mejor jugador) y las condiciones del
## brazalete (tres años en el club y de los tres de más media). Deja la carrera como estaba.

static func probar(b: Variant, c: CarreraJugador, m: Mundo, j: Jugador) -> void:
	var club := c.club(m)
	var guardado := {"stats": c.stats_temp.duplicate(true), "temporadas": c.temporadas.duplicate(true), "ovr": j.ovr, "racha": int(c.ruta["racha"]),
		"capitan": c.capitan, "palmares": m.palmares_mundo.duplicate(true), "grada": (c.ruta["grada"] as Array).duplicate(true), "ultimo": (c.ruta["ultimo"] as Dictionary).duplicate(true),
		"xp": int(c.ruta["xp"]), "nivel": int(c.ruta["nivel"]), "puntos": int(c.ruta["puntos"]), "hab": c.ruta.get("hab", 0), "hab_nivel": c.ruta.get("hab_nivel", 1)}
	## El bono por racha: al LLEGAR a 3, 5, 8 y 12.
	c.ruta["racha"] = 3
	var antes := CarreraRuta.nivel(c) * 100000 + int(c.ruta["xp"])
	b._comprobar(CarreraPremios.bono_racha(c) == 30 and CarreraRuta.nivel(c) * 100000 + int(c.ruta["xp"]) > antes, "  a los tres partidos seguidos a gran nivel, bono de racha")
	c.ruta["racha"] = 4
	b._comprobar(CarreraPremios.bono_racha(c) == 0, "  el bono no se repite en cada partido de la racha")
	## Los premios contra toda la liga.
	c.stats_temp = {"pj": 30, "titular": 30, "goles": 200, "asist": 150, "notas": []}
	for _i in 30:
		(c.stats_temp["notas"] as Array).append(9.6)
	var ids := CarreraPremios.ganados(c, m, false)
	b._comprobar(ids.has("goleador_liga") and ids.has("asistidor_liga") and ids.has("mvp_liga"), "  con la mejor temporada de la liga: goleador, asistidor y mejor jugador (%s)" % ", ".join(ids))
	b._comprobar(ids.has("portero_liga") == j.es_portero(), "  el premio al mejor portero es solo para porteros")
	c.stats_temp = {"pj": 30, "titular": 30, "goles": 1, "asist": 0, "notas": [6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0]}
	var flojos := CarreraPremios.ganados(c, m, false)
	b._comprobar(not flojos.has("goleador_liga") and not flojos.has("mvp_liga") and not flojos.has("mundial"), "  con una temporada floja, ninguno")
	for id: String in ["goleador_liga", "asistidor_liga", "portero_liga", "mvp_liga", "mvp_copa", "mvp_continental", "mundial"]:
		b._comprobar(CarreraPremios.PREMIOS.has(id) and int(CarreraPremios.PREMIOS[id][2]) > 0, "  premio «%s» con su experiencia" % CarreraPremios.PREMIOS[id][0])
	## Los trofeos del club.
	m.palmares_mundo.append({"anio": m.anio, "pais": club.pais, "torneo": "Copa de Prueba", "club": club.id})
	var copas := CarreraPremios.trofeos(m, club)
	var esta := false
	for t: Dictionary in copas:
		esta = esta or (String(t["nombre"]) == "Copa de Prueba" and CarreraPremios.XP_TROFEO.has(String(t["clase"])))
	b._comprobar(esta, "  un trofeo que gana tu club este año cuenta para la experiencia (%d)" % copas.size())
	## El brazalete: tres años en el club y de los tres de más media.
	c.temporadas = []
	j.ovr = 99
	b._comprobar(CarreraPremios.anios_en_club(c, m) == 0 and not CarreraPremios.apto_capitan(c, m), "  recién llegado no puede ser capitán, por bueno que sea")
	for _a in 3:
		c.temporadas.append({"anio": m.anio, "club": club.nombre, "pj": 30, "goles": 0, "asist": 0, "nota": 7.0, "ovr": 99})
	b._comprobar(CarreraPremios.anios_en_club(c, m) == 3 and CarreraPremios.apto_capitan(c, m), "  con tres años en el club y la mejor media, sí")
	var talentos: Dictionary = c.ruta["talentos"]
	var tenia := talentos.has("brazalete")
	talentos.erase("brazalete")
	var sin_talento := CarreraPremios.prob_capitan(c)
	talentos["brazalete"] = true
	b._comprobar(CarreraPremios.prob_capitan(c) > sin_talento + 0.3 and sin_talento > 0.0 and CarreraPremios.prob_capitan(c) < 1.0, "  el talento «Brazalete» no lo garantiza: sube la posibilidad (%.2f → %.2f)" % [sin_talento, CarreraPremios.prob_capitan(c)])
	if not tenia:
		talentos.erase("brazalete")
	j.ovr = 1
	b._comprobar(not CarreraPremios.apto_capitan(c, m), "  con tres años pero sin estar entre los mejores, no")
	c.temporadas.append({"anio": m.anio, "club": "Otro Club", "pj": 30, "goles": 0, "asist": 0, "nota": 7.0, "ovr": 99})
	b._comprobar(CarreraPremios.anios_en_club(c, m) == 0, "  los años cuentan seguidos y en el club de hoy")
	j.ovr = int(guardado["ovr"])
	c.stats_temp = guardado["stats"]; c.temporadas = guardado["temporadas"]; c.capitan = bool(guardado["capitan"]); m.palmares_mundo = guardado["palmares"]
	for k: String in ["racha", "grada", "ultimo", "xp", "nivel", "puntos", "hab", "hab_nivel"]:
		c.ruta[k] = guardado[k]
