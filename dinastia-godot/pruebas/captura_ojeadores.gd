extends Node
## Comprueba la red de ojeadores con nombre y sesgo: la seccion nueva en Club,
## la media borrosa de un rival en su ficha, y el boton "Pedir informe de ojeo".
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_ojeadores.tscn

const ESPERA := 14

var _n := 0
var _pantalla: Node
var _mundo: Mundo
var _rival: Jugador

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		_mundo = _pantalla.get("mundo")
		var mio: Club = _mundo.mi_club()
		mio.mover_saldo(500000000)
		for i in 3:
			_mundo.staff.subir("ojeador", mio)
		_mundo.ojeadores.alternar_pais("ARG")
		var tabs: TabContainer = _pantalla.get("_pestanas")
		for i2 in tabs.get_tab_count():
			if tabs.get_tab_title(i2) == "Club":
				tabs.current_tab = i2
				break
		_pantalla.call("_refrescar")
	if _n == ESPERA + 4:
		_guardar("res://pruebas/pantalla_ojeadores.png")
		## Un rival de un pais SIN cubrir, para ver el rango borroso en su ficha.
		for c: Club in _mundo.clubes.values():
			if c.id != _mundo.mi_club_id and c.pais != "ARG" and c.pais != _mundo.mi_club().pais and not c.plantilla.is_empty():
				_rival = c.plantilla[0]
				break
		_pantalla.call("_ver_ficha", _rival)
	if _n == ESPERA + 8:
		_guardar("res://pruebas/pantalla_ficha_borrosa.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
