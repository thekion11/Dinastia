class_name MiniaturaMenu
extends Control
## LOS DIBUJOS PEQUEÑOS DE LOS PANELES DEL MENÚ DEL PARTIDO (17-11-2026, maqueta): el estadio de noche con su grada, la cámara (campo con el cuadro de lo que se ve),
## el campo con los once de la formación y el emblema de la competición. Todo se dibuja en `_draw`, sin imágenes.

enum Tipo { ESTADIO, CAMARA, CAMPO, EMBLEMA }
var tipo: Tipo = Tipo.ESTADIO
var zoom := 0.5                 ## CAMARA: el tamaño del cuadro de lo que se ve (0-1)
var formacion: Array = []       ## CAMPO: [[pos, x, y], …] (porcentajes, el arco propio abajo)
var acento := Color("c8102e")

const VERDE := Color("1f8a4a")

func _draw() -> void:
	match tipo:
		Tipo.ESTADIO: _estadio()
		Tipo.CAMARA: _camara()
		Tipo.CAMPO: _campo()
		Tipo.EMBLEMA: _emblema()

func _estadio() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), Color("0e1330"))
	draw_rect(Rect2(0, s.y * 0.28, s.x, s.y * 0.22), Color("1a2150"))
	var r := RandomNumberGenerator.new()
	r.seed = 42
	for i in 70:
		draw_circle(Vector2(r.randf() * s.x, s.y * (0.28 + r.randf() * 0.2)), 1.6, Color(1, 0.9, 0.6, 0.5 + r.randf() * 0.4))
	draw_rect(Rect2(0, s.y * 0.5, s.x, s.y * 0.5), VERDE)
	draw_line(Vector2(s.x * 0.5, s.y * 0.5), Vector2(s.x * 0.5, s.y), Color(1, 1, 1, 0.3), 2.0)
	for x in [0.08, 0.92]:
		draw_circle(Vector2(s.x * x, s.y * 0.14), s.y * 0.1, Color(0.85, 0.87, 0.95, 0.85))

func _camara() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), Color("0e1330"))
	var arriba := s.x * 0.2
	draw_polygon(PackedVector2Array([Vector2(arriba, s.y * 0.2), Vector2(s.x - arriba, s.y * 0.2), Vector2(s.x, s.y * 0.95), Vector2(0, s.y * 0.95)]), PackedColorArray([VERDE, VERDE, VERDE, VERDE]))
	draw_line(Vector2(s.x * 0.5, s.y * 0.2), Vector2(s.x * 0.5, s.y * 0.95), Color(1, 1, 1, 0.3), 2.0)
	var w := s.x * (0.28 + zoom * 0.5)
	var h := s.y * (0.3 + zoom * 0.35)
	draw_rect(Rect2(Vector2(s.x * 0.5 - w * 0.5, s.y * 0.58 - h * 0.5), Vector2(w, h)), Color("f5c542"), false, 3.0)

func _campo() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), VERDE)
	draw_rect(Rect2(Vector2.ZERO, s), Color(1, 1, 1, 0.6), false, 2.0)
	draw_line(Vector2(s.x * 0.5, 0), Vector2(s.x * 0.5, s.y), Color(1, 1, 1, 0.5), 1.5)
	draw_arc(s * 0.5, s.y * 0.14, 0, TAU, 24, Color(1, 1, 1, 0.5), 1.5)
	for p: Array in formacion:
		## el campo se dibuja apaisado: el arco propio a la izquierda (y del dato -> x)
		var pt := Vector2((1.0 - float(p[2]) / 100.0) * s.x * 0.92 + s.x * 0.04, float(p[1]) / 100.0 * s.y * 0.9 + s.y * 0.05)
		draw_circle(pt, s.y * 0.045, acento)
		draw_arc(pt, s.y * 0.045, 0, TAU, 16, Color.WHITE, 1.2)

func _emblema() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	draw_circle(c, r, Color("dfe8ff"))
	draw_circle(c, r * 0.76, Color("2a3f78"))
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * r * (0.5 if i % 2 == 0 else 0.22))
	draw_colored_polygon(pts, Color("f5c542"))
	## (17-11, Auditoría) sin el «LIGA» minúsculo: el nombre de la competición y la jornada van debajo, en una línea clara.
