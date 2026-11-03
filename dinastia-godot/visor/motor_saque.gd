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

## LOS COMPAÑEROS SE OFRECEN EN EL SAQUE DE BANDA (ciclo 11, bandera `SAQUE_OFRECE=1`). Antes, mientras el lanzador sacaba, todos iban a su puesto normal (`_forma`) y nadie se ofrecía cerca.
## Ahora los DOS compañeros más cercanos al lanzador (sin porteros) se ofrecen hacia dentro del campo: el primero corto y algo adelantado (5 m al interior, 4 m hacia el arco rival) y el segundo
## en diagonal (9 m al interior, 3 m atrás). Los demás y el equipo que no saca siguen con `base`. Apagado: devuelve `base`.
const OFERTA_A := Vector3(5.0, 0.0, 4.0)
const OFERTA_B := Vector3(9.0, 0.0, -3.0)
static var _ofrece := OS.get_environment("SAQUE_OFRECE") == "1"

static func oferta(m: MotorJugable, p: Dictionary, lugar: Vector3, saca_local: bool, base: Vector3) -> Vector3:
	if not _ofrece or bool(p["es_local"]) != saca_local or bool(p["por"]):
		return base
	var lanzador: Dictionary = (m.saque as Dictionary).get("lanzador", {})
	var cercanos: Array = []
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) == saca_local and not bool(q["por"]) and q != lanzador:
			cercanos.append(q)
	cercanos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var da := m.pos(a).distance_to(lugar)
		var db := m.pos(b).distance_to(lugar)
		return da < db if absf(da - db) > 0.01 else String(a["id"]) < String(b["id"]))
	var rango := cercanos.find(p)
	if rango != 0 and rango != 1:
		return base
	var dentro := -signf(lugar.x) if absf(lugar.x) > 0.01 else 1.0
	var dz := m.dir_ataque(saca_local)
	var o := OFERTA_A if rango == 0 else OFERTA_B
	var obj := Vector3(lugar.x + dentro * o.x, 0.0, lugar.z + dz * o.z)
	return Vector3(clampf(obj.x, -m.ANCHO + 1.0, m.ANCHO - 1.0), 0.0, clampf(obj.z, -m.LARGO + 1.0, m.LARGO - 1.0))
