extends Node
## Comprueba "EMBAJADOR DEL CLUB" en la pestana Club: las tres candidatas y,
## tras fichar una, la fila con nombre/sueldo y el boton Cesar.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_embajador.tscn

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
		mio.mover_saldo(50000000)
		var tabs: TabContainer = _pantalla.get("_pestanas")
		for i in tabs.get_tab_count():
			if tabs.get_tab_title(i) == "Club":
				tabs.current_tab = i
				break
		_pantalla.call("_refrescar")
	if _n == ESPERA + 4:
		_guardar("res://pruebas/pantalla_embajador_candidatas.png")
		## Ahora se ficha a la primera candidata y se vuelve a capturar.
		var mundo: Mundo = _pantalla.get("mundo")
		var cand: Array = Directiva.candidatas_embajador(mundo.cantera.leyendas, mundo.anio)
		if not cand.is_empty():
			mundo.directiva.contratar_embajador(cand[0])
		_pantalla.call("_refrescar")
	if _n == ESPERA + 8:
		_guardar("res://pruebas/pantalla_embajador_fichado.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
