class_name RadarAtributos
extends Control
## GRÁFICO RADIAL DE ATRIBUTOS (informe de diseño, 13-10-2026: «el cerebro tarda
## demasiado en comparar filas de números; un hexágono dice de un vistazo si es
## un pivote defensivo o un extremo rápido»). Dibuja una telaraña de 4 anillos
## y el polígono de los valores (la escala va de 35 a 100: por debajo de 35 casi
## nadie juega, y así las diferencias entre jugadores se ven) de 5 a 8 ejes.
var etiquetas: PackedStringArray = []
var valores: PackedFloat32Array = []
var color := Color(0.2, 0.75, 0.5)
var color_texto := Color(0.85, 0.88, 0.9)
var color_malla := Color(1, 1, 1, 0.14)

func _init() -> void:
	custom_minimum_size = Vector2(150, 140)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func poner(e: PackedStringArray, v: PackedFloat32Array, c: Color) -> void:
	etiquetas = e
	valores = v
	color = c
	queue_redraw()

func _punto(i: int, n: int, radio: float, centro: Vector2) -> Vector2:
	var a := -PI * 0.5 + TAU * float(i) / float(n)
	return centro + Vector2(cos(a), sin(a)) * radio

func _draw() -> void:
	var n := valores.size()
	if n < 3:
		return
	var centro := size * 0.5 + Vector2(0, 2)
	var radio := minf(size.x, size.y) * 0.36
	## La malla: cuatro anillos y los ejes.
	for r in 4:
		var pts := PackedVector2Array()
		for i in n:
			pts.append(_punto(i, n, radio * float(r + 1) / 4.0, centro))
		pts.append(pts[0])
		draw_polyline(pts, color_malla, 1.0)
	for i in n:
		draw_line(centro, _punto(i, n, radio, centro), color_malla, 1.0)
	## El polígono de valores.
	var poli := PackedVector2Array()
	for i in n:
		poli.append(_punto(i, n, radio * clampf((valores[i] - 35.0) / 65.0, 0.06, 1.0), centro))
	draw_colored_polygon(poli, Color(color, 0.32))
	var borde := poli.duplicate()
	borde.append(poli[0])
	draw_polyline(borde, color, 2.0, true)
	for p in poli:
		draw_circle(p, 2.5, color)
	## Las etiquetas, algo fuera del anillo.
	var fuente := get_theme_default_font()
	for i in n:
		if i >= etiquetas.size():
			break
		var q := _punto(i, n, radio + 13.0, centro)
		var ancho := fuente.get_string_size(etiquetas[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_string(fuente, q + Vector2(-ancho * 0.5, 4), etiquetas[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color_texto)
