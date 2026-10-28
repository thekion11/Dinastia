extends Node3D
## IGUALDAD DEL MOTOR JUGABLE CON UN USUARIO (28-10-2026, para poder partir `_control_usuario` sin cambiar el juego): un partido con semilla fija en el que el usuario
## recibe unas entradas «grabadas» (un guion pseudoaleatorio de semilla fija: stick, pase, tiro, centro, hueco, sprint, proteger, modificadores, cambiar…) y se
## compara una huella de las posiciones de los 22, del balón, el marcador y las estadísticas cada 300 pasos y al final con la guardada en `ESPERADO`.
##   godot --headless --path . res://pruebas/igualdad_motor.tscn          (ACTUALIZAR=1 imprime la huella nueva)
## Si cambia a propósito la sensación de juego, se actualiza `ESPERADO` en este archivo, diciéndolo.
const ESPERADO := "1729322334"
const PASOS := 30 * 420
const ACCIONES := ["jugar_pase", "jugar_tiro", "jugar_centro", "jugar_filtrado", "jugar_pase_largo", "jugar_cambiar", "jugar_mod", "jugar_regate", "jugar_pedir", "jugar_sombrero",
	"jugar_fili_arriba", "jugar_fili_abajo", "jugar_fili_izquierda", "jugar_fili_derecha", "jugar_tac_arriba", "jugar_tac_abajo", "jugar_tac_izquierda", "jugar_tac_derecha"]
const MOVER := ["jugar_arriba", "jugar_abajo", "jugar_izquierda", "jugar_derecha"]

func poseedor_es(motor: MotorJugable, p: Dictionary) -> bool:
	return motor.poseedor == p

func _huella(motor: MotorJugable, ball: Node3D) -> String:
	var s := PackedStringArray()
	s.append("%.2f,%.2f,%.2f" % [ball.position.x, ball.position.y, ball.position.z])
	for p: Dictionary in motor.jugadores:
		var q := (p["node"] as Node3D).position
		s.append("%.2f,%.2f,%.2f" % [q.x, q.y, q.z])
	s.append(str(motor.goles) + str(motor.tiros) + motor.estado + str(motor.posesion_local()))
	s.append(str(motor.stats))
	return str(hash("|".join(s)))

func _escenario(indice: int, semilla: int) -> String:
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
	motor.autopiloto = false
	motor.duracion_mitad = 180.0
	motor.preparar(lista, ball, String(l["xi"][indice]), semilla)
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242 + semilla
	var huellas := PackedStringArray()
	var pulsadas: Array[String] = []
	var dt := 1.0 / 30.0
	var pasos := 0
	while motor.estado != "fin" and pasos < PASOS:
		if pasos % 6 == 0:   ## una entrada nueva cada 0,2 s: se mueve hacia el balón (con ruido) y, cerca o con él, usa los botones
			for acc in pulsadas:
				Input.action_release(acc)
			pulsadas.clear()
			var yo := motor.usuario
			if not yo.is_empty():
				var d := MotorJugable.dir_ataque(bool(yo["es_local"]))
				var hacia := ball.position - motor.pos(yo)
				hacia.y = 0.0
				var cerca := hacia.length() < 4.0
				if poseedor_es(motor, yo):
					hacia = Vector3(rng.randf_range(-1.0, 1.0), 0, 1.0 * d)   ## con balón: hacia el arco rival con ruido
				var w := hacia.normalized() if hacia.length() > 0.05 else Vector3.ZERO
				w = (w + Vector3(rng.randf_range(-0.35, 0.35), 0, rng.randf_range(-0.35, 0.35))).normalized()
				var sx := -w.x / d
				var sy := -w.z / d
				if sx < -0.2:
					Input.action_press("jugar_izquierda", minf(1.0, -sx))
					pulsadas.append("jugar_izquierda")
				elif sx > 0.2:
					Input.action_press("jugar_derecha", minf(1.0, sx))
					pulsadas.append("jugar_derecha")
				if sy < -0.2:
					Input.action_press("jugar_arriba", minf(1.0, -sy))
					pulsadas.append("jugar_arriba")
				elif sy > 0.2:
					Input.action_press("jugar_abajo", minf(1.0, sy))
					pulsadas.append("jugar_abajo")
				if rng.randf() < 0.5:
					Input.action_press("jugar_sprint")
					pulsadas.append("jugar_sprint")
				if (cerca or poseedor_es(motor, yo)) and rng.randf() < 0.6:
					var acc: String = ACCIONES[rng.randi() % ACCIONES.size()]
					Input.action_press(acc)
					pulsadas.append(acc)
				elif rng.randf() < 0.12:
					var acc2: String = ACCIONES[rng.randi() % ACCIONES.size()]
					Input.action_press(acc2)
					pulsadas.append(acc2)
		if pasos % 150 == 75 and not motor.usuario.is_empty():   ## cada 5 s se le pone junto al balón: así hay muchos toques, entradas y tiros suyos
			(motor.usuario["node"] as Node3D).position = ball.position + Vector3(0.9, 0, 0.9 * MotorJugable.dir_ataque(bool(motor.usuario["es_local"])))
		motor.paso(dt)
		pasos += 1
		if pasos % 300 == 0:
			huellas.append(_huella(motor, ball))
	for acc in pulsadas:
		Input.action_release(acc)
	huellas.append(_huella(motor, ball))
	print("  escenario %d (semilla %d): %d-%d tiros %s toques %s entradas %s pases %s tiros_u %s" % [indice, semilla, motor.goles[0], motor.goles[1], str(motor.tiros), str(motor.stats["toques"]), str(motor.stats["entradas"]), str(motor.stats["pases"]), str(motor.stats["tiros"])])
	raiz.queue_free()
	return str(hash("|".join(huellas)))

func _ready() -> void:
	var todas := PackedStringArray()
	for esc: Array in [[6, 5], [9, 7], [2, 11], [0, 13]]:   ## un centrocampista, un delantero, un defensa y el portero
		todas.append(_escenario(int(esc[0]), int(esc[1])))
	var total := str(hash("|".join(todas)))
	print("HUELLA ", total)
	var ok := OS.get_environment("ACTUALIZAR") != "" or total == ESPERADO
	print(("  ok    " if ok else "  FALLO ") + "la huella de los cuatro partidos coincide con la guardada (%s)" % ESPERADO)
	print("===== FIN. %d fallos =====" % (0 if ok else 1))
	get_tree().quit(0 if ok else 1)
