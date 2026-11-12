class_name MejorasC4Pared
extends RefCounted
## LA PARED (12-11-2026, sesión 13; objetivo 4 «cadenas de pases» y decisión del líder: paredes y apoyos cerca del área). En C4 no había
## paredes: el portador conducía contra el bloque o soltaba un pase y se quedaba quieto. Con `C4_PARED`:
##   · IDA: a 18-40 m del arco rival, con un compañero libre a 4-12 m (sin rival a < 2,5 m, línea limpia) y espacio por delante del
##     portador, este le da un pase corto y queda «en pared» durante `PARED_T` s;
##   · DESMARQUE: el que la soltó arranca al espacio que tenía delante (8 m hacia el arco, corrido hacia el centro);
##   · VUELTA: el compañero, al recibir, se la devuelve DE PRIMERA al hueco, si el que corre sigue habilitado.
## Contadores: `c4_pared_ida`, `c4_pared_vuelta`, `c4_pared_ok` (el de la ida recibe la vuelta).
static var ACTIVA := OS.get_environment("C4_PARED") == "1"
const PARED_T := 2.5
const IDA_MIN := 4.0
const IDA_MAX := 12.0

static func _estado(m: Object) -> Dictionary:
	var e: Dictionary = m.get_meta("_c4_pared", {})
	if e.is_empty() or float(m.t) - float(e["t"]) > PARED_T:
		return {}
	return e

static func ida(m: Object, p: Dictionary, rng: RandomNumberGenerator) -> bool:
	if not ACTIVA:
		return false
	var local := bool(p["es_local"])
	var yo: Vector3 = m.pos(p)
	var arco: Vector3 = m._arco_rival(p)
	var dist := Vector2(yo.x - arco.x, yo.z - arco.z).length()
	if dist < 18.0 or dist > 40.0:
		return false
	var d: float = m.dir_ataque(local)
	var hueco := yo + Vector3(-signf(yo.x) * 2.0, 0.0, d * 8.0)
	if _rival_cerca(m, hueco, local, 3.0):
		return false   ## sin espacio por delante no hay pared
	var mejor: Dictionary = {}
	var mejor_d := 999.0
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) != local or bool(q["por"]) or String(q["id"]) == String(p["id"]):
			continue
		var qp: Vector3 = m.pos(q)
		var dq := yo.distance_to(qp)
		if dq < IDA_MIN or dq > IDA_MAX or (qp.z - yo.z) * d < -1.5 or _rival_cerca(m, qp, local, 2.5) or m._linea_tapada(yo, qp, local):   ## v2: no hacia atrás
			continue
		if dq < mejor_d:
			mejor = q
			mejor_d = dq
	if mejor.is_empty() or rng.randf() > 0.3 + float(p["attr"]["pas"]) * 0.3:
		return false
	m._pasar_a(p, mejor)
	m.set_meta("_c4_pared", {"a": String(p["id"]), "b": String(mejor["id"]), "t": float(m.t), "hueco": hueco, "vuelta": false})
	m._contar("c4_pared_ida")
	return true

## El que soltó la ida corre al hueco (destino o Vector3.INF).
static func desmarque(m: Object, p: Dictionary) -> Vector3:
	var e := _estado(m)
	if e.is_empty() or String(e["a"]) != String(p["id"]):
		return Vector3.INF
	return e["hueco"]

## El compañero devuelve de primera; o el de la ida recibe la vuelta (cuenta y cierra).
static func vuelta(m: Object, p: Dictionary) -> bool:
	var e := _estado(m)
	if e.is_empty():
		return false
	if bool(e["vuelta"]):
		if String(e["a"]) == String(p["id"]):
			m._contar("c4_pared_ok")
			m.remove_meta("_c4_pared")
		return false
	if String(e["b"]) != String(p["id"]):
		return false
	var a: Dictionary = {}
	for q: Dictionary in m.jugadores:
		if String(q["id"]) == String(e["a"]):
			a = q
	if a.is_empty() or m._adelantado(a, p) or m._linea_tapada(m.pos(p), e["hueco"], bool(p["es_local"])):   ## v2: sin línea limpia al hueco, no hay vuelta
		m.remove_meta("_c4_pared")
		return false
	m._pasar_a(p, a, false, true)
	e["vuelta"] = true
	e["t"] = float(m.t)
	m.set_meta("_c4_pared", e)
	m._contar("c4_pared_vuelta")
	return true

static func _rival_cerca(m: Object, punto: Vector3, local: bool, r: float) -> bool:
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) != local and m.pos(q).distance_to(punto) < r:
			return true
	return false
