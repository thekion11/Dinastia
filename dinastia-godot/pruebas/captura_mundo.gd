extends Node
## Dos pantallas nuevas en una sola corrida:
##  - "Clubes" (`vLigas` + `vClubes` + `vFichaClub` + `vGoleadores` fusionadas):
##    se juega una temporada entera antes, o las tablas salen a cero y los
##    goleadores vacíos, que no prueba nada.
##  - "Premios" (`vPremios`): hace falta CERRAR la temporada para que la gala
##    exista.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_mundo.tscn

const ESPERA := 12

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		var mun = _pantalla.get("mundo")
		mun.jugar_temporada()
		_pantalla.call("_elegir_grupo", "mundo")
		_pantalla.call("_ir_a_pestana", "Clubes")
		_pantalla.call("_refrescar")
	if _n == ESPERA + 2:
		_guardar("res://pruebas/capturas/pantalla_clubes.png")
	if _n == ESPERA + 4:
		## Abrir el plantel de un club ajeno: eso es `vFichaClub`.
		var mun = _pantalla.get("mundo")
		var otro: Club = null
		for c in mun.ligas[0].clubes:
			if c != mun.mi_club():
				otro = c
				break
		_pantalla.set("_clubes_ficha", otro)
		_pantalla.call("_pintar_clubes")
	if _n == ESPERA + 6:
		_guardar("res://pruebas/capturas/pantalla_ficha_club.png")
	if _n == ESPERA + 8:
		## Y la gala: cerrar la temporada la genera.
		_pantalla.call("_nueva_temporada")
		_pantalla.call("_elegir_grupo", "club")
		_pantalla.call("_ir_a_pestana", "Premios")
	if _n == ESPERA + 10:
		_guardar("res://pruebas/capturas/pantalla_premios.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
