extends Node
## Comprueba el visor 3D de la ciudad deportiva recien portado a este
## proyecto: que el boton "Ver la ciudad en 3D" de Club -> Ciudad de verdad
## abre `VistaCiudad`, que el complejo se construye con las instalaciones
## reales del club -no vacio- y que "Volver" restaura la pantalla.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_ciudad_propia.tscn

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
		var tabs: TabContainer = _pantalla.get("_pestanas")
		for i in tabs.get_tab_count():
			if tabs.get_tab_title(i) == "Club":
				tabs.current_tab = i
				break
		var mio: Club = mundo.mi_club()
		## Instalaciones a un nivel real, para que el complejo no salga vacio.
		mundo.obras.niveles["ct"] = 3
		mundo.obras.niveles["acad"] = 2
		mundo.obras.niveles["med"] = 2
		mundo.obras.niveles["gim"] = 1
		mundo.obras.niveles["park"] = 2
		## Y terrenos/negocios, para ver las parcelas comprades y sus edificios:
		## dos compradas (norte, centro) y dos sin comprar (sur, ribera), que es
		## justo el contraste que hay que poder distinguir de un vistazo.
		mundo.ciudad.terrenos = ["norte", "centro", "periferia"]
		mundo.ciudad.negocios["hotel"] = true
		mundo.ciudad.negocios["parking"] = true
		mundo.ciudad.negocios["comercial"] = true
		mundo.ciudad.negocios["clinica"] = true
		_pantalla.call("_pintar_ciudad", mio)
		var lista: Control = _pantalla.get("_lista_ciudad")
		var boton := _buscar_boton(lista, "Ver la ciudad en 3D")
		if boton == null:
			print("NO SE ENCONTRO el boton 'Ver la ciudad en 3D'")
			get_tree().quit()
			return
		print("boton encontrado, pulsando...")
		boton.pressed.emit()
	if _n == ESPERA + 30:
		var hijos := _pantalla.get_children().filter(func(c): return c is VistaCiudad)
		print("VistaCiudad abierta = %s" % (not hijos.is_empty()))
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pantalla_ciudad_3d.png")
		print("captura: pantalla_ciudad_3d.png")
	if _n == ESPERA + 60:
		var hijos := _pantalla.get_children().filter(func(c): return c is VistaCiudad)
		if not hijos.is_empty():
			(hijos[0] as VistaCiudad).cerrado.emit()
	if _n == ESPERA + 66:
		var hijos := _pantalla.get_children().filter(func(c): return c is VistaCiudad)
		print("VistaCiudad sigue abierta tras Volver = %s" % (not hijos.is_empty()))
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pantalla_ciudad_despues_de_volver.png")
		get_tree().quit()

func _buscar_boton(n: Node, texto: String) -> Button:
	if n is Button and String((n as Button).text).contains(texto):
		return n
	for h in n.get_children():
		var r := _buscar_boton(h, texto)
		if r != null:
			return r
	return null
