extends BaseIdea
## LA AYUDA Y «VER OTRO CLUB» CON EL MENÚ DEL RIEL (3-11-2026): la tarjeta de ayuda de capas sale PLEGADA dentro de un menú
## (no tapa la ficha ni los botones), se despliega al pulsarla y no pasa de un menú al siguiente; «Ver otro club» cierra
## el menú de Competiciones antes de abrir «Elegir club».
var _p: Principal

func _tarjeta() -> PanelContainer:
	return _p.get_node_or_null("CapaTutorial") as PanelContainer

func _probar() -> void:
	_titulo("AYUDA PLEGADA EN LOS MENÚS Y «VER OTRO CLUB»")
	var m := Mundo.new()
	m.generar(["CHI"], 20261103)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	PedidoPartida.mundo_pregenerado = m
	CapasTutorial.forzar = true
	CapasTutorial.reiniciar()
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 4:
		await get_tree().process_frame
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial:
			(t as Tutorial)._terminar(false)
	_p._menu_lateral.abrir_menu("plantel", 0)
	for i in 6:
		await get_tree().process_frame
	var t1 := _tarjeta()
	_comprobar(t1 != null, "al abrir el menú sale la tarjeta de ayuda de su sección")
	if t1 != null:
		var cuerpo := t1.get_child(0).get_child(1) as Control
		_comprobar(not cuerpo.is_visible_in_tree() and t1.size.y < 80.0, "sale plegada (%d px de alto), sin tapar el contenido" % int(t1.size.y))
		(t1.get_child(0).get_child(0) as Button).pressed.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		_comprobar(cuerpo.visible and t1.size.y > 100.0, "al pulsarla se despliega (%d px)" % int(t1.size.y))
	_p._menu_lateral.abrir_menu("dinero", 0)
	for i in 6:
		await get_tree().process_frame
	var t2 := _tarjeta()
	_comprobar(t2 == null or t2 != t1, "la tarjeta de un menú no pasa al siguiente")
	var co := MenusLaterales.menu_por_id("competiciones")
	var otro := 0
	for i in (co["subs"] as Array).size():
		if String(co["subs"][i].get("accion", "")) == "elegir_club":
			otro = i
	_p._menu_lateral.abrir_menu("competiciones", otro)
	for i in 30:
		await get_tree().process_frame
	var pm = _p._menu_lateral.pantalla_abierta
	_comprobar(not is_instance_valid(pm) or pm.cerrando(), "«Ver otro club» cierra el menú de Competiciones")
	_comprobar(_p.find_children("*", "Window", false, false).any(func(w: Node) -> bool: return (w as Window).title == Idiomas.t("Elegir club")), "y abre «Elegir club»")
	CapasTutorial.forzar = false
	CapasTutorial.reiniciar()
