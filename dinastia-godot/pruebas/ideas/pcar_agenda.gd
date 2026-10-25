extends BaseIdea
## Carrera de Jugador: la agenda de la semana (M-263), sus eventos únicos y la
## progresión visible. Efecto real, guardado y partidas viejas.

func _probar() -> void:
	_titulo("PCAR: AGENDA DE LA CARRERA")
	var m := _mundo(4242)
	var c := CarreraJugador.crear(m, "Tomás Prueba", "DC", false, 77)
	var j := c.jugador(m)
	_comprobar(j != null, "la carrera tiene jugador")
	_comprobar(c.agenda == "normal", "la agenda empieza en semana normal")
	## Descanso: más energía que una semana normal.
	c.energia = 40
	c.agenda = "normal"
	c.semana(m)
	var e_normal := c.energia
	c.energia = 40
	c.agenda = "descanso"
	c.semana(m)
	_comprobar(c.energia == e_normal + 12, "el descanso da +12 de energía (%d vs %d)" % [c.energia, e_normal])
	## Vida social: seguidores, y con poca energía el DT se enfada.
	c.agenda = "social"
	c.energia = 90
	var seg := c.seguidores
	var rel := c.relacion_dt
	CarreraAgenda.aplicar(c, j)
	_comprobar(c.seguidores >= seg + 40, "la vida social da seguidores (%d → %d)" % [seg, c.seguidores])
	_comprobar(c.relacion_dt == rel, "con energía, el DT no se queja")
	c.energia = 20
	CarreraAgenda.aplicar(c, j)
	_comprobar(c.relacion_dt == rel - 2, "cansado y de fiesta, −2 de relación con el DT")
	CarreraAgenda.aplicar(c, j)
	_comprobar(c.racha_social == 3, "tres semanas sociales seguidas")
	var ids: Array = CarreraAgenda.eventos(c, j).map(func(e: Dictionary) -> String: return String(e["id"]))
	_comprobar(ids.has("foto_viral"), "tras tres semanas de salidas puede salir la foto viral")
	c.agenda = "extra"
	CarreraAgenda.aplicar(c, j)
	_comprobar(c.racha_social == 0, "otra agenda corta la racha social")
	## Sesión extra: entrena mejor (frecuencia de mejora en 300 semanas).
	var mejoras := [0, 0]
	for k in 2:
		var mm := _mundo(4242)
		var cc := CarreraJugador.crear(mm, "Otro", "DC", false, 99)
		cc.agenda = "extra" if k == 1 else "normal"
		for _i in 300:
			cc.energia = 90
			var jj := cc.jugador(mm)
			var antes := int(jj.atributos["tir"])
			cc.entrenar(mm)
			if int(jj.atributos["tir"]) > antes:
				mejoras[k] += 1
			jj.atributos["tir"] = antes
	_comprobar(mejoras[1] > mejoras[0], "la sesión extra mejora más a menudo (%d > %d)" % [mejoras[1], mejoras[0]])
	## Eventos de trayectoria.
	c.goles_carrera = 10
	c.pj_carrera = 100
	ids = CarreraAgenda.eventos(c, j).map(func(e: Dictionary) -> String: return String(e["id"]))
	_comprobar(ids.has("goles_10") and ids.has("partidos_100"), "diez goles y cien partidos dan su evento")
	c.hitos["goles_10"] = true
	ids = CarreraAgenda.eventos(c, j).map(func(e: Dictionary) -> String: return String(e["id"]))
	_comprobar(not ids.has("goles_10"), "un evento único no se repite")
	_comprobar(c._eventos_posibles(m, j).any(func(e: Dictionary) -> bool: return String(e["id"]) == "partidos_100"),
		"los eventos nuevos entran en el sorteo de la semana")
	## Progresión visible y temporadas con su media.
	c.ovr_inicio = j.ovr - 3
	_comprobar(CarreraAgenda.progreso(c, j) == 3, "la progresión de la temporada se ve (+3)")
	c.fin_de_temporada(m)
	_comprobar(int(c.temporadas[-1].get("ovr", 0)) == j.ovr, "la temporada guarda tu media")
	_comprobar(c.ovr_inicio == j.ovr, "la temporada nueva empieza a contar desde tu media")
	## Guardado.
	c.agenda = "social"
	c.racha_social = 2
	var c2 := CarreraJugador.desde_dic(JSON.parse_string(JSON.stringify(c.a_dic())))
	_comprobar(c2.agenda == "social" and c2.racha_social == 2 and c2.ovr_inicio == c.ovr_inicio, "la agenda se guarda y se carga")
	var viejo := c.a_dic()
	viejo.erase("agenda"); viejo.erase("racha_social"); viejo.erase("ovr_inicio")
	var c3 := CarreraJugador.desde_dic(viejo)
	_comprobar(c3.agenda == "normal" and c3.ovr_inicio == -1, "una partida vieja carga con semana normal")
	viejo["agenda"] = "inventada"
	_comprobar(CarreraJugador.desde_dic(viejo).agenda == "normal", "una agenda desconocida vuelve a normal")
