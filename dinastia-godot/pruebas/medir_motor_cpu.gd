extends Node
## CPU del motor jugable por función (usec, sin pantalla): paso entero, _cuerpos y _rival_mas_cercano.
##   godot --headless --path . res://pruebas/medir_motor_cpu.tscn   (mide scripts, no la gráfica)
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
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
	motor.preparar(lista, ball, "", 7)
	motor._saque_de_centro(true)
	var t_paso := 0
	var n := 1800
	for i in n:
		var t0 := Time.get_ticks_usec()
		motor.paso(1.0 / 60.0)
		t_paso += Time.get_ticks_usec() - t0
	var t_c := Time.get_ticks_usec()
	for i in 600:
		motor._cuerpos()
	t_c = Time.get_ticks_usec() - t_c
	var t_r := Time.get_ticks_usec()
	for i in 100:
		for q: Dictionary in motor.jugadores:
			motor._rival_mas_cercano(q)
	t_r = Time.get_ticks_usec() - t_r
	print("MOTORCPU paso %.1f us  _cuerpos %.1f us  _rival_mas_cercano x22 %.1f us" % [t_paso / float(n), t_c / 600.0, t_r / 100.0])
	get_tree().quit()
