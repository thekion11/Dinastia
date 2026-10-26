extends "res://pruebas/banco/partido_p2.gd"
## [Capa 3/6 de `partido.gd`] _probar_fisica_motor

func _probar_fisica_motor() -> void:
	_titulo("FÍSICA DEL MOTOR (SIN PANTALLA)")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var raiz: Node3D = r[1]
	var ball: Node3D = r[2]
	var prev := {}
	var vprev := {}
	var rprev := {}
	var bprev := Vector3.INF
	var c := {"vel": 0, "giro": 0, "tiron": 0, "tele": 0, "muestras": 0}
	var dt := 1.0 / 30.0
	for _f in 1200:
		motor.paso(dt * 0.5)
		motor.paso(dt * 0.5)
		for p: Dictionary in motor.jugadores:
			var nd: Node3D = p["node"]
			var id := nd.get_instance_id()
			var pa := nd.position
			c["muestras"] += 1
			if prev.has(id):
				var vel: Vector3 = (pa - prev[id]) / dt
				vel.y = 0.0
				if vel.length() > 10.5:
					c["vel"] += 1
				if vprev.has(id) and (vel - (vprev[id] as Vector3)).length() / dt > 25.0 and vel.length() < 10.5:
					c["tiron"] += 1
				vprev[id] = vel
			if rprev.has(id) and absf(wrapf(nd.rotation.y - float(rprev[id]), -PI, PI)) / dt > deg_to_rad(720.0):
				c["giro"] += 1
			prev[id] = pa
			rprev[id] = nd.rotation.y
		var pb := ball.position
		if bprev != Vector3.INF and pb.distance_to(bprev) > 1.2 and motor.estado == "juego":
			c["tele"] += 1

		bprev = pb
	print("   · física: %s" % str(c))
	## Coste de CPU del motor (20-10-2026, para valorar C++): ms por paso.
	var t0 := Time.get_ticks_usec()
	for _k in 600:
		motor.paso(dt * 0.5)
	var us := float(Time.get_ticks_usec() - t0) / 600.0
	print("   · motor: %.3f ms por paso de 1/60 s (%.1f %% de un fotograma de 60 fps)" % [us / 1000.0, us / 1000.0 / 16.67 * 100.0])
	_comprobar(motor.minuto() >= 3, "el partido avanzó (minuto %d)" % motor.minuto())
	_comprobar(int(c["vel"]) == 0, "nadie corre a más de 10,5 m/s (%d)" % c["vel"])
	_comprobar(int(c["giro"]) == 0, "ningún giro de más de 720°/s (%d)" % c["giro"])
	_comprobar(float(c["tiron"]) / float(c["muestras"]) < 0.005, "tirones > 25 m/s² por debajo del 0,5 %% (%d de %d)" % [c["tiron"], c["muestras"]])
	_comprobar(int(c["tele"]) <= 3, "el balón no salta en pleno juego (%d)" % c["tele"])
	raiz.queue_free()
