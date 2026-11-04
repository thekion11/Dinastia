class_name MotorAdaptacion
extends RefCounted
## ADAPTABILIDAD, ESTILO, ENTORNO Y HABILIDADES EN LA COLOCACIÓN (03-11-2026, pedido del dueño tras ver el vídeo). Hasta ahora la
## colocación defensiva era igual para todos. Ahora:
##  · ADAPTACIÓN AL RIVAL: se aprende por qué lado ataca el rival (promedio del balón en x cuando él tiene la posesión, memoria ≈ 40 s) y el
##    bloque que defiende se desplaza hacia ese lado hasta `TOPE_LADO` m (cubre el lado fuerte y deja libre el débil), no antes de 15 s.
##  · HABILIDADES: el radio de acción de cada jugador (`MotorAncla`) crece con su ritmo y su físico (de 0,86× a 1,2×).
##  · FORMACIÓN Y ESTILO: los carrileros (CAD/CAI) tienen 1,3× de radio; con cinco defensas el central tiene 0,9×.
##  · ENTORNO: con lluvia, tormenta o nieve el bloque se junta (0,9× de radio).
## `SIN_ADAPTA=1` = nada de esto (colocación de antes).
const TOPE_LADO := 4.0
const MEMORIA := 40.0
const ARRANQUE := 15.0
static var _sin := OS.has_environment("SIN_ADAPTA")

static func _est(m: MotorJugable) -> Dictionary:
	if not m.has_meta("_adapta"):
		m.set_meta("_adapta", {"x": [0.0, 0.0], "vistos": [0.0, 0.0]})
	return m.get_meta("_adapta")

## Una vez por fotograma de juego: si el rival tiene el balón, recuerda en qué lado (x) lo lleva.
static func actualizar(m: MotorJugable, delta: float) -> void:
	if _sin or m.poseedor.is_empty():
		return
	var atac := 0 if bool(m.poseedor["es_local"]) else 1       ## el que ataca
	var e := _est(m)
	var xs: Array = e["x"]
	var vs: Array = e["vistos"]
	xs[atac] = lerpf(float(xs[atac]), m.balon.position.x, 1.0 - exp(-delta / MEMORIA))
	vs[atac] = float(vs[atac]) + delta

## Desplazamiento en x del bloque que DEFIENDE (`local`) hacia el lado por el que ataca el rival (0 si ataca el propio equipo).
static func desvio_x(m: MotorJugable, local: bool, en_posesion: bool) -> float:
	if _sin or en_posesion:
		return 0.0
	var rival := 1 if local else 0
	var e := _est(m)
	if float((e["vistos"] as Array)[rival]) < ARRANQUE:
		return 0.0
	return clampf(float((e["x"] as Array)[rival]) * 0.3, -TOPE_LADO, TOPE_LADO)

## Multiplicador del radio de acción de `p` (ancla) por habilidades, formación y entorno.
static func escala_radio(m: MotorJugable, p: Dictionary) -> float:
	if _sin:
		return 1.0
	var a: Dictionary = p["attr"]
	var f := 0.8 + 0.2 * float(a.get("rit", 0.6)) + 0.2 * float(a.get("fis", 0.6))
	var slot := String(p.get("slot_code", ""))
	if slot == "CAD" or slot == "CAI":
		f *= 1.3
	elif m._rol(p) == "DFC":
		var n_def := 0
		for q: Dictionary in m.jugadores:
			if bool(q["es_local"]) == bool(p["es_local"]) and m._rol(q) in ["DFC", "LD", "LI"]:
				n_def += 1
		if n_def >= 5:
			f *= 0.9
	if String(m.clima) in ["lluvia", "tormenta", "nieve"]:
		f *= 0.9
	return f
