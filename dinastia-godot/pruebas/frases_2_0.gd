extends SceneTree
## Frases del estadio 2.0 que se traducen por variable (salas, saludos,
## catálogo, puestos…). Las añade a la lista de `frases_sin_traducir.json`.
func _init() -> void:
	call_deferred("_correr")

func _correr() -> void:
	var idi: Node = root.get_node("Idiomas")
	var lista: Array = []
	for f: Array in EdificioClub.PLANTAS:
		lista.append(String(f[1]))
		for s: Array in f[2]:
			lista.append(String(s[0]))
	lista += ["Vestuario", "Túnel", "Banda", "Campo", "Acceso", "Pasillo", "Galería", "Escalera de la galería",
		"Vestuario y túnel", "Presidente", "Portero del club", "Buenas, míster.", "Buenos días, míster.",
		"Buenas tardes, míster.", "Buenas noches, míster. Aquí sigo de guardia.", "…", "Estacionamiento"]
	for k: String in RecorridoClub.SALUDOS:
		lista.append(String(RecorridoClub.SALUDOS[k]))
	lista += RecorridoClub.NOVEDADES_PORTERO
	for k2: String in InterioresClub.CATALOGO:
		lista.append(String(InterioresClub.CATALOGO[k2][0]))
	for r: Array in Gente.ROLES:
		lista.append(String(r[1]))
	var faltan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://pruebas/frases_sin_traducir.json"))
	for f: String in lista:
		var sin: Array = []
		for lang: String in ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]:
			idi.idioma = lang
			if idi._directa(f) == "":
				sin.append(lang)
		if not sin.is_empty():
			faltan[f] = sin
	idi.idioma = "es"
	FileAccess.open("res://pruebas/frases_sin_traducir.json", FileAccess.WRITE).store_string(JSON.stringify(faltan, "\t"))
	print("TOTAL SIN TRADUCIR ", faltan.size())
	quit()
