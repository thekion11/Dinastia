extends Node
## Las dos pantallas nuevas del grupo "Ajustes": Glosario (tabla estática
## GLOSARIO) y Ajustes (sonido + autoguardado). Un solo proceso de Godot,
## dos capturas -evita pagar dos veces el arranque del motor por dos
## pantallas que no tienen lógica que fabricar a mano.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_ajustes.tscn

const ESPERA := 12

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		_pantalla.call("_elegir_grupo", "ajustes")
	if _n == ESPERA + 2:
		_guardar("res://pruebas/pantalla_ajustes.png")
	if _n == ESPERA + 4:
		_pantalla.call("_ir_a_pestana", "Glosario")
	if _n == ESPERA + 6:
		_guardar("res://pruebas/pantalla_glosario.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
