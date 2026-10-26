extends BaseIdea
## GLOBO, «SI CREAS UN CLUB, NO SE MUESTRAN LOS DEMÁS» (plan del lunes §3.2, 26-10): lo que
## `f1g_pais` no cubría. Con un MUNDO ya generado (que sí trae clubes con id) y cambiando de
## país, en el modo de crear club la ficha no construye ni un botón de club ni emite `club_id`;
## también cuando el modo llega como el orquestador lo deja (texto «creador») o dentro del
## diccionario del país. Y en el modo normal, con el mismo mundo, sí se ven (control).

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	await get_tree().process_frame
	_titulo("GLOBO (fz0): crear club no enseña los clubes del país")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 4242)
	for estado: Dictionary in [{"modo": "creador", "mundo": m, "pais": "ARG"},
			{"modo": {"id": "creador"}, "mundo": m, "pais": "CHI"},
			{"modo": "dt", "pais": {"pais": "CHI", "crear": true}, "mundo": m}]:
		var s := _nueva(estado)
		await get_tree().process_frame
		s.sin_animaciones()
		var vistos := _botones_club(s)
		_comprobar(s.crear and vistos == 0 and s.ficha().clubes_listados.is_empty(),
			"crear club (%s): ni un botón de club en %s (%d)" % [str(estado["modo"]), s.pais, vistos])
		## Cambiar de país tampoco los trae.
		for p: String in ["ARG", "CHI"]:
			s._elegir(p, true)
			await get_tree().process_frame
			_comprobar(_botones_club(s) == 0 and not s.datos().has("club_id"),
				"crear club: tras pasar a %s sigue sin clubes y sin club_id" % p)
		s.get_parent().queue_free()
	var n := _nueva({"modo": "dt", "mundo": m, "pais": "ARG"})
	await get_tree().process_frame
	n.sin_animaciones()
	_comprobar(not n.crear and _botones_club(n) > 0 and n.datos().has("club_id"),
		"control: en el modo normal con el mismo mundo sí se listan (%d)" % _botones_club(n))
	n.get_parent().queue_free()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _nueva(estado: Dictionary) -> PantallaPais:
	var caja := Control.new()
	add_child(caja)
	caja.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var s := PantallaPais.new()
	s.configurar(estado)
	caja.add_child(s)
	return s

func _botones_club(s: PantallaPais) -> int:
	var k := 0
	for b in s.find_children("*", "Button", true, false):
		if b.has_meta("club"):
			k += 1
	return k
