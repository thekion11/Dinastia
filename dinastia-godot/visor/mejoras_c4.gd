class_name MejorasC4
extends "res://visor/mejoras_c4_p1.gd"
## (Parte 2 de 2 de `mejoras_c4.gd`.)

static func contener_colocacion(m: Object, p: Dictionary) -> Vector3:
	if not CONTENER2 or bool(p["por"]):
		return Vector3.INF
	var c: Dictionary = m.poseedor
	if c.is_empty() or bool(c["es_local"]) == bool(p["es_local"]):
		return Vector3.INF
	var arco: Vector3 = m._arco_rival(c)
	var pc: Vector3 = m.pos(c)
	if Vector2(pc.x - arco.x, pc.z - arco.z).length() > CONTENER_D:
		return Vector3.INF
	## ¿Es `p` el defensor más cercano y hay cobertura detrás?
	var mi_d := pc.distance_to(m.pos(p))
	var mi_arco := Vector2(m.pos(p).x - arco.x, m.pos(p).z - arco.z).length()
	var cobertura := false
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) != bool(p["es_local"]) or bool(q["por"]) or String(q["id"]) == String(p["id"]):
			continue
		if pc.distance_to(m.pos(q)) < mi_d:
			return Vector3.INF
		if Vector2(m.pos(q).x - arco.x, m.pos(q).z - arco.z).length() < mi_arco - 1.0:
			cobertura = true
	if not cobertura or mi_d > 8.0:
		return Vector3.INF
	var hacia := Vector3(arco.x - pc.x, 0.0, arco.z - pc.z).normalized()
	hacia = (hacia + Vector3(-signf(pc.x) * 0.35, 0.0, 0.0)).normalized()   ## del lado de dentro: lo empuja a la banda
	p["correr"] = mi_d > CONT2_DIST + 2.0
	return Vector3(pc.x, 0.0, pc.z) + hacia * CONT2_DIST

static var SEGUIR_SPRINT := OS.get_environment("C4_SEGUIR_SPRINT") == "1"   ## `=1`: seguir el tiro esprintando siempre (v1); por defecto solo si está a más de 6 m (v2)
