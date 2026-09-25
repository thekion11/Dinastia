extends Node
## Escribe un nombre de club y funda, para ver la pantalla de club resultante
## con el club nuevo, su plantel y sus colores.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_fundar.tscn

const ESPERA := 20

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/eleccion_club.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		## OJO: no se llama a _fundar() -dispara change_scene_to_file() de
		## verdad, y como este nodo de prueba ES la escena actual, se
		## destruiria a si mismo a mitad de la prueba (la misma trampa que ya
		## dejo anotada pruebas/captura_contratos.gd). Se replica el mismo
		## efecto a mano: fundar en el nucleo, y el cambio de "escena" es solo
		## instanciar principal.tscn como hijo, igual que el resto de capturas.
		var mun: Mundo = _pantalla.get("_mundo")
		mun.fundar_club("Atlético Prueba", "CHI")
		Principal.mundo_pregenerado = mun
	if _n == ESPERA + 2:
		_pantalla.queue_free()
		_pantalla = load("res://escenas/principal.tscn").instantiate()
		add_child(_pantalla)
	if _n == ESPERA + 8:
		_pantalla.call("_refrescar")
	if _n == ESPERA + 10:
		_guardar("res://pruebas/pantalla_fundar.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
