extends BaseIdea
## LA COPA EN LA CARRERA DE JUGADOR (26-10-2026, prefijo cop). Las semanas de copa el partido de tu club es
## el cruce de copa a partido único: empatado al 90' hay PRÓRROGA y, si sigue, TANDA DE PENALES en el césped
## (y tu penal lo tiras tú). El resultado («gana en penales») vuelve a la copa del núcleo y a la carrera, y
## los penales de la tanda no son goles ni tiros tuyos. Simulada, la copa también va a prórroga y penales.
## La liga empatada termina en el 90'.

const DT := 1.0 / 20.0
var _ui: CarreraJugadorUI

func _probar() -> void:
	PartidoJugable.con_ceremonia = false
	CarreraJugadorUI.mundo = null
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)
	_ui._crear()
	var m := CarreraJugadorUI.mundo
	var club := _ui.carrera.club(m)
	_titulo("COPA EN LA CARRERA: la semana de copa manda la copa")
	_llegar_a_semana_de_copa(m, club)
	var par := _ui._partido_de_la_semana(club)
	_comprobar(m.copa != null and m.copa.participantes.has(club), "la copa es la del país de tu club y tu club la juega")
	_comprobar(CarreraCopa.es_copa(m, par), "el partido de la semana de copa es el cruce de copa")
	_titulo("LIGA EMPATADA: sin prórroga")
	_liga(m, club)
	_titulo("COPA EMPATADA EN EL CÉSPED: prórroga, tanda y vuelta a la copa")
	_copa_en_cesped(m, club)
	_titulo("COPA SIMULADA: prórroga y penales")
	_copa_simulada()
	_titulo("CARRERA SIMULADA EN SEMANA DE COPA")
	_semana_de_copa_simulada(m, club)

## Semanas simuladas hasta la de copa; si el sorteo dejó fuera a tu club, se le hace sitio (preparación).
func _llegar_a_semana_de_copa(m: Mundo, club: Club) -> void:
	var n := 0
	while CarreraCopa.partido(m, club).is_empty() and n < 12:
		if m.copa != null and m.copa.en_curso() and not m.copa.vivos.has(club):
			var i := m.copa.vivos.size() - 1
			m.copa.participantes[m.copa.participantes.find(m.copa.vivos[i])] = club
			m.copa.vivos[i] = club
		if not CarreraCopa.partido(m, club).is_empty():
			break
		_ui._cerrar_semana({})
		n += 1

## Corre el motor con empates forzados al final de la segunda parte (y de la prórroga). En la tanda, cuando
## el lanzador eres tú, mantiene TIRO medio segundo (como un jugador) y suelta.
func _correr(pj: PartidoJugable, empatar_prorroga: bool) -> Dictionary:
	var motor := pj.motor
	motor.set_physics_process(false)
	motor._cambio_decidido = true
	## Durante el juego, tu futbolista en piloto automático (sin mando no lanzaría sus córners); en la
	## tanda vuelves a ser tú.
	motor.autopiloto = true
	var r := {"prorroga": false, "mios": 0, "apunto": false, "mitad_max": 0}
	var cargando := 0.0
	var pasos := 0
	while motor.estado != "fin" and pasos < 60 * 3000:
		pasos += 1
		r["mitad_max"] = maxi(int(r["mitad_max"]), motor.mitad)
		if motor.estado == "juego" and (motor.mitad == 2 or (motor.mitad == 4 and empatar_prorroga)) \
				and motor.goles[0] != motor.goles[1] and motor.t > motor.dur_mitad() + motor._anadido_de(motor.mitad) - 2.0:
			motor._gol(int(motor.goles[0]) < int(motor.goles[1]))
		if motor.prorroga:
			r["prorroga"] = true
		if motor.estado == "tanda":
			motor.autopiloto = false
		if motor.estado == "tanda" and motor.tanda_me_toca_tirar() and String(motor.tanda.get("fase", "")) == "apuntar":
			r["apunto"] = true
			if cargando <= 0.0:
				r["mios"] = int(r["mios"]) + 1
				Input.action_press("jugar_tiro")
			cargando += DT
			if cargando > 0.5:
				Input.action_release("jugar_tiro")
		elif cargando > 0.0:
			Input.action_release("jugar_tiro")
			cargando = 0.0
		motor.paso(DT)
	return r

func _liga(m: Mundo, club: Club) -> void:
	var lp := CarreraJugador.partido_de_la_semana(m, club)
	_comprobar(not CarreraCopa.es_copa(m, lp), "el partido de liga no es de copa")
	var pj := PartidoJugable.abrir(_ui, m, _ui.carrera, lp[0], lp[1], 20.0)
	_comprobar(not pj.motor.eliminatoria, "la liga no llega al motor como eliminatoria")
	var r := _correr(pj, false)
	var res := pj.resultado()
	_comprobar(pj.motor.estado == "fin" and int(res["goles_local"]) == int(res["goles_visita"]), "la liga acaba empatada (%d-%d)" % [res["goles_local"], res["goles_visita"]])
	_comprobar(not bool(r["prorroga"]) and int(r["mitad_max"]) == 2 and (res["penales"] as Array).is_empty(), "liga empatada: fin en el 90', sin prórroga ni penales")
	pj.queue_free()

func _copa_en_cesped(m: Mundo, club: Club) -> void:
	var par := _ui._partido_de_la_semana(club)
	var carrera := _ui.carrera
	var pj_antes := int(carrera.stats_temp["pj"])
	var goles_antes := int(carrera.stats_temp["goles"])
	_ui._jugar_partido()
	var pj: PartidoJugable = null
	for h: Node in _ui.get_children():
		if h is PartidoJugable:
			pj = h
	_comprobar(pj != null and pj.eliminatoria and pj.motor.eliminatoria, "«Jugar el partido» abre la copa como eliminatoria")
	if pj == null:
		return
	## Tu futbolista, el mejor tirador: tira el primer penal de su equipo.
	for p: Dictionary in pj.motor.jugadores:
		if String(p["id"]) == pj.motor.id_usuario:
			p["attr"]["tir"] = 0.99
	var r := _correr(pj, true)
	var motor := pj.motor
	var res := pj.resultado()
	_linea("  (motor: estado %s, mitad %d, goles %s, minuto %d, r %s)" % [motor.estado, motor.mitad, str(motor.goles), motor.minuto(), str(r)])
	var pen: Array = res["penales"]
	_comprobar(bool(r["prorroga"]) and bool(res["prorroga"]) and int(r["mitad_max"]) == 4, "copa empatada al 90': prórroga (2×15', hasta la mitad 4)")
	_comprobar(pen.size() == 2 and int(pen[0]) != int(pen[1]), "empate al 120': tanda con ganador (%s)" % str(pen))
	if motor.tanda.is_empty():
		pj.queue_free()
		return
	_comprobar(MotorJugable.tanda_decidida(motor.tanda["tiros"]), "la tanda acabó decidida, no cortada")
	_comprobar(int(r["mios"]) >= 1 and bool(r["apunto"]), "tu penal lo apuntas y lo tiras tú (%d)" % int(r["mios"]))
	_comprobar(int(motor.stats["tiros"]) == int(motor.tanda["stats_antes"]["tiros"]), "el penal de la tanda no suma a tus tiros")
	_comprobar(int(res["goles"]) == int(motor.stats["goles"]) and absf(float(res["nota"]) - float(motor.tanda["nota_usuario"])) < 0.01,
		"la tanda no cambia tus goles ni tu nota (%.1f)" % float(res["nota"]))
	var txt := ""
	for l: Label in pj._resumen.find_children("*", "Label", true, false):
		txt += l.text + "\n"
	_comprobar(txt.contains("gana %d-%d en los penales" % [maxi(int(pen[0]), int(pen[1])), mini(int(pen[0]), int(pen[1]))]), "el cuadro final dice quién gana en los penales")
	var ronda_antes := m.copa.historial.size()
	pj._cerrar()
	_comprobar(m.copa.historial.size() == ronda_antes + 1, "la ronda de copa se jugó esa semana")
	var mio: Dictionary = {}
	for x: Dictionary in m.copa.historial[-1]["resultados"]:
		if x["local"] == par[0] and x["visita"] == par[1]:
			mio = x
	_comprobar(not mio.is_empty() and int(mio["gl"]) == int(res["goles_local"]) and int(mio["gv"]) == int(res["goles_visita"]), "la copa anota el marcador del césped")
	_comprobar(not mio.is_empty() and mio["penales"] == pen, "la copa anota la tanda del césped (%s)" % str(mio.get("penales", [])))
	var gana: Club = par[0] if int(pen[0]) > int(pen[1]) else par[1]
	_comprobar(not mio.is_empty() and mio["pasa"] == gana, "pasa el que ganó en los penales (%s)" % Nombres.visible(gana.nombre))
	_comprobar(m.copa.vivos.has(gana) and not m.copa.vivos.has(par[1] if gana == par[0] else par[0]), "el que cae en los penales queda fuera de la copa")
	_comprobar(int(carrera.stats_temp["pj"]) == pj_antes + 1 and int(carrera.stats_temp["goles"]) == goles_antes + int(res["goles"]),
		"la carrera cuenta el partido y solo tus goles del juego (%d)" % int(res["goles"]))
	_comprobar(_ui._msg.contains("en los penales (%d-%d)" % ([int(pen[0]), int(pen[1])] if par[0] == club else [int(pen[1]), int(pen[0])])), "el aviso de la semana cuenta la tanda («%s»)" % _ui._msg.right(60))

func _copa_simulada() -> void:
	var mm := Mundo.new()
	mm.generar(["CHI"], 2611)
	var cl: Array = mm.ligas[0].clubes
	var a_prorroga := 0
	var a_penales := 0
	var mal := 0
	for i in 80:
		var p := Partido.new(cl[i % cl.size()], cl[(i * 7 + 3) % cl.size()] if (i * 7 + 3) % cl.size() != i % cl.size() else cl[(i + 1) % cl.size()])
		CarreraCopa.simular(p)
		var hubo := p.minutos_fin == Partido.MINUTOS + 30
		a_prorroga += 1 if hubo else 0
		if p.goles_local == p.goles_visita:
			a_penales += 1
			var pen := p.penales()
			if not hubo or pen.size() != 2 or int(pen[0]) == int(pen[1]):
				mal += 1
		if not p.terminado_ya or p.minuto != p.minutos_fin:
			mal += 1
	_comprobar(a_prorroga > 0 and a_penales > 0, "en 80 cruces simulados hay prórrogas (%d) y tandas (%d)" % [a_prorroga, a_penales])
	_comprobar(mal == 0, "todo empate final pasó por la prórroga y tiene tanda con ganador (%d mal)" % mal)
	var liga_120 := 0
	for i in 40:
		var q := Partido.new(cl[i % cl.size()], cl[(i + 2) % cl.size()])
		q.simular()
		liga_120 += 1 if q.minutos_fin != Partido.MINUTOS else 0
	_comprobar(liga_120 == 0, "la liga simulada nunca tiene prórroga")

func _semana_de_copa_simulada(m: Mundo, club: Club) -> void:
	if not m.copa.vivos.has(club):
		## Eliminado en los penales: se le vuelve a hacer sitio para probar la copa simulada (preparación).
		m.copa.vivos[0] = club
	_llegar_a_semana_de_copa(m, club)
	var par := CarreraCopa.partido(m, club)
	if par.is_empty():
		_comprobar(false, "hay otra semana de copa para simularla")
		return
	var ronda_antes := m.copa.historial.size()
	var pj_antes := int(_ui.carrera.stats_temp["pj"])
	_ui._cerrar_semana({})
	var mio: Dictionary = {}
	for x: Dictionary in m.copa.historial[-1]["resultados"]:
		if x["local"] == par[0] and x["visita"] == par[1]:
			mio = x
	_comprobar(m.copa.historial.size() == ronda_antes + 1 and not mio.is_empty(), "la semana simulada juega tu cruce de copa")
	_comprobar(mio.is_empty() or int(mio["gl"]) != int(mio["gv"]) or (mio["penales"] as Array).size() == 2, "si acabó empatado, con tanda")
	_comprobar(_ui._msg.contains("Copa: %s %d-%d" % [Nombres.visible(par[0].nombre), int(mio.get("gl", -1)), int(mio.get("gv", -1))]), "el aviso de la semana da el resultado de la copa")
	_comprobar(int(_ui.carrera.stats_temp["pj"]) >= pj_antes, "la carrera sigue sana tras la copa simulada")
