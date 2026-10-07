extends Node
## La sala de minijuegos, el tiro libre a mitad de carga y la trivia.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_minijuegos.tscn
var _n := 0
var _p: Node
var _c: Control

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(nombre: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % nombre)

func _process(_d: float) -> void:
	_n += 1
	var m: Mundo = _p.get("mundo")
	if _n == 6:
		_c = SalaMinijuegos.abrir(_p, m)
	if _n == 10:
		_foto("minijuegos_sala")
		_c.queue_free()
		_c = MinijuegoTiroLibre.mostrar(_p, m)
		(_c as MinijuegoTiroLibre)._elegir(2)
	if _n == 30:
		_foto("minijuegos_tiro_libre")
		_c.queue_free()
		_c = TriviaClub.mostrar(_p, m)
	if _n == 36:
		_foto("minijuegos_trivia")
		get_tree().quit()
