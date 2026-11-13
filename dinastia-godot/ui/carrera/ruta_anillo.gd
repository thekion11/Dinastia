class_name RutaAnillo
extends Control
## El anillo del nivel: un arco que se llena con la experiencia y el número
## del nivel dentro.

var progreso := 0.0
var texto := "1"
var color := RutaEstilo.ORO

static func crear(valor: float, numero: String, col: Color, px := 64) -> RutaAnillo:
	var a := RutaAnillo.new()
	a.progreso = clampf(valor, 0.0, 1.0)
	a.texto = numero
	a.color = col
	a.custom_minimum_size = Vector2(px, px)
	a.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return a

func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 4.0
	draw_arc(c, r, 0.0, TAU, 48, Color(1, 1, 1, 0.10), 5.0, true)
	if progreso > 0.0:
		draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * progreso, 48, color, 5.0, true)
	var f := RutaEstilo.titular()
	var tam := int(r * 1.05)
	var ancho := f.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	draw_string(f, Vector2(c.x - ancho / 2.0, c.y + float(tam) * 0.36), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, RutaEstilo.TEXTO)
