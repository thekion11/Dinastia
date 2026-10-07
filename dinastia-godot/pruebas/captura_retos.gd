extends Node
## EL SELECTOR DE RETOS (26-9-2026).
var _n := 0
var _i: Node
func _ready() -> void:
	_i = load("res://escenas/inicio.tscn").instantiate()
	add_child(_i)
func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		_i.call("_elegir_reto")
	if _n == 14:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/retos.png")
		get_tree().quit()
