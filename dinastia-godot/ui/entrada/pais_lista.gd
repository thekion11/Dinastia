class_name PaisLista
extends PanelContainer
## LA LISTA DE PAÍSES de la pantalla de país: la vía rápida y accesible al lado del
## globo (los pines del globo son pequeños y en móvil cuesta acertarles). Agrupada por
## continente, cada fila con su bandera y el NOMBRE COMPLETO. Con teclado o mando se
## recorre con arriba/abajo (lo hace la pantalla con `vecino()`).

signal elegido(pais: String)

var _botones: Dictionary = {}   ## pais -> Button
var _grupo := ButtonGroup.new()
var _scroll: ScrollContainer

func _ready() -> void:
	var caja := Tema.caja(Color(Tema.PANEL, 0.86), Tema.RADIO_GRANDE, Tema.BORDE)
	add_theme_stylebox_override("panel", caja)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	_scroll.add_child(v)
	for c: Array in PaisDatos.CONTINENTES:
		var r := Tema.rotulo(Idiomas.t(String(c[0])))
		r.add_theme_color_override("font_color", Tema.ORO)
		if v.get_child_count() > 0:
			var hueco := Control.new()
			hueco.custom_minimum_size = Vector2(0, 6)
			v.add_child(hueco)
		v.add_child(r)
		for p: String in c[1]:
			v.add_child(_fila(p))

func _fila(p: String) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.button_group = _grupo
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.text = PaisDatos.nombre(p)
	b.icon = Banderas.textura(p)
	b.expand_icon = false
	b.add_theme_constant_override("icon_max_width", 26)
	b.add_theme_constant_override("h_separation", 10)
	b.add_theme_font_size_override("font_size", Tema.TAM_CUERPO)
	b.custom_minimum_size = Vector2(0, 30)
	b.focus_mode = Control.FOCUS_NONE
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(1, 1, 1, 0.0)
	normal.set_corner_radius_all(Tema.RADIO_CHICO)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	var encima := normal.duplicate() as StyleBoxFlat
	encima.bg_color = Color(1, 1, 1, 0.06)
	var marcado := normal.duplicate() as StyleBoxFlat
	marcado.bg_color = Color(Tema.ORO, 0.22)
	marcado.border_color = Tema.ORO
	marcado.border_width_left = 3
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", encima)
	b.add_theme_stylebox_override("pressed", marcado)
	b.add_theme_stylebox_override("hover_pressed", marcado)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	if not PaisDatos.tiene_liga(p):
		b.add_theme_color_override("font_color", Tema.SUAVE)
		b.tooltip_text = Idiomas.t("Este país aún no tiene liga en el juego.")
	b.pressed.connect(func() -> void: elegido.emit(p))
	_botones[p] = b
	return b

## Marca un país sin emitir nada (cuando se elige desde el globo) y lo deja a la vista.
func marcar(p: String) -> void:
	var b: Button = _botones.get(p)
	if b == null:
		return
	## Sin señal, el ButtonGroup no suelta al anterior: se sueltan todos a mano.
	for otro: Button in _botones.values():
		otro.set_pressed_no_signal(otro == b)
	if is_inside_tree():
		_scroll.ensure_control_visible.call_deferred(b)

## El país anterior o siguiente en el orden de la lista (para teclado y mando).
func vecino(p: String, paso: int) -> String:
	var orden := PaisDatos.todos()
	var i := orden.find(p)
	if i < 0:
		return orden[0]
	return orden[posmod(i + paso, orden.size())]

func boton(p: String) -> Button:
	return _botones.get(p)
