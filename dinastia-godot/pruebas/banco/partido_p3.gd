extends "res://pruebas/banco/partido_p2.gd"
## [Capa 3/6 de `partido.gd`] _probar_fisica_motor, _probar_ventaja, _probar_presion_estable, _probar_presion_zona, _probar_linea_prevista

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
	var en_juego_antes := false
	for _f in 1200:
		motor.paso(dt * 0.5)
		motor.paso(dt * 0.5)
		## Recolocar para un saque (tras un gol, todos a su sitio) no es correr: solo cuenta en juego,
		## como el balón (27-10-2026: con un gol dentro de la muestra salían 22 «carreras» de 300 m/s).
		var en_juego := motor.estado == "juego"
		var cuenta := en_juego and en_juego_antes
		en_juego_antes = en_juego
		for p: Dictionary in motor.jugadores:
			var nd: Node3D = p["node"]
			var id := nd.get_instance_id()
			var pa := nd.position
			c["muestras"] += 1
			if prev.has(id) and cuenta:
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

## LA VENTAJA DE VERDAD (01-11-2026, IA R1, `MotorVentaja`): si el equipo de la víctima pierde el balón, se vuelve a la falta.
func _probar_ventaja() -> void:
	_titulo("VENTAJA: SE VUELVE A LA FALTA SI SE PIERDE EL BALÓN")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var loc: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))
	var vis: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]) and not bool(p["por"]))
	var lugar := Vector3(6.0, 0.0, 20.0 * motor.dir_ataque(true))
	## 1) Pierde el balón al segundo: falta para el local donde fue.
	motor.estado = "juego"
	motor._t_estado = 5.0
	motor.poseedor = loc[0]
	MotorVentaja.dar(motor, lugar, true, "Un defensor")
	motor.t += 1.0
	motor._t_estado += 1.0
	motor.poseedor = vis[0]
	MotorVentaja.revisar(motor)
	_comprobar(motor.estado == "saque" and String(motor.saque.get("tipo", "")) == "falta" and bool(motor.saque.get("local", false)),
		"perdió el balón: falta para el que la sufrió (%s, %s)" % [motor.estado, str(motor.saque.get("tipo", ""))])
	_comprobar((motor.saque.get("lugar", Vector3.ZERO) as Vector3).distance_to(Vector3(lugar.x, motor.R, lugar.z)) < 0.01, "y se saca donde fue la falta")
	_comprobar(MotorVentaja.pendiente(motor).is_empty() and int(motor.duelos.get("ventaja_vuelta", 0)) == 1, "la ventaja ya no queda pendiente")
	## 2) Sigue con el balón 3,5 s: la ventaja se da por jugada (aunque luego lo pierda).
	motor.estado = "juego"
	motor._t_estado = 5.0
	motor.poseedor = loc[0]
	MotorVentaja.dar(motor, lugar, true, "Un defensor")
	motor.t += 4.0
	motor._t_estado += 4.0
	MotorVentaja.revisar(motor)
	motor.poseedor = vis[0]
	MotorVentaja.revisar(motor)
	_comprobar(motor.estado == "juego" and MotorVentaja.pendiente(motor).is_empty(), "pasados 3,5 s la ventaja se da por jugada")
	## 3) El juego se paró entre medias (fuera, otra falta): tampoco se vuelve.
	MotorVentaja.dar(motor, lugar, true, "Un defensor")
	motor._t_estado = 0.2
	motor.poseedor = vis[0]
	MotorVentaja.revisar(motor)
	_comprobar(motor.estado == "juego" and MotorVentaja.pendiente(motor).is_empty(), "si el juego se paró, la ventaja se olvida")
	(r[1] as Node3D).queue_free()

## PRESIONADORES ESTABLES (01-11-2026, IA R3, `MotorPresion`): el papel no salta entre dos casi a la misma distancia.
func _probar_presion_estable() -> void:
	_titulo("PRESIONADORES ESTABLES")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var vis: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]) and not bool(p["por"]))
	var centrales := vis.filter(func(p: Dictionary) -> bool: return motor._rol(p) == "DFC")
	var otros := vis.filter(func(p: Dictionary) -> bool: return motor._rol(p) != "DFC")
	for i in vis.size():
		(vis[i]["node"] as Node3D).position = Vector3(-30.0 + i * 2.0, 0, 45.0)
	motor.balon.position = Vector3(0, 0.11, 0)
	var a: Dictionary = otros[0]
	var b: Dictionary = otros[1]
	var ida := String(a["id"])
	var idb := String(b["id"])
	var colocar := func(da: float, db: float) -> void:
		(a["node"] as Node3D).position = Vector3(da, 0, 0)
		(b["node"] as Node3D).position = Vector3(-db, 0, 0)
		motor.t += 0.1
	colocar.call(10.0, 10.4)
	_comprobar(MotorPresion.papeles(motor, false)[0] == ida, "presiona el más cercano")
	colocar.call(10.6, 10.0)
	_comprobar(MotorPresion.papeles(motor, false)[0] == ida, "si otro solo está 0,6 m mejor, no le quita el papel")
	colocar.call(10.6, 8.0)
	_comprobar(MotorPresion.papeles(motor, false)[0] == idb, "si está 2,6 m mejor, sí")
	## El segundo: un medio a 11 m antes que un central a 9 m.
	if not centrales.is_empty() and otros.size() > 2:
		(centrales[0]["node"] as Node3D).position = Vector3(0, 0, 9.0)
		(otros[2]["node"] as Node3D).position = Vector3(0, 0, -11.0)
		colocar.call(30.0, 5.0)
		motor.remove_meta("presion_antes")
		var pp := MotorPresion.papeles(motor, false)
		_comprobar(pp[0] == idb and pp[1] == String(otros[2]["id"]), "de segundo sale un medio y el central guarda su sitio (%s)" % motor._rol(motor.jugadores.filter(func(p: Dictionary) -> bool: return String(p["id"]) == String(pp[1]))[0]))
	(r[1] as Node3D).queue_free()

## PRESIÓN POR ZONA (01-11-2026, IA U1, `MotorPresion.zona`): con el balón adentrado y alguien cerca, sale a morder un rato.
func _probar_presion_zona() -> void:
	_titulo("PRESIÓN POR ZONA")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var loc: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))
	var vis: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]) and not bool(p["por"]))
	var dueno: Dictionary = loc[0]
	var d := motor.dir_ataque(true)
	(motor.tacticas[1] as Dictionary)["presion"] = 0
	for i in vis.size():
		(vis[i]["node"] as Node3D).position = Vector3(-30.0 + i * 2.0, 0, d * 50.0)
	## Local con el balón en su campo, a 35 m de su arco: territorio del visitante 0,83.
	(dueno["node"] as Node3D).position = Vector3(0, 0, -d * 17.5)
	(vis[0]["node"] as Node3D).position = Vector3(0, 0, -d * 25.0)
	_comprobar(not MotorPresion.zona(motor, dueno), "presión baja y nadie a menos de 5 m: espera")
	(vis[0]["node"] as Node3D).position = Vector3(0, 0, -d * 21.0)
	_comprobar(MotorPresion.zona(motor, dueno), "presión baja, balón en su campo y un rival a 3,5 m: sale a morder")
	(vis[0]["node"] as Node3D).position = Vector3(0, 0, -d * 30.0)
	motor.t += 1.0
	_comprobar(MotorPresion.zona(motor, dueno), "y aguanta la presión un rato aunque se aleje")
	motor.t += 2.0
	_comprobar(not MotorPresion.zona(motor, dueno), "a los 2 s la suelta")
	## Balón en el campo del que defiende (territorio 0,3): con presión baja, no.
	(dueno["node"] as Node3D).position = Vector3(0, 0, d * 21.0)
	(vis[0]["node"] as Node3D).position = Vector3(0, 0, d * 24.0)
	_comprobar(not MotorPresion.zona(motor, dueno), "en su propio campo, con presión baja, no sale")
	(motor.tacticas[1] as Dictionary)["presion"] = 2
	_comprobar(MotorPresion.zona(motor, dueno), "con presión alta, sí")
	(r[1] as Node3D).queue_free()

## LÍNEA DE FUERA DE JUEGO PREVISTA (01-11-2026, IA U3): para los desmarques, la defensa se mira donde estará en 0,24 s.
func _probar_linea_prevista() -> void:
	_titulo("LÍNEA DE FUERA DE JUEGO PREVISTA")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var vis: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]) and not bool(p["por"]))
	var d := motor.dir_ataque(false)
	for i in vis.size():
		(vis[i]["node"] as Node3D).position = Vector3(-20.0 + i * 3.0, 0, 0)
		vis[i]["vel"] = Vector3.ZERO
	## El último defensor, a 25 m de su arco, sube a 5 m/s: dentro de 0,24 s estará 1,2 m más arriba.
	(vis[0]["node"] as Node3D).position = Vector3(0, 0, -d * 27.5)
	vis[0]["vel"] = Vector3(0, 0, d * 5.0)
	var linea := motor._ultima_linea(false)
	_comprobar(absf(linea - (-d * 27.5 + d * 1.2)) < 0.01, "la línea se mira donde estará el último (%.2f)" % linea)
	var lado := signf(motor._arco_propio(vis[0]).z)
	var con_vel := motor.linea_fuera_de_juego(lado)
	vis[0]["vel"] = Vector3.ZERO
	_comprobar(is_equal_approx(con_vel, motor.linea_fuera_de_juego(lado)), "el fuera de juego del árbitro no usa la previsión (%.2f)" % con_vel)
	(r[1] as Node3D).queue_free()
