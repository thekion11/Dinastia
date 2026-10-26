extends BaseIdea
## SESIÓN 6 (26-10-2026), plan §10: la pantalla «Novedades» lee `datos/novedades.json`,
## enseña la versión del proyecto (M-429), recuerda si ya se vio, se cierra con Esc
## y todas sus frases están en los 9 idiomas. Se abre desde el pie del menú de modos.

func _probar() -> void:
	_titulo("S6: NOVEDADES (notas de versión)")
	var vs := PantallaNovedades.leer()
	_comprobar(not vs.is_empty() and String((vs[0] as Dictionary).get("version", "")) == PantallaNovedades.version() and PantallaNovedades.version() == "0.9.0",
		"el JSON abre con las notas de la versión del proyecto (%s)" % PantallaNovedades.version())
	_comprobar(PantallaNovedades.leer("res://datos/no_existe.json").is_empty(), "sin archivo no se rompe: lista vacía")
	## Todas las frases, traducidas en los ocho idiomas.
	var frases: Array[String] = ["Novedades", "Versión %s", "Cerrar"]
	for v: Dictionary in vs:
		frases.append(String(v["titulo"]))
		for s: Dictionary in v["secciones"]:
			frases.append(String(s["titulo"]))
			for p: String in s["puntos"]:
				frases.append(p)
	var faltan: Array[String] = []
	for l in ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]:
		Idiomas.idioma = l
		for f in frases:
			if Idiomas.t(f) == f:
				faltan.append("%s: %s" % [l, f.left(30)])
	Idiomas.idioma = "es"
	_comprobar(faltan.is_empty(), "las %d frases están en los 8 idiomas %s" % [frases.size(), str(faltan.slice(0, 4))])
	## Visto / sin ver.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PantallaNovedades.VISTAS))
	_comprobar(PantallaNovedades.hay_sin_ver(), "sin haberlas abierto, el botón lleva el punto de «sin ver»")
	var n := PantallaNovedades.abrir(self)
	var textos := ""
	for l in n.find_children("*", "Label", true, false):
		textos += (l as Label).text + "\n"
	var puntos := 0
	for v2: Dictionary in vs:
		for s2: Dictionary in v2["secciones"]:
			puntos += (s2["puntos"] as Array).size()
	_comprobar(textos.contains("Versión 0.9.0") and textos.count("•  ") == puntos, "la pantalla enseña la versión y los %d puntos" % puntos)
	_comprobar(not PantallaNovedades.hay_sin_ver(), "al abrirla quedan vistas")
	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	n._unhandled_input(esc)
	_comprobar(n.is_queued_for_deletion(), "Esc la cierra")
	## El botón del pie del menú de modos.
	var menu := PantallaModos.new()
	add_child(menu)
	var boton: Button = null
	for b in menu.find_children("*", "Button", true, false):
		if (b as Button).text.contains("Novedades"):
			boton = b
	_comprobar(boton != null and boton.text.contains("0.9.0"), "el menú de modos tiene «✨ Novedades 0.9.0» en el pie")
	if boton != null:
		boton.pressed.emit()
		_comprobar(menu._algo_abierto() and menu.get_node_or_null("Novedades") != null, "y al pulsarlo se abre encima (las flechas del menú quedan quietas)")
	menu.queue_free()
