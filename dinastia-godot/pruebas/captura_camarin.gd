extends Node
## Comprueba la pestana "Camarin" nueva: clanes/camarillas, salud mental
## (ansiedad, terapia, descanso) y jerarquia interna -toda logica ya escrita
## en Vestuario, sin ninguna pantalla que la mostrara-.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_camarin.tscn

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
		## Fuerza a alguien a ansiedad alta de verdad, para que aparezca en
		## "SALUD MENTAL" sin depender del sorteo semanal.
		if not mio.plantilla.is_empty():
			var f: Dictionary = mundo.vestuario.mente(mio.plantilla[0])
			f["ansiedad"] = 60
		var tabs: TabContainer = _pantalla.get("_pestanas")
		for i in tabs.get_tab_count():
			if tabs.get_tab_title(i) == "Camarín":
				tabs.current_tab = i
				break
		_pantalla.call("_refrescar")
	if _n == ESPERA + 4:
		_guardar("res://pruebas/pantalla_camarin.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
