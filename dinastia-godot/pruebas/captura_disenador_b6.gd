extends Node
## EL DISEÑADOR DEL ESTADIO CON LAS SECCIONES DE B6 (25-9-2026): fachada, color
## de fachada y techo, luz de los focos, superficie y color de banquillos.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_disenador_b6.tscn
var _n := 0
var _p: Node

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

## Por fotogramas: sin tarjeta gráfica cada uno tarda casi medio segundo, y la
## lista entra con animación escalonada; antes de +8 tras bajar sale vacía.
func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		_p.call("_ir_a_pestana", "Estadio")
	if _n == 12:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/disenador_b6_arriba.png")
	if _n == 20:
		## Bajar hasta los bloques del diseñador.
		var lista: Control = _p.get("_lista_estadio")
		var sc := lista.get_parent()
		while sc != null and not (sc is ScrollContainer):
			sc = sc.get_parent()
		for h in lista.get_children():
			if h is Label and (h as Label).text == "LA ESTRUCTURA" and sc != null:
				(sc as ScrollContainer).scroll_vertical = int(h.global_position.y - lista.global_position.y) - 10
	if _n == 28:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/disenador_b6.png")
		get_tree().quit()
