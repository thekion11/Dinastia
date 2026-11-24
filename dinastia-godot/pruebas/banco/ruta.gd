extends "res://pruebas/banco/ruta_p1.gd"
## (Parte 2 de 2 de `ruta.gd`.)

## Más goles en el simulado, pero solo en el modo jugador.
func _ru_goles_simulado() -> void:
	_ru_m.avanzar_semana(null)
	_comprobar(is_equal_approx(Partido.ctx_factor_goles, CarreraRuta.GOLES_SIMULADO), "  en el modo jugador el simulado convierte un %d %% más" % roundi((CarreraRuta.GOLES_SIMULADO - 1.0) * 100.0))
	var m_dt := Mundo.new()
	m_dt.generar(_ru_lista, _ru_seed)
	m_dt.tomar_el_mando(m_dt.ligas[0].clubes[1].id)
	m_dt.avanzar_semana(null)
	_comprobar(is_equal_approx(Partido.ctx_factor_goles, 1.0), "  y dirigiendo un club, lo de siempre")


## Estilo, curva y forma (13-11, inspirado en el modo jugador del FC 27, versión propia).
func _ru_estilo() -> void:
	var m_e := Mundo.new()
	m_e.generar(_ru_lista, _ru_seed + 1)
	m_e.mi_club_id = ""
	var c_e := CarreraJugador.crear(m_e, "Prueba Estilo", _ru_pos, true, _ru_seed)
	m_e.carrera_jugador = c_e
	var j_e := c_e.jugador(m_e)
	var linea_e := CarreraEstilo.de_linea(j_e.pos)
	_comprobar(linea_e.size() == 3, "  tu línea (%s) tiene tres estilos" % j_e.pos)
	var id_e := String(linea_e.keys()[1])
	var attrs_e: Dictionary = linea_e[id_e][2]
	var antes_e := {}
	for k_e: String in attrs_e:
		antes_e[k_e] = int(j_e.atributos[k_e])
	var pot_e := j_e.pot
	CarreraEstilo.aplicar(c_e, m_e, id_e, "tardia")
	var sube_e := true
	for k_e2: String in attrs_e:
		sube_e = sube_e and int(j_e.atributos[k_e2]) == mini(99, int(antes_e[k_e2]) + int(attrs_e[k_e2]))
	_comprobar(sube_e and CarreraEstilo.estilo(c_e) == id_e, "  el estilo «%s» sube sus dos atributos" % linea_e[id_e][0])
	_comprobar(j_e.pot == pot_e + 2 and CarreraRuta.techo(c_e, j_e) == pot_e + 2, "  la curva tardía sube el techo 2 puntos")
	CarreraEstilo.aplicar(c_e, m_e, String(linea_e.keys()[0]), "precoz")
	_comprobar(CarreraEstilo.estilo(c_e) == id_e and j_e.pot == pot_e + 2, "  y se elige una sola vez")
	var fav_e := CarreraEstilo.favorita(c_e, m_e)
	var guion_e := CarreraMomentos.guion(c_e, m_e)
	_comprobar(String(guion_e[0]["tipo"]) == fav_e and guion_e.size() == 4, "  su jugada favorita (%s) abre siempre Los Momentos" % fav_e)
	_comprobar(float(CarreraMomentos.zona(j_e, fav_e, 0, true)[0]) > float(CarreraMomentos.zona(j_e, fav_e)[0]) and float(CarreraMomentos.zona(j_e, fav_e, 3)[0]) >= float(CarreraMomentos.zona(j_e, fav_e, -3)[0]),
		"  la zona de la favorita es más ancha, y la forma la mueve")
	j_e.edad = 18
	_comprobar(not CarreraEstilo._empuja(c_e, j_e) and CarreraEstilo._frena(c_e, j_e), "  curva tardía: a los 18 frena")
	j_e.edad = 24
	_comprobar(CarreraEstilo._empuja(c_e, j_e) and not CarreraEstilo._frena(c_e, j_e), "  y a los 24 empuja")
	c_e.stats_temp["notas"] = [8.0, 7.9, 7.7]
	j_e.moral = 90
	c_e.energia = 90
	_comprobar(CarreraEstilo.forma(c_e, j_e) == 3 and CarreraEstilo.media_de_hoy(c_e, j_e) == j_e.ovr + 3, "  en racha, con ánimo y fresco: forma +3")
	c_e.stats_temp["notas"] = [5.2, 5.5, 5.0]
	j_e.moral = 40
	c_e.energia = 20
	_comprobar(CarreraEstilo.forma(c_e, j_e) == -3, "  mal, hundido y sin piernas: forma −3")
	var c_v := CarreraJugador.desde_dic(JSON.parse_string(JSON.stringify(c_e.a_dic())))
	_comprobar(CarreraEstilo.estilo(c_v) == id_e and CarreraEstilo.curva(c_v) == "tardia", "  estilo y curva se guardan con la partida")


## El cierre de temporada: el duelo y los premios, con su experiencia, una vez.
func _ru_cierre() -> void:
	_ru_c.stats_temp["goles"] = 30
	var d := CarreraRuta.duelo(_ru_c, _ru_m)
	_comprobar(int(d[0]) > int(d[1]), "  con 30 goles vas ganando el duelo a tu rival")
	_ru_c.stats_temp["pj"] = 32
	_ru_c.stats_temp["notas"] = [7.6, 7.4, 7.8]
	_ru_c.ovr_inicio = _ru_j.ovr - 5
	var fama0 := _ru_c.fama
	_ru_c.fin_de_temporada(_ru_m)
	var t: Dictionary = _ru_c.ruta["temporada"]
	var ids: Array = t["premios"]
	_comprobar(bool(t["gano_duelo"]) and int(_ru_c.ruta["duelos_ganados"]) == 1 and ids.has("duelo"), "  el cierre apunta el duelo ganado")
	_comprobar(ids.has("revelacion") and ids.has("goleador_club") and ids.has("once_ideal") and ids.has("hierro") and ids.has("salto"),
		"  premios del año: %s" % ", ".join(ids))
	_comprobar(_ru_c.fama > fama0 and int(t["pj"]) == 32 and int(t["goles"]) == 30 and int(_ru_c.stats_temp["pj"]) == 0, "  el resumen guarda tus números antes de ponerlos a cero")
	_comprobar(CarreraPremios.pendiente(_ru_c) and int(CarreraPremios.palmares(_ru_c).get("once_ideal", 0)) == 1, "  queda pendiente de enseñar y entra en tu palmarés")
	_ru_c.fin_de_temporada(_ru_m)
	_comprobar(not ((_ru_c.ruta["temporada"] as Dictionary)["premios"] as Array).has("revelacion"), "  la revelación solo se gana el primer año")
