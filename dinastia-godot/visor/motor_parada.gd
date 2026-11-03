class_name MotorParada
extends RefCounted
## LA PARADA CUANDO LLEGA EL BALÓN (01-11-2026, fallo encontrado al medir IA U3). El portero decide si llega hasta 1,6 s antes
## de que el tiro le alcance (`_reaccion_portero`), y la parada (`_parada`) se hacía en ese mismo instante: con el balón aún a
## 16 m, el blocaje lo llevaba a las manos a 167 m/s y el rechace lo devolvía antes de llegar. Ahora la decisión queda
## pendiente y la parada se hace cuando el balón llega a él (0,1 s antes de cruzar su línea o a menos de 1,6 m); si antes lo
## toca otro, cambia el tiro, se queda corto o se para el juego, se anula. Mientras, el portero sigue colocándose con su IA de siempre.
const ANTES := 0.1
const CERCA := 1.6

## Deja la parada para cuando llegue el balón (o la hace ya si está encima).
static func programar(m: MotorJugable, gk: Dictionary, cruce: Vector3, estirada: bool) -> void:
	var b := m.balon.position
	var vz := m.vel_balon.z
	var tg := clampf((m.pos(gk).z - b.z) / vz, 0.0, 2.0) if absf(vz) > 0.1 else 0.0
	if tg <= ANTES or b.distance_to(m.pos(gk)) < CERCA:
		m._parada(gk, cruce, estirada)
		return
	gk["parada_pend"] = {"cruce": cruce, "estirada": estirada, "n": m._n_patada}

## Cada fotograma del portero: true si la parada pendiente se hizo ahora.
static func revisar(m: MotorJugable, gk: Dictionary) -> bool:
	if not gk.has("parada_pend"):
		return false
	var pp: Dictionary = gk["parada_pend"]
	if int(pp["n"]) != m._n_patada or not m.poseedor.is_empty() or m.estado != "juego":
		gk.erase("parada_pend")
		return false
	## Lo que le falta al balón para cruzar la línea del portero, recalculado (el balón frena al rodar: no vale el tiempo previsto).
	var vz := m.vel_balon.z
	if absf(vz) < 1.0:
		gk.erase("parada_pend")   ## se quedó corto: lo recoge la IA de siempre
		return false
	var falta := (m.pos(gk).z - m.balon.position.z) / vz
	if falta <= ANTES or m.balon.position.distance_to(m.pos(gk)) < CERCA:
		gk.erase("parada_pend")
		m._parada(gk, pp["cruce"], bool(pp["estirada"]))
		return true
	return false

## ANTICIPACIÓN (03-11-2026, IA F7, idea de League-Soccer `goalie_default.cpp::CalculateIfBallIsBoundForGoal`): con la parada ya decidida y
## el balón aún en camino, el portero NO se queda clavado: se desliza hacia donde va a cruzar el tiro (hasta `DESLIZA` m, más cuanto
## mejores reflejos tenga) y llega a la parada ya en su sitio. Devuelve el punto al que ir, o Vector3.INF si no hay parada pendiente.
## `SIN_ANTICIPA=1` = quieto, como antes.
const DESLIZA := 1.2
static var _sin_anticipa := OS.has_environment("SIN_ANTICIPA")

static func destino(m: MotorJugable, gk: Dictionary) -> Vector3:
	if _sin_anticipa or not gk.has("parada_pend"):
		return Vector3.INF
	var cruce: Vector3 = (gk["parada_pend"] as Dictionary)["cruce"]
	var yo := m.pos(gk)
	var tope := DESLIZA * (0.6 + 0.4 * float(gk["attr"]["ref"]))
	gk["correr"] = true
	return Vector3(yo.x + clampf(cruce.x - yo.x, -tope, tope), 0, yo.z)

## CICLO 20 (3-11): el motor para ≈59 % de los tiros a puerta (real ≈70 %). `PARADA_K` multiplica la probabilidad base de atajar (1,0 = como antes).
static var K := float(OS.get_environment("PARADA_K")) if OS.get_environment("PARADA_K") != "" else 1.0

