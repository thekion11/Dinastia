extends Node
## Verifica el reporte del usuario ("jugadores hundidos en el suelo") con una
## camara dedicada, muy cerca y a la altura del tobillo, apuntando directo a
## los pies de un jugador parado -las capturas anteriores (tactica, festejo)
## no estaban lo bastante cerca para confirmar o descartar esto con certeza.

var _vista: VistaEstadio
var _mundo: Mundo
var _partido: Partido
var _frame := 0
var _cam: Camera3D

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4711)
	_mundo.mi_club_id = _mundo.ligas[0].clubes[0].id
	var par := _mundo.proximo_partido()
	_partido = Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], _partido)
	_cam = Camera3D.new()
	_cam.fov = 30
	add_child(_cam)

func _process(_d: float) -> void:
	_frame += 1
	if _frame == 40:
		## Un jugador cualquiera del campo, de pie, en calma -no en medio de
		## una animacion de carrera- para juzgar el contacto pie-suelo sin que
		## el movimiento lo complique.
		var juego = _vista.get("_juego")
		var jugadores: Array = juego.players if juego != null else []
		print("jugadores encontrados: ", jugadores.size())
		if jugadores.size() > 0:
			var j = jugadores[0]
			var nodo: Node3D = j.get("node") if j is Dictionary else j
			if is_instance_valid(nodo):
				var p: Vector3 = nodo.global_position
				_cam.global_position = p + Vector3(1.6, 0.35, 1.6)
				_cam.look_at(p + Vector3(0, -0.05, 0), Vector3.UP)
				_cam.current = true
				print("jugador en: ", p)
	if _frame == 45:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pies_suelo.png")
		print("FIN. 0 fallos")
		get_tree().quit(0)
