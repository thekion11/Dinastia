extends Node
## Comprueba el logo nuevo de `Marca` en la pantalla de Finanzas: antes un
## sponsor era solo una palabra pintada de su color, ahora tiene una insignia
## propia al lado -mismo capitulo que el logo del sorteo y la sala de prensa.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_sponsor.tscn

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
		mundo.auspicio.generar_ofertas(mio)
		var err := mundo.auspicio.firmar(0)
		print("firmar(0) -> '%s'   contrato: %s" % [err, mundo.auspicio.contrato])
		var tabs: TabContainer = _pantalla.get("_pestanas")
		for i in tabs.get_tab_count():
			if tabs.get_tab_title(i) == "Finanzas":
				tabs.current_tab = i
				break
		_pantalla.call("_refrescar")
	if _n == ESPERA + 2:
		var lista: Control = _pantalla.get("_lista_finanzas")
		var scroll := lista.get_parent()
		if scroll is ScrollContainer:
			(scroll as ScrollContainer).scroll_vertical = 100000
	if _n == ESPERA + 6:
		_guardar("res://pruebas/capturas/pantalla_sponsor.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
