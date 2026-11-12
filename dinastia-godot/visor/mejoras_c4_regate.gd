class_name MejorasC4Regate
extends RefCounted
## REGATE Y REMATE EN C4 (12-11-2026, sesión 15). Con la paciencia (`C4_PACIENCIA`), el que gana un regate en la frontal sigue
## sorteando el tiro como cualquiera y casi siempre la toca atrás o conduce: el regate ganado no acaba en ocasión. Con
## `C4_REGATE_TIRO=1`, durante `VENTANA` s tras ganar un regate a menos de `DIST` m del arco, las ganas de tirar no bajan de
## `GANAS` (y la paciencia no lo frena): el defensor quedó atrás, se remata. Solo en C4 (`MotorCombinado`); contadores
## `c4_regate_ok_cerca` y `c4_regate_tiro`.

static var ACTIVO := OS.get_environment("C4_REGATE_TIRO") == "1"
static var DIST := float(OS.get_environment("C4_REGATE_D")) if OS.get_environment("C4_REGATE_D") != "" else 26.0
const VENTANA := 1.5
const GANAS := 0.6

## Llamar tras la finta: si el regate se ganó cerca del arco, se apunta el momento.
static func marcar(m: Object, p: Dictionary, gano: bool) -> void:
	if not ACTIVO or not gano:
		return
	var yo: Vector3 = m.pos(p)
	var arco: Vector3 = m._arco_rival(p)
	if Vector2(yo.x - arco.x, yo.z - arco.z).length() < DIST:
		p["_c4_regate_t"] = float(m.t)
		_contar(m, "c4_regate_ok_cerca")

## Las ganas de tirar tras un regate ganado (`base` = las de la paciencia, `ganas` = las de antes de ella).
static func ganas(m: Object, p: Dictionary, dist: float, ganas_antes: float, base: float) -> float:
	if not ACTIVO or dist >= DIST or float(m.t) - float(p.get("_c4_regate_t", -99.0)) > VENTANA:
		return base
	p.erase("_c4_regate_t")
	_contar(m, "c4_regate_tiro")
	return maxf(maxf(ganas_antes, base), GANAS)

static func _contar(m: Object, clave: String) -> void:
	if m.get("diag") is Dictionary:
		(m.diag as Dictionary)[clave] = int((m.diag as Dictionary).get(clave, 0)) + 1
