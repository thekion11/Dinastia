extends Node
## CAZA DE FALLOS (4-11-2026, orden de la líder): el ÁRBITRO y el VAR llevados al límite.
##   godot --headless --path . res://pruebas/auditoria_arbitro_limite.tscn
## RevisionVAR con márgenes absurdos (INF, -INF, NaN, ±1e9) y todos los factores; tarjetas repetidas a quien ya salió (roja dos veces, amarilla después de la roja,
## roja directa tras dos amarillas), gol anulado cuando el partido ya terminó, y la expulsión repetida en el motor del césped.
var _fallos := 0

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _ready() -> void:
	_vae()
	_tarjetas_repetidas()
	_gol_anulado_tras_el_final()
	_motor_expulsion_doble()
	print("===== FIN. %d fallos =====" % _fallos)
	get_tree().quit(0 if _fallos == 0 else 1)

func _vae() -> void:
	var mal := 0
	var rojas_sin_revision := 0
	var n := 0
	for margen in [INF, -INF, NAN, 1e9, -1e9, 0.0, 0.3, 0.31, -1.0, -1.8, 0.15, -0.5]:
		for factor in [0.0, 0.5, 0.99, 1.0, 1.5, NAN]:
			for semilla in [0, 1, -7, 123456789]:
				var d := RevisionVAR.decidir(margen, factor, semilla)
				var d2 := RevisionVAR.decidir(margen, factor, semilla)
				n += 1
				if d != d2 or not d.has("revisa") or not d.has("ajustado") or not d.has("anula"):
					mal += 1
				if bool(d["anula"]) and not bool(d["revisa"]):
					rojas_sin_revision += 1
				if is_equal_approx(float(factor), 1.0) or float(factor) > 1.0:
					if bool(d["revisa"]):
						mal += 1   ## sin VAR (factor ≥ 1) nunca se revisa
	_comprobar(mal == 0, "RevisionVAR en %d combinaciones extremas: determinista, completo y sin revisar si no hay VAR" % n)
	_comprobar(rojas_sin_revision == 0, "nunca se anula un gol sin revisarlo")
	var anulados_adelantado := 0
	var anulados_en_linea := 0
	for s in 400:
		if bool(RevisionVAR.decidir(0.2, 0.5, s)["anula"]):
			anulados_adelantado += 1
		if bool(RevisionVAR.decidir(-0.5, 0.5, s)["anula"]):
			anulados_en_linea += 1
	_comprobar(anulados_adelantado == 400 and anulados_en_linea == 0, "20 cm adelantado: se anula siempre (%d/400); 50 cm en línea: nunca (%d/400)" % [anulados_adelantado, anulados_en_linea])

func _mundo_partido() -> Array:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var p := Partido.new(a, b)
	p.preparar()
	return [m, a, b, p]

func _tarjetas_repetidas() -> void:
	var r := _mundo_partido()
	var a: Club = r[1]
	var p: Partido = r[3]
	var j: Jugador = p.once_local[3]
	var id := j.id
	p.tarjeta_externa(id, true)
	var susp1 := j.suspension
	var amar1 := j.amarillas
	var once1 := p.once_local.size()
	p.tarjeta_externa(id, true)   ## la misma roja otra vez (el motor 3D la envía una vez, pero un reenvío no debe sancionar doble)
	_comprobar(j.suspension == susp1, "una roja repetida no duplica la sanción (%d → %d partidos)" % [susp1, j.suspension])
	_comprobar(j.amarillas == amar1, "ni suma amarillas de temporada (%d → %d)" % [amar1, j.amarillas])
	_comprobar(p.once_local.size() == once1, "ni saca a otro del once (%d → %d)" % [once1, p.once_local.size()])
	p.tarjeta_externa(id, false)   ## una amarilla a quien ya salió
	_comprobar(j.amarillas == amar1, "una amarilla a quien ya fue expulsado no cuenta (%d → %d)" % [amar1, j.amarillas])
	var j2: Jugador = p.once_local[4]
	p.tarjeta_externa(j2.id, false)
	p.tarjeta_externa(j2.id, false)
	p.tarjeta_externa(j2.id, true)
	_comprobar(not p.once_local.has(j2), "dos amarillas y una roja más: fuera del once")
	_comprobar(j2.amarillas >= 2 and j2.amarillas <= 3, "las amarillas de temporada son coherentes (%d)" % j2.amarillas)

func _gol_anulado_tras_el_final() -> void:
	var r := _mundo_partido()
	var p: Partido = r[3]
	p.gol_externo(true, "", "")
	p.terminado_ya = true
	var antes := p.goles_local
	p.anular_gol_externo(true, "")
	_comprobar(p.goles_local == antes, "anular un gol cuando el partido ya acabó no cambia el acta (%d)" % p.goles_local)
	var q: Partido = _mundo_partido()[3]
	q.anular_gol_externo(false, "")
	q.anular_gol_externo(true, "")
	_comprobar(q.goles_local == 0 and q.goles_visita == 0, "anular goles que no hay no deja negativos")

func _motor_expulsion_doble() -> void:
	var r := _mundo_partido()
	var a: Club = r[1]
	var b: Club = r[2]
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
	motor.tarjetas_reales = true
	motor.preparar(lista, ball, "", 7)
	var p: Dictionary = {}
	for q: Dictionary in motor.jugadores:
		if bool(q["es_local"]) and not bool(q["por"]):
			p = q
			break
	var n0 := motor.jugadores.size()
	motor._expulsar(p)
	motor._expulsar(p)   ## otra vez
	_comprobar(motor.jugadores.size() == n0 - 1, "expulsar dos veces al mismo jugador quita a uno solo (%d → %d)" % [n0, motor.jugadores.size()])
	_comprobar(motor.expulsados.count(p) == 1, "y consta una sola vez en la lista de expulsados (%d)" % motor.expulsados.count(p))
	for i in 60:
		motor.paso(1.0 / 30.0)
	_comprobar(motor.estado != "", "60 pasos después con el expulsado repetido: el motor sigue (%s)" % motor.estado)
