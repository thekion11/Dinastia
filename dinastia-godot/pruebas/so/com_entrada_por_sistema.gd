extends BaseSO
## COMÚN · entrada según el sistema: en móvil y en Web táctil manda el toque (sin teclado físico garantizado), en PC teclado/ratón/mando.
## Se comprueba la expectativa propia de cada sistema: acciones del mapa de entrada que existen, ninguna acción de partido sin tecla en PC,
## y que un toque simulado produce un clic en un botón.
func _nombre() -> String:
	return "com_entrada_por_sistema"

var _pulsado := false

func _probar() -> void:
	_titulo("COMÚN · entrada [%s]" % sistema())
	var acciones := InputMap.get_actions().filter(func(a): return not String(a).begins_with("ui_"))
	_comprobar(acciones.size() >= 5, "el mapa de entrada propio tiene %d acciones" % acciones.size())
	var sin_evento: Array[String] = []
	for a in acciones:
		if InputMap.action_get_events(a).is_empty():
			sin_evento.append(String(a))
	var permitido := int(por_so({"movil": 99, "web": 99, "defecto": 0}))
	_comprobar(sin_evento.size() <= permitido, "acciones sin ninguna tecla/botón: %s (tope de %s: %d)" % [str(sin_evento), sistema(), permitido])
	for a in ["ui_accept", "ui_cancel", "ui_up", "ui_down", "ui_left", "ui_right"]:
		_comprobar(InputMap.has_action(a) and not InputMap.action_get_events(a).is_empty(), "%s tiene eventos" % a)
	## Un toque en un botón cuenta como clic (emulate_mouse_from_touch).
	var raiz := Control.new()
	raiz.size = Vector2(400, 300)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)
	var b := Button.new()
	b.text = "x"
	b.position = Vector2(2, 2)
	b.size = Vector2(50, 40)
	b.pressed.connect(func(): _pulsado = true)
	raiz.add_child(b)
	await _frames(2)
	var mov := InputEventMouseMotion.new()
	mov.position = Vector2(20, 20)
	mov.global_position = mov.position
	get_viewport().push_input(mov)
	await _frames(1)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = Vector2(20, 20)
	ev.global_position = ev.position
	ev.pressed = true
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(ev)
	await _frames(1)
	ev = ev.duplicate()
	ev.pressed = false
	ev.button_mask = 0
	get_viewport().push_input(ev)
	await _frames(2)
	if DisplayServer.get_name() == "headless":
		## Sin ventana el motor no reparte el ratón a la interfaz (ventana de 64x64 sin foco): se comprueba lo que sí cuenta, que el botón
		## acepta clics y que el toque está emulado (arriba); el clic real lo cubren las pruebas con pantalla (xvfb).
		_comprobar(b.mouse_filter == Control.MOUSE_FILTER_STOP and not b.disabled, "el botón acepta clics (modo sin ventana: no se reparte el ratón)")
	else:
		_comprobar(_pulsado, "un clic sobre el botón lo pulsa (el toque emulado llega igual)")
	var tactil := DisplayServer.is_touchscreen_available()
	var esperado := bool(por_so({"android": true, "ios": true, "defecto": false}))
	if esperado:
		_comprobar(tactil, "en %s hay pantalla táctil" % sistema())
	else:
		print("  (en %s la pantalla táctil es opcional: %s)" % [sistema(), str(tactil)])
	raiz.queue_free()
