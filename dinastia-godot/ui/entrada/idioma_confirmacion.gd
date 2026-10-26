class_name ConfirmacionIdioma
extends Control
## LA CONFIRMACIÓN DEL IDIOMA (fase 1, etapa 1; 25-10-2026). Las etapas de la
## entrada son obligatorias y se confirman al rellenarlas (`docs/PLAN_DEL_LUNES.md`
## §3.1): elegir un idioma por error deja al jugador ante menús que no entiende,
## así que antes de seguir se pregunta, EN EL IDIOMA ELEGIDO («¿Quieres jugar en
## este idioma?») y, si es otro, también en el que estaba puesto: quien pulsó sin
## querer el polaco lo lee en castellano y vuelve atrás.
##
## Va encima de la pantalla de idioma (no es otra etapa): oscurece lo de detrás,
## se queda con el foco y con Esc / B se cierra sin elegir.

signal aceptado(codigo: String)
signal cancelado()

const ORO := Color("e8c46a")
const TEXTO := Color("f3eee2")
const SUAVE := Color("a9b1c2")

var codigo := "es"
var boton_si: Button
var boton_otro: Button

var _textos: Dictionary = {}
var _textos_actual: Dictionary = {}
var _panel: PanelContainer
var _cerrando := false

## `textos` en el idioma elegido; `textos_actual` en el que había (vacío si es el
## mismo). `fuente_titulo` la pone la pantalla para que todo case.
func preparar(cual: String, textos: Dictionary, textos_actual: Dictionary, fuente_titulo: Font) -> void:
	codigo = cual
	_textos = textos
	_textos_actual = textos_actual
	set_meta("fuente_titulo", fuente_titulo)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var velo := ColorRect.new()
	velo.color = Color(0.0, 0.0, 0.02, 0.72)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	_panel = PanelContainer.new()
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color(0.045, 0.055, 0.085, 0.97)
	caja.border_color = Color(ORO, 0.75)
	caja.set_border_width_all(2)
	caja.set_corner_radius_all(16)
	caja.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	caja.shadow_size = 28
	caja.content_margin_left = 44
	caja.content_margin_right = 44
	caja.content_margin_top = 30
	caja.content_margin_bottom = 30
	_panel.add_theme_stylebox_override("panel", caja)
	centro.add_child(_panel)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	_panel.add_child(v)
	var bandera := BanderaIdioma.new(codigo, Vector2i(480, 320))
	bandera.custom_minimum_size = Vector2(250, 166)
	bandera.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bandera.fuerza = 0.8
	v.add_child(bandera)
	var fuente: Font = get_meta("fuente_titulo", null)
	var nombre := _etiqueta(String((Idiomas.NOMBRES.get(codigo, ["?"]) as Array)[0]), 34, TEXTO, fuente)
	v.add_child(nombre)
	v.add_child(_etiqueta(String(_textos.get("pregunta", "")), 20, ORO, fuente))
	v.add_child(_etiqueta(String(_textos.get("nota", "")), 14, SUAVE))
	if not _textos_actual.is_empty():
		var otra := _etiqueta(String(_textos_actual.get("pregunta", "")), 13, Color(SUAVE, 0.8))
		otra.add_theme_constant_override("line_spacing", 0)
		v.add_child(otra)
	var hueco := Control.new()
	hueco.custom_minimum_size = Vector2(0, 8)
	v.add_child(hueco)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 16)
	v.add_child(fila)
	boton_otro = _boton(String(_textos.get("otro", "")), false)
	boton_si = _boton(String(_textos.get("si", "")), true)
	fila.add_child(boton_otro)
	fila.add_child(boton_si)
	boton_otro.focus_neighbor_right = boton_otro.get_path_to(boton_si)
	boton_si.focus_neighbor_left = boton_si.get_path_to(boton_otro)
	## Arriba y abajo no salen del cuadro (detrás están las tarjetas).
	for b: Button in [boton_si, boton_otro]:
		b.focus_neighbor_top = b.get_path_to(b)
		b.focus_neighbor_bottom = b.get_path_to(b)
	boton_si.pressed.connect(_aceptar)
	boton_otro.pressed.connect(cerrar)
	## Entra con un fundido y un pequeño «acercarse»: aparece, no salta.
	modulate.a = 0.0
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.94, 0.94)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.18)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_panel.resized.connect(func() -> void: _panel.pivot_offset = _panel.size * 0.5)
	## Al momento (no diferido): la pantalla engancha el sonido de foco DESPUÉS de
	## añadir el cuadro, así el foco inicial no suena encima del «abrir».
	boton_si.grab_focus()

func _etiqueta(texto: String, tam: int, color: Color, fuente: Font = null) -> Label:
	var l := Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(420, 0)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	if fuente != null:
		l.add_theme_font_override("font", fuente)
	return l

func _boton(texto: String, principal: bool) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(190, 46)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", 17)
	## El sonido lo pone la pantalla (uno propio al pasar y al elegir).
	b.set_meta("sin_sonido", true)
	var fondo := Color(ORO, 0.92) if principal else Color(1, 1, 1, 0.06)
	var tinta := Color("16130b") if principal else TEXTO
	for estado: String in ["normal", "hover", "pressed", "focus"]:
		var e := StyleBoxFlat.new()
		e.set_corner_radius_all(10)
		e.bg_color = fondo
		e.border_color = Color(ORO, 0.55 if not principal else 0.0)
		e.set_border_width_all(1)
		if estado == "hover" or estado == "focus":
			e.bg_color = fondo.lightened(0.12) if principal else Color(1, 1, 1, 0.12)
			e.border_color = Color(1, 1, 1, 0.9) if principal else ORO
			e.set_border_width_all(2)
			e.shadow_color = Color(ORO, 0.35)
			e.shadow_size = 10
		elif estado == "pressed":
			e.bg_color = fondo.darkened(0.15)
		b.add_theme_stylebox_override(estado, e)
	for c: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		b.add_theme_color_override(c, tinta)
	return b

func _aceptar() -> void:
	if _cerrando:
		return
	_cerrando = true
	aceptado.emit(codigo)

## Se cierra sin elegir («Elegir otro», Esc o B del mando).
func cerrar() -> void:
	if _cerrando:
		return
	_cerrando = true
	cancelado.emit()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.14)
	tw.tween_callback(queue_free)

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrar()
