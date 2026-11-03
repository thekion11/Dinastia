extends "res://visor/motor_jugable_p8_p1.gd"
## (Parte 2 de 2 de `motor_jugable_p8.gd`.)

## `para_cambio`: el cambio manual con el stick derecho (vale cualquiera, cerca o lejos).
func _companero_en_direccion(p: Dictionary, dir: Vector3, para_cambio := false) -> Dictionary:
	var mejor: Dictionary = {}
	var mejor_nota := -99.0
	var yo := pos(p)
	for q: Dictionary in jugadores:
		if q == p or bool(q["es_local"]) != bool(p["es_local"]) or bool(q["por"]):
			continue
		var v := pos(q) - yo
		var dist := v.length()
		if (dist < 3.0 and not para_cambio) or dist > (70.0 if para_cambio else 45.0):
			continue
		var alineado := v.normalized().dot(dir.normalized())
		var nota := alineado * 3.0 - dist * 0.03
		## PASE ASISTIDO (20-10-2026, al jugarlo Claude: 4 de 26 pases llegaban):
		## entre los que están hacia donde apuntas, mejor el que tiene la línea
		## limpia, como hace la IA. Solo si está razonablemente en la dirección.
		if not para_cambio and alineado > 0.5 and _linea_tapada(yo, pos(q), bool(p["es_local"])):
			nota -= 1.2
		if nota > mejor_nota:
			mejor_nota = nota
			mejor = q
	return mejor
