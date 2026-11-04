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
