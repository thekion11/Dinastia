class_name MotorLibre
extends RefCounted
## EL PARTIDO QUE SE JUEGA SOLO (prototipo, 26-9-2026). Hoy el partido 3D pone
## en escena jugadas de un catálogo. Este motor es el primer paso para dejar de
## depender de ellas: 22 agentes en un campo de 105 × 68 que cada cuarto de
## segundo miran dónde están, qué tienen cerca y ELIGEN qué hacer. Nada está
## guionizado: el gol sale (o no) de pases, conducciones, regates, entradas y
## tiros cuyas probabilidades dependen de los atributos (`AccionesJuego`).
##
## La IA es de UTILIDAD: el que lleva el balón puntúa cada opción (tirar, pasar
## a cada compañero, conducir, regatear) por lo que gana su equipo si sale y lo
## que arriesga si no, y se queda con la mejor. Los demás se colocan según su
## puesto, el balón y quién lo tiene: el equipo que ataca se abre y sube, el que
## defiende se junta y los dos más cercanos presionan.
##
## Y ya admite un jugador CONTROLADO (`tomar_control`, `mover`, `ordenar`): es
## lo que usará el mando. De momento no se muestra en 3D; `foto()` da las
## posiciones para cuando se enchufe al visor.
##
## Coordenadas: x de -52,5 a 52,5 (el equipo 0 ataca hacia +x), y de -34 a 34.

const LARGO := 105.0
const ANCHO := 68.0
const MEDIO_L := 52.5
const MEDIO_A := 34.0

## 4-4-2 en el sistema "ataco hacia la derecha", en el saque inicial.
const PUESTOS := [
	Vector2(-50, 0),
	Vector2(-35, -24), Vector2(-37, -8), Vector2(-37, 8), Vector2(-35, 24),
	Vector2(-16, -22), Vector2(-18, -7), Vector2(-18, 7), Vector2(-16, 22),
	Vector2(-2, -8), Vector2(-2, 8),
]
const ORDEN_LINEAS := {"POR": 0, "DEF": 1, "MED": 2, "DEL": 3}

var dt := 0.25
var t := 0.0
var agentes: Array = []      ## {j, eq, base, pos, vel_max, sentado_hasta, proxima}
var balon := Vector2.ZERO
var balon_vel := Vector2.ZERO
var poseedor := -1
var _vuelo: Dictionary = {}  ## balón en el aire: {destino, llega, desde}
var goles := [0, 0]
var bono := [1.0, 1.0]
var stats := {"tiros": [0, 0], "pases": [0, 0], "pases_ok": [0, 0], "posesion": [0.0, 0.0],
	"regates": [0, 0], "regates_ok": [0, 0], "entradas_ok": [0, 0], "xg": [0.0, 0.0], "decisiones": {}}
var eventos: Array = []      ## {t, tipo, eq, jugador}
var rng := RandomNumberGenerator.new()

## El jugador que lleva el mando (-1 = la IA juega sola).
var controlado := -1
var _entrada := Vector2.ZERO
var _orden := ""

func _init(once_a: Array, once_b: Array, bono_a: float = 1.0, bono_b: float = 1.0, semilla: int = 0) -> void:
	rng.seed = semilla
	bono = [bono_a, bono_b]
	for eq in 2:
		var once: Array = (once_a if eq == 0 else once_b).duplicate()
		once.sort_custom(func(x: Jugador, y: Jugador) -> bool:
			return int(ORDEN_LINEAS.get(x.pos, 2)) < int(ORDEN_LINEAS.get(y.pos, 2)))
		for i in mini(once.size(), PUESTOS.size()):
			var j: Jugador = once[i]
			var base: Vector2 = PUESTOS[i] * Vector2(_dir(eq), 1.0)
			agentes.append({"j": j, "eq": eq, "base": base, "pos": base, "sentado_hasta": 0.0,
				"proxima": 0.0, "entrada_hasta": 0.0, "objetivo": base,
				"vel_max": 4.6 + AccionesJuego.atributo(j, "rit") / 100.0 * 3.6})
	_saque(0)

static func _dir(eq: int) -> float:
	return 1.0 if eq == 0 else -1.0

func _porteria_rival(eq: int) -> Vector2:
	return Vector2(MEDIO_L * _dir(eq), 0.0)

# ---------------------------------------------------------------------------
#  API
# ---------------------------------------------------------------------------

func simular(minutos: float = 90.0) -> Dictionary:
	while t < minutos * 60.0:
		paso()
	return resultado()

func resultado() -> Dictionary:
	var pos_tot: float = stats["posesion"][0] + stats["posesion"][1]
	return {"goles": goles.duplicate(), "tiros": stats["tiros"].duplicate(),
		"pases": stats["pases"].duplicate(), "pases_ok": stats["pases_ok"].duplicate(),
		"posesion": [roundf(100.0 * stats["posesion"][0] / maxf(1.0, pos_tot)), roundf(100.0 * stats["posesion"][1] / maxf(1.0, pos_tot))],
		"regates": stats["regates"].duplicate(), "regates_ok": stats["regates_ok"].duplicate(),
		"entradas_ok": stats["entradas_ok"].duplicate(), "xg": stats["xg"].duplicate(), "decisiones": stats["decisiones"].duplicate()}

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

func _mover_vuelo() -> void:
	var desde: Vector2 = _vuelo["desde"]
	var destino: int = _vuelo["destino"]
	var fin: Vector2 = agentes[destino]["pos"]
	var k := clampf((t - float(_vuelo["sale"])) / maxf(0.01, float(_vuelo["llega"]) - float(_vuelo["sale"])), 0.0, 1.0)
	balon = desde.lerp(fin, k)
	if k >= 1.0:
		_vuelo.clear()
		_dar_balon(destino)

func _balon_suelto() -> void:
	balon += balon_vel * dt
	balon_vel *= 0.8
	balon.x = clampf(balon.x, -MEDIO_L + 0.5, MEDIO_L - 0.5)
	balon.y = clampf(balon.y, -MEDIO_A + 0.5, MEDIO_A - 0.5)
	## El más cercano (no el primero de la lista: eso favorecía al equipo 0).
	var mejor := -1
	var md := 1.5
	for i in agentes.size():
		var d: float = (agentes[i]["pos"] as Vector2).distance_to(balon)
		if d < md and t >= float(agentes[i]["sentado_hasta"]):
			md = d
			mejor = i
	if mejor >= 0:
		_dar_balon(mejor)

func _dar_balon(i: int) -> void:
	poseedor = i
	balon_vel = Vector2.ZERO
	## Recibir no es instantáneo: un momento para controlar y levantar la cabeza.
	agentes[i]["proxima"] = t + rng.randf_range(0.8, 1.8)

## Balón para el portero de `eq` (atajada o saque de puerta).
func _al_portero(eq: int) -> void:
	for i in agentes.size():
		if agentes[i]["eq"] == eq and (agentes[i]["j"] as Jugador).pos == "POR":
			agentes[i]["pos"] = Vector2(-48.0 * _dir(eq), 0.0)
			balon = agentes[i]["pos"]
			_dar_balon(i)
			agentes[i]["proxima"] = t + 2.0
			return
	_saque(eq)

## Todos a su sitio y saca `eq` desde el centro.
func _saque(eq: int) -> void:
	_vuelo.clear()
	for a: Dictionary in agentes:
		a["pos"] = a["base"]
		a["objetivo"] = a["pos"]
	var mejor := -1
	for i in agentes.size():
		if agentes[i]["eq"] == eq and (mejor < 0 or absf((agentes[i]["pos"] as Vector2).x) < absf((agentes[mejor]["pos"] as Vector2).x)):
			mejor = i
	agentes[mejor]["pos"] = Vector2.ZERO
	balon = Vector2.ZERO
	_dar_balon(mejor)

# ---------------------------------------------------------------------------
#  LA IA DE UTILIDAD
# ---------------------------------------------------------------------------

## Lo que vale tener el balón en `p` para el equipo `eq`: casi nada en campo
## propio, mucho cerca del área rival.
func _valor(p: Vector2, eq: int) -> float:
	var d := p.distance_to(_porteria_rival(eq))
	return 0.005 + 0.25 * exp(-d / 12.0)

func _rival_mas_cerca(p: Vector2, eq: int) -> int:
	var mejor := -1
	var md := INF
	for i in agentes.size():
		if agentes[i]["eq"] != eq and t >= float(agentes[i]["sentado_hasta"]):
			var d: float = (agentes[i]["pos"] as Vector2).distance_squared_to(p)
			if d < md:
				md = d
				mejor = i
	return mejor

func _presion(p: Vector2, eq: int) -> float:
	var r := _rival_mas_cerca(p, eq)
	if r < 0:
		return 0.0
	return clampf(1.0 - (agentes[r]["pos"] as Vector2).distance_to(p) / 4.0, 0.0, 1.0)

## Cuánto espacio hay en la línea de pase: la distancia del rival más cercano
## al segmento (y al receptor).
func _hueco(desde: Vector2, hasta: Vector2, eq: int) -> float:
	var md := INF
	for a: Dictionary in agentes:
		if a["eq"] != eq:
			var q: Vector2 = a["pos"]
			md = minf(md, q.distance_to(Geometry2D.get_closest_point_to_segment(q, desde, hasta)))
	return md

func _portero(eq: int) -> Jugador:
	for a: Dictionary in agentes:
		if a["eq"] == eq and (a["j"] as Jugador).pos == "POR":
			return a["j"]
	return null

## Las opciones de quien lleva el balón, puntuadas. [utilidad, tipo, dato]
func _opciones(i: int) -> Array:
	var a: Dictionary = agentes[i]
	var j: Jugador = a["j"]
	var eq: int = a["eq"]
	var p: Vector2 = a["pos"]
	var pres := _presion(p, eq)
	var ops: Array = []
	var aqui := _valor(p, eq)
	## TIRAR
	var meta := _porteria_rival(eq)
	var dg := p.distance_to(meta)
	if dg < 30.0:
		var acc := "tiro" if dg < 20.0 else "tiro_lejano"
		var pe := AccionesJuego.prob_exito(j, acc, {"dist": dg, "presion": pres, "bono": bono[eq]})
		var rel := (p - meta) * Vector2(-_dir(eq), 1.0)
		var pg := AccionesJuego.xg(Vector2(absf(rel.x), rel.y)) * (0.3 + 0.7 * pe) * _factor_portero(1 - eq) * (1.0 - 0.5 * pres)
		## Tirar es perder el balón si no entra: se descuenta lo que valía tenerlo.
		ops.append([pg - aqui * 0.3 - 0.004, acc, i])
	## PASAR a cada compañero
	for k in agentes.size():
		if k == i or agentes[k]["eq"] != eq:
			continue
		var q: Vector2 = agentes[k]["pos"]
		var d := p.distance_to(q)
		if d < 4.0 or d > 55.0:
			continue
		var tipo := "pase_corto" if d < 24.0 else "pase_largo"
		var hueco := _hueco(p, q, eq)
		var pe := AccionesJuego.prob_exito(j, tipo, {"dist": d, "presion": pres, "bono": bono[eq]})
		pe *= clampf(0.65 + hueco / 8.0, 0.25, 1.0)
		## Ganar metros tiene premio: sin él la IA se pasaba el balón en
		## horizontal los 90 minutos.
		var avance := (q.x - p.x) * _dir(eq)
		var u := pe * (_valor(q, eq) + 0.0015 * avance) - (1.0 - pe) * (aqui * 0.6 + 0.02)
		ops.append([u, tipo, k])
	## CONDUCIR hacia delante (y un poco hacia el centro)
	var adelante := p + Vector2(7.0 * _dir(eq), -p.y * 0.15)
	var espacio := _hueco(p, adelante, eq)
	var pc := clampf(espacio / 5.0, 0.2, 1.0) * AccionesJuego.prob_exito(j, "conducir", {"presion": pres, "bono": bono[eq]})
	ops.append([pc * (_valor(adelante, eq) + 0.0015 * 7.0) - (1.0 - pc) * aqui * 0.6, "conducir", adelante])
	## REGATEAR al que tiene encima
	var r := _rival_mas_cerca(p, eq)
	if r >= 0 and (agentes[r]["pos"] as Vector2).distance_to(p) < 3.5:
		var rival := AccionesJuego.calidad(agentes[r]["j"], "entrada")
		var pr := AccionesJuego.prob_exito(j, "regate", {"rival": rival, "bono": bono[eq]})
		var pasado := p + Vector2(6.0 * _dir(eq), 0.0)
		ops.append([pr * _valor(pasado, eq) - (1.0 - pr) * (aqui + 0.03), "regate", r])
	return ops

func _factor_portero(eq: int) -> float:
	var por := _portero(eq)
	if por == null:
		return 1.3
	return clampf(1.4 - AccionesJuego.calidad(por, "atajar") / 110.0, 0.5, 1.2)

func _decidir(i: int) -> void:
	var ops := _opciones(i)
	var mejor: Array = []
	var mu := -INF
	for o: Array in ops:
		## Un poco de ruido: nadie decide siempre lo mismo en la misma jugada.
		var u: float = float(o[0]) + rng.randf_range(-0.012, 0.012)
		if u > mu:
			mu = u
			mejor = o
	if mejor.is_empty():
		return
	_ejecutar(i, String(mejor[1]), mejor[2])

## El jugador controlado: el stick elige a quién/hacia dónde y el botón qué.
func _decidir_controlado() -> void:
	if _orden == "":
		return
	var accion := _orden
	_orden = ""
	var ops := _opciones(controlado)
	var dir := _entrada if _entrada.length() > 0.2 else Vector2(_dir(agentes[controlado]["eq"]), 0.0)
	var p: Vector2 = agentes[controlado]["pos"]
	var mejor: Array = []
	var mu := -INF
	for o: Array in ops:
		var tipo := String(o[1])
		if accion.begins_with("pase") and tipo.begins_with("pase"):
			var q: Vector2 = agentes[int(o[2])]["pos"]
			var enc := dir.normalized().dot((q - p).normalized())
			if enc > mu:
				mu = enc
				mejor = [o[0], "pase_largo" if accion == "pase_largo" else tipo, o[2]]
		elif accion.begins_with("tiro") and tipo.begins_with("tiro"):
			mejor = o
			break
		elif accion == "regate" and tipo == "regate":
			mejor = o
			break
	if not mejor.is_empty():
		_ejecutar(controlado, String(mejor[1]), mejor[2])

func _ejecutar(i: int, tipo: String, dato: Variant) -> void:
	var a: Dictionary = agentes[i]
	var j: Jugador = a["j"]
	var eq: int = a["eq"]
	var p: Vector2 = a["pos"]
	var pres := _presion(p, eq)
	var dec: Dictionary = stats["decisiones"]
	dec[tipo] = int(dec.get(tipo, 0)) + 1
	a["proxima"] = t + rng.randf_range(1.0, 2.2)
	match tipo:
		"tiro", "tiro_lejano":
			stats["tiros"][eq] += 1
			var meta := _porteria_rival(eq)
			var pe := AccionesJuego.prob_exito(j, tipo, {"dist": p.distance_to(meta), "presion": pres,
				"pie_malo": AccionesJuego.usa_pie_malo(j, p.y * _dir(eq) < 0.0, rng), "bono": bono[eq]})
			var rel := (p - meta) * Vector2(-_dir(eq), 1.0)
			var pg := AccionesJuego.xg(Vector2(absf(rel.x), rel.y)) * (0.3 + 0.7 * pe) * _factor_portero(1 - eq) * (1.0 - 0.5 * pres)
			stats["xg"][eq] += pg
			if rng.randf() < pg:
				goles[eq] += 1
				eventos.append({"t": t, "tipo": "gol", "eq": eq, "jugador": j.id, "dist": p.distance_to(meta), "xg": pg})
				_saque(1 - eq)
			else:
				eventos.append({"t": t, "tipo": "tiro", "eq": eq, "jugador": j.id, "dist": p.distance_to(meta), "xg": pg})
				_al_portero(1 - eq)
		"pase_corto", "pase_largo":
			stats["pases"][eq] += 1
			var k: int = dato
			var q: Vector2 = agentes[k]["pos"]
			var d := p.distance_to(q)
			var pe := AccionesJuego.prob_exito(j, tipo, {"dist": d, "presion": pres,
				"pie_malo": AccionesJuego.usa_pie_malo(j, (q - p).y * _dir(eq) < 0.0, rng), "bono": bono[eq]})
			pe *= clampf(0.65 + _hueco(p, q, eq) / 8.0, 0.25, 1.0)
			if rng.randf() < pe:
				stats["pases_ok"][eq] += 1
				poseedor = -1
				_vuelo = {"destino": k, "desde": p, "sale": t, "llega": t + d / (16.0 if tipo == "pase_corto" else 22.0)}
			else:
				## Cortado o largo: el balón queda muerto a medio camino.
				poseedor = -1
				balon = p.lerp(q, rng.randf_range(0.4, 0.9)) + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3))
				balon_vel = Vector2.ZERO
		"conducir":
			a["objetivo"] = dato
		"regate":
			stats["regates"][eq] += 1
			var r: int = dato
			var rival := AccionesJuego.calidad(agentes[r]["j"], "entrada")
			if rng.randf() < AccionesJuego.prob_exito(j, "regate", {"rival": rival, "bono": bono[eq]}):
				stats["regates_ok"][eq] += 1
				agentes[r]["sentado_hasta"] = t + 1.2
				a["pos"] = p + Vector2(2.5 * _dir(eq), rng.randf_range(-1.5, 1.5))
				a["objetivo"] = p + Vector2(9.0 * _dir(eq), 0.0)
			else:
				_dar_balon(r)
				stats["entradas_ok"][1 - eq] += 1

## Los rivales pegados al que lleva el balón intentan quitárselo, cada uno una
## vez por segundo como mucho.
func _disputa() -> void:
	var c: Dictionary = agentes[poseedor]
	var eq: int = c["eq"]
	for i in agentes.size():
		var a: Dictionary = agentes[i]
		if a["eq"] == eq or t < float(a["sentado_hasta"]) or t < float(a["entrada_hasta"]):
			continue
		if (a["pos"] as Vector2).distance_to(c["pos"]) > 1.6:
			continue
		a["entrada_hasta"] = t + 2.5
		var prot: float = AccionesJuego.calidad(c["j"], "proteger") + (float(bono[eq]) - 1.0) * 30.0
		var pe := AccionesJuego.prob_exito(a["j"], "entrada", {"rival": prot, "bono": bono[1 - eq]}) * 0.4
		if rng.randf() < pe:
			stats["entradas_ok"][1 - eq] += 1
			_dar_balon(i)
			return
		a["sentado_hasta"] = t + 0.5

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

## A quién marca `i` (se recalcula cada segundo, no cada paso): el rival más
## cercano a su zona si está a menos de 12 m de ella.
func _marca_de(i: int, zona: Vector2) -> int:
	var a: Dictionary = agentes[i]
	if t < float(a.get("marca_hasta", 0.0)):
		return int(a.get("marca", -1))
	var mejor := -1
	var md := 144.0
	for k in agentes.size():
		if agentes[k]["eq"] != a["eq"] and k != poseedor:
			var d: float = (agentes[k]["pos"] as Vector2).distance_squared_to(zona)
			if d < md:
				md = d
				mejor = k
	a["marca"] = mejor
	a["marca_hasta"] = t + 1.0
	return mejor

## Dónde tiene que estar un jugador sin balón: su puesto, desplazado con el
## balón; más arriba y más abierto si su equipo ataca, más junto si defiende.
func _sitio(a: Dictionary, ataca: bool) -> Vector2:
	var eq: int = a["eq"]
	var d := _dir(eq)
	var b: Vector2 = a["base"]
	var j: Jugador = a["j"]
	if j.pos == "POR":
		return Vector2(-49.0 * d, clampf(balon.y * 0.15, -3.0, 3.0))
	## Todo en el sistema "ataco hacia la derecha".
	var bx := b.x * d
	var balx := balon.x * d
	var x: float
	var y: float
	if ataca:
		x = bx * 0.55 + balx * 0.55 + 14.0
		y = b.y * 1.15 + balon.y * 0.15
	else:
		x = bx * 0.6 + balx * 0.45 - 2.0
		y = b.y * 0.8 + balon.y * 0.3
	## La última línea no pasa del medio campo rival ni se mete en su área.
	x = clampf(x, -46.0, 44.0 if j.pos == "DEL" else 30.0)
	return Vector2(x * d, clampf(y, -MEDIO_A + 1.0, MEDIO_A - 1.0))
