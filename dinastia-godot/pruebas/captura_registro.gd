extends Node
## Juega varias temporadas y mira el registro "LO QUE VA PASANDO": tiene que
## traer avisos de mas de un sistema (antes de hoy, federacion/cesiones/
## entrenamiento/prensa/vestuario emitian su senal noticia() y nadie la oia).
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_registro.tscn

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
		for temporada in 4:
			mun.jugar_temporada()
			mun.nueva_temporada()
	if _n == ESPERA + 6:
		_guardar("res://pruebas/capturas/pantalla_registro.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
