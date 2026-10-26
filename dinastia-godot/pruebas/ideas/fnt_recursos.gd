extends BaseIdea
## Fuentes propias (OFL), banderas de flag-icons (MIT) y su respaldo (26-10-2026, fnt).

## Letras de los 9 idiomas que más fallan en fuentes ajenas (polaco, turco, catalán...).
const LETRAS := "ąćęłńóśźżĄĆĘŁŃÓŚŹŻğĞıİşŞçÇöÖüÜàèíòúïl·lñÑ¿¡ºª€"
## Símbolos de la interfaz que antes dependían de las fuentes del sistema.
const SIMBOLOS := ["⚽", "⚙", "🏆", "📅", "💰", "🎯", "✔", "▶", "⏩", "🧭",
	## Los que hasta el 26-10 solo ponía el sistema.
	"↶", "⇄", "⇠", "⇡", "⇢", "⇣", "ⓒ", "━", "▂", "▄", "▆", "⛶", "⟲", "⟳", "＋", "▸", "✕", "☰"]

func _probar() -> void:
	_titulo("RECURSOS LIBRES: fuentes propias y banderas detalladas (fnt)")
	for n: String in Fuentes.PROPIAS:
		_comprobar(ResourceLoader.exists(Fuentes.PROPIAS[n]) and Fuentes.propia(n) != null, "la fuente propia «%s» se carga" % n)
	var inter := Fuentes.propia("Inter")
	var falta := ""
	for c in LETRAS:
		if not inter.has_char(c.unicode_at(0)):
			falta += c
	_comprobar(falta == "", "Inter tiene todas las letras de los 9 idiomas (faltan: «%s»)" % falta)
	var barlow := Fuentes.propia("Barlow Condensed")
	falta = ""
	for c in LETRAS:
		if not barlow.has_char(c.unicode_at(0)):
			falta += c
	_comprobar(falta == "", "Barlow Condensed tiene todas las letras de los 9 idiomas (faltan: «%s»)" % falta)
	## Cada símbolo lo tiene alguna fuente PROPIA de la cadena (sin contar el sistema).
	var propias: Array[Font] = []
	for f: Font in Fuentes.repuesto():
		if f is FontFile:
			propias.append(f)
	falta = ""
	for s: String in SIMBOLOS:
		var hay := false
		for f: Font in propias:
			hay = hay or f.has_char(s.unicode_at(0))
		if not hay:
			falta += s
	_comprobar(falta == "", "los símbolos de la interfaz salen de fuentes propias aunque el sistema no tenga emojis (faltan: «%s»)" % falta)
	var est := Fuentes.para(Principal.TIPOGRAFIAS["estrecha"][1])
	_comprobar(est is FontFile and (est as FontFile).get_font_name() == "Barlow Condensed" and est.fallbacks.size() >= 4,
		"«Estrecha» es Barlow Condensed propia con el sistema y la cadena de respaldo detrás")
	var tit := Fuentes.para(Principal.TIPOGRAFIAS["titular"][1])
	_comprobar(tit is FontFile and (tit as FontFile).get_font_name() == "Bebas Neue", "«De titular» es Bebas Neue propia (ya no depende de Impact)")
	var dj := Fuentes.del_juego()
	_comprobar(dj is FontVariation and (dj as FontVariation).base_font == ThemeDB.fallback_font and dj.fallbacks == Fuentes.repuesto(),
		"«Del juego» sigue siendo la fuente de fábrica (mismo tamaño) con la cadena de respaldo")
	## La cadena no altera la medida del texto latino con la fuente de fábrica.
	var txt := "Lautaro FC · Zaufanie zarządu · Gençlerbirliği"
	_comprobar(is_equal_approx(dj.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x,
		ThemeDB.fallback_font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x), "el texto mide lo mismo que antes con «Del juego»")
	## La cadena de respaldo no hace más alta la línea (antes de recortar Symbols 2
	## pasaba de 22 a 29 px a 16 px y las tablas perdían filas).
	for t: int in [10, 13, 16, 22, 36]:
		_comprobar(is_equal_approx(dj.get_height(t), ThemeDB.fallback_font.get_height(t)),
			"a %d px la línea mide lo mismo con la cadena de respaldo (%.1f / %.1f)" % [t, dj.get_height(t), ThemeDB.fallback_font.get_height(t)])
	# --- banderas ---
	var faltan: Array = []
	for cod: String in Banderas.ISO:
		if not ResourceLoader.exists("res://assets/banderas/%s.svg" % Banderas.ISO[cod]):
			faltan.append(cod)
	_comprobar(faltan.is_empty(), "hay SVG para los %d países de la tabla (faltan %s)" % [Banderas.ISO.size(), str(faltan)])
	var bandera: Dictionary = Datos.tabla("BANDERA")
	var sin_iso: Array = []
	for cod: String in bandera:
		if not Banderas.ISO.has(cod):
			sin_iso.append(cod)
	for cod: String in Datos.tabla("PAIS_SELECCION"):
		if not Banderas.ISO.has(cod):
			sin_iso.append(cod)
	_comprobar(sin_iso.is_empty(), "todo país del juego tiene código ISO para su SVG (sin código: %s)" % str(sin_iso))
	var det := Banderas.textura("ESP").get_image()
	Banderas._cache.clear()
	Banderas.solo_dibujo = true
	var dib := Banderas.textura("ESP").get_image()
	Banderas.solo_dibujo = false
	Banderas._cache.clear()
	_comprobar(det.get_size() == Vector2i(Banderas.ANCHO, Banderas.ALTO) and det.get_format() == Image.FORMAT_RGB8,
		"la bandera detallada mide y se guarda igual que el dibujo (%dx%d RGB8)" % [det.get_width(), det.get_height()])
	_comprobar(det.get_data() != dib.get_data(), "con el SVG la bandera de España ya no es el dibujo simplificado")
	var c := det.get_pixel(Banderas.ANCHO / 2, 2)
	_comprobar(c.r > 0.5 and c.g < 0.2, "la franja de arriba de España es roja (%s)" % str(c))
	var raro := Banderas.textura("XYZ")
	_comprobar(raro != null and raro.get_width() == Banderas.ANCHO, "un código sin SVG cae al dibujo de siempre")
