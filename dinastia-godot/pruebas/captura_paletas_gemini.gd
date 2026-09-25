extends Node
## Prueba de las seis paletas nuevas de Gemini (`ModuloEsteticaUI` en el
## documento "Visual gemini" de Drive): que aparecen en el selector, que se
## pueden elegir sin reventar, y que el tema se repinta de verdad.

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		_pantalla.set("_paleta", "cibernetico")
		_pantalla.call("_aplicar_aspecto")
	if _n == 13:
		_pantalla.set("_secc_ajustes", "aspecto")
		_pantalla.call("_ir_a_pestana", "Ajustes")
	if _n == 14:
		_pantalla.call("_refrescar")
		print("pantalla de ajustes pintada sin reventar, con 'cibernetico' activa")
	if _n == 25:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pantalla_paletas_gemini.png")
		get_tree().quit()
