extends BaseSO
## ERRORES · ráfagas de entrada: 3000 teclas, ratón y mando seguidos sobre el menú principal real (con el árbol de pantallas montado), sin
## esperar fotogramas. No debe haber SCRIPT ERROR ni cuelgue, el árbol no debe crecer sin tope (fuga) y la pantalla debe seguir viva.
func _nombre() -> String:
	return "err_rafaga_entrada"

func _probar() -> void:
	_titulo("ERRORES · ráfaga de entrada [%s]" % sistema())
	_respaldar_user()
	PedidoPartida.mundo_pregenerado = _mundo(20261105)
	var p: Node = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	await _frames(8)
	for t in get_tree().root.find_children("*", "Tutorial", true, false):
		(t as Tutorial)._terminar(false)
	var nodos0 := get_tree().get_node_count()
	var clases0 := _clases(get_tree().root)
	var teclas := [KEY_TAB, KEY_ENTER, KEY_SPACE, KEY_ESCAPE, KEY_DOWN, KEY_UP, KEY_LEFT, KEY_RIGHT, KEY_A, KEY_D, KEY_F1, KEY_M]
	var t0 := Time.get_ticks_msec()
	for i in 3000:
		var e: InputEvent
		match i % 4:
			0:
				var k := InputEventKey.new()
				k.keycode = teclas[i % teclas.size()]
				k.physical_keycode = k.keycode
				k.pressed = (i / 4) % 2 == 0
				e = k
			1:
				var r := InputEventMouseButton.new()
				r.button_index = MOUSE_BUTTON_LEFT if (i / 4) % 3 else MOUSE_BUTTON_RIGHT
				r.position = Vector2((i * 37) % 64, (i * 11) % 64)
				r.pressed = (i / 4) % 2 == 0
				e = r
			2:
				var j := InputEventJoypadButton.new()
				j.button_index = (i % 10) as JoyButton
				j.pressed = (i / 4) % 2 == 0
				e = j
			_:
				var tq := InputEventScreenTouch.new()
				tq.index = i % 5
				tq.position = Vector2((i * 13) % 64, (i * 7) % 64)
				tq.pressed = (i / 4) % 2 == 0
				e = tq
		get_viewport().push_input(e)
		if i % 500 == 499:
			await _frames(1)
	await _frames(10)
	var ms := Time.get_ticks_msec() - t0
	_comprobar(ms < 60000, "3000 eventos se atienden en %d ms (sin colgarse)" % ms)
	_comprobar(is_instance_valid(p) and p.is_inside_tree(), "la pantalla principal sigue viva")
	var nodos1 := get_tree().get_node_count()
	_comprobar(nodos1 < nodos0 * 2 + 400, "el árbol no se dispara: %d → %d nodos" % [nodos0, nodos1])
	if nodos1 >= nodos0 * 2 + 400:   ## (6-11) en macOS crece 899 → 4777: se imprime QUÉ crece para poder ubicar la pantalla que se abre
		_linea("  crecimiento por clase (las 8 que más): " + _mas_crecidas(clases0, _clases(get_tree().root)))
	for a: StringName in InputMap.get_actions():
		Input.action_release(a)
	p.queue_free()
	await _frames(3)
	_restaurar_user()

## Cuántos nodos hay de cada clase (nombre de la clase del script o del tipo) bajo `raiz`.
func _clases(raiz: Node) -> Dictionary:
	var c := {}
	for n: Node in raiz.find_children("*", "", true, false):
		var sc := n.get_script() as Script
		var nombre := String(sc.get_global_name()) if sc != null and sc.get_global_name() != &"" else n.get_class()
		c[nombre] = int(c.get(nombre, 0)) + 1
	return c

func _mas_crecidas(antes: Dictionary, despues: Dictionary) -> String:
	var dif: Array = []
	for k: String in despues:
		var d := int(despues[k]) - int(antes.get(k, 0))
		if d > 0:
			dif.append([d, k])
	dif.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var partes: PackedStringArray = []
	for i in mini(8, dif.size()):
		partes.append("%s +%d" % [dif[i][1], dif[i][0]])
	return ", ".join(partes)
