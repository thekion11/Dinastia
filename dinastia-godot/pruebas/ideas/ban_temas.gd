extends BaseIdea
## M-296 (28-10-2026): la bandeja de avisos se filtra por tema (`CategoriaAviso`).
##   herramientas/ideas.sh ban_temas

func _ready() -> void:
	await get_tree().process_frame
	_titulo("M-296: BANDEJA POR TEMAS")
	_comprobar(CategoriaAviso.de("Firmado: Pérez") == "mercado" and CategoriaAviso.de("Lesión en entrenamiento") == "plantel"
		and CategoriaAviso.de("Llega la camada juvenil") == "cantera" and CategoriaAviso.de("PLAYOFFS POR EL TÍTULO 2027") == "competicion"
		and CategoriaAviso.de("Crédito concedido") == "club" and CategoriaAviso.de("🎙 Rueda de prensa") == "prensa"
		and CategoriaAviso.de("Llaman del colegio") == "vida", "cada título cae en su tema")
	var pr: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(pr)
	pr._bandeja.clear()
	for t: String in ["Firmado: Pérez", "Renovado: Soto", "Lesión en entrenamiento", "Crédito concedido"]:
		pr._bandeja.append({"titulo": t, "cuerpo": "x", "semana": 1, "anio": 2026, "leida": false})
	var g := pr._ui_gente
	g._correo_tema = "mercado"
	g._pintar_correo()
	var titulos: Array[String] = []
	for h in pr._lista_correo.get_children():
		if h is Button and (h as Button).flat:
			titulos.append((h as Button).text)
	_comprobar(titulos.size() == 2 and titulos[0].contains("Firmado"), "con «Mercado» solo salen los dos de mercado (%s)" % str(titulos))
	var chips := 0
	for h in pr._lista_correo.get_children():
		if h is HFlowContainer:
			chips = h.get_child_count()
	_comprobar(chips == 4, "fila de temas: todos + mercado + plantel + club (%d)" % chips)
	pr.queue_free()
	await get_tree().process_frame
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
