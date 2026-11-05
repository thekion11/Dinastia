extends BaseSO
## COMÚN · cambiar de idioma en vivo: `Idiomas.t` devuelve algo distinto del castellano en cada idioma, vuelve a castellano sin residuos
## y una frase inventada queda intacta. Cada idioma se pide en un `user://` aislado (no toca preferencias del jugador).
func _nombre() -> String:
	return "com_idiomas_cambio_en_vivo"

func _probar() -> void:
	_titulo("COMÚN · cambio de idioma en vivo")
	_respaldar_user()
	var inventada := "Frase que no existe en ningún diccionario zxq"
	var vistas := {}
	for idi: String in Idiomas.ORDEN:
		_fijar_idioma(idi)
		var a := Idiomas.t("Plantel")
		var b := Idiomas.t("Ajustes")
		_comprobar(a != "" and a != "Plantel", "%s: «Plantel» → «%s»" % [idi, a])
		_comprobar(b != "", "%s: «Ajustes» → «%s»" % [idi, b])
		_comprobar(Idiomas.t(inventada) == inventada, "%s: una frase desconocida queda intacta" % idi)
		_comprobar(Idiomas.t("") == "", "%s: la cadena vacía sigue vacía" % idi)
		vistas[a] = true
	_comprobar(vistas.size() >= 6, "los 8 idiomas dan al menos 6 versiones distintas de «Plantel» (%d)" % vistas.size())
	_fijar_idioma("es")
	_comprobar(Idiomas.t("Plantel") == "Plantel", "en castellano no se traduce nada")
	_comprobar(Idiomas.cobertura("de") > 5000, "cobertura del alemán: %d" % Idiomas.cobertura("de"))
	_restaurar_user()
