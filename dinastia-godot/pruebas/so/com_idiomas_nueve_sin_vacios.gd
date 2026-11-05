extends BaseSO
## COMÚN · los 9 idiomas (es + 8) están completos: ninguna clave vacía, mismos marcadores de formato (%s, %d) y mismos grupos ($1, $2)
## en cada patrón que en la frase original. Lee `datos/idiomas_extra.json` en bruto: así lo ve cualquier sistema, también Web (res:// empaquetado).
func _nombre() -> String:
	return "com_idiomas_nueve_sin_vacios"

func _marcas(t: String) -> Array:
	var r := RegEx.new()
	r.compile("%[sdif]|%[0-9.]*[sdf]")
	var out: Array = []
	for m in r.search_all(t):
		out.append(m.get_string())
	out.sort()
	return out

func _probar() -> void:
	_titulo("COMÚN · 9 idiomas completos")
	var crudo := FileAccess.get_file_as_string("res://datos/idiomas_extra.json")
	_comprobar(crudo.length() > 100000, "idiomas_extra.json se lee entero (%d bytes) en %s" % [crudo.length(), sistema()])
	var d: Variant = JSON.parse_string(crudo)
	_comprobar(d is Dictionary, "es un diccionario JSON válido")
	if not (d is Dictionary):
		return
	_comprobar(Idiomas.ORDEN.size() == 8, "hay 8 idiomas además del castellano (%d): 9 y no más" % Idiomas.ORDEN.size())
	var n_ref := -1
	for idi: String in Idiomas.ORDEN:
		var tabla: Dictionary = (d as Dictionary).get(idi, {})
		_comprobar(tabla.size() > 5000, "%s: tabla con %d frases" % [idi, tabla.size()])
		if n_ref < 0:
			n_ref = tabla.size()
		_comprobar(tabla.size() == n_ref, "%s: mismo número de frases que los demás (%d = %d)" % [idi, tabla.size(), n_ref])
		var vacias := 0
		var formato := 0
		for k: String in tabla:
			var v := String(tabla[k])
			if v.strip_edges() == "":
				vacias += 1
			elif _marcas(k) != _marcas(v):
				formato += 1
		_comprobar(vacias == 0, "%s: sin traducciones vacías (%d)" % [idi, vacias])
		_comprobar(formato == 0, "%s: mismos marcadores %%s/%%d que el original (%d distintos)" % [idi, formato])
	var pats: Array = (d as Dictionary).get("patrones", [])
	_comprobar(pats.size() > 100, "hay patrones con grupos (%d)" % pats.size())
	var malos := 0
	for fila: Array in pats:
		var re := RegEx.new()
		if re.compile(String(fila[0])) != OK:
			malos += 1
			continue
		var grupos := re.get_group_count()
		for i in range(1, fila.size()):
			var txt := String(fila[i])
			var ok := txt != ""
			for g in range(1, grupos + 1):
				ok = ok and txt.contains("$%d" % g)
			if not ok:
				malos += 1
	_comprobar(malos == 0, "cada patrón compila y usa en los 8 idiomas todos sus grupos ($1…) (%d fallos)" % malos)
