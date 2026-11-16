class_name BarraAyudas
extends PanelContainer
## LA BARRA DE ABAJO DEL MENÚ CENTRAL (16-11, frente 1; referencia: la barra inferior de eFootball y de la Liga Master del
## PES 2020). Siempre a la vista: a la izquierda qué hace cada tecla (Intro confirma, Esc vuelve) o, con mando, las ayudas
## de `PieMando` (que se muda aquí: la misma pieza, que solo se ve con mando conectado); luego «Mensajes» con los sin leer
## y «Ayuda» (el glosario), que se pulsan; a la derecha, el reloj. En el teléfono no hay teclas: solo Mensajes, Ayuda y reloj.

const ALTO := 30.0
const CADA := 1.0   ## s entre repasos (reloj, sin leer, mando conectado o no)

var _p: Principal
var _teclas: HBoxContainer
var _mensajes: Button
var _reloj: Label
var _t := 0.0

static func montar(p: Principal, raiz: Container) -> BarraAyudas:
	var b := BarraAyudas.new()
	b._p = p
	b.name = "BarraAyudas"
	raiz.add_child(b)
	return b

func _ready() -> void:
	custom_minimum_size.y = ALTO
	var e := StyleBoxFlat.new()
	e.bg_color = Color(0, 0, 0, 0.55)
	e.border_color = Color(1, 1, 1, 0.08)
	e.border_width_top = 1
	e.set_corner_radius_all(6)
	e.content_margin_left = 12; e.content_margin_right = 12
	e.content_margin_top = 2; e.content_margin_bottom = 2
	add_theme_stylebox_override("panel", e)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	add_child(fila)
	_teclas = HBoxContainer.new()
	_teclas.add_theme_constant_override("separation", 14)
	fila.add_child(_teclas)
	if not EscalaMovil.es_tactil():
		_teclas.add_child(PieMando._chip(Idiomas.t("Intro"), Idiomas.t("Confirmar")))
		_teclas.add_child(PieMando._chip(Idiomas.t("Esc"), Idiomas.t("Atrás")))
	## El pie del mando (si existe) se muda aquí: así no hay dos barras de ayudas.
	for pie in _p.find_children("PieMando", "PieMando", true, false):
		if pie.get_parent() != null:
			pie.get_parent().remove_child(pie)
		fila.add_child(pie)
	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hueco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(hueco)
	_mensajes = _boton("✉ " + Idiomas.t("Mensajes"), func() -> void: TableroInicio.abrir(_p, "Correo"))
	fila.add_child(_mensajes)
	fila.add_child(_boton("? " + Idiomas.t("Ayuda"), func() -> void: TableroInicio.abrir(_p, "Glosario")))
	_reloj = Label.new()
	_reloj.add_theme_font_size_override("font_size", Tema.letra(13))
	_reloj.add_theme_color_override("font_color", Tema.TEXTO)
	_reloj.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(_reloj)
	_repasar()

func _boton(texto: String, al_pulsar: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE   ## el foco del mando se queda en el mosaico: estos se alcanzan con el dedo o el ratón
	b.add_theme_font_size_override("font_size", Tema.letra(12))
	b.add_theme_color_override("font_color", Tema.SUAVE.lightened(0.25))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.pressed.connect(al_pulsar)
	return b

func _process(d: float) -> void:
	_t += d
	if _t >= CADA:
		_t = 0.0
		_repasar()

func _repasar() -> void:
	var h := Time.get_time_dict_from_system()
	_reloj.text = "%02d:%02d" % [int(h["hour"]), int(h["minute"])]
	_teclas.visible = not FocoMando.hay_mando()   ## con mando hablan las ayudas de `PieMando`
	var sin_leer := 0
	var bandeja: Variant = _p.get("_bandeja")
	if bandeja is Array:
		for x: Dictionary in bandeja:
			if not bool(x.get("leida", false)):
				sin_leer += 1
	var t := "✉ " + Idiomas.t("Mensajes") + ("  (%d)" % sin_leer if sin_leer > 0 else "")
	if _mensajes.text != t:
		_mensajes.text = t
		_mensajes.add_theme_color_override("font_color", Tema.oro() if sin_leer > 0 else Tema.SUAVE.lightened(0.25))
