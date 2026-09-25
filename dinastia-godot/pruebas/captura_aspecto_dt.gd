extends Node
## Comprueba el retrato del DT y su editor (Club -> Mi Carrera -> Tu aspecto):
## `DT_PELOS`/`DT_TRAJES` existian en tablas.json sin que ninguna pantalla los
## usara -552 combinaciones escritas y ningun sitio donde elegirlas-.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_aspecto_dt.tscn

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
		var lista: Control = _pantalla.get("_lista_club")
		_pantalla.call("_limpiar", lista)
		_pantalla.call("_club_carrera", mio)
	if _n == ESPERA + 6:
		_guardar("res://pruebas/pantalla_aspecto_dt.png")
		var mundo: Mundo = _pantalla.get("mundo")
		var r: Roles = mundo.roles
		var look_antes := r.look_efectivo().duplicate()
		r.look = CaraDT.look_aleatorio()
		var look_despues := r.look_efectivo()
		var cambio := false
		for k in look_antes:
			if look_antes[k] != look_despues.get(k):
				cambio = true
		print("aleatorio cambio el aspecto = %s" % cambio)
		## Guardado y recarga: el aspecto tiene que sobrevivir.
		var datos := r.a_dic()
		var r2 := Roles.new(mundo)
		r2.desde_dic(datos)
		print("look sobrevive al guardado = %s" % (r2.look_efectivo() == look_despues))
		_pantalla.call("_refrescar")
	if _n == ESPERA + 10:
		_guardar("res://pruebas/pantalla_aspecto_dt_aleatorio.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
