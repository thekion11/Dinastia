extends Node
## Capturas de la pantalla de idioma (fase 1, etapa 1) en Forward+:
##   CAPTURA_SIN_CERROJO=1 flock /tmp/godot.lock herramientas/captura.sh res://pruebas/f1l_captura_idioma.tscn
## Tres momentos: recién abierta en castellano, con el turco enfocado (el fondo se
## tiñe y todo habla turco) y la confirmación del alemán abierta.

var _n := 0
var _p: PantallaIdioma

func _ready() -> void:
	Idiomas.idioma = "es"
	_p = PantallaIdioma.new()
	_p.configurar({"idioma": "es"})
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	match _n:
		45:
			_guardar("res://pruebas/capturas/f1l_idioma_1_es.png")
			_p.enfocar("tr")
		90:
			_guardar("res://pruebas/capturas/f1l_idioma_2_tr.png")
			_p.enfocar("de")
		100:
			_p.elegir("de")
		140:
			_guardar("res://pruebas/capturas/f1l_idioma_3_confirmar_de.png")
			Idiomas.idioma = "es"
			get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
