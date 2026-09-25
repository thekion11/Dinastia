extends Node
## Partido natural, sin forzar nada, para confirmar que el tiro libre se
## dispara solo en un partido real -misma disciplina que ya atrapo el bug del
## corner que nunca se disparaba solo.

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
	var juego = _vista.get("_juego")
	juego.vel_idx = 3

func _process(_d: float) -> void:
	_frame += 1
	if _frame >= 3600:
		print("FIN. 0 fallos")
		get_tree().quit(0)
