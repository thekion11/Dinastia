extends BaseIdea
## Cambiar de idioma en partida repinta también los rótulos fijos (26-10-2026, fnt).

func _probar() -> void:
	_titulo("IDIOMAS: cambio en partida sin rótulos viejos (fnt)")
	var antes := Idiomas.idioma
	var raiz := Control.new()
	Idiomas.idioma = "tr"
	var b := Button.new()
	b.text = Idiomas.t("⏭ Un día")
	raiz.add_child(b)
	var l := Label.new()
	l.text = Idiomas.t("Calendario")
	raiz.add_child(l)
	var e := LineEdit.new()
	e.placeholder_text = Idiomas.t("Guardar")
	raiz.add_child(e)
	var nombre := Label.new()
	nombre.text = "Lautaro FC"
	raiz.add_child(nombre)
	_comprobar(b.text != "⏭ Un día" and l.text != "Calendario", "en turco salen traducidos («%s», «%s»)" % [b.text, l.text])
	Idiomas.idioma = "de"
	Idiomas.retraducir_arbol(raiz, "tr")
	_comprobar(b.text == Idiomas.t("⏭ Un día"), "el botón pasa al alemán: «%s»" % b.text)
	_comprobar(l.text == Idiomas.t("Calendario"), "la etiqueta pasa al alemán: «%s»" % l.text)
	_comprobar(e.placeholder_text == Idiomas.t("Guardar"), "el texto de ayuda del campo pasa al alemán: «%s»" % e.placeholder_text)
	_comprobar(nombre.text == "Lautaro FC", "un nombre propio no se toca")
	Idiomas.idioma = "es"
	Idiomas.retraducir_arbol(raiz, "de")
	_comprobar(b.text == "⏭ Un día" and l.text == "Calendario", "y de vuelta al castellano («%s», «%s»)" % [b.text, l.text])
	Idiomas.idioma = "pl"
	Idiomas.retraducir_arbol(raiz, "es")
	_comprobar(l.text == Idiomas.t("Calendario"), "del castellano a otro idioma también: «%s»" % l.text)
	Idiomas.idioma = antes
	raiz.free()
