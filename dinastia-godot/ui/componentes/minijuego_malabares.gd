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
## MÁS PROFUNDIDAD Y MEJOR ASPECTO (21-10-2026, vídeo de gameplay: «muy básico»).
## La RACHA: toques buenos seguidos multiplican los puntos (×2 desde 5, ×3 desde
## 10, ×4 desde 20); un toque flojo la corta. Se dibuja un estadio de noche de
## fondo, el jugador con la camiseta de tu club levanta el pie al tocar, el
## balón gira con sus gajos y salta un chispazo en cada toque bueno.
var _racha := 0
var _giro := 0.0
var _patada := 0.0
var _chispas: Array[Dictionary] = []
var _t := 0.0
var color_camiseta := Color(0.2, 0.4, 0.85)
var color_pantalon := Color(0.95, 0.95, 0.97)

static func cargar_record() -> void:
	var cf := ConfigFile.new()
	if cf.load(ARCHIVO) == OK:
		record = int(cf.get_value("malabares", "record", 0))

static func mostrar(p: Control, _mundo: Mundo) -> MinijuegoMalabares:
	cargar_record()
	var j := MinijuegoMalabares.new()
	if _mundo != null and _mundo.mi_club() != null:
		j.color_camiseta = Color(_mundo.mi_club().color_escudo1())
		j.color_pantalon = Color(_mundo.mi_club().color_escudo2())
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
	_t += d
	_patada = maxf(_patada - d * 4.0, 0.0)
	for c: Dictionary in _chispas:
		c["v"] = (c["v"] as Vector2) + Vector2(0, 420.0) * d
		c["p"] = (c["p"] as Vector2) + (c["v"] as Vector2) * d
		c["t"] = float(c["t"]) - d
	_chispas = _chispas.filter(func(c: Dictionary) -> bool: return float(c["t"]) > 0.0)
	if _fin:
		queue_redraw()
		return
	_giro += (_vx * 18.0 + 2.0) * d
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
		_aviso(Idiomas.t("¡Muy pronto!") if _y < 0.72 else "", 0.5)
		return
	if absf(_x - _pie) > 0.09:
		_aviso(Idiomas.t("¡Lejos del pie!"), 0.6)
		return
	var precisión := 1.0 - absf(_y - 0.85) / 0.12
	var extra := 0
	if precisión > 0.8:
		extra = 2
		_aviso(Idiomas.t("¡PERFECTO!"), 0.7)
	elif precisión > 0.45:
		extra = 1
		_aviso(Idiomas.t("¡Bien!"), 0.5)
	_racha = _racha + 1 if extra > 0 else 0
	_toques += 1
	_puntos += (1 + extra) * multiplicador()
	_patada = 1.0
	_chispazo(extra)
	_g = 1.1 + float(_toques) * 0.05
	_vy = -sqrt(2.0 * _g * 0.55)
	_vx += (_x - _pie) * 1.5
	Sonido.toca("pase", Sonido.Bus.EFECTOS)

## ×1 hasta 4 toques buenos seguidos, ×2 desde 5, ×3 desde 10, ×4 desde 20.
func multiplicador() -> int:
	return 4 if _racha >= 20 else (3 if _racha >= 10 else (2 if _racha >= 5 else 1))

func _chispazo(extra: int) -> void:
	if size.x <= 0.0:
		return
	var c := Vector2(size.x * lerpf(0.08, 0.92, _x), size.y * lerpf(0.12, 0.9, _y))
	for i in 6 + extra * 5:
		var a := _rng.randf_range(PI * 1.05, PI * 1.95)
		_chispas.append({"p": c, "v": Vector2(cos(a), sin(a)) * _rng.randf_range(120.0, 320.0),
			"t": _rng.randf_range(0.35, 0.7), "c": Color(1, 0.85, 0.3) if extra == 2 else Color(1, 1, 1)})

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
		_msg = Idiomas.t("¡NUEVO RÉCORD!")
	else:
		_msg = Idiomas.t("Se cayó")
	_msg_t = 99.0

func _reiniciar() -> void:
	_fin = false
	_x = 0.5
	_y = 0.3
	_vy = 0.0
	_vx = _rng.randf_range(-0.05, 0.05)
	_toques = 0
	_puntos = 0
	_racha = 0
	_g = 1.1
	_msg_t = 0.0

func _draw() -> void:
	var w := size.x
	var h := size.y
	var suelo := h * 0.93
	## El cielo de noche y la grada iluminada al fondo.
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.55), Vector2(0, h * 0.55)]),
		PackedColorArray([Color(0.02, 0.03, 0.08), Color(0.02, 0.03, 0.08), Color(0.08, 0.1, 0.18), Color(0.08, 0.1, 0.18)]))
	draw_rect(Rect2(0, h * 0.42, w, h * 0.16), Color(0.07, 0.08, 0.11))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 260:
		var gx := rng.randf() * w
		var gy := h * (0.44 + rng.randf() * 0.12)
		var bril := 0.25 + 0.35 * rng.randf() + 0.15 * sin(_t * 2.0 + float(i))
		draw_rect(Rect2(gx, gy, 3, 4), Color(bril, bril * 0.95, bril * 0.9))
	for k in 4:
		var fx := w * (0.12 + 0.25 * float(k))
		draw_rect(Rect2(fx - 2, h * 0.18, 4, h * 0.24), Color(0.25, 0.27, 0.3))
		draw_rect(Rect2(fx - 26, h * 0.15, 52, 12), Color(1, 0.97, 0.85))
		draw_circle(Vector2(fx, h * 0.16), 70.0, Color(1, 0.95, 0.8, 0.05))
	## El césped a franjas, con la línea de cal.
	for k in 8:
		var y0 := h * 0.58 + (suelo - h * 0.58) * float(k) / 8.0
		draw_rect(Rect2(0, y0, w, (suelo - h * 0.58) / 8.0 + 1.0), Color(0.11, 0.36, 0.16) if k % 2 == 0 else Color(0.13, 0.41, 0.18))
	draw_rect(Rect2(0, suelo, w, h - suelo), Color(0.09, 0.3, 0.13))
	draw_rect(Rect2(0, h * 0.62, w, 3), Color(1, 1, 1, 0.55))
	var f := ThemeDB.fallback_font
	draw_rect(Rect2(18, 18, 640, 80), Color(0, 0, 0, 0.45))
	draw_string(f, Vector2(30, 50), Idiomas.t("MALABARES · puntos %d · toques %d · récord %d") % [_puntos, _toques, record], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 0.9, 0.5))
	draw_string(f, Vector2(30, 82), Idiomas.t("A/D o ←/→ para moverte · ESPACIO o clic para tocar · Esc sale"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.8, 0.85, 0.9))
	if multiplicador() > 1:
		draw_string(f, Vector2(w - 260, 60), "×%d" % multiplicador(), HORIZONTAL_ALIGNMENT_RIGHT, 220, 46, Color(1, 0.8, 0.25))
	var bx := w * lerpf(0.08, 0.92, _x)
	var by := h * lerpf(0.12, 0.9, _y)
	var px := w * lerpf(0.08, 0.92, _pie)
	## Sombras en el césped.
	draw_set_transform(Vector2(bx, suelo + 2), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 22.0 * (1.25 - _y * 0.5), Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(px, suelo + 2), 0.0, Vector2(1.0, 0.25))
	draw_circle(Vector2.ZERO, 46.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_dibujar_jugador(px, suelo)
	## El balón, con gajos que giran.
	draw_circle(Vector2(bx, by), 24.0, Color(0.97, 0.97, 0.97))
	for k in 5:
		var a := _giro + TAU * float(k) / 5.0
		draw_circle(Vector2(bx, by) + Vector2(cos(a), sin(a)) * 14.0, 6.0, Color(0.12, 0.12, 0.14))
	draw_circle(Vector2(bx, by), 6.5, Color(0.12, 0.12, 0.14))
	draw_arc(Vector2(bx, by), 24.0, 0.0, TAU, 32, Color(0.25, 0.25, 0.28), 2.0, true)
	draw_arc(Vector2(bx - 6, by - 7), 13.0, PI * 1.1, PI * 1.6, 8, Color(1, 1, 1, 0.8), 3.0, true)
	for c: Dictionary in _chispas:
		var col: Color = c["c"]
		col.a = clampf(float(c["t"]) * 2.0, 0.0, 1.0)
		draw_circle(c["p"], 3.0, col)
	if _msg_t > 0.0 and _msg != "":
		draw_string(f, Vector2(w * 0.5 - 150, h * 0.38), _msg, HORIZONTAL_ALIGNMENT_CENTER, 300, 40, Color(1, 0.95, 0.4))
	if _fin:
		draw_string(f, Vector2(w * 0.5 - 220, h * 0.5), Idiomas.t("Toca ESPACIO para volver a intentarlo"), HORIZONTAL_ALIGNMENT_CENTER, 440, 22, Color(0.9, 0.9, 1))

## El jugador de lado: piernas, pantalón, camiseta del club, brazos y cabeza;
## la pierna derecha sube al tocar (`_patada`).
func _dibujar_jugador(px: float, suelo: float) -> void:
	var piel := Color(0.86, 0.68, 0.52)
	var cadera := Vector2(px, suelo - 92.0)
	var pie_apoyo := Vector2(px - 10.0, suelo)
	var sube := ease(_patada, 0.6)
	var rodilla := cadera + Vector2(18.0 * sube, 46.0 - 26.0 * sube)
	var pie := rodilla + Vector2(14.0 + 10.0 * sube, 44.0 - 30.0 * sube)
	draw_line(cadera, pie_apoyo + Vector2(0, -6), Color(0.92, 0.92, 0.95), 13.0)
	draw_line(cadera, rodilla, Color(0.92, 0.92, 0.95), 13.0)
	draw_line(rodilla, pie, Color(0.92, 0.92, 0.95), 12.0)
	draw_rect(Rect2(pie_apoyo.x - 10, suelo - 8, 24, 8), Color(0.08, 0.08, 0.1))
	draw_rect(Rect2(pie.x - 8, pie.y - 7, 24, 8), Color(0.08, 0.08, 0.1))
	draw_rect(Rect2(px - 20, cadera.y - 10, 40, 26), color_pantalon)
	var torso := Rect2(px - 22, cadera.y - 74, 44, 66)
	draw_rect(torso, color_camiseta)
	draw_rect(Rect2(px - 22, cadera.y - 74, 44, 8), color_camiseta.darkened(0.25))
	var balanceo := sin(_t * 3.0) * 6.0
	draw_line(Vector2(px - 20, cadera.y - 66), Vector2(px - 44, cadera.y - 30 + balanceo), color_camiseta, 11.0)
	draw_line(Vector2(px + 20, cadera.y - 66), Vector2(px + 44, cadera.y - 34 - balanceo), color_camiseta, 11.0)
	draw_circle(Vector2(px - 46, cadera.y - 28 + balanceo), 6.0, piel)
	draw_circle(Vector2(px + 46, cadera.y - 32 - balanceo), 6.0, piel)
	draw_circle(Vector2(px, cadera.y - 96), 20.0, piel)
	draw_arc(Vector2(px, cadera.y - 98), 20.0, PI * 1.05, PI * 1.95, 12, Color(0.15, 0.1, 0.07), 9.0)
