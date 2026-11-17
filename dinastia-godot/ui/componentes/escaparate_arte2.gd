class_name EscaparateArte2
extends RefCounted
## Las ilustraciones de «Información del club» (cuentas, patrocinadores, hinchada, estadio, historia, ligas, correo, informe, récords, sistema) para `EscaparateArte`: mismas piezas, mismos colores del club.

static func dibujar(a: EscaparateArte, tipo: String) -> void:
	var c1: Color = a.c1
	var c2: Color = a.c2
	match tipo:
		"cuentas":
			for i in 5:
				a._r(20.0 + i * 20.0, 78.0 - (i + 1) * 11.0, 14, (i + 1) * 11.0, c1 if i % 2 == 0 else c2)
			for i in 4:
				a._o(130, 86 - i * 6, 11, Color("e0b43c")); a._o(130, 84 - i * 6, 11, Color("f3cf5a"))
			a._l(14, 80, 112, 30, Color("ffffff"), 2.0)
		"patrocinadores":
			for i in 3:
				var x := 6.0 + i * 52.0
				a._r(x, 20, 48, 30, Color("20262e")); a._r(x + 2, 22, 44, 26, c1 if i != 1 else c2)
				a._o(x + 14, 35, 7, Color.WHITE); a._r(x + 26, 31, 16, 3, Color(1, 1, 1, 0.8)); a._r(x + 26, 38, 12, 3, Color(1, 1, 1, 0.55))
			a._r(0, 62, 160, 38, Color("2f7d46")); a._o(80, 80, 6, Color.WHITE)
		"hinchada":
			for f in 3:
				for i in 11:
					var x := 8.0 + i * 14.0 + (f % 2) * 7.0
					var y := 38.0 + f * 20.0
					a._r(x - 5, y + 6, 10, 12, c1 if (i + f) % 2 == 0 else c2); a._o(x, y, 4.2, a.PIEL[(i + f) % 4])
			a._l(20, 10, 140, 10, Color("e8e4d6"), 1.5); a._r(20, 10, 120, 12, c1); a._r(20, 14, 120, 3, c2)
		"estadio":
			a.draw_circle(Vector2(80, 52), 64, Color(0, 0, 0, 0.0))
			_ovalo(a, 80, 52, 70, 40, Color("39414d")); _ovalo(a, 80, 52, 62, 33, c1); _ovalo(a, 80, 52, 50, 23, Color("2f7d46"))
			a._r(78, 31, 4, 40, Color(1, 1, 1, 0.55)); a._l(34, 52, 126, 52, Color(1, 1, 1, 0.0))
		"historia":
			a._p([Vector2(50, 18), Vector2(110, 18), Vector2(106, 46), Vector2(92, 58), Vector2(68, 58), Vector2(54, 46)], Color("f3cf5a"))
			a.draw_arc(Vector2(48, 32), 12, PI * 0.5, PI * 1.5, 14, Color("e0b43c"), 3.0); a.draw_arc(Vector2(112, 32), 12, -PI * 0.5, PI * 0.5, 14, Color("e0b43c"), 3.0)
			a._r(74, 58, 12, 14, Color("e0b43c")); a._r(56, 72, 48, 10, c1); a._r(56, 72, 48, 3, c2)
		"ligas":
			for i in 8:
				var y := 12.0 + i * 10.0
				a._r(12, y, 136, 8, Color(1, 1, 1, 0.07 if i % 2 == 0 else 0.0))
				a._o(24, y + 4, 3.4, c1 if i == 5 else c2 if i % 3 == 0 else Color("8a95a3")); a._r(34, y + 2, 50 - i * 3, 3, Color(1, 1, 1, 0.55)); a._r(120, y + 2, 20, 3, Color(1, 1, 1, 0.4))
			a._r(10, 52, 140, 10, Color(c1, 0.45))
		"correo":
			a._r(26, 30, 108, 56, Color("f6f3ea")); a._p([Vector2(26, 30), Vector2(134, 30), Vector2(80, 66)], Color("e0dccb"))
			a._l(26, 86, 70, 56, Color(0, 0, 0, 0.18), 1.2); a._l(134, 86, 90, 56, Color(0, 0, 0, 0.18), 1.2)
			a._o(80, 62, 8, c1); a._o(80, 62, 4.5, c2)
		"informe":
			a._r(38, 8, 84, 88, MADERA); a._r(42, 14, 76, 78, Color("f6f3ea")); a._r(64, 4, 32, 12, Color("9aa5b1"))
			for i in 4:
				var y := 28.0 + i * 15.0
				a._o(52, y + 3, 3.4, Color("d62b2b") if i < 2 else Color("3aa561")); a._r(60, y + 1, 48 - i * 6, 3, Color(0, 0, 0, 0.4)); a._r(60, y + 7, 36, 2, Color(0, 0, 0, 0.2))
		"records":
			for i in 5:
				a._r(18.0 + i * 26.0, 84.0 - (14 + i * 11), 18, 14 + i * 11, c1 if i < 4 else Color("f3cf5a"))
			a._p([Vector2(140, 12), Vector2(143, 20), Vector2(152, 20), Vector2(145, 25), Vector2(148, 33), Vector2(140, 28), Vector2(132, 33), Vector2(135, 25), Vector2(128, 20), Vector2(137, 20)], Color("f3cf5a"))
		_:
			a._o(80, 50, 30, Color("8a95a3")); a._o(80, 50, 16, c1.darkened(0.6))
			for i in 8:
				var ang := i * TAU / 8.0
				a._p([Vector2(80, 50) + Vector2(cos(ang - 0.2), sin(ang - 0.2)) * 28.0, Vector2(80, 50) + Vector2(cos(ang - 0.17), sin(ang - 0.17)) * 40.0,
					Vector2(80, 50) + Vector2(cos(ang + 0.17), sin(ang + 0.17)) * 40.0, Vector2(80, 50) + Vector2(cos(ang + 0.2), sin(ang + 0.2)) * 28.0], Color("8a95a3"))

static func _ovalo(a: EscaparateArte, x: float, y: float, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 40:
		pts.append(Vector2(x + cos(i * TAU / 40.0) * rx, y + sin(i * TAU / 40.0) * ry))
	a.draw_colored_polygon(pts, col)
