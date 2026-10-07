extends Node
## Abre la pantalla de inicio (que desde que se fusiono con la de seleccion de
## modo lleva la grilla completa), la captura, y comprueba que elegir
## "Ayudante de Campo" de verdad llega hasta Roles cuando arranca Principal.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_modo.tscn

const ESPERA := 12

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/inicio.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		_guardar("res://pruebas/capturas/pantalla_modo.png")
		## Simula el clic: mismo efecto que _elegir("ayudante") sin depender de
		## encontrar el boton exacto en el arbol.
		Principal.modo_elegido = "ayudante"
		Principal.dt_nombre_elegido = "Prueba Banco"
	if _n == ESPERA + 2:
		_pantalla.queue_free()
		_pantalla = load("res://escenas/principal.tscn").instantiate()
		add_child(_pantalla)
	if _n == ESPERA + 6:
		var mun = _pantalla.get("mundo")
		print("rol tras elegir ayudante: ", mun.roles.rol, "  es_ayudante=", mun.roles.es_ayudante(),
			"  nombre_dt=", mun.roles.nombre, "  mercado_bloqueado=", mun.roles.mercado_bloqueado() != "")
		_pantalla.call("_refrescar")
		var tabs: TabContainer = _pantalla.get("_pestanas")
		for i in tabs.get_tab_count():
			if tabs.get_tab_title(i) == "Club":
				tabs.current_tab = i
				break
	if _n == ESPERA + 9:
		_guardar("res://pruebas/capturas/pantalla_modo_ayudante.png")
		## Y la ficha de un rival, para ver que el ayudante NO tiene botones de
		## fichar -el permiso que se acaba de hacer cumplir de verdad.
		var mun = _pantalla.get("mundo")
		var mio: Club = mun.mi_club()
		for c: Club in mun.clubes.values():
			if c.id != mio.id and not c.plantilla.is_empty():
				_pantalla.call("_ver_ficha", c.plantilla[0])
				break
		_pantalla.call("_refrescar")
	if _n == ESPERA + 12:
		_guardar("res://pruebas/capturas/pantalla_ayudante_sin_fichar.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
