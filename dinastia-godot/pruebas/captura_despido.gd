extends Node
## Fuerza la confianza de la directiva al suelo A MITAD DE TEMPORADA -no en el
## cierre de temporada, que ya se probaba- para ver si el aviso "ESTÁS
## DESPEDIDO" llega solo al registro, sin tocar ninguna pantalla a mano.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_despido.tscn

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
		mun.avanzar_semana()
		mun.directiva.mover_confianza(-100, "racha de derrotas")
		_pantalla.call("_refrescar")
	if _n == ESPERA + 4:
		_guardar("res://pruebas/capturas/pantalla_despido.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
