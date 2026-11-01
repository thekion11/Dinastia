class_name MotorControl
extends RefCounted
## EL PRIMER TOQUE QUE SE ESCAPA (01-11-2026, IA U5 de `docs/04_auditorias/terceros_ia_motor_2026-11-01.md`, idea de
## League-Soccer `GetFirstTouchContextPenalty`). Antes todo balón que llegaba a un jugador de campo quedaba controlado a la
## perfección. Ahora el control puede irse largo: más con un rival encima (a menos de `PRESION_M`), con el balón muy rápido
## (y más si llega por la espalda) y con el balón alto; menos con más regate. Tope `TOPE`. Usa el mismo error de dificultad
## y de ánimo que el pase (`_error_extra`, `preset_error`). `SIN_PRIMER_TOQUE=1` = antes.
const PRESION_M := 1.6
const TOPE := 0.25
static var _sin := OS.has_environment("SIN_PRIMER_TOQUE")

## La probabilidad de que el control se le vaya a `p` (sin tirar el dado).
static func riesgo(m: MotorJugable, p: Dictionary) -> float:
	if bool(p["por"]):
		return 0.0
	var v := m.vel_balon
	var rapidez := Vector2(v.x, v.z).length()
	var pen := 0.0
	var dr := m._presion(p)
	if dr < PRESION_M:
		pen += 0.12 * (1.0 - dr / PRESION_M)
	if rapidez > 12.0:
		var n := (p["node"] as Node3D).rotation.y
		var fwd := Vector3(sin(n), 0, cos(n))
		var por_detras := rapidez > 0.1 and fwd.dot(Vector3(v.x, 0, v.z) / rapidez) > 0.3   ## el balón va en el mismo sentido que él mira
		pen += 0.08 * clampf((rapidez - 12.0) / 12.0, 0.0, 1.0) * (2.0 if por_detras else 1.0)
	if m.balon.position.y > 0.9:
		pen += 0.03
	var reg := float((p["attr"] as Dictionary).get("reg", 0.5))
	return clampf(pen * (1.3 - reg) * m._error_extra * m.preset_error, 0.0, TOPE)

## Tira el dado: si el control se va, el balón sale suelto 1,5-3 m por delante y a un lado. true = no lo controló.
static func se_le_va(m: MotorJugable, p: Dictionary) -> bool:
	if _sin:
		return false
	var r := riesgo(m, p)
	if r <= 0.0 or m._rng.randf() >= r:
		return false
	var n := (p["node"] as Node3D).rotation.y
	var fwd := Vector3(sin(n), 0, cos(n))
	var lado := Vector3(fwd.z, 0, -fwd.x) * m._rng.randf_range(-0.8, 0.8)
	m.vel_balon = (fwd + lado).normalized() * m._rng.randf_range(3.5, 6.0) + Vector3(0, m._rng.randf_range(0.0, 1.2), 0)
	m.poseedor = {}
	m.ultimo_toque = p
	p["enfriar"] = 0.35
	m.set_meta("controles_largos", int(m.get_meta("controles_largos", 0)) + 1)
	return true
