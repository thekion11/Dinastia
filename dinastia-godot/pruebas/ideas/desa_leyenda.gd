extends BaseIdea
## EL MODO LEYENDA (27-10-2026, fila 956): «treinta temporadas en el mismo club, sin cambiarte».

func _probar() -> void:
	_titulo("DESAFÍOS · MODO LEYENDA: UN SOLO CLUB")
	var m := Mundo.new()
	m.generar(["CHI"], 63)
	var clubes: Array = m.ligas[0].clubes
	m.tomar_el_mando(clubes[0].id)
	var otro: String = clubes[1].id
	_comprobar(m.motivo_sin_cambiar_de_club(otro) == "", "sin el desafío se puede cambiar de club")
	m.desafios.append("leyenda30")
	_comprobar(m.motivo_sin_cambiar_de_club(otro) != "", "con «Modo leyenda» no: %s" % m.motivo_sin_cambiar_de_club(otro))
	_comprobar(m.motivo_sin_cambiar_de_club(clubes[0].id) == "", "quedarse en el propio club no es cambiar")
	## Despedido: puede irse, y la leyenda se rompe.
	m.directiva.despedido_ya = true
	_comprobar(m.motivo_sin_cambiar_de_club(otro) == "", "si te despiden, puedes irte")
	m.tomar_el_mando(otro)
	_comprobar(not m.tiene_desafio("leyenda30"), "y el desafío deja de contar (se pierde el multiplicador)")
	## Volver a tomar el mando del mismo club no lo rompe.
	var m2 := Mundo.new()
	m2.generar(["CHI"], 63)
	m2.tomar_el_mando(m2.ligas[0].clubes[0].id)
	m2.desafios.append("leyenda30")
	m2.tomar_el_mando(m2.mi_club_id)
	_comprobar(m2.tiene_desafio("leyenda30"), "reanudar el mismo club no rompe la leyenda")
