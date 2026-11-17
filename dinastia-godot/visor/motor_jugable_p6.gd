extends "res://visor/motor_jugable_p6_p1.gd"
## (Parte 2 de 2 de `motor_jugable_p6.gd`.)

func _linea_tapada(a: Vector3, c: Vector3, local: bool) -> bool:
	for r: Dictionary in jugadores:
		if bool(r["es_local"]) == local:
			continue
		var cerca := Geometry3D.get_closest_point_to_segment(pos(r), a, c)
		if cerca.distance_to(pos(r)) < 1.3:
			return true
	return false

## Cuánto rueda un balón raso que sale a `v0`: con frenado dv/dt = -(k·v + c),
## x = v0/k - c/k²·ln(1 + k·v0/c).
static func distancia_rodando(v0: float) -> float:
	var k := ROCE_SUELO
	var c := ROCE_FIJO
	return v0 / k - c / (k * k) * log(1.0 + k * v0 / c)

## La velocidad para que un pase raso muera `sobra` metros después del destino: el compañero lo recibe en carrera sin que se le pase de largo.
static func velocidad_para(dist: float, sobra := 2.5) -> float:
	var lo := 1.0
	var hi := 40.0
	for _i in 24:
		var mid := (lo + hi) * 0.5
		if distancia_rodando(mid) < dist + sobra:
			lo = mid
		else:
			hi = mid
	return hi

## `tenso` (RB): raso y fuerte, para romper líneas.
func _pasar_a(p: Dictionary, q: Dictionary, largo := false, al_hueco := false, tenso := false) -> void:
	var destino := pos(q)
	var dist := destino.distance_to(pos(p))
	## Se le pasa adelantado, a donde va a estar.
	destino += _guia_pase(q, dist, al_hueco)   ## (12-11) la fórmula de siempre, en un gancho de la capa 1 que C4 cambia
	## Nadie pasa perfecto: el error crece con la distancia, con la presión y
	## cuanto peor es el pase del que la toca.
	var hab := GestoTecnico.pase(p, largo, al_hueco, tenso)   ## cada pase pesa sus atributos; pie malo y clima (27-10)
	var error := ((1.0 - hab) * dist * 0.22 + (1.2 if _presion(p) < 2.0 else 0.0) * (1.4 - hab)) * _error_extra * preset_error
	error *= GestoTecnico.factor_pie(p, pos(p), destino) * GestoTecnico.factor(self, p, largo or dist > 30.0)
	destino += Vector3(_rng.randf_range(-error, error), 0, _rng.randf_range(-error, error))
	## POR ABAJO SIEMPRE QUE SE PUEDA (13-10-2026): con «cualquier rival cerca
	## de la línea = por arriba» la sonda medía el balón en el aire el 64 % del
	## tiempo (pelotazo y cabezazo). Ahora por arriba solo el envío largo o el
	## que está tapado y lejos, y a media altura.
	_ctx_golpeo = "filtrado" if al_hueco else ""
	var tapada := dist > 9.0 and _linea_tapada(pos(p), destino, bool(p["es_local"]))
	var elevado := largo or ((dist > 36.0 or tapada) and not tenso)
	if tenso and not largo:
		_patear(p, destino, clampf(velocidad_para(dist, 9.0 + dist * 1.5) * 1.15, 12.0, 30.0), 0.0, 0.0, "pase")
	elif elevado and largo and al_hueco:
		## Al hueco bombeado: por encima de la línea, cae en el desmarque.
		_patear(p, destino, clampf(dist * 0.42 + 6.0, 10.0, 18.0), 3.2, 0.0, "pase")
	elif elevado:
		## Envío por arriba: el tapado, picado por encima del defensor (bajo);
		## el largo, con más vuelo.
		_patear(p, destino, clampf(dist * 0.45 + 6.0, 10.0, 19.0), 0.25 if (tapada and dist < 25.0) else 2.0, 0.0, "pase")
	else:
		## Con pace: el balón llega al compañero con fuerza, no muriéndose.
		_patear(p, destino, clampf(velocidad_para(dist, 4.0 + dist * 1.5) * MotorPaseMejora.VEL_K, 7.0, 26.0 * MotorPaseMejora.VEL_K), 0.0, 0.0, "pase")
	pase_a = q
	MotorTraza.pase(self as Object as MotorJugable, p, q, dist)   ## traza (ciclo 13): solo cuenta
	_pase_eq = 0 if bool(p["es_local"]) else 1
	pases[_pase_eq] += 1
	if p == usuario:
		stats["pases"] += 1
		_pase_usuario_vivo = true
		_pase_usuario_de = p
