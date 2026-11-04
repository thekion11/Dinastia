extends BaseIdea
func _probar() -> void:
	var b := CityBuilder.new()
	add_child(b)
	for m in b._terreno():
		b.add_child(m)
	var c := CityBuilder.MONTE_CENTRO
	for d in [0, 100, 200, 300, 400, 500, 600, 800, 1000]:
		var x := c.x - float(d) * 0.707
		var z := c.y - float(d) * 0.707
		var gx := (b.altura_en(x + 6.0, z) - b.altura_en(x - 6.0, z)) / 12.0
		var gz := (b.altura_en(x, z + 6.0) - b.altura_en(x, z - 6.0)) / 12.0
		var ny := 1.0 / sqrt(1.0 + gx * gx + gz * gz)
		_linea("d=%d h=%.1f ny=%.3f" % [d, b.altura_en(x, z), ny])
		## A4-REGLAS-006: antes esta prueba solo imprimía y siempre pasaba. Ahora la ladera del monte
		## debe tener altura finita y no ser un muro (medido 4-11: ny entre 0,80 y 0,99).
		_comprobar(is_finite(b.altura_en(x, z)) and ny >= 0.6, "ladera transitable a %d m del centro (ny=%.2f)" % [d, ny])
