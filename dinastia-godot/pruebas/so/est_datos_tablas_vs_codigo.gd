extends BaseSO
## ESTÁNDAR · datos ↔ código: toda tabla que el código pide con `Datos.tabla("X")` existe en tablas.json (una que falta devuelve null y revienta
## más tarde, en pantalla). Lee el código fuente, que solo está disponible al correr desde el proyecto (Linux/Windows/macOS con editor);
## en un export (Android/Web/builds) el código va compilado, y entonces la expectativa propia es la inversa: las tablas están todas y no hay fuentes.
func _nombre() -> String:
	return "est_datos_tablas_vs_codigo"

func _fuentes(ruta: String, out: Array) -> void:
	var d := DirAccess.open(ruta)
	if d == null:
		return
	for f: String in d.get_files():
		if f.ends_with(".gd"):
			out.append(ruta.path_join(f))
	for s: String in d.get_directories():
		if not s.begins_with(".") and s != "terceros" and s != "addons":
			_fuentes(ruta.path_join(s), out)

func _probar() -> void:
	_titulo("ESTÁNDAR · tablas pedidas por el código [%s]" % sistema())
	_comprobar(Datos.cuantas() >= 200, "Datos tiene %d tablas cargadas" % Datos.cuantas())
	var hay_fuentes := FileAccess.file_exists("res://nucleo/datos.gd")
	if not hay_fuentes:
		_comprobar(OS.has_feature("template") or not OS.has_feature("editor"), "sin código fuente en res:// solo es normal en un export (%s)" % sistema())
		return
	var re := RegEx.create_from_string("Datos\\.(?:tabla|tiene)\\(\"([A-Z0-9_]+)\"\\)")
	var archivos: Array = []
	for r in ["res://nucleo", "res://ui", "res://visor", "res://escenas", "res://minijuegos"]:
		_fuentes(r, archivos)
	var pedidas := {}
	for a: String in archivos:
		var txt := FileAccess.get_file_as_string(a)
		for m in re.search_all(txt):
			pedidas[m.get_string(1)] = a
	_comprobar(pedidas.size() >= 60, "el código pide %d tablas distintas (%d archivos revisados)" % [pedidas.size(), archivos.size()])
	var faltan: Array[String] = []
	for t: String in pedidas:
		if not Datos.tiene(t):
			faltan.append("%s (en %s)" % [t, String(pedidas[t]).get_file()])
	_comprobar(faltan.is_empty(), "todas las tablas que el código pide existen %s" % str(faltan.slice(0, 6)))
