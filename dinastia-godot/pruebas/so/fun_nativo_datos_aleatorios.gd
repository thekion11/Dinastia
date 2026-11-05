extends BaseSO
## FUNCIONES · las funciones puras que existen en C++ y en GDScript, con datos aleatorios (no solo los del juego): rampa de colores con una
## tabla al azar, alisado de normales sobre una malla inventada. Donde hay extensión: bytes idénticos; donde no (Web, macOS), el respaldo
## GDScript cumple las propiedades (tamaño, valores dentro de la tabla, normales unitarias) que cumple el C++.
func _nombre() -> String:
	return "fun_nativo_datos_aleatorios"

func _probar() -> void:
	_titulo("FUNCIONES · nativo con datos aleatorios [%s]" % sistema())
	var nat := Nativo.obj()
	_comprobar((nat != null) == se_espera_nativo(), "extensión %s como se espera en %s" % ["cargada" if nat != null else "ausente", sistema()])
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261105
	for vuelta in 4:
		var img := Image.create_empty(37 + vuelta * 11, 23 + vuelta * 5, false, Image.FORMAT_L8)
		var datos := PackedByteArray()
		datos.resize(img.get_width() * img.get_height())
		for i in datos.size():
			datos[i] = rng.randi() % 256
		img = Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_L8, datos)
		var lut := PackedByteArray()
		lut.resize(1024)
		for i in lut.size():
			lut[i] = rng.randi() % 256
		var a := RuidosFondo._con_rampa_gd(img, lut)
		var b := RuidosFondo._con_rampa(img, lut)
		_comprobar(a.get_data() == b.get_data() and a.get_data().size() == datos.size() * 4, "rampa %d (%dx%d): ruta pública = GDScript y 4 canales por píxel" % [vuelta, img.get_width(), img.get_height()])
		var o := int(datos[0]) * 4
		_comprobar(a.get_data()[0] == lut[o] and a.get_data()[3] == lut[o + 3], "el primer píxel toma su color de la tabla")
	## Alisado sobre una malla de rejilla con alturas al azar.
	var pos := PackedVector3Array()
	var nor := PackedVector3Array()
	var idx := PackedInt32Array()
	var n := 24
	for z in n:
		for x in n:
			pos.append(Vector3(x, rng.randf() * 0.5, z))
			nor.append(Vector3(rng.randf_range(-0.2, 0.2), 1.0, rng.randf_range(-0.2, 0.2)).normalized())
	for z in n - 1:
		for x in n - 1:
			var i0 := z * n + x
			idx.append_array([i0, i0 + n, i0 + 1, i0 + 1, i0 + n, i0 + n + 1])
	var g: Array = VestidorQ._alisado_gd(pos, nor, idx)
	var p: Array = VestidorQ._alisado(pos, nor, idx)
	_comprobar(var_to_bytes(g[0]) == var_to_bytes(p[0]) and var_to_bytes(g[1]) == var_to_bytes(p[1]), "alisado de una malla de %d vértices: ruta pública = GDScript" % pos.size())
	var plano: PackedFloat32Array = p[1]
	var unitarias := plano.size() == nor.size() * 3
	for i in range(0, plano.size() - 2, 3):
		unitarias = unitarias and absf(Vector3(plano[i], plano[i + 1], plano[i + 2]).length() - 1.0) < 0.01
	_comprobar(unitarias, "las normales alisadas (%d valores) siguen siendo unitarias" % plano.size())
