extends Node

func _ready() -> void:
	var cat: Array = Sonido.catalogo()
	print("total sonidos: ", cat.size())
	print("FIN. 0 fallos")
	get_tree().quit(0)
