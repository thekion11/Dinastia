class_name TarjetaMano
extends Control
## LA TARJETA EN LA MANO (§2.5 del guion, pieza A de §2.2h; 31-10-2026): como el móvil de `MovilMano`, al pagar con
## tarjeta sube desde abajo a la derecha la tarjeta del DT (banco, últimos cuatro dígitos, titular y el
## chip sin contacto) con el importe, y vuelve a bajar a los dos segundos. La lanza `VidaCiudad` al oír
## `CarteraDT.pago_con_tarjeta`. Solo 2D, sin tocar el cuerpo del personaje.

const ANCHO := 260.0
const ALTO := 164.0
const DURA := 2.2

var _importe: Label
var _t := 0.0

static func crear(banco: String, titular: String, digitos: String) -> TarjetaMano:
	var t := TarjetaMano.new()
	t._montar(banco, titular, digitos)
	return t

func _montar(banco: String, titular: String, digitos: String) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	offset_left = -ANCHO - 200
	offset_right = -200
	offset_top = 20
	offset_bottom = 20 + ALTO
	rotation_degrees = -6.0
	pivot_offset = Vector2(ANCHO, ALTO)
	var cuerpo := Panel.new()
	cuerpo.set_anchors_preset(Control.PRESET_FULL_RECT)
	cuerpo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.24, 0.5)
	sb.set_corner_radius_all(14)
	sb.border_color = Color(0.55, 0.7, 0.95)
	sb.set_border_width_all(1)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 5)
	cuerpo.add_theme_stylebox_override("panel", sb)
	add_child(cuerpo)
	var chip := ColorRect.new()
	chip.color = Color(0.86, 0.72, 0.36)
	chip.position = Vector2(22, 52)
	chip.size = Vector2(38, 28)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(chip)
	_etiqueta(banco.to_upper(), Vector2(20, 14), 15, Color(1, 1, 1, 0.92))
	_etiqueta("))))", Vector2(ANCHO - 58, 52), 16, Color(1, 1, 1, 0.75))   ## sin contacto
	_etiqueta("••••  ••••  ••••  " + digitos, Vector2(22, 92), 17, Color.WHITE)
	_etiqueta(titular.to_upper(), Vector2(22, 128), 12, Color(1, 1, 1, 0.85))
	_importe = _etiqueta("", Vector2(ANCHO - 120, 12), 18, Color(1.0, 0.86, 0.5))
	_importe.size = Vector2(104, 24)
	_importe.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	visible = false

func _etiqueta(texto: String, pos: Vector2, tam: int, col: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.position = pos
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l

## Enseña la tarjeta con el importe (en €) que se acaba de cobrar.
func mostrar(importe: int) -> void:
	_importe.text = "−%d €" % importe
	_t = DURA
	visible = true

func _process(delta: float) -> void:
	if _t <= 0.0:
		return
	_t -= delta
	## Sube en 0,25 s, se queda y baja en 0,3 s.
	var subida := clampf((DURA - _t) / 0.25, 0.0, 1.0) * clampf(_t / 0.3, 0.0, 1.0)
	offset_top = lerpf(40.0, -ALTO - 50.0, subida)
	offset_bottom = offset_top + ALTO
	if _t <= 0.0:
		visible = false

## Los cuatro últimos dígitos (siempre los mismos para el mismo DT).
static func digitos_de(semilla: String) -> String:
	return "%04d" % (absi(semilla.hash()) % 10000)
