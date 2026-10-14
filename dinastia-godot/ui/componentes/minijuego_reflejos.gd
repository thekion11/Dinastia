class_name MinijuegoReflejos
extends Control
## REFLEJOS DEL PORTERO (14-10-2026): un delantero dispara a uno de tres lados
## (izquierda, centro, derecha; ←/↓/→ o A/S/D). Hay un instante para tirarte
## antes de que el balón llegue, y cada parada lo acorta. 12 disparos; las
## paradas te dan puntos, y el tiempo de reacción también.

const ARCHIVO := "user://minijuegos.cfg"
static var record := 0
const TOTAL := 12

var _lado := -1          ## 0 izq, 1 centro, 2 der; -1 = esperando
var _t := 0.0
var _limite := 0.9
var _espera := 0.8
var _n := 0
var _paradas := 0
var _puntos := 0
var _fin := false
var _msg := ""
var _msg_t := 0.0
var _rng := RandomNumberGenerator.new()

static func cargar_record() -> void:
	var cf := ConfigFile.new()
	if cf.load(ARCHIVO) == OK:
		record = int(cf.get_value("reflejos", "record", 0))

static func mostrar(p: Control, _mundo: Mundo) -> MinijuegoReflejos:
	cargar_record()
	var j := MinijuegoReflejos.new()
	j.set_anchors_preset(Control.PRESET_FULL_RECT)
	j.mouse_filter = Control.MOUSE_FILTER_STOP
	p.add_child(j)
	return j

func _ready() -> void:
	_rng.randomize()

func _process(d: float) -> void:
	_msg_t = maxf(_msg_t - d, 0.0)
	if _fin:
		queue_redraw()
		return
	if _lado < 0:
		_espera -= d
		if _espera <= 0.0:
			_lado = _rng.randi_range(0, 2)
			_t = 0.0
	else:
		_t += d
		if _t >= _limite:
			_resolver(-1)
	queue_redraw()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and (ev as InputEventKey).pressed and not (ev as InputEventKey).echo:
		var k := (ev as InputEventKey).keycode
		if k == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			queue_free()
		elif _fin and (k == KEY_SPACE or k == KEY_ENTER):
			_reiniciar()
		elif k == KEY_LEFT or k == KEY_A:
			_resolver(0)
		elif k == KEY_DOWN or k == KEY_S:
			_resolver(1)
		elif k == KEY_RIGHT or k == KEY_D:
			_resolver(2)

func _resolver(eleccion: int) -> void:
	if _fin or _lado < 0:
		return
	_n += 1
	if eleccion == _lado:
		_paradas += 1
		var rapidez := 1.0 - _t / _limite
		var ganado := 10 + int(rapidez * 10.0)
		_puntos += ganado
		_msg = "¡PARADÓN! +%d" % ganado
		_limite = maxf(_limite * 0.93, 0.32)
		Sonido.toca("paso", Sonido.Bus.EFECTOS)
	else:
		_msg = "¡Gol!" if eleccion >= 0 else "¡Tarde!"
	_msg_t = 0.8
	_lado = -1
	_espera = _rng.randf_range(0.5, 1.2)
	if _n >= TOTAL:
		_fin = true
		if _puntos > record:
			record = _puntos
			var cf := ConfigFile.new()
			cf.load(ARCHIVO)
			cf.set_value("reflejos", "record", record)
			cf.save(ARCHIVO)
			_msg = "¡NUEVO RÉCORD! %d" % _puntos
		_msg_t = 99.0

func _reiniciar() -> void:
	_fin = false
	_n = 0
	_paradas = 0
	_puntos = 0
	_limite = 0.9
	_lado = -1
	_espera = 0.8
	_msg_t = 0.0

func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color(0.04, 0.07, 0.1, 0.97))
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(30, 50), "REFLEJOS · paradas %d/%d · puntos %d · récord %d" % [_paradas, _n, _puntos, record], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.6, 0.9, 1))
	draw_string(f, Vector2(30, 82), "←/A izquierda · ↓/S centro · →/D derecha · Esc sale", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.8, 0.85, 0.9))
	## El arco.
	var ax := w * 0.5
	var ancho := w * 0.6
	draw_rect(Rect2(ax - ancho * 0.5, h * 0.3, ancho, h * 0.4), Color(0.9, 0.9, 0.95, 0.12))
	draw_rect(Rect2(ax - ancho * 0.5, h * 0.3, ancho, 6), Color(0.95, 0.95, 1))
	draw_rect(Rect2(ax - ancho * 0.5, h * 0.3, 6, h * 0.4), Color(0.95, 0.95, 1))
	draw_rect(Rect2(ax + ancho * 0.5 - 6, h * 0.3, 6, h * 0.4), Color(0.95, 0.95, 1))
	for z in 3:
		var cx := ax - ancho * 0.5 + ancho * (float(z) + 0.5) / 3.0
		var activo := _lado == z
		draw_rect(Rect2(cx - ancho / 6.0 + 8, h * 0.3 + 12, ancho / 3.0 - 16, h * 0.4 - 24),
			Color(1, 0.35, 0.2, 0.55) if activo else Color(1, 1, 1, 0.05))
		if activo:
			var r := 12.0 + 40.0 * (_t / _limite)
			draw_circle(Vector2(cx, h * 0.5), r, Color(1, 1, 1, 0.9))
	draw_rect(Rect2(0, h * 0.82, w, h * 0.18), Color(0.1, 0.35, 0.16))
	if _msg_t > 0.0 and _msg != "":
		draw_string(f, Vector2(w * 0.5 - 200, h * 0.2), _msg, HORIZONTAL_ALIGNMENT_CENTER, 400, 36, Color(1, 0.95, 0.4))
	if _fin:
		draw_string(f, Vector2(w * 0.5 - 220, h * 0.9), "ESPACIO para otra tanda", HORIZONTAL_ALIGNMENT_CENTER, 440, 22, Color(0.9, 0.9, 1))
