extends BaseIdea
## LA PIZARRA SE NOTA (01-11-2026, fase 4 «jugabilidad», ideas 385-392 «verificar jugando»): cada perilla cambia el motor
## simulado (`Tactica.multiplicador_*`) Y el partido 3D. Al probarlo salió que «salida corta», «marca al hombre» y «tiro
## lejano» no llegaban al 3D; ahora sí (`MotorTacticaViva.bandera`).

var _raiz: Node3D

func _motor() -> MotorJugable:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	_raiz = Node3D.new()
	add_child(_raiz)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	lista.append_array(sp.spawn_team(_raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(_raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ball := StadiumBuilder.spawn_ball(_raiz, Vector3(0, 0.11, 0))
	var motor := MotorJugable.new()
	_raiz.add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = true
	motor.preparar(lista, ball, "", 7)
	return motor

func _probar() -> void:
	_titulo("LA PIZARRA SE NOTA (SIMULADO Y 3D)")
	## --- Motor simulado ---
	var base := Tactica.new()
	var cambios := [["linea", Tactica.Nivel.ALTO, 1, -1], ["presion", Tactica.Nivel.ALTO, 1, 0], ["ritmo", Tactica.Nivel.ALTO, 1, 0],
		["amplitud", Tactica.Nivel.ALTO, 1, 0], ["salida_corta", true, 1, 0], ["tiro_lejano", true, 1, 0],
		["marca_al_hombre", true, -1, 1], ["fuera_de_juego", true, 0, 1]]
	for c: Array in cambios:
		var t := Tactica.new()
		t.set(String(c[0]), c[1])
		var da := signf(snappedf(t.multiplicador_ataque() - base.multiplicador_ataque(), 0.0001))
		var dd := signf(snappedf(t.multiplicador_defensa() - base.multiplicador_defensa(), 0.0001))
		_comprobar((int(c[2]) == 0 or int(da) == int(c[2])) and (int(c[3]) == 0 or int(dd) == int(c[3])),
			"simulado: «%s» cambia ataque %+d / defensa %+d" % [c[0], int(da), int(dd)])
	## --- Partido 3D ---
	var motor := _motor()
	var p: Dictionary = motor.jugadores.filter(func(q: Dictionary) -> bool: return bool(q["es_local"]) and not bool(q["por"]) and motor._rol(q) in ["EI", "ED", "LI", "LD"])[0]
	var d := motor.dir_ataque(true)
	var tc := Tactica.new()
	motor.tacticas[0] = MotorJugable.tactica_desde(tc)
	var medio := motor._forma(p, true)
	tc.linea = Tactica.Nivel.ALTO
	motor.tacticas[0] = MotorJugable.tactica_desde(tc)
	_comprobar((motor._forma(p, true).z - medio.z) * d > 2.0, "3D: línea alta adelanta el bloque")
	tc.linea = Tactica.Nivel.MEDIO
	tc.amplitud = Tactica.Nivel.ALTO
	motor.tacticas[0] = MotorJugable.tactica_desde(tc)
	_comprobar(absf(motor._forma(p, true).x) > absf(medio.x) + 0.2, "3D: amplitud alta abre a los de banda (%.1f → %.1f)" % [absf(medio.x), absf(motor._forma(p, true).x)])
	tc.amplitud = Tactica.Nivel.MEDIO
	tc.presion = Tactica.Nivel.ALTO
	tc.ritmo = Tactica.Nivel.ALTO
	tc.salida_corta = true
	tc.tiro_lejano = true
	tc.marca_al_hombre = true
	tc.fuera_de_juego = true
	var td := MotorJugable.tactica_desde(tc)
	_comprobar(int(td["presion"]) == 2 and int(td["ritmo"]) == 2 and int(td["trampa"]) == 1, "3D: presión, ritmo y trampa llegan al motor")
	motor.tacticas[0] = td
	_comprobar(MotorTacticaViva.prob_salida_jugada(motor, true) > MotorTacticaViva.prob_salida_jugada(motor, false), "3D: con salida corta el portero juega más en corto")
	_comprobar(MotorTacticaViva.bandera(motor, true, "tiro_lejano") and MotorTacticaViva.bandera(motor, true, "marca") and not MotorTacticaViva.bandera(motor, false, "marca"),
		"3D: tiro lejano y marca al hombre llegan solo al equipo que los pide")
	## Marca al hombre: el defensor se pega más a su rival (1,2 m en vez de 2,4).
	motor.tacticas[1] = td
	var defensor: Dictionary = motor.jugadores.filter(func(q: Dictionary) -> bool: return not bool(q["es_local"]) and not bool(q["por"]) and not (motor._rol(q) in ["DFC", "LD", "LI"]))[0]
	for q: Dictionary in motor.jugadores:
		(q["node"] as Node3D).position = Vector3(0, 0, 200.0)
	motor.balon.position = Vector3(0, 0.11, 0)
	var medios: Array = motor.jugadores.filter(func(q: Dictionary) -> bool: return not bool(q["es_local"]) and not bool(q["por"]) and q != defensor)
	(medios[0]["node"] as Node3D).position = Vector3(0.5, 0, 0)   ## los que presionan son otros
	(medios[1]["node"] as Node3D).position = Vector3(-0.5, 0, 0)
	var fd := motor._forma(defensor, false)
	(defensor["node"] as Node3D).position = fd
	var atacante: Dictionary = motor.jugadores.filter(func(q: Dictionary) -> bool: return bool(q["es_local"]) and not bool(q["por"]))[0]
	(atacante["node"] as Node3D).position = fd + Vector3(3.0, 0, 0)
	var junto := motor._ia_defensa(defensor).distance_to(motor.pos(atacante))
	motor.tacticas[1] = MotorJugable.tactica_desde(Tactica.new())
	var zona := motor._ia_defensa(defensor).distance_to(motor.pos(atacante))
	_comprobar(junto < zona, "3D: al hombre se pega más al rival (%.1f m frente a %.1f m)" % [junto, zona])
	_raiz.queue_free()
