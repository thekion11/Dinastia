extends Node
## C13 EN PANTALLA (26-9-2026): la tira de días con el 11 de septiembre y las
## próximas fechas en la pestaña Calendario.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_calendario.tscn
var _n := 0
var _p: Node

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	var m: Mundo = _p.get("mundo") if _n >= 10 else null
	if _n == 10:
		pass
		_p.call("_ir_a_chip", {"tab": "Legado", "label": "Historia"})
		_p.call("_refrescar")
	if _n == 22:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/historia_c4.png")
		get_tree().quit()
