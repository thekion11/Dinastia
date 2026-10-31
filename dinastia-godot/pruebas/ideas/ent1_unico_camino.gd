extends BaseIdea
## LA ENTRADA NUEVA COMO ÚNICO CAMINO (26-10-2026): el menú de inicio ya no tiene tarjetas
## de modo ni interruptor; «Nuevo juego» lleva a la entrada, y desde ella siguen a mano los
## retos (los cinco, con selector), el tutorial y la Carrera de Jugador.

func _probar() -> void:
	OrquestadorMundo.ranura_al_salir = ""   ## no pisar la partida de la máquina (autoguardado de la entrada)
	_titulo("ENTRADA NUEVA: ÚNICO CAMINO PARA EMPEZAR PARTIDA")
	# --- el menú de inicio --------------------------------------------------------
	var inicio: Control = (load("res://escenas/inicio.tscn") as PackedScene).instantiate()
	add_child(inicio)
	var textos: Array[String] = []
	var botones: Array[String] = []
	var tarjetas := 0
	for n: Node in inicio.find_children("*", "", true, false):
		if n is Label:
			textos.append((n as Label).text)
		elif n is Button:
			botones.append((n as Button).text)
		if n is TextureRect and (n as TextureRect).custom_minimum_size == Vector2(0, 84):
			tarjetas += 1
	_comprobar(not "flujo_nuevo" in inicio, "ya no existe el interruptor Inicio.flujo_nuevo")
	_comprobar(not textos.has(Idiomas.t("ELIGE TU CAMINO")) and tarjetas == 0,
		"el menú ya no enseña «ELIGE TU CAMINO» ni tarjetas de modo")
	_comprobar(textos.has(Idiomas.t("NUEVO JUEGO")) and botones.has(Idiomas.t("▶ Empezar")),
		"y sí el bloque «Nuevo juego» con su botón")
	_comprobar(inicio.get("_panel_continuar") is VBoxContainer and inicio.get("_campo_nombre") is LineEdit,
		"«Continuar», el nombre y la dificultad siguen en el menú")
	_comprobar(not inicio.has_method("_al_pulsar_modo") and not inicio.has_method("_elegir_reto"),
		"el camino viejo (tarjetas y selector de retos del inicio) está borrado")
	inicio.queue_free()

	# --- desde la entrada: tutorial, Carrera de Jugador y retos ---------------------
	var p := PantallaModos.new()
	add_child(p)
	var ids: Array[String] = []
	for m: Dictionary in p.modos():
		if PantallaModos.jugable(m):
			ids.append(String(m.get("id", "")))
	for k: String in ["retos", "tutorial", "carrera-m", "creador", "dt"]:
		_comprobar(ids.has(k), "el menú de modos de la entrada ofrece «%s» y se puede jugar" % k)
	var emitidos: Array = []
	p.terminado.connect(func(d: Dictionary) -> void: emitidos.append(d))
	var i_retos := ids.find("retos")
	for i in p.modos().size():
		if String(p.modos()[i].get("id", "")) == "retos":
			i_retos = i
	p.elegir(i_retos)
	p.confirmacion().confirmar()
	var sel := p.selector_retos()
	_comprobar(sel.abierto() and emitidos.is_empty(), "confirmar «Retos» abre el selector de los retos, sin salir aún")
	_comprobar(sel.botones().size() == Retos.LISTA.size(), "con los %d retos" % Retos.LISTA.size())
	_comprobar(sel.botones()[0].has_focus(), "y el foco en el primero (mando y teclado)")
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	p._unhandled_input(ev)
	_comprobar(not sel.abierto() and emitidos.is_empty(), "Esc / B cierra el selector sin elegir")
	p.elegir(i_retos)
	p.confirmacion().confirmar()
	var ultimo := String(Retos.LISTA[Retos.LISTA.size() - 1][0])
	sel.botones()[Retos.LISTA.size() - 1].pressed.emit()
	_comprobar(emitidos.size() == 1 and emitidos[0] == {"modo": "retos", "reto": ultimo},
		"elegir un reto emite terminado con el modo y ese reto")

	# --- el orquestador lo guarda y el reto elegido es el que se monta --------------
	var o := OrquestadorEntrada.new()
	o.cambiar_escena = false
	o.duracion_fundido = 0.0
	add_child(o)
	o.guardar_datos("modo", {"modo": "retos", "reto": "david"})
	o.guardar_datos("modo", {"modo": "retos", "reto": ultimo})
	_comprobar(String(o.estado.get("modo")) == "retos" and String(o.estado.get("reto")) == ultimo,
		"el orquestador guarda el reto; elegir otro al volver atrás lo sobrescribe")
	_comprobar(not o.etapa_aplica(o.indice_de("pais")), "un reto se salta la elección de país (el club lo pone el reto)")
	o.queue_free()
	p.queue_free()
