class_name IndicadorFC
extends Control
## EL INDICADOR DEL JUGADOR QUE MANEJAS, COMO EN FC (14-10-2026, «ves la
## diferencia de cómo aparece la barra de energía y los nombres»). Antes era
## una flecha 3D amarilla enorme, un aro en el suelo y la energía escrita con
## cuadraditos ▮▮▮▯. En FC 26 es discreto y en pantalla: sobre la cabeza, un
## triángulo del color del mando, el nombre en letra pequeña con sombra y una
## barra FINA de energía que va de verde a amarillo y a rojo. Se dibuja en 2D
## (siempre nítido, del mismo tamaño se mire de cerca o de lejos).

var nombre := ""
var numero := 0
var energia := 1.0
var color_mando := Color("2f9bff")
## Punto de pantalla sobre la cabeza del jugador (lo pone quien lo usa).
var punto := Vector2.ZERO
var _fuente: Font

const ANCHO_BARRA := 54.0
const ALTO_BARRA := 4.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fuente = ThemeDB.fallback_font

func color_energia(e: float) -> Color:
	if e > 0.6:
		return Color("52e07a").lerp(Color("c9ef4f"), clampf((0.85 - e) / 0.25, 0.0, 1.0))
	if e > 0.35:
		return Color("f5d33b")
	return Color("ff5a3c")

func colocar(p: Vector2, nom: String, num: int, e: float) -> void:
	punto = p
	nombre = nom
	numero = num
	energia = e
	queue_redraw()

func _draw() -> void:
	if not visible or nombre == "":
		return
	var y := punto.y
	## El triángulo del mando, con un leve rebote.
	var rebote := sin(Time.get_ticks_msec() * 0.006) * 2.0
	var t0 := Vector2(punto.x, y - 3.0 + rebote)
	var tri := PackedVector2Array([t0 + Vector2(-8, -11), t0 + Vector2(8, -11), t0])
	draw_colored_polygon(tri, Color(0, 0, 0, 0.35))
	draw_colored_polygon(PackedVector2Array([tri[0] + Vector2(1.5, 1.2), tri[1] + Vector2(-1.5, 1.2), tri[2] + Vector2(0, -2)]), color_mando)
	## El nombre (número y apellido), pequeño y con sombra.
	var txt := ("%d  %s" % [numero, nombre]) if numero > 0 else nombre
	var tam := 15
	var ancho := _fuente.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	var base := Vector2(punto.x - ancho * 0.5, y - 26.0 + rebote)
	draw_string_outline(_fuente, base, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, 4, Color(0, 0, 0, 0.75))
	draw_string(_fuente, base, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Color(1, 1, 1, 0.96))
	## La barra de energía, fina, debajo del nombre.
	var r := Rect2(Vector2(punto.x - ANCHO_BARRA * 0.5, y - 21.0 + rebote), Vector2(ANCHO_BARRA, ALTO_BARRA))
	draw_rect(r.grow(1.0), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(r.position, Vector2(ANCHO_BARRA * clampf(energia, 0.0, 1.0), ALTO_BARRA)), color_energia(energia))
