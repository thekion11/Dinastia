extends BaseIdea
## M-462 (27-10-2026): ¿los iconos de la interfaz (emoji, flechas, ●, ✔, ▸, 💾…) salen como cuadros? Junta todos
## los caracteres fuera del alfabeto latino de los textos de `ui/` y `nucleo/` y comprueba que alguna fuente de la
## cadena de respaldo propia (`Fuentes.repuesto`, sin depender de las del sistema) los dibuja.

func _probar() -> void:
	_titulo("M-462: TODOS LOS ICONOS TIENEN GLIFO EN LAS FUENTES DEL JUEGO")
	var cadena: Array[Font] = Fuentes.repuesto()
	var base := Fuentes.propia("Inter")
	if base != null:
		cadena.push_front(base)
	var usados := {}
	for carpeta: String in ["res://ui", "res://nucleo", "res://visor"]:
		_juntar(carpeta, usados)
	var sin: Array[String] = []
	for cp: int in usados:
		var hay := false
		for f: Font in cadena:
			if f.has_char(cp):
				hay = true
				break
		if not hay:
			sin.append("%s U+%04X" % [String.chr(cp), cp])
	_comprobar(usados.size() > 50, "se encontraron %d símbolos distintos en los textos" % usados.size())
	_comprobar(sin.is_empty(), "todos tienen glifo en las fuentes propias %s" % ("" if sin.is_empty() else str(sin.slice(0, 30))))

func _juntar(dir: String, usados: Dictionary) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for sub: String in d.get_directories():
		_juntar(dir + "/" + sub, usados)
	for f: String in d.get_files():
		if not f.ends_with(".gd"):
			continue
		var txt := FileAccess.get_file_as_string(dir + "/" + f)
		var dentro := false
		for i in txt.length():
			var c := txt.unicode_at(i)
			if c == 34:
				dentro = not dentro
			elif dentro and c > 0x2000 and not (c >= 0xFE00 and c <= 0xFE0F) and c != 0x200D:
				usados[c] = true
