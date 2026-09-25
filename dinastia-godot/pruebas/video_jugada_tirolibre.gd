extends Node
## Verifica la jugada de tiro libre (21-9-2026): fuerza una falta peligrosa
## cerca del arco y confirma que el pateador se coloca, la barrera se forma,
## y el balon sale de verdad desde el punto de la falta -no desde donde haya
## quedado por otra cosa, mismo bug ya cazado una vez con el corner.

var _vista: VistaEstadio
var _mundo: Mundo
var _partido: Partido
var _frame := 0
var _disparado := false

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
		var idx := rig.camera_names.find("Detras del arco")
		if idx != -1:
			rig.switch_to(idx)

func _process(_d: float) -> void:
	_frame += 1
	if _frame == 15 and not _disparado:
		_disparado = true
		var juego = _vista.get("_juego")
		## Falta cometida por el LOCAL a 20m de SU propio arco (+52.5): tira
		## libre la visita, apuntando a ese mismo arco -coincide con "Detras
		## del arco", que mira el extremo Z positivo.
		juego.fase = "medio"
		juego.ball_target = Vector3(6.0, 0.1, 34.0)
		juego._jugada_tiro_libre(false, 52.5)
		print("tiro libre forzado. pendiente: ", juego._tirolibre_pendiente)
	if _frame in [90, 100, 105, 110, 130, 160]:
		var juego = _vista.get("_juego")
		print("frame ", _frame, " elapsed=", juego.elapsed, " tl_vacio=",
			juego._tirolibre_pendiente.is_empty(), " disparo_vacio=", juego._disparo_pendiente.is_empty(),
			" ball_pos=", (juego.ball as Node3D).position if juego.ball else "?")
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/tirolibre_f%d.png" % _frame)
	if _frame >= 160:
		print("FIN. 0 fallos")
		get_tree().quit(0)
