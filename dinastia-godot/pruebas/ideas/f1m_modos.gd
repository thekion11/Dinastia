extends BaseIdea
## EL MENÚ INICIAL DE MODOS (fase 1, etapa 2: `ui/entrada/menu_modos.gd`). Comprueba el
## contrato de las pantallas de entrada (configurar / terminado / volver), que cada modo de
## `MODOS_JUEGO` tiene su ambiente de fondo y su ficha, que pasar el ratón o el foco cambia el
## fondo CON fundido, que el logo espera 20 s, que nada sigue sin confirmar, y que se maneja
## con ratón, teclado y mando por el mismo camino (el foco).

func _probar() -> void:
	_titulo("FASE 1 · ETAPA 2: MENÚ INICIAL DE MODOS")
	var tabla: Array = Datos.tabla("MODOS_JUEGO")

	# --- contrato y lista ---------------------------------------------------------
	var p := PantallaModos.new()
	_comprobar(p.has_signal("terminado") and p.has_signal("volver") and p.has_method("configurar"),
		"cumple el contrato de las pantallas de entrada (terminado, volver, configurar)")
	p.configurar({"modo": "cantera", "idioma": "es"})
	add_child(p)
	var vista := get_viewport().get_visible_rect().size
	_comprobar(p.size.is_equal_approx(vista) and p.fondo().size.is_equal_approx(vista),
		"colgada de un Node (no de un Control) ocupa la ventana entera, con el fondo detrás (%s)" % str(p.size))
	_comprobar(p.ficha().size.x > 300.0 and p.ficha().get_global_rect().position.x > vista.x * 0.35,
		"la ficha tiene su ancho de verdad, a la derecha de la lista (no se aplasta en la esquina)")
	_comprobar(p.modos().size() == tabla.size() and p.botones().size() == tabla.size(),
		"la lista trae los %d modos de MODOS_JUEGO, un botón por modo" % tabla.size())
	_comprobar(p.modo_seleccionado() == "cantera" and p.fondo().clave() == "cantera",
		"configurar({modo}) antes de entrar deja ese modo elegido y su fondo puesto")
	_comprobar(p.fondo().capas_vivas() == 1 and not p.fondo().en_transicion(),
		"al abrir, el primer fondo sale de golpe (no hay nada de lo que fundir)")
	_comprobar(p.fondo().estilo_visible() == int(MenuModosFondo.AMBIENTES["cantera"]["estilo"]),
		"el fondo de cantera usa su estilo de fondo_menu.gdshader")

	var sin_ambiente: Array = []
	var sin_rasgos: Array = []
	for m: Dictionary in tabla:
		var id := String(m.get("id", ""))
		if not MenuModosFondo.AMBIENTES.has(id):
			sin_ambiente.append(id)
		if MenuModosFicha.rasgos_de(id).size() != 3:
			sin_rasgos.append(id)
	_comprobar(sin_ambiente.is_empty(), "cada modo tiene su ambiente de fondo propio %s" % str(sin_ambiente))
	_comprobar(sin_rasgos.is_empty(), "cada modo tiene sus tres rasgos en la ficha %s" % str(sin_rasgos))
	var iguales := 0
	for i in range(1, p.modos().size()):
		if MenuModosFondo.ambiente_de(p.modos()[i])["estilo"] == MenuModosFondo.ambiente_de(p.modos()[i - 1])["estilo"]:
			iguales += 1
	_comprobar(iguales == 0, "dos modos vecinos de la lista nunca comparten estilo de fondo (el cambio se nota)")
	var raro := MenuModosFondo.ambiente_de({"id": "nuevo-modo", "c1": "#123456", "c2": "#abcdef"})
	_comprobar(int(raro["estilo"]) >= 0 and int(raro["estilo"]) <= 8 and (raro["c"] as Array).size() == 3,
		"un modo nuevo sin ambiente en la tabla no se queda sin fondo (sale de sus colores)")
	var secciones_ok := true
	for m in p.modos():
		if String(m.get("cat", "")) == "dirigir" and String(m.get("_sec", "")) != "Dirigir":
			secciones_ok = false
	_comprobar(secciones_ok and String(p.modos()[0].get("cat", "")) == "dirigir",
		"los modos van agrupados por MODO_SECCIONES, en su orden (primero «Dirigir»)")

	# --- pasar el cursor / el foco ------------------------------------------------
	var i_dt := _indice(p, "dt")
	var i_imp := _indice(p, "imperio")
	p.botones()[i_dt].mouse_entered.emit()
	_comprobar(p.modo_seleccionado() == "dt" and p.fondo().clave() == "dt",
		"pasar el ratón por «Director Técnico» lo elige y cambia el fondo")
	_comprobar(p.fondo().en_transicion() and p.fondo().capas_vivas() == 2,
		"el cambio es un fundido: el fondo nuevo entra encima del anterior")
	_comprobar(p.ficha().titulo() == "Director Técnico" and p.ficha().descripcion() == String(tabla[0]["sub"]),
		"la ficha enseña el nombre y la descripción corta del modo bajo el cursor")
	_comprobar(p.ficha().rasgos_visibles() == 3, "y sus tres rasgos")
	p.botones()[i_imp].grab_focus()
	_comprobar(p.modo_seleccionado() == "imperio" and p.fondo().estilo_visible() == 7,
		"con teclado/mando (foco) pasa lo mismo: «Dueño de Club» pone la ciudad de noche (estilo 7)")
	for k in 6:
		p.botones()[k].grab_focus()
	_comprobar(p.fondo().capas_vivas() <= MenuModosFondo.MAX_CAPAS,
		"recorrer la lista a toda velocidad no apila capas sin fin (≤ %d)" % MenuModosFondo.MAX_CAPAS)
	var primero := p.botones()[0]
	var ultimo := p.botones()[p.botones().size() - 1]
	_comprobar(primero.get_node_or_null(primero.focus_neighbor_top) == ultimo
		and ultimo.get_node_or_null(ultimo.focus_neighbor_bottom) == primero,
		"la lista da la vuelta con ↑/↓ (de la primera a la última y al revés)")
	var sin_sonido_doble := true
	for b in p.botones():
		if not b.has_meta("sin_sonido"):
			sin_sonido_doble = false
	_comprobar(sin_sonido_doble, "los botones llevan su propio sonido (menu_mover/aceptar/atrás), sin el tic duplicado de BotonFx")

	# --- logo a los 20 s ----------------------------------------------------------
	_comprobar(not p.logo().visible and p.reloj_logo().one_shot and is_equal_approx(p.reloj_logo().wait_time, 20.0)
		and not p.reloj_logo().is_stopped(), "el logo no está al abrir: un reloj de 20 s lo espera")
	_comprobar(p.logo().anchor_left == 1.0 and p.logo().anchor_right == 1.0 and p.logo().offset_top < 60.0,
		"el logo va arriba a la derecha")
	p.reloj_logo().timeout.emit()
	_comprobar(p.logo().visible, "a los 20 s aparece el logo")
	p.logo().completar()
	_comprobar(is_equal_approx(p.logo().progreso, 1.0) and p.logo().mostrado(), "y se dibuja entero")

	# --- confirmación -------------------------------------------------------------
	var emitidos: Array = []
	var vueltas: Array = []
	p.terminado.connect(func(d: Dictionary) -> void: emitidos.append(d))
	p.volver.connect(func() -> void: vueltas.append(true))
	p.elegir(i_imp)
	_comprobar(p.confirmacion().abierto() and emitidos.is_empty(),
		"elegir un modo pide confirmación antes de seguir")
	_comprobar(p.confirmacion().boton_empezar().has_focus(), "con el foco en «Empezar» (Intro / A confirma)")
	p._unhandled_input(_accion("ui_cancel"))
	_comprobar(not p.confirmacion().abierto() and emitidos.is_empty() and vueltas.is_empty(),
		"Esc / B cierra la confirmación sin elegir y sin salir del menú")
	_comprobar(p.botones()[i_imp].has_focus(), "y el foco vuelve al modo que se estaba mirando")
	p.botones()[i_imp].pressed.emit()
	p.confirmacion().confirmar()
	_comprobar(emitidos.size() == 1 and emitidos[0] == {"modo": "imperio"},
		"confirmar emite terminado({\"modo\": clave}) con la clave de MODOS_JUEGO")
	p.elegir(i_dt)
	p.confirmacion().confirmar()
	_comprobar(emitidos.size() == 1 and not p.confirmacion().abierto(), "y solo una vez")

	# --- volver -------------------------------------------------------------------
	var q := PantallaModos.new()
	add_child(q)
	var qv: Array = []
	q.volver.connect(func() -> void: qv.append(true))
	_comprobar(q.modo_seleccionado() == String(tabla[0]["id"]), "sin estado previo, el primero de la lista queda elegido")
	q._unhandled_input(_accion("ui_cancel"))
	_comprobar(qv.size() == 1, "Esc / B sin confirmación abierta emite volver()")
	q.configurar({"modo": "carrera-m"})
	_comprobar(q.modo_seleccionado() == "carrera-m" and q.fondo().clave() == "carrera-m",
		"configurar() después de entrar también cambia el modo elegido")

	# --- modos que no se pueden jugar ---------------------------------------------
	_comprobar(not PantallaModos.jugable({"cat": "proximo"}) and PantallaModos.jugable({"cat": "dirigir"}),
		"un modo «proximo» no se puede confirmar; los demás sí")

	# --- motor ligero e idioma ----------------------------------------------------
	var ligero := Calidad.motor_ligero
	Calidad.motor_ligero = true
	var fl := MenuModosFondo.new()
	add_child(fl)
	fl.mostrar(tabla[0], true)
	var capa: Node = fl.get_child(0)
	_comprobar((capa.get_child(0) as ColorRect).material == null,
		"con el motor ligero el fondo es de color fijo (sin shader que redibuje cada fotograma)")
	Calidad.motor_ligero = ligero
	fl.queue_free()
	var antes := Idiomas.idioma
	Idiomas.idioma = "en"
	var e := PantallaModos.new()
	add_child(e)
	_comprobar(e.botones()[0].text == "Head Coach" and e.ficha().titulo() == "Head Coach",
		"en inglés, la lista y la ficha salen traducidas («Head Coach»)")
	Idiomas.idioma = antes
	for n in [p, q, e]:
		n.queue_free()

func _indice(p: PantallaModos, id: String) -> int:
	for i in p.modos().size():
		if String(p.modos()[i].get("id", "")) == id:
			return i
	return -1

func _accion(nombre: String) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = nombre
	ev.pressed = true
	return ev
