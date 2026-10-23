extends "res://visor/motor_jugable_p5.gd"
## (Parte 6 de 12 de `motor_jugable.gd`.)

## Patea el balón hacia `destino` con una velocidad horizontal `vh` y la
## parábola que haga falta para llegar ahí (más `loft` de altura extra).
func _patear(p: Dictionary, destino: Vector3, vh: float, loft := 0.0, efecto := 0.0, anim := "pase") -> void:
	_ultima_anim = anim
	_n_patada += 1
	var b := balon.position
	var d := Vector3(destino.x - b.x, 0, destino.z - b.z)
	var dist := maxf(d.length(), 0.1)
	var tv := dist / maxf(vh, 1.0)
	var vy := 0.0
	if loft > 0.0:
		## Envío por arriba: `loft` fija la ALTURA de la parábola y de ahí sale
		## el tiempo de vuelo, para que el balón CAIGA donde se apuntó (antes se
		## sumaba encima de la parábola y los despejes cruzaban el campo).
		var cumbre := maxf(1.5 + loft * 1.8, destino.y - b.y + 1.0)
		vy = sqrt(2.0 * G * cumbre)
		var caida := vy * vy - 2.0 * G * (destino.y - b.y)
		tv = (vy + sqrt(maxf(caida, 0.0))) / G
		vh = dist / maxf(tv, 0.2)
	elif destino.y > R + 0.05:
		vy = ((destino.y - b.y) + 0.5 * G * tv * tv) / tv
	## El arrastre frena: se compensa un poco para que llegue.
	var h := d / dist * vh * (1.0 + ARRASTRE * tv * 0.6)
	if vy <= 0.0:
		h = d / dist * vh
	vel_balon = Vector3(h.x, vy, h.z)
	giro_balon = Vector3(0, efecto, 0)
	if depurar:
		print("PATADA %s(%s) desde %s a %s vh %.1f loft %.1f vel %s" % [String(p.get("slot_code", "")), "L" if bool(p["es_local"]) else "V", str(b), str(destino), vh, loft, str(vel_balon)])
	if OS.get_environment("DEPURAR_AIRE") != "" and vy > 2.0:
		var clave := "%s/%s" % [_ctx_golpeo if _ctx_golpeo != "" else anim, estado]
		cuenta_aire[clave] = int(cuenta_aire.get(clave, 0)) + 1
	_foto_offside(p)
	penultimo_toque = ultimo_toque
	ultimo_toque = p
	poseedor = {}
	p["enfriar"] = 0.35
	balon.position.y = maxf(balon.position.y, R + 0.01)
	## Se gira hacia el destino en un giro rápido pero continuo (M-115): antes
	## se encaraba de golpe en un fotograma (giros de más de 720°/s).
	_mirar(p, atan2(d.x, d.z), 0.35)
	var ap: AnimationPlayer = p.get("anim")
	if is_instance_valid(ap):
		_anim(p, _golpeo_anim(p, ap, anim, destino, b, vh, loft, efecto), true)
	_ctx_golpeo = ""
	if p == usuario:
		stats["toques"] += 1

func _companero_cerca(p: Dictionary, punto: Vector3) -> Dictionary:
	var mejor: Dictionary = {}
	var md := 999.0
	for q: Dictionary in jugadores:
		if q != p and bool(q["es_local"]) == bool(p["es_local"]) and not bool(q["por"]):
			var d := pos(q).distance_to(punto)
			if d < md:
				md = d
				mejor = q
	return mejor

func _cabezazo(p: Dictionary) -> void:
	var arco := _arco_rival(p)
	var cerca := absf(pos(p).z - arco.z) < 18.0
	if cerca:
		var destino := Vector3(_rng.randf_range(-PALO + 0.4, PALO - 0.4), _rng.randf_range(0.3, 2.0), arco.z)
		_patear(p, destino, 14.0 + float(p["attr"]["tir"]) * 6.0, 0.0, 0.0, "cabezazo")
		tiros[0 if bool(p["es_local"]) else 1] += 1
		_tiro_vivo = {"p": p, "t": t}
	else:
		## Despeje o pase de cabeza: a un compañero de delante si lo hay, bajo.
		var fwd := Vector3(_rng.randf_range(-8, 8), 0, dir_ataque(bool(p["es_local"])) * 14.0)
		var q := _companero_cerca(p, pos(p) + fwd)
		var destino := pos(q) if not q.is_empty() and pos(q).distance_to(pos(p)) < 22.0 else pos(p) + fwd
		_patear(p, destino, 11.0, 0.0, 0.0, "cabezazo")
		if not q.is_empty():
			pase_a = q

## Una entrada: quita el balón, o hace falta.
func _entrada(p: Dictionary, barrida: bool) -> void:
	if poseedor.is_empty():
		return
	var victima := poseedor
	p["enfriar"] = 1.0 if not barrida else 1.6
	var def_ := float(p["attr"]["def"])
	var reg := float(victima["attr"]["reg"])
	if t < float(victima["regate_hasta"]):
		reg += 0.35
	## Defensa contra regate al cuadrado: el buen defensor roba bastante más
	## que el malo (antes la proporción lineal igualaba a todos).
	var exito := def_ * def_ / (def_ * def_ + reg * reg) * (0.55 if barrida else 0.32)
	## La entrada de pie también es cuerpo: el fuerte se impone al débil (y
	## el que tiene equilibrio aguanta). De media no cambia nada.
	if not barrida:
		exito *= clampf(1.0 + (_fuerza(p) - (_fuerza(victima) * 0.6 + float(victima.get("equilibrio", 0.6)) * 0.4)) * 0.7, 0.6, 1.45)
	## Protegiendo el balón (LT) cuesta mucho más quitárselo de pie.
	if bool(victima.get("protege", false)) and not barrida:
		exito *= 0.55
	if p == usuario:
		stats["entradas"] += 1
	var de_lado := absf((pos(victima) - pos(p)).normalized().dot(Vector3(sin((p["node"] as Node3D).rotation.y), 0, cos((p["node"] as Node3D).rotation.y)))) < 0.5
	var gesto_e := "entrada_de_pie"
	if barrida:
		gesto_e = ["barrida_lateral", "barrida_corta", "barrida_rapida", "barrida_larga", "falta_barrida"][_rng.randi() % 5]
	elif de_lado:
		gesto_e = "carga_hombro" if _rng.randf() < 0.5 else "entrada_lateral_pie"
	_anim(p, gesto_e, true)
	var r := _rng.randf()
	if r < exito:
		if p == usuario:
			stats["entradas_ok"] += 1
		poseedor = {}
		ultimo_toque = p
		_offside = {}
		vel_balon = (pos(p) - pos(victima)).normalized() * 3.0 + Vector3(_rng.randf_range(-2, 2), 0, 0)
		victima["enfriar"] = 0.6
	## FALTAS (17-10-2026): había ~4 por partido; una entrada que no llega al
	## balón acaba en falta más a menudo (sobre todo si el defensor es agresivo).
	elif r < exito + (0.28 if barrida else 0.13) + float(p.get("agresividad", 0.5)) * 0.06:
		_falta(p, victima, 0.25, "", "deslizante" if barrida else "de_pie")

# ---------------------------------------------------------------- disputas

func _disputas(delta: float) -> void:
	for p: Dictionary in jugadores:
		p["enfriar"] = maxf(0.0, float(p["enfriar"]) - delta)
	var b := balon.position
	if poseedor.is_empty():
		## Balón suelto: lo controla el más cercano que llegue.
		var mejor: Dictionary = {}
		var md := 99.0
		for p: Dictionary in jugadores:
			if float(p["enfriar"]) > 0.0:
				continue
			var d := Vector2(pos(p).x - b.x, pos(p).z - b.z).length()
			var alcance := 1.6 if bool(p["por"]) and _en_su_area(p, b) else 0.9
			## El que espera el pase va al encuentro del balón y se perfila:
			## llega antes que su marca (sin esto la sonda medía 4 de cada 10
			## pases cortados por el defensor que marcaba a 1,6 m).
			var ventaja := 0.0
			if p == pase_a:
				alcance = 1.25
				ventaja = 0.55
			if d < alcance and b.y < (2.4 if bool(p["por"]) and _en_su_area(p, b) else 1.5) and d - ventaja < md:
				md = d - ventaja
				mejor = p
		if not mejor.is_empty():
			var rapido := vel_balon.length()
			## Un balón muy fuerte se escapa si el control es malo.
			var control: float = float(mejor["attr"]["reg"]) * 0.5 + 0.5
			if bool(mejor["por"]):
				control = float(mejor["attr"]["par"]) * 0.6 + 0.35
			## CORTAR UN PASE TENSO (14-10-2026): el rival que se cruza en la
			## línea de un pase rápido no siempre lo controla: a veces lo
			## desvía y a veces se le cuela entre las piernas.
			var corta := not pase_a.is_empty() and mejor != pase_a and bool(mejor["es_local"]) != bool(pase_a["es_local"])
			if corta and rapido > 8.0 and _rng.randf() > clampf(1.25 - rapido / 15.0, 0.18, 1.0) * control:
				mejor["enfriar"] = 0.35
				if _rng.randf() < 0.45:
					vel_balon = Vector3(vel_balon.x * 0.4 + _rng.randf_range(-3, 3), _rng.randf_range(0.3, 1.5), vel_balon.z * 0.4)
					penultimo_toque = ultimo_toque
					ultimo_toque = mejor
					pase_a = {}
			elif rapido < 14.0 or _rng.randf() < control:
				_tomar(mejor)
			else:
				## Rechace.
				vel_balon = Vector3(-vel_balon.x * 0.3 + _rng.randf_range(-3, 3), 1.5, -vel_balon.z * 0.35)
				penultimo_toque = ultimo_toque
				ultimo_toque = mejor
				mejor["enfriar"] = 0.4
				## Un rechace del rival rompe el fuera de juego (no el de un compañero).
				if not _offside.is_empty() and bool(mejor["es_local"]) != bool(_offside["local"]):
					_offside = {}
		## Cabezazos: balón alto a la altura de la cabeza.
		elif b.y > 1.5 and b.y < 2.4:
			for p: Dictionary in jugadores:
				if float(p["enfriar"]) > 0.0 or bool(p["por"]):
					continue
				if Vector2(pos(p).x - b.x, pos(p).z - b.z).length() < 0.8:
					_cabezazo(p)
					break
		return
	## Con dueño: entradas de los rivales cercanos (la del usuario va aparte).
	## Al portero con el balón en las manos no se le entra.
	if bool(poseedor["por"]):
		return
	## El toque largo: si el balón va suelto por delante y un rival llega
	## antes, se lo lleva sin entrada.
	var lejos_dueno := Vector2(b.x - pos(poseedor).x, b.z - pos(poseedor).z).length()
	if lejos_dueno > 1.4:
		for q: Dictionary in jugadores:
			if bool(q["es_local"]) == bool(poseedor["es_local"]) or float(q["enfriar"]) > 0.0 or (q == usuario and not autopiloto):
				continue
			var dq := Vector2(b.x - pos(q).x, b.z - pos(q).z).length()
			if dq < 0.6 and dq < lejos_dueno * 0.6:
				poseedor["enfriar"] = 0.4
				poseedor = {}
				_tomar(q)
				return
	for p: Dictionary in jugadores:
		if bool(p["es_local"]) == bool(poseedor["es_local"]) or p == usuario and not autopiloto:
			continue
		if float(p["enfriar"]) > 0.0 or bool(p["por"]):
			continue
		if pos(p).distance_to(pos(poseedor)) < 1.25 + 0.12 * float(_tac(bool(p["es_local"]), "presion") - 1):
			_entrada(p, false)
			break

## Dónde conviene recibir el pase que va en camino.
func _punto_de_recepcion() -> Vector3:
	var b := balon.position
	var v := Vector3(vel_balon.x, 0, vel_balon.z)
	var sp := v.length()
	if sp < 1.0:
		return b
	## Dónde para (o por dónde pasa en un segundo).
	var t_para := minf(sp / (ROCE_SUELO * sp + ROCE_FIJO + 0.01), 1.2)
	return Vector3(b.x, 0, b.z) + v * t_para * 0.6

func _aplicar_fase() -> void:
	var fase: Dictionary = (_jugada["fases"] as Array)[int(_jugada["i"])]
	var d := dir_ataque(bool(_jugada["local"]))
	var dest := {}
	var fd: Dictionary = fase.get("destinos", {})
	for rol: String in fd:
		var v: Vector3 = fd[rol]
		## Catálogo: ataque hacia -Z. Para atacar hacia +Z, espejo completo.
		dest[rol] = Vector3(-v.x * d, 0, -v.z * d) if d > 0.0 else v
	_jugada["destinos"] = dest
	_jugada["pase_a"] = String(fase.get("pase_a", ""))

## LAS JUGADAS PREHECHAS COMO GUÍA. Cuando un equipo tiene el balón en campo
## rival, elige una del catálogo y sus fases le dicen a cada puesto adónde
## desmarcarse y a quién conviene pasarla. El catálogo está escrito para un
## ataque hacia -Z; para el que ataca hacia +Z se da la vuelta.
func _guiar_jugada(delta: float) -> void:
	var local := bool(poseedor["es_local"])
	var d := dir_ataque(local)
	var en_campo_rival := balon.position.z * d > -5.0
	if _jugada.is_empty():
		if not en_campo_rival:
			return
		var id: String = CatalogoJugadas.IDS_ATQ[_rng.randi() % CatalogoJugadas.IDS_ATQ.size()]
		var def := CatalogoJugadas.obtener_definicion(id)
		var fases: Array = def.get("fases", [])
		if fases.is_empty():
			return
		_jugada = {"id": id, "local": local, "fases": fases, "i": 0, "t": 0.0}
		_aplicar_fase()
		return
	_jugada["t"] = float(_jugada["t"]) + delta
	var fase: Dictionary = (_jugada["fases"] as Array)[int(_jugada["i"])]
	if float(_jugada["t"]) > float(fase.get("duracion", 1.0)) * 1.8:
		_jugada["i"] = int(_jugada["i"]) + 1
		_jugada["t"] = 0.0
		if int(_jugada["i"]) >= (_jugada["fases"] as Array).size():
			_jugada = {}
			return
		_aplicar_fase()
func prisa() -> float:
	if PRISA_REF <= 0.0 or duracion_mitad <= 0.0:
		return 1.0
	return clampf(PRISA_REF / duracion_mitad, 1.0, 2.0)

## ¿`q` está ahora en posición adelantada respecto de un pase de `p`?
func _adelantado(q: Dictionary, p: Dictionary) -> bool:
	var local := bool(q["es_local"])
	var d := dir_ataque(local)
	var z := pos(q).z * d
	if z <= 0.0 or z <= pos(p).z * d + 0.3:
		return false
	var prof: Array = []
	for r: Dictionary in jugadores:
		if bool(r["es_local"]) != local:
			prof.append(pos(r).z * d)
	if prof.size() < 2:
		return false
	prof.sort()
	return z > float(prof[prof.size() - 2]) + 0.3

## El mejor pase: progresión hacia el arco, compañero libre y línea limpia.
## Bonificaciones: el destinatario que marca la jugada prehecha, y tú si
## pediste el balón.
func _mejor_pase(p: Dictionary) -> Dictionary:
	var yo := pos(p)
	var d := dir_ataque(bool(p["es_local"]))
	var mejor: Dictionary = {}
	var mejor_nota := -99.0
	for q: Dictionary in jugadores:
		if q == p or bool(q["es_local"]) != bool(p["es_local"]) or bool(q["por"]):
			continue
		var qp := pos(q)
		var dist := qp.distance_to(yo)
		if dist < 4.0 or dist > 42.0:
			continue
		var progreso := (qp.z - yo.z) * d
		var libre := 99.0
		var riesgo := 0.0
		for r: Dictionary in jugadores:
			if bool(r["es_local"]) == bool(p["es_local"]):
				continue
			libre = minf(libre, pos(r).distance_to(qp))
			var cerca := Geometry3D.get_closest_point_to_segment(pos(r), yo, qp)
			var dl := cerca.distance_to(pos(r))
			if dl < 2.2:
				riesgo += (2.2 - dl) * 2.4
		var nota := progreso * (CHISPA_AVANCE * pow(prisa(), 0.7) + 0.025 * float(_tac(bool(p["es_local"]), "mentalidad") - 1) + 0.015 * float(_tac(bool(p["es_local"]), "ritmo") - 1)) \
			+ minf(libre, 10.0) * 0.18 - riesgo - dist * 0.02
		## Un buen pasador ve el fuera de juego: con más visión (pase) casi
		## nunca se la da a un compañero adelantado.
		if _adelantado(q, p) and _rng.randf() < 0.55 + float(p["attr"]["pas"]) * 0.4:
			nota -= 6.0
		if not _jugada.is_empty() and String(_jugada.get("pase_a", "")) == _rol(q):
			nota += 1.2
		if q == usuario and t < pedido_hasta:
			nota += 2.5
		## Visión de juego: con poco pase se elige peor (ruido en la nota).
		nota += _rng.randf_range(-1.0, 1.0) * (1.0 - float(p["attr"]["pas"])) * 3.0
		if nota > mejor_nota:
			mejor_nota = nota
			mejor = q
	if not mejor.is_empty():
		mejor["_nota"] = mejor_nota
	return mejor

func _rival_mas_cercano(p: Dictionary) -> Dictionary:
	var mejor: Dictionary = {}
	var md := 999.0
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) != bool(p["es_local"]):
			var d := pos(q).distance_to(pos(p))
			if d < md:
				md = d
				mejor = q
	return mejor

func _presion(p: Dictionary) -> float:
	var r := _rival_mas_cercano(p)
	return pos(r).distance_to(pos(p)) if not r.is_empty() else 99.0

func _linea_tapada(a: Vector3, c: Vector3, local: bool) -> bool:
	for r: Dictionary in jugadores:
		if bool(r["es_local"]) == local:
			continue
		var cerca := Geometry3D.get_closest_point_to_segment(pos(r), a, c)
		if cerca.distance_to(pos(r)) < 1.3:
			return true
	return false

## Cuánto rueda un balón raso que sale a `v0`: con frenado dv/dt = -(k·v + c),
## x = v0/k - c/k²·ln(1 + k·v0/c).
static func distancia_rodando(v0: float) -> float:
	var k := ROCE_SUELO
	var c := ROCE_FIJO
	return v0 / k - c / (k * k) * log(1.0 + k * v0 / c)

## La velocidad para que un pase raso muera `sobra` metros después del
## destino: el compañero lo recibe en carrera sin que se le pase de largo.
static func velocidad_para(dist: float, sobra := 2.5) -> float:
	var lo := 1.0
	var hi := 40.0
	for _i in 24:
		var mid := (lo + hi) * 0.5
		if distancia_rodando(mid) < dist + sobra:
			lo = mid
		else:
			hi = mid
	return hi

## `tenso` (RB): raso y fuerte, para romper líneas.
func _pasar_a(p: Dictionary, q: Dictionary, largo := false, al_hueco := false, tenso := false) -> void:
	var destino := pos(q)
	var dist := destino.distance_to(pos(p))
	## Se le pasa adelantado, a donde va a estar.
	var guia := (q["vel"] as Vector3) * clampf(dist / 18.0, 0.2, 1.0)
	if al_hueco:
		guia += Vector3(0, 0, dir_ataque(bool(q["es_local"])) * 7.0)
	destino += guia
	## Nadie pasa perfecto: el error crece con la distancia, con la presión y
	## cuanto peor es el pase del que la toca.
	var error := ((1.0 - float(p["attr"]["pas"])) * dist * 0.22 + (1.2 if _presion(p) < 2.0 else 0.0) * (1.4 - float(p["attr"]["pas"]))) * _error_extra
	destino += Vector3(_rng.randf_range(-error, error), 0, _rng.randf_range(-error, error))
	## POR ABAJO SIEMPRE QUE SE PUEDA (13-10-2026): con «cualquier rival cerca
	## de la línea = por arriba» la sonda medía el balón en el aire el 64 % del
	## tiempo (pelotazo y cabezazo). Ahora por arriba solo el envío largo o el
	## que está tapado y lejos, y a media altura.
	_ctx_golpeo = "filtrado" if al_hueco else ""
	var tapada := dist > 9.0 and _linea_tapada(pos(p), destino, bool(p["es_local"]))
	var elevado := largo or ((dist > 36.0 or tapada) and not tenso)
	if tenso and not largo:
		_patear(p, destino, clampf(velocidad_para(dist, 9.0 + dist * 1.5) * 1.15, 12.0, 30.0), 0.0, 0.0, "pase")
	elif elevado and largo and al_hueco:
		## Al hueco bombeado: por encima de la línea, cae en el desmarque.
		_patear(p, destino, clampf(dist * 0.42 + 6.0, 10.0, 18.0), 3.2, 0.0, "pase")
	elif elevado:
		## Envío por arriba: el tapado, picado por encima del defensor (bajo);
		## el largo, con más vuelo.
		_patear(p, destino, clampf(dist * 0.45 + 6.0, 10.0, 19.0), 0.25 if (tapada and dist < 25.0) else 2.0, 0.0, "pase")
	else:
		## Con pace: el balón llega al compañero con fuerza, no muriéndose.
		_patear(p, destino, clampf(velocidad_para(dist, 4.0 + dist * 1.5), 7.0, 26.0), 0.0, 0.0, "pase")
	pase_a = q
	_pase_eq = 0 if bool(p["es_local"]) else 1
	pases[_pase_eq] += 1
	if p == usuario:
		stats["pases"] += 1
		_pase_usuario_vivo = true
		_pase_usuario_de = p
