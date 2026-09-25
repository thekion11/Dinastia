extends Node
## Abre eleccion_club.tscn, la captura con Chile, y cambia a otro pais para
## comprobar que el selector de pais de verdad refresca la lista de clubes.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_eleccion_club.tscn

const ESPERA := 20

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/eleccion_club.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		_guardar("res://pruebas/pantalla_eleccion_club_chi.png")
		_pantalla.call("_elegir_pais", "ESP")
	if _n == ESPERA + 4:
		_guardar("res://pruebas/pantalla_eleccion_club_esp.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
