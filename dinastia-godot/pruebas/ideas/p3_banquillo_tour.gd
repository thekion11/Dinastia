extends BaseIdea
## SUPLENTES EN EL BANQUILLO DE LA VISITA (27-10-2026): el estadio de la ciudad lleva a los cinco mejores suplentes sentados.

func _probar() -> void:
	_titulo("BANQUILLO · SUPLENTES SENTADOS EN LA VISITA AL ESTADIO")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var club: Club = m.ligas[0].clubes[0]
	var estadio := Node3D.new()
	add_child(estadio)
	_comprobar(BanquilloTour.montar(estadio, null).is_empty() and BanquilloTour.montar(null, club).is_empty(), "sin club o sin recinto no se monta nada")
	var antes := estadio.get_child_count()
	var cuerpos := BanquilloTour.montar(estadio, club)
	_comprobar(cuerpos.size() == BanquilloTour.CUANTOS, "se sientan %d suplentes (%d)" % [BanquilloTour.CUANTOS, cuerpos.size()])
	_comprobar(estadio.get_child_count() > antes, "los cuerpos y su banco cuelgan del recinto")
	var x_ok := true
	for c in cuerpos:
		var n: Node3D = c["node"] as Node3D
		if n == null or absf(n.position.x) < 30.0:
			x_ok = false
	_comprobar(x_ok, "todos quedan junto a la banda, fuera del césped")
