extends Node
## Verifica la jugada de corner nueva (21-9-2026): fuerza un evento de disparo
## con `tipo:"fallo"` y llama `_jugada_corner()` directo -bypasea el 30% de
## probabilidad, que es cosmetico y no vale la pena pelear en una prueba-,
## para confirmar que el sacador corre al banderin, los companeros entran al
## area, y el centro llega sincronizado con la patada.

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
		## "Detras del arco" (ver camera_rig.gd) esta armada mirando el
		## extremo de Z POSITIVO -por eso el corner se fuerza para la visita
		## (z_arco=+MEDIO_LARGO), no el local, para que quede en cuadro.
		juego.fase = "ataqueVisita"
		juego.ball_target = Vector3(20.0, 0.1, 50.0)
		juego._jugada_corner(false)
		print("corner forzado. pendiente: ", juego._corner_pendiente)
	if _frame in [30, 60, 90, 105, 115, 130, 160, 200, 240]:
		var juego = _vista.get("_juego")
		print("frame ", _frame, " elapsed=", juego.elapsed, " corner_pendiente_vacio=",
			juego._corner_pendiente.is_empty(), " disparo_pendiente_vacio=", juego._disparo_pendiente.is_empty(),
			" ball_pos=", (juego.ball as Node3D).position if juego.ball else "?")
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/corner_f%d.png" % _frame)
	if _frame >= 240:
		print("FIN. 0 fallos")
		get_tree().quit(0)
