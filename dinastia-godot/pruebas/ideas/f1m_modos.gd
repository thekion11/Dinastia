extends BaseIdea
## EL MENÚ INICIAL DE MODOS (fase 1, etapa 2: `ui/entrada/menu_modos.gd`). Comprueba el
## contrato de las pantallas de entrada (configurar / terminado / volver), que cada modo de
## `MODOS_JUEGO` tiene su ambiente de fondo y su ficha, que pasar el ratón o el foco cambia el
## fondo CON fundido, que el logo espera 20 s, que nada sigue sin confirmar, y que se maneja
## con ratón, teclado y mando por el mismo camino (el foco).

var _p: PantallaModos
var _q: PantallaModos
var _tabla: Array
var _i_dt := 0
var _i_imp := 0

func _probar() -> void:
	_modos_01_bloque()
	_modos_02_contrato_y_lista()
	_modos_03_pasar_el_cursor_el_foc()
	_modos_04_logo_a_los_20_s()
	_modos_05_confirmaci_n()
	_modos_06_volver()
	_modos_07_modos_que_no_se_pueden()
	_modos_08_motor_ligero_e_idioma()

func _modos_01_bloque() -> void:
	_titulo("FASE 1 · ETAPA 2: MENÚ INICIAL DE MODOS")
	_tabla = Datos.tabla("MODOS_JUEGO")

func _modos_02_contrato_y_lista() -> void:
	# --- contrato y lista ---------------------------------------------------------
	_p = PantallaModos.new()
	_comprobar(_p.has_signal("terminado") and _p.has_signal("volver") and _p.has_method("configurar"),
		"cumple el contrato de las pantallas de entrada (terminado, volver, configurar)")
	_p.configurar({"modo": "cantera", "idioma": "es"})
	add_child(_p)
	var vista := get_viewport().get_visible_rect().size
	_comprobar(_p.size.is_equal_approx(vista) and _p.fondo().size.is_equal_approx(vista),
		"colgada de un Node (no de un Control) ocupa la ventana entera, con el fondo detrás (%s)" % str(_p.size))
	_comprobar(_p.ficha().size.x > 300.0 and _p.ficha().get_global_rect().position.x > vista.x * 0.35,
		"la ficha tiene su ancho de verdad, a la derecha de la lista (no se aplasta en la esquina)")
	_comprobar(_p.modos().size() == _tabla.size() and _p.botones().size() == _tabla.size(),
		"la lista trae los %d modos de MODOS_JUEGO, un botón por modo" % _tabla.size())
	_comprobar(_p.modo_seleccionado() == "cantera" and _p.fondo().clave() == "cantera",
		"configurar({modo}) antes de entrar deja ese modo elegido y su fondo puesto")
	_comprobar(_p.fondo().capas_vivas() == 1 and not _p.fondo().en_transicion(),
		"al abrir, el primer fondo sale de golpe (no hay nada de lo que fundir)")
	_comprobar(_p.fondo().estilo_visible() == int(MenuModosFondo.AMBIENTES["cantera"]["estilo"]),
		"el fondo de cantera usa su estilo de fondo_menu.gdshader")

	var sin_ambiente: Array = []
	var sin_rasgos: Array = []
	for m: Dictionary in _tabla:
		var id := String(m.get("id", ""))
		if not MenuModosFondo.AMBIENTES.has(id):
			sin_ambiente.append(id)
		if MenuModosFicha.rasgos_de(id).size() != 3:
			sin_rasgos.append(id)
	_comprobar(sin_ambiente.is_empty(), "cada modo tiene su ambiente de fondo propio %s" % str(sin_ambiente))
	_comprobar(sin_rasgos.is_empty(), "cada modo tiene sus tres rasgos en la ficha %s" % str(sin_rasgos))
	var iguales := 0
	for i in range(1, _p.modos().size()):
		if MenuModosFondo.ambiente_de(_p.modos()[i])["estilo"] == MenuModosFondo.ambiente_de(_p.modos()[i - 1])["estilo"]:
			iguales += 1
	_comprobar(iguales == 0, "dos modos vecinos de la lista nunca comparten estilo de fondo (el cambio se nota)")
	var raro := MenuModosFondo.ambiente_de({"id": "nuevo-modo", "c1": "#123456", "c2": "#abcdef"})
	_comprobar(int(raro["estilo"]) >= 0 and int(raro["estilo"]) <= 8 and (raro["c"] as Array).size() == 3,
		"un modo nuevo sin ambiente en la tabla no se queda sin fondo (sale de sus colores)")
	var secciones_ok := true
	for m in _p.modos():
		if String(m.get("cat", "")) == "dirigir" and String(m.get("_sec", "")) != "Dirigir":
			secciones_ok = false
	_comprobar(secciones_ok and String(_p.modos()[0].get("cat", "")) == "dirigir",
		"los modos van agrupados por MODO_SECCIONES, en su orden (primero «Dirigir»)")

func _modos_03_pasar_el_cursor_el_foc() -> void:
	# --- pasar el cursor / el foco ------------------------------------------------
	_i_dt = _indice(_p, "dt")
	_i_imp = _indice(_p, "imperio")
	_p.botones()[_i_dt].mouse_entered.emit()
	_comprobar(_p.modo_seleccionado() == "dt" and _p.fondo().clave() == "dt",
		"pasar el ratón por «Director Técnico» lo elige y cambia el fondo")
	_comprobar(_p.fondo().en_transicion() and _p.fondo().capas_vivas() == 2,
		"el cambio es un fundido: el fondo nuevo entra encima del anterior")
	_comprobar(_p.ficha().titulo() == "Director Técnico" and _p.ficha().descripcion() == String(_tabla[0]["sub"]),
		"la ficha enseña el nombre y la descripción corta del modo bajo el cursor")
	_comprobar(_p.ficha().rasgos_visibles() == 3, "y sus tres rasgos")
	_p.botones()[_i_imp].grab_focus()
	_comprobar(_p.modo_seleccionado() == "imperio" and _p.fondo().estilo_visible() == 7,
		"con teclado/mando (foco) pasa lo mismo: «Dueño de Club» pone la ciudad de noche (estilo 7)")
	for k in 6:
		_p.botones()[k].grab_focus()
	_comprobar(_p.fondo().capas_vivas() <= MenuModosFondo.MAX_CAPAS,
		"recorrer la lista a toda velocidad no apila capas sin fin (≤ %d)" % MenuModosFondo.MAX_CAPAS)
	var primero = _p.botones()[0]
	var ultimo = _p.botones()[_p.botones().size() - 1]
	_comprobar(primero.get_node_or_null(primero.focus_neighbor_top) == ultimo
		and ultimo.get_node_or_null(ultimo.focus_neighbor_bottom) == primero,
		"la lista da la vuelta con ↑/↓ (de la primera a la última y al revés)")
	var sin_sonido_doble := true
	for b in _p.botones():
		if not b.has_meta("sin_sonido"):
			sin_sonido_doble = false
	_comprobar(sin_sonido_doble, "los botones llevan su propio sonido (menu_mover/aceptar/atrás), sin el tic duplicado de BotonFx")

func _modos_04_logo_a_los_20_s() -> void:
	# --- logo a los 20 s ----------------------------------------------------------
	_comprobar(not _p.logo().visible and _p.reloj_logo().one_shot and is_equal_approx(_p.reloj_logo().wait_time, 20.0)
		and not _p.reloj_logo().is_stopped(), "el logo no está al abrir: un reloj de 20 s lo espera")
	_comprobar(is_equal_approx(_p.logo().anchor_left, 1.0) and is_equal_approx(_p.logo().anchor_right, 1.0) and _p.logo().offset_top < 60.0,
		"el logo va arriba a la derecha")
	_p.reloj_logo().timeout.emit()
	_comprobar(_p.logo().visible, "a los 20 s aparece el logo")
	_p.logo().completar()
	_comprobar(is_equal_approx(_p.logo().progreso, 1.0) and _p.logo().mostrado(), "y se dibuja entero")

func _modos_05_confirmaci_n() -> void:
	# --- confirmación -------------------------------------------------------------
	var emitidos: Array = []
	var vueltas: Array = []
	_p.terminado.connect(func(d: Dictionary) -> void: emitidos.append(d))
	_p.volver.connect(func() -> void: vueltas.append(true))
	_p.elegir(_i_imp)
	_comprobar(_p.confirmacion().abierto() and emitidos.is_empty(),
		"elegir un modo pide confirmación antes de seguir")
	_comprobar(_p.confirmacion().boton_empezar().has_focus(), "con el foco en «Empezar» (Intro / A confirma)")
	_p._unhandled_input(_accion("ui_cancel"))
	_comprobar(not _p.confirmacion().abierto() and emitidos.is_empty() and vueltas.is_empty(),
		"Esc / B cierra la confirmación sin elegir y sin salir del menú")
	_comprobar(_p.botones()[_i_imp].has_focus(), "y el foco vuelve al modo que se estaba mirando")
	_p.botones()[_i_imp].pressed.emit()
	_p.confirmacion().confirmar()
	_comprobar(emitidos.size() == 1 and emitidos[0] == {"modo": "imperio"},
		"confirmar emite terminado({\"modo\": clave}) con la clave de MODOS_JUEGO")
	_p.elegir(_i_dt)
	_p.confirmacion().confirmar()
	_comprobar(emitidos.size() == 1 and not _p.confirmacion().abierto(), "y solo una vez")

func _modos_06_volver() -> void:
	# --- volver -------------------------------------------------------------------
	_q = PantallaModos.new()
	add_child(_q)
	var qv: Array = []
	_q.volver.connect(func() -> void: qv.append(true))
	_comprobar(_q.modo_seleccionado() == String(_tabla[0]["id"]), "sin estado previo, el primero de la lista queda elegido")
	_q._unhandled_input(_accion("ui_cancel"))
	_comprobar(qv.size() == 1, "Esc / B sin confirmación abierta emite volver()")
	_q.configurar({"modo": "carrera-m"})
	_comprobar(_q.modo_seleccionado() == "carrera-m" and _q.fondo().clave() == "carrera-m",
		"configurar() después de entrar también cambia el modo elegido")

func _modos_07_modos_que_no_se_pueden() -> void:
	# --- modos que no se pueden jugar ---------------------------------------------
	_comprobar(not PantallaModos.jugable({"cat": "proximo"}) and PantallaModos.jugable({"cat": "dirigir"}),
		"un modo «proximo» no se puede confirmar; los demás sí")

func _modos_08_motor_ligero_e_idioma() -> void:
	# --- motor ligero e idioma ----------------------------------------------------
	var ligero := Calidad.motor_ligero
	Calidad.motor_ligero = true
	var fl := MenuModosFondo.new()
	add_child(fl)
	fl.mostrar(_tabla[0], true)
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
	for n in [_p, _q, e]:
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

