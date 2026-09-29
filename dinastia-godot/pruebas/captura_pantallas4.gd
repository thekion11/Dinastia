extends Node
## Comprueba las cuatro pantallas que el LEEME.md daba por "sin portar todavia"
## (entrenamiento, federacion, estadio propio, rol/cargo) pero que ya estan
## escritas en principal.gd. Si cargan sin reventar y con contenido visible,
## la documentacion estaba desactualizada, no el codigo.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_pantallas4.tscn

const ESPERA := 12

var _n := 0
var _pantalla: Node
var _tabs: TabContainer

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		_tabs = _pantalla.get("_pestanas")
		## Federacion sin votacion pendiente no se ve: se fuerza una para que la
		## captura muestre algo, igual que captura.gd fuerza una rueda de prensa.
		var mun = _pantalla.get("mundo")
		## abrir_votacion() tira una moneda (PROB_VOTACION) cada vez que se llama:
		## no es un bug que una sola llamada no abra nada, es como esta disenado
		## -"la federacion convoca cada tanto"-. Para la captura se insiste hasta
		## que toque, que es lo que en juego normal harian muchas semanas seguidas.
		if mun.federacion != null:
			for intento in 500:
				if not mun.federacion.voto_pendiente.is_empty():
					break
				mun.federacion.abrir_votacion()
			_pantalla.call("_refrescar")
		## Un jugador elegido para que el arbol de habilidades salga con algo
		## dentro, igual que captura.gd elige al mejor para la ficha.
		var mio: Club = mun.mi_club()
		if not mio.plantilla.is_empty():
			_pantalla.call("_ver_ficha", mio.plantilla[0])
		_ir_a("Entrenar")
	if _n == ESPERA + 6:
		_guardar("res://pruebas/capturas/pantalla_entrenar2.png")
		_ir_a("Federación")
	if _n == ESPERA + 12:
		_guardar("res://pruebas/capturas/pantalla_federacion.png")
		_ir_a("Club")
	if _n == ESPERA + 17:
		## "TU CARGO" va al final de la pestana Club, despues de directiva, staff
		## y obras: hay que bajar el scroll para que salga en la captura.
		var lista_club: VBoxContainer = _pantalla.get("_lista_club")
		var scroll := lista_club.get_parent() as ScrollContainer
		if scroll != null:
			scroll.scroll_vertical = 100000
	if _n == ESPERA + 18:
		_guardar("res://pruebas/capturas/pantalla_rol.png")
		_ir_a("Estadio")
	if _n == ESPERA + 24:
		_guardar("res://pruebas/capturas/pantalla_estadio2.png")
		get_tree().quit()

func _ir_a(nombre: String) -> void:
	for i in _tabs.get_tab_count():
		if _tabs.get_tab_title(i) == nombre or _tabs.get_child(i).name == nombre:
			_tabs.current_tab = i
			return
	print("AVISO: no encuentro la pestana '%s'" % nombre)

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
