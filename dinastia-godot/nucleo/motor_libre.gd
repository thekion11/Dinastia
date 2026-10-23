class_name MotorLibre
extends "res://nucleo/motor_libre_p1.gd"
## [Capa 2/2 de `motor_libre.gd`] _mover_todos, paso, resultado, simular, foto, tomar_control … (+3)

# ---------------------------------------------------------------------------
#  EL MOVIMIENTO SIN BALÓN
# ---------------------------------------------------------------------------

func _mover_todos() -> void:
	var eq_bal := -1
	if poseedor >= 0:
		eq_bal = agentes[poseedor]["eq"]
	elif not _vuelo.is_empty():
		eq_bal = agentes[int(_vuelo["destino"])]["eq"]
	## Los dos defensores más cerca del balón presionan (o van a por él si
	## está suelto).
	var cazadores := {}
	for eq in 2:
		if eq == eq_bal:
			continue
		var orden: Array = []
		for i in agentes.size():
			if agentes[i]["eq"] == eq and (agentes[i]["j"] as Jugador).pos != "POR":
				orden.append([(agentes[i]["pos"] as Vector2).distance_squared_to(balon), i])
		orden.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
		for n in mini(2 if eq_bal >= 0 else 1, orden.size()):
			cazadores[orden[n][1]] = n
	for i in agentes.size():
		var a: Dictionary = agentes[i]
		if t < float(a["sentado_hasta"]):
			continue
		var eq: int = a["eq"]
		var p: Vector2 = a["pos"]
		var vel: float = a["vel_max"]
		var destino: Vector2
		if i == controlado and poseedor != i:
			destino = p + _entrada * vel * dt * 4.0
		elif i == poseedor:
			if i == controlado:
				destino = p + _entrada * vel * dt * 4.0
				vel *= 0.85
			else:
				destino = a["objetivo"]
				vel *= 0.8
			## Con un rival delante tapando, se avanza a paso de hombre.
			var r := _rival_mas_cerca(p, eq)
			if r >= 0:
				var dr: Vector2 = agentes[r]["pos"] - p
				if dr.length() < 2.2 and dr.x * _dir(eq) > 0.0:
					vel *= 0.35
		elif cazadores.has(i):
			## El primero va al balón; el segundo cubre por delante.
			## Se pone entre el balón y su portería, sin lanzarse (temporiza).
			var propia := Vector2(-MEDIO_L * _dir(eq), 0.0)
			destino = balon + (propia - balon).normalized() * (1.2 if cazadores[i] == 0 else 9.0)
			if poseedor < 0:
				destino = balon
		else:
			destino = _sitio(a, eq == eq_bal)
			## MARCAJE: el que defiende se pega, por el lado de su portería, al
			## rival que tiene cerca de su zona.
			if eq != eq_bal and eq_bal >= 0 and (a["j"] as Jugador).pos != "POR":
				var m := _marca_de(i, destino)
				if m >= 0:
					var q: Vector2 = agentes[m]["pos"]
					var propia := Vector2(-MEDIO_L * _dir(eq), 0.0)
					destino = q + (propia - q).normalized() * 1.8
			else:
				vel *= 0.75
		var paso_v := destino - p
		var maxd := vel * dt
		if paso_v.length() > maxd:
			paso_v = paso_v.normalized() * maxd
		p += paso_v
		p.x = clampf(p.x, -MEDIO_L, MEDIO_L)
		p.y = clampf(p.y, -MEDIO_A, MEDIO_A)
		a["pos"] = p
		if i == poseedor:
			balon = p
			## Si llegó a donde iba, que vuelva a pensar ya.
			if p.distance_to(a["objetivo"]) < 0.6:
				a["proxima"] = minf(float(a["proxima"]), t)

# ---------------------------------------------------------------------------
#  EL PASO
# ---------------------------------------------------------------------------

func paso() -> void:
	t += dt
	if poseedor >= 0:
		stats["posesion"][agentes[poseedor]["eq"]] += dt
	if not _vuelo.is_empty():
		_mover_vuelo()
	elif poseedor < 0:
		_balon_suelto()
	else:
		balon = agentes[poseedor]["pos"]
		if poseedor == controlado:
			_decidir_controlado()
		elif t >= float(agentes[poseedor]["proxima"]):
			_decidir(poseedor)
		if poseedor >= 0 and _vuelo.is_empty():
			_disputa()
	_mover_todos()

func resultado() -> Dictionary:
	var pos_tot: float = stats["posesion"][0] + stats["posesion"][1]
	return {"goles": goles.duplicate(), "tiros": stats["tiros"].duplicate(),
		"pases": stats["pases"].duplicate(), "pases_ok": stats["pases_ok"].duplicate(),
		"posesion": [roundf(100.0 * stats["posesion"][0] / maxf(1.0, pos_tot)), roundf(100.0 * stats["posesion"][1] / maxf(1.0, pos_tot))],
		"regates": stats["regates"].duplicate(), "regates_ok": stats["regates_ok"].duplicate(),
		"entradas_ok": stats["entradas_ok"].duplicate(), "xg": stats["xg"].duplicate(), "decisiones": stats["decisiones"].duplicate()}

# ---------------------------------------------------------------------------
#  API
# ---------------------------------------------------------------------------

func simular(minutos: float = 90.0) -> Dictionary:
	while t < minutos * 60.0:
		paso()
	return resultado()

## Posiciones de todo (para dibujarlo o mandarlo al 3D).
func foto() -> Dictionary:
	var ps: Array = []
	for a: Dictionary in agentes:
		ps.append({"id": (a["j"] as Jugador).id, "eq": a["eq"], "pos": a["pos"]})
	return {"t": t, "balon": balon, "poseedor": poseedor, "agentes": ps}

func tomar_control(indice: int) -> void:
	controlado = indice

## Dirección del stick para el jugador controlado.
func mover(v: Vector2) -> void:
	_entrada = v.limit_length(1.0)

## Una acción del catálogo (`AccionesJuego`) para el jugador controlado.
func ordenar(accion: String) -> void:
	_orden = accion

## El botón de cambiar: el compañero más cerca del balón.
func cambiar_jugador() -> void:
	if controlado < 0:
		return
	var eq: int = agentes[controlado]["eq"]
	var mejor := controlado
	var md := INF
	for i in agentes.size():
		if i != controlado and agentes[i]["eq"] == eq:
			var d: float = (agentes[i]["pos"] as Vector2).distance_to(balon)
			if d < md:
				md = d
				mejor = i
	controlado = mejor
