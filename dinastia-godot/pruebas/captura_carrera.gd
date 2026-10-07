extends Node
## Comprueba "TU CARRERA" en la pestana Club: prestigio, historial, ascenso y
## -forzando el rol a dueno- las acciones de dueno (inyectar capital, vender
## el club) y el entrenador empleado. Todo esto ya vivia en Roles, sin ninguna
## pantalla que lo mostrara.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_carrera.tscn

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
		mio.mover_saldo(50000000)
		mundo.roles.rol = "dueño"
		mundo.roles.rol_cambiado.emit("dt", "dueño")
		mundo.roles.trofeos.append({"anio": mundo.anio, "titulo": "Liga"})
		mundo.roles.trofeos.append({"anio": mundo.anio, "titulo": "Copa"})
		mundo.roles.historial.append({"club": "Everton", "hasta": mundo.anio - 2})
		mundo.roles.prestigio = 84
		mundo.roles.call("_contratar_dt_empleado")
		var tabs: TabContainer = _pantalla.get("_pestanas")
		for i in tabs.get_tab_count():
			if tabs.get_tab_title(i) == "Club":
				tabs.current_tab = i
				break
		_pantalla.call("_refrescar")
	if _n == ESPERA + 2:
		## "TU CARRERA" queda mas abajo del scroll: se fuerza al fondo para que
		## la captura la enseñe.
		var lista: VBoxContainer = _pantalla.get("_lista_club")
		var scroll: ScrollContainer = lista.get_parent()
		scroll.scroll_vertical = 100000
	if _n == ESPERA + 4:
		_guardar("res://pruebas/capturas/pantalla_carrera.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
