class_name CajonAjustes
extends Control
## EL CAJÓN DE AJUSTES (25-9-2026, plan maestro B1). Pedido del usuario: *"no
## todos los ajustes deben estar visibles, por ejemplo en el partido; eso debe
## ser modificable en una barra de ajustes que se despliegue"*.
##
## Un botón ⚙ fijo en una esquina; al pulsarlo entra desde la derecha un panel
## con secciones (Transmisión, Partido, Visual, Sonido). Sobre la transmisión
## quedan el marcador, el reloj y el ⚙: nada más tapa el partido.
##
## - Se cierra solo tras `CIERRE_SOLO` segundos sin tocarlo (el ratón encima
##   cuenta como tocarlo), con Esc, o volviendo a pulsar el ⚙.
## - Recuerda si lo dejaste abierto (`user://ajustes.cfg`, sección `hud`),
##   por pantalla: cada una lo crea con su propia `clave`.
## - Se construye con `seccion()`, `boton()`, `interruptor()`, `deslizador()` y
##   `fila()`: la pantalla que lo usa no toca la maquetación.
##
## Uso:
##   var cajon := CajonAjustes.crear(self, "partido3d")
##   cajon.seccion("Transmisión")
##   cajon.boton("📷 Cámara", _rotar_camara)

signal abierto_cambiado(abierto: bool)

const ANCHO := 300.0
const CIERRE_SOLO := 6.0
const RUTA := "user://ajustes.cfg"
const SECCION := "hud"

var clave := ""
var abierto := false
var boton_engranaje: Button
var _panel: PanelContainer
var _lista: VBoxContainer
var _quieto := 0.0
var _tween: Tween

static func crear(padre: Control, clave_pantalla: String) -> CajonAjustes:
	var c := CajonAjustes.new()
	c.clave = clave_pantalla
	c.name = "CajonAjustes"
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(c)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c._montar()
	return c

func _montar() -> void:
	boton_engranaje = Button.new()
	boton_engranaje.text = "⚙"
	boton_engranaje.tooltip_text = "Ajustes"
	boton_engranaje.add_theme_font_size_override("font_size", 20)
	boton_engranaje.custom_minimum_size = Vector2(40, 40)
	boton_engranaje.focus_mode = Control.FOCUS_NONE
	add_child(boton_engranaje)
	boton_engranaje.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	boton_engranaje.offset_left = -58
	boton_engranaje.offset_right = -18
	boton_engranaje.offset_top = 14
	boton_engranaje.offset_bottom = 54
	boton_engranaje.pressed.connect(alternar)

	_panel = PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.05, 0.08, 0.07, 0.97)
	st.border_color = Color(1, 1, 1, 0.10)
	st.border_width_left = 1
	st.corner_radius_top_left = 12
	st.corner_radius_bottom_left = 12
	st.content_margin_left = 16
	st.content_margin_right = 14
	st.content_margin_top = 14
	st.content_margin_bottom = 14
	st.shadow_color = Color(0, 0, 0, 0.45)
	st.shadow_size = 14
	_panel.add_theme_stylebox_override("panel", st)
	add_child(_panel)
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 1.0
	_panel.offset_top = 64
	_panel.offset_bottom = -16
	## Si algo pidiera más ancho, que crezca hacia dentro de la pantalla, nunca
	## hacia fuera (el borde derecho es la pared).
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.clip_contents = true
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(ANCHO - 30.0, 0)
	_panel.add_child(scroll)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 6)
	scroll.add_child(_lista)
	_panel.mouse_entered.connect(func() -> void: _quieto = 0.0)
	_panel.gui_input.connect(func(_e: InputEvent) -> void: _quieto = 0.0)
	_colocar(false, false)
	if _leer_abierto():
		abrir(false)

## --- construcción -----------------------------------------------------------

func seccion(titulo: String) -> Label:
	var l := Label.new()
	l.text = titulo.to_upper()
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color("8fa99a"))
	if _lista.get_child_count() > 0:
		var sep := Control.new()
		sep.custom_minimum_size = Vector2(0, 6)
		_lista.add_child(sep)
	_lista.add_child(l)
	return l

func boton(texto: String, accion: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text = true
	b.custom_minimum_size = Vector2(0, 34)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func() -> void:
		_quieto = 0.0
		accion.call())
	_lista.add_child(b)
	return b

func interruptor(texto: String, valor: bool, al_cambiar: Callable) -> CheckButton:
	var c := CheckButton.new()
	c.text = texto
	c.tooltip_text = texto
	## Un botón no parte la línea: con el texto recortado, un rótulo largo no
	## ensancha el cajón (antes empujaba el panel fuera de la pantalla).
	c.clip_text = true
	c.button_pressed = valor
	c.focus_mode = Control.FOCUS_NONE
	c.toggled.connect(func(si: bool) -> void:
		_quieto = 0.0
		al_cambiar.call(si))
	_lista.add_child(c)
	return c

func deslizador(texto: String, valor: float, al_cambiar: Callable) -> HSlider:
	var fila_v := VBoxContainer.new()
	fila_v.add_theme_constant_override("separation", 0)
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", 13)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fila_v.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = valor
	s.focus_mode = Control.FOCUS_NONE
	s.value_changed.connect(func(v: float) -> void:
		_quieto = 0.0
		al_cambiar.call(v))
	fila_v.add_child(s)
	_lista.add_child(fila_v)
	return s

## Varios botones en una misma línea (por ejemplo, zoom − / +).
func fila(botones: Array) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	for par: Array in botones:
		var b := Button.new()
		b.text = String(par[0])
		b.clip_text = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 32)
		b.focus_mode = Control.FOCUS_NONE
		var accion: Callable = par[1]
		b.pressed.connect(func() -> void:
			_quieto = 0.0
			accion.call())
		h.add_child(b)
	_lista.add_child(h)
	return h

## --- abrir y cerrar ----------------------------------------------------------

func alternar() -> void:
	if abierto:
		cerrar()
	else:
		abrir()

func abrir(animar: bool = true) -> void:
	abierto = true
	_quieto = 0.0
	_colocar(true, animar)
	_guardar_abierto()
	abierto_cambiado.emit(true)

func cerrar(animar: bool = true) -> void:
	abierto = false
	_colocar(false, animar)
	_guardar_abierto()
	abierto_cambiado.emit(false)

func _colocar(dentro: bool, animar: bool) -> void:
	var izq := -ANCHO - 16.0 if dentro else 8.0
	var der := -16.0 if dentro else ANCHO + 8.0
	boton_engranaje.text = "✕" if dentro else "⚙"
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if not animar or not is_inside_tree():
		_panel.offset_left = izq
		_panel.offset_right = der
		_panel.visible = dentro
		return
	_panel.visible = true
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_panel, "offset_left", izq, 0.22)
	_tween.tween_property(_panel, "offset_right", der, 0.22)
	if not dentro:
		_tween.chain().tween_callback(func() -> void: _panel.visible = false)

func _process(delta: float) -> void:
	if not abierto:
		return
	if _panel.get_global_rect().has_point(get_global_mouse_position()):
		_quieto = 0.0
		return
	_quieto += delta
	if _quieto >= CIERRE_SOLO:
		cerrar()

func _unhandled_input(e: InputEvent) -> void:
	if abierto and e is InputEventKey and (e as InputEventKey).pressed and (e as InputEventKey).keycode == KEY_ESCAPE:
		cerrar()
		get_viewport().set_input_as_handled()

## --- memoria -------------------------------------------------------------------

func _leer_abierto() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA) != OK:
		return false
	return bool(cfg.get_value(SECCION, "cajon_" + clave, false))

func _guardar_abierto() -> void:
	var cfg := ConfigFile.new()
	cfg.load(RUTA)
	cfg.set_value(SECCION, "cajon_" + clave, abierto)
	cfg.save(RUTA)
