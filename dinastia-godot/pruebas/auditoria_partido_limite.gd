extends Node
## MEGA AUDITORÍA 4, repaso 3 (AL LÍMITE) del PARTIDO (4-11-2026): casos absurdos del motor 3D y del partido simulado que nunca se probaban. Nada puede dar NaN/INF ni salirse del mundo, y el acta
## no puede romperse con llamadas fuera de orden.
##   godot --headless --path . res://pruebas/auditoria_partido_limite.tscn
var _fallos := 0

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _ready() -> void:
	await get_tree().process_frame
	_motor_3d()
	_acta()
	print("===== FIN. %d fallos =====" % _fallos)
	get_tree().quit(0 if _fallos == 0 else 1)

func _sano(motor: MotorJugable, ball: Node3D) -> String:
	for p: Dictionary in motor.jugadores:
		var q := (p["node"] as Node3D).position
		if not (is_finite(q.x) and is_finite(q.y) and is_finite(q.z)):
			return "jugador %s no finito %s" % [String(p["id"]), str(q)]
		if absf(q.x) > 80.0 or absf(q.z) > 90.0 or q.y > 30.0 or q.y < -5.0:
			return "jugador %s fuera del mundo %s" % [String(p["id"]), str(q)]
	var b := ball.position
	if not (is_finite(b.x) and is_finite(b.y) and is_finite(b.z)):
		return "balón no finito %s" % str(b)
	if absf(b.x) > 150.0 or absf(b.z) > 160.0 or b.y > 80.0 or b.y < -5.0:
		return "balón fuera del mundo %s" % str(b)
	return ""

func _motor_3d() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ball := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	var motor := MotorJugable.new()
	raiz.add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = true
	motor.duracion_mitad = 120.0
	motor.preparar(lista, ball, "", 4242)
	motor._reanudar()
	## 1) pasos de tiempo absurdos: 0, casi 0, enorme (la app vuelve de segundo plano con 5-10 s de golpe).
	for dt: float in [0.0, 0.000001, 1.0 / 240.0, 1.0 / 30.0, 0.25, 2.0, 10.0]:
		for i in 6:
			motor.paso(dt)
		var err := _sano(motor, ball)
		_comprobar(err == "", "paso(%s) ×6 deja el partido sano%s" % [str(dt), (": " + err) if err != "" else ""])
	## 2) 600 pasos normales tras el castigo: sigue jugándose y el reloj avanza.
	var t0 := motor.t
	for i in 600:
		motor.paso(1.0 / 30.0)
	_comprobar(_sano(motor, ball) == "", "600 pasos de 1/30 s tras los pasos absurdos: sano (%s)" % _sano(motor, ball))
	_comprobar(motor.t > t0 or motor.estado != "juego", "el reloj del partido avanza (t %.1f → %.1f, estado %s)" % [t0, motor.t, motor.estado])
	## 3) el balón teletransportado muy lejos y otro con velocidad enorme no rompen nada.
	for i in 3000:   ## (4-11) con el balón en juego: en «saque» el motor no toca el balón hasta que se saca
		if motor.estado == "juego":
			break
		motor.paso(1.0 / 30.0)
	ball.position = Vector3(500.0, 3.0, -700.0)
	motor.paso(1.0 / 30.0)
	motor.vel_balon = Vector3(900.0, 400.0, -900.0)
	for i in 30:
		motor.paso(1.0 / 30.0)
	_comprobar(_sano(motor, ball) == "", "balón fuera del campo y a 1.000 m/s: el motor lo recoge y sigue (%s, estado %s, minuto %d)" % [_sano(motor, ball), motor.estado, motor.minuto()])
	raiz.queue_free()

func _acta() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var p := Partido.new(a, b)
	p.preparar()
	## llamadas fuera de orden y con datos que no existen
	p.tarjeta_externa("no_existe", true)
	p.tarjeta_externa("", false)
	p.remate_externo(true, "no_existe", "fallo")
	p.anular_gol_externo(true, "no_existe")
	_comprobar(p.goles_local == 0 and p.goles_visita == 0, "anular un gol que no existe no deja el marcador en negativo")
	p.gol_externo(true, "no_existe", "no_existe")
	_comprobar(p.goles_local == 1, "un gol con autor desconocido cuenta (en propia puerta)")
	## A4-PARTIDO-006: un gol anulado no es remate ni xG, y no deja al rival una «peor diferencia» que no vivió
	var q := Partido.new(a, b)
	q.preparar()
	for i in 3: q.gol_externo(false, "", "")
	q.anular_gol_externo(false, "")
	q.anular_gol_externo(false, "")
	q.anular_gol_externo(false, "")
	_comprobar(q.remates_visita == 0 and q.tiros_puerta_visita == 0 and absf(q.xg_visita) < 0.001, "tres goles anulados: ni remates ni xG del rival")
	_comprobar(q.peor_diferencia_local == 0, "los goles anulados no cuentan como «remontada de 3» (peor diferencia %d)" % q.peor_diferencia_local)
	q.gol_externo(true, "", "")
	_comprobar(q.remates_local == 1 and q.peor_diferencia_visita == -1, "un gol válido cuenta un remate")
	p.prorroga_externa()
	p.prorroga_externa()
	_comprobar(p.minutos_fin == Partido.MINUTOS + 30 and p.cambios_extra == 1, "pedir la prórroga dos veces no suma dos cambios extra")
	var otro := p.local.plantilla[0] if p.local.plantilla.size() > 0 else null
	if otro != null and p.once_local.size() > 1:
		var r := p.cambiar(p.once_local[0], p.once_local[0])
		_comprobar(r != "", "cambiar a un jugador por sí mismo se rechaza (%s)" % r)
	var pen1 := p.penales()
	var pen2 := p.penales()
	_comprobar(pen1 == pen2 and int(pen1[0]) != int(pen1[1]), "la tanda sale una sola vez y no empata")
	## un partido entero con el once vacío del visitante no se rompe
	var p2 := Partido.new(a, b)
	p2.preparar()
	p2.once_visita.clear()
	p2.invalidar_fuerza()
	var ok := true
	for i in 130:
		p2.simular_minuto()
		if p2.terminado_ya:
			break
	_comprobar(ok and p2.terminado_ya, "un partido con el visitante sin once termina sin romperse (%d-%d)" % [p2.goles_local, p2.goles_visita])
	## tarjetas: roja directa NO suma amarilla; amarilla + roja = 2 amarillas
	var p3 := Partido.new(a, b)
	p3.preparar()
	if p3.once_local.size() > 2:
		var j1: Jugador = p3.once_local[1]
		var j2: Jugador = p3.once_local[2]
		var a1 := j1.amarillas
		var a2 := j2.amarillas
		p3.tarjeta_externa(j1.id, true)
		_comprobar(j1.amarillas == a1, "una roja directa no suma una amarilla de temporada (%d → %d)" % [a1, j1.amarillas])
		p3.tarjeta_externa(j2.id, false)
		p3.tarjeta_externa(j2.id, true)
		_comprobar(j2.amarillas == a2 + 2, "amarilla + segunda amarilla (roja) suman dos (%d → %d)" % [a2, j2.amarillas])
	## notas: quien sale cambiado de un equipo que gana recibe el bono del ganador, no el del perdedor
	var p4 := Partido.new(a, b)
	p4.preparar()
	if p4.once_local.size() > 1 and p4.local.plantilla.size() > 12:
		var sale: Jugador = p4.once_local[1]
		var entra: Jugador = null
		for c: Jugador in p4.local.plantilla:
			if not p4.once_local.has(c) and c.disponible():
				entra = c
				break
		if entra != null and p4.cambiar(sale, entra) == "":
			_comprobar(p4.es_del_local(sale), "el que salió cambiado sigue contando como del local (para su nota)")
			var visitante: Jugador = p4.once_visita[1]
			_comprobar(not p4.es_del_local(visitante), "un visitante no cuenta como del local")
			p4.goles_local = 3
			p4._cerrar_notas()
			_comprobar(sale.notas.size() > 0 and float(sale.notas[sale.notas.size() - 1]) >= 4.5, "las notas se cierran con el cambiado dentro (nota %.1f)" % float(sale.notas[sale.notas.size() - 1]))
