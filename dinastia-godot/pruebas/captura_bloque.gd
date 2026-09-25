extends Node
## Verificación visual de golpe de las pantallas del último bloque, en un solo
## proceso de Godot: Táctica (once a mano + reglamento), Estadio (hinchada con
## segmentos y abonos), Finanzas (contabilidad anual) y Entrenar (pretemporada
## y mentorías). Cuatro capturas, un arranque.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_bloque.tscn

const ESPERA := 12

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		## Una temporada jugada y cerrada: así hay abonados, contabilidad con
		## cifras de verdad y jugadores con contrato por vencer.
		var mun = _pantalla.get("mundo")
		mun.jugar_temporada()
		_pantalla.call("_nueva_temporada")
		_pantalla.call("_elegir_grupo", "plantel")
		_pantalla.call("_ir_a_pestana", "Táctica")
		_pantalla.call("_refrescar")
	if _n == ESPERA + 3:
		_guardar("res://pruebas/pantalla_tactica.png")
	if _n == ESPERA + 5:
		_pantalla.call("_elegir_grupo", "club")
		_pantalla.call("_ir_a_pestana", "Estadio")
	if _n == ESPERA + 7:
		_guardar("res://pruebas/pantalla_hinchada.png")
	if _n == ESPERA + 9:
		_pantalla.call("_elegir_grupo", "finanzas")
		_pantalla.call("_ir_a_pestana", "Finanzas")
	if _n == ESPERA + 11:
		_guardar("res://pruebas/pantalla_contabilidad.png")
	if _n == ESPERA + 13:
		_pantalla.call("_elegir_grupo", "plantel")
		_pantalla.call("_ir_a_pestana", "Entrenar")
	if _n == ESPERA + 15:
		_guardar("res://pruebas/pantalla_entrenar_plus.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
