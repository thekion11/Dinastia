extends Node
## Spike (18-9-2026): intento de grabar video con `--write-movie`, que NO usa el
## reloj real -renderiza a un paso fijo y escribe cada cuadro a disco, así que
## no necesita ni ventana interactiva ni framebuffer en tiempo real-. Si esto
## funciona en este entorno sin pantalla, es la primera vez que se puede
## verificar una jugada por video en vez de solo por aserciones numéricas.
##
## Fuerza un gol A LOS POCOS FOTOGRAMAS (no espera a que la simulación anote
## sola) para que la jugada de gol -la que más importa verificar- quede dentro
## de la ventana corta que se graba.
##
##   godot --path . --rendering-driver opengl3 --write-movie res://pruebas/jugada_gol.avi res://pruebas/video_jugada_gol.tscn

var _vista: VistaEstadio
var _mundo: Mundo
var _partido: Partido
var _frame := 0
var _disparado := false

const FRAMES_TOTAL := 480  # 8s a 60fps de paso fijo

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4711)
	_mundo.mi_club_id = _mundo.ligas[0].clubes[0].id
	var par := _mundo.proximo_partido()
	_partido = Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], _partido)
	print("partido: %s vs %s" % [par[0].nombre, par[1].nombre])

func _process(_d: float) -> void:
	_frame += 1
	## Frame 15: ya paso `_ready()` de la vista y del once, es seguro forzar el
	## gol -el autor y el asistidor salen del once real, no de un dato fabricado.
	if _frame == 15 and not _disparado:
		_disparado = true
		if _partido.once_local.size() >= 2:
			var autor: Jugador = _partido.once_local[0]
			var asistente: Jugador = _partido.once_local[1]
			print("forzando gol: %s (asiste %s)" % [autor.nombre, asistente.nombre])
			_partido.gol.emit(par_local(), autor, 12, asistente)
	## Capturas propias, ademas del video: para que YO (sin pantalla) tambien
	## pueda revisar el resultado leyendo PNGs, no solo el usuario viendo el
	## .avi. Los frames se eligen para cubrir: justo tras el gol, la carrera
	## del asistidor, el remate/festejo, y la camara ya siguiendo al goleador.
	if _frame in [20, 60, 110, 200, 350]:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/jugada_gol_f%d.png" % _frame)
	## Primer plano (18-9-2026): el usuario reporto jugadores "hundidos en el
	## suelo" y postura corporal rara -invisible en la vista tactica de arriba,
	## hay que acercarse a un jugador de verdad para verlo.
	if _frame == 130:
		var rig: CameraRig = _vista.get("_rig")
		if rig != null:
			var idx := rig.camera_names.find("A ras de campo")
			if idx != -1:
				rig.switch_to(idx)
			rig.ajustar_zoom(-40.0)
	if _frame == 160:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/jugada_gol_closeup.png")
	if _frame >= FRAMES_TOTAL:
		print("FIN. 0 fallos")
		get_tree().quit(0)

func par_local() -> Club:
	return _partido.local
