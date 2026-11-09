class_name EventoPantallaCompleta
extends CanvasLayer
## BASE DE LOS EVENTOS A PANTALLA COMPLETA (regla del dueño, 9-11): los eventos (aviso del partido de despedida, homenaje…) ocupan TODA la pantalla, con fondo
## propio opaco, y solo se inician al llegar a su fecha (nunca al abrir un menú). Aquí: el fondo (degradado verde con filetes dorados y viñeta), el fundido de
## entrada y los ayudantes de texto y botón con la paleta del juego (`Tema`: verde y dorado). Cada evento hereda y rellena `_centro` (un VBox centrado).
signal elegido(op: String)
signal terminado

var _centro: VBoxContainer
var _raiz: Control

func _init() -> void:
	layer = 58

## Crea el fondo y devuelve el VBox central donde va el contenido. Se llama una vez desde `mostrar` de cada evento.
func _montar_base(pr: Node) -> void:
	pr.add_child(self)
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP   ## nada de lo de debajo recibe clics
	add_child(_raiz)
	var fondo := ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.color = Tema.FONDO
	_raiz.add_child(fondo)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.10, 0.20, 0.13, 1.0))
	grad.set_color(1, Color(0.03, 0.06, 0.04, 1.0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.4)
	gt.fill_to = Vector2(1.1, 1.0)
	var luz := TextureRect.new()
	luz.texture = gt
	luz.set_anchors_preset(Control.PRESET_FULL_RECT)
	luz.stretch_mode = TextureRect.STRETCH_SCALE
	luz.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	luz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(luz)
	for arriba: bool in [true, false]:   ## los dos filetes dorados
		var f := ColorRect.new()
		f.color = Tema.ORO
		f.set_anchors_preset(Control.PRESET_TOP_WIDE if arriba else Control.PRESET_BOTTOM_WIDE)
		f.offset_top = 36 if arriba else -40
		f.offset_bottom = 38 if arriba else -38
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_raiz.add_child(f)
	var desliza := ScrollContainer.new()   ## entre los dos filetes; si el contenido no cabe (pantalla pequeña) se desliza en vez de salirse
	desliza.set_anchors_preset(Control.PRESET_FULL_RECT)
	desliza.offset_top = 46
	desliza.offset_bottom = -50
	desliza.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_raiz.add_child(desliza)
	var centro := CenterContainer.new()
	centro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desliza.add_child(centro)
	_centro = VBoxContainer.new()
	_centro.add_theme_constant_override("separation", 12)
	_centro.custom_minimum_size = Vector2(760, 0)
	centro.add_child(_centro)
	_raiz.modulate.a = 0.0   ## fundido de entrada
	create_tween().tween_property(_raiz, "modulate:a", 1.0, 0.45)

static func etiqueta(texto: String, tam: int, color: Color, centrada := true, ajustar := true) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", Tema.letra(tam))   ## respeta la escala de texto de Ajustes
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	l.add_theme_constant_override("outline_size", 4)
	if ajustar:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if centrada:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

## Un botón grande; `principal` lo destaca con el borde dorado y el fondo dorado tenue. En foco (mando) y al pasar el cursor se ve más claro y con borde dorado grueso;
## el botón principal toma el foco al aparecer, para poder confirmar con el mando sin tocar nada.
static func boton(texto: String, principal := false) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(0, 58)
	b.add_theme_font_size_override("font_size", Tema.letra(20))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(Tema.ORO, 0.22) if principal else Color(1, 1, 1, 0.06)
	normal.border_color = Tema.ORO if principal else Color(1, 1, 1, 0.25)
	normal.set_border_width_all(2 if principal else 1)
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(12)
	var resalte := normal.duplicate() as StyleBoxFlat
	resalte.bg_color = Color(Tema.ORO, 0.38) if principal else Color(1, 1, 1, 0.14)
	resalte.border_color = Tema.ORO
	resalte.set_border_width_all(3)
	b.add_theme_stylebox_override("normal", normal)
	for estado in ["hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(estado, resalte)
	if principal:
		b.call_deferred("grab_focus")
	return b
