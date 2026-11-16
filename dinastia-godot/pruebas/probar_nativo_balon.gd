class_name ProbarNativoBalon
extends RefCounted
## El balón de League en C++ = el de GDScript (16-11-2026, paso a C++; lo llama `probar_nativo.gd`): `balon_prediccion` frente a `MotorLeague.prediccion_gd` y
## `balon_avanzar` frente a `MotorLeague._avanzar_balon_gd`, byte a byte (var_to_bytes), con balones en el suelo, en el aire, rebotando, con efecto, dentro de la red,
## con portador y con viento/humedad. Devuelve {fallos: Array[String], textos: Array[String]}.

static func probar(nat: Object) -> Dictionary:
	var fallos: Array[String] = []
	var textos: Array[String] = []
	var rr := RandomNumberGenerator.new()
	rr.seed = 1611
	var motor := MotorLeague.new()
	var distintos_p := 0
	var distintos_a := 0
	var tp := [0, 0]
	var ta := [0, 0]
	var n := 600
	for caso in n:
		var cfg := LeagueNucleo.config_balon(rr.randf() * (1.0 if caso % 3 == 0 else 0.0), Vector3(rr.randf_range(-2, 2), 0, rr.randf_range(-2, 2)) if caso % 4 == 0 else Vector3.ZERO)
		var p := Vector3(rr.randf_range(-35, 35), rr.randf_range(0.0, 6.0) if caso % 2 == 0 else MotorJugable.R, rr.randf_range(-56, 56))
		if caso % 11 == 0:
			p.z = rr.randf_range(MotorJugable.LARGO - 0.5, MotorJugable.LARGO + 2.0) * (1.0 if caso % 2 == 0 else -1.0)
			p.x = rr.randf_range(-3, 3)
			p.y = rr.randf_range(0.2, 1.5)
		var v := Vector3(rr.randf_range(-25, 25), rr.randf_range(-8, 12) if caso % 2 == 0 else 0.0, rr.randf_range(-25, 25))
		var giro := Vector3(rr.randf_range(-30, 30), rr.randf_range(-30, 30), rr.randf_range(-30, 30)) if caso % 5 != 0 else Vector3.ZERO
		if caso % 13 == 0:
			v = Vector3.ZERO
		var hay := caso % 7 == 0
		var vp := Vector3(rr.randf_range(-8, 8), 0, rr.randf_range(-8, 8))
		## Predicción.
		var t0 := Time.get_ticks_usec()
		var a := MotorLeague.prediccion_gd(p, v, cfg, hay, vp, 70)
		var t1 := Time.get_ticks_usec()
		var b: PackedVector3Array = nat.balon_prediccion(p, v, cfg, hay, vp, 70, 0.01, MotorJugable.R)
		var t2 := Time.get_ticks_usec()
		tp[0] += t1 - t0
		tp[1] += t2 - t1
		if var_to_bytes(a) != var_to_bytes(b):
			distintos_p += 1
		## Pasos de 10 ms (delta de fotograma variable, con resto acumulado).
		motor.cfg_balon = cfg
		motor.vel_balon = v
		motor.giro_balon = giro
		motor._resto_balon = rr.randf() * 0.01
		var resto0: float = motor._resto_balon
		var delta := rr.randf_range(0.005, 0.05)
		var k := PackedFloat64Array([MotorLeague.PASO_BALON, MotorJugable.R, MotorJugable.R + 0.02, 0.2, 0.012, Balance.GIRO_AIRE, Balance.GIRO_SUELO, MotorJugable.LARGO, MotorJugable.PALO, MotorJugable.LARGUERO])
		var u0 := Time.get_ticks_usec()
		var pg := motor._avanzar_balon_gd(p, delta)
		var u1 := Time.get_ticks_usec()
		var r: Array = nat.balon_avanzar(p, v, giro, resto0, delta, cfg, k)
		var u2 := Time.get_ticks_usec()
		ta[0] += u1 - u0
		ta[1] += u2 - u1
		if var_to_bytes([pg, motor.vel_balon, motor.giro_balon, motor._resto_balon]) != var_to_bytes(r):
			distintos_a += 1
	motor.free()
	if distintos_p > 0:
		fallos.append("predicción del balón distinta en %d de %d casos" % [distintos_p, n])
	if distintos_a > 0:
		fallos.append("pasos del balón distintos en %d de %d casos" % [distintos_a, n])
	textos.append("balón (League): predicción GDScript %.1f µs, C++ %.1f µs; pasos GDScript %.1f µs, C++ %.1f µs por llamada" % [tp[0] / float(n), tp[1] / float(n), ta[0] / float(n), ta[1] / float(n)])
	return {"fallos": fallos, "textos": textos}
