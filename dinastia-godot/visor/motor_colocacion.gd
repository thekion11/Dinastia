class_name MotorColocacion
extends RefCounted
## COLOCACIÓN SIN BALÓN CON MEMORIA (03-11-2026, IA F1 de `docs/04_auditorias/terceros_ia_motor_2026-11-01.md`; la idea viene de
## League-Soccer `GetAdaptedFormationPosition`, escrita aparte y mucho más corta). Antes `_forma` mezclaba la base con el balón
## de ESTE fotograma: toda la línea se mecía con cada rebote. Ahora:
##  - el equipo mira un balón «lento» (promedio con retardo de 2-4 s: más rápido cuanto más cerca está su jugador más cercano),
##  - lleva un sesgo de POSESIÓN suavizado (1 = el balón es suyo, 0 = del rival, ~4 s de memoria), y
##  - con balón el bloque se alarga y se abre (sigue menos al balón); sin balón se junta y lo sigue más.
## `SIN_COLOCACION=1` = el `_forma` de antes.
const RETARDO_MAX := 3.8   ## s de retardo con el balón lejos de todos
const RETARDO_MIN := 1.8   ## s cuando un compañero está encima del balón
const MEMORIA_POSESION := 4.0
const PESO_Z_CON := 0.34    ## seguimiento del balón en profundidad con balón (antes 0,45)
const PESO_Z_SIN := 0.45    ## y sin balón: lo de siempre (0,55 de la primera versión sobreactuaba el enjambre, vídeo 3-11)
const PESO_X_CON := 0.18
const PESO_X_SIN := 0.22
static var _sin := OS.has_environment("SIN_COLOCACION")

static func _est(m: MotorJugable, local: bool) -> Dictionary:
	var k := "_colocacion_%s" % ("l" if local else "v")
	if not m.has_meta(k):
		m.set_meta(k, {"bal": m.balon.position, "sesgo": 0.5})
	return m.get_meta(k)

## Llamar una vez por fotograma de juego (`paso`).
## El retardo del balón estabiliza al equipo que lo TIENE; si el rival tiene el balón, el equipo lo sigue casi en directo (`RETARDO_RIVAL`),
## y la memoria de posesión cae rápido (`CAIDA_POSESION`) al perderlo: medido, un retardo de hasta 3,8 s justo cuando atacaba el rival
## regalaba goles de contra (+30 % en 16 partidos).
const RETARDO_RIVAL := 0.5
const CAIDA_POSESION := 0.8
static func actualizar(m: MotorJugable, delta: float) -> void:
	if _sin:
		return
	for local: bool in [true, false]:
		var e := _est(m, local)
		var cerca := 40.0
		for q: Dictionary in m.jugadores:
			if bool(q["es_local"]) == local:
				cerca = minf(cerca, m.pos(q).distance_to(m.balon.position))
		var urg := 1.0 - clampf((cerca - 2.0) / 28.0, 0.0, 1.0)
		var tau := lerpf(RETARDO_MAX, RETARDO_MIN, urg)
		var rival_con_balon := not m.poseedor.is_empty() and bool(m.poseedor["es_local"]) != local
		if rival_con_balon:
			tau = RETARDO_RIVAL
		e["bal"] = (e["bal"] as Vector3).lerp(m.balon.position, 1.0 - exp(-delta / tau))
		if not m.poseedor.is_empty():
			var meta := 0.0 if rival_con_balon else 1.0
			var k := CAIDA_POSESION if meta < float(e["sesgo"]) else MEMORIA_POSESION
			e["sesgo"] = lerpf(float(e["sesgo"]), meta, 1.0 - exp(-delta / k))

## Balón que «ve» el equipo, y sesgo de posesión (0-1).
static func balon_lento(m: MotorJugable, local: bool) -> Vector3:
	return m.balon.position if _sin else (_est(m, local)["bal"] as Vector3)

static func sesgo(m: MotorJugable, local: bool) -> float:
	return 0.5 if _sin else float(_est(m, local)["sesgo"])

## Pesos con los que `_forma` mezcla la base con el balón: [z del balón, x del balón, z de la base, x de la base].
## Apagado devuelve EXACTAMENTE los de siempre (0,45 · 0,22 · 0,55 · 0,8; los de X sumaban 1,02). Van en un arreglo de 64 bits
## a propósito: un Vector3/Vector4 de Godot guarda 32 bits y cambiaba la huella del motor.
static func pesos(m: MotorJugable, local: bool, en_posesion: bool) -> PackedFloat64Array:
	if _sin:
		return PackedFloat64Array([0.45, 0.22, 0.55, 0.8])
	var s := sesgo(m, local)
	if en_posesion:
		s = maxf(s, 0.6)
	var zb := lerpf(PESO_Z_SIN, PESO_Z_CON, s)
	var xb := lerpf(PESO_X_SIN, PESO_X_CON, s)
	return PackedFloat64Array([zb, xb, 1.0 - zb, 1.0 - xb])
