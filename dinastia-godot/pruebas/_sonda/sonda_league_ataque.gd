extends Node
## Sonda de la fase 4c: con balón, ¿a qué distancia del arco rival están el portador, el compañero más adelantado y la línea
## del fuera de juego rival? Dos cruces de países y estilos distintos. MOTOR=siempre para comparar.
func _ready() -> void:
	await get_tree().process_frame
	var m := Mundo.new()
	m.generar(["CHI", "ARG", "ESP"], 4711)
	var cruces := [[m.ligas[0].clubes[0], m.ligas[1].clubes[1]], [m.ligas[2].clubes[3], m.ligas[0].clubes[5]]]
	for cr: Array in cruces:
		var a: Club = cr[0]
		var b: Club = cr[1]
		var raiz := Node3D.new()
		add_child(raiz)
		var sp := PlayerSpawner.new()
		var lista: Array = []
		var l := Puente3D.once(a.once())
		var v := Puente3D.once(b.once())
		lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
		lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
		var ball := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
		var motor: MotorJugable = MotorJugable.new() if OS.get_environment("MOTOR") == "siempre" else MotorLeague.new()
		raiz.add_child(motor)
		motor.set_physics_process(false)
		motor.autopiloto = true
		motor.duracion_mitad = 120.0
		motor.tacticas = [MotorJugable.tactica_desde(a.tactica), MotorJugable.tactica_desde(b.tactica)]
		motor.preparar(lista, ball, "", 9)
		var n := 0
		var s := [0.0, 0.0, 0.0, 0.0]
		for i in 7200:
			motor.paso(1.0 / 30.0)
			if i % 15 != 0 or motor.poseedor.is_empty() or motor.estado != "juego":
				continue
			var pp: Dictionary = motor.poseedor
			var loc := bool(pp["es_local"])
			var arco_z := MotorJugable.LARGO * MotorJugable.dir_ataque(loc)
			var adel := 999.0
			var defz: Array = []
			for q: Dictionary in motor.jugadores:
				var dz := absf(arco_z - motor.pos(q).z)
				if bool(q["es_local"]) == loc:
					adel = minf(adel, dz)
				else:
					defz.append(dz)
			defz.sort()
			n += 1
			s[0] += absf(arco_z - motor.pos(pp).z)
			s[1] += adel
			s[2] += float(defz[1])   ## el penúltimo rival (el primero es el portero)
			s[3] += float(defz[2])
		print("ATAQUE %s (%s) - %s (%s): portador %.1f m · compañero más adelantado %.1f m · línea rival (2.º) %.1f m · 3.º %.1f m · muestras %d" % [a.nombre, a.pais, b.nombre, b.pais, s[0] / n, s[1] / n, s[2] / n, s[3] / n, n])
		raiz.queue_free()
	get_tree().quit()
