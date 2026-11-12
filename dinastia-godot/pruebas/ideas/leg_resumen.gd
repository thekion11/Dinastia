extends BaseIdea
## M-311 (28-10-2026): «TU CARRERA» arriba de Legado cuenta también los partidos simulados (G-E-P, goles, %).
##   herramientas/ideas.sh leg_resumen

func _ready() -> void:
	await get_tree().process_frame
	_titulo("M-311: RESUMEN DE CARRERA EN LEGADO")
	var pr: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(pr)
	for i in 8:
		pr.mundo.avanzar_semana()
	var c: Dictionary = pr.mundo.logros.carrera
	_comprobar(int(c.get("pj", 0)) >= 5 and int(c.get("pg", 0)) + int(c.get("pe", 0)) + int(c.get("pp", 0)) == int(c["pj"]),
		"8 semanas simuladas: %d partidos y G+E+P cuadra (%s)" % [int(c.get("pj", 0)), str(c)])
	_comprobar(int(c.get("gf", 0)) + int(c.get("gc", 0)) > 0, "y cuenta goles")
	pr._ui_legado._pintar_records()
	var vals: Array[String] = []
	var banda := pr._lista_records.find_child("CifrasClave", false, false)   ## (12-11) la carrera va en fichas grandes
	for ficha in (banda.get_children() if banda != null else []):
		vals.append((ficha.get_child(0).get_child(1) as Label).text)
	_comprobar(vals.size() == 6 and vals[1] == str(c["pj"]), "la fila de Legado enseña esos partidos (%s)" % str(vals))
	pr.queue_free()
	await get_tree().process_frame
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
