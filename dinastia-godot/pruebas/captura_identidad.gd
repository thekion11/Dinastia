extends Node
## Mirada critica a la pantalla de identidad visual (Gente -> Identidad):
## escudo, uniforme, colores, simbolo. Ya existente y bastante completa -se
## verifica que se vea bien de verdad, no que exista el codigo.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_identidad.tscn

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
		var mio: Club = mundo.mi_club()
		var tabs: TabContainer = _pantalla.get("_pestanas")
		for i in tabs.get_tab_count():
			if tabs.get_tab_title(i) == "Gente":
				tabs.current_tab = i
				break
		var lista: Control = _pantalla.get("_lista_gente")
		_pantalla.call("_limpiar", lista)
		_pantalla.call("_pintar_identidad", mio)
	if _n == ESPERA + 6:
		_guardar("res://pruebas/pantalla_identidad.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
