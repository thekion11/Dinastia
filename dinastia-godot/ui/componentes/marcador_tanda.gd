class_name MarcadorTanda
extends PanelContainer
## EL MARCADOR DE LA TANDA (17-10-2026), como en la tele: arriba al centro,
## una fila por equipo con un círculo por lanzamiento (verde = dentro, rojo =
## fallado, hueco = por tirar) y el total. Cinco huecos de base; en la muerte
## súbita van apareciendo más. El equipo que tira ahora lleva el ▶.

const VERDE := "4caf6d"
const ROJO := "e05555"
const HUECO := "6c7a72"

var _titulo: Label
var _filas: Array[RichTextLabel] = []

static func crear(padre: Control) -> MarcadorTanda:
	var m := MarcadorTanda.new()
	padre.add_child(m)
	return m

func _ready() -> void:
	var e := StyleBoxFlat.new()
	e.bg_color = Color(0.03, 0.05, 0.04, 0.82)
	e.border_width_top = 3
	e.border_color = Color("c9a227")
	e.set_corner_radius_all(8)
	e.content_margin_left = 18; e.content_margin_right = 18
	e.content_margin_top = 8; e.content_margin_bottom = 10
	add_theme_stylebox_override("panel", e)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -190
	offset_right = 190
	## Debajo del marcador y de los rótulos de la tele (que van arriba).
	offset_top = 74
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 2)
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caja)
	_titulo = Label.new()
	_titulo.text = "🥅 " + Idiomas.t("TANDA DE PENALES")
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.add_theme_font_size_override("font_size", 14)
	_titulo.add_theme_color_override("font_color", Color("c9a227"))
	caja.add_child(_titulo)
	for i in 2:
		var f := RichTextLabel.new()
		f.bbcode_enabled = true
		f.fit_content = true
		f.scroll_active = false
		f.autowrap_mode = TextServer.AUTOWRAP_OFF
		f.custom_minimum_size = Vector2(340, 0)
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		f.add_theme_font_size_override("normal_font_size", 20)
		f.add_theme_font_size_override("bold_font_size", 20)
		caja.add_child(f)
		_filas.append(f)

## Los círculos de un equipo: "●●○●○" con colores, como texto BBCode.
static func circulos(tiros: Array, huecos: int) -> String:
	var s := ""
	for b: bool in tiros:
		s += "[color=#%s]●[/color] " % (VERDE if b else ROJO)
	for _i in maxi(huecos - tiros.size(), 0):
		s += "[color=#%s]○[/color] " % HUECO
	return s.strip_edges()

## `tiros`: [[bool…], [bool…]] del motor; `turno`: el equipo que tira (-1 nadie).
func pintar(nombre_local: String, nombre_visita: String, tiros: Array, turno: int) -> void:
	if _filas.is_empty():
		return
	var huecos := maxi(5, maxi((tiros[0] as Array).size(), (tiros[1] as Array).size()))
	for i in 2:
		var t: Array = tiros[i]
		var goles := 0
		for b: bool in t:
			goles += 1 if b else 0
		var nombre := nombre_local if i == 0 else nombre_visita
		_filas[i].text = "%s[b]%s[/b]  %s   [b]%d[/b]" % [
			"[color=#c9a227]▶[/color] " if i == turno else "    ", nombre, circulos(t, huecos), goles]
