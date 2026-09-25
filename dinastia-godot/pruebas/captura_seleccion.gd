extends Node
## Abre la pestana Seleccion tras jugar tres temporadas -para que haya
## resultados, internacionales y algun candidato a nacionalizar de verdad-.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_seleccion.tscn

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
		## Tres temporadas para que se vean resultados, ranking con movimiento y
		## algun jugador con residencia suficiente para nacionalizarse.
		for temporada in 3:
			mun.jugar_temporada()
			mun.nueva_temporada()
		_pantalla.call("_refrescar")
		var tabs: TabContainer = _pantalla.get("_pestanas")
		for i in tabs.get_tab_count():
			if tabs.get_tab_title(i) == "Selección":
				tabs.current_tab = i
				break
	if _n == ESPERA + 6:
		_guardar("res://pruebas/pantalla_seleccion.png")
		var lista: VBoxContainer = _pantalla.get("_lista_seleccion")
		var scroll := lista.get_parent() as ScrollContainer
		if scroll != null:
			scroll.scroll_vertical = 100000
	if _n == ESPERA + 10:
		_guardar("res://pruebas/pantalla_seleccion2.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
