class_name MotorPaseMejora
extends RefCounted
## ELEGIR EL PASE POR CUÁNTO MEJORA LA JUGADA (01-11-2026, IA R2 de `docs/04_auditorias/terceros_ia_motor_2026-11-01.md`, idea de
## League-Soccer `AI_CalculatePassingOdds` / `AI_GetPassRatings`). Lo usa `_mejor_pase` para cada compañero: lo libre que está
## y el riesgo de que corten el pase. Con la bandera APAGADA hace exactamente la cuenta de siempre (rivales donde están, pasillo
## fijo de 2,2 m). ENCENDIDA (`PMOT_PASE=1`, como `TIRO_PULIDO`):
##   - el receptor se mira donde estará en 0,5 s y cada rival donde estará en 0,3 s (corta el que llega corriendo, no el quieto);
##   - el pasillo se ensancha con la distancia: 0,45 m + 0,22 por metro desde el pasador (un pase largo da más tiempo a cortarlo);
##   - pasar a la espalda de hacia donde mira cuesta: hasta `GIRO` de riesgo extra para un pase hacia atrás.
const PREVE_RECEPTOR := 0.5
const PREVE_RIVAL := 0.3
const GIRO := 1.2
static var ACTIVO := OS.get_environment("PMOT_PASE") == "1"
## Peso del riesgo de corte en la nota del pase (ciclo 8, 03-11; 1,0 = la cuenta de siempre). `PMOT_RIESGO=2` = el receptor tapado pesa el doble.
## Velocidad del pase raso (ciclo 9, 03-11; por defecto 1,2; 1,0 = la de siempre): un pase más rápido da menos tiempo a cortarlo. `PMOT_VEL=1.2` = un 20 % más rápido.
static var VEL_K := float(OS.get_environment("PMOT_VEL")) if OS.get_environment("PMOT_VEL") != "" else 1.2   ## ENCENDIDO por defecto desde el 3-11 (ciclo 9: +4,4 puntos de pases buenos en 32 partidos); `PMOT_VEL=1.0` = como antes
static var RIESGO_K := float(OS.get_environment("PMOT_RIESGO")) if OS.get_environment("PMOT_RIESGO") != "" else 1.0

## [libre (m al rival más cercano del receptor), riesgo de corte] del pase de `p` a `q`.
static func libre_y_riesgo(m: MotorJugable, p: Dictionary, q: Dictionary, yo: Vector3, qp: Vector3) -> Array:
	var libre := 99.0
	var riesgo := 0.0
	var local := bool(p["es_local"])
	if not ACTIVO:
		for r: Dictionary in m.jugadores:
			if bool(r["es_local"]) == local:
				continue
			libre = minf(libre, m.pos(r).distance_to(qp))
			var cerca := Geometry3D.get_closest_point_to_segment(m.pos(r), yo, qp)
			var dl := cerca.distance_to(m.pos(r))
			if dl < 2.2:
				riesgo += (2.2 - dl) * 2.4
		return [libre, riesgo]
	var qf := qp + m._plano(q["vel"] as Vector3) * PREVE_RECEPTOR
	for r: Dictionary in m.jugadores:
		if bool(r["es_local"]) == local:
			continue
		var rf := m.pos(r) + m._plano(r["vel"] as Vector3) * PREVE_RIVAL
		libre = minf(libre, rf.distance_to(qf))
		var cerca := Geometry3D.get_closest_point_to_segment(rf, yo, qf)
		var ancho := 0.45 + cerca.distance_to(yo) * 0.22
		var dl := cerca.distance_to(rf)
		if dl < ancho:
			riesgo += (1.0 - dl / ancho) * 5.3
	var giro := (p["node"] as Node3D).rotation.y
	var fwd := Vector3(sin(giro), 0, cos(giro))
	var hacia := m._plano(qf - yo).normalized()
	riesgo += (1.0 - fwd.dot(hacia)) * 0.5 * GIRO
	return [libre, riesgo]
