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
	if _n == 40:
		get_viewport().get_texture().get_image().save_png("res://pruebas/objetivos_borde.png")
		get_tree().quit()
