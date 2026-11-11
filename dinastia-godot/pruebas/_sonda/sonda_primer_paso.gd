## PRIMER PASO DEL PARTIDO (11-11, fase 4d): cronometra 6000 pasos de MotorLeague y lista los que pasan de 15 ms (con lo que gastó la locomoción). La precarga de `LeagueLocomocion.precargar` mueve el coste de las bibliotecas a `preparar`.
extends Node
func _ready() -> void:
	await get_tree().process_frame
	var m := Mundo.new()
	m.generar(["CHI", "ESP"], 4711)
	var a: Club = m.ligas[0].clubes[2]
	var b: Club = m.ligas[m.ligas.size() - 1].clubes[4]
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ball := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	var motor := MotorLeague.new()
	raiz.add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = true
	var t0 := Time.get_ticks_usec()
	motor.preparar(lista, ball, "", 100)
	print("PASO preparar ", (Time.get_ticks_usec() - t0) / 1000.0, " ms")
	var peor := []
	for i in 6000:
		t0 = Time.get_ticks_usec()
		var l0 := LeagueLocomocion.us_total
		var est0 := motor.estado
		var tq := motor.cuenta_toques.duplicate()
		motor.paso(1.0 / 30.0)
		var d := (Time.get_ticks_usec() - t0) / 1000.0
		if d > 15.0:
			peor.append("%d:%.1f loco=%.1f %s->%s toques=%s" % [i, d, (LeagueLocomocion.us_total - l0) / 1000.0, est0, motor.estado, str(motor.cuenta_toques) if motor.cuenta_toques != tq else "-"])
	print("PASO lentos(>8ms) ", peor)
	get_tree().quit()
