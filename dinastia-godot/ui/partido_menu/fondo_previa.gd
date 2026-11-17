class_name FondoPrevia
extends Control
## EL FONDO DE LA PREVIA DEL PARTIDO (17-11-2026, referencia del dueño: la previa del PES 2020). Un tono hondo y saturado que mezcla los dos clubes
## (el local tiñe la izquierda, el visitante la derecha, como la maqueta), y encima las CINTAS curvas de luz que barren la pantalla en diagonal (el
## «swoosh» del PES): bandas brillantes que se desvanecen en sus puntas, con un filo más claro. Debajo, las franjas inclinadas de la maqueta, muy
## suaves, y una viñeta. Las cintas ondulan muy despacio (quietas si las animaciones están reducidas).

var color := Color("c8102e")     ## local
var color_b := Color("1f8a4c")   ## visitante
var _t := 0.0

const BASE := Color("2a0e4a")    ## el morado hondo de fondo (el del PES), al que se acercan los colores de los clubes

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	set_process(not Animar.reducidas())

func _process(delta: float) -> void:
	_t += delta
	if Engine.get_process_frames() % 2 == 0:
		queue_redraw()

## El color de un club llevado a un tono de fondo: más oscuro y hacia el morado, pero reconocible.
static func tono(c: Color) -> Color:
	var t := c.lerp(BASE, 0.5).darkened(0.3)
	t.s = clampf(t.s * 1.15, 0.0, 1.0)
	return t

## Un color de cinta: el del club, encendido y algo hacia el magenta.
static func cinta(c: Color) -> Color:
	var t := c.lerp(Color("e0309a"), 0.35).lightened(0.25)
	t.s = clampf(t.s * 1.2, 0.0, 1.0)
	return t

func _draw() -> void:
	var s := size
	var a := tono(color)
	var b := tono(color_b)
	var medio := a.lerp(b, 0.5).darkened(0.25)
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(s.x * 0.5, 0), Vector2(s.x * 0.5, s.y), Vector2(0, s.y)]), PackedColorArray([a, medio, medio, a.darkened(0.2)]))
	draw_polygon(PackedVector2Array([Vector2(s.x * 0.5, 0), Vector2(s.x, 0), s, Vector2(s.x * 0.5, s.y)]), PackedColorArray([medio, b, b.darkened(0.2), medio]))
	## Las franjas finas de la maqueta, casi invisibles.
	var inclina := s.y * 0.4663
	var x := -inclina
	var fr := Color(1, 1, 1, 0.035)
	while x < s.x + 30.0:
		draw_polygon(PackedVector2Array([Vector2(x + inclina, 0), Vector2(x + inclina + 30.0, 0), Vector2(x + 30.0, s.y), Vector2(x, s.y)]), PackedColorArray([fr, fr, fr, fr]))
		x += 90.0
	var o := sin(_t * 0.35) * 0.012
	var ca := cinta(color)
	var cb := cinta(color_b)
	## Abajo a la izquierda, dos cintas que suben hacia el centro (el local).
	_cinta(s, [Vector2(-0.05, 0.98), Vector2(0.18, 0.78 + o), Vector2(0.32, 0.92), Vector2(0.55, 0.62 - o)], 0.085, ca, 0.8)
	_cinta(s, [Vector2(-0.05, 0.86), Vector2(0.12, 0.7 - o), Vector2(0.3, 0.8), Vector2(0.46, 0.55 + o)], 0.03, ca.lightened(0.2), 0.4)
	## Arriba a la izquierda, una que baja.
	_cinta(s, [Vector2(-0.02, 0.06), Vector2(0.14, 0.2 + o), Vector2(0.2, -0.02), Vector2(0.4, 0.02)], 0.06, ca, 0.6)
	## A la derecha, las del visitante: una grande que cae de arriba y otra abajo.
	_cinta(s, [Vector2(1.05, 0.04), Vector2(0.86, 0.24 - o), Vector2(0.74, 0.12), Vector2(0.5, 0.4 + o)], 0.085, cb, 0.8)
	_cinta(s, [Vector2(1.05, 0.62), Vector2(0.9, 0.78 + o), Vector2(0.84, 0.98), Vector2(0.66, 1.04)], 0.07, cb, 0.75)
	_cinta(s, [Vector2(1.05, 0.72), Vector2(0.94, 0.86 - o), Vector2(0.9, 1.0), Vector2(0.78, 1.06)], 0.022, cb.lightened(0.25), 0.4)
	## La sombra del centro (detrás de los nombres) y la viñeta.
	draw_texture_rect(FondoCine._vineta_tex(), Rect2(Vector2.ZERO, s), false)

## Una cinta: una curva de Bézier (4 puntos en fracciones de pantalla) con su grosor; brilla en el medio y se apaga en las puntas,
## con un filo claro en el borde de arriba.
func _cinta(s: Vector2, p: Array, grosor: float, c: Color, alfa: float) -> void:
	var n := 28
	var arriba := PackedVector2Array()
	var abajo := PackedVector2Array()
	var cols_a := PackedColorArray()
	for i in n + 1:
		var t := float(i) / n
		var q := _bezier(p, t) * s
		var q2 := _bezier(p, minf(t + 0.01, 1.0)) * s - _bezier(p, maxf(t - 0.01, 0.0)) * s
		var normal := Vector2(-q2.y, q2.x).normalized()
		var g := grosor * s.y * (0.35 + 0.65 * sin(t * PI))
		arriba.append(q + normal * g * 0.5)
		abajo.append(q - normal * g * 0.5)
		cols_a.append(Color(c, alfa * pow(sin(t * PI), 0.7)))
	## Por tramos (cuadriláteros): un polígono entero se rompe si la curva se dobla.
	for i in n:
		var ci := Color(cols_a[i].darkened(0.35), cols_a[i].a * 0.55)
		var cj := Color(cols_a[i + 1].darkened(0.35), cols_a[i + 1].a * 0.55)
		draw_primitive(PackedVector2Array([arriba[i], arriba[i + 1], abajo[i + 1], abajo[i]]), PackedColorArray([cols_a[i], cols_a[i + 1], cj, ci]), PackedVector2Array())
	var filo := PackedColorArray()
	for i in n + 1:
		filo.append(Color(Color.WHITE, cols_a[i].a * 0.45))
	draw_polyline_colors(arriba, filo, maxf(1.5, s.y * 0.0018), true)

static func _bezier(p: Array, t: float) -> Vector2:
	var u := 1.0 - t
	return (p[0] as Vector2) * u * u * u + (p[1] as Vector2) * 3.0 * u * u * t + (p[2] as Vector2) * 3.0 * u * t * t + (p[3] as Vector2) * t * t * t
