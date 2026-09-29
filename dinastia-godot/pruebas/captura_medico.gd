extends Node
## Comprueba a ojo las cuatro señales de Medico que hasta esta tanda nadie
## escuchaba, más el botón nuevo "Pedir informe médico" -Medico.informe()
## estaba escrito entero y sin ningún botón que lo llamara-.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_medico.tscn

const ESPERA := 14

var _n := 0
var _pantalla: Node
var _mundo: Mundo

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		_mundo = _pantalla.get("mundo")
		var mio: Club = _mundo.mi_club()
		## Fuerza una lesion de entrenamiento de verdad, para que salga por la
		## señal lesion_nueva en vez de esperar al azar semanal.
		var j: Jugador = mio.plantilla[0]
		_mundo.medico.lesionar(j, _mundo.medico.MEDIA, "prueba forzada", _mundo.anio, _mundo.semana)
		## Y un informe médico de un rival, con la ficha abierta -el boton nuevo-.
		var ajeno: Jugador = null
		for c: Club in _mundo.clubes.values():
			if c.id != mio.id and not c.plantilla.is_empty():
				ajeno = c.plantilla[0]
				break
		_pantalla.call("_ver_ficha", ajeno)
	if _n == ESPERA + 2:
		_guardar("res://pruebas/capturas/pantalla_medico_lesion.png")
		## Simula pulsar "Pedir informe médico": llama al mismo handler del botón.
		_pantalla.call("_pedir_informe_medico", _pantalla.get("_seleccionado"))
	if _n == ESPERA + 6:
		_guardar("res://pruebas/capturas/pantalla_medico_informe.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
