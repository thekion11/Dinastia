extends SceneTree
## Lista las frases de `Idiomas.t("…")` del código que no tienen traducción en
## algún idioma. Uso: godot --headless --path . -s res://pruebas/frases_sin_traducir.gd
## Escribe `pruebas/frases_sin_traducir.json` ({frase: [idiomas que faltan]}).

func _init() -> void:
	call_deferred("_correr")

func _correr() -> void:
	var idi: Node = root.get_node("Idiomas")
	var re := RegEx.new()
	re.compile('Idiomas\\.t\\("((?:[^"\\\\]|\\\\.)*)"\\)')
	var frases := {}
	for dir: String in ["res://ui", "res://visor", "res://nucleo"]:
		_juntar(dir, re, frases)
	var faltan := {}
	for f: String in frases:
		if f.contains("%") and f.strip_edges() == "%s":
			continue
		var sin: Array = []
		for lang: String in ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]:
			idi.idioma = lang
			if idi._directa(f) == "" and String(idi._t(f, 0)) == f:
				sin.append(lang)
		if not sin.is_empty():
			faltan[f] = sin
	idi.idioma = "es"
	var arch := FileAccess.open("res://pruebas/frases_sin_traducir.json", FileAccess.WRITE)
	arch.store_string(JSON.stringify(faltan, "\t"))
	print("FRASES ", frases.size(), " SIN TRADUCIR ", faltan.size())
	quit()

func _juntar(dir: String, re: RegEx, frases: Dictionary) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			var txt := FileAccess.get_file_as_string(dir + "/" + f)
			for m in re.search_all(txt):
				frases[m.get_string(1).c_unescape()] = true
	for d in DirAccess.get_directories_at(dir):
		_juntar(dir + "/" + d, re, frases)
