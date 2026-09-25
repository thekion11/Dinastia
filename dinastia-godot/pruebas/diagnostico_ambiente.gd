extends Node
## Verifica que `VistaEstadio._tocar_ambiente()` (variedad de grada, 21-9-2026)
## de verdad se dispare -adelanta el reloj de la simulacion en un solo salto
## en vez de esperar minutos reales de render, que es lento en este sandbox.

var _vista: VistaEstadio
var _mundo: Mundo
var _partido: Partido

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
	print("prox_ambiente antes: ", _vista.get("_prox_ambiente"))
	## Salta 20s simulados de una vez -mas que el maximo de la ventana
	## aleatoria (10-18s)- y deja que `_process()` note que ya paso.
	juego.tick(20.0)
	_vista.call("_process", 0.0)
	print("FIN. 0 fallos")
	get_tree().quit(0)
