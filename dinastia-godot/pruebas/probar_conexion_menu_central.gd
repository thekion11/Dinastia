extends Node
## EL MENÚ CENTRAL NUEVO CONECTA CON TODO (17-11-2026, orden del dueño: «que NADA quede sin conectar»), versión con ventana (xvfb en `herramientas/especiales.sh`; la de datos está en el banco, grupo
## «menus»). Con un Principal real: (1) la barra lateral SE VE en el Inicio con sus 14 menús, cada botón del riel abre su menú y CADA submenú registrado en `MenusLaterales` se abre en su menú y
## su submenú (los de «acción» no se abren: arrancarían la casa, el móvil o el estadio); (2) los botones de la barra de arriba (Despacho, Mensajes, Oficina del DT, Base de datos, Sistema, escudo, caja)
## y las tarjetas del Inicio abren algo de verdad, y Esc cierra las pantallas completas; (3) con el mando, desde el primer control se llega a TODOS los demás siguiendo los vecinos de foco.
## Dos clubes de países distintos.

var fallos := 0

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO ", msg)

func _frames(n := 4) -> void:
	for i in n:
		await get_tree().process_frame

func _accion(nombre: String) -> void:
	for pulsada in [true, false]:
		var ev := InputEventAction.new()
		ev.action = nombre
		ev.pressed = pulsada
		Input.parse_input_event(ev)
		await _frames(2)

func _pestana(pr: Principal, i: int) -> void:
	if TableroInicio.pestana != i:
		var barra: Node = (pr.get_meta("escaparate") as Node).find_child("Botones", true, false)
		((barra.get_meta("tabs") as Array)[i] as Button).pressed.emit()
	await _frames(5)

func _cerrar_menu(pr: Principal) -> void:
	var m := pr._menu_lateral.pantalla_abierta
	if is_instance_valid(m):
		m.cerrar()
	await _frames(6)

func _abierto(pr: Principal) -> PantallaMenu:
	var m := pr._menu_lateral.pantalla_abierta
	return m if is_instance_valid(m) and m.is_inside_tree() and not m.cerrando() else null

func _boton_entrada(pr: Principal, clave: String) -> Button:
	for b in (pr.get_meta("escaparate") as Node).find_children("*", "Button", true, false):
		if String(b.get_meta("entrada", "")) == clave:
			return b as Button
	return null

func _tarjeta_con_nombre(raiz: Node, rotulo: String) -> Button:
	for l in raiz.find_children("*", "Label", true, false):
		if (l as Label).text == rotulo.to_upper() and l.get_parent() is Button:
			return l.get_parent() as Button
	return null

func _barra(pant: Node) -> Node:   ## la barra se repinta al cerrar menús: se vuelve a buscar siempre
	return pant.find_child("Botones", true, false)

func _ready() -> void:
	AvanceDiasUI.sin_pantalla = true
	JornadaEventos._abierto = true
	for cfg: Array in [["ESP", 4, 20261104], ["ARG", 3, 20261117]]:
		await _una(cfg)
	print("FIN. %d fallos" % fallos)
	get_tree().quit()

func _una(cfg: Array) -> void:
	var m := Mundo.new()
	var ps: Array[String] = [String(cfg[0])]
	m.generar(ps, int(cfg[2]))
	m.tomar_el_mando(m.ligas[0].clubes[int(cfg[1])].id)
	PedidoPartida.mundo_pregenerado = m
	PedidoPartida.modo_elegido = "dt"
	PedidoPartida.dt_nombre_elegido = "Prueba"
	PedidoPartida.dificultad_elegida = "normal"
	PedidoPartida.aplicado_a = 0
	var pr: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(pr)
	await _frames(8)
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial:
			(t as Tutorial)._terminar(false)
	await _frames(6)
	var e: String = cfg[0]
	var pant := pr.get_meta("escaparate") as EscaparatePantalla
	## 0. La barra lateral se ve en el Inicio con sus 14 menús
	for mn: Dictionary in MenusLaterales.MENUS:
		var bb0: Button = pr._menu_lateral.boton_de(String(mn["id"]))
		_ok(bb0 != null and bb0.is_visible_in_tree() and bb0.get_global_rect().position.x < MenuLateral.ANCHO_RIEL and bb0.get_global_rect().size.y >= 36.0, "%s: el riel enseña el menú «%s» con el Inicio a la vista" % [e, mn["id"]])
	## 2. La barra de arriba y las tarjetas del Inicio
	for nombre: String in ["BotonDespacho", "BotonMensajes"]:
		var b := _barra(pant).get_node_or_null(nombre) as Button
		_ok(b != null, "%s: la barra tiene «%s»" % [e, nombre])
		if b == null:
			continue
		b.pressed.emit()
		await _frames(4)
		_ok(is_instance_valid(pant.panel_despacho) if nombre == "BotonDespacho" else is_instance_valid(pant.informe), "%s: «%s» abre su pantalla completa" % [e, nombre])
		await _accion("ui_cancel")
		await _frames(4)
		_ok(not is_instance_valid(pant.panel_despacho) and not is_instance_valid(pant.informe), "%s: Esc cierra la pantalla de «%s»" % [e, nombre])
	for b in _barra(pant).get_children():
		if b is Button and ["Oficina del DT", "Base de datos", "Sistema"].has(String(b.get_meta("rotulo", ""))):
			(b as Button).pressed.emit()
			await _frames(4)
			var abierto_algo := _abierto(pr) != null or (is_instance_valid(pant._busqueda) and pant._busqueda.visible) or pant.find_child("Panel", true, false) != null
			_ok(abierto_algo, "%s: «%s» abre algo" % [e, b.get_meta("rotulo")])
			if is_instance_valid(pant._busqueda):
				pant._busqueda.hide()
			var pn_s := pant.find_child("Panel", true, false)
			if pn_s != null:
				pn_s.queue_free()
				await _frames(3)
			await _cerrar_menu(pr)
	_ok(pant.find_child("BotonEntrarClub", true, false) != null or pant.find_child("BotonLevantarse", true, false) != null, "%s: el pie tiene «Entrar al club» (o «Levantarse del PC»)" % e)
	for rotulo: String in ["Oficina del DT", "Noticias y correo", "Tabla de posiciones", "Hinchada y socios"]:
		var t2 := _tarjeta_con_nombre(pant, Idiomas.t(rotulo))
		_ok(t2 != null, "%s: Inicio tiene la tarjeta «%s»" % [e, rotulo])
		if t2 == null:
			continue
		t2.pressed.emit()
		await _frames(3)
		_ok(_abierto(pr) != null, "%s: la tarjeta «%s» abre un menú" % [e, rotulo])
		await _cerrar_menu(pr)
	var desp := _tarjeta_con_nombre(pant, Idiomas.t("Despacho"))
	_ok(desp != null, "%s: Inicio tiene la tarjeta «Despacho»" % e)
	if desp != null:
		desp.pressed.emit()
		await _frames(4)
		_ok(is_instance_valid(pant.panel_despacho), "%s: la tarjeta «Despacho» abre su pantalla completa" % e)
		await _accion("ui_cancel")
		await _frames(4)
		_ok(pr._despacho.get_parent() != null and not pant.is_ancestor_of(pr._despacho), "%s: al cerrar, el despacho vuelve a su sitio" % e)
	## 3. El mando: desde el primer control se llega a TODOS los demás por los vecinos de foco
	await _frames(4)
	var todos := EscaparateFoco.enfocables(pant)
	_ok(todos.size() > 15, "%s: hay %d controles enfocables en el Inicio" % [e, todos.size()])
	var visto := {}
	var cola: Array = [todos[0]] if not todos.is_empty() else []
	while not cola.is_empty():
		var c: Control = cola.pop_back()
		if visto.has(c):
			continue
		visto[c] = true
		for lado in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			var n := c.get_node_or_null(c.get_focus_neighbor(lado))
			if n is Control and not visto.has(n):
				cola.append(n)
	var sin: Array[String] = []
	for c in todos:
		if not visto.has(c):
			sin.append(String(c.name))
	_ok(sin.is_empty(), "%s: el D-pad llega a todos los controles del Inicio (sin llegar: %s)" % [e, str(sin.slice(0, 6))])
	## 4. La barra lateral, siempre visible, y todos sus submenús (al final: algunas pantallas, como el diseñador de equipaciones, dejan cosas abiertas)
	var abiertos := 0
	var total := 0
	for mn: Dictionary in MenusLaterales.MENUS:
		var id := String(mn["id"])
		var bb: Button = pr._menu_lateral.boton_de(id)
		if bb != null and bb.is_visible_in_tree():
			bb.pressed.emit()
			await _frames(3)
			var pm := _abierto(pr)
			_ok(pm != null and String(pm.get_meta("id", "")) == id, "%s: el botón del riel abre «%s»" % [e, id])
		var subs: Array = mn["subs"]
		for i in subs.size():
			total += 1
			if (subs[i] as Dictionary).has("accion"):
				continue
			var pm2: PantallaMenu = pr._menu_lateral.abrir_menu(id, i)
			await _frames(2)
			var bien := pm2 != null and pm2.submenu_activo() == i
			_ok(bien, "%s: «%s» abre el submenú %d de «%s»" % [e, (subs[i] as Dictionary).get("label", ""), i, id])
			abiertos += 1 if bien else 0
		await _cerrar_menu(pr)
	print("   %s: %d submenús, %d abiertos de verdad (los de acción no se abren)" % [e, total, abiertos])
	TableroInicio.pestana = 0
	pr.queue_free()
	await _frames(3)
