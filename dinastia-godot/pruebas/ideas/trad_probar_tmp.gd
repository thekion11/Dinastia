extends SceneTree
## Imprime Idiomas.t de cada frase de /tmp/trad/probar.json en IDIOMAS (por defecto en).
func _init() -> void:
	call_deferred("_correr")
func _correr() -> void:
	var idi: Node = root.get_node("Idiomas")
	var lista: Array = JSON.parse_string(FileAccess.get_file_as_string("/tmp/trad/probar.json"))
	var langs := OS.get_environment("IDIOMAS").split(",") if OS.get_environment("IDIOMAS") != "" else PackedStringArray(["en"])
	var falta := 0
	for f: String in lista:
		var fila := []
		for l in langs:
			idi.idioma = l
			idi._cache.clear()
			var r: String = idi.t(f)
			if r == f:
				falta += 1
			fila.append(l + "=" + r)
		print("· ", f, "  ->  ", " | ".join(fila))
	print("SIN CAMBIO: ", falta)
	quit()
