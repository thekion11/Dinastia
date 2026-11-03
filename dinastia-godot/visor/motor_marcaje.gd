class_name MotorMarcaje
extends RefCounted
## MARCAJE A LOS 3 RIVALES MÁS PELIGROSOS (03-11-2026, IA F4 de `docs/04_auditorias/terceros_ia_motor_2026-11-01.md`; idea de
## League-Soccer `CalculateManMarking`, escrita aparte). Antes cada defensa marcaba al rival más cercano a su zona: dos podían
## pegarse al mismo y el delantero libre quedaba solo. Ahora, cada 0,5 s, se puntúa a los rivales de campo por PELIGRO (cerca de
## nuestro arco, a distancia de recibir el balón, lanzado hacia el gol) y se asigna a los 3 primeros UN marcador cada uno: el
## defensor libre más cercano (no el que presiona ni el segundo). El reparto es estable (no cambia si el marcador sigue a < 28 m
## y el rival sigue entre los 5 más peligrosos). Los marcadores se ponen entre el rival y el arco, a 1,8 m.
## `SIN_MARCAJE=1` = marca al más cercano de la zona, como antes.
const MAX_MARCAS := 3
const RADIO_MARCADOR := 28.0      ## el marcador no se va tan lejos de su sitio
const ZONA_PELIGRO := 40.0        ## los rivales a más de esto de nuestro arco no se marcan al hombre
const REVISION := 0.5
const CERCA_BALON := 9.0          ## los rivales a menos de esto del balón los cubre la presión
static var _sin := OS.has_environment("SIN_MARCAJE")

static func _peligro(m: MotorJugable, q: Dictionary, arco: Vector3, dir_gol: float) -> float:
	var pq := m.pos(q)
	var d_arco := pq.distance_to(arco)
	if d_arco > ZONA_PELIGRO:
		return -1.0
	## Los pegados al balón (< CERCA_BALON m) ya los cubren el que presiona y el segundo, salvo que estén en plena área.
	var d_balon := pq.distance_to(m.balon.position)
	if d_balon < CERCA_BALON and d_arco > 20.0:
		return -1.0
	var s := 1.0 - d_arco / ZONA_PELIGRO                                         ## cerca del arco
	if (m.balon.position.z - pq.z) * dir_gol < 0.0:                               ## por delante del balón, hacia nuestro arco
		s += 0.5
	s += (1.0 - clampf(d_balon / 35.0, 0.0, 1.0)) * 0.25                          ## a distancia de recibir (peso bajo)
	var v := q["vel"] as Vector3
	s += clampf(v.z * dir_gol / 6.0, 0.0, 1.0) * 0.4                              ## lanzado hacia el gol
	return s

## Dónde se pone `p` si le toca marcar a un peligroso (INF si no): del lado del arco; cerca de su área, mezclado con tapar la línea de pase.
static func objetivo(m: MotorJugable, p: Dictionary, arco: Vector3) -> Vector3:
	var marcado := rival_de(m, p)
	if marcado.is_empty():
		return Vector3.INF
	var pm := MotorMente.pos_vista(m, p, marcado)
	p["correr"] = m.pos(p).distance_to(pm) > 6.0
	var om := pm + (arco - pm).normalized() * 1.8
	if m.balon.position.distance_to(arco) < 32.0:
		var carril := pm + (m.balon.position - pm).normalized() * 1.6
		om = om.lerp(carril, 0.5)
	om.z = clampf(om.z, -m.LARGO + 2.0, m.LARGO - 2.0)
	## La defensa mantiene la LÍNEA COMÚN en profundidad (M-123) y solo sigue al rival en el ancho: sin esto, los marcadores rompían la línea
	## y los delanteros quedaban solos (medido: +30 % de goles en 16 partidos).
	if m._rol(p) in ["DFC", "LD", "LI"] and not m._SIN_LINEA:
		om.z = m._linea_defensiva(bool(p["es_local"]))
	return om

## Reparto vigente {id_del_rival: id_del_marcador} del equipo `local` cuando defiende.
static func reparto(m: MotorJugable, local: bool) -> Dictionary:
	if _sin:
		return {}
	var k := "_marcaje_%s" % ("l" if local else "v")
	var e: Dictionary = m.get_meta(k, {"t": -99.0, "mapa": {}})
	if m.t - float(e["t"]) < REVISION:
		return e["mapa"]
	var arco := m._arco_propio({"es_local": local})
	var dir_gol := m.dir_ataque(not local)   ## hacia donde atacan los rivales (nuestro arco)
	var rivales: Array = []
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) != local and not bool(q["por"]) and q != m.poseedor:
			var s := _peligro(m, q, arco, dir_gol)
			if s >= 0.0:
				rivales.append([s, q])
	rivales.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var pp := MotorPresion.papeles(m, local)
	var libres: Array = m.jugadores.filter(func(p: Dictionary) -> bool:
		return bool(p["es_local"]) == local and not bool(p["por"]) and String(p["id"]) != String(pp[0]) and String(p["id"]) != String(pp[1]) and p != m.usuario)
	var previo: Dictionary = e["mapa"]
	var mapa := {}
	var usados := {}
	for i in mini(5, rivales.size()):
		if mapa.size() >= MAX_MARCAS:
			break
		var q: Dictionary = rivales[i][1]
		var qid := String(q["id"])
		## Estabilidad: si ya tenía marcador y sigue cerca, se queda.
		var mid := String(previo.get(qid, ""))
		if mid != "" and not usados.has(mid):
			for p: Dictionary in libres:
				if String(p["id"]) == mid and m.pos(p).distance_to(m.pos(q)) < RADIO_MARCADOR:
					mapa[qid] = mid
					usados[mid] = true
					break
		if mapa.has(qid):
			continue
		var mejor: Dictionary = {}
		var md := RADIO_MARCADOR
		for p: Dictionary in libres:
			if usados.has(String(p["id"])):
				continue
			var d := m.pos(p).distance_to(m.pos(q))
			if d < md:
				md = d
				mejor = p
		if not mejor.is_empty():
			mapa[qid] = String(mejor["id"])
			usados[String(mejor["id"])] = true
	m.set_meta(k, {"t": m.t, "mapa": mapa})
	return mapa

## El rival que `p` debe marcar al hombre ({} si ninguno).
static func rival_de(m: MotorJugable, p: Dictionary) -> Dictionary:
	if _sin:
		return {}
	var yo := String(p["id"])
	var mapa := reparto(m, bool(p["es_local"]))
	for qid: String in mapa:
		if String(mapa[qid]) == yo:
			for q: Dictionary in m.jugadores:
				if String(q["id"]) == qid:
					return q
	return {}
