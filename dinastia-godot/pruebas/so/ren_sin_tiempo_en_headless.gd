extends BaseSO
## RENDIMIENTO · regla del proyecto hecha prueba: NINGUNA prueba afirma sobre el tiempo de fotograma o los FPS en --headless (tiene un suelo de 6,9 ms y
## en llvmpipe los FPS no valen). Busca en las pruebas las afirmaciones (`_comprobar`/`assert`) que mezclan `get_frames_per_second` o `TIME_PROCESS` y que
## no estén marcadas como medición con gráfica (`DisplayServer`/`hw_modesto`). Solo se puede revisar desde el proyecto (con el código fuente).
func _nombre() -> String:
	return "ren_sin_tiempo_en_headless"

func _fuentes(ruta: String, out: Array) -> void:
	var d := DirAccess.open(ruta)
	if d == null:
		return
	for f: String in d.get_files():
		if f.ends_with(".gd"):
			out.append(ruta.path_join(f))
	for s: String in d.get_directories():
		_fuentes(ruta.path_join(s), out)

func _probar() -> void:
	_titulo("RENDIMIENTO · ninguna afirmación sobre FPS en headless [%s]" % sistema())
	if not FileAccess.file_exists("res://pruebas/banco.gd"):
		print("  (en %s no hay código fuente de las pruebas: se revisa desde el proyecto)" % sistema())
		return
	var archivos: Array = []
	_fuentes("res://pruebas", archivos)
	_comprobar(archivos.size() > 300, "se revisan %d pruebas" % archivos.size())
	var sospechosas: Array[String] = []
	var re := RegEx.create_from_string("(_comprobar|assert)\\(.*(get_frames_per_second|TIME_PROCESS|TIME_FPS|fps\\s*[<>]=?\\s*[0-9]+)")
	for a: String in archivos:
		var txt := FileAccess.get_file_as_string(a)
		var con_pantalla := txt.contains("DisplayServer.get_name()") or txt.contains("hw_modesto") or txt.contains("--write-movie") or a.contains("/so/ren_") or a.contains("/so/vis_")
		var lineas := txt.split("\n")
		for i in lineas.size():
			if not con_pantalla and re.search(lineas[i]) != null:
				sospechosas.append("%s:%d" % [a.trim_prefix("res://pruebas/"), i + 1])
	_comprobar(sospechosas.is_empty(), "%d afirmaciones sobre FPS/tiempo de fotograma sin comprobar que haya pantalla: %s" % [sospechosas.size(), str(sospechosas.slice(0, 6))])
