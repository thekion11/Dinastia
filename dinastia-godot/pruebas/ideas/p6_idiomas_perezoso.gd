extends BaseIdea
## (3-11, memoria en el móvil) Solo se carga la tabla del idioma elegido: en castellano ninguna; al cambiar se carga la nueva y el origen de lo ya pintado sigue funcionando.

func _probar() -> void:
	_titulo("P6: IDIOMAS CARGADOS BAJO DEMANDA")
	var antes := Idiomas.idioma
	Idiomas._cargados.clear()
	Idiomas._extra.clear()
	Idiomas._inverso.clear()
	Idiomas.idioma = "es"
	_comprobar(Idiomas._cargados.is_empty(), "en castellano no se carga ninguna tabla")
	_comprobar(Idiomas.t("Plantel") == "Plantel", "y el castellano sale tal cual")
	Idiomas.idioma = "en"
	_comprobar(Idiomas._cargados.size() == 1 and Idiomas._cargados.has("en"), "al elegir inglés solo se carga el inglés (%s)" % str(Idiomas._cargados.keys()))
	_comprobar(Idiomas.t("Plantel") == "Squad", "traduce (Plantel → %s)" % Idiomas.t("Plantel"))
	Idiomas.idioma = "fr"
	_comprobar(Idiomas._cargados.has("fr") and Idiomas._cargados.has("en") and Idiomas._cargados.size() == 2, "al pasar a francés se suma el francés")
	_comprobar(Idiomas.origen("Squad") == "Plantel", "el origen de un texto ya pintado en inglés se encuentra (%s)" % Idiomas.origen("Squad"))
	_comprobar(Idiomas.origen("Effectif") == "Plantel", "y el de uno en francés (%s)" % Idiomas.origen("Effectif"))
	Idiomas.idioma = "es"
	_comprobar(Idiomas.t("Plantel") == "Plantel", "al volver al castellano, castellano")
	Idiomas._asegurar_todos()
	_comprobar(Idiomas._cargados.size() == Idiomas.ORDEN.filter(func(k): return k != "es").size(), "_asegurar_todos carga todos los traducidos (%d)" % Idiomas._cargados.size())
	Idiomas.idioma = antes
