extends Node
## Prueba aislada del reparto Redes/Sala de Prensa/El Ruido de Fuera -sin los
## `_avanzar_semana()` en bloque de `captura.gd`, que esta sesión enganchó un
## sorteo de copa fuera de tiempo y se quedó colgado. Aquí no hace falta
## avanzar ninguna semana: los tres chips ya tienen contenido desde que se
## toma el mando.

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		_pantalla.call("_elegir_grupo", "operaciones")
		_pantalla.call("_ir_a_chip", {"tab": "Redes", "secc": "redes", "label": "Feed de Redes"})
	if _n == 14:
		_guardar("res://pruebas/capturas/pantalla_redes_feed.png")
		_pantalla.call("_ir_a_chip", {"tab": "Redes", "secc": "prensa", "label": "Sala de Prensa"})
	if _n == 16:
		_guardar("res://pruebas/capturas/pantalla_redes_prensa.png")
		_pantalla.call("_ir_a_chip", {"tab": "Redes", "secc": "debate", "label": "El Ruido de Fuera"})
	if _n == 18:
		_guardar("res://pruebas/capturas/pantalla_redes_debate.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
