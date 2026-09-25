class_name Anillo
extends Control
## EL ANILLO DE VALORACIÓN (25-9-2026): el círculo con la cifra dentro que usan
## los managers modernos (Soccer Manager, FC) para leer de un vistazo "cuánto de
## bueno" es algo -la media del plantel, la confianza del directorio, la media
## de un jugador-. Se llena animado al aparecer.

var valor := 0.0
var maximo := 100.0
var color := Color("3fa06a")
var color_fondo := Color(1, 1, 1, 0.10)
var texto := ""
var tam_texto := 18
var grosor := 6.0
var _mostrado := 0.0

static func crear(v: float, maxv: float, col: Color, diametro: float = 64.0, txt: String = "") -> Anillo:
	var a := Anillo.new()
	a.valor = v
	a.maximo = maxv
	a.color = col
	a.texto = txt if txt != "" else str(int(round(v)))
	a.custom_minimum_size = Vector2(diametro, diametro)
	a.tam_texto = int(diametro * 0.3)
	a.grosor = maxf(3.0, diametro * 0.09)
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return a

func _ready() -> void:
	var t := create_tween()
	t.tween_method(func(x: float) -> void:
		_mostrado = x
		queue_redraw(), 0.0, clampf(valor / maxf(maximo, 0.001), 0.0, 1.0), 0.7) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	var centro := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - grosor * 0.5 - 1.0
	draw_arc(centro, r, 0.0, TAU, 64, color_fondo, grosor, true)
	if _mostrado > 0.0:
		draw_arc(centro, r, -PI * 0.5, -PI * 0.5 + TAU * _mostrado, 64, color, grosor, true)
	var fuente := get_theme_default_font()
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_CENTER, -1, tam_texto).x
	var alto := fuente.get_height(tam_texto)
	draw_string(fuente, Vector2(centro.x - ancho * 0.5, centro.y + alto * 0.32), texto,
		HORIZONTAL_ALIGNMENT_LEFT, -1, tam_texto, Color("e9eeea"))
