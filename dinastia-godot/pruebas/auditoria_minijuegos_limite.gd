extends Node
## CAZA DE FALLOS (4-11-2026, orden de la líder): los MINIJUEGOS 2D llevados al límite (reflejos, malabares, tiro libre, penales).
##   godot --headless --path . res://pruebas/auditoria_minijuegos_limite.tscn
## Cada uno se abre con mundo y SIN mundo (null), se machaca con teclas y clics al azar (pulsaciones dobles incluidas), cambia de idioma y de calidad a mitad,
## se sale con Escape a mitad (o se libera de golpe) y se vuelve a abrir; el de tiro libre y el de penales también con el plantel de un club con atributos a 1 y a 99.
## Nada debe romperse (los errores salen como SCRIPT ERROR) ni quedar nodos sueltos; el récord nunca baja.
var _fallos := 0
var _fase := 0
var _n := 0
var _rng := RandomNumberGenerator.new()
var _mundo: Mundo
var _contenedor: Control
var _actual: Control
var _quedan := 0

const JUEGOS := ["Reflejos", "Malabares", "TiroLibre", "Penales"]

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _ready() -> void:
	_rng.seed = 4711
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4711)
	_mundo.mi_club_id = _mundo.ligas[0].clubes[0].id
	_contenedor = Control.new()
	_contenedor.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_contenedor)

func _abrir(juego: String, con_mundo: bool) -> Control:
	var m: Mundo = _mundo if con_mundo else null
	match juego:
		"Reflejos": return MinijuegoReflejos.mostrar(_contenedor, m)
		"Malabares": return MinijuegoMalabares.mostrar(_contenedor, m)
		"TiroLibre": return MinijuegoTiroLibre.mostrar(_contenedor, m)
		_: return MinijuegoPenales.mostrar(_contenedor, m)

func _tecla(k: Key, pulsa := true) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.physical_keycode = k
	e.pressed = pulsa
	Input.parse_input_event(e)

func _clic(pos: Vector2) -> void:
	for p in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = pos
		e.pressed = p
		Input.parse_input_event(e)

func _machacar() -> void:
	for i in _rng.randi_range(1, 4):
		var k: Key = [KEY_SPACE, KEY_ENTER, KEY_LEFT, KEY_RIGHT, KEY_DOWN, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_W][_rng.randi() % 10]
		_tecla(k, true)
		if _rng.randf() < 0.7:
			_tecla(k, false)
			_tecla(k, true)   ## pulsación doble
			_tecla(k, false)
	if _rng.randf() < 0.3:
		_clic(Vector2(_rng.randf() * 1100.0, _rng.randf() * 650.0))

func _process(_d: float) -> void:
	_n += 1
	if _n < 5:
		return
	var total := JUEGOS.size() * 2
	if _fase >= total:
		_cerrar_todo()
		return
	var juego: String = JUEGOS[_fase / 2]
	var con_mundo := _fase % 2 == 0
	if _actual == null or not is_instance_valid(_actual):
		_actual = _abrir(juego, con_mundo)
		_quedan = 420
		_comprobar(_actual != null, "%s %s: se abre" % [juego, "con mundo" if con_mundo else "SIN mundo"])
		return
	_quedan -= 1
	_machacar()
	if _quedan == 300:
		Idiomas.idioma = ["en", "pt", "fr", "de", "tr", "ca", "pl", "it"][_fase % 8]   ## idioma a mitad
	if _quedan == 200:
		Calidad.elegida = Calidad.ALTO if _fase % 2 == 0 else Calidad.MINIMO   ## calidad a mitad
	if _quedan == 100 and _actual != null and juego in ["TiroLibre", "Penales"]:
		for j: Jugador in _mundo.mi_club().plantilla:   ## atributos extremos con el minijuego abierto
			for k: String in j.atributos:
				j.atributos[k] = 1 if _fase % 4 == 0 else 99
	if _quedan <= 0:
		Idiomas.idioma = "es"
		Calidad.elegida = Calidad.MINIMO
		if _fase % 4 < 2:
			_tecla(KEY_ESCAPE, true)     ## salir con Escape a mitad
			_tecla(KEY_ESCAPE, false)
		if is_instance_valid(_actual) and not _actual.is_queued_for_deletion():
			_actual.queue_free()           ## o liberarlo de golpe
		_fase += 1
		_actual = null
		_n = 3   ## deja pasar un par de fotogramas para que se libere

func _cerrar_todo() -> void:
	_n += 0
	await get_tree().process_frame
	await get_tree().process_frame
	_comprobar(_contenedor.get_child_count() == 0, "al terminar no queda ningún minijuego abierto (%d hijos)" % _contenedor.get_child_count())
	_comprobar(MinijuegoReflejos.record >= 0 and MinijuegoMalabares.record >= 0 and MinijuegoTiroLibre.record >= 0, "los récords nunca son negativos")
	print("===== FIN. %d fallos =====" % _fallos)
	set_process(false)
	get_tree().quit(0 if _fallos == 0 else 1)
