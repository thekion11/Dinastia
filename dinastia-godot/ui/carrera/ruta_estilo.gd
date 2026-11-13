class_name RutaEstilo
extends RefCounted
## LA ESTÉTICA DE «LA RUTA» (13-11-2026): noche de estadio. Azul noche, tarjetas
## redondeadas, oro para lo que importa, coral para lo que quema y menta para
## lo que va bien; títulos en Bebas Neue, como un marcador.

const NOCHE := Color("070b18")
const TINTA := Color("121a30")
const TINTA2 := Color("1a2440")
const BORDE := Color(1, 1, 1, 0.08)
const ORO := Color("ffc93c")
const CORAL := Color("ff5a7a")
const MENTA := Color("4ee6b0")
const CIELO := Color("5ab8ff")
const TEXTO := Color("f2f5fb")
const SUAVE := Color("93a0bd")

static var _titular: Font
## Las capturas y las pruebas apagan las animaciones (la foto caería a medias).
static var sin_animar := false

static func _anima() -> bool:
	return not sin_animar and not AhorroMenu.fondo_estatico()

## Una capa que aparece fundiéndose.
static func entrada(n: Control) -> void:
	if not _anima():
		return
	n.modulate.a = 0.0
	n.ready.connect(func() -> void: n.create_tween().tween_property(n, "modulate:a", 1.0, 0.25))

## Una barra que se llena desde cero.
static func llenar(b: ProgressBar, retraso := 0.2) -> void:
	if not _anima():
		return
	var hasta := b.value
	b.value = 0.0
	b.ready.connect(func() -> void:
		b.create_tween().tween_property(b, "value", hasta, 0.8).set_delay(retraso).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT))

## Un número que sube contando hasta su valor (`formato` como "%.1f").
static func contar(l: Label, hasta: float, formato: String) -> void:
	if not _anima():
		return
	l.text = formato % 0.0
	l.ready.connect(func() -> void:
		l.create_tween().tween_method(func(x: float) -> void: l.text = formato % x, 0.0, hasta, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT))

## La fuente de los titulares (con la del juego de respaldo para lo que no trae).
static func titular() -> Font:
	if _titular == null:
		var f := FontVariation.new()
		f.base_font = load("res://assets/fuentes/BebasNeue-Regular.ttf")
		f.fallbacks = [ThemeDB.fallback_font]
		f.spacing_glyph = 1
		_titular = f
	return _titular

static func caja(fondo := TINTA, radio := 16, borde := BORDE, margen := 16) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = fondo
	st.border_color = borde
	st.set_border_width_all(1)
	st.set_corner_radius_all(radio)
	st.content_margin_left = margen; st.content_margin_right = margen
	st.content_margin_top = margen - 2; st.content_margin_bottom = margen - 2
	return st

## Una tarjeta; con `acento`, una raya de ese color arriba.
static func tarjeta(acento := Color(0, 0, 0, 0), fondo := TINTA) -> PanelContainer:
	var p := PanelContainer.new()
	var st := caja(fondo)
	if acento.a > 0.0:
		st.border_width_top = 3
		st.border_color = acento
	p.add_theme_stylebox_override("panel", st)
	return p

static func lbl(tam: int, col: Color, texto := "", corta := false) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	if texto.length() > 34 and not corta:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

## Un titular de marcador (Bebas Neue).
static func titulo(tam: int, col: Color, texto: String) -> Label:
	var l := lbl(tam, col, texto, true)
	l.add_theme_font_override("font", titular())
	return l

## La etiqueta pequeña de una sección («DÍA DE PARTIDO»).
static func rotulo(texto: String, col := SUAVE) -> Label:
	var l := titulo(17, col, texto)
	return l

## Botón de píldora. `lleno`: relleno del color (la acción principal).
static func boton(texto: String, col: Color, accion: Callable, alto := 44, lleno := false) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(0, alto)
	b.add_theme_font_size_override("font_size", 16 if alto >= 44 else 14)
	var n := caja(col if lleno else Color(col, 0.10), mini(14, alto / 2), Color(col, 0.0 if lleno else 0.55), 16)
	n.content_margin_top = 4; n.content_margin_bottom = 4
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = col.lightened(0.18) if lleno else Color(col, 0.24)
	var pr := n.duplicate() as StyleBoxFlat
	pr.bg_color = col.darkened(0.15) if lleno else col
	var dis := n.duplicate() as StyleBoxFlat
	dis.bg_color = Color(1, 1, 1, 0.04)
	dis.border_color = BORDE
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("focus", h)
	b.add_theme_stylebox_override("pressed", pr)
	b.add_theme_stylebox_override("disabled", dis)
	var tinta := (Color("0a0f1e") if col.get_luminance() > 0.32 else TEXTO) if lleno else TEXTO
	b.add_theme_color_override("font_color", tinta)
	b.add_theme_color_override("font_hover_color", tinta)
	b.add_theme_color_override("font_focus_color", tinta)
	b.add_theme_color_override("font_pressed_color", Color("0a0f1e"))
	b.add_theme_color_override("font_disabled_color", SUAVE)
	if accion.is_valid():
		b.pressed.connect(accion)
	if lleno:
		b.set_meta("principal", true)
	return b

## Pone el foco (mando y teclado) en la acción principal de `raiz`: el último
## botón relleno que se añadió gana si hay una capa encima (resumen, toque).
static func enfocar(raiz: Node) -> void:
	var hallado: Button = null
	for n: Node in raiz.find_children("*", "Button", true, false):
		if n.has_meta("principal") and (n as Button).is_visible_in_tree() and not (n as Button).disabled:
			if hallado == null or raiz.get_child(raiz.get_child_count() - 1).is_ancestor_of(n):
				hallado = n
	if hallado != null:
		hallado.grab_focus.call_deferred()

## Botón de elección (uno de un grupo): queda relleno cuando está elegido.
static func opcion(texto: String, col: Color, grupo: ButtonGroup, elegido: bool, accion: Callable, alto := 38) -> Button:
	var b := boton(texto, col, accion, alto)
	b.toggle_mode = true
	b.button_group = grupo
	b.button_pressed = elegido
	return b

static func chip(texto: String, col: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var st := caja(Color(col, 0.16), 10, Color(col, 0.5), 10)
	st.content_margin_top = 3; st.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", st)
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_child(lbl(13, col, texto, true))
	return p

## Barra redonda de progreso.
static func barra(valor: float, maximo: float, col: Color, alto := 8) -> ProgressBar:
	var b := ProgressBar.new()
	b.max_value = maxf(1.0, maximo)
	b.value = clampf(valor, 0.0, b.max_value)
	b.show_percentage = false
	b.custom_minimum_size = Vector2(40, alto)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var f := StyleBoxFlat.new()
	f.bg_color = Color(1, 1, 1, 0.09)
	f.set_corner_radius_all(alto / 2)
	var ll := StyleBoxFlat.new()
	ll.bg_color = col
	ll.set_corner_radius_all(alto / 2)
	b.add_theme_stylebox_override("background", f)
	b.add_theme_stylebox_override("fill", ll)
	return b

## «Nombre ▬▬▬ 64»: un medidor con su número.
static func medidor(nombre: String, valor: int, maximo: int, col: Color, ancho_nombre := 118) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var l := lbl(13, SUAVE, nombre, true)
	l.custom_minimum_size = Vector2(ancho_nombre, 0)
	h.add_child(l)
	h.add_child(barra(valor, maximo, col))
	var n := titulo(20, col, str(valor))
	n.custom_minimum_size = Vector2(30, 0)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(n)
	return h

## Una cifra grande con su leyenda debajo.
static func cifra(valor: String, leyenda: String, col := TEXTO, tam := 34) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var n := titulo(tam, col, valor)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(n)
	var l := lbl(12, SUAVE, leyenda, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	return v

static func escudo(c: Club, px: int) -> TextureRect:
	return imagen(Escudo.textura(c, px), px)

static func imagen(tex: Texture2D, px: int) -> TextureRect:
	var e := TextureRect.new()
	e.texture = tex
	e.custom_minimum_size = Vector2(px, px)
	e.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	e.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	e.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return e

static func columna(sep := 10) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return v

static func fila(sep := 10) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func flujo(sep := 6) -> HFlowContainer:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", sep)
	f.add_theme_constant_override("v_separation", sep)
	return f

## ¿Pantalla estrecha? (un teléfono de pie: el lienzo mide ~540 px de ancho)
static func estrecho(ui: Variant) -> bool:
	return ui.get_viewport_rect().size.x < 760.0

## ¿Pantalla baja? (un teléfono tumbado: el lienzo mide ~394 px de alto)
static func bajo(ui: Variant) -> bool:
	return ui.get_viewport_rect().size.y < 520.0

## Fila en ancho, columna en estrecho.
static func reparto(vertical: bool, sep := 10) -> BoxContainer:
	var b := BoxContainer.new()
	b.vertical = vertical
	b.add_theme_constant_override("separation", sep)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b

## El cuerpo de una pestaña: dos columnas que se desplazan por separado (la
## derecha, de ancho fijo) o, en estrecho, una sola columna con todo.
static func columnas(ui: Variant, izq: Array, der: Array, ancho_der := 390.0) -> Control:
	var angosto := estrecho(ui)
	var cols := fila(14)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sc := ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cols.add_child(sc)
	var a := columna(12)
	sc.add_child(a)
	for n: Control in izq:
		a.add_child(n)
	var b := a
	if not angosto and not der.is_empty():
		var sc2 := ScrollContainer.new()
		sc2.custom_minimum_size = Vector2(ancho_der, 0)
		sc2.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		cols.add_child(sc2)
		b = columna(12)
		sc2.add_child(b)
	for n2: Control in der:
		b.add_child(n2)
	return cols

static func miles(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out

## El mismo color, aclarado hasta que se lea como texto sobre la noche.
static func legible(col: Color) -> Color:
	var c := col
	for _i in 6:
		if c.get_luminance() >= 0.34:
			break
		c = c.lightened(0.22)
	return c

## Un color de club que se lea sobre la noche (los muy oscuros se aclaran).
static func de_club(c: Club) -> Color:
	if c == null:
		return ORO
	var col := Color(String(c.color1))
	if col.get_luminance() < 0.22:
		var otro := Color(String(c.color2))
		col = otro if otro.get_luminance() >= 0.22 else col.lightened(0.45)
	return col
