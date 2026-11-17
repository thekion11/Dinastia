class_name MenuPartido
extends Control
## EL MENÚ DEL PARTIDO (17-11-2026, orden del dueño), como la previa de la maqueta (referencia: la previa de la Liga Master de PES 2020): fondo dual con los colores de
## los dos clubes, los dos jugadores grandes con su camiseta, los escudos con el emblema de la competición en medio, los nombres de los clubes con sus once titulares y,
## abajo, las seis pestañas (Uniforme · Estadio · Saque inicial · Plan de juego · Opciones generales · Cámara) que abren su panel en el centro. «Confirmar» (A) empieza.
## Emite `elegido` con lo mismo que `EleccionPartido` ({modo, control, ocasiones}): el resto del flujo no cambia. TODOS los ajustes del partido viven aquí
## (`OpcionesPartido` y `PanelesMenuPartido`). Los paneles viven en `menu_partido_paneles.gd`; los dibujos, en `menu_partido_dibujos.gd` y `menu_partido_figura.gd`.

signal elegido(eleccion: Dictionary)

const PESTANAS := [["uniforme", "Uniforme"], ["estadio", "Estadio"], ["saque", "Saque inicial"], ["plan", "Plan de juego"], ["opciones", "Opciones generales"], ["camara", "Cámara"]]

var partido: Partido
var mio: Club
var liga_rival: Liga
var clima := {}
var competicion := "Liga"
var opcion := "jugar"          ## jugar / importantes / simular
var sim := "resumen"           ## cómo se ve si se simula
var recordar := false          ## «No volver a preguntar»
var _cuerpo: VBoxContainer     ## el contenido del panel abierto
var _botones: Dictionary = {}
var _modal: PanelContainer
var _titulo_modal: Label
var _pie: Label
var _abierta := ""
var _fig_mio: FiguraClub

static func mostrar(padre: Node, p: Partido, mi_club: Club, liga: Liga, info_clima: Dictionary, comp := "Liga") -> MenuPartido:
	var m := MenuPartido.new()
	m.partido = p
	m.mio = mi_club
	m.liga_rival = liga
	m.clima = info_clima
	m.competicion = comp
	padre.add_child(m)
	return m

func _ready() -> void:
	top_level = true
	position = Vector2.ZERO
	size = get_viewport_rect().size
	get_viewport().size_changed.connect(func() -> void: size = get_viewport_rect().size)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var ult := EleccionPartido.ultima()
	if not ult.is_empty():
		match String(ult.get("modo", "")):
			"completo": opcion = "jugar"
			"destacados": opcion = "importantes"
			_:
				opcion = "simular"
				sim = String(ult.get("modo", "resumen"))
	var l := partido.local
	var v := partido.visita
	var fondo := FondoCine.new()
	fondo.modo = FondoCine.Modo.DUAL
	fondo.color = _color_club(l)
	fondo.color_b = _color_club(v)
	fondo.bokeh = true
	add_child(fondo)
	_montar_cabecera(l, v)
	_montar_figuras(l, v)
	_montar_alineaciones(l, v)
	_montar_barra()
	_montar_modal()
	_montar_pie()
	Animar.entrar(self)

static func _color_club(c: Club) -> Color:
	return Color(c.kit_color1 if c.kit_color1 != "" else c.color1)

func _caja(izq: float, der: float, arr: float, aba: float) -> Control:
	var c := Control.new()
	c.anchor_left = izq; c.anchor_right = der; c.anchor_top = arr; c.anchor_bottom = aba
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	return c

func _escudo(c: Club, px: int) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Escudo.textura(c, px)
	t.custom_minimum_size = Vector2(px, px)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return t

func _montar_cabecera(l: Club, v: Club) -> void:
	var chip := EstiloAvanzar.etiqueta(Idiomas.t(competicion), 15, Color.WHITE, false, true)
	chip.add_theme_stylebox_override("normal", PanelesMenuPartido._estilo(Color("1d2d55")))
	chip.position = Vector2(30, 26)
	add_child(chip)
	var c := _caja(0.25, 0.75, 0.03, 0.27)
	var f := HBoxContainer.new()
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	f.alignment = BoxContainer.ALIGNMENT_CENTER
	f.add_theme_constant_override("separation", 56)
	c.add_child(f)
	f.add_child(_escudo(l, 140))
	var em := MiniaturaMenu.new()
	em.tipo = MiniaturaMenu.Tipo.EMBLEMA
	em.custom_minimum_size = Vector2(76, 76)
	em.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	f.add_child(em)
	f.add_child(_escudo(v, 140))

## El jugador mejor del once (el que sale grande), con su dorsal.
func dorsal_estrella(c: Club) -> int:
	var o := c.once()
	var mejor: Jugador = null
	for j: Jugador in o:
		if mejor == null or j.ovr > mejor.ovr:
			mejor = j
	return maxi(mejor.dorsal, 1) if mejor != null else 10

func _figura(c: Club, cols: Array) -> FiguraClub:
	var f := FiguraClub.new()
	var h := absi(c.id.hash())
	var pieles := [Color("f0c8a0"), Color("d9a67c"), Color("b27b52"), Color("8a5a3a")]
	var pelos := [Color("2a1c14"), Color("c9a96b"), Color("151010"), Color("6b3a1c")]
	f.textura = EstiloAvanzar.figura(cols[0], cols[1], pieles[h % 4], pelos[(h / 4) % 4])
	f.dorsal = dorsal_estrella(c)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return f

func _montar_figuras(l: Club, v: Club) -> void:
	var izq := _caja(0.0, 0.25, 0.14, 0.9)
	_fig_mio = _figura(l, PanelesMenuPartido.colores_uniforme(l, String(OpcionesPartido.leer("uniforme_partido", "titular")) if l == mio else "titular"))
	_fig_mio.set_anchors_preset(Control.PRESET_FULL_RECT)
	izq.add_child(_fig_mio)
	var der := _caja(0.75, 1.0, 0.14, 0.9)
	var fv := _figura(v, PanelesMenuPartido.colores_uniforme(v, "titular"))
	fv.set_anchors_preset(Control.PRESET_FULL_RECT)
	der.add_child(fv)

## El uniforme elegido se ve en la figura de TU club (sea el local o el visitante).
func poner_uniforme(clave: String) -> void:
	var f := _fig_mio if partido.local == mio else null
	if f == null:
		return
	var col := PanelesMenuPartido.colores_uniforme(mio, clave)
	f.textura = EstiloAvanzar.figura(col[0], col[1])
	f.queue_redraw()

static func linea_jugador(j: Jugador) -> String:
	var partes := Nombres.visible(j.nombre).split(" ", false)
	var txt := Nombres.visible(j.nombre).to_upper()
	if partes.size() >= 2:
		txt = "%s. %s" % [String(partes[0]).left(1).to_upper(), " ".join(partes.slice(1)).to_upper()]
	if j.pos_e == "POR":
		txt += " (POR)"
	if j.capitan:
		txt += " (C)"
	return txt

func _montar_alineaciones(l: Club, v: Club) -> void:
	var c := _caja(0.27, 0.73, 0.28, 0.82)
	var f := HBoxContainer.new()
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	f.alignment = BoxContainer.ALIGNMENT_CENTER
	f.add_theme_constant_override("separation", 60)
	c.add_child(f)
	for club: Club in [l, v]:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.add_child(_nombre(club.nombre.to_upper(), 54))
		for j: Jugador in club.once():
			var e := EstiloAvanzar.etiqueta(linea_jugador(j), 19, Color(1, 1, 1, 0.92), true)
			e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			col.add_child(e)
		f.add_child(col)

func _nombre(txt: String, tam: int) -> Label:
	var e := EstiloAvanzar.etiqueta(txt, tam, Color.WHITE, true)
	e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return e

func _montar_barra() -> void:
	var barra := _caja(0.03, 0.97, 0.865, 0.935)
	var f := HBoxContainer.new()
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	f.add_theme_constant_override("separation", 12)
	barra.add_child(f)
	for par: Array in PESTANAS:
		var b := Button.new()
		b.text = Idiomas.t(String(par[1]))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.toggle_mode = true
		b.add_theme_font_override("font", EstiloAvanzar.fuente_titulo())
		b.add_theme_font_size_override("font_size", Tema.letra(20))
		var n := PanelesMenuPartido._estilo(Color(0.86, 0.88, 0.94, 0.9))
		b.add_theme_stylebox_override("normal", n)
		b.add_theme_stylebox_override("hover", PanelesMenuPartido._estilo(Color(0.93, 0.94, 0.98, 0.95)))
		var sel := PanelesMenuPartido._estilo(Color.WHITE)
		sel.border_color = PanelesMenuPartido.ROJO
		sel.set_border_width_all(3)
		for k in ["pressed", "hover_pressed", "focus"]:
			b.add_theme_stylebox_override(k, sel)
		for k in ["font_color", "font_hover_color"]:
			b.add_theme_color_override(k, Color("26304f"))
		for k in ["font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(k, PanelesMenuPartido.ROJO)
		var clave := String(par[0])
		b.pressed.connect(_abrir.bind(clave))
		f.add_child(b)
		_botones[clave] = b

func _montar_modal() -> void:
	_modal = PanelContainer.new()
	_modal.anchor_left = 0.21; _modal.anchor_right = 0.79; _modal.anchor_top = 0.235; _modal.anchor_bottom = 0.84
	var sb := PanelesMenuPartido._estilo(Color("0a0e1b"))
	sb.border_color = Color("1f2a47")
	sb.set_border_width_all(1)
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 22
	sb.content_margin_bottom = 18
	_modal.add_theme_stylebox_override("panel", sb)
	_modal.visible = false
	add_child(_modal)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_modal.add_child(v)
	var cab := HBoxContainer.new()
	v.add_child(cab)
	_titulo_modal = EstiloAvanzar.etiqueta("", 38, Color.WHITE, true, true)
	_titulo_modal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(_titulo_modal)
	var x := Button.new()
	x.text = "×"
	x.custom_minimum_size = Vector2(36, 36)
	x.add_theme_stylebox_override("normal", PanelesMenuPartido._estilo(Color("243656")))
	x.add_theme_stylebox_override("hover", PanelesMenuPartido._estilo(Color("34497a")))
	x.pressed.connect(cerrar_panel)
	cab.add_child(x)
	var desliza := ScrollContainer.new()
	desliza.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desliza.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(desliza)
	_cuerpo = VBoxContainer.new()
	_cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cuerpo.add_theme_constant_override("separation", 8)
	desliza.add_child(_cuerpo)

func _montar_pie() -> void:
	_pie = EstiloAvanzar.etiqueta(Idiomas.t("Pulsa Confirmar para empezar el partido"), 18, Color(1, 1, 1, 0.85))
	_pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pie.anchor_left = 0.2; _pie.anchor_right = 0.8; _pie.anchor_top = 0.835; _pie.anchor_bottom = 0.865
	add_child(_pie)
	var ayuda := HBoxContainer.new()
	ayuda.add_theme_constant_override("separation", 22)
	for par: Array in [["A", "Confirmar", Color("27a35a")], ["B", "Volver", Color("e0592a")]]:
		var g := HBoxContainer.new()
		g.add_theme_constant_override("separation", 8)
		var c := Label.new()
		c.text = String(par[0])
		c.custom_minimum_size = Vector2(26, 26)
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_theme_stylebox_override("normal", Tema.caja(par[2], 13))
		g.add_child(c)
		g.add_child(EstiloAvanzar.etiqueta(Idiomas.t(String(par[1])), 14, Color(1, 1, 1, 0.75)))
		ayuda.add_child(g)
	ayuda.anchor_top = 1.0; ayuda.anchor_bottom = 1.0
	ayuda.offset_left = 38; ayuda.offset_top = -48
	add_child(ayuda)
	var b := PantallaMaqueta.boton(Idiomas.t("Confirmar"), true, 22)
	b.name = "Confirmar"
	b.anchor_left = 1.0; b.anchor_right = 1.0; b.anchor_top = 1.0; b.anchor_bottom = 1.0
	b.offset_left = -240; b.offset_right = -40; b.offset_top = -64; b.offset_bottom = -12
	b.pressed.connect(confirmar)
	add_child(b)
	b.grab_focus.call_deferred()

func _abrir(clave: String) -> void:
	if clave == _abierta and _modal.visible:
		cerrar_panel()
		return
	_abierta = clave
	for h in _cuerpo.get_children():
		h.queue_free()
	for k: String in _botones:
		(_botones[k] as Button).set_pressed_no_signal(k == clave)
	var nombre := ""
	for par: Array in PESTANAS:
		if String(par[0]) == clave:
			nombre = String(par[1])
	_titulo_modal.text = Idiomas.t(nombre).to_upper()
	_cuerpo.alignment = BoxContainer.ALIGNMENT_BEGIN
	match clave:
		"uniforme": PanelesMenuPartido.uniforme(self, _cuerpo)
		"estadio": PanelesMenuPartido.estadio(self, _cuerpo)
		"saque": PanelesMenuPartido.saque(self, _cuerpo)
		"plan": PanelesMenuPartido.plan(self, _cuerpo)
		"opciones": PanelesMenuPartido.opciones(self, _cuerpo)
		"camara": PanelesMenuPartido.camara(self, _cuerpo)
	_modal.visible = true
	_resumen()

func cerrar_panel() -> void:
	_modal.visible = false
	_abierta = ""
	for k: String in _botones:
		(_botones[k] as Button).set_pressed_no_signal(false)
	_pie.text = Idiomas.t("Pulsa Confirmar para empezar el partido")

func al_cambiar_plan() -> void:
	_resumen()

func _resumen() -> void:
	var t := mio.tactica
	match _abierta:
		"plan":
			_pie.text = "%s: %s · %s · %s" % [Idiomas.t("Plan de juego"), t.formacion, Idiomas.t(String(PanelesMenuPartido.MENTALIDAD[t.mentalidad][1])).to_lower(),
				Idiomas.t("presión %s") % Idiomas.t(String(PanelesMenuPartido.NIVELES[t.presion][1])).to_lower()]
		"estadio":
			_pie.text = "%s: %s" % [Idiomas.t("Estadio"), partido.local.estadio_nombre if partido.local.estadio_nombre != "" else partido.local.nombre]
		"camara":
			_pie.text = "%s: %s" % [Idiomas.t("Cámara"), Idiomas.t("Pro: %s") % Idiomas.t(String(VistaEstadio.pro_camara_guardada()))]
		"opciones":
			_pie.text = "%s %s" % [Idiomas.t("Dificultad"), Idiomas.t(String(MotorJugable.DIFICULTADES[VistaEstadio.dificultad_cpu_guardada()]["nombre"]))]
		_:
			_pie.text = Idiomas.t("Pulsa Confirmar para empezar el partido")

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel") and _modal.visible:
		get_viewport().set_input_as_handled()
		cerrar_panel()

func confirmar() -> void:
	_elegir(opcion)

func _elegir(op: String) -> void:
	var e := EleccionPartido.eleccion(op, sim)
	EleccionPartido.aplicar(e)
	if recordar:
		EleccionPartido.fijar_preguntar(false)
	Sonido.toca("clic")
	elegido.emit(e)
