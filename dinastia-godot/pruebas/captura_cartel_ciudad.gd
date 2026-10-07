extends Node
## Verifica si el cartel "Polideportivo" se ve gigante/distorsionado con la
## cámara REAL de arranque (110 m de altura, sin forzar nada) -a diferencia de
## `captura_sdfgi.gd`, que fuerza la cámara a 65 m para otra prueba y hace que
## todo, carteles incluidos, se vea más grande de lo normal.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##         res://pruebas/captura_cartel_ciudad.tscn

var _n := 0
var _vista: VistaCiudad
var _mundo: Mundo

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4713)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	for k in _mundo.obras.niveles.keys():
		_mundo.obras.niveles[k] = 3
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.abrir(_mundo.mi_club(), _mundo.obras, _mundo.ciudad,
		_mundo.perfil_estadio_de(_mundo.mi_club()))
	_vista.set("_girando", false)

func _process(_d: float) -> void:
	_n += 1
	if _n == 20:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/cartel_ciudad_camara_real.png")
		print("guardado")
		get_tree().quit()
