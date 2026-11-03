extends BaseIdea
## LA GUÍA DEL TUTORIAL CON EL CENTRAL NUEVO (3-11-2026): ningún paso señala algo invisible y cada misión se puede
## cumplir («Muéstramelo» la cumple y `hecho` lo ve). Recorre los guiones de todos los modos, más las misiones del
## panel de objetivos del mentor.
var _p: Principal
var _hijos0: Array = []
var _raiz0: Array = []

func _visible(c: Variant) -> bool:
	return is_instance_valid(c) and c.is_visible_in_tree() and c.size.x > 1.0 and c.size.y > 1.0

func _cerrar_menu() -> void:
	var pm = _p._menu_lateral.pantalla_abierta
	if is_instance_valid(pm):
		pm.cerrar()
		for i in 40:
			await get_tree().process_frame
			if not is_instance_valid(pm):
				break
	## Cualquier pantalla completa extra (el diseñador de equipación…) se cierra.
	for c in _p.get_children():
		if not _hijos0.has(c) and not (c is Tutorial):
			c.queue_free()
	for c in get_tree().root.get_children():
		if not _raiz0.has(c) and c != self:
			c.queue_free()
	_p.visible = true
	_p._ir_a_pestana("Inicio")
	await get_tree().process_frame
	await get_tree().process_frame

func _probar() -> void:
	_titulo("TUTORIAL: PASOS Y MISIONES CON EL CENTRAL NUEVO")
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
	_hijos0 = _p.get_children()
	_raiz0 = get_tree().root.get_children()
	## Toda pestaña del central (salvo Inicio) tiene submenú en el panel lateral: si no, `_abrir_en_lateral` la deja escondida.
	var con_menu := {}
	for mn: Dictionary in MenusLaterales.MENUS:
		for sb: Dictionary in mn["subs"]:
			if sb.has("tab"):
				con_menu[String(sb["tab"])] = true
	var sueltas: Array[String] = []
	for i in _p._pestanas.get_tab_count():
		var tt: String = _p._pestanas.get_tab_title(i)
		if tt != "Inicio" and not con_menu.has(tt):
			sueltas.append(tt)
	_comprobar(sueltas.is_empty(), "ninguna pestaña del central queda sin submenú %s" % str(sueltas))
	var ctx := Tutorial.contexto(m)
	var malos: Array[String] = []
	var n := 0
	var vistas := {}
	for modo: String in ["dt", "dir", "ayudante", "interino", "cantera", "jeque", "novato", "mecenas"]:
		var g := Tutorial.guion(modo, ctx)
		if not g.has("pasos"):
			continue
		for paso: Dictionary in g["pasos"]:
			var clave := String(paso.get("objetivo", ""))
			var hecho := String(paso.get("hecho", ""))
			var id := "%s/%s" % [modo, String(paso.get("titulo", ""))]
			await _cerrar_menu()
			if clave != "":
				n += 1
				if not _visible(_p._guia.objetivo(clave)):
					malos.append("%s: objetivo «%s» invisible" % [id, clave])
			if hecho != "" and not vistas.has(hecho):
				vistas[hecho] = true
				_p._guia.accion(hecho)
				for i in 3:
					await get_tree().process_frame
				if not _p._guia.hecho(hecho):
					malos.append("%s: «Muéstramelo» no cumple «%s»" % [id, hecho])
	_comprobar(n > 20 and malos.is_empty(), "%d pasos con objetivo; sin invisibles ni misiones imposibles %s" % [n, str(malos)])
