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
		InterruptorCiudad.activa = true   ## (9-11) la ciudad está apagada por defecto: esta prueba la necesita
		MenuLateral.ejecutar(_p, "ciudad_pie")
	## (2-11-2026, CI) La ciudad se arma por etapas entre fotogramas, así que en una máquina lenta tarda más de
	## 60 fotogramas: se espera a que el paseo arranque (hasta ~3000 fotogramas) en vez de mirar en un número fijo.
	if _n > 6 and (_n % 5 == 0 or _n > 2900):
		var ok := false
		for h in _p.get_children():
			if h is VistaCiudad and (h as VistaCiudad).get("_explorador") != null:
				ok = true
		if ok or _n > 3000:
			print("PASEO ARRANCADO: ", ok, " (fotograma ", _n, ")")
			print("FIN. ", 0 if ok else 1, " fallos")
			get_tree().quit()
