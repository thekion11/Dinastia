class_name MotorPresion
extends RefCounted
## PRESIONADORES ESTABLES (01-11-2026, IA R3 de `docs/04_auditorias/terceros_ia_motor_2026-11-01.md`, idea de League-Soccer
## `ShouldKeepPressurePlayer`). Antes el primero y el segundo en presionar salían de ordenar por distancia al balón en cada
## fotograma: con dos a la misma distancia, los papeles parpadeaban y los dos frenaban y arrancaban. Ahora se eligen una vez por
## paso y por equipo, y el que ya tiene el papel lo conserva salvo que otro esté `CAMBIO` m mejor. Para el segundo, un central
## cuenta `CASTIGO_CENTRAL` m de más: que salga un medio y el central guarde su sitio.
const CAMBIO := 1.5
static var CASTIGO_CENTRAL := float(OS.get_environment("PRES_CASTIGO")) if OS.get_environment("PRES_CASTIGO") != "" else 3.0
static var _sin := OS.has_environment("SIN_PRESION_ESTABLE")   ## vuelve a lo de antes (para medir)

## [id del primero, id del segundo] del equipo (local o visitante); "" si no hay.
static func papeles(m: MotorJugable, local: bool) -> Array:
	var clave := Vector2(m.t, m._t_estado)
	var cache: Dictionary = m.get_meta("presion", {})
	if cache.get("clave", Vector2(-1, -1)) == clave and cache.has(local):
		return cache[local]
	if cache.get("clave", Vector2(-1, -1)) != clave:
		cache = {"clave": clave}
	var antes: Array = (m.get_meta("presion_antes", {}) as Dictionary).get(local, ["", ""])
	var b := m.balon.position
	var dist := {}
	var roles := {}
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) == local and not bool(q["por"]) and not (q == m.usuario and not m.autopiloto):
			dist[String(q.get("id", ""))] = m.pos(q).distance_to(b)
			roles[String(q.get("id", ""))] = m._rol(q)
	var primero := _elegir(dist, String(antes[0]), "", {})
	var segundo := _elegir(dist, String(antes[1]), primero, roles)
	var r := [primero, segundo]
	cache[local] = r
	m.set_meta("presion", cache)
	var guardado: Dictionary = m.get_meta("presion_antes", {})
	guardado[local] = r
	m.set_meta("presion_antes", guardado)
	return r

## El de menor nota (distancia, + castigo si es central y hay `roles`); el que ya lo era sigue salvo que otro le saque `CAMBIO` m.
static func _elegir(dist: Dictionary, previo: String, fuera: String, roles: Dictionary) -> String:
	var mejor := ""
	var nm := INF
	for id: String in dist:
		if id == fuera:
			continue
		var n := _nota(dist, roles, id)
		if n < nm:
			nm = n
			mejor = id
	if not _sin and previo != "" and previo != fuera and dist.has(previo) and _nota(dist, roles, previo) - nm < CAMBIO:
		return previo
	return mejor

static func _nota(dist: Dictionary, roles: Dictionary, id: String) -> float:
	return float(dist[id]) + (CASTIGO_CENTRAL if not _sin and String(roles.get(id, "")) == "DFC" else 0.0)
