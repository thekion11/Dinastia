class_name CuadroDialogo
extends CanvasLayer
## CUADRO DE DIÁLOGO (13-10-2026): sustituye al texto flotante sobre la cabeza.
## Panel inferior translúcido con placa del nombre en el color del hablante,
## texto que se escribe letra a letra, puntos de turno y aviso para seguir.
## Uso: dialogo.decir("El hincha", "Tengo el abono…", Color, turno, total)

const VELOCIDAD := 55.0  ## letras por segundo

var _panel: PanelContainer
var _placa: PanelContainer
var _nombre: Label
var _texto: RichTextLabel
var _puntos: Label
var _aviso: Label
var _visibles := 0.0
var _t := 0.0

func _init() -> void:
	layer = 40
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -330
	_panel.offset_right = 330
	_panel.offset_top = -240
	_panel.offset_bottom = -110
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.1, 0.86)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1, 0.12)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 12
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", sb)
	raiz.add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	_panel.add_child(col)
	_texto = RichTextLabel.new()
	_texto.bbcode_enabled = false
	_texto.fit_content = true
	_texto.scroll_active = false
	_texto.add_theme_font_size_override("normal_font_size", Tema.letra(19))
	_texto.add_theme_color_override("default_color", Color(0.95, 0.95, 0.93))
	_texto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_texto)
	var pie := HBoxContainer.new()
	col.add_child(pie)
	_puntos = Label.new()
	_puntos.add_theme_font_size_override("font_size", Tema.letra(13))
	_puntos.modulate = Color(1, 1, 1, 0.55)
	_puntos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pie.add_child(_puntos)
	_aviso = Label.new()
	_aviso.text = _tecla_seguir()
	_aviso.add_theme_font_size_override("font_size", Tema.letra(13))
	_aviso.modulate = Color(1, 0.85, 0.4)
	pie.add_child(_aviso)
	## Placa del nombre: primera fila del panel, ajustada al texto.
	_placa = PanelContainer.new()
	_placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_placa.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(_placa)
	col.move_child(_placa, 0)
	_nombre = Label.new()
	_nombre.add_theme_font_size_override("font_size", Tema.letra(15))
	_nombre.add_theme_color_override("font_color", Color(0.05, 0.05, 0.07))
	_placa.add_child(_nombre)
	visible = false

func decir(quien: String, frase: String, color := Color(1.0, 0.8, 0.35), turno := 0, total := 1) -> void:
	var sp := StyleBoxFlat.new()
	sp.bg_color = color
	sp.set_corner_radius_all(8)
	sp.content_margin_left = 12
	sp.content_margin_right = 12
	sp.content_margin_top = 3
	sp.content_margin_bottom = 3
	_placa.add_theme_stylebox_override("panel", sp)
	_nombre.text = quien
	_texto.text = frase
	_texto.visible_characters = 0
	_visibles = 0.0
	var p := ""
	for i in total:
		p += "● " if i == turno else "○ "
	_puntos.text = p.strip_edges() if total > 1 else ""
	_aviso.visible = false
	## Se mira en cada frase: el mando puede enchufarse a media conversación.
	_aviso.text = _tecla_seguir()
	_t = 0.0
	visible = true

## Qué tecla pide el «sigue»: la E del teclado o, con un mando enchufado, la X
## (los exploradores de ciudad y estadio avanzan con JOY_BUTTON_X). Antes
## ponía siempre «E», que con mando no dice nada.
static func _tecla_seguir() -> String:
	if Mando.hay_mando():
		return "%s ▸" % String(Mando.NOMBRE_BOTON.get(JOY_BUTTON_X, "X"))
	return "E ▸"

func cerrar() -> void:
	visible = false

## True si el texto aún se está escribiendo (E lo completa en vez de pasar).
func escribiendo() -> bool:
	return visible and _texto.visible_characters >= 0 and _texto.visible_characters < _texto.text.length()

func completar() -> void:
	_texto.visible_characters = -1
	_aviso.visible = true

func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if _texto.visible_characters >= 0:
		_visibles += delta * VELOCIDAD
		_texto.visible_characters = int(_visibles)
		if _texto.visible_characters >= _texto.text.length():
			completar()
	## El aviso parpadea suave para invitar a seguir.
	_aviso.modulate.a = 0.6 + 0.4 * sin(_t * 4.0)

# --- piezas compartidas: el mismo aspecto en la ciudad, el estadio y los interiores ---

static func estilo_panel() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.1, 0.9)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1, 0.12)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 12
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 12
	sb.content_margin_bottom = 14
	return sb

static func placa(texto: String, color := Color(1.0, 0.8, 0.35)) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var sp := StyleBoxFlat.new()
	sp.bg_color = color
	sp.set_corner_radius_all(8)
	sp.content_margin_left = 12
	sp.content_margin_right = 12
	sp.content_margin_top = 3
	sp.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", sp)
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", Tema.letra(15))
	l.add_theme_color_override("font_color", Color(0.05, 0.05, 0.07))
	p.add_child(l)
	return p

## Botón de respuesta: píldora oscura con borde que se ilumina al pasar.
## FOCO PARA MANDO (25-10-2026, uitm): el foco era idéntico al «pasar el
## ratón» -borde dorado de 1 px- y con mando no se distinguía bien cuál está
## elegida. Ahora el foco lleva el borde de 2 px y opaco. Los márgenes
## interiores son fijos, así que el botón no cambia de tamaño.
static func respuesta(b: Button) -> Button:
	for estado in ["normal", "hover", "pressed", "disabled", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(18)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		sb.set_border_width_all(1)
		sb.bg_color = Color(1, 1, 1, 0.06 if estado == "normal" else (0.16 if estado != "disabled" else 0.02))
		sb.border_color = Color(1, 0.85, 0.4, 0.8) if estado in ["hover", "focus"] else Color(1, 1, 1, 0.18)
		if estado == "focus":
			## El de foco se dibuja ENCIMA del estado actual: un velo claro
			## suave (como antes) más el borde fuerte.
			sb.bg_color = Color(1, 1, 1, 0.1)
			sb.border_color = Color(1, 0.85, 0.4, 1.0)
			sb.set_border_width_all(2)
		b.add_theme_stylebox_override(estado, sb)
	b.add_theme_font_size_override("font_size", Tema.letra(15))
	return b

## Escribe el texto de una etiqueta letra a letra.
static func escribir(l: Label, texto: String) -> void:
	l.text = texto
	l.visible_ratio = 0.0
	var tw := l.create_tween()
	tw.tween_property(l, "visible_ratio", 1.0, clampf(texto.length() / VELOCIDAD, 0.2, 2.5))
