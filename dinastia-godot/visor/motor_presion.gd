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

## PRESIÓN POR ZONA (01-11-2026, IA U1, idea de League-Soccer `ShouldStartZonePressure`): un gatillo más de `_gatillo_presion`.
## El equipo que defiende sale a morder si el balón ya está adentrado en el campo rival (territorio > 0,55 − 0,9·presión, con la
## presión 0/1/2 pasada a 0/0,5/1) y tiene a alguien a menos de 5 + 8·presión m del portador; una vez empieza, aguanta
## `ZONA_DURA` + 2·presión s aunque el portador salga de la zona. Medido con `SIN_ZONA=1` (= antes).
const ZONA_DURA := 2.0
static var _sin_zona := OS.has_environment("SIN_ZONA")

static func zona(m: MotorJugable, dueno: Dictionary) -> bool:
	if _sin_zona:
		return false
	var defiende_local := not bool(dueno["es_local"])
	var pr := float(m._tac(defiende_local, "presion")) * 0.5
	var hasta: Dictionary = m.get_meta("zona_hasta", {})
	if m.t < float(hasta.get(defiende_local, -1.0)):
		return true
	## Territorio desde el arco propio del que defiende: 0 en su arco, 1 en el del portador.
	var terr := 0.5 + m.pos(dueno).z * m.dir_ataque(defiende_local) / (2.0 * m.LARGO)
	if terr <= 0.55 - 0.9 * pr or m._presion(dueno) > 5.0 + 8.0 * pr:
		return false
	hasta[defiende_local] = m.t + ZONA_DURA + 2.0 * pr
	m.set_meta("zona_hasta", hasta)
	return true

## LÍNEA DE FUERA DE JUEGO PREVISTA (01-11-2026, IA U3, idea de League-Soccer `AI_GetOffsideLine(futureSim_ms=240)`): para los
## DESMARQUES (`_ultima_linea`: `_companero_al_hueco` y el ataque sin balón) la última línea rival se mira donde estará dentro
## de 0,24 s, no donde está: el delantero se adelanta a la defensa que sube y no se queda en fuera de juego. El fuera de juego
## que pita el árbitro (`_foto_offside`) no cambia. `SIN_LINEA_PREVISTA=1` = antes.
static var PREVE_LINEA := 0.0 if OS.has_environment("SIN_LINEA_PREVISTA") else 0.24
