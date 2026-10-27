extends BaseIdea
## EL DESAFÍO «SIN RED» (27-10-2026, fila 971): no se puede volver a un guardado anterior.

func _probar() -> void:
	_titulo("DESAFÍOS · SIN RED: SIN VOLVER ATRÁS")
	var m := Mundo.new()
	m.generar(["CHI"], 52)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	_comprobar(Partida.ranura_para(m, "ranura_2") == "ranura_2" and Partida.motivo_sin_cargar(m) == "", "sin el desafío todo es como siempre: ranuras libres y cargar permitido")
	m.desafios.append("sinRecarga")
	for n in ["ranura_1", "ranura_2", "ranura_3", "partida"]:
		_comprobar(Partida.ranura_para(m, n) == Partida.RANURA_UNICA, "guardar en «%s» usa la única ranura (%s)" % [n, Partida.ranura_para(m, n)])
	var veto := Partida.motivo_sin_cargar(m)
	_comprobar(veto.contains("Sin red"), "cargar queda vetado con su motivo: %s" % veto)
	_comprobar(Partida.ranura_para(null, "x") == "x" and Partida.motivo_sin_cargar(null) == "", "sin partida no molesta")
	var m3 := Partida.desde_instantanea(Partida.instantanea(m))
	_comprobar(Partida.motivo_sin_cargar(m3) != "", "y tras guardar y cargar el desafío sigue ahí")
