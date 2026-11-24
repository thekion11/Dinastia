class_name MejorasC4Despeje
extends RefCounted
## EL DESPEJE DEL RECHACE (17-11-2026, orden de Auditoría tras la sonda de goles de C4: con más paradas subían los goles en los 3 s siguientes, de 0,7 a
## 1,2-1,6 por partido: cada parada regalaba otro tiro). Con `C4_DESPEJE_RECHACE=1`, en los `VENTANA` s que siguen a un rechace del portero
## (`_t_rechace`) o a un tiro (`_tiro_vivo`):
##  - el defensor que se hace con el balón dentro de su área NO lo controla: lo despeja lejos y a la banda (contador `c4_despeje`);
##  - el portero va a por el balón suelto que le queda a menos de `PORTERO_R` m, aunque haya un rival cerca (contador `c4_portero_suelto`).
static var activo := OS.get_environment("C4_DESPEJE_RECHACE") == "1"
const VENTANA := 3.0
const PORTERO_R := 3.0

static func _en_ventana(m: Object) -> bool:
	var tr := float(m.get_meta("_t_rechace", -99.0))
	var t: float = m.t
	if t >= tr and t - tr < VENTANA:
		return true
	var tv: Dictionary = m._tiro_vivo
	return not tv.is_empty() and t - float(tv.get("t", -99.0)) < VENTANA

## El defensor con el balón en su área, justo tras el rechace: lo revienta. true = ya pateó.
static func despejar(m: Object, p: Dictionary, rng: RandomNumberGenerator) -> bool:
	if not activo or bool(p["por"]):
		return false
	var yo: Vector3 = m.pos(p)
	if not m._en_su_area(p, yo) or not _en_ventana(m):
		return false
	var lado := signf(yo.x) if absf(yo.x) > 1.0 else (1.0 if rng.randf() < 0.5 else -1.0)
	var d: float = m.dir_ataque(bool(p["es_local"]))
	var destino := Vector3(lado * rng.randf_range(22.0, 32.0), 0, yo.z + d * rng.randf_range(25.0, 40.0))
	m._patear(p, destino, 24.0, 7.0, 0.0, "patear")
	m._contar("c4_despeje")
	return true

## El portero con el balón suelto a su alcance tras el rechace: va a por él.
static func portero_a_por_el(m: Object, gk: Dictionary, b: Vector3) -> bool:
	if not activo or b.y > 2.0 or not _en_ventana(m):
		return false
	var yo: Vector3 = m.pos(gk)
	if Vector2(b.x - yo.x, b.z - yo.z).length() >= PORTERO_R:
		return false
	m._contar("c4_portero_suelto")
	return true
