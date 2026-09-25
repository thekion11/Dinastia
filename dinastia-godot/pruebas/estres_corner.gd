extends Node
## Partido natural, sin forzar nada, corrido varios minutos simulados para
## que ocurran disparos reales -y con ellos, corners reales- y confirmar que
## nada revienta a lo largo de muchos eventos seguidos.

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
	## x4 para que pasen muchos minutos simulados rapido, mas eventos por
	## segundo real de prueba.
	juego.vel_idx = 3

func _process(_d: float) -> void:
	_frame += 1
	if _frame >= 3600:
		print("FIN. 0 fallos")
		get_tree().quit(0)
