extends Node
## Aisla si el aliasing de la tribuna (ver LEEME.md 21-9-2026) es un problema
## de la textura en si, o algo ligado al MOVIMIENTO de camara/juego -sin tocar
## nada, solo abrir la vista y capturar apenas esta lista, camara quieta.

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

func _process(_d: float) -> void:
	_frame += 1
	if _frame == 8:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/tribuna_estatica_f8.png")
	if _frame == 90:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/capturas/tribuna_estatica_f90.png")
		print("FIN. 0 fallos")
		get_tree().quit(0)
