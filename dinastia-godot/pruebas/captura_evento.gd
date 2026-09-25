extends Node
## UN EVENTO NUEVO EN PANTALLA (25-9-2026, plan maestro B4): la tarjeta con la
## cara del implicado y, al decidir, el aviso con la consecuencia.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_evento.tscn
const ESPERA := 12
var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

## Por fotogramas y no por segundos: en la captura sin tarjeta gráfica cada
## fotograma tarda casi medio segundo, y a +70 el aviso ya se había ido.
func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		var m: Mundo = _pantalla.get("mundo")
		var mio := m.mi_club()
		for e: Dictionary in m.prensa._pool(m, mio):
			if String(e["id"]) == "viral":
				m.prensa.pendiente = e
		_pantalla.call("_refrescar")
		_pantalla.call("_ir_a_pestana", "Inicio")
	if _n == ESPERA + 8:
		get_viewport().get_texture().get_image().save_png("res://pruebas/evento_tarjeta.png")
		_pantalla.call("_resolver", "a")
	if _n == ESPERA + 12:
		get_viewport().get_texture().get_image().save_png("res://pruebas/evento_resuelto.png")
		get_tree().quit()
