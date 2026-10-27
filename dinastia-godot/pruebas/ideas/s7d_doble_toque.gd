extends BaseIdea
## s7d · CONFIRMAR CON UN SEGUNDO TOQUE (M-299, 27-10-2026; `DobleToque`). Vender aceptando una oferta y cesar
## al embajador iban al primer clic. El primer toque arma el botón (aviso en rojo), el segundo ejecuta; si no
## llega, vuelve solo. Y el panel de mercado ya no vende al primer toque.

func _probar() -> void:
	_titulo("S7D: lo que no tiene vuelta pide un segundo toque")
	var b := Button.new()
	b.text = "Aceptar"
	add_child(b)
	var hechas := [0]
	var accion := func() -> void: hechas[0] += 1
	_comprobar(not DobleToque.pulsar(b, "¿Seguro?", accion) and hechas[0] == 0, "el primer toque no ejecuta")
	_comprobar(b.text == "¿Seguro?" and DobleToque.armado(b) and b.modulate != Color.WHITE, "arma el botón: aviso en su texto y teñido")
	_comprobar(DobleToque.pulsar(b, "¿Seguro?", accion) and hechas[0] == 1, "el segundo ejecuta")
	_comprobar(b.text == "Aceptar" and not DobleToque.armado(b) and b.modulate == Color.WHITE, "y el botón vuelve a como estaba")
	DobleToque.pulsar(b, "¿Seguro?", accion)
	b.set_meta("doble_hasta", Time.get_ticks_msec() / 1000.0 - 1.0)
	_comprobar(not DobleToque.pulsar(b, "¿Seguro?", accion) and hechas[0] == 1, "pasado el plazo, el toque vuelve a ser el primero")
	DobleToque.desarmar(b)
	## Con la señal de verdad del botón.
	var b2 := Button.new()
	b2.text = "Cesar"
	add_child(b2)
	DobleToque.conectar(b2, "¿Cesarlo?", accion)
	b2.pressed.emit()
	_comprobar(hechas[0] == 1 and b2.text == "¿Cesarlo?", "conectado: una pulsación solo avisa")
	b2.pressed.emit()
	_comprobar(hechas[0] == 2 and b2.text == "Cesar", "y la segunda cesa")
	_panel_mercado()
	b.free()
	b2.free()

## El panel de mercado con una oferta recibida: el botón «Aceptar» necesita dos toques para emitir la venta.
func _panel_mercado() -> void:
	var m := _mundo(6161)
	var c := m.mi_club()
	var j: Jugador = c.plantilla[0]
	var comprador: Club = m.ligas[0].clubes[1]
	m.mercado.ofertas_recibidas.append({"jugador": j, "club": comprador, "monto": 1000000})
	var pm := PanelMercado.new()
	add_child(pm)
	var emitidas: Array = []
	pm.oferta_respondida.connect(func(i: int, si: bool) -> void: emitidas.append([i, si]))
	pm.inicializar(m, {})
	pm.pintar()
	var acepta: Button = null
	for n: Node in pm.find_children("*", "Button", true, false):
		if (n as Button).text == Idiomas.t("Aceptar"):
			acepta = n
	_comprobar(acepta != null, "mercado: la oferta recibida sale con su botón «Aceptar»")
	if acepta == null:
		pm.queue_free()
		return
	acepta.pressed.emit()
	_comprobar(emitidas.is_empty(), "mercado: un toque en «Aceptar» no vende")
	acepta.pressed.emit()
	_comprobar(emitidas == [[0, true]], "mercado: el segundo vende (%s)" % str(emitidas))
	pm.queue_free()
