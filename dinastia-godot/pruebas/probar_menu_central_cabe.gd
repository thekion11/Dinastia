extends Node
## EL MENÚ CENTRAL CABE (17-11-2026): el Inicio y las otras dos pestañas («Dirección del equipo», «Información del club») caben enteros en 1600×900 y en 1280×720: cada
## control visible queda dentro de la ventana (salvo lo que recorta un padre con `clip_contents`) y no hay ningún ScrollContainer visible. Dos clubes de países distintos.
## Necesita la ventana (xvfb en `herramientas/especiales.sh`): en headless puro el tamaño de la ventana no cambia.

var fallos := 0

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO ", msg)

func _frames(n := 4) -> void:
	for i in n:
		await get_tree().process_frame

func _recortado(n: Control, raiz: Node) -> bool:
	var a: Node = n.get_parent()
	while a != null and a != raiz:
		if a is Control and (a as Control).clip_contents:
			return true
		a = a.get_parent()
	return false

func _revisar(pr: Principal, etiqueta: String, tam: Vector2i) -> void:
	var pantalla: Node = pr.get_meta("escaparate") if pr.has_meta("escaparate") else null
	_ok(pantalla != null and (pantalla as Control).visible, "%s: el escaparate está a la vista" % etiqueta)
	if pantalla == null:
		return
	var vista := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size).grow(1.5)
	var fuera := 0
	var desliza := 0
	var vistos := 0
	for n in pantalla.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree():
			continue
		if c is ScrollContainer:
			desliza += 1
		if c.get_global_rect().size.x <= 0.0 or _recortado(c, pantalla):
			continue
		vistos += 1
		if not vista.encloses(c.get_global_rect()):
			fuera += 1
			if fuera <= 3:
				print("   fuera: %s %s en %s" % [c.get_path(), c.get_global_rect(), vista])
	_ok(fuera == 0, "%s (%dx%d): %d controles se salen de la ventana" % [etiqueta, tam.x, tam.y, fuera])
	_ok(vistos > 30, "%s: se revisaron %d controles (ventana %s)" % [etiqueta, vistos, vista.size])
	_ok(desliza == 0, "%s (%dx%d): hay %d ScrollContainer visibles" % [etiqueta, tam.x, tam.y, desliza])

func _ready() -> void:
	AvanceDiasUI.sin_pantalla = true
	JornadaEventos._abierto = true
	for cfg: Array in [["ESP", 4, 20261104], ["ENG", 2, 20261117]]:
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
		for tam: Vector2i in [Vector2i(1600, 900), Vector2i(1280, 720)]:
			get_window().size = tam
			await _frames(4)
			for pestana in 3:
				TableroInicio.pestana = pestana
				pr._refrescar()
				await _frames(8)
				_revisar(pr, "%s pestaña %d" % [cfg[0], pestana], tam)
		TableroInicio.pestana = 0
		pr.queue_free()
		await _frames(3)
	print("FIN. %d fallos" % fallos)
	get_tree().quit()
