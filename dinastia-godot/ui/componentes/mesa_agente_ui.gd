class_name MesaAgenteUI
extends Control
## LA MESA DEL REPRESENTANTE, en pantalla (MEGAPLAN fase 4). Muestra la
## lógica de `MesaAgente`: el agente con su perfil, lo que pide hoy, las tazas
## de paciencia, lo último que dijo con su señal, y las jugadas (tres ofertas,
## el farol, ceder o plantarse). Al terminar llama a `al_cerrar(mesa)`.

const FONDO := Color(0.03, 0.035, 0.04, 0.94)
const MADERA := Color("3a2a1c")
const MADERA_CLARA := Color("5a4128")
const ORO := Color("d9b44a")

var mesa: MesaAgente
var al_cerrar: Callable
var _pide: Label
var _barra: ProgressBar
var _tazas: Label
var _dice: Label
var _ronda: Label
var _jugadas: VBoxContainer

func _init(m: MesaAgente, cerrar: Callable) -> void:
	mesa = m
	al_cerrar = cerrar
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(820.0, get_viewport_rect().size.x - 32.0), 0)
	var e := StyleBoxFlat.new()
	e.bg_color = MADERA
	e.border_color = MADERA_CLARA
	e.set_border_width_all(3)
	e.set_corner_radius_all(14)
	e.content_margin_left = 26; e.content_margin_right = 26
	e.content_margin_top = 20; e.content_margin_bottom = 20
	e.shadow_size = 18
	e.shadow_color = Color(0, 0, 0, 0.5)
	panel.add_theme_stylebox_override("panel", e)
	centro.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	v.add_child(_lbl(Idiomas.t("🤝 LA MESA DEL REPRESENTANTE"), 13, ORO))
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 16)
	v.add_child(cab)
	var cara := _lbl(mesa.emoji(), 54, Color.WHITE)
	cara.custom_minimum_size = Vector2(74, 74)
	cara.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cab.add_child(cara)
	var datos := VBoxContainer.new()
	datos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(datos)
	datos.add_child(_lbl(mesa.agente, 24, Color.WHITE))
	var perfil := _lbl(Idiomas.t("Perfil: %s  ·  exige: %s") % [_perfil(), _exige()], 13, Color(0.85, 0.8, 0.7))
	perfil.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	datos.add_child(perfil)
	_ronda = _lbl("", 12, Color(0.75, 0.7, 0.6))
	datos.add_child(_ronda)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	v.add_child(fila)
	_pide = _lbl("", 18, ORO)
	_pide.custom_minimum_size = Vector2(250, 0)
	fila.add_child(_pide)
	_barra = ProgressBar.new()
	_barra.max_value = 100
	_barra.show_percentage = false
	_barra.custom_minimum_size = Vector2(0, 16)
	_barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bf := StyleBoxFlat.new()
	bf.bg_color = ORO
	bf.set_corner_radius_all(6)
	var bb := StyleBoxFlat.new()
	bb.bg_color = Color(0, 0, 0, 0.35)
	bb.set_corner_radius_all(6)
	_barra.add_theme_stylebox_override("fill", bf)
	_barra.add_theme_stylebox_override("background", bb)
	fila.add_child(_barra)
	_tazas = _lbl("", 22, Color.WHITE)
	fila.add_child(_tazas)

	var bocadillo := PanelContainer.new()
	var eb := StyleBoxFlat.new()
	eb.bg_color = Color(0.96, 0.93, 0.86)
	eb.set_corner_radius_all(10)
	eb.content_margin_left = 16; eb.content_margin_right = 16
	eb.content_margin_top = 12; eb.content_margin_bottom = 12
	bocadillo.add_theme_stylebox_override("panel", eb)
	v.add_child(bocadillo)
	_dice = _lbl("", 15, Color(0.12, 0.1, 0.08))
	_dice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dice.custom_minimum_size = Vector2(0, 48)
	bocadillo.add_child(_dice)

	_jugadas = VBoxContainer.new()
	_jugadas.add_theme_constant_override("separation", 8)
	v.add_child(_jugadas)
	_pintar()

## El estado con el que se pintó la última vez: el sonido del desenlace suena
## una sola vez, al pasar de «abierta» a otra cosa.
var _estado_previo := "abierta"

func _pintar() -> void:
	var abierta := mesa.estado == "abierta"
	_pide.text = Idiomas.t("Pide: %d %%  (%s)") % [mesa.pide, Idiomas.t(mesa.detalle(mesa.pide))] if abierta else _final_corto()
	_pide.add_theme_font_size_override("font_size", 15 if abierta else 18)
	## El desenlace con su color: verde si hay trato, rojo si se fue, neutro si
	## te plantaste. Antes los tres salían en el mismo dorado que «Pide».
	_pide.add_theme_color_override("font_color", ORO if abierta else _color_final())
	_barra.value = mesa.pide if abierta else float(mesa.acordado)
	_tazas.text = "☕".repeat(maxi(0, mesa.paciencia)) + "·".repeat(maxi(0, mesa.paciencia_max - maxi(0, mesa.paciencia)))
	_tazas.tooltip_text = Idiomas.t("Paciencia: cada ronda gasta una taza")
	_ronda.text = Idiomas.t("Ronda %d") % mesa.ronda if mesa.ronda > 0 else Idiomas.t("Primera ronda: tú mueves")
	## Lo que dice el representante llega del núcleo en castellano: se traduce al pintarlo.
	_dice.text = Idiomas.t(mesa.ultima)
	if mesa.estado != _estado_previo:
		_estado_previo = mesa.estado
		Sonido.toca("contrato" if mesa.estado == "acuerdo" else "error", Sonido.Bus.INTERFAZ)
	for h in _jugadas.get_children():
		h.queue_free()
	if not abierta:
		var bc := _boton(Idiomas.t("Cerrar la mesa"), func() -> void:
			queue_free()
			al_cerrar.call(mesa), _jugadas, _color_final())
		bc.grab_focus.call_deferred()
		return
	var ofertas := HBoxContainer.new()
	ofertas.add_theme_constant_override("separation", 8)
	_jugadas.add_child(ofertas)
	var primero: Button = null
	for o: int in mesa.ofertas():
		var b := _boton(Idiomas.t("Ofrecer %d %%") % o + "\n" + Idiomas.t(mesa.detalle(o)), func() -> void:
			mesa.regatear(o)
			_pintar(), ofertas, Color(0.86, 0.82, 0.74))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if primero == null:
			primero = b
	var otras := HBoxContainer.new()
	otras.add_theme_constant_override("separation", 8)
	_jugadas.add_child(otras)
	var bf := _boton(Idiomas.t("🃏 Farol: %s") % Idiomas.t(mesa.texto_farol()), func() -> void:
		mesa.farol()
		_pintar(), otras, Color(0.7, 0.85, 1.0))
	bf.disabled = mesa.farol_usado
	bf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bf.clip_text = true
	bf.tooltip_text = bf.text
	_boton(Idiomas.t("Ceder (%d %%)") % mesa.pide, func() -> void:
		mesa.ceder()
		_pintar(), otras, Color(0.6, 0.9, 0.6))
	_boton(Idiomas.t("Plantarse"), func() -> void:
		mesa.plantarse()
		_pintar(), otras, Color(1.0, 0.6, 0.55))
	## Con teclado o mando, el foco empieza en la primera oferta: sin esto no
	## había ningún botón enfocado y las flechas no hacían nada hasta pulsar Tab.
	if primero != null:
		primero.grab_focus.call_deferred()

func _color_final() -> Color:
	match mesa.estado:
		"acuerdo":
			return Color(0.55, 0.9, 0.55)
		"se_fue":
			return Color(1.0, 0.5, 0.45)
		_:
			return Color(0.85, 0.8, 0.7)

func _final_corto() -> String:
	match mesa.estado:
		"acuerdo":
			return Idiomas.t("✔ TRATO al %d %%  (%s)") % [mesa.acordado, Idiomas.t(mesa.detalle(mesa.acordado))]
		"se_fue":
			return Idiomas.t("✖ SE FUE DE LA MESA")
		_:
			return Idiomas.t("TE PLANTASTE")

func _perfil() -> String:
	return {"tiburon": Idiomas.t("tiburón"), "mediatico": Idiomas.t("mediático"), "formador": Idiomas.t("formador")}.get(mesa.perfil, Idiomas.t("discreto"))

func _exige() -> String:
	return {"mejora": Idiomas.t("mejorar un contrato"), "comision": Idiomas.t("una comisión por debajo de la mesa"),
		"canterano": Idiomas.t("que fiches a su canterano")}.get(mesa.tipo, Idiomas.t("exclusividad"))

func _lbl(t: String, tam: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	return l

func _boton(t: String, accion: Callable, padre: Node, col: Color) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_size_override("font_size", 13)
	var e := StyleBoxFlat.new()
	e.bg_color = Color(col, 0.18)
	e.border_color = col
	e.set_border_width_all(2)
	e.set_corner_radius_all(8)
	e.content_margin_left = 12; e.content_margin_right = 12
	var eh := e.duplicate() as StyleBoxFlat
	eh.bg_color = Color(col, 0.34)
	b.add_theme_stylebox_override("normal", e)
	b.add_theme_stylebox_override("hover", eh)
	b.add_theme_stylebox_override("pressed", eh)
	var ed := e.duplicate() as StyleBoxFlat
	ed.bg_color = Color(0.2, 0.2, 0.2, 0.3)
	ed.border_color = Color(0.4, 0.4, 0.4)
	b.add_theme_stylebox_override("disabled", ed)
	## El foco, bien visible sobre la madera: borde dorado grueso. El estilo
	## por defecto (un marco fino claro) apenas se distinguía del borde normal.
	var ef := StyleBoxFlat.new()
	ef.draw_center = false
	ef.border_color = ORO
	ef.set_border_width_all(3)
	ef.set_corner_radius_all(9)
	ef.expand_margin_left = 2; ef.expand_margin_right = 2
	ef.expand_margin_top = 2; ef.expand_margin_bottom = 2
	b.add_theme_stylebox_override("focus", ef)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.pressed.connect(accion)
	padre.add_child(b)
	return b
