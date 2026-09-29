extends Node
## Federación (licencia + tribunal + antidopaje) y el precio de la entrada.
## Se fuerza un caso de disciplina y un control antidopaje, porque sin ellos
## esos bloques salen vacíos y la captura no probaría nada.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_fed_precio.tscn

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
		mun.federacion.abrir_caso("roja", mio.plantilla[0], 3,
			"agresión sin balón", mun.anio, mun.semana)
		mun.federacion.controles.append({
			"nombre": mio.plantilla[1].nombre, "anio": mun.anio,
			"semana": mun.semana, "positivo": false})
		_pantalla.call("_elegir_grupo", "mundo")
		_pantalla.call("_ir_a_pestana", "Federación")
		_pantalla.call("_refrescar")
	if _n == ESPERA + 2:
		_guardar("res://pruebas/capturas/pantalla_federacion.png")
	if _n == ESPERA + 4:
		_pantalla.call("_elegir_grupo", "finanzas")
		_pantalla.call("_ir_a_pestana", "Finanzas")
	if _n == ESPERA + 6:
		_guardar("res://pruebas/capturas/pantalla_precio_entrada.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
