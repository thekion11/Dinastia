extends Node
## M-309: los créditos y licencias en Ajustes → Partida.
##   herramientas/captura.sh res://pruebas/captura_creditos.tscn
var _n := 0
var _p: Node
func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		_p.set("_secc_ajustes", "partida")
		_p.call("_ir_a_pestana", "Ajustes")
	if _n == 16:
		var lista: Node = _p.get("_lista_ajustes")
		var cuantas := 0
		for l in lista.find_children("*", "Label", true, false):
			if (l as Label).text.contains("CC0") or (l as Label).text.contains("MIT"):
				cuantas += 1
		print("CREDITOS ", cuantas)
		var sc: ScrollContainer = lista.get_parent() as ScrollContainer
		if sc != null:
			sc.scroll_vertical = 100000
	if _n == 20:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/creditos.png")
		get_tree().quit()
