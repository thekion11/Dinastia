extends Node
func _frames(n := 4) -> void:
	for i in n:
		await get_tree().process_frame
func _rec(n: Node, nivel: int) -> void:
	if nivel > 4:
		return
	for h in n.get_children():
		if h is Control and (h as Control).visible:
			var c := h as Control
			if c.get_combined_minimum_size().x > 300:
				print("  ".repeat(nivel), c.name, " min=", c.get_combined_minimum_size().x, " ", c.get_class())
				_rec(c, nivel + 1)
func _ready() -> void:
	AvanceDiasUI.sin_pantalla = true
	JornadaEventos._abierto = true
	var m := Mundo.new()
	var ps: Array[String] = ["ESP"]
	m.generar(ps, 20261104)
	m.tomar_el_mando(m.ligas[0].clubes[4].id)
	PedidoPartida.mundo_pregenerado = m
	PedidoPartida.modo_elegido = "dt"
	PedidoPartida.dt_nombre_elegido = "Prueba"
	PedidoPartida.dificultad_elegida = "normal"
	PedidoPartida.aplicado_a = 0
	var pr: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(pr)
	await _frames(14)
	var pant := pr.get_meta("escaparate") as Control
	print("OVERLAY size=", pant.size, " Principal=", pr.size)
	_rec(pant, 0)
	get_tree().quit()
