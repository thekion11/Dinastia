extends Node
## MEDIR CUÁNTO CAMBIA EL PARTIDO (01-11-2026): partidos simulados en autopiloto con semillas fijas; imprime goles, remates, faltas,
## pases buenos y duelos. Comparar con y sin un cambio (p. ej. SIN_LEAGUE=1). N_PARTIDOS=16 DESDE=1 godot --headless --path . res://pruebas/zz_medir_partido.tscn
## Mide partidos simulados (autopiloto) con varias semillas: goles, remates, faltas, pases buenos, duelos.
func _ready() -> void:
	await get_tree().process_frame
	var tot := {"goles": 0, "tiros": 0, "faltas": 0, "pases_ok": 0, "duelos": 0}
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
		tot["fueras_juego"] = int(tot.get("fueras_juego", 0)) + int(motor.fueras_de_juego[0]) + int(motor.fueras_de_juego[1])
		var d := 0
		for k: String in motor.duelos:
			d += int(motor.duelos[k])
		tot["duelos"] += d
		raiz.queue_free()
	print("MEDIDA ", OS.get_environment("SIN_LEAGUE"), " ", tot)
	get_tree().quit()
