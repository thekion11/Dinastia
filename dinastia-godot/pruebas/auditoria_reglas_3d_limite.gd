extends Node
## CAZA DE FALLOS (4-11-2026, orden de la líder): el partido al límite de REGLAS (simulado y 3D deben dar lo mismo).
##   godot --headless --path . res://pruebas/auditoria_reglas_3d_limite.tscn
## (1) expulsiones hasta 7 y 6: el 3D y el simulado suspenden igual y con el mismo marcador de mesa; la roja en plena falta no revive el partido.
## (2) lesión con los cambios agotados: sale del campo y juega con uno menos; el portero lesionado sin relevo → un jugador de campo al arco (fuerza finita); con cambios, el suplente de su puesto entra solo.
## (3) no hay doble partido con goles de visita en este juego (copas y Champions: partido único, empate → prórroga y penales, ver `cop_prorroga_tanda`).
## (4) cambios durante una TANDA de penales o el DESCANSO en el motor 3D, y con un id que no existe. (5) la pausa táctica con 0 jugadores en el banco.
var _fallos := 0

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _ready() -> void:
	_siete()
	_lesiones()
	await _motor_cambios()
	await _banco_vacio()
	print("===== FIN. %d fallos =====" % _fallos)
	get_tree().quit(0 if _fallos == 0 else 1)

func _partido(semilla := 4711) -> Array:
	var m := Mundo.new()
	m.generar(["CHI"], semilla)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var p := Partido.new(a, b)
	p.preparar()
	return [m, a, b, p]

func _motor(a: Club, b: Club, eliminatoria := false) -> Array:
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	var lista: Array = []
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ball := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	var motor := MotorJugable.new()
	raiz.add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = true
	motor.eliminatoria = eliminatoria
	motor.tarjetas_reales = true
	motor.preparar(lista, ball, "", 7)
	return [motor, raiz, sp]

## (1)
func _siete() -> void:
	for lado_local in [true, false]:
		var r := _partido(100)
		var p: Partido = r[3]
		var once: Array[Jugador] = p.once_local if lado_local else p.once_visita
		if lado_local: p.gol_externo(true, "", "")
		else: p.gol_externo(false, "", "")
		var ids := once.filter(func(j: Jugador) -> bool: return not j.es_portero()).map(func(j: Jugador) -> String: return j.id)
		for k in 5:
			p.tarjeta_externa(String(ids[k]), true)
		var suspendido_a_6 := p.suspendido and p.terminado_ya
		var ml := p.goles_local
		var mv := p.goles_visita
		## El motor 3D, con el mismo marcador previo, da lo mismo.
		var r2 := _motor(r[1], r[2])
		var m: MotorJugable = r2[0]
		m.goles = [1, 0] if lado_local else [0, 1]
		var mios: Array = m.jugadores.filter(func(q: Dictionary) -> bool: return bool(q["es_local"]) == lado_local and not bool(q["por"]))
		for k in 5:
			m._expulsar(mios[k])
		_comprobar(suspendido_a_6 and m.suspendido and m.estado == "fin", "con 6 (%s): suspendido en el simulado (%s) y en el 3D (%s)" % ["local" if lado_local else "visita", str(suspendido_a_6), str(m.suspendido)])
		_comprobar(ml == int(m.goles[0]) and mv == int(m.goles[1]), "…y con el mismo marcador de mesa (simulado %d-%d, 3D %d-%d)" % [ml, mv, m.goles[0], m.goles[1]])
	## A 7 sigue: ni uno ni otro se suspende.
	var r3 := _partido(101)
	var p3: Partido = r3[3]
	var ids3 := p3.once_local.filter(func(j: Jugador) -> bool: return not j.es_portero()).map(func(j: Jugador) -> String: return j.id)
	for k in 4:
		p3.tarjeta_externa(String(ids3[k]), true)
	_comprobar(not p3.suspendido and p3.once_local.size() == 7, "con 7 el simulado sigue (%d en el campo)" % p3.once_local.size())
	## La roja EN PLENA FALTA (con penal): el partido suspendido no revive («saque»).
	var r4 := _motor(r3[1], r3[2])
	var m4: MotorJugable = r4[0]
	var mios4: Array = m4.jugadores.filter(func(q: Dictionary) -> bool: return bool(q["es_local"]) and not bool(q["por"]))
	for k in 4:
		m4._expulsar(mios4[k])
	m4._expulsar(mios4[4])
	m4._empezar_saque("penal", false, Vector3(0, 0.11, 40))
	_comprobar(m4.estado == "fin", "un penal que iba a sacarse tras la roja que suspende el partido ya no se saca (%s)" % m4.estado)

## (2)
func _lesiones() -> void:
	## Sin cambios: sale y juega con diez.
	var r := _partido(200)
	var p: Partido = r[3]
	p.cambios_local = Partido.MAX_CAMBIOS
	var j: Jugador = p.once_local.filter(func(q: Jugador) -> bool: return not q.es_portero())[2]
	var salidos: Array = []
	p.baja_sin_cambio.connect(func(q: Jugador, _m: int) -> void: salidos.append(q.id))
	j.lesionar(4)
	PartidoLesiones.nueva(p, j)
	p.simular_minuto()
	_comprobar(not p.once_local.has(j) and p.once_local.size() == 10 and salidos == [j.id], "lesionado con los cambios agotados: sale y su equipo juega con 10 (%d)" % p.once_local.size())
	## El portero lesionado, sin cambios: un jugador de campo al arco, la fuerza sigue siendo un número.
	var r2 := _partido(201)
	var p2: Partido = r2[3]
	p2.cambios_local = Partido.MAX_CAMBIOS
	var gk: Jugador = p2.once_local.filter(func(q: Jugador) -> bool: return q.es_portero())[0]
	gk.lesionar(6)
	PartidoLesiones.nueva(p2, gk)
	p2.simular_minuto()
	var f := p2.fuerza(p2.once_local, p2.local)
	_comprobar(not p2.once_local.has(gk) and is_finite(float(f["def"])) and float(f["def"]) > 0.0, "portero lesionado sin cambios: sin portero en el once, la defensa sigue siendo un número positivo (%.1f)" % float(f["def"]))
	var min0 := p2.minuto
	while not p2.terminado_ya and p2.minuto < 200:
		p2.simular_minuto()
	_comprobar(p2.terminado_ya and p2.minuto >= min0, "…y el partido llega al final (%d-%d)" % [p2.goles_local, p2.goles_visita])
	## Con cambios: el suplente de su puesto entra solo (la CPU en el acto; el DT del jugador tras 3 minutos).
	var r3 := _partido(202)
	var p3: Partido = r3[3]
	var rival: Jugador = p3.once_visita.filter(func(q: Jugador) -> bool: return not q.es_portero())[1]
	rival.lesionar(3)
	PartidoLesiones.nueva(p3, rival)
	p3.simular_minuto()
	_comprobar(not p3.once_visita.has(rival) and p3.once_visita.size() == 11 and p3.cambios_visita == 1, "la CPU cambia al lesionado en el acto (cambios %d, once %d)" % [p3.cambios_visita, p3.once_visita.size()])
	Partido.ctx_club_id = p3.local.id
	var mio: Jugador = p3.once_local.filter(func(q: Jugador) -> bool: return not q.es_portero())[3]
	mio.lesionar(3)
	PartidoLesiones.nueva(p3, mio)
	p3.simular_minuto()
	var sigue := p3.once_local.has(mio)
	for i in 3:
		p3.simular_minuto()
	_comprobar(sigue and not p3.once_local.has(mio) and p3.cambios_local == 1, "el DT del jugador tiene %d minutos; si no mueve el banquillo, lo hace el ayudante" % PartidoLesiones.ESPERA_DT)
	Partido.ctx_club_id = ""

## (4)
func _motor_cambios() -> void:
	var r := _partido(300)
	var r2 := _motor(r[1], r[2], true)
	var m: MotorJugable = r2[0]
	var sp: PlayerSpawner = r2[2]
	var raiz: Node3D = r2[1]
	var club: Club = r[1]
	var banco: Jugador = null
	var en_once: Array = club.once()
	for q: Jugador in club.plantilla:
		if not en_once.has(q) and not q.es_portero():
			banco = q
			break
	var una := Puente3D.once([banco] as Array[Jugador])
	## Descanso.
	m.set_physics_process(false)
	m.t = m.dur_mitad() - 0.05
	for i in 400:
		m.paso(1.0 / 30.0)
		if m.estado == "descanso":
			break
	var sale: Dictionary = m.jugadores.filter(func(q: Dictionary) -> bool: return bool(q["es_local"]) and not bool(q["por"]))[0]
	var nuevos := sp.spawn_team(raiz, una["xi"], una["jugadores"], {"s": [[sale["slot_code"], 50, 50]]}, true, Puente3D.kit(club), Puente3D.kit_portero(club))
	var ok := m.reemplazar(String(sale["id"]), nuevos[0])
	_comprobar(m.estado == "descanso" and ok and not m.jugadores.has(sale), "cambio en el descanso: se hace (%s)" % str(ok))
	_comprobar(not m.reemplazar("no_existe", nuevos[0]), "un id que no existe devuelve falso")
	for i in 90:
		m.paso(1.0 / 30.0)
	_comprobar(m.estado != "", "el motor sigue tras el cambio (%s)" % m.estado)
	## Tanda: cambiar al portero que va a atajar o al lanzador no deja al motor mirando a quien ya salió.
	m.mitad = 4
	m.prorroga = true
	m.goles = [1, 1]
	m._fin_de_mitad()
	_comprobar(m.estado == "tanda", "se llega a la tanda (%s)" % m.estado)
	var lanz: Dictionary = m.tanda.get("lanzador", {})
	var objetivo: Dictionary = (m.tanda["orden"][0] as Array)[0]
	var nuevos2 := sp.spawn_team(raiz, una["xi"], una["jugadores"], {"s": [[objetivo["slot_code"], 50, 50]]}, bool(objetivo["es_local"]), Puente3D.kit(club), Puente3D.kit_portero(club))
	m.reemplazar(String(objetivo["id"]), nuevos2[0])
	var quedan_viejos := 0
	for lado in 2:
		for q: Dictionary in (m.tanda["orden"][lado] as Array):
			if q == objetivo:
				quedan_viejos += 1
	_comprobar(quedan_viejos == 0, "cambio en plena tanda: el orden de lanzadores ya no trae al que salió (%d)" % quedan_viejos)
	m.autopiloto = true
	m.set_physics_process(true)
	var f := 0
	while m.estado != "fin" and f < 60 * 120:
		await get_tree().process_frame
		f += 1
	_comprobar(m.estado == "fin", "y la tanda termina (%s, %d fotogramas)" % [m.estado, f])

## (5)
func _banco_vacio() -> void:
	var r := _partido(400)
	var club: Club = r[1]
	var once: Array = club.once()
	var guardados: Array[Jugador] = []
	for q: Jugador in club.plantilla:
		if not once.has(q):
			guardados.append(q)
	club.plantilla = club.plantilla.filter(func(q: Jugador) -> bool: return once.has(q))
	var raiz := Control.new()
	add_child(raiz)
	var p: Partido = r[3]
	var panel := PanelDTPartido.abrir(raiz, p, club, null)
	await get_tree().process_frame
	_comprobar(is_instance_valid(panel), "la pausa táctica abre sin nadie en el banco")
	var botones := panel.find_children("*", "Button", true, false).size() if is_instance_valid(panel) else 0
	_comprobar(botones > 0, "…y tiene botones (%d)" % botones)
	if is_instance_valid(panel):
		panel.queue_free()
	club.plantilla.append_array(guardados)
