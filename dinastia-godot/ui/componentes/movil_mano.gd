class_name MovilMano
extends Control
## EL MÓVIL EN LA MANO (13-10-2026): al correr, conducir o ir en metro sube
## desde abajo a la derecha un móvil con la velocidad, la calle y lo recorrido,
## como una app de carrera. Al andar o pararse vuelve a bajar.

const ANCHO := 150.0
const ALTO := 250.0

var _vel: Label
var _unidad: Label
var _calle: Label
var _dist: Label
var _icono: Label
var _barra: ProgressBar
var _mostrar := false
var _t := 0.0
var _recorrido := 0.0

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	offset_left = -ANCHO - 30
	offset_right = -30
	offset_top = 40
	offset_bottom = 40 + ALTO
	rotation_degrees = -4.0
	pivot_offset = Vector2(ANCHO, ALTO)
	var carcasa := Panel.new()
	carcasa.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sc := StyleBoxFlat.new()
	sc.bg_color = Color(0.08, 0.08, 0.1)
	sc.set_corner_radius_all(22)
	sc.set_border_width_all(2)
	sc.border_color = Color(0.32, 0.33, 0.37)
	sc.shadow_color = Color(0, 0, 0, 0.5)
	sc.shadow_size = 14
	sc.shadow_offset = Vector2(0, 6)
	carcasa.add_theme_stylebox_override("panel", sc)
	carcasa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(carcasa)
	var pantalla := Panel.new()
	pantalla.set_anchors_preset(Control.PRESET_FULL_RECT)
	for k in ["left", "top", "right", "bottom"]:
		pantalla.set("offset_" + k, 6.0 if k in ["left", "top"] else -6.0)
	var sp := StyleBoxFlat.new()
	sp.bg_color = Color(0.05, 0.09, 0.08)
	sp.set_corner_radius_all(17)
	pantalla.add_theme_stylebox_override("panel", sp)
	pantalla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pantalla)
	var isla := Panel.new()
	isla.add_theme_stylebox_override("panel", _caja(Color.BLACK, 7))
	isla.position = Vector2(ANCHO * 0.5 - 24, 11)
	isla.size = Vector2(48, 13)
	add_child(isla)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 16
	v.offset_right = -16
	v.offset_top = 34
	v.offset_bottom = -16
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	_icono = _l(13, Color(0.55, 0.95, 0.7))
	v.add_child(_icono)
	_vel = _l(54, Color.WHITE)
	_vel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_vel)
	_unidad = _l(13, Color(1, 1, 1, 0.6))
	_unidad.text = "km/h"
	_unidad.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_unidad)
	_barra = ProgressBar.new()
	_barra.show_percentage = false
	_barra.custom_minimum_size = Vector2(0, 6)
	_barra.add_theme_stylebox_override("background", _caja(Color(1, 1, 1, 0.1), 3))
	_barra.add_theme_stylebox_override("fill", _caja(Color(0.35, 0.9, 0.6), 3))
	v.add_child(_barra)
	var hueco := Control.new()
	hueco.custom_minimum_size = Vector2(0, 8)
	v.add_child(hueco)
	_calle = _l(12, Color(1, 1, 1, 0.85))
	_calle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_calle)
	_dist = _l(12, Color(1, 0.85, 0.45))
	v.add_child(_dist)
	modulate.a = 0.0

func _l(tam: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func _caja(col: Color, r: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(r)
	return s

## `modo`: "pie", "correr", "coche", "tren". `maxima`: para la barra.
func poner(modo: String, km_h: float, maxima: float, calle: String, metros: float) -> void:
	_mostrar = modo in ["correr", "coche", "tren"]
	_vel.text = str(int(round(km_h)))
	_barra.max_value = maxima
	_barra.value = km_h
	_icono.text = Idiomas.t({"correr": "🏃 Carrera", "coche": "🚗 Conduciendo", "tren": "🚇 Metro"}.get(modo, "🚶 A pie"))
	_calle.text = ("📍 " + calle) if calle != "" else ""
	_recorrido += metros
	_dist.text = "%.2f km" % (_recorrido / 1000.0) if _recorrido >= 100.0 else "%d m" % int(_recorrido)

func _process(delta: float) -> void:
	_t += delta
	## Sube y baja suave, con un leve vaivén de la mano al correr.
	var objetivo := 1.0 if _mostrar else 0.0
	modulate.a = move_toward(modulate.a, objetivo, delta * 4.0)
	var baja := (1.0 - modulate.a) * 180.0
	position.y = get_parent_area_size().y - ALTO - 120.0 + baja + (sin(_t * 9.0) * 3.0 if _mostrar else 0.0)
	visible = modulate.a > 0.01
