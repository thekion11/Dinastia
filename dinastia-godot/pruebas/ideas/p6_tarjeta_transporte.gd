extends BaseIdea
## M-182: tarjeta de transporte Red (recarga desde la cartera, tarifas por modo, sin saldo no se sube, se guarda).

func _probar() -> void:
	_titulo("P6: TARJETA DE TRANSPORTE")
	var m := Mundo.new()
	m.generar(["CHI"], 2026)
	m.mi_club_id = m.ligas[0].clubes[0].id
	var c := CarteraDT.new()
	c.efectivo = 20
	var dia := 5
	_comprobar(c.pagar_pasaje("metro") == "saldo", "sin saldo no se puede pagar el pasaje")
	var r := c.recargar_transporte(m.roles, CarteraDT.RECARGA, dia)
	_comprobar(String(r["error"]) == "" and c.saldo_transporte == 5 and c.efectivo == 15, "recargar 5 € sale del efectivo y entra en la tarjeta (saldo %d, efectivo %d)" % [c.saldo_transporte, c.efectivo])
	_comprobar(c.pagar_pasaje("metro") == "" and c.saldo_transporte == 4, "el metro cuesta %d €" % int(CarteraDT.TARIFAS["metro"]))
	_comprobar(c.pagar_pasaje("teleferico") == "" and c.saldo_transporte == 1, "el teleférico cuesta %d €" % int(CarteraDT.TARIFAS["teleferico"]))
	_comprobar(c.pagar_pasaje("teleferico") == "saldo" and c.saldo_transporte == 1, "con 1 € ya no alcanza para el teleférico y el saldo no cambia")
	var d := c.a_dict()
	var c2 := CarteraDT.new()
	c2.desde_dict(d)
	_comprobar(c2.saldo_transporte == 1, "el saldo se guarda y se carga")
	var vieja := CarteraDT.new()
	vieja.desde_dict({})
	_comprobar(vieja.saldo_transporte == 0, "una partida vieja empieza con la tarjeta a 0")
	var c3 := CarteraDT.new()
	c3.efectivo = 0
	m.roles.patrimonio = 0
	var r3 := c3.recargar_transporte(m.roles, CarteraDT.RECARGA, dia)
	_comprobar(String(r3["error"]) != "" and c3.saldo_transporte == 0, "sin dinero la recarga falla (%s) y no suma saldo" % String(r3["error"]))
