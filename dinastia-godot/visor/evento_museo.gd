class_name EventoMuseo
extends CanvasLayer
## EL MUSEO CRECE: MINI EVENTO A PANTALLA COMPLETA (12-11-2026, orden 36 del dueño: «museo: planta extra por títulos con mini
## evento»). La primera vez que se entra en la planta 3 («Museo ampliado») sale este cuadro: la fachada del museo con sus dos
## plantas, la tercera que SUBE desde el tejado con un brillo dorado, las copas que caen una a una en sus ventanas y el rótulo
## «¡El museo crece!» con el número de títulos. Dura `DURACION` s; cualquier tecla, botón del mando, clic o toque lo salta.
## Al acabar (o saltarlo) emite `terminado` y se borra; `MuseoAmpliadoAnim` enciende entonces las copas de la sala.
## Todo es 2D dibujado (sin texturas ni nodos 3D): no suma llamadas al 3D ni memoria de texturas.
signal terminado

const DURACION := 4.2
const MAX_COPAS := 12

var titulos := 0
var copas_nuevas := 0
var c1 := Color(0.8, 0.1, 0.1)
var c2 := Color(1, 1, 1)
var _t := 0.0
var _acabado := false
var _dibujo: Control
var _fondo: ColorRect

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fondo = ColorRect.new()
	_fondo.color = Color(0.03, 0.03, 0.05, 0.0)
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fondo)
	_dibujo = Control.new()
	_dibujo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dibujo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dibujo.draw.connect(_pintar)
	add_child(_dibujo)

func _process(d: float) -> void:
	if _acabado:
		return
	_t += d
	_fondo.color.a = clampf(_t / 0.35, 0.0, 1.0) * 0.92 * clampf((DURACION - _t) / 0.4, 0.0, 1.0)
	_dibujo.modulate.a = clampf((DURACION - _t) / 0.4, 0.0, 1.0)
	_dibujo.queue_redraw()
	if _t >= DURACION:
		saltar()

func _input(e: InputEvent) -> void:
	if _acabado or _t < 0.25:   ## un cuarto de segundo de gracia: la tecla con la que se entra en la sala no lo salta
		return
	var pulsa := (e is InputEventKey and (e as InputEventKey).pressed and not (e as InputEventKey).echo) \
		or (e is InputEventMouseButton and (e as InputEventMouseButton).pressed) \
		or (e is InputEventScreenTouch and (e as InputEventScreenTouch).pressed) \
		or (e is InputEventJoypadButton and (e as InputEventJoypadButton).pressed)
	if pulsa:
		get_viewport().set_input_as_handled()
		saltar()

## Termina ya (lo llama también la prueba del banco).
func saltar() -> void:
	if _acabado:
		return
	_acabado = true
	terminado.emit()
	queue_free()

## 0 → 1 entre a y b (suavizado).
static func _tramo(t: float, a: float, b: float) -> float:
	var x := clampf((t - a) / (b - a), 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)

func _pintar() -> void:
	var tam := _dibujo.size
	var esc := minf(tam.x / 1280.0, tam.y / 720.0)
	var cx := tam.x * 0.5
	var suelo := tam.y * 0.86
	var ancho := 560.0 * esc
	var alto_p := 108.0 * esc
	var piedra := Color(0.82, 0.8, 0.74)
	var sombra := Color(0.55, 0.53, 0.5)
	var vidrio := Color(0.16, 0.2, 0.28)
	var oro := Color(1.0, 0.82, 0.35)
	_dibujo.draw_rect(Rect2(0, suelo, tam.x, tam.y - suelo), Color(0.1, 0.1, 0.12))
	## Las dos plantas de siempre.
	for k in 2:
		var y := suelo - alto_p * float(k + 1)
		_dibujo.draw_rect(Rect2(cx - ancho * 0.5, y, ancho, alto_p), piedra)
		_dibujo.draw_rect(Rect2(cx - ancho * 0.5, y + alto_p - 6.0 * esc, ancho, 6.0 * esc), sombra)
		for v in 5:
			_dibujo.draw_rect(Rect2(cx - ancho * 0.5 + ancho * (float(v) + 0.2) / 5.0, y + alto_p * 0.22, ancho * 0.12, alto_p * 0.5), vidrio)
	## La franja con los colores del club sobre la puerta.
	_dibujo.draw_rect(Rect2(cx - ancho * 0.5, suelo - alto_p * 0.16, ancho, alto_p * 0.08), c1)
	_dibujo.draw_rect(Rect2(cx - ancho * 0.5, suelo - alto_p * 0.08, ancho, alto_p * 0.04), c2)
	## La planta nueva sube desde el tejado (0,3 → 1,6 s) con andamio dorado y luego brilla.
	var sube := _tramo(_t, 0.3, 1.6)
	var y3 := suelo - alto_p * 2.0 - alto_p * sube
	if sube > 0.0:
		var brillo := _tramo(_t, 1.5, 1.9) * (1.0 - _tramo(_t, 2.4, 3.2))
		_dibujo.draw_rect(Rect2(cx - ancho * 0.5 - 14.0 * esc, y3 - 14.0 * esc, ancho + 28.0 * esc, alto_p * sube + 14.0 * esc), Color(oro, 0.35 * brillo))
		_dibujo.draw_rect(Rect2(cx - ancho * 0.5, y3, ancho, alto_p * sube), piedra.lerp(oro, 0.25))
		var n := clampi(copas_nuevas, 1, MAX_COPAS)
		for i in n:
			## Cada copa cae en su ventana, una tras otra (1,6 → 3,0 s).
			var t0 := 1.6 + 1.4 * float(i) / float(n)
			var caida := _tramo(_t, t0, t0 + 0.25)
			if caida <= 0.0:
				continue
			var px := cx - ancho * 0.5 + ancho * (float(i) + 0.5) / float(n)
			var py := y3 + alto_p * 0.72 - (1.0 - caida) * 60.0 * esc
			_copa(Vector2(px, py), minf(26.0, 300.0 / float(n)) * esc, Color(oro, caida))
	## Tejado.
	var yt := minf(y3, suelo - alto_p * 2.0)
	_dibujo.draw_colored_polygon(PackedVector2Array([Vector2(cx - ancho * 0.56, yt), Vector2(cx + ancho * 0.56, yt), Vector2(cx, yt - 70.0 * esc)]), sombra)
	## Rótulos.
	var fuente := ThemeDB.fallback_font
	var a := _tramo(_t, 1.6, 2.0)
	var t1 := Idiomas.t("¡EL MUSEO CRECE!")
	var t2 := Idiomas.t("Museo ampliado · %d títulos") % titulos
	var t3 := Idiomas.t("Pulsa cualquier botón o toca la pantalla para saltar")
	_texto(fuente, t1, Vector2(cx, tam.y * 0.13), int(64 * esc), Color(oro, a))
	_texto(fuente, t2, Vector2(cx, tam.y * 0.13 + 58.0 * esc), int(30 * esc), Color(1, 1, 1, a))
	_texto(fuente, t3, Vector2(cx, tam.y * 0.95), int(20 * esc), Color(0.75, 0.75, 0.75, 0.9))

func _texto(f: Font, s: String, centro: Vector2, tam_f: int, col: Color) -> void:
	tam_f = maxi(tam_f, 12)
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_f).x
	_dibujo.draw_string_outline(f, Vector2(centro.x - w * 0.5, centro.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_f, maxi(2, tam_f / 10), Color(0, 0, 0, col.a))
	_dibujo.draw_string(f, Vector2(centro.x - w * 0.5, centro.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_f, col)

## Una copa sencilla: cuenco, asas, pie y peana.
func _copa(p: Vector2, r: float, col: Color) -> void:
	_dibujo.draw_circle(p + Vector2(0, -r * 1.1), r * 0.62, col)
	_dibujo.draw_rect(Rect2(p.x - r * 0.62, p.y - r * 1.75, r * 1.24, r * 0.65), col)
	_dibujo.draw_arc(p + Vector2(-r * 0.66, -r * 1.35), r * 0.28, PI * 0.5, PI * 1.5, 8, col, maxf(1.5, r * 0.12))
	_dibujo.draw_arc(p + Vector2(r * 0.66, -r * 1.35), r * 0.28, -PI * 0.5, PI * 0.5, 8, col, maxf(1.5, r * 0.12))
	_dibujo.draw_rect(Rect2(p.x - r * 0.1, p.y - r * 0.55, r * 0.2, r * 0.4), col)
	_dibujo.draw_rect(Rect2(p.x - r * 0.45, p.y - r * 0.18, r * 0.9, r * 0.2), col.darkened(0.3))
