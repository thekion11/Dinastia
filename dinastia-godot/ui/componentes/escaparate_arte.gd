class_name EscaparateArte
extends Control
## LAS ILUSTRACIONES DE LAS TARJETAS DE «DIRECCIÓN DEL EQUIPO» E «INFORMACIÓN DEL CLUB» (17-11-2026, cuarta ronda): una imagen RECONOCIBLE por tarjeta (camilla y botiquín, taquillas con camisetas,
## pizarra con la formación, escritorio con contratos, conos y balones, el once en el campo…), dibujada con formas planas en los COLORES DEL CLUB sobre un fondo oscuro con luz: sin
## archivos (0 KB), nítida a cualquier tamaño y distinta en cada club. Se dibuja en una caja virtual de 160×100 centrada en el tercio alto de la tarjeta; el texto va debajo.
## Las que no son de equipo (cuentas, patrocinadores, hinchada…) están en `EscaparateArte2` (mismas piezas).

const PIEL := [Color("e8b894"), Color("c68b62"), Color("8d5a3c"), Color("f1cfae")]
const MADERA := Color("9b6b3f")

var tipo := ""
var c1 := Color("c8102e")
var c2 := Color.WHITE
var formacion := "4-3-3"
var numeros: Array = []

## Pone la ilustración `tipo` como fondo (hijo 0) de la tarjeta `b`, con los colores del club `c`.
static func poner(b: Control, tipo_: String, c: Club) -> EscaparateArte:
	var a := EscaparateArte.new()
	a.tipo = tipo_
	a.c1 = EscaparateBarra.color_de(c)
	a.c2 = Color(c.color2)
	a.formacion = c.tactica.formacion
	for j: Jugador in c.plantilla.slice(0, 11):
		a.numeros.append(maxi(j.dorsal, 1))
	a.set_anchors_preset(Control.PRESET_FULL_RECT)
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(a)
	b.move_child(a, 0)
	return a

func _r(x: float, y: float, w: float, h: float, col: Color) -> void:
	draw_rect(Rect2(x, y, w, h), col)

func _o(x: float, y: float, r: float, col: Color) -> void:
	draw_circle(Vector2(x, y), r, col)

func _p(pts: Array, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array(pts), col)

func _l(x1: float, y1: float, x2: float, y2: float, col: Color, w := 1.0) -> void:
	draw_line(Vector2(x1, y1), Vector2(x2, y2), col, w, true)

func _t(x: float, y: float, s: String, tam: int, col: Color) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(x, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, col)

## Una persona de pecho para arriba: cabeza, cuello y hombros con la camiseta `ropa`.
func _pers(x: float, y: float, esc: float, ropa: Color, piel: Color) -> void:
	_r(x - 3.0 * esc, y + 6.0 * esc, 6.0 * esc, 5.0 * esc, piel)
	_p([Vector2(x - 14.0 * esc, y + 30.0 * esc), Vector2(x - 12.0 * esc, y + 12.0 * esc), Vector2(x - 4.0 * esc, y + 9.0 * esc), Vector2(x + 4.0 * esc, y + 9.0 * esc),
		Vector2(x + 12.0 * esc, y + 12.0 * esc), Vector2(x + 14.0 * esc, y + 30.0 * esc)], ropa)
	_o(x, y, 7.0 * esc, piel)

func _draw() -> void:
	var k := minf(size.x / 160.0, size.y * 0.74 / 100.0)
	var fondo := c1.darkened(0.7)
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size]), PackedColorArray([fondo.lightened(0.18), fondo.lightened(0.18), fondo.darkened(0.2)]))
	draw_polygon(PackedVector2Array([Vector2.ZERO, size, Vector2(0, size.y)]), PackedColorArray([fondo.lightened(0.18), fondo.darkened(0.2), fondo.darkened(0.45)]))
	draw_set_transform(Vector2((size.x - 160.0 * k) * 0.5, size.y * 0.05), 0.0, Vector2(k, k))
	match tipo:
		"enfermeria": _enfermeria()
		"camarin": _camarin()
		"pizarra": _pizarra()
		"mercado": _mercado()
		"contratos": _contratos()
		"academia": _academia()
		"entrenamiento": _entrenamiento()
		"personal": _personal()
		"plantel": _plantel()
		_: EscaparateArte2.dibujar(self, tipo)

func _enfermeria() -> void:
	_r(0, 80, 160, 20, Color(1, 1, 1, 0.06))
	_r(28, 56, 84, 6, Color("eef2f6"))
	_r(34, 62, 3, 18, Color("9aa5b1")); _r(103, 62, 3, 18, Color("9aa5b1"))
	_o(35, 82, 4, Color("2b323b")); _o(105, 82, 4, Color("2b323b"))
	_r(32, 47, 56, 9, Color("cfe3f5")); _r(90, 49, 18, 7, Color("ffffff"))
	_r(112, 14, 36, 34, Color("f4f6f8")); _r(112, 14, 36, 4, c1)
	_r(127, 21, 6, 22, Color("d62b2b")); _r(119, 29, 22, 6, Color("d62b2b"))
	_r(120, 70, 28, 10, c2); _r(120, 70, 28, 3, Color(1, 1, 1, 0.5))

func _camarin() -> void:
	for i in 5:
		var x := 6.0 + i * 30.0
		_r(x, 8, 26, 74, Color("3b4656")); _r(x + 2, 10, 22, 70, Color("2a3340"))
		_r(x + 12, 12, 2, 66, Color(1, 1, 1, 0.12))
		_l(x + 13, 16, x + 13, 22, Color("c9d0d8"), 1.5)
		var cam: Color = c1 if i % 2 == 0 else c2
		_p([Vector2(x + 5, 22), Vector2(x + 10, 20), Vector2(x + 13, 24), Vector2(x + 16, 20), Vector2(x + 21, 22), Vector2(x + 25, 32), Vector2(x + 20, 34), Vector2(x + 20, 54), Vector2(x + 6, 54), Vector2(x + 6, 34), Vector2(x + 1, 32)], cam)
		_r(x + 6, 38, 14, 3, c2 if i % 2 == 0 else c1)
	_r(0, 84, 160, 5, MADERA); _r(0, 89, 160, 11, Color(0, 0, 0, 0.25))

func _pizarra() -> void:
	_r(10, 6, 140, 82, MADERA); _r(14, 10, 132, 74, Color("1f5a3d"))
	var bl := Color(1, 1, 1, 0.55)
	draw_rect(Rect2(20, 14, 120, 66), bl, false, 1.0); _l(80, 14, 80, 80, bl); draw_arc(Vector2(80, 47), 9, 0, TAU, 24, bl, 1.0)
	var filas := formacion.split("-")
	var xs := [32.0]
	for i in filas.size():
		xs.append(32.0 + (i + 1) * (92.0 / filas.size()))
	_o(xs[0], 47, 4.5, c2)
	for i in filas.size():
		var n := maxi(int(filas[i]), 1)
		for j in n:
			var y := 47.0 + (j - (n - 1) / 2.0) * (56.0 / maxf(n, 3))
			_o(xs[i + 1], y, 4.5, c1); draw_arc(Vector2(xs[i + 1], y), 4.5, 0, TAU, 12, Color.WHITE, 1.0)
	_l(100, 47, 124, 30, Color("ffd24a"), 1.5); _p([Vector2(124, 30), Vector2(117, 31), Vector2(121, 37)], Color("ffd24a"))
	_r(10, 88, 140, 5, Color("6f4b2a")); _r(30, 86, 10, 3, Color.WHITE)

func _mercado() -> void:
	_r(0, 78, 160, 22, Color(0, 0, 0, 0.3)); _r(8, 70, 144, 8, MADERA)
	_pers(40, 28, 1.25, c1, PIEL[0]); _pers(120, 28, 1.25, c2, PIEL[2])
	_r(66, 50, 28, 32, Color("f6f3ea")); _r(66, 50, 28, 4, c1)
	for i in 4:
		_r(70, 58 + i * 5, 20 - (i % 2) * 6, 1.6, Color(0, 0, 0, 0.35))
	_o(86, 76, 4, Color("d62b2b")); _l(96, 74, 108, 62, Color("1c2430"), 2.0)
	_r(58, 62, 8, 4, PIEL[0]); _r(94, 62, 8, 4, PIEL[2])   ## las manos que se acercan

func _contratos() -> void:
	_r(0, 62, 160, 38, MADERA); _r(0, 62, 160, 3, Color(1, 1, 1, 0.25))
	_p([Vector2(30, 70), Vector2(92, 66), Vector2(100, 94), Vector2(24, 96)], Color("f6f3ea"))
	_p([Vector2(70, 56), Vector2(130, 60), Vector2(134, 90), Vector2(74, 88)], Color("e8e4d6"))
	for i in 5:
		_l(36, 76 + i * 4.5, 90 - i, 74 + i * 4.5, Color(0, 0, 0, 0.3), 1.0)
	_o(114, 76, 8, c1); _o(114, 76, 5, c2)
	_p([Vector2(100, 40), Vector2(105, 38), Vector2(124, 74), Vector2(121, 76)], Color("1c2430")); _p([Vector2(121, 76), Vector2(124, 74), Vector2(126, 82)], Color("d9b44a"))

func _academia() -> void:
	_r(4, 12, 152, 78, Color("2f7d46")); draw_rect(Rect2(10, 18, 140, 66), Color(1, 1, 1, 0.6), false, 1.0)
	_l(80, 18, 80, 84, Color(1, 1, 1, 0.6)); draw_arc(Vector2(80, 51), 9, 0, TAU, 24, Color(1, 1, 1, 0.6), 1.0)
	for i in 6:
		var x := 32.0 + i * 20.0
		var y := 34.0 + (i % 3) * 14.0
		_o(x, y, 3.2, PIEL[i % 4]); _r(x - 3.5, y + 3, 7, 8, c1 if i % 2 == 0 else c2)
	_o(80, 52, 2.6, Color.WHITE)
	_r(6, 40, 3, 22, Color("e8eef2")); _r(151, 40, 3, 22, Color("e8eef2"))
	for i in 3:
		_p([Vector2(40 + i * 40, 76), Vector2(44 + i * 40, 76), Vector2(42 + i * 40, 70)], Color("ff8a1f"))

func _entrenamiento() -> void:
	_r(0, 40, 160, 60, Color("2f7d46")); _r(0, 40, 160, 10, Color("3c9157"))
	for i in 5:
		var x := 22.0 + i * 28.0
		_p([Vector2(x - 6, 78), Vector2(x + 6, 78), Vector2(x, 62)], Color("ff8a1f")); _r(x - 8, 78, 16, 2.5, Color("d96a00"))
	for q in [[40, 90], [92, 88], [128, 92]]:
		_o(q[0], q[1], 6, Color.WHITE); _o(q[0], q[1], 2.4, Color("1c2430"))
	for i in 5:
		_r(24 + i * 10.0, 50, 7, 3, Color(1, 1, 1, 0.5))
	_pers(120, 22, 1.0, c1, PIEL[1])

func _personal() -> void:
	_r(0, 84, 160, 16, Color(0, 0, 0, 0.3))
	for i in 4:
		_pers(24.0 + i * 37.0, 30.0 + (i % 2) * 6.0, 1.3, c1 if i % 2 == 0 else c2, PIEL[i % 4])
		_r(14.0 + i * 37.0, 52.0 + (i % 2) * 6.0, 20, 3, Color(1, 1, 1, 0.55))
	_r(110, 60, 22, 14, Color("e8e4d6")); _r(112, 64, 18, 1.5, Color(0, 0, 0, 0.35))

func _plantel() -> void:
	_r(0, 6, 160, 90, Color("2f7d46"))
	for i in 6:
		_r(i * 26.7, 6, 13.3, 90, Color(1, 1, 1, 0.05))
	draw_rect(Rect2(8, 12, 144, 78), Color(1, 1, 1, 0.6), false, 1.0); _l(80, 12, 80, 90, Color(1, 1, 1, 0.6)); draw_arc(Vector2(80, 51), 10, 0, TAU, 24, Color(1, 1, 1, 0.6), 1.0)
	var filas := formacion.split("-")
	var pos: Array = [Vector2(14, 51)]
	for i in filas.size():
		var n := maxi(int(filas[i]), 1)
		for j in n:
			pos.append(Vector2(14.0 + (i + 1) * (130.0 / (filas.size() + 0.4)), 51.0 + (j - (n - 1) / 2.0) * (70.0 / maxf(n, 3.5))))
	for q in pos.size():
		var v: Vector2 = pos[q]
		_o(v.x, v.y, 6.2, c2 if q == 0 else c1); draw_arc(v, 6.2, 0, TAU, 16, Color.WHITE, 1.2)
		var num := str(numeros[q]) if q < numeros.size() else str(q + 1)
		_t(v.x - 3.2 * num.length(), v.y + 3.0, num, 8, Color.WHITE)
