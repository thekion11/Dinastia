extends Node
## COSTE POR FASE DEL PASO DEL MOTOR JUGABLE (10-11-2026, paso a C++): repite la rama «juego» de `MotorJugable.paso` midiendo cada fase por separado (usec por paso, sin pantalla).
## Solo mide; no cambia el motor. Herramienta, no prueba del banco.   godot --headless --path . res://pruebas/zz_perfil_motor.tscn
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
	var mo := MotorJugable.new()
	raiz.add_child(mo)
	mo.set_physics_process(false)
	mo.autopiloto = true
	mo.preparar(lista, ball, "", 7)
	mo._saque_de_centro(true)
	var d := 1.0 / 60.0
	var n := 1500
	var t := {}
	var fases := {
		"_mover_balon": func() -> void: mo._mover_balon(d),
		"_duelos": func() -> void: mo._duelos(),
		"MotorVentaja.revisar": func() -> void: MotorVentaja.revisar(mo),
		"MotorColocacion.actualizar": func() -> void: MotorColocacion.actualizar(mo, d),
		"MotorMente.actualizar": func() -> void: MotorMente.actualizar(mo),
		"MotorAdaptacion.actualizar": func() -> void: MotorAdaptacion.actualizar(mo, d),
		"MotorTraza.paso": func() -> void: MotorTraza.paso(mo),
		"_disputas": func() -> void: mo._disputas(d),
		"_ia_equipos": func() -> void: mo._ia_equipos(d),
		"_control_usuario": func() -> void: mo._control_usuario(d),
		"_indicar_pase": func() -> void: mo._indicar_pase(d),
		"[22 jugadores] _ia_defensa": func() -> void:
			for q: Dictionary in mo.jugadores:
				mo._ia_defensa(q),
		"[22 jugadores] _ia_ataque_sin_balon": func() -> void:
			for q: Dictionary in mo.jugadores:
				mo._ia_ataque_sin_balon(q),
		"[22 jugadores] _rival_mas_cercano": func() -> void:
			for q: Dictionary in mo.jugadores:
				mo._rival_mas_cercano(q),
		"[22 jugadores] _presion": func() -> void:
			for q: Dictionary in mo.jugadores:
				mo._presion(q),
		"_cuerpos": func() -> void: mo._cuerpos(),
		"_mover_jugadores": func() -> void: mo._mover_jugadores(d),
	}
	for i in n:
		mo.paso(d)   ## avanza el motor de verdad (el partido sigue); las fases se miden aparte sobre ese mismo estado
		if mo.estado != "juego":
			continue
		for k: String in fases:
			var t0 := Time.get_ticks_usec()
			(fases[k] as Callable).call()
			t[k] = float(t.get(k, 0.0)) + (Time.get_ticks_usec() - t0)
	var filas: Array = []
	for k: String in t:
		filas.append([float(t[k]) / n, k])
	filas.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) > float(y[0]))
	print("PERFIL MOTOR (%d pasos; cada fase ejecutada UNA vez extra por paso, sobre el estado real)" % n)
	for f: Array in filas:
		print("  %8.1f µs  %s" % [float(f[0]), f[1]])
	get_tree().quit()
