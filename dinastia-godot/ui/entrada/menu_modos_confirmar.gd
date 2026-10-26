class_name MenuModosConfirmar
extends Control
## LA CONFIRMACIÓN DEL MENÚ DE MODOS (fase 1, etapa 2). Elegir modo decide la
## partida entera: un clic de más al recorrer la lista con el ratón, o un
## «aceptar» del mando que se escapó, no puede tirar al jugador a otra
## pantalla. Antes de seguir se pregunta, con el modo bien visible.
##
## Se maneja igual con ratón, teclado y mando: el foco empieza en «Empezar»,
## izquierda/derecha cambian de botón y no se puede salir del cuadro con las
## flechas; Esc o B (`ui_cancel`, que recoge `PantallaModos`) cancela.

signal aceptado
signal cancelado

var _velo: ColorRect
var _panel: PanelContainer
var _estilo: StyleBoxFlat
var _lbl_pregunta: Label
var _lbl_titulo: Label
var _lbl_sub: Label
var _btn_si: Button
var _btn_no: Button

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_velo = ColorRect.new()
	_velo.color = Color(0, 0, 0, 0.6)
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_velo.mouse_filter = Control.MOUSE_FILTER_STOP
	## Pulsar fuera del cuadro es «no, todavía no».
	_velo.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			cancelar())
	add_child(_velo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(480, 0)
	_estilo = StyleBoxFlat.new()
	_estilo.bg_color = Color(Tema.PANEL, 0.97)
	_estilo.set_border_width_all(2)
	_estilo.set_corner_radius_all(Tema.RADIO_GRANDE)
	_estilo.set_content_margin_all(26)
	_estilo.shadow_color = Color(0, 0, 0, 0.5)
	_estilo.shadow_size = 24
	_panel.add_theme_stylebox_override("panel", _estilo)
	centro.add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_panel.add_child(v)
	_lbl_pregunta = _etiqueta(14, Tema.SUAVE)
	_lbl_pregunta.text = Idiomas.t("¿Empezar con este modo?")
	v.add_child(_lbl_pregunta)
	_lbl_titulo = _etiqueta(30, Tema.TEXTO)
	v.add_child(_lbl_titulo)
	_lbl_sub = _etiqueta(15, Tema.TEXTO)
	_lbl_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_sub.custom_minimum_size = Vector2(428, 0)
	v.add_child(_lbl_sub)
	var hueco := Control.new()
	hueco.custom_minimum_size = Vector2(0, 8)
	v.add_child(hueco)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	fila.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(fila)
	_btn_no = _boton(Idiomas.t("Cambiar de modo"))
	_btn_no.pressed.connect(cancelar)
	fila.add_child(_btn_no)
	_btn_si = _boton(Idiomas.t("Empezar"))
	_btn_si.pressed.connect(func() -> void:
		if visible:
			visible = false
			aceptado.emit())
	fila.add_child(_btn_si)
	## El foco no se escapa del cuadro: arriba/abajo se quedan donde están.
	for b: Button in [_btn_si, _btn_no]:
		b.focus_neighbor_top = b.get_path_to(b)
		b.focus_neighbor_bottom = b.get_path_to(b)
	_btn_si.focus_neighbor_left = _btn_si.get_path_to(_btn_no)
	_btn_si.focus_neighbor_right = _btn_si.get_path_to(_btn_no)
	_btn_no.focus_neighbor_left = _btn_no.get_path_to(_btn_si)
	_btn_no.focus_neighbor_right = _btn_no.get_path_to(_btn_si)

func abierto() -> bool:
	return visible

## Abre el cuadro con el modo, en el color de su luz.
func abrir(titulo: String, sub: String, luz: Color) -> void:
	_lbl_titulo.text = titulo
	_lbl_titulo.add_theme_color_override("font_color", luz.lerp(Color.WHITE, 0.25))
	_lbl_sub.text = sub
	_estilo.border_color = Color(luz, 0.7)
	_pintar_boton(_btn_si, luz, true)
	_pintar_boton(_btn_no, luz, false)
	visible = true
	_velo.modulate.a = 0.0
	_panel.modulate.a = 0.0
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.94, 0.94)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_velo, "modulate:a", 1.0, 0.18)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.18)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if is_inside_tree():
		_btn_si.grab_focus()

func cancelar() -> void:
	if not visible:
		return
	visible = false
	cancelado.emit()

## Pulsa «Empezar» (pruebas, y el mismo camino que el clic).
func confirmar() -> void:
	if visible:
		_btn_si.pressed.emit()

func boton_empezar() -> Button:
	return _btn_si

func _etiqueta(tam: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l

func _boton(texto: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(150, 42)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", 15)
	## El sonido lo pone `PantallaModos` (aceptar/atrás), no el tic genérico.
	b.set_meta("sin_sonido", true)
	return b

func _pintar_boton(b: Button, luz: Color, principal: bool) -> void:
	for estado in ["normal", "hover", "pressed", "focus"]:
		var e := StyleBoxFlat.new()
		e.set_corner_radius_all(Tema.RADIO)
		e.set_content_margin_all(10)
		var resaltado: bool = estado != "normal"
		if principal:
			e.bg_color = luz.darkened(0.15 if resaltado else 0.35)
		else:
			e.bg_color = Color(1, 1, 1, 0.12 if resaltado else 0.05)
		if estado == "focus":
			e.draw_center = false
			e.set_border_width_all(2)
			e.border_color = Color.WHITE
		b.add_theme_stylebox_override(estado, e)
	b.add_theme_color_override("font_color", Color("0c1510") if principal else Tema.TEXTO)
	b.add_theme_color_override("font_hover_color", Color("0c1510") if principal else Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color("0c1510") if principal else Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color("0c1510") if principal else Color.WHITE)
