extends Node
## Verificación del evento "Lobby institucional con árbitros" (26-9-2026,
## cierra el punto del ROADMAP "confirmado que no existe (14-9)"). Sin
## interfaz nueva a propósito: usa el mismo pool genérico de `Prensa` que ya
## pinta `Principal._pintar_decision()` -por eso esta prueba abre
## `principal.tscn` de verdad (un `Mundo` armado a mano se queda con `prensa`/
## `roles` sin inicializar) y va directo al motor (`Prensa._pool()`/
## `resolver()`), sin necesitar tocar ningún botón nuevo.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_verificar_lobby_arbitral.tscn

const ESPERA := 10

var _pantalla: Node
var _mundo: Mundo
var _mio: Club
var _fallos := 0
var _n := 0

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _mal(txt: String) -> void:
	print("MAL: " + txt)
	_fallos += 1

func _process(_d: float) -> void:
	_n += 1
	if _n != ESPERA:
		return

	_mundo = _pantalla.get("mundo")
	_mio = _mundo.mi_club()

	## 1) Sin enojo acumulado, el evento no debe salir en el pool -es lo que lo
	## distingue de "reclamo", que sale siempre que hay algo pendiente.
	_mundo.federacion.enojo_arbitral = 0
	if _tiene_evento(_mundo.prensa._pool(_mundo, _mio)):
		_mal("el evento aparece en el pool SIN enojo_arbitral acumulado")
	else:
		print("OK: sin enojo acumulado, el evento no está en el pool")

	## 2) Con enojo acumulado, tiene que aparecer.
	_mundo.federacion.enojo_arbitral = 3
	var pool := _mundo.prensa._pool(_mundo, _mio)
	var evento := _buscar_evento(pool)
	if evento.is_empty():
		_mal("el evento NO aparece en el pool con enojo_arbitral = 3")
		print("FIN. %d fallos" % _fallos)
		get_tree().quit(_fallos)
		return
	print("OK: con enojo acumulado (3), el evento aparece: %s" % String(evento["txt"]).left(60))

	## 3) Resolver "asistir" (a): debe bajar el enojo Y cobrar dinero, siempre.
	_mundo.prensa.pendiente = evento
	var saldo_antes := _mio.saldo
	var r := _mundo.prensa.resolver("a")
	if _mundo.federacion.enojo_arbitral != 2:
		_mal("asistir no bajó enojo_arbitral de 3 a 2 (quedó en %d)" % _mundo.federacion.enojo_arbitral)
	else:
		print("OK: asistir bajó Federacion.enojo_arbitral de 3 a 2")
	if _mio.saldo >= saldo_antes:
		_mal("asistir no le costó plata al club (saldo %d -> %d)" % [saldo_antes, _mio.saldo])
	else:
		print("OK: asistir costó plata de verdad (saldo %d -> %d)" % [saldo_antes, _mio.saldo])
	print("resultado 'asistir': %s — %s" % [r.get("titulo"), r.get("cuerpo")])

	## 4) Resolver "declinar" (b) con enojo de nuevo en 3: no debe tocar nada.
	_mundo.federacion.enojo_arbitral = 3
	_mundo.prensa.pendiente = evento
	var saldo_antes2 := _mio.saldo
	var r2 := _mundo.prensa.resolver("b")
	if _mundo.federacion.enojo_arbitral != 3:
		_mal("declinar cambió enojo_arbitral (debía quedar en 3, quedó en %d)" % _mundo.federacion.enojo_arbitral)
	else:
		print("OK: declinar no cambió Federacion.enojo_arbitral")
	if _mio.saldo != saldo_antes2:
		_mal("declinar le costó o dio plata al club, no debería")
	else:
		print("OK: declinar no movió la caja")
	print("resultado 'declinar': %s — %s" % [r2.get("titulo"), r2.get("cuerpo")])

	print("FIN. %d fallos" % _fallos)
	get_tree().quit(_fallos)

func _tiene_evento(pool: Array) -> bool:
	return not _buscar_evento(pool).is_empty()

func _buscar_evento(pool: Array) -> Dictionary:
	for e: Dictionary in pool:
		if String(e["id"]) == "lobby_arbitral":
			return e
	return {}
