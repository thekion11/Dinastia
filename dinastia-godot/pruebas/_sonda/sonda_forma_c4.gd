extends Node
## SONDA (17-11): cuánto cuesta cada pieza de `_forma` en C4 y la prueba pequeña del porte (`roles_base` en C++ contra `MotorRoles.base`).
func _ready() -> void:
	await get_tree().process_frame
	var m := Mundo.new()
	m.generar(["ESP", "ARG"] as Array[String], 77)
	var a: Club = m.ligas[0].clubes[2]
	var bcl: Club = m.ligas[1].clubes[3] if m.ligas[1].pais != a.pais else m.ligas[2].clubes[3]
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(bcl.once())
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(bcl.tactica.formacion), false, Puente3D.kit(bcl), Puente3D.kit_portero(bcl)))
	var ball := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	var mo: MotorJugable = MotorFabrica.crear("combinado_c4")
	raiz.add_child(mo)
	mo.set_physics_process(false)
	mo.autopiloto = true
	mo.duracion_mitad = 240.0
	mo.tacticas = [MotorJugable.tactica_desde(a.tactica), MotorJugable.tactica_desde(bcl.tactica)]
	mo.preparar(lista, ball, "", 5)
	var t_paso := 0
	var n_paso := 0
	var tt := {"forma": 0, "base": 0, "lento": 0, "pesos": 0, "tv": 0, "desvio": 0, "base_cpp": 0, "forma_gd": 0}
	var nat := Nativo.obj()
	var distintos := 0
	var nulos := 0
	var n := 0
	for i in 3000:
		var t0 := Time.get_ticks_usec()
		mo.paso(1.0 / 30.0)
		t_paso += Time.get_ticks_usec() - t0
		n_paso += 1
		if i % 10 != 0:
			continue
		for p: Dictionary in mo.jugadores:
			var pos := i % 20 == 0
			var loc := bool(p["es_local"])
			var s := Time.get_ticks_usec(); mo._forma(p, pos); tt["forma"] += Time.get_ticks_usec() - s
			s = Time.get_ticks_usec(); (mo as MotorCombinado)._forma_gd(p, pos); tt["forma_gd"] += Time.get_ticks_usec() - s
			s = Time.get_ticks_usec(); MotorRoles.base(mo, p); tt["base"] += Time.get_ticks_usec() - s
			s = Time.get_ticks_usec(); MotorColocacion.balon_lento(mo, loc); tt["lento"] += Time.get_ticks_usec() - s
			s = Time.get_ticks_usec(); MotorColocacion.pesos(mo, loc, pos); tt["pesos"] += Time.get_ticks_usec() - s
			s = Time.get_ticks_usec(); MotorTacticaViva.f(mo, loc, "linea"); MotorTacticaViva.urgencia(mo, loc); MotorTacticaViva.f(mo, loc, "amplitud"); tt["tv"] += Time.get_ticks_usec() - s
			s = Time.get_ticks_usec(); MotorAdaptacion.desvio_x(mo, loc, pos); tt["desvio"] += Time.get_ticks_usec() - s
			s = Time.get_ticks_usec(); var rc: Variant = nat.roles_base(mo, p, mo.t, mo.jugadores); tt["base_cpp"] += Time.get_ticks_usec() - s
			if rc == null:
				nulos += 1
			elif rc != MotorRoles.base(mo, p):
				distintos += 1
			n += 1
	var txt := "FORMA paso %.0f us;" % (float(t_paso) / n_paso)
	for k: String in tt:
		txt += " %s %.2f us;" % [k, float(tt[k]) / n]
	print(txt, " distintos ", distintos, " nulos ", nulos, " de ", n)
	get_tree().quit()
