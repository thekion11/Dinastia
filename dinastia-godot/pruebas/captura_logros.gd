extends Node
## Dirige varios partidos y juega varias temporadas con el club mas fuerte de
## su liga, para que la memoria del club tenga contenido real: titulos, records
## y algun logro desbloqueado. Antes de engancharla, esta pestana solo mostraba
## la lista entera en "por hacer" para siempre.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_logros.tscn

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
		## Se cambia al club de mas reputacion de su liga -mismo truco que el
		## banco- para maximizar las chances de titulo en pocas temporadas.
		var favorito: Club = mun.ligas[0].clubes[0]
		for c: Club in mun.ligas[0].clubes:
			if c.rep > favorito.rep:
				favorito = c
		mun.tomar_el_mando(favorito.id)
		_pantalla.call("_conectar_noticias")
		for temporada in 6:
			mun.jugar_temporada()
			mun.nueva_temporada()
		_pantalla.call("_refrescar")
		var tabs: TabContainer = _pantalla.get("_pestanas")
		for i in tabs.get_tab_count():
			if tabs.get_tab_title(i) == "Logros":
				tabs.current_tab = i
				break
	if _n == ESPERA + 6:
		_guardar("res://pruebas/capturas/pantalla_logros.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
