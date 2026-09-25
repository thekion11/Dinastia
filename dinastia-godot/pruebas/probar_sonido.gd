extends Node
## Comprueba que la sintesis produce ondas de verdad y no silencio.
func _ready() -> void:
	await get_tree().process_frame
	var vacios := 0
	var lista: Array = Sonido.catalogo()
	for nombre: String in lista:
		var f: Dictionary = Sonido.ficha(nombre)
		print("  %-14s %d variantes  %.2f s  pico %d" % [
			nombre, int(f["variantes"]), float(f["segundos"]), int(f["pico"])])
		## El umbral es bajo a proposito: el murmullo de fondo es AMBIENTE y tiene
		## que sonar suave (pico ~400). Con el umbral en 1000 la prueba lo daba por
		## mudo, y el mudo era la prueba.
		if int(f["pico"]) < 300:
			vacios += 1
	print("bancos con sonido: %d de %d" % [lista.size() - vacios, lista.size()])
	get_tree().quit(1 if vacios > 0 or lista.is_empty() else 0)
