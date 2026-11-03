class_name MotorTiroLimpio
extends RefCounted
## TIRO POR PROBABILIDAD DE LÍNEA LIMPIA (03-11-2026, IA F6 de `docs/04_auditorias/terceros_ia_motor_2026-11-01.md`; idea de
## League-Soccer `GetOnTheBallCommands`: tres puntos del arco, `odds^0,5 + azar`, escrita aparte). Antes el tiro apuntaba a un
## palo y a una altura AL AZAR, sin mirar al portero ni a los defensas que tapaban la línea. Ahora se puntúan tres puntos del
## arco (palo izquierdo, centro, palo derecho) por la distancia al portero y por los rivales que cruzan la línea de tiro, y se
## apunta al mejor (con algo de azar). Además las ganas de tirar suben con la línea limpia y bajan si está tapada.
## `SIN_TIRO_LIMPIO=1` = el apunte al azar de antes.
const PUNTOS := [-0.82, 0.0, 0.82]       ## fracción del medio arco útil
const RADIO_BLOQUEO := 1.7                ## un rival a menos de esto de la línea de tiro la tapa
const DIST_PORTERO := 3.6                 ## el portero a más de esto del punto = punto libre
const AZAR := 0.18
static var _sin := OS.has_environment("SIN_TIRO_LIMPIO")

static func _portero_rival(m: MotorJugable, p: Dictionary) -> Dictionary:
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) != bool(p["es_local"]) and bool(q["por"]):
			return q
	return {}

## Probabilidad (0-1) de que el tiro a la fracción `f` del arco no sea tapado ni esté al alcance del portero.
static func limpieza(m: MotorJugable, p: Dictionary, f: float) -> float:
	var arco := m._arco_rival(p)
	var desde := m.pos(p)
	var punto := Vector3(f * (m.PALO - 0.35), 0, arco.z)
	var odds := 1.0
	var por := _portero_rival(m, p)
	if not por.is_empty():
		odds *= clampf(absf(m.pos(por).x - punto.x) / DIST_PORTERO, 0.15, 1.0)
	var seg := Vector2(punto.x - desde.x, punto.z - desde.z)
	var largo := seg.length()
	if largo < 0.5:
		return odds
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) == bool(p["es_local"]) or bool(q["por"]):
			continue
		var v := Vector2(m.pos(q).x - desde.x, m.pos(q).z - desde.z)
		var t := clampf(v.dot(seg) / (largo * largo), 0.0, 1.0)
		if t <= 0.02 or t >= 0.98:
			continue
		var d := (v - seg * t).length()
		if d < RADIO_BLOQUEO:
			odds *= clampf(d / RADIO_BLOQUEO, 0.1, 1.0)
	return odds

## Mejor punto: devuelve [fracción, limpieza]. Con la bandera apagada: [0, -1].
static func mejor(m: MotorJugable, p: Dictionary) -> Array:
	if _sin:
		return [0.0, -1.0]
	var best_f := 0.0
	var best_s := -999.0
	var best_o := 0.0
	for f: float in PUNTOS:
		var o := limpieza(m, p, f)
		var s := sqrt(o) + m._rng.randf() * AZAR
		if s > best_s:
			best_s = s
			best_f = f
			best_o = o
	return [best_f, best_o]

static func activo() -> bool:
	return not _sin

## Factor sobre las ganas de tirar según la línea más limpia (0,7 tapada .. 1,15 limpia).
static func factor_ganas(limpia: float) -> float:
	return lerpf(0.7, 1.15, clampf(limpia, 0.0, 1.0))
