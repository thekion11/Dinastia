extends Node
var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		_pantalla.set("_secc_ajustes", "pantalla")
		_pantalla.call("_ir_a_pestana", "Ajustes")
		_pantalla.call("_refrescar")
	if _n == 14:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pantalla_atajos.png")
		get_tree().quit()
