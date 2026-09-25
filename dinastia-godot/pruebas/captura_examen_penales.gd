extends Node
## C7 EN PANTALLA (26-9-2026): el examen de licencia y el minijuego de penales.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_examen_penales.tscn
var _n := 0
var _p: Node
var _abierto: Node

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	var m: Mundo = _p.get("mundo") if _n >= 10 else null
	if _n == 10:
		_abierto = ExamenLicencia.mostrar(_p, m)
		_abierto.call("_responder", 1)
	if _n == 16:
		get_viewport().get_texture().get_image().save_png("res://pruebas/examen_licencia.png")
		_abierto.queue_free()
		_abierto = MinijuegoPenales.mostrar(_p, m)
	if _n == 20:
		_abierto.call("_patear", 0)
	if _n == 27:
		get_viewport().get_texture().get_image().save_png("res://pruebas/minijuego_penales.png")
		get_tree().quit()
