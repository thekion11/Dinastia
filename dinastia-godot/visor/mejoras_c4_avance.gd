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

## RUPTURA DEL 9 (sesión 15): el pase al hueco (`_companero_al_hueco`, `MejorasC4Hueco`) solo encuentra receptor si alguien está a
## pocos metros de la última línea y habilitado. Con `C4_RUPTURA=1`, mientras un compañero (no el portero) tiene el balón a 25-55 m del
## arco rival con tiempo (sin rival a < 2 m) y lleva menos de `RUPTURA_T` s con él, el DC más cercano a la última línea se planta en
## ella (1 m por detrás, habilitado), cerrándose hacia el centro, y esprinta: está listo cuando el pasador decide. Contador `c4_ruptura`.
static var RUPTURA := OS.get_environment("C4_RUPTURA") == "1"
const RUPTURA_T := 3.0

static func ruptura(m: Object, p: Dictionary) -> Vector3:
	if not RUPTURA or String(m._rol(p)) != "DC":
		return Vector3.INF
	var b: Dictionary = m.poseedor
	if b.is_empty() or b == p or bool(b["por"]) or bool(b["es_local"]) != bool(p["es_local"]):
		return Vector3.INF
	if float(m.t) - float(b.get("tomo_en", -99.0)) > RUPTURA_T or float(m._presion(b)) < 2.0:
		return Vector3.INF
	var arco: Vector3 = m._arco_rival(p)
	var db := absf(arco.z - m.pos(b).z)
	if db < 25.0 or db > 55.0:
		return Vector3.INF
	var local := bool(p["es_local"])
	var d: float = m.dir_ataque(local)
	var linea: float = m._ultima_linea(not local)
	var yo: Vector3 = m.pos(p)
	if absf(yo.z - linea) > 12.0:
		return Vector3.INF
	var x := lerpf(yo.x, 0.0, 0.3)
	if float(p.get("_c4_ruptura_t", -99.0)) < float(b.get("tomo_en", 0.0)):   ## una vez por posesión del compañero
		p["_c4_ruptura_t"] = float(m.t)
		if m.get("diag") is Dictionary:
			(m.diag as Dictionary)["c4_ruptura"] = int((m.diag as Dictionary).get("c4_ruptura", 0)) + 1
	return Vector3(x, 0, linea - d * 1.0)
