class_name PlantillaPes
extends RefCounted
## LA PLANTILLA A LA PES (9-11; orden del líder y ejemplos del dueño: «Estrategia» y «Opción de entrenamiento»), con la paleta del juego (verde y dorado,
## `Tema`), no la morada del PES. Tres columnas: el CAMPO con la formación y los once (cada uno con su nota y la etiqueta de su línea), la LISTA con
## etiquetas de posición de colores y nota (titulares y reservas) y, a la derecha, la INFORMACIÓN del elegido: retrato, nota grande, radar y datos.
## «⚖ Comparar» enseña a un segundo jugador al lado y la diferencia de cada atributo. Es de lectura: el once se cambia en «Mi plantel».
const ATR_CAMPO := ["rit", "tir", "pas", "reg", "def", "fis"]
const ATR_PORTERO := ["div", "par", "saq", "ref", "vel", "pos"]
const ANCHO_CAMPO := 340.0   ## medida mínima/inicial; el campo ocupa todo su panel (`_ancho`, `_alto`)
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
var _cambiando := false
var _pila: Array = []   ## fotos del once antes de cada cambio, para «Deshacer»
var _btn_deshacer: Button
var _btn_auto: Button
var _aviso_texto := ""
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

## INTERCAMBIAR en el once: ver `GestionOnce.intercambiar` (se deja aquí por compatibilidad con las pruebas y las llamadas de siempre).
static func intercambiar(club: Club, a: Jugador, b: Jugador) -> bool:
	return GestionOnce.intercambiar(club, a, b)

## El color de una barra según el valor (como el PES: dorado arriba, verde, ámbar, rojo abajo).
static func color_de_valor(v: int) -> Color:
	if v >= 85:
		return Tema.ORO
	if v >= 75:
		return Color("56c27a")
	if v >= 65:
		return Tema.ACENTO
	if v >= 55:
		return Color("d9a43a")
	return Tema.MAL

static func color_de(j: Jugador) -> Color:
	return Tema.POS.get(j.pos, Tema.SUAVE)

func _ancho() -> float:
	return maxf(_campo.size.x, ANCHO_CAMPO * 0.6) if _campo != null and _campo.size.x > 1.0 else ANCHO_CAMPO

func _alto() -> float:
	return maxf(_campo.size.y, ALTO_CAMPO * 0.6) if _campo != null and _campo.size.y > 1.0 else ALTO_CAMPO

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
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(pc)
	_campo = Control.new()
	_campo.custom_minimum_size = Vector2(ANCHO_CAMPO, ALTO_CAMPO)
	_campo.draw.connect(_dibujar_campo)
	pc.add_child(_campo)
	var pl := _panel(330)
	pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(pl)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pl.add_child(scroll)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_lista)
	var pi := _panel(300)
	pi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pi.size_flags_stretch_ratio = 1.3
	cols.add_child(pi)
	var desl := ScrollContainer.new()   ## la columna de información puede ser larga (radar, atributos y estilos): se desliza
	desl.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pi.add_child(desl)
	_info = VBoxContainer.new()
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desl.add_child(_info)
	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 10)
	raiz.add_child(pie)
	var comp := Button.new()
	comp.toggle_mode = true
	comp.text = Idiomas.t("⚖ Comparar")
	var camb := Button.new()
	camb.toggle_mode = true
	camb.text = Idiomas.t("↔ Cambiar en el once")
	comp.toggled.connect(func(on: bool) -> void:
		_comparando = on
		_b = null
		if on and camb.button_pressed:
			camb.button_pressed = false
		_pintar())
	camb.toggled.connect(func(on: bool) -> void:
		_cambiando = on
		_b = null
		if on and comp.button_pressed:
			comp.button_pressed = false
		_pintar())
	pie.add_child(comp)
	pie.add_child(camb)
	_btn_deshacer = Button.new()
	_btn_deshacer.text = Idiomas.t("↶ Deshacer")
	_btn_deshacer.pressed.connect(func() -> void:
		if not _pila.is_empty():
			GestionOnce.restaurar(_club, _pila.pop_back())
			_titulares = _club.once()
			_aviso_texto = Idiomas.t("Cambio deshecho.")
			_pintar())
	pie.add_child(_btn_deshacer)
	_btn_auto = Button.new()
	_btn_auto.text = Idiomas.t("⟲ Once automático")
	_btn_auto.pressed.connect(func() -> void:
		_pila.append(GestionOnce.foto(_club))
		GestionOnce.automatico(_club)
		_titulares = _club.once()
		_aviso_texto = Idiomas.t("El once vuelve a armarse solo.")
		_pintar())
	pie.add_child(_btn_auto)
	var ayuda := _etiqueta(Idiomas.t("Elige un jugador de la lista · con «Comparar» el segundo clic es el rival de la comparación"), 12, Tema.SUAVE)
	ayuda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pie.add_child(ayuda)
	var cerrar := Button.new()
	cerrar.text = Idiomas.t("Cerrar")
	cerrar.pressed.connect(_capa.queue_free)
	pie.add_child(cerrar)
	_a = _titulares[0] if not _titulares.is_empty() else _club.plantilla[0]
	_pintar()
	_campo.resized.connect(_pintar_campo)   ## el campo ocupa todo su panel: al fijarse el tamaño se recolocan los once
	raiz.modulate.a = 0.0   ## entra con un fundido corto
	raiz.create_tween().tween_property(raiz, "modulate:a", 1.0, 0.25)

## El césped con sus rayas, las líneas y el área, dibujados en el control del campo.
func _dibujar_campo() -> void:
	var w := _ancho()
	var h := _alto()
	for k in 8:
		_campo.draw_rect(Rect2(0, h * k / 8.0, w, h / 8.0), Color(0.16, 0.40, 0.22) if k % 2 == 0 else Color(0.18, 0.45, 0.25))
	var linea := Color(1, 1, 1, 0.55)
	_campo.draw_rect(Rect2(6, 6, w - 12, h - 12), linea, false, 2.0)
	_campo.draw_line(Vector2(6, h / 2.0), Vector2(w - 6, h / 2.0), linea, 2.0)
	_campo.draw_arc(Vector2(w / 2.0, h / 2.0), 42.0, 0.0, TAU, 40, linea, 2.0)
	_campo.draw_circle(Vector2(w / 2.0, h / 2.0), 3.0, linea)
	_campo.draw_circle(Vector2(w / 2.0, 6 + h * 0.105), 2.5, linea)
	_campo.draw_circle(Vector2(w / 2.0, h - 6 - h * 0.105), 2.5, linea)
	for k in 6:   ## viñeta: los bordes más oscuros, como la luz del estadio
		_campo.draw_rect(Rect2(float(k), float(k), w - 2.0 * k, h - 2.0 * k), Color(0, 0, 0, 0.05), false, 2.0)
	_campo.draw_rect(Rect2(w * 0.22, 6, w * 0.56, h * 0.15), linea, false, 2.0)
	_campo.draw_rect(Rect2(w * 0.22, h - 6 - h * 0.15, w * 0.56, h * 0.15), linea, false, 2.0)

## Solo el campo (los once colocados según su tamaño): es lo que se rehace al cambiar el tamaño del panel.
func _pintar_campo() -> void:
	for h in _campo.get_children():
		h.queue_free()
	var forms: Dictionary = Datos.tabla("FORMS")
	var ranuras: Array = (forms.get(_club.tactica.formacion, forms.get("4-3-3", {})) as Dictionary).get("s", [])
	for i in mini(ranuras.size(), _titulares.size()):
		_campo.add_child(_ficha_campo(_titulares[i], ranuras[i]))
	_campo.queue_redraw()

func _pintar() -> void:
	_pintar_campo()
	for h in _lista.get_children():
		h.queue_free()
	for h in _info.get_children():
		h.queue_free()
	_lista.add_child(_etiqueta(Idiomas.t("TITULARES"), 12, Tema.ORO))
	for j: Jugador in _titulares:
		_lista.add_child(_fila(j))
	_lista.add_child(_etiqueta(Idiomas.t("RESERVAS"), 12, Tema.ORO))
	var reservas: Array = _club.plantilla.filter(func(j: Jugador) -> bool: return not _titulares.has(j))
	reservas.sort_custom(func(x: Jugador, y: Jugador) -> bool: return x.ovr > y.ovr)
	for j: Jugador in reservas:
		_lista.add_child(_fila(j))
	if _btn_deshacer != null:
		_btn_deshacer.disabled = _pila.is_empty()
		_btn_auto.disabled = _club.once_elegido.is_empty()
	_pintar_info()

func _elegir(j: Jugador) -> void:
	_aviso_texto = ""
	if _cambiando and _a != null and j != _a:
		var antes := GestionOnce.foto(_club)
		if GestionOnce.intercambiar(_club, _a, j):
			_pila.append(antes)
			_titulares = _club.once()
			_aviso_texto = "%s ↔ %s" % [_a.nombre, j.nombre]
		else:
			_aviso_texto = Idiomas.t("No se puede: alguien no está disponible o los dos son reservas.")
		_b = null
	elif _comparando and _a != null and j != _a:
		_b = j
	else:
		_a = j
		_b = null
	_pintar()

## Un titular sobre el campo, como en el PES: su CARA en un aro del color de su línea (dorado si es el elegido), la nota en una chapa y su
## apellido en una placa debajo.
func _ficha_campo(j: Jugador, ranura: Array) -> Button:
	var elegido := j == _a or j == _b
	var b := Button.new()
	b.flat = true
	b.custom_minimum_size = Vector2(78, 82)
	b.size = Vector2(78, 82)
	b.position = Vector2(float(ranura[1]) / 100.0 * _ancho() - 39.0, float(ranura[2]) / 100.0 * _alto() - 34.0)
	for estado in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
	var aro := PanelContainer.new()
	aro.position = Vector2(15, 0)
	aro.custom_minimum_size = Vector2(48, 48)
	aro.size = Vector2(48, 48)
	aro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aro.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var sa := StyleBoxFlat.new()
	sa.bg_color = Color(0.08, 0.1, 0.09)
	sa.set_corner_radius_all(24)
	aro.add_theme_stylebox_override("panel", sa)
	var cara := _p._retrato(j, 68)
	cara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cara.custom_minimum_size = Vector2(48, 48)
	cara.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aro.add_child(cara)
	b.add_child(aro)
	var anillo := Panel.new()   ## el borde, encima de la cara
	anillo.position = aro.position
	anillo.size = aro.size
	anillo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sr := StyleBoxFlat.new()
	sr.bg_color = Color(0, 0, 0, 0)
	sr.set_corner_radius_all(24)
	sr.border_color = Tema.ORO if elegido else color_de(j)
	sr.set_border_width_all(4 if elegido else 3)
	if elegido:
		sr.shadow_color = Color(Tema.ORO, 0.55)
		sr.shadow_size = 8
	anillo.add_theme_stylebox_override("panel", sr)
	b.add_child(anillo)
	var chapa := PanelContainer.new()
	chapa.position = Vector2(4, 0)
	chapa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sc := StyleBoxFlat.new()
	sc.bg_color = color_de(j)
	sc.set_corner_radius_all(4)
	sc.set_content_margin_all(2)
	chapa.add_theme_stylebox_override("panel", sc)
	chapa.add_child(_etiqueta(str(j.ovr), 12, Color.WHITE))
	b.add_child(chapa)
	var placa := PanelContainer.new()
	placa.position = Vector2(2, 54)
	placa.custom_minimum_size = Vector2(74, 0)
	placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sp := StyleBoxFlat.new()
	sp.bg_color = Color(0, 0, 0, 0.62)
	sp.set_corner_radius_all(4)
	sp.set_content_margin_all(2)
	placa.add_theme_stylebox_override("panel", sp)
	var ap := _etiqueta(j.nombre.split(" ")[-1].left(10), 11, Tema.ORO if elegido else Color.WHITE)
	ap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placa.add_child(ap)
	b.add_child(placa)
	b.pressed.connect(func() -> void: _elegir(j))
	if elegido:
		b.pivot_offset = Vector2(39, 24)
		b.scale = Vector2(1.12, 1.12)
	return b

## Una fila de la lista: etiqueta de posición de color, nombre y nota (como la lista de «Estrategia» del PES).
func _fila(j: Jugador) -> Button:
	var b := Button.new()
	b.flat = true
	b.custom_minimum_size = Vector2(0, 34)
	var fila := HBoxContainer.new()
	fila.set_anchors_preset(Control.PRESET_FULL_RECT)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_theme_constant_override("separation", 8)
	b.add_child(fila)
	if j == _a or j == _b:   ## la franja dorada de la fila elegida
		var fs := StyleBoxFlat.new()
		fs.bg_color = Color(Tema.ORO, 0.14)
		fs.border_color = Tema.ORO
		fs.border_width_left = 3
		fs.set_corner_radius_all(3)
		for estado in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(estado, fs)
	var cuadro := PanelContainer.new()
	cuadro.custom_minimum_size = Vector2(26, 26)
	cuadro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cuadro.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var scu := StyleBoxFlat.new()
	scu.bg_color = Color(0.08, 0.1, 0.09)
	scu.set_corner_radius_all(13)
	cuadro.add_theme_stylebox_override("panel", scu)
	var foto := _p._retrato(j, 38)
	foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	foto.custom_minimum_size = Vector2(26, 26)
	foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cuadro.add_child(foto)
	fila.add_child(cuadro)
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
	fila.add_child(FlechaForma.etiqueta(j))   ## (10-11) la flecha de forma, como la «condición» del PES
	fila.add_child(_etiqueta(str(j.ovr), 14, Tema.TEXTO))
	b.pressed.connect(func() -> void: _elegir(j))
	return b

func _pintar_info() -> void:
	if _a == null:
		return
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 10)
	_info.add_child(cab)
	var tarjeta := PanelContainer.new()   ## el retrato sobre un fondo con los colores del club
	var st := StyleBoxFlat.new()
	st.bg_color = Color(_club.color1).lerp(Color(0.05, 0.08, 0.06), 0.65)
	st.border_color = Color(Tema.ORO, 0.7)
	st.set_border_width_all(1)
	st.set_corner_radius_all(6)
	tarjeta.add_theme_stylebox_override("panel", st)
	tarjeta.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	tarjeta.add_child(_p._retrato(_a, 124))
	cab.add_child(tarjeta)
	var datos := VBoxContainer.new()
	cab.add_child(datos)
	datos.add_child(_etiqueta(_a.nombre, 16, Tema.ORO))
	datos.add_child(_etiqueta("#%d · %s" % [_a.dorsal, _a.pos_e], 13, Tema.SUAVE))
	datos.add_child(_etiqueta(str(_a.ovr), 46, Tema.ORO))
	var radar := RadarAtributos.new()
	radar.custom_minimum_size = Vector2(280, 200)
	var etq := PackedStringArray()
	var vals := PackedFloat32Array()
	for k: String in claves_de(_a):
		etq.append(Idiomas.t(String(Principal.NOMBRES_ATRIBUTOS.get(k, k))).left(5))
		vals.append(float(_a.atributos.get(k, 0)))
	radar.poner(etq, vals, Tema.ACENTO)
	_info.add_child(PlantillaHabilidades.junto_al_mapa(radar, _a))   ## (10-11) radar + mapa de calor, como el PES
	for k: String in claves_de(_a):
		_info.add_child(_fila_atributo(k))
	PlantillaEstilos.pintar(_p.mundo, _club, _a, _info, _pintar)   ## estilo de juego con estrellas (idea del PES)
	PlantillaHabilidades.pintar(_a, _info)   ## (10-11) habilidades individuales con estrellas
	_info.add_child(_etiqueta("%s %d · %s %d%% · %s %d%% · %s %d%%" % [Idiomas.t("Edad"), _a.edad, Idiomas.t("Forma"), _a.forma,
		Idiomas.t("Moral"), _a.moral, Idiomas.t("Físico"), _a.fisico], 12, Tema.SUAVE))
	if _cambiando and _aviso_texto == "":
		_info.add_child(_etiqueta("↔ %s %s" % [Idiomas.t("Elige con quién cambiar a"), _a.nombre], 13, Tema.ORO))
	if _aviso_texto != "":
		_info.add_child(_etiqueta(_aviso_texto, 13, Tema.ORO))
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
	barra.custom_minimum_size = Vector2(96, 12)
	barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = color_de_valor(int(barra.value))
	relleno.set_corner_radius_all(3)
	var hueco := StyleBoxFlat.new()
	hueco.bg_color = Color(1, 1, 1, 0.08)
	hueco.set_corner_radius_all(3)
	barra.add_theme_stylebox_override("fill", relleno)
	barra.add_theme_stylebox_override("background", hueco)
	fila.add_child(barra)
	fila.add_child(_etiqueta(str(int(_a.atributos.get(clave, 0))), 12, Tema.TEXTO))
	if _b != null:
		var d := diferencia(_a, _b, clave)
		fila.add_child(_etiqueta(str(int(_b.atributos.get(clave, 0))), 12, Tema.SUAVE))
		fila.add_child(_etiqueta(("%+d" % d) if d != 0 else "=", 12, Tema.BIEN if d > 0 else (Tema.MAL if d < 0 else Tema.NEUTRO)))
	return fila
