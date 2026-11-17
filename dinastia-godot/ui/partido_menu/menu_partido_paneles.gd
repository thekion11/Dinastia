class_name PanelesMenuPartido
extends RefCounted
## LOS SEIS PANELES DEL MENÚ DEL PARTIDO (17-11-2026, maqueta): Uniforme, Estadio, Saque inicial, Plan de juego, Opciones generales y Cámara. Cada uno rellena el
## contenedor que le da `MenuPartido`. Lo que se cambia aquí es REAL (la pizarra del club, las preferencias del partido) salvo lo que se dice en su nota.

const NAVY := Color("1b2a4a")
const ROJO := Color("c8102e")
const NOTA := Color("9aa6c4")

static func cap(padre: Control, texto: String) -> void:
	var l := EstiloAvanzar.etiqueta(Idiomas.t(texto), 13, NOTA, false, true)
	l.add_theme_constant_override("outline_size", 0)
	padre.add_child(l)

static func nota(padre: Control, texto: String) -> Label:
	var l := EstiloAvanzar.etiqueta(Idiomas.t(texto), 15, NOTA)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	padre.add_child(l)
	return l

static func _estilo(col: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

## Una fila de botones de la que se elige uno (el activo en rojo, el resto azul marino). `al_elegir(clave)`.
static func chips(padre: Control, opciones: Array, actual: String, al_elegir: Callable) -> HFlowContainer:
	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", 6)
	fila.add_theme_constant_override("v_separation", 6)
	var lista: Array[Button] = []
	for par: Array in opciones:
		var b := Button.new()
		b.text = Idiomas.t(String(par[1]))
		b.add_theme_font_override("font", EstiloAvanzar.fuente_titulo())
		b.add_theme_font_size_override("font_size", Tema.letra(19))
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.add_theme_color_override("font_pressed_color", Color.WHITE)
		b.add_theme_color_override("font_focus_color", Color.WHITE)
		b.toggle_mode = true
		b.button_pressed = String(par[0]) == actual
		b.add_theme_stylebox_override("normal", _estilo(NAVY))
		b.add_theme_stylebox_override("hover", _estilo(NAVY.lightened(0.12)))
		b.add_theme_stylebox_override("pressed", _estilo(ROJO))
		b.add_theme_stylebox_override("hover_pressed", _estilo(ROJO.lightened(0.1)))
		var f := _estilo(NAVY)
		f.border_color = Color.WHITE
		f.set_border_width_all(2)
		b.add_theme_stylebox_override("focus", f)
		var clave := String(par[0])
		b.pressed.connect(func() -> void:
			for o in lista:
				o.set_pressed_no_signal(o == b)
			al_elegir.call(clave))
		lista.append(b)
		fila.add_child(b)
	padre.add_child(fila)
	return fila

static func _interruptor(padre: Control, clave: String, texto: String, defecto: bool) -> void:
	var c := CheckButton.new()
	c.text = Idiomas.t(texto)
	c.button_pressed = bool(OpcionesPartido.leer(clave, defecto))
	c.add_theme_font_override("font", EstiloAvanzar.fuente_titulo())
	c.add_theme_font_size_override("font_size", Tema.letra(19))
	c.add_theme_stylebox_override("normal", _estilo(NAVY))
	c.add_theme_stylebox_override("hover", _estilo(NAVY.lightened(0.1)))
	c.add_theme_stylebox_override("pressed", _estilo(NAVY))
	c.add_theme_stylebox_override("hover_pressed", _estilo(NAVY.lightened(0.1)))
	c.toggled.connect(func(si: bool) -> void: OpcionesPartido.guardar(clave, si))
	padre.add_child(c)

# ---------------------------------------------------------------- UNIFORME
const UNIFORMES := [["titular", "Titular"], ["alternativa", "Alternativa"], ["tercera", "Tercera"]]

static func colores_uniforme(c: Club, cual: String) -> Array:
	var c1 := Color(c.kit_color1 if c.kit_color1 != "" else c.color1)
	var c2 := Color(c.kit_color2 if c.kit_color2 != "" else c.color2)
	match cual:
		"alternativa": return [c2, c1]
		"tercera": return [Color("151c33"), c1]
	return [c1, c2]

static func uniforme(m: MenuPartido, v: VBoxContainer) -> void:
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 14)
	v.add_child(fila)
	var actual := String(OpcionesPartido.leer("uniforme_partido", "titular"))
	var marcos: Dictionary = {}
	for par: Array in UNIFORMES:
		var col := colores_uniforme(m.mio, String(par[0]))
		var b := Button.new()
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(150, 240)
		b.button_pressed = String(par[0]) == actual
		b.add_theme_stylebox_override("normal", _estilo(Color(1, 1, 1, 0.06)))
		var sel := _estilo(Color(ROJO, 0.16))
		sel.border_color = ROJO
		sel.set_border_width_all(2)
		for k in ["pressed", "hover_pressed", "focus", "hover"]:
			b.add_theme_stylebox_override(k, sel)
		var caja := VBoxContainer.new()
		caja.set_anchors_preset(Control.PRESET_FULL_RECT)
		caja.alignment = BoxContainer.ALIGNMENT_CENTER
		caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var fig := FiguraClub.new()
		fig.textura = EstiloAvanzar.figura(col[0], col[1])
		fig.dorsal = m.dorsal_estrella(m.mio)
		fig.custom_minimum_size = Vector2(120, 190)
		fig.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caja.add_child(fig)
		var t := EstiloAvanzar.etiqueta(Idiomas.t(String(par[1])), 20, Color.WHITE, true)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caja.add_child(t)
		b.add_child(caja)
		var clave := String(par[0])
		marcos[clave] = b
		b.pressed.connect(func() -> void:
			for k: String in marcos:
				(marcos[k] as Button).set_pressed_no_signal(k == clave)
			OpcionesPartido.guardar("uniforme_partido", clave)
			m.poner_uniforme(clave))
		fila.add_child(b)
	nota(v, "El rival usa su uniforme titular; si chocan los colores, cambia solo. (La elección se ve en esta pantalla; el partido 3D usa los colores del club.)")

# ---------------------------------------------------------------- ESTADIO
static func estadio(m: MenuPartido, v: VBoxContainer) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 30)
	v.add_child(fila)
	var izq := VBoxContainer.new()
	izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	izq.add_theme_constant_override("separation", 8)
	fila.add_child(izq)
	var local := m.partido.local
	izq.add_child(EstiloAvanzar.etiqueta(local.estadio_nombre if local.estadio_nombre != "" else Idiomas.t("Estadio de %s") % local.nombre, 32, Color.WHITE, true))
	nota(izq, Idiomas.t("%d espectadores") % local.estadio_aforo)
	cap(izq, "Clima del partido")
	var texto := String(m.clima.get("texto", ""))
	var etiq := EstiloAvanzar.etiqueta("%s %s" % [Clima.icono(m.clima), texto] if not m.clima.is_empty() else Idiomas.t("Sin datos"), 22, Color.WHITE, true)
	etiq.add_theme_stylebox_override("normal", _estilo(ROJO))
	etiq.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	izq.add_child(etiq)
	nota(izq, "El clima lo pone la ciudad y la época del año; el estadio es el del equipo local.")
	var mini := MiniaturaMenu.new()
	mini.tipo = MiniaturaMenu.Tipo.ESTADIO
	mini.custom_minimum_size = Vector2(300, 170)
	fila.add_child(mini)

# ---------------------------------------------------------------- SAQUE INICIAL
static func saque(m: MenuPartido, v: VBoxContainer) -> void:
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var moneda := Label.new()
	moneda.text = "C"
	moneda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moneda.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	moneda.custom_minimum_size = Vector2(110, 80)
	moneda.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	moneda.add_theme_font_override("font", EstiloAvanzar.fuente_titulo())
	moneda.add_theme_font_size_override("font_size", Tema.letra(46))
	moneda.add_theme_color_override("font_color", Color("6b4a0c"))
	var d := Tema.caja(Color("e8b93d"), 40)
	d.border_color = Color("a87c1a")
	d.set_border_width_all(3)
	moneda.add_theme_stylebox_override("normal", d)
	v.add_child(moneda)
	var t := EstiloAvanzar.etiqueta(Idiomas.t("SACA %s") % m.partido.local.nombre.to_upper(), 44, Color.WHITE, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var n := nota(v, "El motor del partido aún no sortea el saque: el saque inicial lo hace siempre el equipo local.")
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var b := PantallaMaqueta.boton(Idiomas.t("Empezar partido"), true, 24)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(m.confirmar)
	v.add_child(b)

# ---------------------------------------------------------------- PLAN DE JUEGO
const MENTALIDAD := [["0", "Defensivo"], ["1", "Equilibrado"], ["2", "Ofensivo"]]
const NIVELES := [["0", "Baja"], ["1", "Media"], ["2", "Alta"]]

static func plan(m: MenuPartido, v: VBoxContainer) -> void:
	var t: Tactica = m.mio.tactica
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 26)
	v.add_child(fila)
	var izq := VBoxContainer.new()
	izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	izq.add_theme_constant_override("separation", 6)
	fila.add_child(izq)
	var forms: Dictionary = Datos.tabla("FORMS")
	var campo := MiniaturaMenu.new()
	campo.tipo = MiniaturaMenu.Tipo.CAMPO
	campo.custom_minimum_size = Vector2(300, 190)
	campo.acento = ROJO
	campo.formacion = (forms.get(t.formacion, {}) as Dictionary).get("s", [])
	var por_formacion: Array = []
	for k: String in forms.keys():
		por_formacion.append([k, k])
	cap(izq, "Formación")
	chips(izq, por_formacion, t.formacion, func(c: String) -> void:
		t.formacion = c
		campo.formacion = (forms.get(c, {}) as Dictionary).get("s", [])
		campo.queue_redraw()
		m.al_cambiar_plan())
	cap(izq, "Estilo de juego")
	chips(izq, MENTALIDAD, str(t.mentalidad), func(c: String) -> void:
		t.mentalidad = int(c)
		m.al_cambiar_plan())
	cap(izq, "Presión")
	chips(izq, NIVELES, str(t.presion), func(c: String) -> void:
		t.presion = int(c)
		m.al_cambiar_plan())
	cap(izq, "Línea defensiva")
	chips(izq, NIVELES, str(t.linea), func(c: String) -> void:
		t.linea = int(c)
		m.al_cambiar_plan())
	fila.add_child(campo)

# ---------------------------------------------------------------- OPCIONES GENERALES
const MODOS := [["jugar", "Jugar"], ["importantes", "Solo las importantes"], ["simular", "Simular"]]

static func opciones(m: MenuPartido, v: VBoxContainer) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 30)
	v.add_child(fila)
	var izq := VBoxContainer.new()
	izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	izq.add_theme_constant_override("separation", 6)
	fila.add_child(izq)
	cap(izq, "Cómo quieres este partido")
	chips(izq, MODOS, m.opcion, func(c: String) -> void: m.opcion = c)
	cap(izq, "Si lo simulas")
	chips(izq, [["instantaneo", "Al instante"], ["resumen", "Resumen"], ["vivo", "En vivo"]], m.sim, func(c: String) -> void: m.sim = c)
	cap(izq, "Dificultad de la CPU")
	var dif: Array = []
	for k: String in MotorJugable.ORDEN_DIFICULTAD:
		dif.append([k, String(MotorJugable.DIFICULTADES[k]["nombre"])])
	chips(izq, dif, VistaEstadio.dificultad_cpu_guardada(), func(c: String) -> void: OpcionesPartido.guardar("dificultad_cpu8", c))
	cap(izq, "Duración")
	chips(izq, OpcionesPartido.RITMOS, String(OpcionesPartido.leer("ritmo_partido", "normal")), func(c: String) -> void: OpcionesPartido.guardar("ritmo_partido", c))
	cap(izq, "Estilo de juego (jugabilidad)")
	var pre: Array = []
	for k: String in MotorJugable.ORDEN_PRESETS:
		pre.append([k, String(MotorJugable.PRESETS[k]["nombre"])])
	chips(izq, pre, VistaEstadio.preset_guardado(), func(c: String) -> void: OpcionesPartido.guardar("preset_juego", c))
	var der := VBoxContainer.new()
	der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	der.add_theme_constant_override("separation", 6)
	fila.add_child(der)
	cap(der, "Ajustes")
	for g: Array in OpcionesPartido.GENERALES + OpcionesPartido.PANTALLA:
		_interruptor(der, String(g[0]), String(g[1]), bool(g[2]))
	_interruptor(der, "nombres", "🏷 Nombres de los jugadores", PlayerSpawner.mostrar_nombres)
	var sonido := VBoxContainer.new()
	OpcionesPartido.construir_sonido(sonido)
	der.add_child(sonido)
	var rec := CheckBox.new()
	rec.text = Idiomas.t("No volver a preguntar (se cambia en Ajustes)")
	rec.button_pressed = m.recordar
	rec.toggled.connect(func(si: bool) -> void: m.recordar = si)
	der.add_child(rec)

# ---------------------------------------------------------------- CÁMARA
const CAMARAS := [["cerca", "Cerca", 0.1], ["normal", "Normal", 0.45], ["lejos", "Alejada", 0.9]]

static func camara(_m: MenuPartido, v: VBoxContainer) -> void:
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 14)
	v.add_child(fila)
	var actual := VistaEstadio.pro_camara_guardada()
	var marcos: Dictionary = {}
	for par: Array in CAMARAS:
		var b := Button.new()
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(230, 190)
		b.button_pressed = String(par[0]) == actual
		b.add_theme_stylebox_override("normal", _estilo(Color(1, 1, 1, 0.05)))
		var sel := _estilo(Color(ROJO, 0.14))
		sel.border_color = ROJO
		sel.set_border_width_all(2)
		for k in ["pressed", "hover_pressed", "focus", "hover"]:
			b.add_theme_stylebox_override(k, sel)
		var caja := VBoxContainer.new()
		caja.set_anchors_preset(Control.PRESET_FULL_RECT)
		caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mini := MiniaturaMenu.new()
		mini.tipo = MiniaturaMenu.Tipo.CAMARA
		mini.zoom = float(par[2])
		mini.custom_minimum_size = Vector2(0, 130)
		mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caja.add_child(mini)
		var t := EstiloAvanzar.etiqueta(Idiomas.t(String(par[1])), 20, Color.WHITE, true)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caja.add_child(t)
		b.add_child(caja)
		var clave := String(par[0])
		marcos[clave] = b
		b.pressed.connect(func() -> void:
			for k: String in marcos:
				(marcos[k] as Button).set_pressed_no_signal(k == clave)
			OpcionesPartido.guardar("pro_camara", clave))
		fila.add_child(b)
	nota(v, "La distancia de la cámara Pro (la de jugar). Dentro del partido se cambia de cámara y se acerca o aleja con los botones del cajón.")
