extends Node
## El menú Ciudad 3D → «Pasear a pie» abre la ciudad y arranca el paseo.
var _n := 0
var _p: Node

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		MenuLateral.ejecutar(_p, "ciudad_pie")
	if _n == 60:
		var ok := false
		for h in _p.get_children():
			if h is VistaCiudad and (h as VistaCiudad).get("_explorador") != null:
				ok = true
		print("PASEO ARRANCADO: ", ok)
		print("FIN. ", 0 if ok else 1, " fallos")
		get_tree().quit()
