extends BaseIdea
## A4-INT · la caché de `Idiomas.t` tiene tope: 60.000 frases distintas (nombres y cifras que no se repiten) no la dejan crecer sin fin, y lo traducido sigue bien.
func _probar() -> void:
	_titulo("AUDITORÍA 4 · caché de Idiomas.t acotada")
	Idiomas._asegurar_todos()
	Idiomas.idioma = "en"
	var antes: Dictionary = Idiomas._cache.get("en", {})
	for i in 60000:
		Idiomas.t("Jornada %d de 30 · Racha %d" % [i, i * 7])
	var cache: Dictionary = Idiomas._cache.get("en", {})
	_comprobar(cache.size() <= Idiomas.TOPE_CACHE, "tras 60.000 frases distintas la caché tiene %d (tope %d)" % [cache.size(), Idiomas.TOPE_CACHE])
	_comprobar(Idiomas.t("Plantel") == "Squad" or Idiomas.t("Plantel") != "Plantel", "y sigue traduciendo («Plantel» → %s)" % Idiomas.t("Plantel"))
	_comprobar(Idiomas.t("Jornada 3 de 30") != "Jornada 3 de 30", "incluidos los patrones con números (%s)" % Idiomas.t("Jornada 3 de 30"))
	Idiomas.idioma = "es"
