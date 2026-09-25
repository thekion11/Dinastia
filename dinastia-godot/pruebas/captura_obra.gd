extends Node
## `Mundo.avanzar_semana()` (mundo.gd:540) reemite `obra_lista` con la clave
## de cada obra que termina esa semana. Se fuerza el centro de entrenamiento
## a un plazo de 1 semana y se avanza una, el mismo camino real que toma
## cualquier obra que se termine de pagar, para ver si ahora avisa de verdad.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_obra.tscn

const ESPERA := 12

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		var mun = _pantalla.get("mundo")
		mun.obras.obras["ct"] = 1
		mun.avanzar_semana()
		_pantalla.call("_refrescar")
	if _n == ESPERA + 2:
		_guardar("res://pruebas/pantalla_obra.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
