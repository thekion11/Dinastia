class_name PlantillaPes
extends RefCounted
## LA PLANTILLA A LA PES (9-11, idea del PES 2020 que le gusta al dueño; orden del líder: «menú de plantilla estilo PES»). Tres columnas sobre
## un fondo con el color del club: a la IZQUIERDA la lista por líneas con una barra de nota (★ = en el once), en el CENTRO los atributos del
## elegido en barras y, a la DERECHA, su retrato, número y estado. «Comparar» pone a otro jugador al lado y marca la diferencia de cada atributo.
## Se abre desde Plantel → «Plantilla (vista PES)». Todo es de lectura: no cambia el once (eso sigue en «Mi plantel»).
const LINEAS := [["POR", "Porteros"], ["DEF", "Defensas"], ["MED", "Mediocampistas"], ["DEL", "Delanteros"]]
const ATR_CAMPO := ["rit", "tir", "pas", "reg", "def", "fis"]
const ATR_PORTERO := ["div", "par", "saq", "ref", "vel", "pos"]

var _p: Principal
var _club: Club
var _capa: CanvasLayer
var _centro: VBoxContainer
var _derecha: VBoxContainer
var _a: Jugador = null
var _b: Jugador = null
var _comparando := false
var _btn_comparar: Button

static func abrir(p: Principal) -> PlantillaPes:
	var club := p.mundo.mi_club() if p.mundo != null else null
	if club == null or club.plantilla.is_empty():
		return null
	var v := PlantillaPes.new()
	v._p = p
	v._club = club
	v._montar()
	return v

## La nota para pintar la barra (portero o de campo): la media del jugador.
static func nota(j: Jugador) -> int:
	return j.ovr

## Los atributos que se enseñan, según sea portero o de campo.
static func claves_de(j: Jugador) -> Array:
	return ATR_PORTERO if j.pos == "POR" else ATR_CAMPO

## Diferencia de un atributo entre A y B (positiva = A mejor).
static func diferencia(a: Jugador, b: Jugador, clave: String) -> int:
	return int(a.atributos.get(clave, 0)) - int(b.atributos.get(clave, 0))

func _montar() -> void:
	_capa = CanvasLayer.new()
	_capa.layer = 56
	_p.add_child(_capa)
	var fondo := ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(_club.color1).lerp(Color(0.06, 0.07, 0.1), 0.85)
	_capa.add_child(fondo)
	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 24
	raiz.offset_right = -24
	raiz.offset_top = 16
	raiz.offset_bottom = -12
	_capa.add_child(raiz)
	var titulo := Label.new()
	titulo.text = "%s · %s" % [Idiomas.t("PLANTILLA"), _club.nombre]
	titulo.add_theme_font_size_override("font_size", 22)
	raiz.add_child(titulo)
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 14)
	raiz.add_child(cols)
	cols.add_child(_columna_lista())
	_centro = VBoxContainer.new()
	_centro.custom_minimum_size = Vector2(330, 0)
	cols.add_child(_centro)
	_derecha = VBoxContainer.new()
	_derecha.custom_minimum_size = Vector2(260, 0)
	_derecha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(_derecha)
	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 10)
	raiz.add_child(pie)
	_btn_comparar = Button.new()
	_btn_comparar.toggle_mode = true
	_btn_comparar.text = Idiomas.t("⚖ Comparar")
	_btn_comparar.toggled.connect(func(on: bool) -> void:
		_comparando = on
		_b = null
		_pintar())
	pie.add_child(_btn_comparar)
	var ayuda := Label.new()
	ayuda.text = Idiomas.t("Elige un jugador de la lista · con «Comparar» el segundo clic es el rival de la comparación")
	ayuda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ayuda.add_theme_font_size_override("font_size", 12)
	pie.add_child(ayuda)
	var cerrar := Button.new()
	cerrar.text = Idiomas.t("Cerrar")
	cerrar.pressed.connect(_capa.queue_free)
	pie.add_child(cerrar)
	_a = _club.plantilla[0]
	_pintar()

func _columna_lista() -> Control:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(340, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(lista)
	for linea: Array in LINEAS:
		var cab := Label.new()
		cab.text = Idiomas.t(String(linea[1])).to_upper()
		cab.add_theme_font_size_override("font_size", 12)
		cab.add_theme_color_override("font_color", Color(String(_club.color2)))
		lista.add_child(cab)
		var jugs: Array = _club.plantilla.filter(func(j: Jugador) -> bool: return j.pos == String(linea[0]))
		jugs.sort_custom(func(x: Jugador, y: Jugador) -> bool: return x.ovr > y.ovr)
		for j: Jugador in jugs:
			lista.add_child(_fila(j))
	return scroll

func _fila(j: Jugador) -> Button:
	var b := Button.new()
	b.flat = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, 30)
	var estrella := "★ " if _club.once_elegido.has(j.id) else "   "
	b.text = "%s%-4s %s   %d" % [estrella, j.pos_e, j.nombre, j.ovr]
	var barra := ProgressBar.new()
	barra.show_percentage = false
	barra.max_value = 100.0
	barra.value = float(nota(j))
	barra.custom_minimum_size = Vector2(0, 4)
	barra.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	barra.offset_top = -4
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(barra)
	b.pressed.connect(func() -> void:
		if _comparando and _a != null and j != _a:
			_b = j
		else:
			_a = j
			_b = null
		_pintar())
	return b

func _pintar() -> void:
	for h in _centro.get_children():
		h.queue_free()
	for h in _derecha.get_children():
		h.queue_free()
	if _a == null:
		return
	var enc := Label.new()
	enc.text = _a.nombre if _b == null else "%s  ⚖  %s" % [_a.nombre, _b.nombre]
	enc.add_theme_font_size_override("font_size", 16)
	_centro.add_child(enc)
	for clave: String in claves_de(_a):
		_centro.add_child(_fila_atributo(clave))
	## La derecha: retrato, número y estado.
	var retrato := _p._retrato(_a, 200)
	retrato.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_derecha.add_child(retrato)
	var datos := Label.new()
	datos.text = "#%d  %s · %s\n%s %d   %s %d\n%s %d%%   %s %d%%   %s %d%%" % [_a.dorsal, _a.nombre, _a.pos_e,
		Idiomas.t("Edad"), _a.edad, Idiomas.t("Nota"), _a.ovr,
		Idiomas.t("Forma"), _a.forma, Idiomas.t("Moral"), _a.moral, Idiomas.t("Físico"), _a.fisico]
	datos.add_theme_font_size_override("font_size", 14)
	_derecha.add_child(datos)
	if _b != null:   ## el segundo jugador de la comparación, debajo
		var rb := _p._retrato(_b, 110)
		rb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_derecha.add_child(rb)
		var db := Label.new()
		db.text = "#%d  %s · %s   %s %d" % [_b.dorsal, _b.nombre, _b.pos_e, Idiomas.t("Nota"), _b.ovr]
		_derecha.add_child(db)
	if _a.lesion > 0:
		var les := Label.new()
		les.text = "🩹 %s %d" % [Idiomas.t("Lesionado, semanas:"), _a.lesion]
		_derecha.add_child(les)

func _fila_atributo(clave: String) -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	var nombre := Label.new()
	nombre.custom_minimum_size = Vector2(96, 0)
	nombre.text = Idiomas.t(String(Principal.NOMBRES_ATRIBUTOS.get(clave, clave)))
	fila.add_child(nombre)
	var barra := ProgressBar.new()
	barra.show_percentage = false
	barra.max_value = 100.0
	barra.value = float(_a.atributos.get(clave, 0))
	barra.custom_minimum_size = Vector2(130, 14)
	barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(barra)
	var valor := Label.new()
	valor.custom_minimum_size = Vector2(30, 0)
	valor.text = str(int(_a.atributos.get(clave, 0)))
	fila.add_child(valor)
	if _b != null:
		var d := diferencia(_a, _b, clave)
		var vb := Label.new()   ## el valor del segundo jugador, junto a la diferencia
		vb.custom_minimum_size = Vector2(30, 0)
		vb.text = str(int(_b.atributos.get(clave, 0)))
		fila.add_child(vb)
		var cmp := Label.new()
		cmp.text = ("%+d" % d) if d != 0 else "="
		cmp.add_theme_color_override("font_color", Color(0.45, 0.9, 0.55) if d > 0 else (Color(0.95, 0.45, 0.45) if d < 0 else Color(0.8, 0.8, 0.8)))
		fila.add_child(cmp)
	return fila
