extends Node
## Prueba con pantalla del AVANCE DE FECHA (10-11): la fila «PRÓXIMOS» (eventos) y la vista de varias semanas que abre su botón 📅; Esc la cierra. Saca dos capturas JPG.
## xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1920x1080 res://pruebas/prueba_calendario_semanas.tscn
var _n := 0
var _p: Node
var _fase := 0
var _fallos := 0

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _comprobar(ok: bool, que: String) -> void:
	print(("  ok    " if ok else "  FALLO ") + que)
	if not ok:
		_fallos += 1

func _vista() -> Node:
	for h in get_children():
		if h is CalendarioSemanas:
			return h
	return null

func _process(_d: float) -> void:
	_n += 1
	if _n == 20 and _fase == 0:
		_fase = 1
		var fila := _p._guia.nodos["fila_proximos"] as HBoxContainer
		var tarjetas := 0
		var boton: Button = null
		for h in fila.get_children():
			if h is PanelContainer:
				tarjetas += 1
			if h is Button:
				boton = h
		_comprobar(tarjetas == FilaProximos.CUANTOS and boton != null, "la fila de la pantalla trae %d eventos y el botón 📅 (%d)" % [FilaProximos.CUANTOS, tarjetas])
		await get_tree().create_timer(0.8).timeout
		get_viewport().get_texture().get_image().save_jpg("/tmp/claude-0/-home-user-Dinastia/7395ea24-cc3e-543b-bb68-b8151f68704f/scratchpad/avance_fecha_fila.jpg", 0.9)
		boton.pressed.emit()
		await get_tree().create_timer(1.2).timeout
		_comprobar(_vista() != null, "el botón abre la vista de varias semanas")
		get_viewport().get_texture().get_image().save_jpg("/tmp/claude-0/-home-user-Dinastia/7395ea24-cc3e-543b-bb68-b8151f68704f/scratchpad/avance_fecha.jpg", 0.9)
		var esc := InputEventAction.new()
		esc.action = "ui_cancel"
		esc.pressed = true
		Input.parse_input_event(esc)
		await get_tree().create_timer(0.5).timeout
		_comprobar(_vista() == null, "Esc cierra la vista")
		print("FIN. %d fallos" % _fallos)
		get_tree().quit()
