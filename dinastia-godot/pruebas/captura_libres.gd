extends Node
## `vLibres()`/`ficharLibre()` del HTML: la bolsa de agentes libres. Se ve la
## lista de verdad, se forza una joya (4% en el juego real, aquí a mano) para
## ver su aviso, y se ficha al primero de la lista con reintentos hasta que
## acepte -puede decir que no, como en el mercado normal-.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_libres.tscn

const ESPERA := 12

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		_pantalla.call("_elegir_grupo", "finanzas")
		_pantalla.call("_ir_a_pestana", "Libres")
	if _n == ESPERA + 2:
		_guardar("res://pruebas/pantalla_libres.png")
	if _n == ESPERA + 4:
		var mun = _pantalla.get("mundo")
		var e = mun._nuevo_libre(true)
		mun.libres.push_front(e)
		mun.libre_estrella.emit(e)
		_pantalla.call("_refrescar")
	if _n == ESPERA + 6:
		_guardar("res://pruebas/pantalla_libre_estrella.png")
	if _n == ESPERA + 8:
		## Ficha al primero de la lista, con reintentos: puede decir que no.
		var mun = _pantalla.get("mundo")
		var mio = mun.mi_club()
		var intentos := 0
		while not mun.libres.is_empty() and intentos < 20:
			var r = mun.fichar_libre(0, mio)
			if r.has("ok"):
				break
			intentos += 1
		_pantalla.call("_refrescar")
	if _n == ESPERA + 10:
		_guardar("res://pruebas/pantalla_libre_fichado.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
