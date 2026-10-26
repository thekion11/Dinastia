extends Node
## Captura el menú de inicio arriba y desplazado hasta el fondo (Forward+, con
## `herramientas/captura.sh`): sirve para ver el antes/después de dejar la
## entrada nueva como único camino para empezar partida.
##   SUFIJO=antes herramientas/captura.sh res://pruebas/captura_inicio_unico.tscn

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/inicio.tscn").instantiate()
	add_child(_pantalla)

func _scroll() -> ScrollContainer:
	for h in _pantalla.get_children():
		if h is ScrollContainer:
			return h
	return null

func _process(_d: float) -> void:
	_n += 1
	var suf := OS.get_environment("SUFIJO")
	if _n == 12:
		_guardar("res://pruebas/capturas/inicio_arriba_%s.png" % suf)
		var s := _scroll()
		if s != null:
			s.scroll_vertical = 100000
	elif _n == 20:
		_guardar("res://pruebas/capturas/inicio_abajo_%s.png" % suf)
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s" % ruta)
