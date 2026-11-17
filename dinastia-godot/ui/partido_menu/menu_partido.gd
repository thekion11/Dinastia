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
var saca_local := true         ## el sorteo del saque inicial (se decide al abrir; va a `partido.saca_local` al confirmar)
var sorteo_visto := false      ## la moneda gira solo la primera vez
var _cuerpo: VBoxContainer     ## el contenido del panel abierto
var _botones: Dictionary = {}
var _modal: Control             ## la pantalla completa de la pestaña abierta (fondo de la previa + su tarjeta)
var _titulo_modal: Label
var _pie: Label
var _abierta := ""
var _fig_mio: Control
var _por_montar: Array[Control] = []

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
	saca_local = sorteo(partido, competicion, clima)
	var fondo := FondoPrevia.new()
	fondo.color = _color_club(l)
	fondo.color_b = _color_club(v)
	add_child(fondo)
	PreviaMenuPartido.cabecera(self, l, v)
	_montar_figuras(l, v)
	PreviaMenuPartido.alineaciones(self, l, v)
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

## El jugador mejor del once (el que sale grande), con su dorsal.
func dorsal_estrella(c: Club) -> int:
	var mejor := estrella(c)
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
	var uni := String(OpcionesPartido.leer("uniforme_partido", "titular"))
	for lado in 2:
		var c: Club = l if lado == 0 else v
		var caja := _caja(0.0, 0.3, 0.03, 0.85) if lado == 0 else _caja(0.7, 1.0, 0.03, 0.85)
		var cols := PanelesMenuPartido.colores_uniforme(c, uni if c == mio else "titular")
		## El futbolista 3D real con su equipación (sin pantalla, la figura plana).
		var fig: Control = load("res://ui/partido_menu/retrato_jugador3d.gd").crear(c, estrella(c), [] if c != mio or uni == "titular" else cols, 0.38 if lado == 0 else -0.38)
		if fig == null:
			fig = _figura(c, cols)
			caja.anchor_top = 0.14
			caja.anchor_bottom = 0.9
		fig.set_anchors_preset(Control.PRESET_FULL_RECT)
		caja.add_child(fig)
		if c == mio:
			_fig_mio = fig
		if fig.has_method("montar"):
			_por_montar.append(fig)
	_montar_retratos.call_deferred()

## Los retratos 3D se montan después de abrir (uno por cuadro): el menú sale al instante y los jugadores aparecen con un fundido.
func _montar_retratos() -> void:
	for f: Control in _por_montar:
		await get_tree().process_frame
		if is_instance_valid(f):
			f.call("montar")
	_por_montar.clear()

## El jugador que sale grande: el mejor del once.
func estrella(c: Club) -> Jugador:
	var mejor: Jugador = null
	for j: Jugador in c.once():
		if mejor == null or j.ovr > mejor.ovr:
			mejor = j
	return mejor

## El uniforme elegido se ve en la figura de TU club (sea el local o el visitante).
func poner_uniforme(clave: String) -> void:
	if _fig_mio == null:
		return
	var col := PanelesMenuPartido.colores_uniforme(mio, clave)
	if _fig_mio is FiguraClub:
		(_fig_mio as FiguraClub).textura = EstiloAvanzar.figura(col[0], col[1])
		_fig_mio.queue_redraw()
	else:
		_fig_mio.call("vestir", [] if clave == "titular" else col)

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

func _montar_barra() -> void:
	var barra := _caja(0.03, 0.97, 0.855, 0.92)
	var f := HBoxContainer.new()
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	f.add_theme_constant_override("separation", 12)
	barra.add_child(f)
	for par: Array in PESTANAS:
		var b := PreviaMenuPartido.pestana(String(par[0]), String(par[1]))
		var clave := String(par[0])
		b.pressed.connect(_abrir.bind(clave))
		f.add_child(b)
		_botones[clave] = b

func _montar_modal() -> void:
	## (17-11, dueño) Cada pestaña es una PANTALLA COMPLETA: tapa la previa (fondo propio con los colores de los dos clubes) y deja abajo la barra de
	## pestañas para saltar de una a otra; B / Esc vuelve a la previa.
	_modal = Control.new()
	_modal.anchor_right = 1.0; _modal.anchor_bottom = 0.845
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	var fondo := FondoPrevia.new()
	fondo.color = _color_club(partido.local)
	fondo.color_b = _color_club(partido.visita)
	_modal.add_child(fondo)
	var tarjeta := PanelContainer.new()
	tarjeta.anchor_left = 0.05; tarjeta.anchor_right = 0.95; tarjeta.anchor_top = 0.05; tarjeta.anchor_bottom = 0.97
	_modal.add_child(tarjeta)
	var sb := PanelesMenuPartido._estilo(Color("0a0e1b"))
	sb.border_color = Color("1f2a47")
	sb.set_border_width_all(1)
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 22
	sb.content_margin_bottom = 18
	sb.bg_color = Color(sb.bg_color, 0.9)
	tarjeta.add_theme_stylebox_override("panel", sb)
	_modal.visible = false
	add_child(_modal)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	tarjeta.add_child(v)
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
	_pie.anchor_left = 0.3; _pie.anchor_right = 0.7; _pie.anchor_top = 0.795; _pie.anchor_bottom = 0.83
	add_child(_pie)
	var ayuda := HBoxContainer.new()
	ayuda.add_theme_constant_override("separation", 22)
	for par: Array in [["B", "Volver", Color("e0592a")]]:   ## el «Confirmar» es solo el botón rojo (Auditoría: no dos)
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
	b.offset_left = -240; b.offset_right = -40; b.offset_top = -52; b.offset_bottom = -8
	b.pressed.connect(confirmar)
	add_child(b)
	b.grab_focus.call_deferred()

func _abrir(clave: String) -> void:
	if clave == _abierta and _modal.visible:
		cerrar_panel()
		return
	if clave == "plan" and _abrir_tactica_del_juego():
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

## (17-11, dueño: «el plan de juego es la alineación; ya tenemos una pantalla de eso») «Plan de juego» abre la pantalla de TÁCTICA del juego, a pantalla
## completa (menú lateral «Partido» → Táctica: pizarra, formación, órdenes y el once). La previa se esconde mientras tanto y vuelve al cerrarla, con
## el plan nuevo en su pie. Sin menú lateral (pruebas), queda el panel propio.
func _abrir_tactica_del_juego() -> bool:
	var pr := get_parent()
	var ml = pr.get("_menu_lateral") if pr != null else null
	if ml == null or not (ml as Node).is_inside_tree():
		return false
	var sub := -1
	for m: Dictionary in MenusLaterales.MENUS:
		if String(m["id"]) != "partido":
			continue
		var subs: Array = m["subs"]
		for i in subs.size():
			if String((subs[i] as Dictionary).get("tab", "")) == "Táctica" and sub < 0:
				sub = i
	if sub < 0:
		return false
	var pm = ml.abrir_menu("partido", sub)
	if pm == null:
		return false
	visible = false
	pm.cerrada.connect(func() -> void:
		visible = true
		cerrar_panel()
		_abierta = "plan"
		_resumen()
		_abierta = "")
	return true

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

## El sorteo del saque: semilla estable por partido (los dos clubes, la competición y el clima del día, que depende de la fecha), sin tocar el azar global.
static func sorteo(p: Partido, comp: String, info_clima: Dictionary) -> bool:
	var r := RandomNumberGenerator.new()
	r.seed = hash("%s|%s|%s|%s" % [p.local.id, p.visita.id, comp, str(info_clima)])
	return r.randi() % 2 == 0

func _elegir(op: String) -> void:
	partido.saca_local = saca_local
	var e := EleccionPartido.eleccion(op, sim)
	EleccionPartido.aplicar(e)
	if recordar:
		EleccionPartido.fijar_preguntar(false)
	Sonido.toca("clic")
	elegido.emit(e)
