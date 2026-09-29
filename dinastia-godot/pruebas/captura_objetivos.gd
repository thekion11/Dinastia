extends Node
## LOS OBJETIVOS EN EL BORDE (29-9-2026): el panel fijo a la derecha.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_objetivos.tscn
var _n := 0
var _p: Node
func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		_p.call("_refrescar")
	if _n == 20:
		## Arrastrarlo: pulsar, mover 300 px a la izquierda y 200 arriba, soltar.
		var po: PanelObjetivos = _p.get("_panel_obj")
		PanelObjetivos.ruta = "user://objetivos_captura.cfg"
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = true
		ev.position = Vector2(20, 10)
		po._al_arrastrar(ev)
		var mv := InputEventMouseMotion.new()
		mv.position = Vector2(-280, -190)
		po._al_arrastrar(mv)
		ev.pressed = false
		po._al_arrastrar(ev)
		print("OBJETIVOS movido a ", po.position)
	if _n == 40:
		get_viewport().get_texture().get_image().save_png("res://pruebas/objetivos_borde.png")
		get_tree().quit()
