class_name AnimFutbol
extends "res://visor/anim_futbol_p2.gd"
## (Parte 3 de 3 de `anim_futbol.gd`.)

## Las que tienen espejo útil (golpeos, barridas, regates): el zurdo y el
## regate hacia el otro lado.
static func espejables() -> Array:
	var f := familias()
	var r: Array = []
	for k: String in ["tiro", "pase", "barrida", "regate"]:
		r.append_array(f[k])
	return r
