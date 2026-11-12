class_name PieMando
extends PanelContainer
## EL PIE DE PANTALLA CON LAS AYUDAS DEL MANDO (12-11-2026, referencia del PES 2020 del dueño, `PLAN_GENERAL.md` punto 99 (3)):
## abajo del menú central, una fila con los botones que sirven AHORA y lo que hacen. Solo se ve con un mando conectado
## (`FocoMando.hay_mando`): con ratón, teclado o dedo no ocupa sitio. Cambia según el contexto: con el panel lateral abierto,
## LB/RB pasan de submenú y LT/RT de menú (`AtajosMenu`); en el central, LB/RB cambian de sección y LT/RT de bloque.
## Los nombres de los botones salen de `Mando.NOMBRE_BOTON` (los mismos que la pantalla de controles).

const CADA := 0.25   ## s entre comprobaciones (conectar o quitar el mando, abrir el panel)

## `lateral_abierto`: Callable() -> bool (el de Principal: ¿el panel lateral tapa el central?).
var lateral_abierto: Callable
var _fila: HBoxContainer
var _t := 0.0
var _clave := ""

static func crear(lateral: Callable) -> PieMando:
	var pie := PieMando.new()
	pie.lateral_abierto = lateral
	return pie

func _ready() -> void:
	name = "PieMando"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var e := StyleBoxFlat.new()
	e.bg_color = Color(0, 0, 0, 0.25)
	e.set_corner_radius_all(8)
	e.content_margin_left = 10; e.content_margin_right = 10
	e.content_margin_top = 3; e.content_margin_bottom = 3
	add_theme_stylebox_override("panel", e)
	_fila = HBoxContainer.new()
	_fila.alignment = BoxContainer.ALIGNMENT_END
	_fila.add_theme_constant_override("separation", 14)
	_fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fila)
	_actualizar()

func _process(d: float) -> void:
	_t += d
	if _t >= CADA:
		_t = 0.0
		_actualizar()

## Las ayudas del contexto actual: [[botones, qué hace], ...].
static func ayudas(con_lateral: bool) -> Array:
	var nb: Dictionary = Mando.NOMBRE_BOTON
	var l: Array = [[String(nb[JOY_BUTTON_A]), "Elegir"], [String(nb[JOY_BUTTON_B]), "Volver"]]
	var hombros := "%s/%s" % [nb[JOY_BUTTON_LEFT_SHOULDER], nb[JOY_BUTTON_RIGHT_SHOULDER]]
	if con_lateral:
		l.append([hombros, "Submenú"])
		l.append(["LT/RT", "Menú"])
	else:
		l.append([hombros, "Sección"])
		l.append(["LT/RT", "Bloque"])
	return l

func _actualizar() -> void:
	var hay := FocoMando.hay_mando()
	visible = hay
	if not hay:
		return
	var lat := lateral_abierto.is_valid() and bool(lateral_abierto.call())
	var clave := "%s|%s" % [lat, Idiomas.idioma]
	if clave == _clave:
		return
	_clave = clave
	for h: Node in _fila.get_children():
		h.free()
	for a: Array in ayudas(lat):
		_fila.add_child(_chip(String(a[0]), Idiomas.t(String(a[1]))))

static func _chip(boton: String, que: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 5)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p := PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = Tema.ORO
	e.set_corner_radius_all(9)
	e.content_margin_left = 6; e.content_margin_right = 6
	e.content_margin_top = 0; e.content_margin_bottom = 0
	p.add_theme_stylebox_override("panel", e)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b := Label.new()
	b.text = boton
	b.add_theme_font_size_override("font_size", 11)
	b.add_theme_color_override("font_color", Color("0c1510"))
	p.add_child(b)
	h.add_child(p)
	var t := Label.new()
	t.text = que
	t.add_theme_font_size_override("font_size", 12)
	t.add_theme_color_override("font_color", Tema.SUAVE)
	h.add_child(t)
	return h
