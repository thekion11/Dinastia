extends BaseIdea
## El DT sube al bus «Red»: solo con un bus parado junto al paradero, y baja 3 paradas más allá de su recorrido.

func _probar() -> void:
	_titulo("P6: EL DT SUBE AL BUS Y PAGA")
	var num: String = RecorridosMapa.servicios()[0]
	var lista: Array = RecorridosMapa.servicio(num)["paraderos"]
	var cod := String(lista[0])
	var dest := BusDT.destino(num, cod)
	_comprobar(dest != "" and dest != cod and dest == String(lista[mini(BusDT.PARADAS, lista.size() - 1) % lista.size()]), "desde %s en el %s se baja en %s (%d paradas más allá)" % [cod, num, dest, BusDT.PARADAS])
	_comprobar(BusDT.destino(num, "PA9999") == "", "un paradero por el que no pasa el recorrido no vale")
	var pa := Node3D.new()
	pa.add_to_group("paradero_red")
	pa.set_meta("codigo_red", cod)
	add_child(pa)
	pa.global_position = Vector3(100, 0, 100)
	_comprobar(BusDT.detectar(get_tree(), Vector3(100, 0, 102)).is_empty(), "sin autobús parado no se ofrece subir")
	var bus := Node3D.new()
	bus.add_to_group("bus_red")
	bus.set_meta("red_recorrido", num)
	add_child(bus)
	bus.global_position = Vector3(106, 0, 100)
	var d := BusDT.detectar(get_tree(), Vector3(100, 0, 102))
	_comprobar(not d.is_empty() and String(d["tipo"]) == "bus_parada" and String(d["num"]) == num, "con el bus junto a la marquesina aparece «subir al bus %s»" % num)
	_comprobar(BusDT.detectar(get_tree(), Vector3(100, 0, 110)).is_empty(), "lejos del paradero (8 m) tampoco")
	bus.global_position = Vector3(140, 0, 100)
	_comprobar(BusDT.detectar(get_tree(), Vector3(100, 0, 102)).is_empty(), "el bus que ya se fue (40 m) no cuenta")
	var c := CarteraDT.new()
	c.saldo_transporte = 1
	_comprobar(c.pagar_pasaje("bus") == "" and c.saldo_transporte == 0 and c.pagar_pasaje("bus") == "saldo", "el pasaje de bus sale de la tarjeta y sin saldo no se sube")
	## La app Red enseña el saldo.
	var mu := Mundo.new()
	mu.generar(["CHI"], 4713)
	mu.tomar_el_mando(mu.ligas[0].clubes[0].id)
	mu.roles.cartera.saldo_transporte = 7
	_comprobar(AppRed.saldo_tarjeta(mu) == 7 and AppRed.saldo_tarjeta(null) == -1, "la app Red lee el saldo de la tarjeta (7 €)")
