extends Control
## [Capa 1/2 de `idioma.gd`] LA CONSTRUCCIÓN de la pantalla de idioma: textos por
## idioma, fuentes, fondo, tarjetas, vista previa y ayudas. Aquí no hay lógica ni
## señales (eso vive en `idioma.gd`, que conecta las tarjetas tras construirlas).

const FONDO := preload("res://ui/entrada/idioma_fondo.gdshader")
const ORO := Color("e8c46a")
const TEXTO := Color("f3eee2")
const SUAVE := Color("a9b1c2")
const PANEL := Color(0.05, 0.065, 0.1, 0.78)
const TAM_TARJETA := Vector2(228, 150)
## Etiqueta corta de cada idioma bajo su nombre.
const ETIQUETAS := {"es": "ES", "en": "EN · UK", "pt": "PT · BR", "fr": "FR", "it": "IT",
	"de": "DE", "ca": "CA", "pl": "PL", "tr": "TR"}

## Segundos entre confirmar y emitir `terminado` (el cuadro se funde y la
## tarjeta elegida late). 0 = al momento.
var duracion_salida := 0.3

var _inicial := "es"
var _actual := "es"
var _puede_volver := true
var _foco := ""
var _textos: Dictionary = {}
var _tarjetas: Dictionary = {}
var _banderas: Dictionary = {}
var _confirmacion: ConfirmacionIdioma = null
var _cerrando := false
var _listo := false
var _mat_fondo: ShaderMaterial
var _fondo: ColorRect
var _serif: Font
var _serif_cursiva: Font
var _lbl_titulo: Label
var _lbl_vista: Label
var _lbl_nombre: Label
var _lbl_etiqueta: Label
var _lbl_saludo: Label
var _lbl_menus: Label
var _chips: HFlowContainer
var _bandera_grande: BanderaIdioma
var _vista: VBoxContainer
var _boton_volver: Button
var _pistas: Array[Label] = []

# --- textos ---------------------------------------------------------------------------

## Los textos de la pantalla en el idioma `c`. Se pone `Idiomas.idioma` un momento
## en `c`, se traduce con `Idiomas.t` (literales: la prueba de traducciones los ve)
## y se devuelve como estaba. Es síncrono: nadie llega a ver el cambio.
func _calcular_textos(c: String) -> Dictionary:
	var antes := Idiomas.idioma
	Idiomas.idioma = c
	var d := {
		"titulo": Idiomas.t("Elige tu idioma"),
		"saludo": Idiomas.t("Hola, míster. Hoy empieza tu dinastía."),
		"vista": Idiomas.mayusculas(Idiomas.t("Vista previa")),
		"menus": Idiomas.t("Así se verán los menús"),
		"chips": [Idiomas.t("Plantel"), Idiomas.t("Táctica"), Idiomas.t("Partido"), Idiomas.t("Cantera")],
		"pistas": [Idiomas.t("Moverse"), Idiomas.t("Elegir"), Idiomas.t("Volver")],
		"volver": Idiomas.t("Volver"),
		"pregunta": Idiomas.t("¿Quieres jugar en este idioma?"),
		"nota": Idiomas.t("Podrás cambiarlo cuando quieras en Ajustes."),
		"si": Idiomas.t("Sí, continuar"),
		"otro": Idiomas.t("Elegir otro"),
	}
	Idiomas.idioma = antes
	return d

func _fuente_serif(peso: int, cursiva: bool) -> Font:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Georgia", "Cambria", "Charter", "Bitstream Charter", "Liberation Serif", "DejaVu Serif", "serif"])
	f.font_weight = peso
	f.font_italic = cursiva
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	## Si la serif del sistema no tiene una letra (la «ğ» turca, la «ł» polaca),
	## la saca la fuente del juego en vez de un cuadradito.
	f.fallbacks = [ThemeDB.fallback_font]
	return f

# --- construcción ---------------------------------------------------------------------

func _construir() -> void:
	_fondo = ColorRect.new()
	_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat_fondo = ShaderMaterial.new()
	_mat_fondo.shader = FONDO
	_fondo.material = _mat_fondo
	add_child(_fondo)
	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado: String in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, 64)
	margen.add_theme_constant_override("margin_top", 34)
	margen.add_theme_constant_override("margin_bottom", 24)
	add_child(margen)
	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 0)
	margen.add_child(raiz)
	raiz.add_child(_cabecera())
	var cuerpo := HBoxContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 40)
	raiz.add_child(cuerpo)
	cuerpo.add_child(_columna_tarjetas())
	cuerpo.add_child(_vista_previa())
	raiz.add_child(_pie())

func _cabecera() -> Control:
	var fila := HBoxContainer.new()
	var marca := Label.new()
	var fv := FontVariation.new()
	fv.base_font = _fuente_serif(700, false)
	fv.spacing_glyph = 7
	marca.add_theme_font_override("font", fv)
	marca.add_theme_font_size_override("font_size", 15)
	marca.add_theme_color_override("font_color", ORO)
	marca.text = "DINASTÍA"
	fila.add_child(marca)
	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(hueco)
	_boton_volver = Button.new()
	_boton_volver.flat = true
	_boton_volver.focus_mode = Control.FOCUS_ALL
	_boton_volver.set_meta("sin_sonido", true)
	_boton_volver.add_theme_font_size_override("font_size", 14)
	for c: String in ["font_color", "font_hover_color", "font_focus_color"]:
		_boton_volver.add_theme_color_override(c, SUAVE if c == "font_color" else TEXTO)
	_boton_volver.visible = _puede_volver
	fila.add_child(_boton_volver)
	return fila

func _columna_tarjetas() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	_lbl_titulo = _etiqueta(44, TEXTO, _serif)
	col.add_child(_lbl_titulo)
	var raya := ColorRect.new()
	raya.color = Color(ORO, 0.8)
	raya.custom_minimum_size = Vector2(72, 2)
	raya.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(raya)
	var hueco := Control.new()
	hueco.custom_minimum_size = Vector2(0, 22)
	col.add_child(hueco)
	var rejilla := GridContainer.new()
	rejilla.columns = 3
	rejilla.add_theme_constant_override("h_separation", 14)
	rejilla.add_theme_constant_override("v_separation", 14)
	col.add_child(rejilla)
	for c: String in Idiomas.NOMBRES:
		rejilla.add_child(_tarjeta(c))
	return col

func _tarjeta(c: String) -> Button:
	var b := Button.new()
	b.name = "Tarjeta_" + c
	b.custom_minimum_size = TAM_TARJETA
	b.focus_mode = Control.FOCUS_ALL
	b.set_meta("sin_sonido", true)
	b.tooltip_text = ""
	var normal := _caja(PANEL, Color(1, 1, 1, 0.08), 1)
	var encima := _caja(PANEL.lightened(0.06), Color(1, 1, 1, 0.16), 1)
	var foco := _caja(Color(0, 0, 0, 0), ORO, 2)
	foco.draw_center = false
	foco.shadow_color = Color(ORO, 0.28)
	foco.shadow_size = 16
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", encima)
	b.add_theme_stylebox_override("pressed", _caja(PANEL.darkened(0.2), ORO, 1))
	b.add_theme_stylebox_override("focus", foco)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var bandera := BanderaIdioma.new(c, Vector2i(300, 200))
	bandera.custom_minimum_size = Vector2(136, 90)
	bandera.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bandera.fuerza = 0.18
	v.add_child(bandera)
	_banderas[c] = bandera
	var nombre := _etiqueta(19, TEXTO, _serif)
	nombre.text = String((Idiomas.NOMBRES[c] as Array)[0])
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nombre)
	var tag := _etiqueta(10, SUAVE)
	tag.text = String(ETIQUETAS.get(c, c.to_upper()))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tag)
	if c == _actual:
		## El que está puesto ahora: un punto dorado en la esquina.
		var punto := _etiqueta(12, ORO)
		punto.text = "●"
		punto.position = Vector2(TAM_TARJETA.x - 22, 6)
		punto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(punto)
	_tarjetas[c] = b
	return b

func _vista_previa() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(350, 0)
	var caja := _caja(Color(0.04, 0.05, 0.08, 0.72), Color(1, 1, 1, 0.07), 1)
	caja.set_corner_radius_all(18)
	caja.content_margin_left = 30
	caja.content_margin_right = 30
	caja.content_margin_top = 24
	caja.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", caja)
	_vista = VBoxContainer.new()
	_vista.add_theme_constant_override("separation", 6)
	panel.add_child(_vista)
	_lbl_vista = _etiqueta(11, SUAVE)
	_vista.add_child(_lbl_vista)
	_bandera_grande = BanderaIdioma.new(_inicial, Vector2i(540, 360))
	_bandera_grande.custom_minimum_size = Vector2(290, 193)
	_bandera_grande.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_bandera_grande.fuerza = 0.7
	_vista.add_child(_bandera_grande)
	_lbl_nombre = _etiqueta(32, TEXTO, _serif)
	_vista.add_child(_lbl_nombre)
	_lbl_etiqueta = _etiqueta(11, ORO)
	_vista.add_child(_lbl_etiqueta)
	var hueco := Control.new()
	hueco.custom_minimum_size = Vector2(0, 6)
	_vista.add_child(hueco)
	_lbl_saludo = _etiqueta(21, Color(TEXTO, 0.92), _serif_cursiva)
	_lbl_saludo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vista.add_child(_lbl_saludo)
	var raya := ColorRect.new()
	raya.color = Color(1, 1, 1, 0.08)
	raya.custom_minimum_size = Vector2(0, 1)
	_vista.add_child(raya)
	_lbl_menus = _etiqueta(12, SUAVE)
	_vista.add_child(_lbl_menus)
	_chips = HFlowContainer.new()
	_chips.add_theme_constant_override("h_separation", 6)
	_chips.add_theme_constant_override("v_separation", 6)
	_vista.add_child(_chips)
	return panel

func _pie() -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 26)
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	for teclas: String in ["← ↑ ↓ →", "↵  ·  A", "Esc  ·  B"]:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var tecla := PanelContainer.new()
		var e := _caja(Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.22), 1)
		e.set_corner_radius_all(6)
		e.content_margin_left = 8
		e.content_margin_right = 8
		e.content_margin_top = 2
		e.content_margin_bottom = 2
		tecla.add_theme_stylebox_override("panel", e)
		var lt := _etiqueta(12, TEXTO)
		lt.text = teclas
		tecla.add_child(lt)
		h.add_child(tecla)
		var texto := _etiqueta(13, SUAVE)
		h.add_child(texto)
		_pistas.append(texto)
		fila.add_child(h)
	return fila

func _chip(texto: String, activo: bool) -> Control:
	var p := PanelContainer.new()
	var e := _caja(Color(Tema.ACENTO, 0.85 if activo else 0.16), Color(Tema.ACENTO, 0.9), 1)
	e.set_corner_radius_all(6)
	e.content_margin_left = 12
	e.content_margin_right = 12
	e.content_margin_top = 4
	e.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", e)
	var l := _etiqueta(13, Color.WHITE if activo else TEXTO)
	l.text = texto
	p.add_child(l)
	return p

func _etiqueta(tam: int, color: Color, fuente: Font = null) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	if fuente != null:
		l.add_theme_font_override("font", fuente)
	return l

func _caja(fondo: Color, borde: Color, grosor: int) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = fondo
	e.border_color = borde
	e.set_border_width_all(grosor)
	e.set_corner_radius_all(12)
	return e
