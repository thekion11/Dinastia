class_name MenuPartido
extends Control
## EL MENÚ DEL PARTIDO (17-11-2026, orden del dueño; referencia: la previa de la Liga Master de PES 2020). Reemplaza a «¿Cómo quieres este partido?»: pantalla
## completa con la cabecera (escudos, competición, estadio), una columna de pestañas a la izquierda (Previa, Uniforme, Estadio, Plan de juego, Opciones, Cámara)
## y abajo las tres maneras de jugarlo (jugar, solo las importantes, simular). TODOS los ajustes del partido viven en «Opciones» y «Cámara» (`OpcionesPartido`).
## Emite `elegido` con lo mismo que `EleccionPartido` ({modo, control, ocasiones}), así que el resto del flujo no cambia.

signal elegido(eleccion: Dictionary)

const PESTANAS := [["previa", "Previa"], ["uniforme", "Uniforme"], ["estadio", "Estadio"], ["plan", "Plan de juego"], ["opciones", "Opciones"], ["camara", "Cámara"]]

var partido: Partido
var mio: Club
var liga_rival: Liga
var clima := {}
var _sim := "resumen"
var _cuerpo: VBoxContainer
var _botones: Dictionary = {}
var _recordar: CheckBox
var _primera: Button

static func mostrar(padre: Node, p: Partido, mi_club: Club, liga: Liga, info_clima: Dictionary) -> MenuPartido:
	var m := MenuPartido.new()
	m.partido = p
	m.mio = mi_club
	m.liga_rival = liga
	m.clima = info_clima
	padre.add_child(m)
	return m

func _ready() -> void:
	top_level = true
	position = Vector2.ZERO
	size = get_viewport_rect().size
	get_viewport().size_changed.connect(func() -> void: size = get_viewport_rect().size)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var fondo := ColorRect.new()
	fondo.color = Color(Tema.FONDO, 0.98)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var raiz := VBoxContainer.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 40; raiz.offset_right = -40; raiz.offset_top = 24; raiz.offset_bottom = -24
	raiz.add_theme_constant_override("separation", 14)
	add_child(raiz)
	raiz.add_child(_cabecera())
	var medio := HBoxContainer.new()
	medio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	medio.add_theme_constant_override("separation", 22)
	raiz.add_child(medio)
	var lateral := VBoxContainer.new()
	lateral.custom_minimum_size = Vector2(230, 0)
	medio.add_child(lateral)
	var grupo := ButtonGroup.new()
	for par: Array in PESTANAS:
		var b := Button.new()
		b.text = Idiomas.t(String(par[1])).to_upper()
		b.toggle_mode = true
		b.button_group = grupo
		b.custom_minimum_size = Vector2(0, 46)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var clave := String(par[0])
		b.pressed.connect(_abrir.bind(clave))
		lateral.add_child(b)
		_botones[clave] = b
	var desliza := ScrollContainer.new()
	desliza.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desliza.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	medio.add_child(desliza)
	_cuerpo = VBoxContainer.new()
	_cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cuerpo.add_theme_constant_override("separation", 10)
	desliza.add_child(_cuerpo)
	raiz.add_child(_acciones())
	(_botones["previa"] as Button).button_pressed = true
	_abrir("previa")
	_primera.grab_focus.call_deferred()
	Animar.entrar(raiz)

func _cabecera() -> Control:
	var f := HBoxContainer.new()
	f.alignment = BoxContainer.ALIGNMENT_CENTER
	f.add_theme_constant_override("separation", 22)
	f.add_child(MenuPartidoTabs._escudo(partido.local, 72))
	var c := VBoxContainer.new()
	var t := Tema.etiqueta(Tema.TAM_MARCADOR, Tema.ORO, "%s  vs  %s" % [partido.local.nombre, partido.visita.nombre])
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(t)
	var s := Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, Idiomas.t("Antes del partido"))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(s)
	f.add_child(c)
	f.add_child(MenuPartidoTabs._escudo(partido.visita, 72))
	return f

func _abrir(clave: String) -> void:
	for h in _cuerpo.get_children():
		h.queue_free()
	var rival := partido.visita if partido.local == mio else partido.local
	match clave:
		"previa": MenuPartidoTabs.previa(_cuerpo, mio, rival, liga_rival)
		"uniforme": MenuPartidoTabs.uniforme(_cuerpo, partido.local, partido.visita)
		"estadio": MenuPartidoTabs.estadio(_cuerpo, partido.local, clima)
		"plan": MenuPartidoTabs.plan(_cuerpo, mio)
		"opciones": OpcionesPartido.construir(_cuerpo)
		"camara": OpcionesPartido.construir_camara(_cuerpo)

func _acciones() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 16)
	col.add_child(fila)
	_primera = _boton(fila, "🎮 " + Idiomas.t("JUGAR"), "jugar")
	_boton(fila, "🎯 " + Idiomas.t("SOLO LAS IMPORTANTES"), "importantes")
	_boton(fila, "⏩ " + Idiomas.t("SIMULAR"), "simular")
	var sub := HBoxContainer.new()
	sub.alignment = BoxContainer.ALIGNMENT_CENTER
	var grupo := ButtonGroup.new()
	for par: Array in EleccionPartido.SIMULAR:
		var b := Button.new()
		b.text = Idiomas.t(String(par[1]))
		b.toggle_mode = true
		b.button_group = grupo
		b.button_pressed = String(par[0]) == _sim
		var clave := String(par[0])
		b.pressed.connect(func() -> void: _sim = clave)
		sub.add_child(b)
	col.add_child(sub)
	_recordar = CheckBox.new()
	_recordar.text = Idiomas.t("No volver a preguntar (se cambia en Ajustes)")
	_recordar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(_recordar)
	return col

func _boton(padre: Control, texto: String, opcion: String) -> Button:
	var b := Button.new()
	b.name = "Opcion_" + opcion
	b.text = texto
	b.custom_minimum_size = Vector2(250, 64)
	b.add_theme_font_size_override("font_size", Tema.letra(18))
	b.pressed.connect(_elegir.bind(opcion))
	padre.add_child(b)
	return b

func _elegir(opcion: String) -> void:
	var e := EleccionPartido.eleccion(opcion, _sim)
	EleccionPartido.aplicar(e)
	if _recordar.button_pressed:
		EleccionPartido.fijar_preguntar(false)
	Sonido.toca("clic")
	elegido.emit(e)
