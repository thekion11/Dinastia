class_name MotorTandaCambio
extends RefCounted
## UN CAMBIO EN PLENA TANDA DE PENALES (caza de fallos, 4-11-2026, reglas al límite): el motor guarda a los lanzadores y al portero de la tanda como diccionarios (`tanda.orden`,
## `lanzador`, `portero`); si el DT cambia a uno de ellos (por ejemplo al portero lesionado) esas referencias seguían apuntando al que salió. Ahora se actualizan.

static func reemplazar(m: MotorJugable, sale: Dictionary, entra: Dictionary) -> void:
	if m.tanda.is_empty():
		return
	for lado: Array in m.tanda.get("orden", []):
		var i := lado.find(sale)
		if i >= 0:
			lado[i] = entra
	for k: String in ["lanzador", "portero"]:
		if m.tanda.get(k, {}) == sale:
			m.tanda[k] = entra
