extends BaseIdea
## LOS ATAJOS DE TECLADO DE CADA MENÚ Y SUBMENÚ (3-11-2026, rediseño del menú central, etapa 5): pulsa la tecla de cada uno y comprueba que abre SU menú (y su submenú); sin tecla,
## nada; reasignar y quitar; la migración de las teclas viejas (1-9, 0); y que no chocan con Q/E ni con WASD. Los atajos no se enseñan en ninguna pantalla salvo Ajustes → Accesibilidad.
var _p: Principal

func _tecla_de(accion: String) -> InputEventKey:
	var ev := InputEventKey.new()
	for e: InputEvent in InputMap.action_get_events(accion):
		if e is InputEventKey:
			ev.physical_keycode = (e as InputEventKey).physical_keycode
			ev.keycode = (e as InputEventKey).keycode
	ev.pressed = true
	return ev

func _abierto() -> String:
	var pm = _p._menu_lateral.pantalla_abierta
	if not is_instance_valid(pm) or pm.cerrando():
		return ""
	return String(pm.get_meta("id", ""))

func _probar() -> void:
	_titulo("ATAJOS DE TECLADO POR MENÚ Y SUBMENÚ")
	var m := Mundo.new()
	m.generar(["CHI"], 20261103)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	PedidoPartida.mundo_pregenerado = m
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 4:
		await get_tree().process_frame
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial:
			(t as Tutorial)._terminar(false)
	TeclasInterfaz.restaurar()
	var cat := AtajosCentrales.catalogo()
	var n_menus := 0
	var n_subs := 0
	var con_tecla := 0
	for e: Dictionary in cat:
		if String(e["clave"]).begins_with("menu:"):
			n_menus += 1
		elif String(e["clave"]).begins_with("sub:"):
			n_subs += 1
		if int(e["tecla"]) != 0:
			con_tecla += 1
	var subs_reales := 0
	for mn: Dictionary in MenusLaterales.MENUS:
		subs_reales += (mn["subs"] as Array).size()
	_comprobar(n_menus == MenusLaterales.MENUS.size() and n_subs == subs_reales, "hay un atajo posible por cada menú (%d) y cada submenú (%d)" % [n_menus, n_subs])
	var acciones := {}
	var repetidas: Array[String] = []
	for e: Dictionary in cat:
		if acciones.has(e["accion"]):
			repetidas.append(String(e["accion"]))
		acciones[e["accion"]] = true
	_comprobar(repetidas.is_empty(), "cada menú y submenú tiene su acción propia, sin repetir %s" % str(repetidas))
	var teclas := {}
	var chocan: Array[String] = []
	for e: Dictionary in cat:
		var k := int(e["tecla"])
		if k != 0:
			if teclas.has(k) or k in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_Q, KEY_E, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_SPACE, KEY_ENTER, KEY_ESCAPE]:
				chocan.append(String(e["accion"]))
			teclas[k] = true
	_comprobar(chocan.is_empty(), "las teclas de fábrica no se repiten ni chocan con WASD, Q/E, flechas, Espacio, Intro ni Esc %s" % str(chocan))
	## Cada atajo con tecla de fábrica abre su menú y su submenú, desde cualquier sitio.
	var abiertos := 0
	for e: Dictionary in cat:
		if int(e["tecla"]) == 0 or not (e["destino"] is Dictionary):
			continue
		var destino: Dictionary = e["destino"]
		_p._menu_lateral.abrir_menu("ajustes" if String(destino["menu"]) != "ajustes" else "plantel", -1)
		await get_tree().process_frame
		var ok := AtajosCentrales.manejar(_p, _tecla_de(String(e["accion"])))
		await get_tree().process_frame
		var sub_ok := true
		if int(destino["sub"]) >= 0 and is_instance_valid(_p._menu_lateral.pantalla_abierta) and not (MenusLaterales.menu_por_id(String(destino["menu"]))["subs"][int(destino["sub"])] as Dictionary).has("accion"):
			sub_ok = _p._menu_lateral.pantalla_abierta.submenu_activo() == int(destino["sub"])
		var bien := ok and _abierto() == String(destino["menu"]) and sub_ok
		_comprobar(bien, "la tecla %s abre «%s» › «%s» (abierto: %s)" % [TeclasInterfaz.texto_de(String(e["accion"])), e["grupo"], e["nombre"], _abierto()])
		abiertos += 1
	_linea("  %d atajos con tecla de fábrica probados" % abiertos)
	_comprobar(abiertos == con_tecla - 3, "los %d con tecla de fábrica que abren menús se pulsaron (más N, F3 y F5)" % (con_tecla - 3))
	## Un submenú sin tecla no hace nada; se le puede dar una y funciona.
	var sin: Dictionary = {}
	for e: Dictionary in cat:
		if int(e["tecla"]) == 0 and String(e["clave"]) == "sub:plantel:Enfermería":
			sin = e
	_comprobar(not sin.is_empty() and InputMap.action_get_events(String(sin["accion"])).is_empty(), "«Enfermería» no tiene tecla de fábrica (sin tecla)")
	var f9 := InputEventKey.new()
	f9.physical_keycode = KEY_F9
	f9.pressed = true
	TeclasInterfaz.reasignar(String(sin["accion"]), f9)
	_p._menu_lateral.abrir_menu("ajustes", -1)
	await get_tree().process_frame
	_comprobar(AtajosCentrales.manejar(_p, f9) and _abierto() == "plantel", "asignada F9 a «Enfermería», abre el plantel")
	TeclasInterfaz.quitar(String(sin["accion"]))
	_comprobar(InputMap.action_get_events(String(sin["accion"])).is_empty() and TeclasInterfaz.texto_de(String(sin["accion"])) == Idiomas.t("sin tecla"), "quitada: vuelve a «sin tecla»")
	## Quitar una de fábrica (la P del plantel) y restaurar.
	TeclasInterfaz.quitar("dinastia_menu_plantel")
	_p._menu_lateral.abrir_menu("ajustes", -1)
	await get_tree().process_frame
	var tp := InputEventKey.new()
	tp.physical_keycode = KEY_P
	tp.pressed = true
	_comprobar(not AtajosCentrales.manejar(_p, tp), "sin la tecla del plantel, la P no hace nada")
	TeclasInterfaz.restaurar()
	_comprobar(AtajosCentrales.manejar(_p, tp), "restaurar devuelve las de fábrica: la P vuelve a manejarse")
	await get_tree().process_frame
	_comprobar(_abierto() == "plantel", "y abre el plantel")
	## Con una capa encima (un diálogo a pantalla completa) o escribiendo, callan.
	var capa := ColorRect.new()
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.mouse_filter = Control.MOUSE_FILTER_STOP
	_p.add_child(capa)
	_p._menu_lateral.abrir_menu("ajustes", -1)
	await get_tree().process_frame
	_comprobar(_p._atajos._capa_modal_ajena(), "una capa a pantalla completa cuenta como modal ajena")
	capa.queue_free()
	await get_tree().process_frame
	## Migración: las teclas viejas (1-9/0) que alguien había cambiado pasan a su menú nuevo.
	var cf := ConfigFile.new()
	cf.set_value("teclas", "dinastia_ir_mercado", {"tecla": int(KEY_F7)})
	cf.set_value("teclas", "dinastia_ir_inicio", {"tecla": int(KEY_F6)})
	cf.save(TeclasInterfaz.RUTA)
	TeclasInterfaz._cargado = false
	TeclasInterfaz.cargar()
	var nueva := AtajosCentrales.accion_de_clave("sub:dinero:Mercado")
	_comprobar(nueva != "" and TeclasInterfaz._propio.has(nueva) and int((TeclasInterfaz._propio[nueva] as Dictionary)["tecla"]) == KEY_F7, "la tecla vieja del mercado (F7) pasa al submenú Mercado")
	_comprobar(not TeclasInterfaz._propio.has("dinastia_ir_inicio"), "y la de «ir a inicio», que ya no existe, se descarta")
	TeclasInterfaz.restaurar()
	_comprobar(AtajosCentrales.accion_de_clave("sub:plantel:Táctica") == "dinastia_sub_plantel_tactica", "los nombres de las acciones son estables (dinastia_sub_plantel_tactica)")
	## En Ajustes → Pantalla (Dispositivo) ya no se enseñan los atajos de menú.
	_p._menu_lateral.abrir_menu("ajustes", 0)
	await get_tree().process_frame
	await get_tree().process_frame
	var visibles := ""
	for l in _p.find_children("*", "Label", true, false):
		visibles += (l as Label).text + "\n"
	_comprobar(not visibles.contains("Ir a Mi plantel") and not visibles.contains("Pasar un día"), "Dispositivo no enseña los atajos de los menús")
	TeclasInterfaz.restaurar()
	## Ajustes → Accesibilidad lista TODOS los menús y submenús con su tecla (o «sin tecla») y se pueden asignar.
	var idx_acceso := -1
	for k in (MenusLaterales.menu_por_id("ajustes")["subs"] as Array).size():
		if String(MenusLaterales.menu_por_id("ajustes")["subs"][k].get("secc", "")) == "acceso":
			idx_acceso = k
	_p._menu_lateral.abrir_menu("ajustes", idx_acceso)
	await get_tree().process_frame
	await get_tree().process_frame
	var etiquetas: Array[String] = []
	var botones_cambiar := 0
	var botones_quitar := 0
	for l in _p.find_children("*", "Label", true, false):
		etiquetas.append((l as Label).text)
	for b in _p.find_children("*", "Button", true, false):
		if (b as Button).text == Idiomas.t("Cambiar"):
			botones_cambiar += 1
		elif (b as Button).text == Idiomas.t("Quitar"):
			botones_quitar += 1
	_comprobar(etiquetas.has("Táctica") and etiquetas.has("Enfermería") and etiquetas.has("sin tecla") and etiquetas.has("El menú entero"), "Accesibilidad lista los submenús y los menús, y «sin tecla» a los que no tienen")
	_comprobar(botones_cambiar >= cat.size() and botones_quitar == cat.size(), "con «Cambiar» y «Quitar» en cada atajo (%d cambiar, %d quitar, %d atajos)" % [botones_cambiar, botones_quitar, cat.size()])
	TeclasInterfaz.restaurar()
