extends "res://pruebas/probar_nativo_p2_p1.gd"
## (Parte 2 de 2 de `probar_nativo_p2.gd`.)

## El sorteo ponderado del goleador y del asistente: C++ y GDScript eligen a lo mismo.
func _once_goleador(nat, mundo: Mundo) -> void:
	## (10-11, paso a C++) El sorteo ponderado del goleador y del asistente: C++ y GDScript eligen a los MISMOS con la misma semilla de `Azar`, sin roles y con roles asignados.
	var jc := 0
	var jd := 0
	var tg0 := 0
	var tc0 := 0
	var roles_por_grupo := {}
	for rk: String in RolTactico.CATALOGO:
		roles_por_grupo[String(RolTactico.CATALOGO[rk]["grupo"])] = rk
	for conroles in [false, true]:
		for c: Club in mundo.clubes.values():
			var rv: Club = mundo.clubes.values()[(jc * 7 + 3) % mundo.clubes.size()]
			var p := Partido.new(c, rv)
			p.preparar()
			if conroles:
				for j: Jugador in p.once_local:
					p.local.tactica.roles[j.id] = roles_por_grupo.get(Datos.grupo(j.pos_e), "")
			for q in 3:
				for lado in 2:
					var once: Array[Jugador] = p.once_local if lado == 0 else p.once_visita
					if once.is_empty():
						continue
					Azar.sembrar(1000 + jc)
					var w0 := Time.get_ticks_usec()
					var a1 := PartidoPonderado.goleador(p, once)
					var w1 := Time.get_ticks_usec()
					var a2 := PartidoPonderado.asistente(p, once, a1, 10 + q)
					var s1 := Azar.f()
					var w2 := Time.get_ticks_usec()
					Azar.sembrar(1000 + jc)
					var w2b := Time.get_ticks_usec()
					var b1 := PartidoPonderado.goleador_gd(p, once)
					var w3 := Time.get_ticks_usec()
					var b2 := PartidoPonderado.asistente_gd(p, once, b1, 10 + q)
					var s2 := Azar.f()
					tc0 += (w1 - w0)
					tg0 += (w3 - w2b)
					jc += 1
					if a1 != b1 or a2 != b2 or s1 != s2:
						jd += 1
	_comprobar(jc > 500 and jd == 0, "goleador/asistente: C++ = GDScript en %d sorteos, con y sin roles (distintos: %d)" % [jc, jd])
	print("goleador: GDScript %.1f µs, C++ %.1f µs por sorteo" % [tg0 / float(jc), tc0 / float(jc)])
