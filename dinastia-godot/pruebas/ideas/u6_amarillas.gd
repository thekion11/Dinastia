extends BaseIdea
## U6 (3-11): AVISO DE «A UNA AMARILLA DE LA SANCIÓN». `Disciplina.a_una` (4, 9, 14… amarillas y sin sanción), `al_borde` del club, la marca 🟨 con su ayuda en Mi plantel,
## y que las dos frases nuevas estén traducidas a los ocho idiomas.

func _ready() -> void:
	await get_tree().process_frame
	_titulo("U6 · AMARILLAS ANTES DE LA SANCIÓN")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var c: Club = m.ligas[0].clubes[0]
	m.mi_club_id = c.id
	var j: Jugador = c.plantilla[3]
	for n in [0, 1, 3, 4, 5, 8, 9, 10, 14]:
		j.amarillas = n
		j.suspension = 0
		var espera: bool = n in [4, 9, 14]
		_comprobar(Disciplina.a_una(j) == espera, "con %d amarillas, a_una = %s" % [n, str(espera)])
	j.amarillas = 4
	j.suspension = 1
	_comprobar(not Disciplina.a_una(j), "ya sancionado no se avisa (4 amarillas con sanción)")
	j.suspension = 0
	_comprobar(Disciplina.al_borde(c).has(j) and Disciplina.al_borde(c).size() == 1, "al_borde del club lista al jugador (%d)" % Disciplina.al_borde(c).size())
	_comprobar(Disciplina.frase_borde(j).contains(j.nombre) and Disciplina.frase_borde(j).contains("4"), "la frase lleva su nombre y cuántas lleva")
	## La marca en Mi plantel.
	var lista := VBoxContainer.new()
	add_child(lista)
	PanelPlantel.pintar(lista, c, m, "ovr", true, Color.GREEN, func(col: Color) -> Color: return col,
		func(g: GridContainer, jj: Jugador, columnas: Array, _co: Array) -> void:
			var b := Button.new()
			b.text = String(columnas[0])
			g.add_child(b),
		func(_k: String) -> void: pass)
	var con_marca := 0
	var con_ayuda := 0
	for b in lista.find_children("*", "Button", true, false):
		if (b as Button).text.contains("🟨"):
			con_marca += 1
			if (b as Control).tooltip_text.contains("amarilla") or (b.get_parent() as Control).tooltip_text.contains("amarilla"):
				con_ayuda += 1
	_comprobar(con_marca == 1, "Mi plantel marca con 🟨 a ese jugador y a nadie más (%d)" % con_marca)
	_comprobar(con_ayuda == 1, "y su ayuda explica la amarilla (%d)" % con_ayuda)
	## Traducciones.
	var json := JSON.parse_string(FileAccess.get_file_as_string("res://datos/idiomas_extra.json")) as Dictionary
	for clave: String in ["%s está a una amarilla de la sanción (%d de %d): si ve otra, se pierde el siguiente partido.", "🟨 A una amarilla de la sanción: %s."]:
		var ok := true
		for l: String in ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]:
			ok = ok and (json[l] as Dictionary).has(clave) and String((json[l] as Dictionary)[clave]).count("%") == clave.count("%")
		_comprobar(ok, "traducida a los 8 idiomas con los mismos %%: «%s»" % clave.substr(0, 40))
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
