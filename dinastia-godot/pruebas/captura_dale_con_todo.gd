extends Node
## Prueba visual de la tanda "dale con todo": solicitudes del plantel,
## intercambio de jugadores en la mesa de negociación, y entrenamiento
## individual. Sin `_avanzar_semana()` en bloque -el sorteo de copa que se
## engancha ahí ya colgó una vez esta sesión-: se fuerza el estado a mano.

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		var mundo: Mundo = _pantalla.get("mundo")
		## 1) Solicitud forzada -saltando el sorteo de candidatos, directo al
		## estado ya elegido, para no depender del azar en una prueba.
		var mio: Club = mundo.mi_club()
		var j: Jugador = mio.plantilla[0]
		mundo.vestuario.solicitud = {"pid": j.id, "k": "sueldo"}
		_pantalla.call("_elegir_grupo", "central")
		_pantalla.call("_refrescar")
	if _n == 14:
		_guardar("res://pruebas/pantalla_solicitud.png")
		## 2) Entrenamiento individual: la pestaña ya existe en el menú.
		_pantalla.call("_ir_a_pestana", "Entrenar")
	if _n == 16:
		_guardar("res://pruebas/pantalla_entreno_individual.png")
		## 3) Mesa de negociación con un objetivo del mercado, para ver el
		## selector de intercambio.
		var mundo2: Mundo = _pantalla.get("mundo")
		var objetivos: Array = _pantalla.call("_objetivos", mundo2.mi_club())
		if not objetivos.is_empty():
			mundo2.mercado.abrir_negociacion(objetivos[0])
		_pantalla.call("_ir_a_pestana", "Mercado")
		_pantalla.call("_refrescar")
	if _n == 18:
		_guardar("res://pruebas/pantalla_intercambio.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
