extends Node
## Los tres mapas del transporte (completo, autobuses, metro) a 1600x900. NO corre con --headless:
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_mapas.tscn
## Sale en /tmp/mapa_transporte_N.png (CAPTURA_SALIDA cambia la carpeta).

var _n := 0
var _mapa: MapaTransporte

func _ready() -> void:
	var b := CityBuilder.new()
	add_child(b)
	for tm in b._terreno():
		b.add_child(tm)   ## con el terreno de verdad (la cima del cerro queda a ~400 m)
	var ex := CiudadExpansion.new(b)
	ex.armar_red()
	ex.armar_bloques()
	ex.armar_transporte()
	ex.tele_nodo = Teleferico.montar(b)
	ex.teleferico = ex.tele_nodo.datos()
	_mapa = MapaTransporte.crear(ex, 0)
	add_child(_mapa)

func _process(_d: float) -> void:
	_n += 1
	var carpeta := OS.get_environment("CAPTURA_SALIDA") if OS.get_environment("CAPTURA_SALIDA") != "" else "/tmp"
	if _n % 5 == 0 and _n / 5 <= 3:
		get_viewport().get_texture().get_image().save_png("%s/mapa_transporte_%d.png" % [carpeta, _n / 5 - 1])
		_mapa.modo = mini(_n / 5, 2)
		_mapa.queue_redraw()
	if _n > 5 * 4:
		get_tree().quit()
