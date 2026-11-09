extends Node
## (9-11, «solo club») El menú → «Entrar al estadio» te deja CAMINANDO el club (explorador activo, sin vista exterior) y salir (Esc) cierra
## la vista y devuelve el menú.
var _n := 0
var _p: Node
var _vista: Node = null
var _fase := 0

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		MenuLateral.ejecutar(_p, "ver_estadio")
	if _n > 6 and _n % 5 == 0 and _fase == 0:
		for h in _p.get_children():
			var sc := h.get_script() as Script
			if sc != null and String(sc.get_global_name()) == "VistaEstadio" and h.get("_explorador") != null:
				_vista = h
				_fase = 1
				print("PASEO A PIE ARRANCADO (fotograma ", _n, ")")
				(h.get("_explorador") as Node).emit_signal("salir")   ## equivale a Esc
				_n = 100
	if _fase == 1 and _n > 110 and _n % 5 == 0:
		var cerrada := not is_instance_valid(_vista) or _vista.is_queued_for_deletion()
		print("VISTA CERRADA AL SALIR: ", cerrada)
		print("FIN. ", 0 if cerrada else 1, " fallos")
		get_tree().quit()
	if _n > 3000:
		print("NO ARRANCÓ EL PASEO A PIE")
		print("FIN. 1 fallos")
		get_tree().quit()
