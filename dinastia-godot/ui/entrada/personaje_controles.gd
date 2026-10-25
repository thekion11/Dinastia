class_name ControlesPersonaje
extends RefCounted
## LAS PIEZAS DEL EDITOR DE ASPECTO (25-10-2026): chips de opción, muestras de
## color, deslizadores con palabras, interruptores y el selector ◀ ▶. Las usan
## las hojas del aspecto (`HojasPersonaje`) de la etapa de entrada y del
## creador del menú, así los dos se ven y se comportan igual.
##
## Cada pieza lee el valor de `asp` y, al tocarla, llama a
## `cambiar.call(clave, valor, repintar)`; `repintar` es para lo que cambia
## qué otras opciones tienen sentido (el cuerpo, la ropa, la cara).

const ALTO_CHIP := 34
const LADO_MUESTRA := 34

## Estilo de chip: oscuro y en reposo, o con el borde de oro si está elegido.
static func _estilo_chip(activo: bool, apagado := false) -> StyleBoxFlat:
	var e := Tema.caja(Color("1d2a21") if activo else Color("16211a"), Tema.RADIO, Tema.ORO if activo else Color("ffffff14"))
	e.set_border_width_all(2 if activo else 1)
	e.content_margin_left = 12
	e.content_margin_right = 12
	e.content_margin_top = 4
	e.content_margin_bottom = 4
	if apagado:
		e.bg_color = Color("101712")
	return e

static func chip(texto: String, activo: bool, al_pulsar: Callable, apagado := false) -> Button:
	var b := Button.new()
	b.text = texto
	b.toggle_mode = true
	b.disabled = apagado
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(0, ALTO_CHIP)
	b.add_theme_font_size_override("font_size", Tema.TAM_CUERPO)
	estilar_chip(b, activo, apagado)
	b.pressed.connect(al_pulsar)
	return b

## El aspecto del chip según esté elegido o no (también para cambiarlo luego).
static func estilar_chip(b: Button, activo: bool, apagado := false) -> void:
	b.set_pressed_no_signal(activo)
	b.add_theme_stylebox_override("normal", _estilo_chip(activo, apagado))
	b.add_theme_stylebox_override("pressed", _estilo_chip(true))
	var encima := _estilo_chip(activo)
	encima.bg_color = Color("223228")
	b.add_theme_stylebox_override("hover", encima)
	b.add_theme_stylebox_override("hover_pressed", _estilo_chip(true))
	b.add_theme_stylebox_override("disabled", _estilo_chip(false, true))
	var foco := _estilo_chip(true)
	foco.draw_center = false
	b.add_theme_stylebox_override("focus", foco)
	b.add_theme_color_override("font_color", Tema.ORO if activo else Tema.TEXTO)
	b.add_theme_color_override("font_pressed_color", Tema.ORO)
	b.add_theme_color_override("font_hover_pressed_color", Tema.ORO)
	b.add_theme_color_override("font_disabled_color", Color("5a6b5f"))

## Un rótulo de sección con una nota opcional a su lado («se ve con manga corta»).
static func rotulo(vb: VBoxContainer, texto: String, nota: String = "") -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	vb.add_child(fila)
	var r := Tema.rotulo(Idiomas.t(texto))
	r.add_theme_color_override("font_color", Color("b4c4b8"))
	fila.add_child(r)
	if nota != "":
		var n := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "· " + Idiomas.t(nota))
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(n)

static func nota(vb: VBoxContainer, texto: String) -> void:
	var n := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, Idiomas.t(texto))
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(n)

## Opciones en chips: `lista` = [[valor, nombre], ...] (el nombre se traduce).
static func opciones(vb: VBoxContainer, asp: Dictionary, rotulo_txt: String, clave: String, lista: Array,
		cambiar: Callable, apagado := false, nota_txt := "") -> void:
	rotulo(vb, rotulo_txt, nota_txt)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	vb.add_child(flow)
	for par: Array in lista:
		var valor: Variant = par[0]
		flow.add_child(chip(Idiomas.t(String(par[1])), asp.get(clave) == valor,
			func() -> void: cambiar.call(clave, valor, true), apagado))

## Muestras de color redondas, con aro de oro en la elegida, y «＋» para
## cualquier otro color.
static func muestras(vb: VBoxContainer, asp: Dictionary, rotulo_txt: String, clave: String, colores: Array,
		cambiar: Callable) -> void:
	rotulo(vb, rotulo_txt)
	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", 6)
	fila.add_theme_constant_override("v_separation", 6)
	vb.add_child(fila)
	var actual := String(asp.get(clave, "")).to_lower()
	var vistos := {}
	for hexa: String in colores:
		if vistos.has(hexa.to_lower()):
			continue
		vistos[hexa.to_lower()] = true
		var b := Button.new()
		b.custom_minimum_size = Vector2(LADO_MUESTRA, LADO_MUESTRA)
		b.tooltip_text = "#" + hexa
		var elegido := hexa.to_lower() == actual
		for estado: String in ["normal", "hover", "pressed", "focus"]:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(hexa)
			sb.set_corner_radius_all(int(LADO_MUESTRA * 0.5))
			sb.border_color = Tema.ORO if elegido else (Color(1, 1, 1, 0.55) if estado == "hover" else Color(0, 0, 0, 0.45))
			sb.set_border_width_all(3 if elegido else 2)
			b.add_theme_stylebox_override(estado, sb)
		b.pressed.connect(func() -> void: cambiar.call(clave, hexa, true))
		fila.add_child(b)
	var picker := ColorPickerButton.new()
	picker.text = "＋"
	picker.tooltip_text = Idiomas.t("Otro color")
	picker.color = Color(String(asp.get(clave, "ffffff")))
	picker.custom_minimum_size = Vector2(LADO_MUESTRA + 12, LADO_MUESTRA)
	picker.edit_alpha = false
	picker.popup_closed.connect(func() -> void: cambiar.call(clave, picker.color.to_html(false), true))
	picker.color_changed.connect(func(c: Color) -> void: cambiar.call(clave, c.to_html(false), false))
	fila.add_child(picker)

## Cómo se lee un rasgo de -1 a 1: con palabras, no con «+0,35».
static func palabra_rasgo(v: float) -> String:
	if v < -0.6:
		return Idiomas.t("Mucho menos")
	if v < -0.2:
		return Idiomas.t("Menos")
	if v <= 0.2:
		return Idiomas.t("Normal")
	if v <= 0.6:
		return Idiomas.t("Más")
	return Idiomas.t("Mucho más")

static func deslizador(vb: VBoxContainer, asp: Dictionary, rotulo_txt: String, clave: String, minimo: float,
		maximo: float, paso: float, como: Callable, cambiar: Callable) -> HSlider:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	vb.add_child(fila)
	var et := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, Idiomas.t(rotulo_txt))
	et.custom_minimum_size = Vector2(118, 0)
	fila.add_child(et)
	var s := HSlider.new()
	s.min_value = minimo
	s.max_value = maximo
	s.step = paso
	s.value = float(asp.get(clave, 0.0))
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.custom_minimum_size = Vector2(160, 26)
	fila.add_child(s)
	var val := Tema.etiqueta(Tema.TAM_CUERPO, Tema.ORO, String(como.call(s.value)))
	val.custom_minimum_size = Vector2(104, 0)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fila.add_child(val)
	s.value_changed.connect(func(v: float) -> void:
		val.text = String(como.call(v))
		cambiar.call(clave, v, false))
	return s

static func interruptor(vb: VBoxContainer, asp: Dictionary, rotulo_txt: String, clave: String, cambiar: Callable,
		apagado := false, nota_txt := "") -> void:
	var c := CheckButton.new()
	c.text = Idiomas.t(rotulo_txt) + ("   · " + Idiomas.t(nota_txt) if nota_txt != "" else "")
	c.button_pressed = bool(asp.get(clave, false)) and not apagado
	c.disabled = apagado
	c.add_theme_font_size_override("font_size", Tema.TAM_CUERPO)
	c.toggled.connect(func(on: bool) -> void: cambiar.call(clave, on, true))
	vb.add_child(c)

## ◀ nombre ▶ para listas largas (las caras y cortes de la biblioteca).
## `lista` = [[valor, nombre ya traducido], ...].
static func selector(vb: VBoxContainer, asp: Dictionary, rotulo_txt: String, clave: String, lista: Array,
		cambiar: Callable, apagado := false, nota_txt := "") -> void:
	rotulo(vb, rotulo_txt, nota_txt)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	vb.add_child(fila)
	var actual := 0
	for i in lista.size():
		if (lista[i] as Array)[0] == asp.get(clave):
			actual = i
	var et := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO if not apagado else Tema.SUAVE, String((lista[actual] as Array)[1]))
	et.custom_minimum_size = Vector2(240, ALTO_CHIP)
	et.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	et.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", _estilo_chip(false, apagado))
	caja.add_child(et)
	for paso: int in [-1, 1]:
		var j := posmod(actual + paso, lista.size())
		var al_pulsar := func() -> void: cambiar.call(clave, (lista[j] as Array)[0], true)
		var b := chip("◀" if paso < 0 else "▶", false, al_pulsar, apagado)
		b.toggle_mode = false
		b.custom_minimum_size = Vector2(42, ALTO_CHIP)
		fila.add_child(b)
		if paso < 0:
			fila.add_child(caja)
