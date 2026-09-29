extends Node
## Comprueba la mesa de negociación en vivo: abrir, ajustar terminos, mandar
## una oferta y ver la respuesta.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_negociacion.tscn

const ESPERA := 14

var _n := 0
var _pantalla: Node
var _mundo: Mundo
var _objetivo: Jugador

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		_mundo = _pantalla.get("mundo")
		var mio: Club = _mundo.mi_club()
		mio.mover_saldo(300000000)
		for c: Club in _mundo.clubes.values():
			if c.id != mio.id and not c.plantilla.is_empty():
				_objetivo = c.plantilla[0]
				break
		_mundo.mercado.abrir_negociacion(_objetivo)
		var tabs: TabContainer = _pantalla.get("_pestanas")
		for i in tabs.get_tab_count():
			if tabs.get_tab_title(i) == "Mercado":
				tabs.current_tab = i
				break
		_pantalla.call("_refrescar")
	if _n == ESPERA + 4:
		_guardar("res://pruebas/capturas/pantalla_negociacion_abierta.png")
		## Sube la ficha y la parte fija bastante, para que se acepte pronto.
		var neg = _mundo.mercado.negociacion
		neg.fijo = int(float(neg.pedido) * 1.1)
		neg.sueldo = int(float(neg.sueldo) * 1.6)
		neg.firma = neg.sueldo * 5
		_pantalla.call("_enviar_oferta_negociacion")
	if _n == ESPERA + 8:
		_guardar("res://pruebas/capturas/pantalla_negociacion_ronda.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
