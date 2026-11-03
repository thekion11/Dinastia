class_name MotorSaque
extends RefCounted
## RECEPTOR SEGURO EN LOS SAQUES DE BANDA Y DE CENTRO (03-11-2026, ciclo 11 de la sesión líder: «la calidad de las reanudaciones»). La traza (`MotorTraza`) midió en 16 partidos que
## el saque de banda de la IA se conserva solo el 41 % de las veces, y el de centro (tras gol y al empezar cada parte) otro 41 %: usaban el selector general `_mejor_pase`, que premia el
## avance y acepta riesgo. Con la bandera `SAQUE_SEGURO=1` estos dos saques van al compañero más libre a 4-22 m, con la línea limpia (libre − 1,5·riesgo − 0,08·distancia), y solo si no hay
## candidato vuelven al selector de siempre. Apagado (por defecto): no cambia nada.
const DIST_MIN := 4.0
const DIST_MAX := 22.0
const PESO_RIESGO := 1.5
const PESO_DIST := 0.08
static var _on := OS.get_environment("SAQUE_SEGURO") == "1"

static func receptor(m: MotorJugable, p: Dictionary, tipo: String) -> Dictionary:
	if not _on or not (tipo in ["banda", "centro"]):
		return m._mejor_pase(p)
	var yo := m.pos(p)
	var mejor: Dictionary = {}
	var mejor_nota := -INF
	for q: Dictionary in m.jugadores:
		if q == p or bool(q["es_local"]) != bool(p["es_local"]) or bool(q["por"]):
			continue
		var qp := m.pos(q)
		var dist := qp.distance_to(yo)
		if dist < DIST_MIN or dist > DIST_MAX:
			continue
		var lr := MotorPaseMejora.libre_y_riesgo(m, p, q, yo, qp)
		var nota := minf(float(lr[0]), 10.0) - PESO_RIESGO * float(lr[1]) - PESO_DIST * dist
		if nota > mejor_nota:
			mejor_nota = nota
			mejor = q
	return mejor if not mejor.is_empty() else m._mejor_pase(p)
