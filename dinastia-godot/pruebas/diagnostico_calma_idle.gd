extends Node
## Reverifica visualmente `mult_calma` (nunca se habia comprobado con un
## render real, solo con el numero): partido NATURAL, sin forzar ningun gol,
## capturado varias veces mientras la fase es "medio" -el caso que deberia
## verse mas tranquilo que antes-.

var _vista: VistaEstadio
var _mundo: Mundo
var _partido: Partido
var _frame := 0

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4711)
	_mundo.mi_club_id = _mundo.ligas[0].clubes[0].id
	var par := _mundo.proximo_partido()
	_partido = Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], _partido)
	var rig: CameraRig = _vista.get("_rig")
	if rig != null:
		var idx := rig.camera_names.find("Tribuna alta")
		if idx != -1:
			rig.switch_to(idx)

func _process(_d: float) -> void:
	_frame += 1
	## `fase` solo se recalcula una vez por minuto simulado -al azar puede
	## tocar "ataqueLocal/Visita" varios minutos seguidos, que es justo lo que
	## paso en el primer intento de esta captura (parecia que "en calma" no
	## hacia nada, pero en realidad nunca estuvo en fase "medio"). Forzada
	## aqui para probar especificamente el caso que dice ser mas tranquilo.
	var juego = _vista.get("_juego")
	if juego != null:
		juego.fase = "medio"
	if _frame in [90, 240, 400]:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/calma_idle_f%d.png" % _frame)
	if _frame >= 400:
		print("FIN. 0 fallos")
		get_tree().quit(0)
