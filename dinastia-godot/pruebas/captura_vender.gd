extends Node
## Comprueba a ojo lo que el banco solo puede comprobar en numeros: la pestana
## Mercado con una oferta recibida de verdad (botones Aceptar/Rechazar) y la
## ficha de un jugador propio con las dos puertas nuevas, "VENDER" y
## "RESCINDIR CONTRATO", donde hasta esta tanda la ficha se quedaba en blanco.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_vender.tscn

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
		## Fuerza una oferta de verdad en vez de esperar al azar semanal.
		var j: Jugador = mio.plantilla[0]
		_mundo.mercado.listar_transferible(j)
		var intentos := 0
		while _mundo.mercado.ofertas_recibidas.is_empty() and intentos < 200:
			_mundo.mercado.buscar_oferta_por_mi_jugador()
			intentos += 1
		print("ofertas tras %d intentos: %d" % [intentos, _mundo.mercado.ofertas_recibidas.size()])
		var tabs: TabContainer = _pantalla.get("_pestanas")
		## "Mercado" es la pestana 1, la misma que usa captura.gd para la ficha
		## de un objetivo ajeno.
		tabs.current_tab = 1
		_pantalla.call("_refrescar")
	if _n == ESPERA + 4:
		_guardar("res://pruebas/capturas/pantalla_ofertas.png")
		## Ahora la ficha de un jugador PROPIO -antes se quedaba en blanco tras
		## los datos basicos-.
		var mio2: Club = _mundo.mi_club()
		_pantalla.call("_ver_ficha", mio2.plantilla[1])
	if _n == ESPERA + 8:
		_guardar("res://pruebas/capturas/pantalla_venta_ficha.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
