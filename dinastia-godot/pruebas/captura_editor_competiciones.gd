extends Node
## EL EDITOR DE COMPETICIONES (28-9-2026): ligas de tu país (nombre, cuántos
## bajan, puntos por victoria) y la copa (nombre y sede fija de la final).
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_editor_competiciones.tscn
var _n := 0
var _p: Node
func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		_p.call("_ir_a_chip", {"tab": "Editor", "label": "Editor"})
		_p.call("_refrescar")
	if _n == 24:
		get_viewport().get_texture().get_image().save_png("res://pruebas/editor_competiciones.png")
		get_tree().quit()
