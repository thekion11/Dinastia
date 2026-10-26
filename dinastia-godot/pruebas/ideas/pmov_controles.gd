extends BaseIdea
## pmov (26-10-2026, M-433): al pasear y conducir, todo lo del teclado tiene
## equivalente con mando y táctil. Antes, con mando no se podía volver al mapa
## (solo Esc), ni cambiar la vista, ni esconder el GPS, ni mirar por la ventana
## del tren; en coche los gatillos no aceleraban; en táctil no había correr,
## freno de mano ni vista.

func _probar() -> void:
	_titulo("PMOV: CONTROLES CON MANDO Y TÁCTIL EN LA CIUDAD")
	var e := ExploradorCiudad.new()
	e.cuerpo = Node3D.new()
	e._aviso = Label.new()
	add_child(e)
	e.set_physics_process(false)
	var salidas := [0]
	e.salir.connect(func() -> void: salidas[0] += 1)

	_boton(e, JOY_BUTTON_START)
	_comprobar(salidas[0] == 1, "Start del mando vuelve al mapa (como Esc)")
	e.modo = "pie"
	_boton(e, JOY_BUTTON_Y)
	_comprobar(e.primera_persona, "Y cambia a primera persona a pie (como V)")
	_boton(e, JOY_BUTTON_Y)
	_comprobar(not e.primera_persona, "y otra vez Y vuelve a tercera")
	e.modo = "coche"
	_boton(e, JOY_BUTTON_Y)
	_comprobar(e.cam_coche == 1, "en coche, Y cambia la cámara (capó: %d)" % e.cam_coche)
	var gps := e._gps_oculto
	_boton(e, JOY_BUTTON_BACK)
	_comprobar(e._gps_oculto != gps, "Select esconde o muestra el GPS (como M)")
	_boton(e, JOY_BUTTON_RIGHT_SHOULDER)
	_comprobar(not e._ventana, "RB fuera del tren no hace nada")
	e.estado = "tren"
	_boton(e, JOY_BUTTON_RIGHT_SHOULDER)
	_comprobar(e._ventana, "RB en el tren mira por la ventana (como C)")
	e.estado = "calle"

	## El teclado sigue igual.
	_tecla(e, KEY_ESCAPE)
	_comprobar(salidas[0] == 2, "Esc sigue volviendo al mapa")
	_tecla(e, KEY_V)
	_comprobar(e.cam_coche == 2, "V sigue cambiando la cámara del coche")

	## Gatillos: RT acelera y LT frena (en coche).
	_eje(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_comprobar(e._entrada().y > 0.9, "RT acelera el coche (entrada %.2f)" % e._entrada().y)
	_eje(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_eje(JOY_AXIS_TRIGGER_LEFT, 0.8)
	_comprobar(e._entrada().y < -0.7, "LT frena (entrada %.2f)" % e._entrada().y)
	_eje(JOY_AXIS_TRIGGER_LEFT, 0.0)
	_comprobar(absf(e._entrada().y) < 0.01, "sin tocar nada, quieto")

	## Táctil: los botones existen y hacen lo de V y Mayús/Espacio.
	var capa := CanvasLayer.new()
	add_child(capa)
	e.modo = "pie"
	e._tactil(capa)
	var vista: Button = null
	var correr: Button = null
	for b in capa.find_children("*", "Button", true, false):
		if (b as Button).text == "👁":
			vista = b
		elif (b as Button).text == "🏃":
			correr = b
	_comprobar(vista != null and correr != null, "táctil: hay botón de vista y de correr")
	if vista != null and correr != null:
		vista.pressed.emit()
		_comprobar(e.primera_persona, "el botón táctil de vista cambia a primera persona")
		correr.button_down.emit()
		_comprobar(e._corre() and e._freno_mano(), "mantener «correr» corre (y en coche es el freno de mano)")
		correr.button_up.emit()
		_comprobar(not e._corre(), "al soltarlo, deja de correr")
	capa.queue_free()
	e.cuerpo.free()
	e.queue_free()

func _boton(e: ExploradorCiudad, b: JoyButton) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = b
	ev.pressed = true
	e._unhandled_input(ev)

func _tecla(e: ExploradorCiudad, k: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.pressed = true
	e._unhandled_input(ev)

func _eje(eje: JoyAxis, valor: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.device = 0
	ev.axis = eje
	ev.axis_value = valor
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
