extends "res://pruebas/banco/partido_p2.gd"
## (Parte 1 de 2 de `partido_p3.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `partido_p3.gd`, conserva la clase.)

## [Capa 3/6 de `partido.gd`] _probar_fisica_motor, _probar_ventaja, _probar_presion_estable, _probar_presion_zona, _probar_linea_prevista, _probar_primer_toque, _probar_tactica_viva, _probar_pase_mejora, _probar_estilo_club, _probar_perfiles_ayuda

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
		## Salto = moverse MÁS de lo que permite su velocidad (4-11: un tiro fuerte de ~37 m/s recorre 1,2 m en un fotograma sin saltar).
		if bprev != Vector3.INF and pb.distance_to(bprev) > maxf(1.2, motor.vel_balon.length() * dt * 1.3) and motor.estado == "juego":
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

## EL PRIMER TOQUE QUE SE ESCAPA (01-11-2026, IA U5, `MotorControl`).
func _probar_primer_toque() -> void:
	_titulo("PRIMER TOQUE BAJO PRESIÓN")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var loc: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))
	var vis: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]) and not bool(p["por"]))
	var gk: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["por"]))
	for i in vis.size():
		(vis[i]["node"] as Node3D).position = Vector3(-30.0 + i * 3.0, 0, 40.0)
	var p: Dictionary = loc[0]
	(p["node"] as Node3D).position = Vector3.ZERO
	(p["node"] as Node3D).rotation.y = 0.0
	motor.balon.position = Vector3(0, 0.11, 0.5)
	motor.vel_balon = Vector3(0, 0, -6.0)
	_comprobar(MotorControl.riesgo(motor, p) == 0.0, "balón suave y nadie cerca: control seguro")
	(vis[0]["node"] as Node3D).position = Vector3(0.6, 0, 0)
	var con_rival := MotorControl.riesgo(motor, p)
	_comprobar(con_rival > 0.0, "con un rival a 0,6 m el control puede irse (%.3f)" % con_rival)
	motor.vel_balon = Vector3(0, 0, 22.0)   ## rápido y por la espalda (mira a +z y el balón va a +z)
	var detras := MotorControl.riesgo(motor, p)
	motor.vel_balon = Vector3(0, 0, -22.0)
	var frente := MotorControl.riesgo(motor, p)
	_comprobar(detras > frente and frente > con_rival, "rápido cuesta más, y por la espalda más aún (%.3f > %.3f)" % [detras, frente])
	_comprobar(detras <= MotorControl.TOPE, "nunca pasa del tope (%.3f)" % detras)
	_comprobar(gk.is_empty() or MotorControl.riesgo(motor, gk[0]) == 0.0, "el portero no se ve afectado")
	(r[1] as Node3D).queue_free()

## LA TÁCTICA SEGÚN EL MARCADOR Y EL RELOJ (01-11-2026, IA U2, `MotorTacticaViva`).
func _probar_tactica_viva() -> void:
	_titulo("TÁCTICA SEGÚN MARCADOR Y RELOJ")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	motor.goles = [0, 1]
	motor.mitad = 1
	motor.t = 0.0
	_comprobar(MotorTacticaViva.urgencia(motor, true) == 0.0, "al empezar, perder 0-1 no cambia nada")
	motor.mitad = 2
	motor.t = motor.duracion_mitad * 0.9
	var pierde := MotorTacticaViva.urgencia(motor, true)
	var gana := MotorTacticaViva.urgencia(motor, false)
	_comprobar(pierde > 0.2 and gana < -0.2, "al final, el que pierde se adelanta y el que gana se repliega (%.2f / %.2f)" % [pierde, gana])
	motor.goles = [0, 4]
	_comprobar(MotorTacticaViva.urgencia(motor, true) <= MotorTacticaViva.TOPE, "con tope (%.2f)" % MotorTacticaViva.urgencia(motor, true))
	motor.control_equipo = 0
	_comprobar(MotorTacticaViva.urgencia(motor, true) == 0.0, "el equipo del usuario no se toca")
	(r[1] as Node3D).queue_free()

## EL PASE POR CUÁNTO MEJORA (01-11-2026, IA R2, `MotorPaseMejora`, bandera PMOT_PASE): apagada, la cuenta de siempre; encendida,
## el rival que llega corriendo a la línea del pase cuenta, y pasar a la espalda cuesta.
func _probar_pase_mejora() -> void:
	_titulo("PASE POR MEJORA (BANDERA)")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var loc: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))
	var vis: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]))
	for i in vis.size():
		(vis[i]["node"] as Node3D).position = Vector3(-30.0 + i * 3.0, 0, 45.0)
		vis[i]["vel"] = Vector3.ZERO
	var p: Dictionary = loc[0]
	var q: Dictionary = loc[1]
	(p["node"] as Node3D).position = Vector3.ZERO
	(p["node"] as Node3D).rotation.y = 0.0
	(q["node"] as Node3D).position = Vector3(0, 0, 16.0)
	q["vel"] = Vector3.ZERO
	## Un rival a 3 m de la línea del pase, corriendo hacia ella a 7 m/s.
	(vis[0]["node"] as Node3D).position = Vector3(3.0, 0, 8.0)
	vis[0]["vel"] = Vector3(-7.0, 0, 0)
	var antes := MotorPaseMejora.ACTIVO
	MotorPaseMejora.ACTIVO = false
	var apagada: Array = MotorPaseMejora.libre_y_riesgo(motor, p, q, Vector3.ZERO, Vector3(0, 0, 16.0))
	MotorPaseMejora.ACTIVO = true
	var encendida: Array = MotorPaseMejora.libre_y_riesgo(motor, p, q, Vector3.ZERO, Vector3(0, 0, 16.0))
	_comprobar(float(apagada[1]) == 0.0, "apagada: el rival a 3 m de la línea no cuenta (%.2f)" % float(apagada[1]))
	_comprobar(float(encendida[1]) > 1.0, "encendida: el que llega corriendo, sí (%.2f)" % float(encendida[1]))
	(vis[0]["node"] as Node3D).position = Vector3(-30.0, 0, 45.0)
	var adelante: float = MotorPaseMejora.libre_y_riesgo(motor, p, q, Vector3.ZERO, Vector3(0, 0, 16.0))[1]
	(q["node"] as Node3D).position = Vector3(0, 0, -16.0)
	var atras: float = MotorPaseMejora.libre_y_riesgo(motor, p, q, Vector3.ZERO, Vector3(0, 0, -16.0))[1]
	_comprobar(atras > adelante + 1.0, "encendida: pasar a la espalda cuesta (%.2f frente a %.2f)" % [atras, adelante])
	MotorPaseMejora.ACTIVO = antes
	(r[1] as Node3D).queue_free()

## EL ESTILO PROPIO DE CADA CLUB (01-11-2026, IA U8, `MotorTacticaViva.estilo_club`).
func _probar_estilo_club() -> void:
	_titulo("ESTILO PROPIO DE CADA CLUB")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var clubes: Array = m.ligas[0].clubes
	var vistos := {}
	for c: Club in clubes:
		vistos[str(MotorTacticaViva.estilo_club(c))] = true
	_comprobar(vistos.size() >= clubes.size() - 2, "casi cada club tiene su estilo (%d distintos de %d)" % [vistos.size(), clubes.size()])
	var e := MotorTacticaViva.estilo_club(clubes[0])
	_comprobar(e == MotorTacticaViva.estilo_club(clubes[0]) and absf(float(e["f_linea"])) <= 0.5 and absf(float(e["f_amplitud"])) <= MotorTacticaViva.MATIZ,
		"fijo y dentro de sus topes (%s)" % str(e))
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var p: Dictionary = motor.jugadores.filter(func(q: Dictionary) -> bool: return bool(q["es_local"]) and not bool(q["por"]))[0]
	motor.tacticas[0] = {}
	var sin := motor._forma(p, true)
	motor.tacticas[0] = {"f_linea": 0.5, "f_amplitud": 0.0}
	var con := motor._forma(p, true)
	_comprobar((con.z - sin.z) * motor.dir_ataque(true) > 1.0, "en `_forma`, el matiz de línea adelanta el bloque (%.2f m)" % ((con.z - sin.z) * motor.dir_ataque(true)))
	(r[1] as Node3D).queue_free()

## PERFILES DE AYUDA (01-11-2026, M-131): Arcade / Semi / Manual aplican las tres ayudas de una vez.
func _probar_perfiles_ayuda() -> void:
	_titulo("PERFILES DE AYUDA")
	var antes := {}
	for k: String in ["pase", "tiro", "cambio"]:
		antes[k] = Mando.ayuda(k)
	Mando.aplicar_perfil("manual")
	_comprobar(Mando.ayuda("pase") == "manual" and Mando.ayuda("tiro") == "manual" and Mando.ayuda("cambio") == "manual" and Mando.perfil() == "manual", "Manual: todo a mano")
	Mando.aplicar_perfil("semi")
	_comprobar(Mando.ayuda("pase") == "asistido" and Mando.ayuda("tiro") == "manual" and Mando.perfil() == "semi", "Semi: pase asistido y tiro manual")
	Mando.fijar_ayuda("cambio", "manual")
	_comprobar(Mando.perfil() == "personalizado", "si tocas una ayuda suelta, el perfil pasa a personalizado")
	Mando.aplicar_perfil("arcade")
	_comprobar(Mando.perfil() == "arcade", "Arcade: todo asistido")
	for k: String in antes:
		Mando.fijar_ayuda(k, String(antes[k]))

## COLOCACIÓN SIN BALÓN CON MEMORIA (03-11-2026, IA F1, `MotorColocacion`): el bloque mira un balón con retardo y recuerda quién tuvo la posesión.
func _probar_colocacion() -> void:
	_titulo("COLOCACIÓN SIN BALÓN CON MEMORIA")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	motor.balon.position = Vector3(0, 0.11, 0)
	MotorColocacion.actualizar(motor, 0.1)
	motor.balon.position = Vector3(0, 0.11, 30.0)
	for i in 10:
		MotorColocacion.actualizar(motor, 0.1)
	var z1 := MotorColocacion.balon_lento(motor, true).z
	_comprobar(z1 > 1.0 and z1 < 24.0, "al segundo el balón lento va por detrás del real (%.1f de 30 m)" % z1)
	for i in 300:
		MotorColocacion.actualizar(motor, 0.1)
	_comprobar(MotorColocacion.balon_lento(motor, true).z > 28.0, "a los 30 s ya lo alcanzó")
	var loc: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))
	motor.poseedor = loc[0]
	for i in 150:
		MotorColocacion.actualizar(motor, 0.1)
	var s_l := MotorColocacion.sesgo(motor, true)
	var s_v := MotorColocacion.sesgo(motor, false)
	_comprobar(s_l > 0.9 and s_v < 0.1, "tras 15 s con el balón, sesgo local %.2f y rival %.2f" % [s_l, s_v])
	var con := MotorColocacion.pesos(motor, true, false)
	var sin := MotorColocacion.pesos(motor, false, false)
	_comprobar(con[0] < sin[0] and con[1] < sin[1], "con balón sigue menos al balón (%.2f frente a %.2f) y sin él se junta" % [con[0], sin[0]])
	_comprobar(con[0] > 0.2 and sin[0] < 0.7, "los pesos son razonables")
	(r[1] as Node3D).queue_free()

## MARCAJE A LOS 3 RIVALES MÁS PELIGROSOS (03-11-2026, IA F4, `MotorMarcaje`): un marcador por peligroso, distintos y estables.
func _probar_marcaje() -> void:
	_titulo("MARCAJE A LOS PELIGROSOS")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var locales: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))
	var vis: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]) and not bool(p["por"]))
	var arco := motor._arco_propio(locales[0])
	var hacia := (Vector3(0, 0, 0) - arco).normalized()
	## Toda la visita lejos, salvo tres delanteros en el área; los locales repartidos por detrás.
	for i in vis.size():
		(vis[i]["node"] as Node3D).position = Vector3(-30.0 + i * 5.0, 0, -arco.z * 0.9 + 0.0)
	for i in 3:
		(vis[i]["node"] as Node3D).position = arco + hacia * (12.0 + i * 3.0) + Vector3(-6.0 + i * 6.0, 0, 0)
	for i in locales.size():
		(locales[i]["node"] as Node3D).position = arco + hacia * 18.0 + Vector3(-12.0 + i * 2.5, 0, 0)
	motor.balon.position = Vector3(0, 0.11, 0)
	motor.poseedor = {}
	motor.t += 1.0
	var mapa := MotorMarcaje.reparto(motor, true)
	var marcadores := mapa.values()
	_comprobar(mapa.size() == 3, "los 3 delanteros tienen marcador (%d)" % mapa.size())
	var unicos := {}
	for mid in marcadores:
		unicos[mid] = true
	_comprobar(unicos.size() == mapa.size(), "ningún defensa marca a dos")
	var ok := true
	for qid in mapa:
		var mid: String = mapa[qid]
		var p: Variant = locales.filter(func(x: Dictionary) -> bool: return String(x["id"]) == mid)
		var marcado := MotorMarcaje.rival_de(motor, p[0]) if not p.is_empty() else {}
		ok = ok and not p.is_empty() and String(marcado.get("id", "")) == String(qid)
	_comprobar(ok, "cada marcador sabe a quién marca")
	## Estabilidad: se mueven un poco y, medio segundo después, el reparto es el mismo.
	for i in 3:
		(vis[i]["node"] as Node3D).position += Vector3(1.0, 0, 0.5)
	motor.t += 0.7
	var mapa2 := MotorMarcaje.reparto(motor, true)
	_comprobar(mapa2 == mapa, "el reparto no cambia por moverse un poco")
	(r[1] as Node3D).queue_free()

## CARRERAS AL ESPACIO (03-11-2026, IA F5, `MotorCarreras`): un solo delantero corre al hueco; los demás mantienen la forma.
func _probar_carreras() -> void:
	_titulo("CARRERAS AL ESPACIO CON TEMPORIZADOR")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var locales: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))
	var delanteros: Array = locales.filter(func(p: Dictionary) -> bool: return motor._rol(p) in MotorCarreras.ROLES)
	var otros: Array = locales.filter(func(p: Dictionary) -> bool: return not (motor._rol(p) in MotorCarreras.ROLES))
	if delanteros.size() < 2 or otros.is_empty():
		_comprobar(false, "hay al menos 2 delanteros y otro jugador (%d)" % delanteros.size())
		(r[1] as Node3D).queue_free()
		return
	var dz := motor.dir_ataque(true)
	var linea := 20.0 * dz
	for i in delanteros.size():
		(delanteros[i]["node"] as Node3D).position = Vector3(-10.0 + i * 8.0, 0, linea - dz * 4.0)
	(otros[0]["node"] as Node3D).position = Vector3(0, 0, 0)
	motor.poseedor = otros[0]
	motor.t = 10.0
	var en_linea := 0
	for p: Dictionary in delanteros:
		var o := MotorCarreras.objetivo(motor, p, Vector3(pos_x(p), 0, linea - dz * 9.0), linea, dz)
		if absf(o.z - (linea - dz * 0.6)) < 0.01 and bool(p["correr"]):
			en_linea += 1
	_comprobar(en_linea == 1, "solo un delantero hace la carrera (%d)" % en_linea)
	var detras := true
	for p: Dictionary in delanteros:
		var o2 := MotorCarreras.objetivo(motor, p, Vector3(pos_x(p), 0, linea - dz * 9.0), linea, dz)
		if absf(o2.z - (linea - dz * 0.6)) > 0.01:
			detras = detras and (linea - o2.z) * dz >= 3.0
	_comprobar(detras, "los demás se quedan al menos 3 m por detrás de la línea")
	## Termina: pasado el tiempo máximo, nadie corre durante el descanso.
	motor.t += MotorCarreras.DUR_MAX + 0.2
	for p: Dictionary in delanteros:
		MotorCarreras.objetivo(motor, p, Vector3(pos_x(p), 0, linea - dz * 9.0), linea, dz)
	var e: Dictionary = motor.get_meta("_carrera_l")
	_comprobar(String(e["id"]) == "" and float(e["libre"]) > motor.t, "tras la carrera hay un descanso antes de la siguiente")
	_comprobar(MotorCarreras.hueco(motor, true) >= -motor.ANCHO and MotorCarreras.hueco(motor, true) <= motor.ANCHO, "el hueco cae dentro del campo")
	(r[1] as Node3D).queue_free()

## (11-11, ideas del dueño) C4 abre dos carreras a la vez (`MejorasC4`); el motor de siempre sigue con una.
func _probar_mejoras_c4() -> void:
	_titulo("MEJORAS DE C4: DOS DESMARQUES A LA VEZ")
	var c4 := MotorFabrica.crear("combinado_c4")
	_comprobar(int(c4.get_meta("carreras_n", 1)) == (2 if MejorasC4.DESMARQUES else 1) and not MotorJugable.new().has_meta("carreras_n"), "C4 abre dos plazas de carrera; el motor de siempre, una")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	MejorasC4.DESMARQUES = true
	MejorasC4.preparar(motor)
	var del: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]) and motor._rol(p) in MejorasC4.ROLES_CARRERA)
	var otro: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]) and not (motor._rol(p) in MejorasC4.ROLES_CARRERA))
	var dz := motor.dir_ataque(true)
	for i in del.size():
		(del[i]["node"] as Node3D).position = Vector3(-12.0 + i * 6.0, 0, 20.0 * dz - dz * 4.0)
	motor.poseedor = otro[0]
	motor.t = 10.0
	var corren := 0
	for p: Dictionary in del:
		if absf(MotorCarreras.objetivo(motor, p, Vector3.ZERO, 20.0 * dz, dz).z - (20.0 * dz - dz * 0.6)) < 0.01:
			corren += 1
	_comprobar(corren == 2 and MejorasC4.corredores(motor, true).size() == 2, "con C4 corren dos al espacio (%d)" % corren)
	(r[1] as Node3D).queue_free()

func pos_x(p: Dictionary) -> float:
	return (p["node"] as Node3D).position.x
