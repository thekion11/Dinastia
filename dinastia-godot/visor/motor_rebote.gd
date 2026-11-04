class_name MotorRebote
extends RefCounted
## LLEGADA AL REBOTE Y AL SEGUNDO PALO (03-11-2026, ciclo 28 de la sesión líder). Con un centro, un tiro o un rechace del portero en el aire (el balón no tiene dueño y el último toque fue del equipo que
## ataca), solo el más cercano al balón lo perseguía: los demás se quedaban en su forma, y el 85 % de los tiros se hacía sin NINGÚN compañero a < 18 m del arco. Con `REBOTE_LLEGADA=1` los dos atacantes más cercanos al
## balón después del que lo persigue se meten al área: uno al segundo palo (lado contrario al balón) y otro al punto de penal. `REBOTE_LLEGADA=0` (por defecto) = como antes. No sortea números aleatorios.
static var ON := OS.get_environment("REBOTE_LLEGADA") == "1"
const ALCANCE := 30.0     ## el balón a menos de esto del arco rival

## Dónde va `p` a atacar el rebote (Vector3.INF = nada).
static func objetivo(m: MotorJugable, p: Dictionary) -> Vector3:
	if not ON or not m.poseedor.is_empty() or m.ultimo_toque.is_empty() or bool(p["por"]):
		return Vector3.INF
	if bool(m.ultimo_toque["es_local"]) != bool(p["es_local"]):
		return Vector3.INF
	var arco := m._arco_rival(p)
	var b := m.balon.position
	if b.distance_to(arco) > ALCANCE:
		return Vector3.INF
	var dz := m.dir_ataque(bool(p["es_local"]))
	var orden: Array = []
	for q: Dictionary in m.jugadores:
		if bool(q["es_local"]) == bool(p["es_local"]) and not bool(q["por"]):
			orden.append([m.pos(q).distance_to(b), String(q["id"])])
	orden.sort_custom(func(u: Array, v: Array) -> bool: return u[0] < v[0])
	var puesto := -1
	for i in orden.size():
		if String(orden[i][1]) == String(p["id"]):
			puesto = i
			break
	if puesto == 1:
		return Vector3(-signf(b.x) * 4.5 if absf(b.x) > 1.0 else 4.5, 0.0, arco.z - dz * 6.5)   ## segundo palo
	if puesto == 2:
		return Vector3(b.x * 0.4, 0.0, arco.z - dz * 11.0)   ## punto de penal
	return Vector3.INF
