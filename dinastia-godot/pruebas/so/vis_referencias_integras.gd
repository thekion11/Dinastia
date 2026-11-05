extends "res://pruebas/so/vis_base.gd"
## VISUALIZACIÓN · las referencias de las pruebas visuales están sanas: las 20 del recorrido (`pruebas/visual/referencias/`) y las de esta
## carpeta existen, se leen como JPG del tamaño esperado, no están vacías ni repetidas, y no sobra ninguna sin pantalla que la use.
func _nombre() -> String:
	return "vis_referencias_integras"

func _probar() -> void:
	_titulo("VISUALIZACIÓN · referencias sanas [%s]" % sistema())
	var d := DirAccess.open("res://pruebas/visual/referencias")
	_comprobar(d != null, "existe pruebas/visual/referencias")
	var vistas := {}
	var n := 0
	if d != null:
		for f: String in d.get_files():
			if not f.ends_with(".jpg"):
				continue
			n += 1
			var img := Image.load_from_file("res://pruebas/visual/referencias/" + f)
			_comprobar(img != null and img.get_width() == 640 and img.get_height() == 360, "%s mide 640x360" % f)
			if img == null:
				continue
			var e := _estadisticas(img)
			_comprobar(float(e["desv"]) > 0.02 and int(e["colores"]) >= 15, "%s no está vacía (desv %.3f, %d tonos)" % [f, e["desv"], e["colores"]])
			var h := img.get_data().hex_encode().md5_text()
			_comprobar(not vistas.has(h), "%s no es copia exacta de otra" % f)
			vistas[h] = f
	_comprobar(n == 20, "hay 20 referencias del recorrido (%d)" % n)
	if FileAccess.file_exists("res://pruebas/visual/visual.gd"):
		var fuente := FileAccess.get_file_as_string("res://pruebas/visual/visual.gd")
		var re := RegEx.create_from_string("\\[\"([a-z_]+)\", \"[^\"]+\", \"[^\"]*\"\\]")
		var nombres := {}
		for m in re.search_all(fuente.substr(fuente.find("const PANTALLAS"), 1500)):
			nombres[m.get_string(1)] = true
		_comprobar(nombres.size() == 20, "visual.gd lista 20 pantallas (%d)" % nombres.size())
		var sobran: Array[String] = []
		var faltan: Array[String] = []
		for k in nombres:
			if not FileAccess.file_exists("res://pruebas/visual/referencias/%s.jpg" % k):
				faltan.append(k)
		for h in vistas.values():
			if not nombres.has(String(h).get_basename()):
				sobran.append(h)
		_comprobar(faltan.is_empty() and sobran.is_empty(), "cada pantalla tiene su referencia y no sobra ninguna (faltan %s, sobran %s)" % [str(faltan), str(sobran)])
	var r := DirAccess.open("res://pruebas/so/referencias")
	if r != null:
		for f: String in r.get_files():
			if f.ends_with(".jpg"):
				var img := Image.load_from_file("res://pruebas/so/referencias/" + f)
				_comprobar(img != null and float(_estadisticas(img)["desv"]) > 0.02, "%s (propia) se lee y no está vacía" % f)
