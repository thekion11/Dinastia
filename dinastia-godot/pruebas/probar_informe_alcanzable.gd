extends Node
## EL INFORME DE LA SEMANA SE ALCANZA DESDE EL MENÚ CENTRAL (17-11-2026): el botón «Mensajes · N» de la barra de arriba (correo, noticias e informe de la semana); con el foco (mando/teclado) y Intro/A se abre su
## pantalla completa, el foco queda dentro (en un aviso o en «Volver») y Esc/B la cierra. Los avisos urgentes suman en el contador. Dos clubes de países distintos.
## Con pantalla (xvfb en `herramientas/especiales.sh`).

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

func _tarjeta(raiz: Node, rotulo: String) -> Button:
	for l in raiz.find_children("*", "Label", true, false):
		if (l as Label).text == rotulo.to_upper() and l.get_parent() is Button:
			return l.get_parent() as Button
	return null

func _ready() -> void:
	AvanceDiasUI.sin_pantalla = true
	JornadaEventos._abierto = true
	for cfg: Array in [["ESP", 4, 20261104], ["ARG", 3, 20261117]]:
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
		var pant := pr.get_meta("escaparate") as EscaparatePantalla
		var barra: Node = pant.find_child("Botones", true, false)
		var boton := barra.find_child("BotonMensajes", true, false) as Button
		_ok(boton != null, "%s: la barra tiene «Mensajes»" % e)
		if boton == null:
			continue
		var graves := int(InformeSemana.resumen(pr)["graves"])
		var rotulo: String = boton.get_meta("rotulo", "")
		_ok(graves == 0 or rotulo.contains("·"), "%s: «Mensajes» lleva el contador (%d avisos urgentes del informe) «%s»" % [e, graves, rotulo])
		boton.grab_focus()
		await _frames(2)
		_ok(boton.has_focus(), "%s: «Mensajes» recibe el foco (mando/teclado)" % e)
		await _accion("ui_accept")
		await _frames(4)
		_ok(is_instance_valid(pant.informe) and pant.informe.is_visible_in_tree(), "%s: Intro/A abre Mensajes e informe de la semana a pantalla completa" % e)
		if is_instance_valid(pant.informe):
			var dueno := get_viewport().gui_get_focus_owner()
			_ok(dueno != null and pant.informe.is_ancestor_of(dueno), "%s: el foco queda dentro de la pantalla" % e)
			_ok(Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size).grow(1.5).encloses(pant.informe.get_global_rect()), "%s: ocupa la pantalla" % e)
			await _accion("ui_cancel")
			await _frames(4)
			_ok(not is_instance_valid(pant.informe), "%s: Esc/B la cierra y se vuelve al menú" % e)
		TableroInicio.pestana = 0
		pr.queue_free()
		await _frames(3)
	print("FIN. %d fallos" % fallos)
	get_tree().quit()
