extends Node
## Comprueba el logo del sponsor superpuesto en la camiseta procedural
## (Club -> Infraestructura -> Equipacion): antes el parametro "sp" de
## Jersey.svg_de() nunca se leia -"va como etiqueta de Godot" decia su
## propio comentario, y esa etiqueta nunca se puso-. Ahora se superpone el
## logo real de `Marca` sobre el dibujo, solo cuando NO hay foto real -una
## foto real ya trae su sponsor de verdad impreso-.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_equipacion.tscn

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
		mio.mover_saldo(300000000)
		mundo.auspicio.generar_ofertas(mio)
		mundo.auspicio.firmar(0)
		var tabs: TabContainer = _pantalla.get("_pestanas")
		for i in tabs.get_tab_count():
			if tabs.get_tab_title(i) == "Club":
				tabs.current_tab = i
				break
		## Se busca un club SIN foto real -si el propio queda con una, el logo
		## del sponsor no se dibuja a propósito, ver el comentario en
		## _pintar_equipacion()-, para probar de verdad la superposición sobre
		## el dibujo procedural.
		var probar: Club = mio
		for cand: Club in mundo.clubes.values():
			if Jersey.textura_real(cand, 0) == null:
				probar = cand
				break
		## Se salta `_club_infra()` -que primero pinta una lista larguísima de
		## obras- y se llama a `_pintar_equipacion()` sola, para no depender de
		## hacer scroll en una ventana de prueba.
		var lista: Control = _pantalla.get("_lista_club")
		_pantalla.call("_limpiar", lista)
		_pantalla.call("_pintar_equipacion", probar)
	if _n == ESPERA + 6:
		_guardar("res://pruebas/pantalla_equipacion.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
