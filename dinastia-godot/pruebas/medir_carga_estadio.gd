extends Node
## LA PRIMERA CARGA DEL ESTADIO (MEGAPLAN fase 2): cuánto tarda abrirlo la
## primera vez y la segunda (con las cachés de caras y pelo ya llenas).
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/medir_carga_estadio.tscn
var _n := 0
var _mundo: Mundo
var _vista: VistaEstadio

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 777)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)

func _abrir() -> int:
	var par := _mundo.proximo_partido()
	var t := Time.get_ticks_msec()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))
	return Time.get_ticks_msec() - t

func _process(_d: float) -> void:
	_n += 1
	if _n == 3:
		print("MEDIDA primera apertura: %d ms" % _abrir())
	if _n == 8:
		_vista.queue_free()
	if _n == 10:
		print("MEDIDA segunda apertura: %d ms" % _abrir())
	if _n == 14:
		get_tree().quit()
