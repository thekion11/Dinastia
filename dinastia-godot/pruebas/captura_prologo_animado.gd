extends Node
## Captura de los seis planos del prólogo animado: xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1920x1080 res://pruebas/captura_prologo_animado.tscn
var _p: Node
var _n := 0
var _v: PrologoAnimado
var _k := -1
var _espera := 0.0

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(d: float) -> void:
	_n += 1
	if _n == 12:
		_v = PrologoAnimado.mostrar(_p)
		_k = 0
		_espera = 3.0
	elif _k >= 0 and _k < 6:
		_espera -= d
		if _espera <= 0.0:
			get_viewport().get_texture().get_image().save_jpg("/tmp/prologo_%d.jpg" % _k, 0.88)
			_k += 1
			if _k < 6:
				_v._segmentos[_k].pressed.emit()
				_espera = 3.2
			else:
				print("CAPTURA OK")
				get_tree().quit()
