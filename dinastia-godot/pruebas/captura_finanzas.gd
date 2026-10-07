extends Node
## Comprueba la pestana "Finanzas" nueva: el libro de movimientos que llenan
## siete senales que llevaban tiempo sin que nadie las escuchara.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_finanzas.tscn

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
		## Un par de movimientos reales y variados: contratar staff (Finanzas no,
		## pero coste_subir mueve la caja directo) y una beca de cantera -
		## Cantera.movimiento-, ademas de forzar el cierre de mes -Finanzas.
		## movimiento- avanzando semanas.
		if mundo.cantera != null:
			var candidato: Jugador = null
			for j in mio.plantilla:
				if j.edad <= 21:
					candidato = j
					break
			if candidato != null:
				mundo.cantera.becar(candidato)
		for i in 5:
			_pantalla.call("_avanzar_semana")
		var tabs: TabContainer = _pantalla.get("_pestanas")
		for i2 in tabs.get_tab_count():
			if tabs.get_tab_title(i2) == "Finanzas":
				tabs.current_tab = i2
				break
		_pantalla.call("_refrescar")
	if _n == ESPERA + 4:
		_guardar("res://pruebas/capturas/pantalla_finanzas.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
