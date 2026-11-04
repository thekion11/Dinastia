extends BaseIdea
## U6 (3-11): el coste del viaje y del día de partido, DESGLOSADO a la vista. Las líneas de la previa (fuera y en casa) y la de Finanzas salen de los mismos números que se
## descuentan de la caja (`Viajes`): la suma de las partes es el total, y las frases están traducidas a los 8 idiomas.

func _ready() -> void:
	await get_tree().process_frame
	_titulo("U6 · COSTE DEL VIAJE Y DEL DÍA DE PARTIDO")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var c: Club = m.ligas[0].clubes[0]
	var v := Viajes.viaje_euros("CHI", "ESP", c.rep)
	_comprobar(absf(float(v["transporte"]) + float(v["hotel"]) + float(v["dietas"]) - float(v["total"])) < 0.01, "transporte + hotel + dietas = total (%.0f)" % float(v["total"]))
	var fuera := Viajes.linea_previa_fuera("Madrid FC", v)
	_comprobar(fuera.contains("Madrid FC") and fuera.contains(str(int(v["km"]))) and fuera.contains("%d" % int(v["noches"])), "la previa de un partido fuera dice adónde, km y noches: %s" % fuera)
	var d := Viajes.dia_de_partido_euros("CHI", 20000, 30000)
	_comprobar(absf(float(d["seguridad"]) + float(d["limpieza"]) + float(d["personal"]) + float(d["sanitario"]) + float(d["apertura"]) - float(d["total"])) < 0.01, "el día de partido suma sus cinco partes")
	_comprobar(Viajes.linea_previa_casa(d).contains("seguridad"), "la previa en casa desglosa el día de partido")
	var f := Viajes.linea_finanzas(Viajes.viaje_euros("CHI", "CHI", c.rep))
	_comprobar(f.contains("km") and f.contains("="), "la línea de Finanzas desglosa un viaje típico: %s" % f)
	_comprobar(Viajes.nombre_medio("bus") == "autocar" and Viajes.nombre_medio("avion") == "avión" and Viajes.nombre_medio("charter") == "chárter", "los tres medios tienen nombre")
	var json := JSON.parse_string(FileAccess.get_file_as_string("res://datos/idiomas_extra.json")) as Dictionary
	for clave: String in ["autocar", "avión", "chárter", "✈ Viaje a %s: %d km en %s, %d noche(s) de hotel, delegación de %d personas. Transporte %s + hotel %s + dietas %s = %s.",
			"🏟 Día de partido en casa: seguridad %s + limpieza %s + personal %s + sanitario %s + apertura %s = %s.",
			"Un viaje típico por tu país: %d km en %s, %d noche(s), %d personas (transporte %s + hotel %s + dietas %s = %s)."]:
		var ok := true
		for l: String in ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]:
			ok = ok and (json[l] as Dictionary).has(clave) and String((json[l] as Dictionary)[clave]).count("%") == clave.count("%")
		_comprobar(ok, "traducida a los 8 idiomas con los mismos %%: «%s»" % clave.substr(0, 36))
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
