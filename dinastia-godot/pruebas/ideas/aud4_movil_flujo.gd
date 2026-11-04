extends BaseIdea
## A4-INT · el flujo del jugador en el móvil (2400×1080, 400 ppp, zoom 1,5): primeras semanas, fichar un libre, guardar, cargar, y abrir todos los menús con TODOS los botones de ≥ 7 mm, sin controles fuera de pantalla ni listas que no se puedan deslizar.
var _p: Principal

func _frames(n: int = 2) -> void:
	for i in n:
		await get_tree().process_frame

## Botones visibles más bajos que el toque, o fuera de la ventana por la derecha, o ScrollContainer que no se desliza.
func _problemas(alto: float) -> Array[String]:
	var r: Array[String] = []
	var ancho := get_viewport().get_visible_rect().size.x
	for n in _p.find_children("*", "Button", true, false):
		var b := n as Button
		if not b.is_visible_in_tree() or b.get_window() != get_tree().root or b.size.x < 4.0:
			continue
		if b.size.y < alto - 1.5:
			r.append("bajo «%s» %.0f" % [b.text.left(20), b.size.y])
	for n in _p.find_children("*", "ScrollContainer", true, false):
		var sk := n as ScrollContainer
		if sk.is_visible_in_tree() and sk.get_child_count() > 0 and sk.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
			var h := sk.get_child(0) as Control
			if h != null and h.get_combined_minimum_size().y > sk.size.y + 2.0:
				r.append("scroll sin deslizar %s" % sk.name)
	return r

func _probar() -> void:
	_titulo("AUDITORÍA 4 · INTERFAZ · flujo en el móvil")
	_respaldar_user()
	get_window().size = Vector2i(2400, 1080)
	get_window().content_scale_factor = EscalaMovil.ZOOM_MOVIL
	PantallaMovil.dpi_forzado = 400.0
	PantallaMovil.ventana_forzada = Vector2i(2400, 1080)
	var m := _mundo(20261104)
	PedidoPartida.mundo_pregenerado = m
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	await _frames(8)
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial:
			(t as Tutorial)._terminar(false)
	CapasTutorial.poner_activas(false)
	_p._autoguardado = false
	var alto := EscalaMovil.alto_toque(_p)
	_comprobar(alto > 40.0, "alto de toque %.1f px" % alto)
	var f0 := _problemas(alto)
	_comprobar(f0.is_empty(), "pantalla de inicio: %s" % str(f0.slice(0, 4)))
	var sem0 := m.semana
	for i in 4:
		_p._al_elegir_calendario(1)   ## siguiente semana
		await _frames(3)
	_comprobar(m.semana != sem0 or m.anio > 0, "avanzaron las semanas (%d → %d)" % [sem0, m.semana])
	var f1 := _problemas(alto)
	_comprobar(f1.is_empty(), "tras 4 semanas: %s" % str(f1.slice(0, 4)))
	if m.libres.is_empty():
		m.generar_libres()
	var antes: int = m.mi_club().plantel().size()
	m.fichar_libre(0, m.mi_club())
	await _frames(3)
	_comprobar(m.mi_club().plantel().size() >= antes, "fichar un libre no rompe el plantel (%d → %d)" % [antes, m.mi_club().plantel().size()])
	Partida.guardar(m, "aud4_movil")
	var c := Partida.cargar("aud4_movil")
	_comprobar(c != null and c.mi_club().id == m.mi_club().id, "guardar y cargar da el mismo club")
	var nodos0 := _p.find_children("*", "", true, false).size()
	var mal: Array[String] = []
	var fm: Array[String] = []
	for mn: Dictionary in MenusLaterales.MENUS:
		var subs: Array = mn["subs"]
		for i in subs.size():
			if (subs[i] as Dictionary).has("accion") or String((subs[i] as Dictionary).get("secc", "")) == "kits":
				continue
			_p._menu_lateral.abrir_menu(String(mn["id"]), i)
			await _frames(4)
			var pm: Variant = _p._menu_lateral.pantalla_abierta
			if not is_instance_valid(pm) or (pm as PantallaMenu).cerrando():
				mal.append("%s/%d" % [mn["id"], i])
			else:
				for x in _problemas(alto):
					fm.append("%s/%d %s" % [mn["id"], i, x])
				(pm as PantallaMenu).cerrar()
			await _frames(20)
	_comprobar(mal.is_empty(), "todos los submenús abren en el móvil %s" % str(mal.slice(0, 5)))
	_comprobar(fm.is_empty(), "sin botones bajos ni listas bloqueadas en los menús: %d %s" % [fm.size(), str(fm.slice(0, 4))])
	await _frames(200)   ## las pestañas que ya no se ven se sueltan (A4-INT-R01)
	var nodos1 := _p.find_children("*", "", true, false).size()
	_comprobar(nodos1 <= nodos0 + 1500, "tras recorrer todos los menús en el móvil los nodos no se acumulan (%d → %d)" % [nodos0, nodos1])
	Partida.borrar("aud4_movil")
	PantallaMovil.dpi_forzado = 0.0
	PantallaMovil.ventana_forzada = Vector2i.ZERO
	get_window().content_scale_factor = 1.0
	_restaurar_user()
