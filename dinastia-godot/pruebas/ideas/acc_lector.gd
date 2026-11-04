extends BaseIdea
## M-284 (2-11): la lectura de pantalla (voz del sistema) lee el control que toma el foco cuando está encendida.
##   herramientas/ideas.sh acc_lector

func _probar() -> void:
	_titulo("M-284: LECTURA DE PANTALLA")
	var b := Button.new()
	b.text = "⚽ Guardar"
	b.tooltip_text = "Guarda la partida en la ranura actual."
	_comprobar(LectorPantalla.texto_de(b) == "Guardar. Guarda la partida en la ranura actual.", "de un botón lee el rótulo sin icono y su ayuda (%s)" % LectorPantalla.texto_de(b))
	var le := LineEdit.new()
	le.placeholder_text = "Nombre del club"
	_comprobar(LectorPantalla.texto_de(le) == "Nombre del club", "de un campo vacío lee la pista")
	var ch := CheckButton.new()
	ch.text = "Autoguardado"
	ch.button_pressed = true
	_comprobar(LectorPantalla.texto_de(ch) == "Autoguardado. activado", "de un interruptor lee su estado")
	## A4 (accesibilidad al límite): lo que no tiene rótulo se nombra por su contexto.
	var fila := HBoxContainer.new()
	add_child(fila)
	var et := Label.new()
	et.text = "Color del bus"
	fila.add_child(et)
	var cp := ColorPickerButton.new()
	fila.add_child(cp)
	_comprobar(LectorPantalla.texto_de(cp) == "Color del bus", "un selector de color se nombra por la etiqueta de su fila (%s)" % LectorPantalla.texto_de(cp))
	var tarjeta := Button.new()
	var lt := Label.new()
	lt.text = "Próximo partido"
	tarjeta.add_child(lt)
	add_child(tarjeta)
	_comprobar(LectorPantalla.texto_de(tarjeta) == "Próximo partido", "un botón-tarjeta lee las etiquetas que lleva dentro (%s)" % LectorPantalla.texto_de(tarjeta))
	var simbolos := HFlowContainer.new()
	add_child(simbolos)
	var emoji := Button.new()
	emoji.text = "🌋"
	emoji.toggle_mode = true
	emoji.button_pressed = true
	simbolos.add_child(Button.new())
	simbolos.add_child(emoji)
	_comprobar(LectorPantalla.texto_de(emoji) == "Opción 2 de 2. elegida", "un botón de solo emoji dice su lugar y si está elegido (%s)" % LectorPantalla.texto_de(emoji))
	fila.free()
	tarjeta.free()
	simbolos.free()
	var antes := LectorPantalla.activo()
	LectorPantalla.fijar(true)
	_comprobar(LectorPantalla.activo(), "el interruptor se guarda")
	LectorPantalla._activo = -1
	_comprobar(LectorPantalla.activo(), "y se vuelve a leer del archivo")
	LectorPantalla.decir("prueba")
	_comprobar(not LectorPantalla._hay_voz(), "sin pantalla no hay voz y no se queja")
	LectorPantalla.fijar(antes)
	b.free()
	le.free()
	ch.free()
