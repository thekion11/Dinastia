class_name RutaBarra
extends Control
## LA BARRA DE TOQUE: una marca va y viene y hay que pararla dentro de la zona
## (verde = perfecto, oro = bien). La usan «El Toque» del entreno y «Los
## Momentos» del partido.

const E := preload("res://ui/carrera/ruta_estilo.gd")

var marca := 0.0
var centro := 0.5
var perfecto := 0.05      ## medio ancho de la zona verde (0-1 de la barra)
var bueno := 0.14         ## medio ancho de la zona oro
var velocidad := 2.6
var parada := true
var luces: Array = []     ## calidad de los intentos ya hechos (puntos de abajo)
var total_luces := 0
var _t := 0.0

func _init() -> void:
	custom_minimum_size = Vector2(0, 64)

## Empieza un intento: zona nueva (al azar con `azar`) y la marca en marcha.
func lanzar(azar: RandomNumberGenerator, vel: float, medio_perfecto := 0.05, medio_bueno := 0.14) -> void:
	perfecto = medio_perfecto
	bueno = medio_bueno
	velocidad = vel
	centro = azar.randf_range(0.08 + bueno, 0.92 - bueno)
	_t = azar.randf_range(0.0, TAU)
	parada = false

func _process(d: float) -> void:
	if parada:
		return
	_t += d * velocidad
	marca = 0.5 + 0.5 * sin(_t)
	queue_redraw()

## Para la marca y devuelve la calidad: 1 perfecto, 0,6 bien, 0,1 fuera.
func golpear() -> float:
	parada = true
	queue_redraw()
	return calidad(marca, centro, perfecto, bueno)

static func calidad(pos: float, medio: float, medio_perfecto := 0.05, medio_bueno := 0.14) -> float:
	var dist := absf(pos - medio)
	return 1.0 if dist <= medio_perfecto else (0.6 if dist <= medio_bueno else 0.1)

static func color_de(q: float) -> Color:
	return E.MENTA if q >= 1.0 else (E.ORO if q >= 0.6 else E.CORAL)

func _draw() -> void:
	var w := size.x
	var h := size.y
	var y := h * 0.5 - 9.0
	draw_style_box(_caja(Color(1, 1, 1, 0.08)), Rect2(0, y, w, 18))
	draw_style_box(_caja(Color(E.ORO, 0.55)), Rect2((centro - bueno) * w, y, bueno * 2.0 * w, 18))
	draw_style_box(_caja(E.MENTA), Rect2((centro - perfecto) * w, y, perfecto * 2.0 * w, 18))
	draw_circle(Vector2(marca * w, h * 0.5), 15.0, E.TEXTO)
	draw_circle(Vector2(marca * w, h * 0.5), 9.0, E.NOCHE)
	for i in total_luces:
		var col := Color(1, 1, 1, 0.15)
		if i < luces.size():
			col = color_de(float(luces[i]))
		draw_circle(Vector2(w * 0.5 + (float(i) - float(total_luces - 1) * 0.5) * 22.0, h - 4.0), 5.0, col)

func _caja(col: Color) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = col
	st.set_corner_radius_all(9)
	return st
