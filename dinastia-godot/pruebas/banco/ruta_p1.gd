extends "res://pruebas/banco/base.gd"
## (Parte 1 de 2 de `ruta.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `ruta.gd`, conserva la clase.)

## [Banco · grupo «ruta»] «La Ruta», el modo jugador nuevo (13-11): núcleo y guardado.
## (21-11, refactor de la forma) La prueba de La Ruta se parte en secciones que comparten su
## estado en las variables `_ru_*`; el orden de ejecución y los textos son los de antes.

var _ru_m: Mundo
var _ru_c: CarreraJugador
var _ru_j: Jugador
var _ru_rv: Jugador
var _ru_lista: Array[String] = []
var _ru_pos := ""
var _ru_seed := 0
var _ru_attr := ""
var _ru_v0 := 0


func rv_club(m: Mundo, o: Jugador) -> Club:
	return m.clubes.get(o.club_id)


func _ru_ids_ev() -> Array:
	return CarreraEventosRuta.eventos(_ru_c, _ru_m).map(func(e: Dictionary) -> String: return String(e["id"]))


## «LA RUTA» DEL MODO JUGADOR (13-11): nivel, talentos, retos, racha, rival,
## toque del entreno y el club elegido al empezar. Con tres países y puestos.
func _probar_carrera_ruta() -> void:
	_titulo("LA RUTA DEL MODO JUGADOR (nivel, talentos, retos, racha y rival)")
	for caso: Array in [[["ARG", "ESP", "ITA"], "DC", 11], [["GER", "BRA", "FRA"], "DFC", 22], [["ENG", "CHI", "ESP"], "POR", 33]]:
		_ru_empezar(caso)
		_ru_arranque()
		_ru_partidazo()
		_ru_talentos()
		_ru_toque()
		_ru_momentos()
		_ru_eventos()
		_ru_eventos_cadena()
		_ru_logros()
		_ru_eventos_duelo()
		_ru_corte()
		_ru_pique_y_reset()
		_ru_vida()
		_ru_patrocinio()
		_ru_asentado()
		_ru_pulir()
		_ru_misiones()
		_ru_tope()
		_ru_techo()
		_ru_guardado()
		_ru_rival_lejos()
		call(&"_ru_goles_simulado")
		call(&"_ru_estilo")
		call(&"_ru_cierre")
	Partido.limpiar_contexto()


## Un club de caso (país, puesto y semilla) y la carrera del jugador en él.
func _ru_empezar(caso: Array) -> void:
	_ru_m = Mundo.new()
	var lista: Array[String] = []
	lista.assign(caso[0])
	_ru_lista = lista
	_ru_m.generar(lista, int(caso[2]))
	_ru_m.mi_club_id = ""
	_ru_c = CarreraJugador.crear(_ru_m, "Prueba Ruta", String(caso[1]), false, int(caso[2]))
	_ru_m.carrera_jugador = _ru_c
	_ru_pos = String(caso[1])
	_ru_seed = int(caso[2])


func _ru_arranque() -> void:
	var ofertas := CarreraComienzo.pruebas(_ru_m, _ru_seed)
	var paises := {}
	for cl: Club in ofertas:
		paises[cl.pais] = true
	_comprobar(ofertas.size() == 3 and paises.size() == 3, "%s: tres clubes de tres países te ofrecen contrato" % _ru_pos)
	CarreraComienzo.mudar(_ru_c, _ru_m, ofertas[2])
	_ru_j = _ru_c.jugador(_ru_m)
	_comprobar(_ru_c.club(_ru_m) == ofertas[2] and _ru_j.pais == ofertas[2].pais, "  empiezas en el club elegido (%s, %s)" % [ofertas[2].nombre, ofertas[2].pais])
	_ru_rv = CarreraRuta.rival(_ru_c, _ru_m)
	_comprobar(_ru_rv != null and _ru_rv.pos == _ru_j.pos and _ru_rv.club_id != _ru_j.club_id, "  tu rival es de tu línea y de otro club de tu liga")
	var retos := CarreraRuta.retos(_ru_c, _ru_m)
	_comprobar(retos.size() == 3 and CarreraRuta.retos(_ru_c, _ru_m) == retos, "  tres retos por semana, y no cambian al volver a mirar")
	for reto: Dictionary in retos:
		_comprobar((CarreraRuta.RETOS[String(reto["id"])][2] as Array).has(_ru_j.pos), "  el reto «%s» es de tu línea" % CarreraRuta.RETOS[String(reto["id"])][0])


## Un partidazo: cumple lo que se pueda y da experiencia.
func _ru_partidazo() -> void:
	var antes_nivel := CarreraRuta.nivel(_ru_c)
	_ru_c.tras_partido(_ru_m, {"minutos": 90, "goles": 3, "asist": 1, "nota": 8.6, "titular": true, "encajados": 0, "paradas": 5})
	var ult: Dictionary = _ru_c.ruta["ultimo"]
	var hechos := 0
	for h: Dictionary in ult["retos"]:
		hechos += 1 if bool(h["hecho"]) else 0
	_comprobar(hechos == 3 and int(ult["xp"]) > 60, "  con un partidazo se cumplen los tres retos (%d de experiencia)" % int(ult["xp"]))
	_comprobar(int(_ru_c.ruta["racha"]) == 1, "  empieza la racha")
	var xp0 := int(_ru_c.ruta["xp"]) + CarreraRuta.nivel(_ru_c) * 1000
	_ru_c.tras_partido(_ru_m, {"minutos": 90, "goles": 3, "asist": 1, "nota": 8.6, "titular": true, "encajados": 0, "paradas": 5})
	_comprobar(int(_ru_c.ruta["xp"]) + CarreraRuta.nivel(_ru_c) * 1000 > xp0, "  los retos ya cumplidos no se cobran dos veces, pero el partido sí da")
	_comprobar(CarreraRuta.nivel(_ru_c) > antes_nivel and int(_ru_c.ruta["puntos"]) >= 1, "  con dos partidazos subes de nivel y ganas un punto de talento")
	for h2: Dictionary in (_ru_c.ruta["ultimo"] as Dictionary)["retos"]:
		_comprobar(not bool(h2["hecho"]), "  (reto repetido sin premio)")
	_ru_c.tras_partido(_ru_m, {"minutos": 90, "goles": 0, "asist": 0, "nota": 5.0, "titular": true, "encajados": 3})
	_comprobar(int(_ru_c.ruta["racha"]) == 0 and int(_ru_c.ruta["mejor_racha"]) == 2, "  un mal partido corta la racha (la mejor queda en 2)")


## Talentos: en cadena dentro de la rama. Y «Ejemplo» sube la relación con el DT cada semana.
func _ru_talentos() -> void:
	_comprobar(not CarreraTalentos.puede_aprender(_ru_c, "pulmones"), "  el segundo talento de una rama pide el primero")
	_ru_c.ruta["puntos"] = 3
	_comprobar(CarreraTalentos.aprender(_ru_c, _ru_m, "ejemplo") and CarreraTalentos.aprender(_ru_c, _ru_m, "voz") and CarreraTalentos.aprender(_ru_c, _ru_m, "brazalete"), "  se aprende la rama Líder entera")
	_comprobar(not _ru_c.capitan and int(_ru_c.ruta["puntos"]) == 0 and not CarreraTalentos.aprender(_ru_c, _ru_m, "instinto"), "  recién llegado, el talento del brazalete aún no te hace capitán (pide tres años en el club); y sin puntos no hay más talentos")
	var rel := _ru_c.relacion_dt
	CarreraRuta.semana(_ru_c, _ru_m)
	_comprobar(_ru_c.relacion_dt == mini(100, rel + 1), "  «Ejemplo» suma relación con el DT cada semana")


## El toque del entreno: perfecto = mejora asegurada; una vez por semana.
func _ru_toque() -> void:
	_ru_c.foco = CarreraPortero.focos_para(_ru_j).keys()[0]
	_ru_attr = String(CarreraPortero.focos_para(_ru_j)[_ru_c.foco][1])
	_comprobar(CarreraRuta.anotar_toque(_ru_c, _ru_m, 1.0) and not CarreraRuta.anotar_toque(_ru_c, _ru_m, 0.2), "  el toque se anota una vez por semana")
	_ru_v0 = int(_ru_j.atributos[_ru_attr])
	_ru_c.entrenar(_ru_m)
	_comprobar(int(_ru_j.atributos[_ru_attr]) == _ru_v0 + 1, "  con toque perfecto el entreno mejora seguro (%s %d → %d)" % [_ru_attr, _ru_v0, int(_ru_j.atributos[_ru_attr])])
	_ru_c.entrenar(_ru_m)
	_comprobar(int(_ru_j.atributos[_ru_attr]) == _ru_v0 + 1, "  y no se entrena dos veces la misma semana")


## «Los Momentos»: cuatro jugadas del puesto; la calidad decide el partido.
func _ru_momentos() -> void:
	var guion := CarreraMomentos.guion(_ru_c, _ru_m)
	_comprobar(guion.size() == 4 and (CarreraMomentos.GUIONES[_ru_j.pos] as Array).has(String(guion[0]["tipo"])) and int(guion[0]["minuto"]) < int(guion[3]["minuto"]),
		"  cuatro jugadas de tu línea, en orden de minuto")
	_comprobar(CarreraMomentos.guion(_ru_c, _ru_m, 70).size() == 2 and int(CarreraMomentos.guion(_ru_c, _ru_m, 70)[0]["minuto"]) > 70, "  de suplente, dos jugadas desde que entras")
	var z0 := CarreraMomentos.zona(_ru_j, String(guion[0]["tipo"]))
	var a_m := String(CarreraMomentos.TIPOS[String(guion[0]["tipo"])][2])
	var guardado := int(_ru_j.atributos[a_m])
	_ru_j.atributos[a_m] = 95
	_comprobar(float(CarreraMomentos.zona(_ru_j, String(guion[0]["tipo"]))[0]) > float(z0[0]), "  con más atributo la zona perfecta es más ancha")
	_ru_j.atributos[a_m] = guardado
	var buenas: Array = []
	var malas: Array = []
	for mo: Dictionary in guion:
		buenas.append(CarreraMomentos.desenlace(String(mo["tipo"]), 1.0))
		malas.append(CarreraMomentos.desenlace(String(mo["tipo"]), 0.1))
	var par_m := [_ru_c.club(_ru_m), rv_club(_ru_m, _ru_rv)]
	var bien := CarreraMomentos.resultado(_ru_c, _ru_m, par_m, buenas)
	var mal := CarreraMomentos.resultado(_ru_c, _ru_m, par_m, malas)
	_comprobar(float(bien["nota"]) >= 8.0 and float(mal["nota"]) <= 5.0, "  cuatro perfectas dan nota %.1f; cuatro fallos, %.1f" % [float(bien["nota"]), float(mal["nota"])])
	_comprobar(int(bien["goles_local"]) - int(bien["goles_visita"]) > int(mal["goles_local"]) - int(mal["goles_visita"]), "  y el marcador lo nota (%d-%d contra %d-%d)" % [
		int(bien["goles_local"]), int(bien["goles_visita"]), int(mal["goles_local"]), int(mal["goles_visita"])])
	_comprobar(int(bien["goles"]) + int(bien["asist"]) + int(bien["paradas"]) + (1 if _ru_j.pos == "DEF" else 0) >= 1 and int(bien["encajados"]) == int(bien["goles_visita"]),
		"  el resumen trae goles, asistencias o paradas, y lo que encajó tu equipo")
	for tipo_m: String in CarreraMomentos.TIPOS:
		if not RutaPizarra.JUGADAS.has(tipo_m):
			_comprobar(false, "  la jugada «%s» no tiene dibujo en la pizarra" % tipo_m)
	## Con la selección: tu equipo es el de paso, sea local o visitante.
	var sel_m := CarreraMomentos.resultado(_ru_c, _ru_m, [rv_club(_ru_m, _ru_rv), _ru_c.club(_ru_m)], buenas, -1, false, rv_club(_ru_m, _ru_rv))
	_comprobar(int(sel_m["goles_local"]) >= int(sel_m["goles"]) + int(sel_m["asist"]), "  jugando con otro equipo (la selección), tus goles van a su marcador")
	var copa_m := CarreraMomentos.resultado(_ru_c, _ru_m, par_m, [], -1, true)
	_comprobar(int(copa_m["goles_local"]) != int(copa_m["goles_visita"]), "  en copa no hay empate")


## Los eventos de la ruta: salen de lo que te pasa y sus efectos se aplican.
func _ru_eventos() -> void:
	_ru_c.energia = 80
	_ru_c.ruta["racha"] = 0
	_comprobar(not _ru_ids_ev().has("ruta_racha") and not _ru_ids_ev().has("ruta_fundido"), "  sin racha ni cansancio no hay eventos de racha ni de preparador físico")
	_ru_c.ruta["racha"] = 3
	_ru_c.energia = 20
	_comprobar(_ru_ids_ev().has("ruta_racha") and _ru_ids_ev().has("ruta_fundido"), "  con racha de 3 habla la prensa; con 20 de energía te para el preparador")
	_ru_c.ruta["ahorros"] = _ru_j.sueldo * 20
	var lista_ev := CarreraEventosRuta.eventos(_ru_c, _ru_m)
	var primo: Dictionary = lista_ev.filter(func(e: Dictionary) -> bool: return String(e["id"]) == "ruta_primo")[0]
	_ru_c.eventos.append(primo)
	_ru_c.resolver(_ru_m, _ru_c.eventos.size() - 1, 0)
	_comprobar(CarreraVida.ahorros(_ru_c) == _ru_j.sueldo * 12, "  prestarle al primo cuesta ocho semanas de sueldo")
	var nivel_ev := CarreraRuta.nivel(_ru_c) * 100000 + int(_ru_c.ruta["xp"])
	CarreraEventosRuta.aplicar(_ru_c, _ru_m, {"ruta_xp": 60})
	_comprobar(CarreraRuta.nivel(_ru_c) * 100000 + int(_ru_c.ruta["xp"]) > nivel_ev, "  la hora extra con el veterano da experiencia")
	for e_r: Dictionary in lista_ev:
		_comprobar((e_r["opciones"] as Array).size() == 2 and String(e_r["texto"]).length() > 30, "  evento «%s» con dos salidas" % e_r["titulo"])


## En cadena: lo que elegiste trae otro evento semanas después. Y las habilidades y premios.
func _ru_eventos_cadena() -> void:
	_comprobar(CarreraEventosRuta.semanas_desde(_ru_c, _ru_m, "bar") == 0 and not _ru_ids_ev().has("ruta_bar"), "  recién prestado, el bar todavía no da noticias")
	(_ru_c.ruta["marcas"] as Dictionary)["bar"] = _ru_m.anio * 60 + _ru_m.semana - 15
	_comprobar(_ru_ids_ev().has("ruta_bar"), "  quince semanas después llega «El bar de tu primo»")
	for par: Array in [["botas", 12, "ruta_escuela"], ["veterano", 10, "ruta_legado"]]:
		CarreraEventosRuta.aplicar(_ru_c, _ru_m, {"ruta_marca": String(par[0])})
		var antes_cad: bool = _ru_ids_ev().has(String(par[2]))
		(_ru_c.ruta["marcas"] as Dictionary)[String(par[0])] = _ru_m.anio * 60 + _ru_m.semana - int(par[1])
		_comprobar(not antes_cad and _ru_ids_ev().has(String(par[2])), "  la marca «%s» trae su evento %d semanas después" % [par[0], par[1]])
	load("res://pruebas/banco/ruta_hab.gd").probar(self, _ru_c, _ru_m, _ru_j)
	load("res://pruebas/banco/ruta_premios.gd").probar(self, _ru_c, _ru_m, _ru_j)


## Los logros propios de La Ruta: se ganan una vez, dan experiencia y esperan a que la pantalla los anuncie.
func _ru_logros() -> void:
	var logros_guardados: Dictionary = CarreraLogros.ganados(_ru_c).duplicate()
	var cuenta_guardada: Dictionary = (_ru_c.ruta.get("cuenta", {}) as Dictionary).duplicate()
	CarreraLogros.ganados(_ru_c).clear()
	_ru_c.ruta["cuenta"] = {}
	var lg_antes := 0
	_ru_c.ruta["logros_nuevos"] = []
	var xp_lg := CarreraRuta.nivel(_ru_c) * 100000 + int(_ru_c.ruta["xp"])
	var nuevos_lg := CarreraLogros.tras_partido(_ru_c, _ru_m, {"minutos": 90, "goles": 3, "asist": 1, "nota": 9.2})
	_comprobar(nuevos_lg.has("triplete") and nuevos_lg.has("un_diez") and CarreraLogros.tiene(_ru_c, "doblete"), "  un partido de tres goles y nota 9 da «Triplete», «Doblete» y «Un diez» (%s)" % str(nuevos_lg))
	_comprobar(CarreraRuta.nivel(_ru_c) * 100000 + int(_ru_c.ruta["xp"]) > xp_lg and CarreraLogros.ganados(_ru_c).size() == lg_antes + nuevos_lg.size(), "  cada logro da experiencia y queda guardado")
	_comprobar(CarreraLogros.tras_partido(_ru_c, _ru_m, {"minutos": 90, "goles": 3, "asist": 0, "nota": 9.5}).is_empty(), "  un logro no se gana dos veces")
	_comprobar(CarreraLogros.tomar_nuevos(_ru_c).size() == nuevos_lg.size() and CarreraLogros.tomar_nuevos(_ru_c).is_empty(), "  la pantalla los anuncia una sola vez")
	for id_lg: String in CarreraLogros.LOGROS:
		var def_lg: Array = CarreraLogros.LOGROS[id_lg]
		_comprobar(def_lg.size() == 4 and int(def_lg[3]) > 0 and String(def_lg[2]).length() > 12, "  logro «%s» con su explicación y su premio" % def_lg[1])
	_ru_c.ruta["logros"] = logros_guardados
	_ru_c.ruta["cuenta"] = cuenta_guardada
	_ru_c.ruta["logros_nuevos"] = []


## Los eventos que nacen de los puntos sin gastar, del documental y del duelo por remontar.
func _ru_eventos_duelo() -> void:
	var puntos_ev := int(_ru_c.ruta["puntos"])
	_ru_c.ruta["puntos"] = 3
	_comprobar(_ru_ids_ev().has("ruta_estancado"), "  con tres puntos sin gastar, el preparador te lo dice")
	_ru_c.ruta["puntos"] = puntos_ev
	CarreraEventosRuta.aplicar(_ru_c, _ru_m, {"ruta_marca": "docu"})
	var antes_docu: bool = _ru_ids_ev().has("ruta_estreno")
	(_ru_c.ruta["marcas"] as Dictionary)["docu"] = _ru_m.anio * 60 + _ru_m.semana - 14
	_comprobar(not antes_docu and _ru_ids_ev().has("ruta_estreno"), "  el documental se estrena catorce semanas después de aceptarlo")
	CarreraEventosRuta.aplicar(_ru_c, _ru_m, {"ruta_marca": "remontada"})
	_comprobar(_ru_ids_ev().has("ruta_burla"), "  si vas por detrás en el duelo, tu rival se ríe en la tele")
	CarreraEventosRuta.quitar_marca(_ru_c, "remontada")


## El corte del duelo a mitad de temporada: por detrás nace el objetivo de remontar.
func _ru_corte() -> void:
	var pj_corte := int(_ru_c.stats_temp["pj"])
	var goles_corte := int(_ru_c.stats_temp["goles"])
	if CarreraRuta.rival(_ru_c, _ru_m) != null:
		CarreraEventosRuta.quitar_marca(_ru_c, "corte")
		_ru_c.stats_temp["pj"] = 30
		_ru_c.stats_temp["goles"] = 0
		CarreraRuta.rival(_ru_c, _ru_m).goles += 40
		CarreraDuelo.corte(_ru_c, _ru_m)
		_comprobar(CarreraDuelo.por_remontar(_ru_c), "  a mitad de temporada, por detrás en el duelo: objetivo de remontarlo")
		var grada_corte := (_ru_c.ruta["grada"] as Array).size()
		CarreraDuelo.corte(_ru_c, _ru_m)
		_comprobar((_ru_c.ruta["grada"] as Array).size() == grada_corte, "  el corte se hace una sola vez por temporada")
		_comprobar(CarreraDuelo.cierre(_ru_c, true) == CarreraDuelo.XP_REMONTADA and not CarreraDuelo.por_remontar(_ru_c), "  remontarlo da experiencia extra y limpia el objetivo")
		CarreraRuta.rival(_ru_c, _ru_m).goles -= 40
		_ru_c.stats_temp["goles"] = 200
		CarreraDuelo.corte(_ru_c, _ru_m)
		_comprobar(not CarreraDuelo.por_remontar(_ru_c) and CarreraEventosRuta.tiene_marca(_ru_c, "corte"), "  y si mandas tú, premio y sin objetivo")
		CarreraDuelo.cierre(_ru_c, false)
	_ru_c.stats_temp["pj"] = pj_corte
	_ru_c.stats_temp["goles"] = goles_corte


## Si contestaste a tu rival en redes, el duelo se calienta. Luego se limpian las marcas y la energía.
func _ru_pique_y_reset() -> void:
	CarreraEventosRuta.aplicar(_ru_c, _ru_m, {"ruta_marca": "pique"})
	(_ru_c.ruta["marcas"] as Dictionary)["pique"] = _ru_m.anio * 60 + _ru_m.semana - 4
	_comprobar(_ru_ids_ev().has("ruta_pique"), "  y si contestaste a tu rival en redes, el duelo se calienta")
	CarreraEventosRuta.aplicar(_ru_c, _ru_m, {"ruta_marca": "duelo_doble"})
	_comprobar(CarreraEventosRuta.tiene_marca(_ru_c, "duelo_doble"), "  elegir «vale doble» deja la marca para el cierre del duelo")
	CarreraEventosRuta.quitar_marca(_ru_c, "duelo_doble")
	_ru_c.ruta["marcas"] = {}
	_ru_c.energia = 100
	_ru_c.ruta["racha"] = 0


## Tu vida: el sueldo se ahorra y lo comprado cambia la carrera.
func _ru_vida() -> void:
	_ru_c.ruta["ahorros"] = 0
	_ru_c.ruta["vida"] = {}
	var energia_v := _ru_c.energia
	CarreraVida.semana(_ru_c, _ru_m)
	_comprobar(CarreraVida.ahorros(_ru_c) == _ru_j.sueldo and not CarreraVida.puede_comprar(_ru_c, _ru_m, "fisio"), "  cada semana ahorras tu sueldo; con una semana no llega para el fisio")
	_ru_c.ruta["ahorros"] = CarreraVida.precio(_ru_c, _ru_m, "fisio") + CarreraVida.precio(_ru_c, _ru_m, "coche")
	var rel_v := _ru_c.relacion_dt
	_comprobar(CarreraVida.comprar(_ru_c, _ru_m, "fisio") and CarreraVida.comprar(_ru_c, _ru_m, "coche") and not CarreraVida.comprar(_ru_c, _ru_m, "coche") and CarreraVida.ahorros(_ru_c) == 0,
		"  compras el fisio y el deportivo, una vez cada uno, y te quedas a cero")
	_comprobar(_ru_c.relacion_dt == maxi(0, rel_v - 3), "  el deportivo le sienta mal al DT")
	_ru_c.energia = 50
	CarreraVida.semana(_ru_c, _ru_m)
	_comprobar(_ru_c.energia == 56 and CarreraVida.factor_xp(_ru_c) < 1.05, "  el fisio devuelve 6 de energía cada semana")
	_ru_c.energia = energia_v
	_ru_c.relacion_dt = rel_v
	_ru_c.ruta["vida"] = {}
	_ru_c.ruta["ahorros"] = 0


## El contrato de botas: llega con la fama, se elige marca y paga por partido.
func _ru_patrocinio() -> void:
	_ru_c.fama = 5
	_comprobar(CarreraPatrocinio.eventos(_ru_c).is_empty() and CarreraPatrocinio.etiqueta(_ru_c) == "", "  sin fama no hay marca que te quiera")
	_ru_c.fama = 16
	var of_b := CarreraPatrocinio.eventos(_ru_c)
	_comprobar(of_b.size() == 1 and (of_b[0]["opciones"] as Array).size() == 2, "  con 15 de fama llega la oferta de botas, con dos marcas")
	_ru_c.eventos.append(of_b[0])
	_ru_c.hitos["patro_1"] = true
	_ru_c.resolver(_ru_m, _ru_c.eventos.size() - 1, 0)
	_comprobar(CarreraPatrocinio.marca(_ru_c) == "rayo" and CarreraPatrocinio.nivel(_ru_c) == 1 and CarreraPatrocinio.eventos(_ru_c).is_empty(), "  firmas con Rayo I, y no te la vuelven a ofrecer")
	var pb := CarreraPatrocinio.premio(_ru_c, {"goles": 2, "asist": 1, "nota": 6.0, "minutos": 90}, false)
	_comprobar(int(pb[0]) == 60 and int(pb[1]) == 270, "  Rayo paga por gol y asistencia (%d XP, %d seguidores)" % [int(pb[0]), int(pb[1])])
	_ru_c.fama = 45
	_ru_c.eventos.append(CarreraPatrocinio.eventos(_ru_c)[0])
	_ru_c.resolver(_ru_m, _ru_c.eventos.size() - 1, 1)
	_comprobar(CarreraPatrocinio.etiqueta(_ru_c) == "👟 Roca II" and int(CarreraPatrocinio.premio(_ru_c, {"nota": 7.2}, false)[0]) == 37, "  con más fama, Roca II paga un 50 % más por partido de 7")
	_ru_c.fama = 5
	_ru_c.ruta["fama_ref"] = 5
	_ru_c.ruta["patro"] = {}


## Las ofertas esperan a que te asientes: 15 partidos y nota 6,3.
func _ru_asentado() -> void:
	_ru_c.pj_carrera = 3
	_comprobar(not CarreraRuta.asentado(_ru_c), "  con 3 partidos en el club nadie te ofrece nada todavía")
	_ru_c.pj_carrera = 3 + CarreraRuta.PARTIDOS_PARA_OFERTA
	_ru_c.ruta["pj_llegada"] = 3
	_ru_c.stats_temp["notas"] = [6.6, 6.4]
	_comprobar(CarreraRuta.asentado(_ru_c), "  con 15 partidos y nota 6,5 ya pueden llegar ofertas")
	_ru_c.stats_temp["notas"] = [5.9, 6.0]
	_comprobar(not CarreraRuta.asentado(_ru_c), "  y con nota 5,9 no")
	_ru_c.ruta["pj_llegada"] = 0
	_ru_c.pj_carrera = 3


## Pulir (16-11, R-08): un punto de talento vale lo que los puntos de habilidad de un nivel en esa zona; y la fama cuesta más de subir.
func _ru_pulir() -> void:
	_ru_c.ruta["puntos"] = 1
	var a0 := int(_ru_j.atributos[_ru_attr])
	var hab0 := CarreraHabilidad.puntos(_ru_c)
	_comprobar(CarreraTalentos.pulir(_ru_c, _ru_m, _ru_attr) and int(_ru_c.ruta["puntos"]) == 0 and not CarreraTalentos.pulir(_ru_c, _ru_m, _ru_attr), "  un punto de talento se cambia por los puntos de habilidad de un nivel")
	var apuntado := 0
	for par: Array in CarreraHabilidad.de_zona(_ru_attr):
		apuntado += int((_ru_c.ruta.get("pulidos", {}) as Dictionary).get(String(par[0]), 0))
	var sobra := CarreraHabilidad.puntos(_ru_c) - hab0
	_comprobar(int(_ru_j.atributos[_ru_attr]) >= a0 and sobra >= 0 and sobra <= CarreraHabilidad.PUNTOS_POR_NIVEL and (sobra == CarreraHabilidad.PUNTOS_POR_NIVEL or apuntado > 0),
		"  y se gastan en esa zona a su precio de hoy; lo que no alcanza queda como puntos de habilidad (%d → %d, sobran %d)" % [a0, int(_ru_j.atributos[_ru_attr]), sobra])
	_ru_j.atributos[_ru_attr] = a0
	_ru_c.ruta["hab"] = hab0
	_ru_c.ruta["fama_ref"] = 60
	_ru_c.fama = 72
	_ru_c.stats_temp["notas"] = [7.0]
	CarreraRuta.semana(_ru_c, _ru_m)
	_comprobar(_ru_c.fama > 60 and _ru_c.fama < 68, "  con 60 de fama, de 12 puntos ganados se quedan pocos (%d)" % _ru_c.fama)
	_ru_c.fama = 5
	_ru_c.ruta["fama_ref"] = 5


## Las misiones del capítulo: al cumplir las tres, un punto de talento.
func _ru_misiones() -> void:
	var cap := CarreraMisiones.capitulo_en_curso(_ru_c)
	_comprobar(cap == "Promesa" and not CarreraMisiones.cobrada(_ru_c, cap), "  las misiones empiezan por «Promesa»")
	var puntos0 := int(_ru_c.ruta["puntos"])
	_comprobar(CarreraMisiones.revisar(_ru_c, _ru_m).is_empty(), "  con 3 partidos todavía no se cobran")
	_ru_c.pj_carrera = 5
	_ru_c.seguidores = 1000
	_ru_j.ovr = maxi(_ru_j.ovr, 62)
	_comprobar(CarreraMisiones.revisar(_ru_c, _ru_m) == ["Promesa"] and int(_ru_c.ruta["puntos"]) >= puntos0 + 1, "  cumplidas las tres: +1 punto de talento")
	_comprobar(CarreraMisiones.revisar(_ru_c, _ru_m).is_empty() and CarreraMisiones.cobrada(_ru_c, "Promesa"), "  y no se cobran dos veces")
	for mi: Array in CarreraMisiones.MISIONES[CarreraMisiones.capitulo_en_curso(_ru_c)]:
		_comprobar(CarreraMisiones.texto(_ru_c, _ru_m, mi).find("%") < 0, "  misión con su meta: %s" % CarreraMisiones.texto(_ru_c, _ru_m, mi))
	_ru_c.ruta["puntos"] = 0


## Un atributo no se despega: a 14 de la media deja de subir.
func _ru_tope() -> void:
	_ru_j.atributos[_ru_attr] = mini(99, _ru_j.ovr + CarreraRuta.TOPE_SOBRE_MEDIA)
	_ru_c.entreno_semana = -1
	_ru_c.ruta["toque_semana"] = -1
	CarreraRuta.anotar_toque(_ru_c, _ru_m, 1.0)
	var tope0 := int(_ru_j.atributos[_ru_attr])
	_ru_c.entrenar(_ru_m)
	_comprobar(int(_ru_j.atributos[_ru_attr]) == tope0, "  un atributo a 14 puntos de tu media ya no sube (ni con toque perfecto)")
	_ru_j.atributos[_ru_attr] = _ru_v0 + 1


## El techo: entrenando no se pasa de tu mejor potencial + 3.
func _ru_techo() -> void:
	var ovr0 := _ru_j.ovr
	var pot0 := _ru_j.pot
	var t0 := CarreraRuta.techo(_ru_c, _ru_j)
	_ru_j.pot = t0 - 6
	_comprobar(CarreraRuta.techo(_ru_c, _ru_j) == t0, "  tu techo es el mejor potencial que has tenido (no baja con los años)")
	_ru_j.ovr = t0 + CarreraRuta.MARGEN_TECHO
	_ru_c.entreno_semana = -1
	var v_t := int(_ru_j.atributos[_ru_attr])
	_ru_c.entrenar(_ru_m)
	_comprobar(int(_ru_j.atributos[_ru_attr]) == v_t and CarreraRuta.en_el_techo(_ru_c, _ru_j), "  en el techo, entrenar ya no sube atributos")
	_ru_j.ovr = ovr0
	_ru_j.pot = pot0


## Guardar y cargar conserva la ruta, en memoria y en disco.
func _ru_guardado() -> void:
	var c2 := CarreraJugador.desde_dic(JSON.parse_string(JSON.stringify(_ru_c.a_dic())))
	_comprobar(CarreraRuta.nivel(c2) == CarreraRuta.nivel(_ru_c) and CarreraRuta.tiene(c2, "voz") and (c2.ruta["grada"] as Array).size() == (_ru_c.ruta["grada"] as Array).size(),
		"  la ruta se guarda y se carga igual")
	_comprobar(CarreraRuta.texto_grada((c2.ruta["grada"] as Array)[0]) != "", "  la grada tiene algo que decir")
	## Y en disco: la partida entera se guarda, se carga y la ruta vuelve igual.
	CarreraVida.semana(_ru_c, _ru_m)
	_ru_c.ruta["vida"] = {"fisio": true}
	_ru_c.ruta["patro"] = {"marca": "roca", "nivel": 2}
	var nombre_g := "prueba_ruta_%s" % _ru_pos.to_lower()
	_comprobar(Partida.guardar(_ru_m, nombre_g), "  la partida con la ruta se guarda en disco")
	var m3 := Partida.cargar(nombre_g)
	Partida.borrar(nombre_g)
	var c3: CarreraJugador = m3.carrera_jugador if m3 != null else null
	_comprobar(c3 != null and c3.jugador(m3) != null and c3.club(m3).nombre == _ru_c.club(_ru_m).nombre, "  al cargar sigues en tu club (%s)" % _ru_c.club(_ru_m).nombre)
	if c3 != null:
		_comprobar(CarreraRuta.nivel(c3) == CarreraRuta.nivel(_ru_c) and int(c3.ruta["xp"]) == int(_ru_c.ruta["xp"]) and CarreraVida.ahorros(c3) == CarreraVida.ahorros(_ru_c)
			and CarreraVida.tiene(c3, "fisio") and CarreraPatrocinio.etiqueta(c3) == "👟 Roca II" and CarreraMisiones.cobrada(c3, "Promesa") == CarreraMisiones.cobrada(_ru_c, "Promesa")
			and CarreraRuta.retos(c3, m3).size() == 3 and CarreraRuta.rival(c3, m3) != null and CarreraRuta.rival(c3, m3).id == CarreraRuta.rival(_ru_c, _ru_m).id,
			"  nivel, experiencia, ahorros, compras, botas, misiones, retos y rival vuelven igual")
	_ru_c.ruta["vida"] = {}
	_ru_c.ruta["patro"] = {}
	_ru_c.ruta["ahorros"] = 0


## Si ya eres mucho mejor que tu liga, el rival se busca en todo el mundo.
func _ru_rival_lejos() -> void:
	var ovr_r := _ru_j.ovr
	_ru_j.ovr = 93
	(_ru_c.ruta["rival"] as Dictionary).clear()
	var lejos := CarreraRuta.rival(_ru_c, _ru_m)
	_comprobar(lejos != null and lejos.pos == _ru_j.pos and lejos.ovr >= 80 and bool((_ru_c.ruta["rival"] as Dictionary)["fuera"]), "  con media 93 tu rival es de los mejores del mundo en tu línea (%s, %d)" % [lejos.nombre, lejos.ovr])
	_comprobar(CarreraRuta.rival(_ru_c, _ru_m) == lejos, "  y se conserva aunque no juegue en tu liga")
	_ru_j.ovr = ovr_r
	(_ru_c.ruta["rival"] as Dictionary).clear()
