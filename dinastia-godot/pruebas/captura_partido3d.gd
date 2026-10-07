extends Node
## Juega un partido de verdad en 3D y lo captura en varios minutos.
##
## Es la prueba de que las dos mitades estan conectadas: los jugadores que se
## mueven son los del once real, el marcador que sube es el del `Partido` que
## alimenta la tabla, y el gol que se ve es el mismo gol que cuenta.
##
##   godot --path . --rendering-driver vulkan res://pruebas/captura_partido3d.tscn

const ARRANQUE := 20

var _n := 0
var _vista: VistaEstadio
var _mundo: Mundo
var _partido: Partido
var _disparos := 0
## En que minutos del partido se dispara una captura.
const MINUTOS := [8, 40, 75]

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4711)
	_mundo.mi_club_id = _mundo.ligas[0].clubes[0].id
	var par := _mundo.proximo_partido()
	_partido = Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.9, par[1], _partido)
	## Al maximo, o noventa minutos a velocidad de juego serian dos minutos de
	## reloj real y la captura tardaria una eternidad.
	_vista.get("_juego").vel_idx = 4
	print("partido: %s vs %s" % [par[0].nombre, par[1].nombre])
	print("tamano de la vista: %s   viewport: %s" % [_vista.size, get_viewport().get_visible_rect().size])

func _process(_d: float) -> void:
	_n += 1
	if _n < ARRANQUE or _disparos >= MINUTOS.size():
		return
	if _partido.minuto < MINUTOS[_disparos]:
		return
	var img := get_viewport().get_texture().get_image()
	var ruta := "res://pruebas/capturas/partido3d_%d.png" % (_disparos + 1)
	img.save_png(ruta)
	print("captura %s en el minuto %d, marcador %d-%d, %d en el campo" % [
		ruta, _partido.minuto, _partido.goles_local, _partido.goles_visita,
		(_vista.get("_en_campo") as Array).size()])
	_disparos += 1
	if _disparos >= MINUTOS.size():
		print("cronica: %d sucesos" % _partido.cronica.size())
		get_tree().quit()
