extends Node
## Comprueba "LEYENDAS DEL CLUB", la seccion nueva en la pestana Cantera --
## Cantera.leyendas alimentaba de verdad la camada anual pero nunca se veia
## en ningun sitio del juego.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_leyendas.tscn

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
		## Fuerza que al menos una leyenda quede sembrada en TU club, para no
		## depender de que el sorteo la haya puesto ahi.
		mundo.cantera.leyendas.append({
			"nombre": "Fernando Salinas", "club_id": mundo.mi_club().id, "pos": "DEL",
			"nivel": 88, "anio_hijo": mundo.anio + 3, "usado": false,
		})
		var tabs: TabContainer = _pantalla.get("_pestanas")
		for i in tabs.get_tab_count():
			if tabs.get_tab_title(i) == "Cantera":
				tabs.current_tab = i
				break
		_pantalla.call("_refrescar")
	if _n == ESPERA + 4:
		_guardar("res://pruebas/capturas/pantalla_leyendas.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
