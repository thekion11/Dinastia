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
## Penalización por METRO de distancia en la nota del pase (ciclo 13, 03-11; 0,02 = la de siempre): los pases largos son el 33 % de los pases y aportan 4,6 de los 12,7 cortes por partido. `PMOT_DIST=0.06` = penaliza el triple.
static var DIST_K := float(OS.get_environment("PMOT_DIST")) if OS.get_environment("PMOT_DIST") != "" else 0.02
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

## CICLO 15 (3-11, distribución del pase): el 43 % de los pases son largos (real ≈10-15 %). La nota premia el avance por metro sin tope, así que un
## envío de 30 m siempre gana a un pase corto. `PMOT_PROG` = tope en metros del avance que cuenta (999 = sin tope, como antes).
static var PROG_TOPE := float(OS.get_environment("PMOT_PROG")) if OS.get_environment("PMOT_PROG") != "" else 10.0   ## ENCENDIDO el 3-11 (ciclo 15, 32 partidos: pases largos 43→31 %, pases buenos 72,8→76,8 %, goles 2,56→2,47); `PMOT_PROG=999` = sin tope, como antes

static func progreso(x: float) -> float:
	return minf(x, PROG_TOPE)

## Nota SIN azar de pasar de `p` a `q` (la misma fórmula de `_mejor_pase`, sin los términos aleatorios, fuera de juego ni jugada); [nota, libre, dist]. Solo para medir (ciclo 19).
static func nota_base(m: MotorJugable, p: Dictionary, q: Dictionary) -> Array:
	var yo := m.pos(p)
	var qp := m.pos(q)
	var d := m.dir_ataque(bool(p["es_local"]))
	var dist := qp.distance_to(yo)
	var lr := libre_y_riesgo(m, p, q, yo, qp)
	var loc := bool(p["es_local"])
	var nota := progreso((qp.z - yo.z) * d) * (MotorJugable.CHISPA_AVANCE * pow(m.prisa(), 0.7) + 0.025 * float(m._tac(loc, "mentalidad") - 1) + 0.015 * float(m._tac(loc, "ritmo") - 1) + 0.03 * float(m._tac(loc, "verticalidad") - 1)) \
		+ minf(float(lr[0]), 10.0) * 0.18 - float(lr[1]) * RIESGO_K - dist * DIST_K
	return [nota, float(lr[0]), dist]

## CICLO 29 (plan «construir hasta el área», C2): solo el 13 % de los pases de la IA acaba en el último tercio (real ≈28-35 %) y el 0,4 % en el área. `PMOT_TERCIO` = bono de nota a un pase cuyo receptor está en el último
## tercio (o en el área); 0 = como antes. No usa números aleatorios.
static var TERCIO_K := float(OS.get_environment("PMOT_TERCIO")) if OS.get_environment("PMOT_TERCIO") != "" else 0.0

static func bono_tercio(m: MotorJugable, p: Dictionary, qp: Vector3) -> float:
	if TERCIO_K <= 0.0:
		return 0.0
	var z := MotorTraza.zona_punto(m, 0 if bool(p["es_local"]) else 1, qp)
	return TERCIO_K if (z == "ataque" or z == "area") else 0.0

