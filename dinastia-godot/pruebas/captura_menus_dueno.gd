extends Node
## RECORRIDO CON FOTOS DEL MENÚ NUEVO, para que el dueño lo revise (3-11-2026): el central (lunes y jueves), cada menú del
## riel en su PORTADA y en su primer submenú, Ajustes → Partida y → Accesibilidad, el diálogo de salir y Competiciones →
## «Ver otro club». Las fotos van FUERA del repo (OUT, por defecto /tmp/fotos_menus) y de ahí salen las hojas de contacto
## (`herramientas/hoja_contacto.py`). Lanzar con: herramientas/captura_menus.sh
var _p: Principal
var _dir := "/tmp/fotos_menus"
var _n := 0

func _espera(s: float = 1.2) -> void:
	await get_tree().create_timer(s).timeout
	await get_tree().process_frame

func _foto(nombre: String) -> void:
	await _espera(0.8)
	_n += 1
	var img := get_viewport().get_texture().get_image()
	var ruta := "%s/%02d_%s.jpg" % [_dir, _n, nombre]
	img.save_jpg(ruta, 0.9)
	print("foto %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
	## (12-11) El diseñador de equipación es una capa a pantalla completa: si se queda abierto, tapa todas las fotos que vienen después.
	for d in get_tree().root.find_children("*", "DisenadorKit", true, false):
		d.call("_cerrar")

func _cerrar() -> void:
	var pm = _p._menu_lateral.pantalla_abierta
	if is_instance_valid(pm) and not pm.cerrando():
		pm.cerrar()
	await _espera(0.9)

func _sub_de(menu: Dictionary, secc: String) -> int:
	var subs: Array = menu["subs"]
	for i in subs.size():
		if String((subs[i] as Dictionary).get("secc", "")) == secc:
			return i
	return 0

## (12-11) Los eventos con diálogo a pantalla completa (reunión con la directiva de la semana 1, `EventosClub`) tapaban TODAS las fotos del
## recorrido: se dan por contestados antes de abrir el menú.
func _despachar_eventos(m: Mundo) -> void:
	for k in 4:
		var ev := EventosClub.pendiente(m)
		if ev.is_empty():
			return
		EventosClub.aplicar(m, ev, 0)

func _ready() -> void:
	if OS.get_environment("OUT") != "":
		_dir = OS.get_environment("OUT")
	DirAccess.make_dir_recursive_absolute(_dir)
	## MOVIL=1: como en un teléfono (zoom de interfaz del móvil; con una ventana más alta que ancha, RESOLUCION=608x1080, el diseño vertical).
	if OS.get_environment("MOVIL") == "1":
		EscalaMovil.forzar = true
		EscalaMovil.poner(get_tree(), EscalaMovil.ZOOM_MOVIL)
	var m := Mundo.new()
	## PAIS=ARG CLUB=7: otro país y otro club (regla 34: nunca revisar con un solo equipo).
	m.generar([OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"], 20261103)
	m.tomar_el_mando(m.ligas[0].clubes[int(OS.get_environment("CLUB")) % m.ligas[0].clubes.size()].id)
	if OS.get_environment("EVENTOS") != "1":   ## EVENTOS=1: se dejan (la primera foto es la reunión con la directiva a pantalla completa)
		_despachar_eventos(m)
	PedidoPartida.mundo_pregenerado = m
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	await _espera(2.5)
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial:
			(t as Tutorial)._terminar(false)
	## Las tarjetas de ayuda («Entendido»…) se quedan encima de los menús y tapan lo que se quiere ver: AYUDAS=1 las deja.
	var ayudas_antes := CapasTutorial.activas()
	if OS.get_environment("AYUDAS") != "1":
		CapasTutorial.poner_activas(false)
	for c in _p.find_children("CapaTutorial", "", true, false):
		c.queue_free()
	await _espera(1.0)
	await _foto("central_lunes")
	var menus: Array = MenusLaterales.MENUS
	## ABRIR=calendario,palmares: foto de esas pantallas completas (calendario de semanas, palmarés del mundo) y fin.
	if OS.get_environment("ABRIR") != "":
		for que: String in OS.get_environment("ABRIR").split(","):
			if que == "calendario":
				CalendarioSemanas.mostrar(_p, _p.mundo)
			else:
				MenuLateral.ejecutar(_p, "palmares_mundo")
			await _foto(que)
			for h in _p.get_children():
				if h is EventoPantallaCompleta:
					h.queue_free()
			await _espera(0.5)
		CapasTutorial.poner_activas(ayudas_antes)
		get_tree().quit()
		return
	## SOLO_MENU=dinero: solo ese menú, con TODOS sus submenús de pestaña (y sin el resto del recorrido).
	var solo := OS.get_environment("SOLO_MENU")
	if solo != "":
		var ms := MenusLaterales.menu_por_id(solo)
		_p._menu_lateral.abrir_menu(solo, -1)
		await _foto("%s_portada" % solo)
		for i in (ms["subs"] as Array).size():
			## SOLO_TAB=Entrenar: de ese menú, solo los submenús de esa pestaña.
			if (ms["subs"][i] as Dictionary).has("tab") and OS.get_environment("SOLO_TAB") in ["", String(ms["subs"][i]["tab"])]:
				_p._menu_lateral.abrir_menu(solo, i)
				await _foto("%s_%s" % [solo, String(ms["subs"][i].get("secc", ms["subs"][i].get("tab", "")))])
		CapasTutorial.poner_activas(ayudas_antes)
		get_tree().quit()
		return
	for mn: Dictionary in menus:
		var id := String(mn["id"])
		_p._menu_lateral.abrir_menu(id, -1)
		await _foto("%s_portada" % id)
		var primero := 0
		for i in (mn["subs"] as Array).size():
			if (mn["subs"][i] as Dictionary).has("tab"):
				primero = i
				break
		_p._menu_lateral.abrir_menu(id, primero)
		await _foto("%s_sub_%s" % [id, String(mn["subs"][primero].get("label", "0")).to_lower().replace(" ", "_")])
		await _cerrar()
	var aj := MenusLaterales.menu_por_id("ajustes")
	_p._menu_lateral.abrir_menu("ajustes", _sub_de(aj, "partida"))
	await _foto("ajustes_partida")
	_p._menu_lateral.abrir_menu("ajustes", _sub_de(aj, "acceso"))
	await _foto("ajustes_accesibilidad_teclas")
	await _cerrar()
	_p.get_node("SalidaGuardada").pedir_salir(false)
	await _foto("dialogo_guardar_antes_de_salir")
	for d in _p.find_children("DialogoSalir", "", true, false):
		(d as Window).hide()
	await _espera(0.5)
	var co := MenusLaterales.menu_por_id("competiciones")
	var otro := 0
	for i in (co["subs"] as Array).size():
		if String(co["subs"][i].get("accion", "")) == "elegir_club":
			otro = i
	_p._menu_lateral.abrir_menu("competiciones", otro)
	await _foto("competiciones_ver_otro_club")
	await _cerrar()
	for w in get_tree().root.find_children("*", "Window", true, false):
		if w != get_tree().root and w is Window:
			(w as Window).hide()
	await _espera(0.6)
	for k in 3:
		_p._avanzar_dia()
		await _espera(1.5)
		for ev in _p.find_children("*", "EventoDialogo", true, false):
			ev.queue_free()
	await _foto("central_jueves")
	CapasTutorial.poner_activas(ayudas_antes)
	get_tree().quit()
