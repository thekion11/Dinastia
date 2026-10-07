extends Node
## Comprueba el interruptor "Mercado a ciegas" en Club, y su efecto en la
## ficha de un rival: en vez de un rango numerico, una palabra cualitativa.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_ciego.tscn

const ESPERA := 14

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		var mundo: Mundo = _pantalla.get("mundo")
		mundo.ojeadores.modo_ciego = true
		var mio: Club = mundo.mi_club()
		var rival: Jugador = null
		for c: Club in mundo.clubes.values():
			if c.id != mio.id and c.pais != mio.pais and not c.plantilla.is_empty():
				rival = c.plantilla[0]
				break
		var tabs: TabContainer = _pantalla.get("_pestanas")
		for i in tabs.get_tab_count():
			if tabs.get_tab_title(i) == "Club":
				tabs.current_tab = i
				break
		_pantalla.call("_refrescar")
		if rival != null:
			_pantalla.call("_ver_ficha", rival)
	if _n == ESPERA + 4:
		_guardar("res://pruebas/capturas/pantalla_modo_ciego.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
