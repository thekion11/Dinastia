extends BaseIdea
## A4-INT · ACCESIBILIDAD: solo teclado. Con TECLAS «Tab» de verdad (no una simulación del orden del foco) en cada submenú del juego: el foco empieza en la pantalla, no se queda atrapado en un bucle corto y alcanza
## (casi) todos los botones, campos y deslizadores que se ven. Y «Escape» la cierra.
var _p: Principal
var _vistos := {}

func _frames(n: int = 2) -> void:
	for i in n:
		await get_tree().process_frame

func _tab() -> void:
	var e := InputEventKey.new()
	e.keycode = KEY_TAB
	e.physical_keycode = KEY_TAB
	e.pressed = true
	get_viewport().push_input(e)
	e.pressed = false
	get_viewport().push_input(e)

func _enfocables(raiz: Node) -> Array:
	return raiz.find_children("*", "Control", true, false).filter(func(x: Node) -> bool:
		var c := x as Control
		return (c is Button or c is LineEdit or c is Slider) and c.is_visible_in_tree() and c.focus_mode == Control.FOCUS_ALL and c.get_window() == get_tree().root \
			and not (c is Button and (c as Button).disabled) and c.size.x >= 4.0)

func _probar() -> void:
	_titulo("AUDITORÍA 4 · ACCESIBILIDAD · solo teclado")
	_respaldar_user()
	var m := _mundo(20261104)
	PedidoPartida.mundo_pregenerado = m
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	await _frames(8)
	for t in get_tree().root.find_children("*", "Tutorial", true, false):
		(t as Tutorial)._terminar(false)
	CapasTutorial.poner_activas(false)
	_p._autoguardado = false
	var mal: Array[String] = []
	var n_pant := 0
	var n_enf := 0
	var n_vis := 0
	for mn: Dictionary in MenusLaterales.MENUS:
		var subs: Array = mn["subs"]
		for i in subs.size():
			if (subs[i] as Dictionary).has("accion") or String((subs[i] as Dictionary).get("secc", "")) == "kits":
				continue
			_p._menu_lateral.abrir_menu(String(mn["id"]), i)
			await _frames(6)
			var pm: Variant = _p._menu_lateral.pantalla_abierta
			if not is_instance_valid(pm) or (pm as PantallaMenu).cerrando():
				continue
			n_pant += 1
			var antes := _enfocables(pm as Node)
			if antes.size() < 2:
				(pm as PantallaMenu).cerrar()
				await _frames(10)
				continue
			(antes[0] as Control).grab_focus()
			_vistos.clear()
			_vistos[antes[0]] = true   ## donde empieza también cuenta
			var tope := mini(antes.size() * 2 + 12, 400)
			for k in tope:
				_tab()
				var f := get_viewport().gui_get_focus_owner()
				if f != null:
					_vistos[f] = true
			var alcanzados := 0
			for c: Control in antes:
				if _vistos.has(c):
					alcanzados += 1
			n_enf += antes.size()
			n_vis += alcanzados
			if float(alcanzados) < float(antes.size()) * 0.85:
				mal.append("%s/%d: %d de %d" % [mn["id"], i, alcanzados, antes.size()])
			(pm as PantallaMenu).cerrar()
			await _frames(10)
	_comprobar(n_pant >= 20, "se recorrieron %d pantallas con Tab" % n_pant)
	_comprobar(mal.is_empty(), "el foco con Tab alcanza ≥ 85 %% de lo enfocable en cada pantalla (%d de %d en total); fallan: %s" % [n_vis, n_enf, str(mal.slice(0, 6))])
	## «Escape» vuelve a la portada y luego cierra la pantalla abierta (sin ratón).
	var sin_escape: Array[String] = []
	for destino: Array in [["plantel", 0], ["partido", 0], ["dinero", 0], ["ajustes", 0], ["historia", 3]]:
		_p._menu_lateral.abrir_menu(String(destino[0]), int(destino[1]))
		await _frames(6)
		var pa: Variant = _p._menu_lateral.pantalla_abierta
		if not is_instance_valid(pa):
			continue
		var e := InputEventKey.new()
		e.keycode = KEY_ESCAPE
		e.physical_keycode = KEY_ESCAPE
		e.pressed = true
		get_viewport().push_input(e)
		await _frames(20)
		if is_instance_valid(pa) and not (pa as PantallaMenu).cerrando():   ## en el detalle, la primera vuelve a la portada y la segunda cierra
			get_viewport().push_input(e)
			await _frames(20)
		if is_instance_valid(pa) and not (pa as PantallaMenu).cerrando():
			sin_escape.append("%s/%d" % [destino[0], destino[1]])
			(pa as PantallaMenu).cerrar()
			await _frames(10)
	_comprobar(sin_escape.is_empty(), "«Escape» cierra la pantalla abierta (no la cierra en: %s)" % str(sin_escape))
	_restaurar_user()
