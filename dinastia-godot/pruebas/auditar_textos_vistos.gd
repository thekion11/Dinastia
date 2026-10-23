extends Node
## Lee los textos que guardó `recorrido_pantallas` (RECORRIDO_TEXTOS=ruta) y lista, en el idioma pedido, los que NO se
## traducen (23-10-2026). Solo muestra los que parecen castellano (acentos, ¿¡ o palabras típicas).
##   TEXTOS=/ruta/textos.json IDIOMA=en godot --headless --path . res://pruebas/auditar_textos_vistos.tscn
func _ready() -> void:
	var idioma := OS.get_environment("IDIOMA") if OS.get_environment("IDIOMA") != "" else "en"
	Idiomas.idioma = idioma
	var datos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("TEXTOS")))
	var rx := RegEx.new()
	rx.compile("[áéíóúñ¿¡]|\\b(el|la|los|las|de|del|que|con|para|por|tu|tus|una|un|sin|más|hay|está|son|se|su|sus)\\b")
	var sin: Array[String] = []
	for k in datos.keys():
		var s := String(k)
		if s.length() < 4 or not rx.search(s.to_lower()):
			continue
		if Idiomas.t(s) == s:
			sin.append(s)
	sin.sort()
	print("TEXTOS VISTOS: %d; con pinta de castellano y sin traducir en %s: %d" % [datos.size(), idioma, sin.size()])
	for s in sin:
		print("  · ", s.replace("\n", " ⏎ ").left(150))
	get_tree().quit()
