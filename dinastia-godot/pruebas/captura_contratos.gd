extends Node
## Cede a un canterano, pacta una clausula propia, y abre la ficha de un rival
## con clausula para ver el boton del clausulazo -las tres cosas que hasta hoy
## no se podian hacer desde ningun lado.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_contratos.tscn

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
		var mio: Club = mun.mi_club()
		## Un canterano a prestamo, para que "CEDIDOS FUERA" no salga vacio.
		for j in mio.plantilla:
			if j.edad <= Cesiones.EDAD_CANTERANO:
				mun.cesiones.ceder_canterano(j)
				break
		## Una clausula propia, para que la lista no salga toda "sin clausula".
		var mejor: Jugador = mio.plantilla[0]
		for j in mio.plantilla:
			if j.ovr > mejor.ovr:
				mejor = j
		mun.cesiones.blindar(mejor)
		_pantalla.call("_refrescar")
		var tabs: TabContainer = _pantalla.get("_pestanas")
		for i in tabs.get_tab_count():
			if tabs.get_tab_title(i) == "Contratos":
				tabs.current_tab = i
				break
	if _n == ESPERA + 6:
		_guardar("res://pruebas/capturas/pantalla_contratos.png")
		## Y la ficha de un rival con clausula, para ver el clausulazo.
		var mun = _pantalla.get("mundo")
		var mio: Club = mun.mi_club()
		for c: Club in mun.clubes.values():
			if c.id == mio.id:
				continue
			for j in c.plantilla:
				if mun.cesiones.clausula_de(j) > 0:
					_pantalla.call("_ver_ficha", j)
					break
			if _pantalla.get("_seleccionado") != null:
				break
	if _n == ESPERA + 10:
		_guardar("res://pruebas/capturas/pantalla_clausulazo.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
