extends BaseIdea
## BANCO «menu_navegacion» · PRUEBAS PROPIAS (fase 2, 4-11-2026): cada menú y cada submenú del panel lateral, por todas las vías: el riel (botón y toque), los
## submenús uno a uno, Esc (detalle → portada → central), el botón «Volver», el mando (L1/R1 de submenú, L2/R2 de menú, con los eventos reales
## de cada acción) y volver SIEMPRE al central (Inicio, sin panel ni capa encima). Además la coherencia de los datos (`MenusLaterales`): ids y etiquetas únicos,
## ninguna pestaña sin submenú, cada acción con su manejador, nada tapado (el menú cabe en pantalla, sin tarjeta de ayuda desplegada encima).
var _p: Principal
var _raiz0: Array = []

func _abierto() -> PantallaMenu:
	var pm: Variant = _p._menu_lateral.pantalla_abierta
	if is_instance_valid(pm) and not (pm as PantallaMenu).cerrando():
		return pm as PantallaMenu
	return null

func _frames(n: int = 4) -> void:
	for i in n:
		await get_tree().process_frame

func _cerrar_todo() -> void:
	## Una pantalla completa propia (el diseñador de equipación…) esconde Principal: se cierra y se vuelve a mostrar.
	for c in get_tree().root.get_children():
		if not _raiz0.has(c) and c != self:
			c.queue_free()
	_p.visible = true
	for c in _p.get_children():
		if c is Window and (c as Window).visible:
			(c as Window).hide()
	var pm := _abierto()
	if pm != null:
		pm.cerrar()
	await _frames(24)

func _accion(nombre: String) -> void:
	var e := InputEventAction.new()
	e.action = nombre
	e.pressed = true
	Input.parse_input_event(e)
	await _frames(3)
	var s := InputEventAction.new()
	s.action = nombre
	s.pressed = false
	Input.parse_input_event(s)
	await _frames(2)

func _volver() -> Button:
	var pm := _abierto()
	if pm == null:
		return null
	for b in pm.find_children("*", "Button", true, false):
		if (b as Button).text.contains(Idiomas.t("Volver")) and (b as Button).is_visible_in_tree():
			return b as Button
	return null

func _en_central() -> bool:
	return _abierto() == null and not _p._menu_lateral.ocupado() and _p._pestanas.get_tab_title(_p._pestanas.current_tab) == "Inicio"

func _probar() -> void:
	_titulo("BANCO MENU_NAVEGACION · 14 menús, todos los submenús, todas las vías")
	var m := Mundo.new()
	m.generar(["CHI"], 20261104)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	PedidoPartida.mundo_pregenerado = m
	CapasTutorial.forzar = false
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	await _frames(6)
	_raiz0 = get_tree().root.get_children()
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial:
			(t as Tutorial)._terminar(false)
	var ayudas := CapasTutorial.activas()
	CapasTutorial.poner_activas(false)
	_datos()
	await _riel()
	await _submenus()
	await _teclado_y_volver()
	await _mando()
	await _toque()
	await _pestanas_a_menu()
	CapasTutorial.poner_activas(ayudas)

## Coherencia de los datos del panel.
func _datos() -> void:
	var menus: Array = MenusLaterales.MENUS
	var ids := {}
	var subs_total := 0
	var sin_desc: Array[String] = []
	var dup: Array[String] = []
	var claves := {}
	for mn: Dictionary in menus:
		ids[String(mn["id"])] = true
		var etiquetas := {}
		var subs: Array = mn["subs"]
		subs_total += subs.size()
		for sb: Dictionary in subs:
			var et := String(sb.get("label", ""))
			if et == "" or String(sb.get("desc", "")) == "" or String(sb.get("icono", "")) == "":
				sin_desc.append("%s/%s" % [mn["id"], et])
			if etiquetas.has(et):
				dup.append("%s/%s" % [mn["id"], et])
			etiquetas[et] = true
			var clave := "%s|%s|%s|%s" % [mn["id"], sb.get("tab", ""), sb.get("secc", ""), sb.get("accion", "")]
			if claves.has(clave):
				dup.append(clave)
			claves[clave] = true
	_comprobar(menus.size() == 14 and ids.size() == 14, "hay 14 menús con id único (%d)" % menus.size())
	_comprobar(subs_total >= 60, "los menús suman %d submenús (≥ 60)" % subs_total)
	_comprobar(sin_desc.is_empty(), "cada submenú tiene etiqueta, icono y descripción %s" % str(sin_desc.slice(0, 4)))
	_comprobar(dup.is_empty(), "sin etiquetas ni destinos repetidos dentro de un menú %s" % str(dup.slice(0, 4)))
	var con_menu := {}
	for mn: Dictionary in menus:
		for sb: Dictionary in mn["subs"]:
			if sb.has("tab"):
				con_menu[String(sb["tab"])] = true
	var sueltas: Array[String] = []
	for i in _p._pestanas.get_tab_count():
		var t := _p._pestanas.get_tab_title(i)
		if t != "Inicio" and not con_menu.has(t):
			sueltas.append(t)
	_comprobar(sueltas.is_empty(), "ninguna pestaña del central sin submenú %s" % str(sueltas))
	## Cada acción de un submenú tiene su manejador en `MenuLateral.ejecutar`.
	var fuente := FileAccess.get_file_as_string("res://ui/componentes/menu_lateral.gd")
	var sin_manejador: Array[String] = []
	var n_acc := 0
	for mn: Dictionary in menus:
		for sb: Dictionary in mn["subs"]:
			if sb.has("accion"):
				n_acc += 1
				if not fuente.contains("\"%s\"" % sb["accion"]):
					sin_manejador.append(String(sb["accion"]))
	_comprobar(n_acc >= 10 and sin_manejador.is_empty(), "las %d acciones tienen manejador en MenuLateral.ejecutar %s" % [n_acc, str(sin_manejador)])
	for mn: Dictionary in menus:
		_comprobar(_p._menu_lateral.boton_de(String(mn["id"])) != null, "el riel tiene el botón de «%s»" % mn["id"])

## El riel: pulsar cada botón abre SU portada; pulsarlo otra vez la deja; cerrar vuelve al central.
func _riel() -> void:
	for mn: Dictionary in MenusLaterales.MENUS:
		var id := String(mn["id"])
		var b := _p._menu_lateral.boton_de(id)
		b.pressed.emit()
		await _frames(5)
		var pm := _abierto()
		_comprobar(pm != null and String(pm.get_meta("id", "")) == id, "riel «%s»: abre su menú" % id)
		if pm == null:
			continue
		_comprobar(pm.submenu_activo() == -1, "riel «%s»: se abre en la PORTADA (sin submenú elegido)" % id)
		_comprobar(b.button_pressed, "riel «%s»: el botón queda marcado" % id)
		var vp := _p.get_viewport_rect()
		_comprobar(vp.encloses(pm.get_global_rect().grow(-2.0)), "riel «%s»: el menú cabe en la pantalla (%s)" % [id, str(pm.get_global_rect().size)])
		_comprobar(_volver() != null, "riel «%s»: se ve el botón «Volver»" % id)
		var tarjetas := 0
		for c in pm.find_children("*", "Button", true, false):
			if (c as Button).is_visible_in_tree() and (c as Button).custom_minimum_size.x >= 250.0:
				tarjetas += 1
		var esperadas := (mn["subs"] as Array).size()
		_comprobar(tarjetas == esperadas, "riel «%s»: la portada enseña sus %d tarjetas (%d)" % [id, esperadas, tarjetas])
		await _cerrar_todo()
		_comprobar(_en_central(), "riel «%s»: al cerrar se vuelve al central (Inicio, sin panel)" % id)
		_comprobar(not b.button_pressed, "riel «%s»: y el botón se desmarca" % id)

## Cada submenú: se abre por su índice, enseña contenido, no queda tapado y el botón «Volver» devuelve al central.
func _submenus() -> void:
	var total := 0
	var sin_contenido: Array[String] = []
	var tapados: Array[String] = []
	var mal_pestana: Array[String] = []
	var mal_volver: Array[String] = []
	for mn: Dictionary in MenusLaterales.MENUS:
		var id := String(mn["id"])
		var subs: Array = mn["subs"]
		for i in subs.size():
			var sb: Dictionary = subs[i]
			if sb.has("accion"):
				continue
			total += 1
			var nombre := "%s › %s" % [id, sb["label"]]
			_p._menu_lateral.abrir_menu(id, i)
			await _frames(5)
			var pm := _abierto()
			if pm == null or pm.submenu_activo() != i:
				mal_pestana.append(nombre + " (no abre)")
				await _cerrar_todo()
				continue
			if String(sb.get("secc", "")) == "kits":
				## La equipación abre su diseñador a pantalla completa (Principal se esconde): debe haber una pantalla nueva y se vuelve sin quedarse atascado.
				if _p.visible and get_tree().root.get_child_count() == _raiz0.size():
					mal_pestana.append(nombre + " (no abre el diseñador)")
				await _cerrar_todo()
				_comprobar(_en_central() and _p.visible, "el diseñador de equipación se cierra y se vuelve al central (%s)" % nombre)
				continue
			var tab_ok: bool = _p._pestanas.get_tab_title(_p._pestanas.current_tab) == String(sb["tab"])
			if not tab_ok:
				mal_pestana.append("%s (pestaña %s)" % [nombre, _p._pestanas.get_tab_title(_p._pestanas.current_tab)])
			var textos := 0
			for l in pm.find_children("*", "Label", true, false):
				if (l as Label).is_visible_in_tree() and (l as Label).text.strip_edges() != "":
					textos += 1
			var botones := 0
			for bt in pm.find_children("*", "Button", true, false):
				if (bt as Button).is_visible_in_tree():
					botones += 1
			if textos < 3 and botones < 3:
				sin_contenido.append("%s (%d textos, %d botones)" % [nombre, textos, botones])
			if not _p.get_viewport_rect().encloses(pm.get_global_rect().grow(-2.0)):
				tapados.append(nombre + " (fuera de pantalla)")
			var carta := _p.get_node_or_null("CapaTutorial") as Control
			if carta != null and carta.visible and carta.size.y > 80.0:
				tapados.append(nombre + " (ayuda desplegada encima)")
			var v := _volver()
			if v == null:
				mal_volver.append(nombre + " (sin Volver)")
			else:
				v.pressed.emit()
				await _frames(24)
				if not _en_central():
					mal_volver.append(nombre + " (Volver no llega al central)")
			await _cerrar_todo()
	_linea("  %d submenús con sección probados" % total)
	_comprobar(total >= 50, "se probaron %d submenús con sección (≥ 50)" % total)
	_comprobar(mal_pestana.is_empty(), "cada submenú abre su sección y la pestaña de su menú %s" % str(mal_pestana.slice(0, 5)))
	_comprobar(sin_contenido.is_empty(), "cada submenú enseña contenido %s" % str(sin_contenido.slice(0, 5)))
	_comprobar(tapados.is_empty(), "ninguno queda fuera de pantalla ni tapado por la ayuda %s" % str(tapados.slice(0, 5)))
	_comprobar(mal_volver.is_empty(), "«Volver» devuelve siempre al central %s" % str(mal_volver.slice(0, 5)))

## Esc: del detalle a la portada y de la portada al central; en el central no hace nada raro.
func _teclado_y_volver() -> void:
	var cuenta := 0
	for mn: Dictionary in MenusLaterales.MENUS:
		var id := String(mn["id"])
		var primero := -1
		for i in (mn["subs"] as Array).size():
			if (mn["subs"][i] as Dictionary).has("tab"):
				primero = i
				break
		if primero < 0:
			continue
		_p._menu_lateral.abrir_menu(id, primero)
		await _frames(5)
		await _accion("ui_cancel")
		var pm := _abierto()
		var a_portada := pm != null and pm.submenu_activo() == -1
		await _accion("ui_cancel")
		await _frames(24)
		var a_central := _en_central()
		_comprobar(a_portada and a_central, "Esc en «%s»: detalle → portada → central" % id)
		cuenta += 1
		await _cerrar_todo()
	_comprobar(cuenta == 14 or cuenta >= 12, "Esc probado en %d menús" % cuenta)
	await _accion("ui_cancel")
	_comprobar(_en_central(), "Esc en el central no abre ni rompe nada")

## El mando: L1/R1 (`dinastia_tab_*`) pasan de submenú y L2/R2 (`dinastia_bloque_*`) de menú; una vuelta entera vuelve al punto de partida.
func _mando() -> void:
	for a in ["dinastia_tab_siguiente", "dinastia_tab_anterior", "dinastia_bloque_siguiente", "dinastia_bloque_anterior"]:
		var con_boton := false
		for e: InputEvent in InputMap.action_get_events(a):
			if e is InputEventJoypadButton or e is InputEventJoypadMotion:
				con_boton = true
		_comprobar(con_boton, "«%s» tiene botón de mando asignado" % a)
	var n_menus := MenusLaterales.MENUS.size()
	_p._menu_lateral.abrir_menu("plantel", -1)
	await _frames(5)
	var recorridos: Array[String] = []
	for k in n_menus:
		var pm := _abierto()
		recorridos.append("" if pm == null else String(pm.get_meta("id", "")))
		await _accion("dinastia_bloque_siguiente")
		await _frames(8)
	var distintos := {}
	for r in recorridos:
		distintos[r] = true
	_comprobar(distintos.size() == n_menus and not distintos.has(""), "L2/R2: %d pulsaciones recorren los %d menús sin repetir" % [n_menus, n_menus])
	var pm_fin := _abierto()
	_comprobar(pm_fin != null and String(pm_fin.get_meta("id", "")) == "plantel", "…y la vuelta entera termina donde empezó (plantel)")
	await _accion("dinastia_bloque_anterior")
	await _frames(8)
	_comprobar(_abierto() != null and String(_abierto().get_meta("id", "")) == String(MenusLaterales.MENUS[n_menus - 1]["id"]), "L2 va al menú anterior (el último, dando la vuelta)")
	## L1/R1 dentro de un menú con varios submenús.
	_p._menu_lateral.abrir_menu("plantel", 0)
	await _frames(5)
	var pasos: Array[int] = []
	var tabs := 0
	for sb: Dictionary in MenusLaterales.MENUS[0]["subs"]:
		if sb.has("tab"):
			tabs += 1
	for k in tabs:
		await _accion("dinastia_tab_siguiente")
		await _frames(4)
		pasos.append(_abierto().submenu_activo() if _abierto() != null else -99)
	var unicos := {}
	for p in pasos:
		unicos[p] = true
	_comprobar(unicos.size() == tabs and pasos[tabs - 1] == 0, "R1: %d pulsaciones recorren los %d submenús del plantel y vuelven al primero %s" % [tabs, tabs, str(pasos)])
	await _accion("dinastia_tab_anterior")
	await _frames(4)
	_comprobar(_abierto() != null and _abierto().submenu_activo() == tabs - 1, "L1 retrocede (del primero al último)")
	await _cerrar_todo()
	_comprobar(_en_central(), "tras navegar con el mando, cerrar vuelve al central")

## El dedo: el toque llega a CADA botón del riel (nada lo tapa, con el central abierto y con un menú encima) y mide lo que un dedo necesita.
## (El viewport sin pantalla no entrega ratón ni toques a la interfaz, así que se busca el control que recibiría el toque con las reglas del motor:
## el último de los visibles, de arriba abajo, cuyo rectángulo contiene el punto y que no ignora el ratón.)
func _arriba(nodo: Node, pos: Vector2) -> Control:
	var hijos := nodo.get_children()
	hijos.reverse()
	for h in hijos:
		if h is Control and (h as Control).visible and (h as Control).get_global_rect().has_point(pos):
			var dentro := _arriba(h, pos)
			if dentro != null:
				return dentro
			if (h as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
				return h as Control
		elif h is CanvasLayer or (h is Node and not h is Control and not h is Window):
			var d2 := _arriba(h, pos)
			if d2 != null:
				return d2
	return null

func _toque() -> void:
	var tapados: Array[String] = []
	var chicos: Array[String] = []
	for estado in ["central", "menu abierto"]:
		if estado == "menu abierto":
			_p._menu_lateral.abrir_menu("plantel", -1)
			await _frames(5)
		for mn: Dictionary in MenusLaterales.MENUS:
			var id := String(mn["id"])
			var b := _p._menu_lateral.boton_de(id)
			var r := b.get_global_rect()
			var c := r.get_center()
			if r.size.x < 36.0 or r.size.y < 36.0:
				chicos.append("%s %s" % [id, str(r.size)])
			var top := _arriba(_p, c)
			if top != b and not b.is_ancestor_of(top):
				tapados.append("%s (%s, %s)" % [id, estado, top.name if top != null else "nada"])
	await _cerrar_todo()
	_comprobar(chicos.is_empty(), "los 14 botones del riel miden al menos 36 px (dedo) %s" % str(chicos))
	_comprobar(tapados.is_empty(), "el toque llega a cada botón del riel, con el central y con un menú abierto %s" % str(tapados.slice(0, 4)))
	_comprobar(_en_central(), "y se termina en el central")

## Desde cualquier pestaña (`_ir_a_pestana`, lo que usan los botones del central) se abre su submenú correcto y la acción se hace con el menú del propio dueño.
func _pestanas_a_menu() -> void:
	var mal: Array[String] = []
	var n := 0
	for i in _p._pestanas.get_tab_count():
		var t := _p._pestanas.get_tab_title(i)
		if t == "Inicio":
			continue
		n += 1
		_p._ir_a_pestana(t)
		await _frames(5)
		var pm := _abierto()
		if pm == null:
			mal.append(t + " (no abre menú)")
		else:
			var sub: int = pm.submenu_activo()
			var subs: Array = pm.menu()["subs"]
			if sub < 0 or sub >= subs.size() or String((subs[sub] as Dictionary).get("tab", "")) != t:
				mal.append("%s (abre %s sub %d)" % [t, pm.get_meta("id", ""), sub])
		await _cerrar_todo()
	_comprobar(mal.is_empty(), "las %d pestañas del central abren su submenú con `_ir_a_pestana` %s" % [n, str(mal.slice(0, 5))])
	_comprobar(_en_central(), "y se termina en el central")
