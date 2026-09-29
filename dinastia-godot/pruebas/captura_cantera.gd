extends Node
## Abre la pestana Cantera tras varias temporadas, para que haya camada,
## canteranos en categorias y (con suerte) algun hijo de leyenda.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_cantera.tscn

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
		for temporada in 5:
			mun.jugar_temporada()
			mun.nueva_temporada()
		_pantalla.call("_refrescar")
		var tabs: TabContainer = _pantalla.get("_pestanas")
		for i in tabs.get_tab_count():
			if tabs.get_tab_title(i) == "Cantera":
				tabs.current_tab = i
				break
	if _n == ESPERA + 6:
		_guardar("res://pruebas/capturas/pantalla_cantera.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
