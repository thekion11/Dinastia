class_name TecladoPin
## El teclado de PIN que comparten el cajero (`PanelCajero`) y el pago con tarjeta (`PanelPagoPin`): título, los cuatro puntos y las 12 teclas.
## No guarda nada: pinta en `caja` y avisa con `al_tecla(t)` ("0".."9", "⌫" o "✕").
static func pintar(caja: Container, titulo_: String, tecleado: String, al_tecla: Callable) -> void:
	var titulo := Label.new()
	titulo.text = titulo_
	titulo.add_theme_font_size_override("font_size", 19)
	caja.add_child(titulo)
	var pantalla := Label.new()
	pantalla.text = "•".repeat(tecleado.length()) + "·".repeat(4 - tecleado.length())
	pantalla.add_theme_font_size_override("font_size", 34)
	pantalla.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(pantalla)
	var rejilla := GridContainer.new()
	rejilla.columns = 3
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	caja.add_child(rejilla)
	for t in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "⌫", "0", "✕"]:
		var b := Button.new()
		b.text = t
		b.custom_minimum_size = Vector2(120, 54)
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(al_tecla.bind(t))
		rejilla.add_child(b)
