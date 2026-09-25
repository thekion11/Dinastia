extends Node
## `Logros.celebrar_titulo()` es el mismo camino que usan la liga, la copa
## nacional y los continentales -estos dos últimos solo tenían sonido, nunca
## texto en el registro-. Se llama directo, como lo hace de verdad
## `avanzar_semana()` al coronar un continental a mitad de año, para ver si
## ahora también queda escrito.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_titulo.tscn

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
		mun.logros.celebrar_titulo("Champions League")
		_pantalla.call("_refrescar")
	if _n == ESPERA + 4:
		_guardar("res://pruebas/pantalla_titulo.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
