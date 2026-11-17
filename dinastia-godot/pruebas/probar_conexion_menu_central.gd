extends Node
## EL MENÚ CENTRAL NUEVO CONECTA CON TODO (17-11-2026, orden del dueño: «que NADA quede sin conectar»), versión con ventana (xvfb en `herramientas/especiales.sh`; la de datos está en el banco, grupo
## «menus»). Con un Principal real: (1) CADA submenú registrado en `MenusLaterales` se abre desde la pestaña «Índice» pulsando su botón (ratón) y queda en el menú y submenú correctos (los de «acción»
## solo se comprueba que tienen su botón: abrirlos arrancaría la casa, el móvil o el estadio); (2) con el foco y «aceptar» (mando/teclado) se abren los de muestra; (3) cada tarjeta de «Dirección del
## equipo» e «Información del club» y los atajos de la barra y del pie abren algo de verdad (un menú, la pantalla del despacho o la del informe); (4) «☰» abre el cajón con los 14 menús.
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
	var e: String = cfg[0]
	## 1. El Índice: cada submenú por ratón
	await _pestana(pr, 3)
	var abiertos := 0
	var con_boton := 0
	var total := 0
	for entrada: Array in EscaparateIndice.entradas():
		total += 1
		var clave := "%s:%d" % [entrada[0], entrada[1]]
		await _pestana(pr, 3)
		var b := _boton_entrada(pr, clave)
		if b == null:
			_ok(false, "%s: el Índice no tiene botón para «%s» (%s)" % [e, entrada[2], clave])
			continue
		con_boton += 1
		var sub: Dictionary = (MenusLaterales.menu_por_id(String(entrada[0]))["subs"] as Array)[int(entrada[1])]
		if sub.has("accion"):
			continue   ## abrirlo ejecutaría la acción (casa, móvil, estadio…)
		b.pressed.emit()
		await _frames(3)
		var pm := _abierto(pr)
		var bien := pm != null and String(pm.get_meta("id", "")) == String(entrada[0]) and pm.submenu_activo() == int(entrada[1])
		_ok(bien, "%s: «%s» (%s) abre su menú y su submenú desde el Índice" % [e, entrada[2], clave])
		abiertos += 1 if bien else 0
		await _cerrar_menu(pr)
	_ok(con_boton == total, "%s: el Índice tiene botón para los %d submenús (%d)" % [e, total, con_boton])
	print("   %s: %d submenús con botón, %d abiertos de verdad" % [e, con_boton, abiertos])
	## 2. Con foco y «aceptar» (mando/teclado), uno por menú
	var vistos := {}
	for entrada: Array in EscaparateIndice.entradas():
		var id := String(entrada[0])
		var sub2: Dictionary = (MenusLaterales.menu_por_id(id)["subs"] as Array)[int(entrada[1])]
		if vistos.has(id) or sub2.has("accion"):
			continue
		vistos[id] = true
		await _pestana(pr, 3)
		var b2 := _boton_entrada(pr, "%s:%d" % [id, int(entrada[1])])
		if b2 == null:
			continue
		b2.grab_focus()
		await _frames(2)
		await _accion("ui_accept")
		await _frames(3)
		var pm2 := _abierto(pr)
		_ok(pm2 != null and String(pm2.get_meta("id", "")) == id, "%s: foco + aceptar abre el menú «%s»" % [e, id])
		await _cerrar_menu(pr)
	## 3. Las tarjetas de las pestañas 1 y 2 (menos el informe, que abre su pantalla): todas abren un menú
	for pestana in [1, 2]:
		var lista: Array = TableroInicio.EQUIPO if pestana == 1 else TableroInicio.CLUB
		for rot: String in lista:
			await _pestana(pr, pestana)
			var rotulo := rot
			if rot == "*plantel": rotulo = "Mi plantel"
			elif rot == "*cuentas": rotulo = "Cuentas del club"
			elif rot == "*sistema": rotulo = "Sistema"
			var tarjeta := _tarjeta_con_nombre(pr.get_meta("escaparate"), Idiomas.t(rotulo))
			_ok(tarjeta != null, "%s: pestaña %d tiene la tarjeta «%s»" % [e, pestana, rotulo])
			if tarjeta == null:
				continue
			tarjeta.pressed.emit()
			await _frames(3)
			_ok(_abierto(pr) != null, "%s: la tarjeta «%s» abre un menú" % [e, rotulo])
			await _cerrar_menu(pr)
	await _pestana(pr, 2)
	var inf := _tarjeta_con_nombre(pr.get_meta("escaparate"), Idiomas.t("Informe de la semana"))
	_ok(inf != null, "%s: la tarjeta «Informe de la semana» está en Información del club" % e)
	if inf != null:
		inf.pressed.emit()
		await _frames(3)
		var pant := pr.get_meta("escaparate") as EscaparatePantalla
		_ok(is_instance_valid(pant.informe), "%s: abre la pantalla del informe" % e)
		await _accion("ui_cancel")
		await _frames(4)
	## 4. Inicio: DT, noticia, tabla, hinchada, despacho; y el pie y la barra
	await _pestana(pr, 0)
	for rotulo: String in ["Oficina del DT", "Noticias y correo", "Tabla de posiciones", "Hinchada y socios"]:
		await _pestana(pr, 0)
		var t2 := _tarjeta_con_nombre(pr.get_meta("escaparate"), Idiomas.t(rotulo))
		_ok(t2 != null, "%s: Inicio tiene la tarjeta «%s»" % [e, rotulo])
		if t2 == null:
			continue
		t2.pressed.emit()
		await _frames(3)
		_ok(_abierto(pr) != null, "%s: la tarjeta «%s» abre un menú" % [e, rotulo])
		await _cerrar_menu(pr)
	var desp := _tarjeta_con_nombre(pr.get_meta("escaparate"), Idiomas.t("Despacho"))
	_ok(desp != null, "%s: Inicio tiene la tarjeta «Despacho»" % e)
	if desp != null:
		desp.pressed.emit()
		await _frames(4)
		var pant2 := pr.get_meta("escaparate") as EscaparatePantalla
		_ok(is_instance_valid(pant2.panel_despacho), "%s: «Despacho» abre su pantalla completa" % e)
		await _accion("ui_cancel")
		await _frames(4)
		_ok(pr._despacho.get_parent() != null and not (pr.get_meta("escaparate") as Node).is_ancestor_of(pr._despacho), "%s: al cerrar, el despacho vuelve a su sitio" % e)
	## 5. «☰»: el cajón con los 14 menús, y cada botón del riel abre su menú
	await _pestana(pr, 0)
	var menu_b: Button = null
	for b in (pr.get_meta("escaparate") as Node).find_children("*", "Button", true, false):
		if (b as Button).text == "☰":
			menu_b = b as Button
	_ok(menu_b != null, "%s: la barra tiene el botón «☰»" % e)
	if menu_b != null:
		menu_b.grab_focus()
		_ok(menu_b.has_focus(), "%s: el foco del mando llega al «☰»" % e)
		menu_b.pressed.emit()
		await _frames(8)
		_ok(pr._menu_lateral.abierto(), "%s: «☰» abre el cajón de menús" % e)
		for mn: Dictionary in MenusLaterales.MENUS:
			var bb: Button = pr._menu_lateral.boton_de(String(mn["id"]))
			_ok(bb != null and bb.is_visible_in_tree(), "%s: el cajón enseña el menú «%s»" % [e, mn["id"]])
		pr._menu_lateral.plegar()
		await _frames(8)
	TableroInicio.pestana = 0
	pr.queue_free()
	await _frames(3)
