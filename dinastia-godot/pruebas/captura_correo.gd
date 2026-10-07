extends Node
## Fuerza un par de avisos reales -una lesión y un informe médico, los mismos
## caminos que `_conectar_noticias()` ya escucha- para ver la bandeja de
## Correo con mezcla de leído/sin leer, tal como la vería un jugador de
## verdad tras unas semanas.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_correo.tscn

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
		var mio = mun.mi_club()
		var j = mio.plantilla[0]
		mun.medico.lesion_nueva.emit(j, 4, "Esguince de tobillo", "entrenamiento")
		var j2 = mio.plantilla[1]
		mun.medico.informe_listo.emit(j2, {"riesgo": "bajo", "graves": 0})
		_pantalla.call("_refrescar")
	if _n == ESPERA + 2:
		_pantalla.call("_elegir_grupo", "ajustes")
		_pantalla.call("_ir_a_pestana", "Correo")
	if _n == ESPERA + 4:
		_guardar("res://pruebas/capturas/pantalla_correo_sinleer.png")
	if _n == ESPERA + 6:
		## Marca la primera como leída pulsando su botón de verdad, no a mano.
		var lista = _pantalla.get("_lista_correo")
		for hijo in lista.get_children():
			if hijo is Button:
				hijo.pressed.emit()
				break
	if _n == ESPERA + 8:
		_guardar("res://pruebas/capturas/pantalla_correo_leida.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
