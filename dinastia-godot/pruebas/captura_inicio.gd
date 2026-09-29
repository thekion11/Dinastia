extends Node
## Captura la pantalla de titulo (inicio.tscn) tal cual la ve el jugador al
## abrir el juego, para comparar con el menu del HTML.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_inicio.tscn

const ESPERA := 10

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/inicio.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		_guardar("res://pruebas/capturas/pantalla_inicio.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
