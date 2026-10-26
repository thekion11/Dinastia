class_name RadarAtributos
extends Control
## GRÁFICO RADIAL DE ATRIBUTOS (informe de diseño, 13-10-2026: «el cerebro tarda
## demasiado en comparar filas de números; un hexágono dice de un vistazo si es
## un pivote defensivo o un extremo rápido»). Dibuja una telaraña de 4 anillos
## y el polígono de los valores (la escala va de 35 a 100: por debajo de 35 casi
## nadie juega, y así las diferencias entre jugadores se ven) de 5 a 8 ejes.
## La malla y el borde son líneas suaves (`TrazoSuave`, 26-10-2026): se rehacen
## al cambiar los valores o el tamaño, no en cada `_draw`.
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
	_rehacer_lineas()
	queue_redraw()

func _notification(que: int) -> void:
	if que == NOTIFICATION_RESIZED:
		_rehacer_lineas()

func _centro_radio() -> Array:
	return [size * 0.5 + Vector2(0, 2), minf(size.x, size.y) * 0.36]

func _poligono_valores(n: int, radio: float, centro: Vector2) -> PackedVector2Array:
	var poli := PackedVector2Array()
	for i in n:
		poli.append(_punto(i, n, radio * clampf((valores[i] - 35.0) / 65.0, 0.06, 1.0), centro))
	return poli

## La malla (cuatro anillos y los ejes) va DETRÁS del relleno; el borde, encima.
func _rehacer_lineas() -> void:
	TrazoSuave.limpiar(self)
	var n := valores.size()
	if n < 3 or size.x <= 0.0:
		return
	var cr := _centro_radio()
	var centro: Vector2 = cr[0]
	var radio: float = cr[1]
	for r in 4:
		var pts := PackedVector2Array()
		for i in n:
			pts.append(_punto(i, n, radio * float(r + 1) / 4.0, centro))
		TrazoSuave.linea(self, pts, color_malla, 1.0, true, true)
	for i in n:
		TrazoSuave.linea(self, PackedVector2Array([centro, _punto(i, n, radio, centro)]), color_malla, 1.0, false, true)
	TrazoSuave.linea(self, _poligono_valores(n, radio, centro), color, 2.0, true)

func _punto(i: int, n: int, radio: float, centro: Vector2) -> Vector2:
	var a := -PI * 0.5 + TAU * float(i) / float(n)
	return centro + Vector2(cos(a), sin(a)) * radio

func _draw() -> void:
	var n := valores.size()
	if n < 3:
		return
	var cr := _centro_radio()
	var centro: Vector2 = cr[0]
	var radio: float = cr[1]
	## El polígono de valores (la malla y el borde son líneas hijas).
	var poli := _poligono_valores(n, radio, centro)
	draw_colored_polygon(poli, Color(color, 0.32))
	for p in poli:
		draw_circle(p, 2.5, color, true, -1.0, true)
	## Las etiquetas, algo fuera del anillo.
	var fuente := get_theme_default_font()
	for i in n:
		if i >= etiquetas.size():
			break
		var q := _punto(i, n, radio + 13.0, centro)
		var ancho := fuente.get_string_size(etiquetas[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_string(fuente, q + Vector2(-ancho * 0.5, 4), etiquetas[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color_texto)
