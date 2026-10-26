extends Node
## EL SELECTOR DE RETOS (26-9-2026; desde el 26-10 vive en el menú de modos de la entrada).
var _n := 0
var _m: PantallaModos
func _ready() -> void:
	_m = PantallaModos.new()
	add_child(_m)
func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		_m.configurar({"modo": "retos"})
		_m.elegir(_indice_retos())
		_m.confirmacion().confirmar()
	if _n == 14:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/retos.png")
		get_tree().quit()
func _indice_retos() -> int:
	for i in _m.modos().size():
		if String(_m.modos()[i].get("id", "")) == "retos":
			return i
	return 0
