class_name PlantillaPes
extends RefCounted
## LA PLANTILLA A LA PES (9-11; orden del líder y ejemplos del dueño: «Estrategia» y «Opción de entrenamiento»), con la paleta del juego (verde y dorado,
## `Tema`), no la morada del PES. Tres columnas: el CAMPO con la formación y los once (cada uno con su nota y la etiqueta de su línea), la LISTA con
## etiquetas de posición de colores y nota (titulares y reservas) y, a la derecha, la INFORMACIÓN del elegido: retrato, nota grande, radar y datos.
## «⚖ Comparar» enseña a un segundo jugador al lado y la diferencia de cada atributo. Es de lectura: el once se cambia en «Mi plantel».
const ATR_CAMPO := ["rit", "tir", "pas", "reg", "def", "fis"]
const ATR_PORTERO := ["div", "par", "saq", "ref", "vel", "pos"]
const ANCHO_CAMPO := 340.0
const ALTO_CAMPO := 470.0

var _p: Principal
var _club: Club
var _capa: CanvasLayer
var _campo: Control
var _lista: VBoxContainer
var _info: VBoxContainer
var _a: Jugador = null
var _b: Jugador = null
var _comparando := false
var _titulares: Array[Jugador] = []

static func abrir(p: Principal) -> PlantillaPes:
	var club := p.mundo.mi_club() if p.mundo != null else null
	if club == null or club.plantilla.is_empty():
		return null
	var v := PlantillaPes.new()
	v._p = p
	v._club = club
	v._montar()
	return v

## Los atributos que se enseñan, según sea portero o de campo.
static func claves_de(j: Jugador) -> Array:
	return ATR_PORTERO if j.pos == "POR" else ATR_CAMPO

## Diferencia de un atributo entre A y B (positiva = A mejor).
static func diferencia(a: Jugador, b: Jugador, clave: String) -> int:
	return int(a.atributos.get(clave, 0)) - int(b.atributos.get(clave, 0))

static func color_de(j: Jugador) -> Color:
	return Tema.POS.get(j.pos, Tema.SUAVE)

func _panel(ancho: float) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(ancho, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Tema.PANEL
	sb.border_color = Color(Tema.ORO, 0.55)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	pc.add_theme_stylebox_override("panel", sb)
	return pc

func _etiqueta(texto: String, tam: int, color: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l

func _montar() -> void:
	_titulares = _club.once()
	_capa = CanvasLayer.new()
	_capa.layer = 56
	_p.add_child(_capa)
	var fondo := ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.color = Tema.FONDO
	_capa.add_child(fondo)
	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 20
	raiz.offset_right = -20
	raiz.offset_top = 14
	raiz.offset_bottom = -12
	_capa.add_child(raiz)
	raiz.add_child(_etiqueta("%s · %s · %s" % [Idiomas.t("PLANTILLA"), _club.nombre, _club.tactica.formacion], 22, Tema.ORO))
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 12)
	raiz.add_child(cols)
	var pc := _panel(ANCHO_CAMPO + 16)
	cols.add_child(pc)
	_campo = Control.new()
	_campo.custom_minimum_size = Vector2(ANCHO_CAMPO, ALTO_CAMPO)
	_campo.draw.connect(_dibujar_campo)
	pc.add_child(_campo)
	var pl := _panel(330)
	cols.add_child(pl)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pl.add_child(scroll)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_lista)
	var pi := _panel(300)
	pi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(pi)
	_info = VBoxContainer.new()
	pi.add_child(_info)
	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 10)
	raiz.add_child(pie)
	var comp := Button.new()
	comp.toggle_mode = true
	comp.text = Idiomas.t("⚖ Comparar")
	comp.toggled.connect(func(on: bool) -> void:
		_comparando = on
		_b = null
		_pintar())
	pie.add_child(comp)
	var ayuda := _etiqueta(Idiomas.t("Elige un jugador de la lista · con «Comparar» el segundo clic es el rival de la comparación"), 12, Tema.SUAVE)
	ayuda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pie.add_child(ayuda)
	var cerrar := Button.new()
	cerrar.text = Idiomas.t("Cerrar")
	cerrar.pressed.connect(_capa.queue_free)
	pie.add_child(cerrar)
	_a = _titulares[0] if not _titulares.is_empty() else _club.plantilla[0]
	_pintar()

## El césped con sus rayas, las líneas y el área, dibujados en el control del campo.
func _dibujar_campo() -> void:
	var w := ANCHO_CAMPO
	var h := ALTO_CAMPO
	for k in 8:
		_campo.draw_rect(Rect2(0, h * k / 8.0, w, h / 8.0), Color(0.16, 0.40, 0.22) if k % 2 == 0 else Color(0.18, 0.45, 0.25))
	var linea := Color(1, 1, 1, 0.55)
	_campo.draw_rect(Rect2(6, 6, w - 12, h - 12), linea, false, 2.0)
	_campo.draw_line(Vector2(6, h / 2.0), Vector2(w - 6, h / 2.0), linea, 2.0)
	_campo.draw_arc(Vector2(w / 2.0, h / 2.0), 42.0, 0.0, TAU, 40, linea, 2.0)
	_campo.draw_rect(Rect2(w * 0.22, 6, w * 0.56, h * 0.15), linea, false, 2.0)
	_campo.draw_rect(Rect2(w * 0.22, h - 6 - h * 0.15, w * 0.56, h * 0.15), linea, false, 2.0)

func _pintar() -> void:
	for h in _campo.get_children():
		h.queue_free()
	for h in _lista.get_children():
		h.queue_free()
	for h in _info.get_children():
		h.queue_free()
	var forms: Dictionary = Datos.tabla("FORMS")
	var ranuras: Array = (forms.get(_club.tactica.formacion, forms.get("4-3-3", {})) as Dictionary).get("s", [])
	for i in mini(ranuras.size(), _titulares.size()):
		_campo.add_child(_ficha_campo(_titulares[i], ranuras[i]))
	_campo.queue_redraw()
	_lista.add_child(_etiqueta(Idiomas.t("TITULARES"), 12, Tema.ORO))
	for j: Jugador in _titulares:
		_lista.add_child(_fila(j))
	_lista.add_child(_etiqueta(Idiomas.t("RESERVAS"), 12, Tema.ORO))
	var reservas: Array = _club.plantilla.filter(func(j: Jugador) -> bool: return not _titulares.has(j))
	reservas.sort_custom(func(x: Jugador, y: Jugador) -> bool: return x.ovr > y.ovr)
	for j: Jugador in reservas:
		_lista.add_child(_fila(j))
	_pintar_info()

func _elegir(j: Jugador) -> void:
	if _comparando and _a != null and j != _a:
		_b = j
	else:
		_a = j
		_b = null
	_pintar()

## Un titular sobre el campo: nota y apellido, con el color de su línea y borde dorado si es el elegido.
func _ficha_campo(j: Jugador, ranura: Array) -> Button:
	var b := Button.new()
	var apellido := j.nombre.split(" ")[-1]
	b.text = "%d\n%s" % [j.ovr, apellido.left(9)]
	b.add_theme_font_size_override("font_size", 11)
	b.custom_minimum_size = Vector2(66, 40)
	b.size = Vector2(66, 40)
	b.position = Vector2(float(ranura[1]) / 100.0 * ANCHO_CAMPO - 33.0, float(ranura[2]) / 100.0 * ALTO_CAMPO - 20.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color_de(j), 0.85)
	sb.set_corner_radius_all(5)
	sb.border_color = Tema.ORO if (j == _a or j == _b) else Color(0, 0, 0, 0.4)
	sb.set_border_width_all(3 if (j == _a or j == _b) else 1)
	for estado in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(estado, sb)
	b.pressed.connect(func() -> void: _elegir(j))
	return b

## Una fila de la lista: etiqueta de posición de color, nombre y nota (como la lista de «Estrategia» del PES).
func _fila(j: Jugador) -> Button:
	var b := Button.new()
	b.flat = true
	b.custom_minimum_size = Vector2(0, 30)
	var fila := HBoxContainer.new()
	fila.set_anchors_preset(Control.PRESET_FULL_RECT)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_theme_constant_override("separation", 8)
	b.add_child(fila)
	var tag := PanelContainer.new()
	tag.custom_minimum_size = Vector2(44, 0)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = color_de(j)
	sb.set_corner_radius_all(3)
	tag.add_theme_stylebox_override("panel", sb)
	var t := _etiqueta(j.pos_e, 11, Color.WHITE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_child(t)
	fila.add_child(tag)
	var nombre := _etiqueta(j.nombre, 13, Tema.ORO if (j == _a or j == _b) else Tema.TEXTO)
	nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nombre.clip_text = true
	fila.add_child(nombre)
	fila.add_child(_etiqueta(str(j.ovr), 14, Tema.TEXTO))
	b.pressed.connect(func() -> void: _elegir(j))
	return b

func _pintar_info() -> void:
	if _a == null:
		return
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 10)
	_info.add_child(cab)
	var retrato := _p._retrato(_a, 110)
	cab.add_child(retrato)
	var datos := VBoxContainer.new()
	cab.add_child(datos)
	datos.add_child(_etiqueta(_a.nombre, 16, Tema.ORO))
	datos.add_child(_etiqueta("#%d · %s" % [_a.dorsal, _a.pos_e], 13, Tema.SUAVE))
	datos.add_child(_etiqueta(str(_a.ovr), 36, Tema.ORO))
	var radar := RadarAtributos.new()
	radar.custom_minimum_size = Vector2(240, 190)
	var etq := PackedStringArray()
	var vals := PackedFloat32Array()
	for k: String in claves_de(_a):
		etq.append(Idiomas.t(String(Principal.NOMBRES_ATRIBUTOS.get(k, k))).left(5))
		vals.append(float(_a.atributos.get(k, 0)))
	radar.poner(etq, vals, Tema.ACENTO)
	_info.add_child(radar)
	for k: String in claves_de(_a):
		_info.add_child(_fila_atributo(k))
	_info.add_child(_etiqueta("%s %d · %s %d%% · %s %d%% · %s %d%%" % [Idiomas.t("Edad"), _a.edad, Idiomas.t("Forma"), _a.forma,
		Idiomas.t("Moral"), _a.moral, Idiomas.t("Físico"), _a.fisico], 12, Tema.SUAVE))
	if _a.lesion > 0:
		_info.add_child(_etiqueta("🩹 %s %d" % [Idiomas.t("Lesionado, semanas:"), _a.lesion], 12, Tema.MAL))

func _fila_atributo(clave: String) -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	var nombre := _etiqueta(Idiomas.t(String(Principal.NOMBRES_ATRIBUTOS.get(clave, clave))), 12, Tema.TEXTO)
	nombre.custom_minimum_size = Vector2(80, 0)
	fila.add_child(nombre)
	var barra := ProgressBar.new()
	barra.show_percentage = false
	barra.max_value = 100.0
	barra.value = float(_a.atributos.get(clave, 0))
	barra.custom_minimum_size = Vector2(90, 10)
	barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(barra)
	fila.add_child(_etiqueta(str(int(_a.atributos.get(clave, 0))), 12, Tema.TEXTO))
	if _b != null:
		var d := diferencia(_a, _b, clave)
		fila.add_child(_etiqueta(str(int(_b.atributos.get(clave, 0))), 12, Tema.SUAVE))
		fila.add_child(_etiqueta(("%+d" % d) if d != 0 else "=", 12, Tema.BIEN if d > 0 else (Tema.MAL if d < 0 else Tema.NEUTRO)))
	return fila
