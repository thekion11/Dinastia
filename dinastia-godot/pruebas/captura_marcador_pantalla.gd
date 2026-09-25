extends Node
## Verifica a ojo la pantalla con el resultado en vivo (22-9-2026, pedido
## repetido del usuario: "puede estar una visualización... del resultado que
## van"). Fuerza un par de goles y confirma que el marcador de la pantalla
## cambia con ellos.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_marcador_pantalla.tscn

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
	print("partido: %s vs %s" % [par[0].nombre, par[1].nombre])

	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 35.0
	cam.position = Vector3(0.0, 17.5, 40.0)
	cam.look_at(Vector3(0.0, 17.5, 62.4), Vector3.UP)
	cam.current = true

func _process(_d: float) -> void:
	_frame += 1
	if _frame == 15:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/pantalla_marcador_0_0.png")
		print("captura guardada: pantalla_marcador_0_0.png")
		if _partido.once_local.size() >= 1:
			_partido.gol.emit(_partido.local, _partido.once_local[0], 12, null)
	if _frame == 25:
		if _partido.once_visita.size() >= 1:
			_partido.gol.emit(_partido.visita, _partido.once_visita[0], 34, null)
	if _frame == 35:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/pantalla_marcador_1_1.png")
		print("captura guardada: pantalla_marcador_1_1.png")
		print("FIN. 0 fallos")
		get_tree().quit()
