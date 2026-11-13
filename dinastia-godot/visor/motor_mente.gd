class_name MotorMente
extends RefCounted
## LA IMAGEN MENTAL (03-11-2026, IA F8 de `docs/04_auditorias/terceros_ia_motor_2026-11-01.md`; idea de League-Soccer `mentalimage.cpp`,
## escrita aparte). Antes todos los jugadores de la CPU leían la posición EXACTA de los rivales en cada fotograma: la dificultad solo
## tocaba atributos, presión y error. Ahora el motor guarda un historial corto de posiciones (cada 0,1 s, 1,2 s de memoria) y la CPU
## «ve» a los rivales con RETARDO según su nivel (`vista` en `DIFICULTADES`): Practicante 0,5 s, Cadete 0,3 s; de Debutante en
## adelante 0 (el motor calibrado de siempre) y los altos LEEN MEJOR: retardo negativo = ven al rival donde ESTARÁ (posición +
## velocidad × adelanto): Profesional 0,08 s, Experto 0,14, Maestro 0,20, Ultimate 0,30. Así los niveles bajos marcan donde estaba el rival, no donde está. Solo afecta a los
## jugadores de la CPU (nunca al equipo que maneja el usuario). `SIN_MENTE=1` = todos ven el presente.
const CADA := 0.1
const MEMORIA := 1.2
static var _sin := OS.has_environment("SIN_MENTE")

static func _est(m: MotorJugable) -> Dictionary:
	if not m.has_meta("_mente"):
		m.set_meta("_mente", {"h": [], "ult": -99.0, "cache_t": -99.0, "cache_r": -1.0, "cache": {}})
	return m.get_meta("_mente")

## Llamar una vez por fotograma de juego (`paso`).
static func actualizar(m: MotorJugable) -> void:
	if _sin:
		return
	var e := _est(m)
	if m.t - float(e["ult"]) < CADA and m.t >= float(e["ult"]):
		return
	e["ult"] = m.t
	var snap := {}
	for q: Dictionary in m.jugadores:
		snap[String(q["id"])] = m.pos(q)
	var h: Array = e["h"]
	h.append({"t": m.t, "p": snap})
	while h.size() > 1 and m.t - float(h[0]["t"]) > MEMORIA:
		h.pop_front()

## Segundos de retardo con los que el jugador `obs` ve a los rivales (0 = presente; NEGATIVO = se adelanta: ve dónde ESTARÁ).
static func retardo(m: MotorJugable, obs: Dictionary) -> float:
	if _sin or m.equipo_cpu() != (0 if bool(obs["es_local"]) else 1):
		return 0.0
	return float((MotorJugable.DIFICULTADES.get(m.dificultad_cpu, {}) as Dictionary).get("vista", 0.0))

## Dónde ve `obs` al jugador `q` (rival suyo): su posición de hace `retardo` segundos.
static func pos_vista(m: MotorJugable, obs: Dictionary, q: Dictionary) -> Vector3:
	return pos_vista_con(m, q, retardo(m, obs))

## Lo mismo con el retardo ya calculado (`retardo(m, obs)` no cambia dentro de un bucle sobre los rivales del mismo `obs`).
static func pos_vista_con(m: MotorJugable, q: Dictionary, r: float) -> Vector3:
	if r < 0.0:
		var v: Vector3 = q.get("vel", Vector3.ZERO)
		return m.pos(q) + Vector3(v.x, 0.0, v.z) * (-r)
	if r == 0.0:
		return m.pos(q)
	var e := _est(m)
	var h: Array = e["h"]
	if h.is_empty():
		return m.pos(q)
	var obj_t := m.t - r
	var mejor: Dictionary = h[0]
	for s: Dictionary in h:
		if float(s["t"]) <= obj_t:
			mejor = s
		else:
			break
	return (mejor["p"] as Dictionary).get(String(q["id"]), m.pos(q))
