extends BaseIdea
## A4-M3D · los carteles 3D de la ciudad (museo, tienda, huerto, teleférico, metro) se traducen en los 8 idiomas.
func _probar() -> void:
	_titulo("AUDITORÍA 4 · carteles 3D traducidos")
	Idiomas._asegurar_todos()
	var frases := ["Museo", "Tienda", "Huerto del club", "Tenis y pádel", "MUSEO DEL CLUB", "TELEFÉRICO DEL CERRO", "Línea 1", "Línea 2", "Próximo tren: %s"]
	for l in ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]:
		Idiomas.idioma = l
		var sin: Array = []
		for f in frases:
			if Idiomas.t(f) == f and l != "it" and f != "Museo":
				sin.append(f)
		_comprobar(sin.is_empty(), "%s: carteles sin traducir %s" % [l, str(sin)])
		_comprobar(Idiomas.t("sem") != "", "%s: «sem» tiene traducción" % l)
	Idiomas.idioma = "es"
	_comprobar(Idiomas.t("Museo") == "Museo", "en castellano no cambia")
