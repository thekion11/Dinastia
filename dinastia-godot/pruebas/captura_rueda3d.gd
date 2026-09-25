extends Node
## Comprueba el plato 3D nuevo de la rueda de prensa: el podio, el fondo de
## patrocinadores y el DT, con el subtitulo de la pregunta encima.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_rueda3d.tscn

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
		mundo.prensa.abrir_rueda(true, false)
		print("hay_rueda: ", mundo.prensa.hay_rueda(), "  pregunta: ", mundo.prensa.entrevista.get("pregunta", ""))
		_pantalla.call("_refrescar")
	if _n == ESPERA + 10:
		_guardar("res://pruebas/pantalla_rueda3d.png")
		## Prueba de la interacción real: cambiar el tono y responder, y
		## comprobar que el popup se cierra solo sin dejar nada raro.
		(_pantalla.get("mundo") as Mundo).prensa.fijar_cuerpo("dubitativo")
		_pantalla.call("_repintar_posturas")
		var pop_antes: Object = _pantalla.get("_rueda_pop")
		print("popup antes de responder: ", pop_antes != null)
		_pantalla.call("_responder", 0)
		var pop_despues: Object = _pantalla.get("_rueda_pop")
		print("popup despues de responder: ", pop_despues != null, "  (deberia ser false)")
	if _n == ESPERA + 12:
		_guardar("res://pruebas/pantalla_rueda3d_tras_responder.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
