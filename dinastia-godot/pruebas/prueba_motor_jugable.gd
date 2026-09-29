extends Node3D
## EL MOTOR JUGABLE, EN PILOTO AUTOMÁTICO (29-9-2026, mapa de metas 18). Un
## partido entero con los 22 manejados por la IA, a paso fijo y sin pantalla:
##   godot --headless --path . res://pruebas/prueba_motor_jugable.tscn
## Comprueba que se juega: hay tiros, saques de todo tipo, el balón no se
## escapa del campo y el partido termina.
var _fallos := 0
func _ok(c: bool, txt: String) -> void:
	print(("  ok    " if c else "  FALLO ") + txt)
	if not c:
		_fallos += 1

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	lista.append_array(sp.spawn_team(self, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(self, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ball := StadiumBuilder.spawn_ball(self, Vector3(0, 0.11, 0))
	var motor := MotorJugable.new()
	add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = true
	motor.depurar = OS.get_environment("DEPURAR") == "2"
	motor.duracion_mitad = 180.0
	motor.preparar(lista, ball, String(l["xi"][9]), 5)
	var saques := {}
	var goles_ev := [0]
	var max_fuera := [0.0]
	var n_log := [0]
	motor.cambio_estado.connect(func(e: String) -> void:
		saques[e] = int(saques.get(e, 0)) + 1
		if e == "saque_puerta" and n_log[0] < 12 and OS.get_environment("DEPURAR") != "":
			n_log[0] += 1
			var u: Dictionary = motor.ultimo_toque
			print("PUERTA min %d lugar %s ultimo %s(%s por=%s) pen %s vel %s" % [motor.minuto(), str(motor.saque.get("lugar")), String(u.get("slot_code", "?")), "L" if bool(u.get("es_local", false)) else "V", str(u.get("por", false)), String(motor.penultimo_toque.get("slot_code", "?")), str(motor.vel_balon)]))
	motor.gol.connect(func(_l: bool, _a: String, _s: String) -> void: goles_ev[0] += 1)
	var dt := 1.0 / 30.0
	var pasos := 0
	while motor.estado != "fin" and pasos < 30 * 800:
		motor.paso(dt)
		pasos += 1
		var p := ball.position
		max_fuera[0] = maxf(max_fuera[0], maxf(absf(p.x) - 34.0, absf(p.z) - 54.5))
	print("RESULTADO %d-%d  tiros %s  posesión local %d%%  saques %s  pasos %d" % [motor.goles[0], motor.goles[1], str(motor.tiros), motor.posesion_local(), str(saques), pasos])
	_ok(motor.estado == "fin", "el partido termina (dos tiempos)")
	_ok(motor.tiros[0] + motor.tiros[1] >= 6, "hay tiros de los dos lados (%d)" % (motor.tiros[0] + motor.tiros[1]))
	_ok(int(saques.get("saque_banda", 0)) + int(saques.get("saque_corner", 0)) + int(saques.get("saque_puerta", 0)) >= 4, "el balón sale y se reanuda con saques")
	_ok(max_fuera[0] < 3.0, "el balón nunca se escapa lejos del campo (%.1f m)" % max_fuera[0])
	_ok(goles_ev[0] == motor.goles[0] + motor.goles[1], "cada gol se avisa una vez")
	var pos_l := motor.posesion_local()
	_ok(pos_l > 20 and pos_l < 80, "la posesión se reparte (%d %%)" % pos_l)
	print("FIN MOTOR. %d fallos" % _fallos)
	get_tree().quit()
