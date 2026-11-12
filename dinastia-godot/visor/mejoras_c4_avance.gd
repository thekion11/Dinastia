class_name MejorasC4Avance
extends RefCounted
## LLEGAR AL ÁREA CON EL BALÓN EN C4 (12-11-2026, sesión 15). Los goles de jugada son ~0,7 de ~4,4 por partido y los tiros desde
## dentro del área ~8: el portador llega a la frontal y, sin nadie encima, la toca hacia atrás (el «mejor pase» de siempre puntúa
## también los pases de seguridad). Con `C4_NO_ATRAS=1`, a menos de `DIST` m del arco rival, en juego y sin rival a menos de `PRESION`
## m, el pase que va más de `ATRAS` m hacia atrás no se da: sigue conduciendo hacia el área (o elige otra cosa). Solo en C4
## (`MotorCombinado._mejor_pase`); contador `c4_no_atras`.

static var ACTIVO := OS.get_environment("C4_NO_ATRAS") == "1"
static var DIST := float(OS.get_environment("C4_NO_ATRAS_D")) if OS.get_environment("C4_NO_ATRAS_D") != "" else 35.0
const PRESION := 3.0
const ATRAS := 3.0

## El pase que propone la decisión de siempre (`q`), o {} si en C4 sería un pase atrás evitable.
static func filtrar(m: Object, p: Dictionary, q: Dictionary) -> Dictionary:
	if not ACTIVO or q.is_empty() or String(m.estado) != "juego" or m.poseedor != p or bool(p["por"]):
		return q
	var arco: Vector3 = m._arco_rival(p)
	var yo: Vector3 = m.pos(p)
	var dy := absf(arco.z - yo.z)
	if dy > DIST or float(m._presion(p)) < PRESION:
		return q
	if absf(arco.z - m.pos(q).z) - dy < ATRAS:
		return q
	if m.get("diag") is Dictionary:
		(m.diag as Dictionary)["c4_no_atras"] = int((m.diag as Dictionary).get("c4_no_atras", 0)) + 1
	return {}

## MÁS 1 CONTRA 1 EN LA FRONTAL (sesión 15): con `C4_REGATE_AREA=k` (0 = apagada) las ganas de encarar al defensor a menos de 32 m del
## arco rival se multiplican por `k` (el de siempre ya les da ×1,25 ahí). Lo usa `MotorCombinado._intentar_regate`.
static var REGATE_AREA := float(OS.get_environment("C4_REGATE_AREA")) if OS.get_environment("C4_REGATE_AREA") != "" else 0.0
