class_name MinijuegoMalabares
extends Control
## MALABARES (14-10-2026, «más juegos dentro del juego»): mantén el balón en el
## aire. El balón cae y deriva con el viento; muévete con A/D o ←/→ para
## ponerte debajo y toca ESPACIO (o clic) cuando esté a la altura del pie: cuanto
## más justo, más puntos. Cada toque acelera un poco la caída. Falla y se acaba.

const ARCHIVO := "user://minijuegos.cfg"
static var record := 0

var _x := 0.5            ## posición del balón (0..1)
var _y := 0.3            ## altura del balón (0 arriba, 1 suelo)
var _vy := 0.0
var _vx := 0.0
var _pie := 0.5
var _toques := 0
var _puntos := 0
var _g := 1.1
var _fin := false
var _msg := ""
var _msg_t := 0.0
var _rng := RandomNumberGenerator.new()

static func cargar_record() -> void:
	var cf := ConfigFile.new()
	if cf.load(ARCHIVO) == OK:
		record = int(cf.get_value("malabares", "record", 0))

static func mostrar(p: Control, _mundo: Mundo) -> MinijuegoMalabares:
	cargar_record()
	var j := MinijuegoMalabares.new()
	j.set_anchors_preset(Control.PRESET_FULL_RECT)
	j.mouse_filter = Control.MOUSE_FILTER_STOP
	p.add_child(j)
	return j

func _ready() -> void:
	_rng.randomize()
	focus_mode = Control.FOCUS_ALL
	grab_focus()
	_vx = _rng.randf_range(-0.05, 0.05)

func _process(d: float) -> void:
	if _fin:
		queue_redraw()
		return
	_msg_t = maxf(_msg_t - d, 0.0)
	var dir := Input.get_axis("ui_left", "ui_right")
	if Input.is_physical_key_pressed(KEY_A):
		dir -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		dir += 1.0
	_pie = clampf(_pie + clampf(dir, -1.0, 1.0) * d * 0.9, 0.05, 0.95)
	_vy += _g * d
	_y += _vy * d
	_x += _vx * d
	_vx += _rng.randf_range(-0.12, 0.12) * d * (1.0 + float(_toques) * 0.04)
	if _x < 0.05 or _x > 0.95:
		_vx = -_vx
		_x = clampf(_x, 0.05, 0.95)
	if _y >= 0.97:
		_terminar()
	queue_redraw()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and (ev as InputEventKey).pressed and not (ev as InputEventKey).echo:
		var k := (ev as InputEventKey).keycode
		if k == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			queue_free()
		elif k == KEY_SPACE or k == KEY_ENTER:
			get_viewport().set_input_as_handled()
			_tocar()
	elif ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
		_tocar()

func _tocar() -> void:
	if _fin:
		_reiniciar()
		return
	## El pie alcanza si el balón está bajo (0,72–0,95) y encima.
	if _y < 0.72 or _y > 0.96:
		_aviso("¡Muy pronto!" if _y < 0.72 else "", 0.5)
		return
	if absf(_x - _pie) > 0.09:
		_aviso("¡Lejos del pie!", 0.6)
		return
	var precisión := 1.0 - absf(_y - 0.85) / 0.12
	var extra := 0
	if precisión > 0.8:
		extra = 2
		_aviso("¡PERFECTO!", 0.7)
	elif precisión > 0.45:
		extra = 1
		_aviso("¡Bien!", 0.5)
	_toques += 1
	_puntos += 1 + extra
	_g = 1.1 + float(_toques) * 0.05
	_vy = -sqrt(2.0 * _g * 0.55)
	_vx += (_x - _pie) * 1.5
	Sonido.toca("pase", Sonido.Bus.EFECTOS)

func _aviso(t: String, s: float) -> void:
	_msg = t
	_msg_t = s

func _terminar() -> void:
	_fin = true
	if _puntos > record:
		record = _puntos
		var cf := ConfigFile.new()
		cf.load(ARCHIVO)
		cf.set_value("malabares", "record", record)
		cf.save(ARCHIVO)
		_msg = "¡NUEVO RÉCORD!"
	else:
		_msg = "Se cayó"
	_msg_t = 99.0

func _reiniciar() -> void:
	_fin = false
	_x = 0.5
	_y = 0.3
	_vy = 0.0
	_vx = _rng.randf_range(-0.05, 0.05)
	_toques = 0
	_puntos = 0
	_g = 1.1
	_msg_t = 0.0

func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color(0.05, 0.1, 0.07, 0.97))
	draw_rect(Rect2(0, h * 0.93, w, h * 0.07), Color(0.12, 0.38, 0.17))
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(30, 50), "MALABARES · puntos %d · toques %d · récord %d" % [_puntos, _toques, record], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 0.9, 0.5))
	draw_string(f, Vector2(30, 82), "A/D o ←/→ para moverte · ESPACIO o clic para tocar · Esc sale", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.8, 0.85, 0.9))
	var bx := w * lerpf(0.08, 0.92, _x)
	var by := h * lerpf(0.12, 0.9, _y)
	var px := w * lerpf(0.08, 0.92, _pie)
	draw_circle(Vector2(bx, h * 0.935), 14.0 * (1.2 - _y * 0.5), Color(0, 0, 0, 0.35))
	## El jugador: una silueta simple con el pie extendido.
	draw_circle(Vector2(px, h * 0.8), 22.0, Color(0.95, 0.8, 0.65))
	draw_rect(Rect2(px - 22, h * 0.8 + 22, 44, 70), Color(0.2, 0.4, 0.85))
	draw_rect(Rect2(px - 6, h * 0.8 + 92, 12, h * 0.93 - (h * 0.8 + 92)), Color(0.9, 0.9, 0.95))
	draw_circle(Vector2(px, h * 0.93), 9.0, Color(0.12, 0.12, 0.14))
	## El balón.
	draw_circle(Vector2(bx, by), 24.0, Color(0.97, 0.97, 0.97))
	draw_arc(Vector2(bx, by), 24.0, 0.0, TAU, 28, Color(0.1, 0.1, 0.1), 3.0, true)
	draw_circle(Vector2(bx, by), 8.0, Color(0.12, 0.12, 0.12))
	if _msg_t > 0.0 and _msg != "":
		draw_string(f, Vector2(w * 0.5 - 150, h * 0.38), _msg, HORIZONTAL_ALIGNMENT_CENTER, 300, 40, Color(1, 0.95, 0.4))
	if _fin:
		draw_string(f, Vector2(w * 0.5 - 220, h * 0.5), "Toca ESPACIO para volver a intentarlo", HORIZONTAL_ALIGNMENT_CENTER, 440, 22, Color(0.9, 0.9, 1))
