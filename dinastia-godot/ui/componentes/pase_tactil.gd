class_name PaseTactil
extends RefCounted
## EL TOQUE SOBRE UN COMPAÑERO (4-11-2026, mega auditoría 4): dada la posición de un toque en la pantalla, qué compañero del jugador que llevas hay allí (el más cercano dentro de `RADIO_PX` píxeles del lienzo,
## contando la cabeza a 1 m del suelo). `ControlesTactiles` lo usa cuando tocas la zona libre: si hay un compañero, el pase va a él (`MotorPaseDirigido`).
const RADIO_PX := 110.0

static func receptor_en(pj: Node, pos: Vector2) -> Dictionary:
	var motor: Variant = pj.get("motor")
	var cam: Variant = pj.get("_cam")
	if motor == null or cam == null or (motor.usuario as Dictionary).is_empty():
		return {}
	var yo: Dictionary = motor.usuario
	var vp: Variant = pj.get("_vp")
	var c := pj.get_node_or_null("ControlesTactiles") as Control
	var k := 1.0                                   ## del lienzo a los píxeles del viewport 3D
	if vp is SubViewport and c != null and c.size.x > 0.0:
		k = float((vp as SubViewport).size.x) / c.size.x
	var mejor: Dictionary = {}
	var md := RADIO_PX * k
	for q: Dictionary in motor.jugadores:
		if not MotorPaseDirigido.valido(yo, q):
			continue
		var cabeza: Vector3 = motor.pos(q) + Vector3(0, 1.0, 0)
		if (cam as Camera3D).is_position_behind(cabeza):
			continue
		var d := ((cam as Camera3D).unproject_position(cabeza) - pos * k).length()
		if d < md:
			md = d
			mejor = q
	return mejor
