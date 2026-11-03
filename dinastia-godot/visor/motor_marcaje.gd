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
static var _sin := OS.has_environment("SIN_MARCAJE")

static func _peligro(m: MotorJugable, q: Dictionary, arco: Vector3, dir_gol: float) -> float:
	var pq := m.pos(q)
	var d_arco := pq.distance_to(arco)
	if d_arco > ZONA_PELIGRO:
		return -1.0
	var s := 1.0 - d_arco / ZONA_PELIGRO                                   ## cerca del arco
	s += (1.0 - clampf(pq.distance_to(m.balon.position) / 35.0, 0.0, 1.0)) * 0.6   ## a distancia de recibir
	var v := q["vel"] as Vector3
	s += clampf(v.z * dir_gol / 6.0, 0.0, 1.0) * 0.4                        ## lanzado hacia el gol
	return s

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
