extends BaseSO
## RENDIMIENTO · peso de los recursos: ningún archivo suelto de res://datos, res://ui o res://nucleo pasa de lo que el sistema carga bien (el JSON de
## idiomas es el mayor, ~46 MB cargados al arrancar si se pidieran todos: aquí se vigila el tamaño en disco), el total de datos no se dispara y los .ogg
## de interfaz son pequeños. Lee tamaños (FileAccess), así que corre igual desde el proyecto y desde un export; en Web el límite de datos es el más bajo.
func _nombre() -> String:
	return "ren_peso_archivos"

func _recorrer(ruta: String, hasta: Array) -> void:
	var d := DirAccess.open(ruta)
	if d == null:
		return
	for f: String in d.get_files():
		if f.ends_with(".import") or f.ends_with(".uid"):
			continue
		var f2 := FileAccess.open(ruta.path_join(f), FileAccess.READ)
		if f2 != null:
			hasta.append([ruta.path_join(f), f2.get_length()])
	for s: String in d.get_directories():
		_recorrer(ruta.path_join(s), hasta)

func _probar() -> void:
	_titulo("RENDIMIENTO · peso de archivos [%s]" % sistema())
	var datos: Array = []
	_recorrer("res://datos", datos)
	_comprobar(datos.size() >= 15, "res://datos tiene %d archivos legibles" % datos.size())
	datos.sort_custom(func(a, b): return a[1] > b[1])
	var total := 0
	for f in datos:
		total += int(f[1])
	var mayor_mb := float(datos[0][1]) / 1048576.0
	print("  INFO  mayor: %s (%.1f MB) · total datos %.1f MB" % [datos[0][0], mayor_mb, total / 1048576.0])
	var tope_archivo := float(por_so({"web": 60.0, "movil": 80.0, "defecto": 120.0}))
	var tope_total := float(por_so({"web": 150.0, "movil": 200.0, "defecto": 400.0}))
	_comprobar(mayor_mb < tope_archivo, "el archivo de datos más grande pesa %.1f MB < %.0f MB" % [mayor_mb, tope_archivo])
	_comprobar(total / 1048576.0 < tope_total, "los datos pesan %.1f MB en total < %.0f MB (tope de %s)" % [total / 1048576.0, tope_total, sistema()])
	var sonidos: Array = []
	_recorrer("res://audio/ui", sonidos)
	var gordos := 0
	for s in sonidos:
		gordos += int(int(s[1]) > 300 * 1024)
	_comprobar(sonidos.size() >= 5 and gordos == 0, "%d sonidos de interfaz, ninguno de más de 300 KB (%d grandes)" % [sonidos.size(), gordos])
	var codigo: Array = []
	for c in ["res://nucleo", "res://ui", "res://visor"]:
		_recorrer(c, codigo)
	var gd := 0
	var mayor_gd := 0
	for f in codigo:
		if String(f[0]).ends_with(".gd"):
			gd += 1
			mayor_gd = maxi(mayor_gd, int(f[1]))
	if gd > 0:
		_comprobar(mayor_gd < 90 * 1024, "el script más grande pesa %d KB (< 90 KB; la norma de 450 líneas lo mantiene pequeño)" % (mayor_gd / 1024))
	else:
		print("  (en %s el código va compilado: no hay .gd que medir)" % sistema())
