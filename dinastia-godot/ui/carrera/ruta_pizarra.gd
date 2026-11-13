class_name RutaPizarra
extends Control
## LA PIZARRA DE «LOS MOMENTOS»: la jugada dibujada desde arriba (medio campo
## con su área): tú en oro, los tuyos en el color de tu club, los rivales en
## gris, el balón y las flechas de lo que va a pasar. Las de ataque miran a la
## portería de arriba; las de defensa, a la tuya, abajo.

const E := preload("res://ui/carrera/ruta_estilo.gd")

## tipo -> {abajo, yo, mios, suyos, balon, flechas: [[desde, hasta, es_pase]]}
const JUGADAS := {
	"remate": {"abajo": false, "yo": Vector2(0.5, 0.46), "mios": [Vector2(0.86, 0.3)], "suyos": [Vector2(0.5, 0.1), Vector2(0.41, 0.36), Vector2(0.61, 0.42)],
		"balon": Vector2(0.84, 0.3), "flechas": [[Vector2(0.84, 0.3), Vector2(0.53, 0.45), true], [Vector2(0.5, 0.44), Vector2(0.43, 0.06), false]]},
	"mano": {"abajo": false, "yo": Vector2(0.5, 0.62), "mios": [], "suyos": [Vector2(0.5, 0.26), Vector2(0.3, 0.72), Vector2(0.7, 0.74)],
		"balon": Vector2(0.52, 0.58), "flechas": [[Vector2(0.52, 0.58), Vector2(0.6, 0.06), false]]},
	"pase": {"abajo": false, "yo": Vector2(0.42, 0.82), "mios": [Vector2(0.6, 0.52)], "suyos": [Vector2(0.5, 0.1), Vector2(0.5, 0.5), Vector2(0.72, 0.5)],
		"balon": Vector2(0.44, 0.78), "flechas": [[Vector2(0.44, 0.78), Vector2(0.62, 0.3), true], [Vector2(0.6, 0.52), Vector2(0.62, 0.32), false]]},
	"robo": {"abajo": false, "yo": Vector2(0.44, 0.66), "mios": [Vector2(0.7, 0.4)], "suyos": [Vector2(0.5, 0.5), Vector2(0.3, 0.35), Vector2(0.5, 0.1)],
		"balon": Vector2(0.52, 0.53), "flechas": [[Vector2(0.44, 0.66), Vector2(0.51, 0.54), false]]},
	"entrada": {"abajo": true, "yo": Vector2(0.5, 0.64), "mios": [Vector2(0.5, 0.9)], "suyos": [Vector2(0.5, 0.38), Vector2(0.75, 0.3)],
		"balon": Vector2(0.52, 0.42), "flechas": [[Vector2(0.5, 0.4), Vector2(0.5, 0.56), false]]},
	"despeje": {"abajo": true, "yo": Vector2(0.64, 0.8), "mios": [Vector2(0.36, 0.78)], "suyos": [Vector2(0.45, 0.6)],
		"balon": Vector2(0.5, 0.84), "flechas": [[Vector2(0.5, 0.84), Vector2(0.5, 0.95), true], [Vector2(0.64, 0.8), Vector2(0.53, 0.85), false]]},
	"parada": {"abajo": true, "yo": Vector2(0.5, 0.9), "mios": [Vector2(0.3, 0.5)], "suyos": [Vector2(0.5, 0.6)],
		"balon": Vector2(0.52, 0.64), "flechas": [[Vector2(0.52, 0.64), Vector2(0.56, 0.93), false]]},
	"vuelo": {"abajo": true, "yo": Vector2(0.5, 0.9), "mios": [Vector2(0.4, 0.55), Vector2(0.58, 0.55)], "suyos": [Vector2(0.45, 0.36)],
		"balon": Vector2(0.47, 0.4), "flechas": [[Vector2(0.47, 0.4), Vector2(0.6, 0.94), false]]},
	"salida": {"abajo": true, "yo": Vector2(0.5, 0.9), "mios": [Vector2(0.42, 0.74)], "suyos": [Vector2(0.9, 0.58), Vector2(0.47, 0.7), Vector2(0.57, 0.72)],
		"balon": Vector2(0.88, 0.6), "flechas": [[Vector2(0.88, 0.6), Vector2(0.52, 0.76), true], [Vector2(0.5, 0.9), Vector2(0.51, 0.79), false]]},
	"falta": {"abajo": false, "yo": Vector2(0.44, 0.74), "mios": [Vector2(0.62, 0.3)], "suyos": [Vector2(0.5, 0.1), Vector2(0.41, 0.5), Vector2(0.45, 0.5), Vector2(0.49, 0.5), Vector2(0.53, 0.5)],
		"balon": Vector2(0.46, 0.7), "flechas": [[Vector2(0.46, 0.7), Vector2(0.56, 0.05), false]]},
	"cabezazo": {"abajo": false, "yo": Vector2(0.44, 0.24), "mios": [Vector2(0.97, 0.05), Vector2(0.58, 0.3)], "suyos": [Vector2(0.5, 0.08), Vector2(0.4, 0.2), Vector2(0.55, 0.22)],
		"balon": Vector2(0.95, 0.06), "flechas": [[Vector2(0.95, 0.06), Vector2(0.47, 0.22), true], [Vector2(0.45, 0.22), Vector2(0.52, 0.05), false]]},
	"centro": {"abajo": false, "yo": Vector2(0.9, 0.2), "mios": [Vector2(0.55, 0.42)], "suyos": [Vector2(0.5, 0.1), Vector2(0.82, 0.26), Vector2(0.48, 0.34)],
		"balon": Vector2(0.9, 0.16), "flechas": [[Vector2(0.9, 0.16), Vector2(0.56, 0.26), true], [Vector2(0.55, 0.42), Vector2(0.55, 0.28), false]]},
	"cobertura": {"abajo": true, "yo": Vector2(0.4, 0.66), "mios": [Vector2(0.72, 0.4), Vector2(0.5, 0.9)], "suyos": [Vector2(0.68, 0.5), Vector2(0.4, 0.4)],
		"balon": Vector2(0.69, 0.54), "flechas": [[Vector2(0.69, 0.54), Vector2(0.6, 0.7), false], [Vector2(0.4, 0.66), Vector2(0.57, 0.69), false]]},
	"penal": {"abajo": true, "yo": Vector2(0.5, 0.93), "mios": [Vector2(0.3, 0.42)], "suyos": [Vector2(0.5, 0.62), Vector2(0.66, 0.42)],
		"balon": Vector2(0.5, 0.67), "flechas": [[Vector2(0.5, 0.67), Vector2(0.45, 0.95), false]]},
	"pies": {"abajo": true, "yo": Vector2(0.5, 0.88), "mios": [Vector2(0.9, 0.6)], "suyos": [Vector2(0.42, 0.7), Vector2(0.58, 0.72)],
		"balon": Vector2(0.52, 0.84), "flechas": [[Vector2(0.52, 0.84), Vector2(0.87, 0.62), true]]},
}

## Adónde va el balón al resolver: tipo -> [si sale bien, si sale mal].
const DESTINOS := {
	"remate": [Vector2(0.44, 0.03), Vector2(0.3, 0.0)], "mano": [Vector2(0.56, 0.03), Vector2(0.5, 0.24)],
	"pase": [Vector2(0.62, 0.3), Vector2(0.5, 0.5)], "robo": [Vector2(0.46, 0.64), Vector2(0.5, 0.3)],
	"entrada": [Vector2(0.52, 0.62), Vector2(0.5, 0.97)], "despeje": [Vector2(0.86, 0.5), Vector2(0.5, 0.97)],
	"parada": [Vector2(0.52, 0.88), Vector2(0.56, 0.97)], "vuelo": [Vector2(0.72, 0.8), Vector2(0.56, 0.97)],
	"salida": [Vector2(0.5, 0.87), Vector2(0.48, 0.97)],
	"falta": [Vector2(0.56, 0.03), Vector2(0.49, 0.5)], "cabezazo": [Vector2(0.52, 0.03), Vector2(0.5, 0.08)],
	"centro": [Vector2(0.56, 0.27), Vector2(0.48, 0.34)], "cobertura": [Vector2(0.56, 0.69), Vector2(0.6, 0.9)],
	"penal": [Vector2(0.48, 0.9), Vector2(0.44, 0.97)], "pies": [Vector2(0.88, 0.61), Vector2(0.58, 0.72)],
}

var tipo := "remate"
## 0-1: lo que lleva recorrido el balón hacia su destino tras resolver.
var avance := 0.0:
	set(v):
		avance = v
		queue_redraw()
var _destino := Vector2.ZERO
var tono := E.CIELO
## -1 sin resolver; 1 perfecto, 0,6 bien, 0,1 fallo: tiñe las flechas.
var calidad := -1.0

func _init() -> void:
	custom_minimum_size = Vector2(0, 150)

func poner(tipo_jugada: String, color_club: Color) -> void:
	tipo = tipo_jugada if JUGADAS.has(tipo_jugada) else "remate"
	tono = color_club
	calidad = -1.0
	avance = 0.0
	queue_redraw()

## `bien`: si la jugada acabó a tu favor (el balón va al destino bueno).
func resolver(q: float, bien := true) -> void:
	calidad = q
	_destino = DESTINOS[tipo][0 if bien else 1]
	if E._anima() and is_inside_tree():
		avance = 0.0
		create_tween().tween_property(self, "avance", 1.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		avance = 1.0

func _p(u: Vector2, r: Rect2) -> Vector2:
	return r.position + u * r.size

func _draw() -> void:
	var d: Dictionary = JUGADAS[tipo]
	## El campo: a lo ancho, hasta cuatro veces el alto (centrado si sobra).
	var w := minf(size.x, size.y * 4.0)
	var r := Rect2((size.x - w) * 0.5, 0, w, size.y)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color("123524")
	fondo.set_corner_radius_all(10)
	draw_style_box(fondo, r)
	var raya := Color(1, 1, 1, 0.28)
	var abajo := bool(d["abajo"])
	var y_gol := 0.97 if abajo else 0.03
	var sentido := -1.0 if abajo else 1.0
	## Área grande, área chica y portería.
	draw_rect(Rect2(_p(Vector2(0.22, y_gol if not abajo else y_gol - 0.42), r), Vector2(0.56, 0.42) * r.size), raya, false, 2.0)
	draw_rect(Rect2(_p(Vector2(0.38, y_gol if not abajo else y_gol - 0.16), r), Vector2(0.24, 0.16) * r.size), raya, false, 2.0)
	draw_line(_p(Vector2(0.43, y_gol), r), _p(Vector2(0.57, y_gol), r), E.TEXTO, 5.0)
	draw_arc(_p(Vector2(0.5, y_gol + sentido * 0.42), r), r.size.y * 0.12, 0.0 if not abajo else PI, PI if not abajo else TAU, 16, raya, 2.0)
	## Las flechas (debajo de las fichas).
	var col_f := E.TEXTO if calidad < 0.0 else RutaBarra.color_de(calidad)
	for f: Array in d["flechas"]:
		_flecha(_p(f[0], r), _p(f[1], r), Color(col_f, 0.9), bool(f[2]))
	for s: Vector2 in d["suyos"]:
		draw_circle(_p(s, r), 9.0, Color("8b93a7"))
		draw_arc(_p(s, r), 9.0, 0.0, TAU, 20, Color(0, 0, 0, 0.5), 1.5)
	for mi: Vector2 in d["mios"]:
		draw_circle(_p(mi, r), 9.0, tono)
		draw_arc(_p(mi, r), 9.0, 0.0, TAU, 20, Color(1, 1, 1, 0.7), 1.5)
	draw_circle(_p(d["yo"], r), 11.0, E.ORO)
	draw_arc(_p(d["yo"], r), 14.0, 0.0, TAU, 24, Color(E.ORO, 0.6), 2.0)
	var balon: Vector2 = d["balon"]
	if calidad >= 0.0:
		balon = balon.lerp(_destino, avance)
	draw_circle(_p(balon, r), 5.0, Color.WHITE)
	draw_arc(_p(balon, r), 5.0, 0.0, TAU, 12, Color.BLACK, 1.0)

## Flecha de `a` a `b`; a trazos si es un pase o un balón que viene.
func _flecha(a: Vector2, b: Vector2, col: Color, trazos: bool) -> void:
	if trazos:
		draw_dashed_line(a, b, col, 2.5, 8.0)
	else:
		draw_line(a, b, col, 3.0, true)
	var dir := (b - a).normalized()
	var lado := Vector2(-dir.y, dir.x)
	draw_colored_polygon(PackedVector2Array([b, b - dir * 11.0 + lado * 6.0, b - dir * 11.0 - lado * 6.0]), col)
