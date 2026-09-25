extends Node
## Comprueba el comparador nuevo -vComparador() de vistas.js, un archivo que
## esta sesion no habia mirado hasta hoy-: tres jugadores lado a lado, con
## potencial escondido salvo que sea tuyo o lo hayas ojeado.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_comparar.tscn

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
		var comp: Array = _pantalla.get("_comparar_ids")
		## Uno tuyo (potencial siempre visible) y dos ajenos -uno ojeado, otro no-.
		comp.append(mio.plantilla[0].id)
		var ajenos: Array[Jugador] = []
		for c: Club in _mundo.clubes.values():
			if c.id != mio.id:
				for j in c.plantilla:
					if j.edad <= 23:
						ajenos.append(j)
					if ajenos.size() >= 2:
						break
			if ajenos.size() >= 2:
				break
		comp.append(ajenos[0].id)
		comp.append(ajenos[1].id)
		_mundo.ojeados[ajenos[0].id] = true
		print("comparando: ", mio.plantilla[0].nombre, " / ", ajenos[0].nombre, " (ojeado) / ", ajenos[1].nombre, " (sin ojear)")
		var tabs: TabContainer = _pantalla.get("_pestanas")
		for i in tabs.get_tab_count():
			if tabs.get_tab_title(i) == "Comparar":
				tabs.current_tab = i
				break
		_pantalla.call("_refrescar")
	if _n == ESPERA + 4:
		_guardar("res://pruebas/pantalla_comparador.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
