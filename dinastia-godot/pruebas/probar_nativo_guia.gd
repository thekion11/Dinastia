class_name ProbarNativoGuia
extends RefCounted
## La guía de clips de League en C++ = la de GDScript (16-11-2026, paso a C++, orden del dueño «50 % del tiempo de CPU en C++»; lo llama
## `probar_nativo.gd`): `LeagueGuia.paso` por la extensión (`guia_pendientes` + `decidir` + `guia_seguir`) frente a `LeagueGuia._paso_gd`, con dos
## copias iguales de 22 jugadores durante 600 pasos: diccionarios enteros (`var_to_bytes`, sin el nodo), posiciones y contadores iguales.
## Cubre arranques, frenadas y giros con clip, cortes (CPU y jugador humano), marchas, porteros, gestos, caídas y nodos liberados.
## Devuelve {fallos: Array[String], textos: Array[String]}.

static func _grupo(raiz: Node3D) -> Array:
	var g: Array = []
	for q in 22:
		var n := Node3D.new()
		raiz.add_child(n)
		n.position = Vector3(float(q % 5) * 6.0 - 12.0, 0.0, float(q / 5) * 9.0 - 20.0)
		n.rotation.y = float(q) * 0.7
		g.append({"node": n, "id": "j%d" % q, "vel": Vector3.ZERO, "objetivo": n.position, "attr": {"rit": 0.4 + 0.5 * float(q % 5) / 4.0},
			"aguante": 0.8, "correr": q % 2 == 0, "por": q == 0 or q == 11, "es_local": q < 11, "anim_actual": "ls_ciclo__trote" if q % 4 == 1 else "trotar"})
	return g

static func _sin_nodo(p: Dictionary) -> PackedByteArray:
	var c := p.duplicate(true)
	c.erase("node")
	return var_to_bytes(c)

static func probar(nat: Object, raiz: Node3D) -> Dictionary:
	var fallos: Array[String] = []
	var textos: Array[String] = []
	if nat == null or not nat.has_method("guia_seguir"):
		fallos.append("la extensión no tiene guia_seguir")
		return {"fallos": fallos, "textos": textos}
	var motor := MotorJugable.new()
	var g: Array = [_grupo(raiz), _grupo(raiz)]
	var rr := RandomNumberGenerator.new()
	rr.seed = 1611
	var dt := 1.0 / 30.0
	motor.t = 0.0
	var r := _pasos(nat, motor, g, rr, dt)
	var dis: int = r["dis"]
	var tg: int = r["tg"]
	var tc: int = r["tc"]
	var cuenta: Array = r["cuenta"]
	if dis > 0:
		fallos.append("guía de clips: %d jugadores-paso distintos" % dis)
	if cuenta[0] != cuenta[1]:
		fallos.append("guía de clips: contadores distintos %s / %s" % [str(cuenta[0]), str(cuenta[1])])
	if int(cuenta[0][1]) == 0 or int(cuenta[0][0]) == 0:
		fallos.append("guía de clips: la prueba no ejercita guía y cortes (%s)" % str(cuenta[0]))
	textos.append("guía de clips: GDScript %.1f µs, C++ %.1f µs por paso (cortes %d, guiados %d)" % [tg / 600.0, tc / 600.0, cuenta[0][0], cuenta[0][1]])
	motor.free()
	return {"fallos": fallos, "textos": textos}


## Los 600 pasos de la guía: cada paso lo calculan la extensión y GDScript y se comparan.
static func _pasos(nat: Object, motor: MotorJugable, g: Array, rr: RandomNumberGenerator, dt: float) -> Dictionary:
	var dis := 0
	var tg := 0
	var tc := 0
	var cuenta := [[0, 0], [0, 0]]
	for paso in 600:
		## El «motor» de la prueba: cambia objetivos, velocidades y estados igual en las dos copias.
		for q in 22:
			var cambios := {}
			if rr.randf() < 0.08:
				cambios["objetivo"] = Vector3(rr.randf_range(-34, 34), 0, rr.randf_range(-52, 52))
			if rr.randf() < 0.3:
				var a := rr.randf_range(-PI, PI)
				cambios["vel"] = Vector3(sin(a), rr.randf_range(-0.2, 0.2), cos(a)) * rr.randf_range(0.0, 8.5)
			if rr.randf() < 0.02:
				cambios["gesto_hasta"] = motor.t + rr.randf_range(0.1, 0.6)
			if rr.randf() < 0.01:
				cambios["levanta_hasta"] = motor.t + 0.4
			if rr.randf() < 0.01:
				cambios["mirar_hasta"] = motor.t + 0.3
			if q == 7 and paso == 300:
				cambios["levantar_en"] = motor.t + 1.0
			if q == 5:
				cambios["ls_humano"] = paso % 200 < 100
			for k in 2:
				var p: Dictionary = g[k][q]
				for c: String in cambios:
					p[c] = cambios[c]
				var n: Node3D = p["node"]
				var v: Vector3 = p["vel"]
				n.position += Vector3(v.x, 0.0, v.z) * dt
				if Vector2(v.x, v.z).length() > 0.8:
					n.rotation.y = atan2(v.x, v.z)
		motor.poseedor = {}
		for k in 2:
			motor.jugadores = g[k]
			motor.usuario = g[k][9]
			var p_pos: Dictionary = g[k][paso % 22]
			motor.poseedor = p_pos if paso % 3 == 0 else {}
			LeagueGuia.reiniciar_cuenta()
			var t0 := Time.get_ticks_usec()
			if k == 0:
				LeagueGuia._paso_gd(motor, dt)
			else:
				LeagueGuia.paso(motor, dt)
			var t1 := Time.get_ticks_usec()
			if k == 0:
				tg += t1 - t0
			else:
				tc += t1 - t0
			cuenta[k][0] += LeagueGuia.cortes
			cuenta[k][1] += LeagueGuia.guiados
		for q in 22:
			var a: Dictionary = g[0][q]
			var b: Dictionary = g[1][q]
			if _sin_nodo(a) != _sin_nodo(b) or (a["node"] as Node3D).position != (b["node"] as Node3D).position:
				dis += 1
		motor.t += dt
	return {"dis": dis, "tg": tg, "tc": tc, "cuenta": cuenta}
