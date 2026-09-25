extends Node
## Captura visual del evento "Lobby institucional con árbitros" pintado de
## verdad en el Despacho -no solo el motor, como `captura_verificar_lobby_
## arbitral.gd`-. Fuerza `Federacion.enojo_arbitral` y el evento pendiente, y
## refresca para que `Principal._pintar_decision()` lo pinte con el mismo
## camino genérico que cualquier otro evento de `Prensa`.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_visual_lobby_arbitral.tscn

const ESPERA := 10

var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

var _n := 0

func _process(_d: float) -> void:
	_n += 1
	var n := _n
	if n == ESPERA:
		var mundo: Mundo = _pantalla.get("mundo")
		mundo.federacion.enojo_arbitral = 3
		var evento := {}
		for e: Dictionary in mundo.prensa._pool(mundo, mundo.mi_club()):
			if String(e["id"]) == "lobby_arbitral":
				evento = e
		mundo.prensa.pendiente = evento
		## `_despacho` no es una pestaña propia: es la columna central fija
		## (`raiz`), visible sea cual sea la pestaña activa -por eso no hace
		## falta `_ir_a_pestana()` aquí, a diferencia de otras capturas.
		_pantalla.call("_refrescar")
	if n == ESPERA + 3:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pantalla_lobby_arbitral.png")
		print("captura: pantalla_lobby_arbitral.png")
		get_tree().quit(0)
