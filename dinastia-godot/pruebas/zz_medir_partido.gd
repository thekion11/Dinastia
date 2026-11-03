extends Node
## MEDIR CUÁNTO CAMBIA EL PARTIDO (01-11-2026): partidos simulados en autopiloto con semillas fijas; imprime goles, remates, faltas,
## pases buenos y duelos. Comparar con y sin un cambio (p. ej. SIN_LEAGUE=1). N_PARTIDOS=16 DESDE=1 godot --headless --path . res://pruebas/zz_medir_partido.tscn
## Mide partidos simulados (autopiloto) con varias semillas: goles, remates, faltas, pases buenos, duelos.
func _ready() -> void:
	await get_tree().process_frame
	var tot := {"goles": 0, "tiros": 0, "faltas": 0, "pases_ok": 0, "duelos": 0}
	var traza := {}
	var ext := {"pases": 0, "pases_ok": 0, "poses_local": 0.0, "dentro": 0, "frontal": 0, "lejos": 0, "a_puerta": 0, "tiros_pie": 0}
	var n := int(OS.get_environment("N_PARTIDOS")) if OS.get_environment("N_PARTIDOS") != "" else 16
	for semilla in range(int(OS.get_environment("DESDE")) if OS.get_environment("DESDE") != "" else 1, (int(OS.get_environment("DESDE")) if OS.get_environment("DESDE") != "" else 1) + n):
		var m := Mundo.new()
		m.generar(["CHI"], 4711)
		var a: Club = m.ligas[0].clubes[semilla % 8]
		var b: Club = m.ligas[0].clubes[(semilla + 3) % 8]
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
		motor.preparar(lista, ball, "", semilla)
		for i in 30 * 60 * 6:
			motor.paso(1.0 / 30.0)
		tot["goles"] += int(motor.goles[0]) + int(motor.goles[1])
		tot["tiros"] += int(motor.tiros[0]) + int(motor.tiros[1])
		tot["faltas"] += int(motor.faltas[0]) + int(motor.faltas[1])
		tot["pases_ok"] += int(motor.pases_ok[0]) + int(motor.pases_ok[1])
		tot["controles_largos"] = int(tot.get("controles_largos", 0)) + int(motor.get_meta("controles_largos", 0))
		tot["fueras_juego"] = int(tot.get("fueras_juego", 0)) + int(motor.fueras_de_juego[0]) + int(motor.fueras_de_juego[1])
		var d := 0
		for k: String in motor.duelos:
			d += int(motor.duelos[k])
		tot["duelos"] += d
		ext["pases"] += int(motor.pases[0]) + int(motor.pases[1])
		ext["pases_ok"] += int(motor.pases_ok[0]) + int(motor.pases_ok[1])
		var pt := float(motor.posesion[0]) + float(motor.posesion[1])
		ext["poses_local"] += float(motor.posesion[0]) / pt if pt > 0.0 else 0.5
		for k: String in motor.diag:
			var cuenta := int(motor.diag[k])
			if k.begins_with("traza_"):
				traza[k] = int(traza.get(k, 0)) + int(motor.diag[k])
			if k.begins_with("tiro_") and k.ends_with("_dentro"):
				ext["dentro"] += cuenta
			elif k.begins_with("tiro_") and k.ends_with("_frontal"):
				ext["frontal"] += cuenta
			elif k.begins_with("tiro_") and k.ends_with("_lejos"):
				ext["lejos"] += cuenta
			elif k.begins_with("a_puerta_"):
				ext["a_puerta"] += cuenta
		raiz.queue_free()
	print("MEDIDA ", OS.get_environment("SIN_LEAGUE"), " ", tot)
	print("MEDIDA3 ", traza)
	## MEDIDA2 (03-11): lo que pide la sesión líder. xG aproximado por zona (medias de la literatura, no datos medidos): dentro 0,13 · frontal 0,05 · lejos 0,03.
	var con_zona := int(ext["dentro"]) + int(ext["frontal"]) + int(ext["lejos"])
	var xg := float(ext["dentro"]) * 0.13 + float(ext["frontal"]) * 0.05 + float(ext["lejos"]) * 0.03
	print("MEDIDA2 ", {
		"partidos": n,
		"pases_pct": snappedf(100.0 * float(ext["pases_ok"]) / maxf(float(ext["pases"]), 1.0), 0.1),
		"posesion_local_pct": snappedf(100.0 * float(ext["poses_local"]) / maxf(float(n), 1.0), 0.1),
		"tiros_dentro": ext["dentro"], "tiros_frontal": ext["frontal"], "tiros_lejos": ext["lejos"],
		"pct_dentro": snappedf(100.0 * float(ext["dentro"]) / maxf(float(con_zona), 1.0), 0.1),
		"a_puerta": ext["a_puerta"],
		"a_puerta_pct": snappedf(100.0 * float(ext["a_puerta"]) / maxf(float(tot["tiros"]), 1.0), 0.1),
		"xg_por_tiro": snappedf(xg / maxf(float(con_zona), 1.0), 0.001),
		"acierto_pct": snappedf(100.0 * float(tot["goles"]) / maxf(float(tot["tiros"]), 1.0), 0.1),
		"tiros_por_partido": snappedf(float(tot["tiros"]) / maxf(float(n), 1.0), 0.1),
		"goles_por_partido": snappedf(float(tot["goles"]) / maxf(float(n), 1.0), 0.01)})
	get_tree().quit()
