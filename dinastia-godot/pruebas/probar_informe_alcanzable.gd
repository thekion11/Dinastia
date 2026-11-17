extends Node
## EL INFORME DE LA SEMANA SE ALCANZA DESDE EL MENÚ CENTRAL (17-11-2026): en «Información del club» hay una tarjeta «Informe de la semana»; con el foco (mando/teclado) y Intro/A se abre su
## pantalla completa, el foco queda dentro (en un aviso o en «Volver») y Esc/B la cierra. Los avisos urgentes suman en el contador de «Mensajes» del pie. Dos clubes de países distintos.
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
		((barra.get_meta("tabs") as Array)[2] as Button).pressed.emit()
		await _frames(6)
		var tarjeta := _tarjeta(pant, Idiomas.t("Informe de la semana"))
		_ok(tarjeta != null, "%s: «Información del club» tiene la tarjeta «Informe de la semana»" % e)
		if tarjeta == null:
			continue
		tarjeta.grab_focus()
		await _frames(2)
		_ok(tarjeta.has_focus(), "%s: la tarjeta recibe el foco (mando/teclado)" % e)
		var graves := int(InformeSemana.resumen(pr)["graves"])
		var hay_cont := false
		for b in pant.find_children("*", "Button", true, false):
			if (b as Button).text.begins_with("✉") and (graves == 0 or (b as Button).text.contains("(")):
				hay_cont = true
		_ok(hay_cont, "%s: el contador de Mensajes suma los %d avisos urgentes del informe" % [e, graves])
		await _accion("ui_accept")
		await _frames(4)
		_ok(is_instance_valid(pant.informe) and pant.informe.is_visible_in_tree(), "%s: Intro/A abre la pantalla completa del informe" % e)
		if is_instance_valid(pant.informe):
			var dueno := get_viewport().gui_get_focus_owner()
			_ok(dueno != null and pant.informe.is_ancestor_of(dueno), "%s: el foco queda dentro del informe" % e)
			var r := pant.informe.get_global_rect()
			_ok(Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size).grow(1.5).encloses(r), "%s: el informe ocupa la pantalla" % e)
			await _accion("ui_cancel")
			await _frames(4)
			_ok(not is_instance_valid(pant.informe) or pant.informe.is_queued_for_deletion(), "%s: Esc/B cierra el informe y se vuelve al menú" % e)
		TableroInicio.pestana = 0
		pr.queue_free()
		await _frames(3)
	print("FIN. %d fallos" % fallos)
	get_tree().quit()
