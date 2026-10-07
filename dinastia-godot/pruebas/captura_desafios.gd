extends Node
## Marca un par de desafios en eleccion_club.tscn y la captura, para ver el
## panel y el multiplicador en pantalla.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_desafios.tscn

const ESPERA := 20

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/eleccion_club.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		## button_pressed no se actualiza solo al llamar la funcion a mano -eso
		## solo pasa cuando el usuario pulsa de verdad-, asi que se fuerza aqui
		## para que la captura muestre las tarjetas realmente marcadas.
		var fila: HFlowContainer = _pantalla.get("_fila_desafios")
		var tabla: Array = Datos.tabla("DESAFIOS")
		for i in tabla.size():
			var clave := String(tabla[i][0])
			if clave == "pobreza" or clave == "invicto":
				var b: Button = fila.get_child(i)
				b.button_pressed = true
				_pantalla.call("_alternar_desafio", clave)
	if _n == ESPERA + 2:
		_guardar("res://pruebas/capturas/pantalla_desafios.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
