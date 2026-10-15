extends Node
## Malabares y Reflejos: se crean, avanzan y puntúan (14-10-2026).
var _fallos := 0

func _ok(cond: bool, t: String) -> void:
	print(("  ok  " if cond else "  FALLO ") + t)
	if not cond:
		_fallos += 1

func _ready() -> void:
	var raiz := Control.new()
	add_child(raiz)
	var m := MinijuegoMalabares.mostrar(raiz, null)
	await get_tree().process_frame
	## Se coloca el balón a la altura del pie y encima: el toque debe puntuar.
	m._y = 0.85
	m._x = m._pie
	m._tocar()
	_ok(m._puntos >= 1, "malabares: un toque a tiempo puntúa (%d)" % m._puntos)
	_ok(m._vy < 0.0, "malabares: el balón sube tras el toque")
	m._y = 0.3
	m._tocar()
	_ok(m._puntos < 10, "malabares: un toque con el balón arriba no puntúa de más")
	m._y = 0.99
	m._process(0.016)
	_ok(m._fin, "malabares: el balón al suelo termina la partida")
	var r := MinijuegoReflejos.mostrar(raiz, null)
	await get_tree().process_frame
	r._lado = 2
	r._t = 0.1
	r._resolver(2)
	_ok(r._paradas == 1 and r._puntos > 10, "reflejos: acertar el lado para (%d pts)" % r._puntos)
	r._lado = 0
	r._resolver(1)
	_ok(r._paradas == 1, "reflejos: el lado equivocado no para")
	for i in 12:
		r._lado = 1
		r._resolver(-1)
	_ok(r._fin, "reflejos: tras 12 disparos termina")
	print("===== FIN MINIJUEGOS NUEVOS. %d fallos =====" % _fallos)
	get_tree().quit()
