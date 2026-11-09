extends Node
## (9-11) El prólogo animado: sale en una partida con el prólogo pendiente (ciudad apagada), tiene 6 planos, un tramo de la barra de arriba salta de plano, el stick lo
## salta entero, y al terminar la partida queda con el prólogo visto. Necesita pantalla: xvfb-run -a godot --path . --rendering-driver opengl3 …
var _n := 0
var _p: Node
var _fase := 0
var _fallos := 0

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _v() -> PrologoAnimado:
	for h in _p.get_children():
		if h is PrologoAnimado:
			return h
	return null

func _ok(c: bool, t: String) -> void:
	print(("  ok    " if c else "  FALLO ") + t)
	if not c:
		_fallos += 1

func _process(_d: float) -> void:
	_n += 1
	if _n == 12 and _fase == 0:
		_p.mundo.prologo_pendiente = true
		_p.mundo.prologo_visto = false
		_p._refrescar()   ## lo lanza al refrescar (una sola vez)
		_fase = 1
	elif _fase == 1 and _n > 30:
		var v := _v()
		_ok(v != null, "el prólogo animado sale al empezar con el prólogo pendiente")
		if v == null:
			print("FIN. ", _fallos, " fallos"); get_tree().quit(); return
		_ok(PrologoAnimado.PLANOS.size() == 6 and v._segmentos.size() == 6, "seis planos y seis tramos en la barra de arriba")
		_ok(v._raiz.get_global_rect().size.is_equal_approx(get_viewport().get_visible_rect().size), "ocupa toda la pantalla")
		v._segmentos[3].pressed.emit()   ## tocar el tramo 4
		_ok(v._i == 3, "tocar un tramo de la barra salta a ese plano (plano %d)" % (v._i + 1))
		_fase = 2
		_n = 40
	elif _fase == 2 and _n > 70:
		var v2 := _v()
		var ev := InputEventJoypadMotion.new()
		ev.axis = JOY_AXIS_LEFT_X
		ev.axis_value = 0.95
		v2._vivo = 5.0   ## pasado el margen inicial
		v2._input(ev)
		_ok(v2._acabado, "mover el stick lo salta entero")
		_fase = 3
		_n = 80
	elif _fase == 3 and _n > 110:
		_ok(_p.mundo.prologo_visto and not _p.mundo.prologo_pendiente, "al terminar, la partida queda con el prólogo visto")
		_ok(_v() == null, "y la animación se retira de la pantalla")
		print("FIN. ", _fallos, " fallos")
		get_tree().quit()
