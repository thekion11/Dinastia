extends Node
const ESPERA := 10
var _n := 0
var _pantalla: Node
func _ready() -> void:
	_pantalla = load("res://escenas/inicio.tscn").instantiate()
	add_child(_pantalla)
func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		var root: Control = _pantalla
		var scroll: ScrollContainer = root.get_child(1)
		scroll.get_v_scroll_bar().value = 900
	if _n == ESPERA + 4:
		_guardar("res://pruebas/pantalla_inicio_2.png")
	if _n == ESPERA + 6:
		var root: Control = _pantalla
		var scroll: ScrollContainer = root.get_child(1)
		scroll.get_v_scroll_bar().value = 1800
	if _n == ESPERA + 10:
		_guardar("res://pruebas/pantalla_inicio_3.png")
		get_tree().quit()
func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s" % ruta)
