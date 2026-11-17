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
	s.content_margin_top = 5
	s.content_margin_bottom = 5
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
		b.add_theme_font_size_override("font_size", Tema.letra(17))
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

static func _interruptor(padre: Control, clave: String, texto: String, defecto: bool, extra := Callable()) -> void:
	var c := CheckButton.new()
	c.text = Idiomas.t(texto)
	c.button_pressed = bool(OpcionesPartido.leer(clave, defecto))
	c.add_theme_font_override("font", EstiloAvanzar.fuente_titulo())
	c.add_theme_font_size_override("font_size", Tema.letra(19))
	c.add_theme_stylebox_override("normal", _estilo(NAVY))
	c.add_theme_stylebox_override("hover", _estilo(NAVY.lightened(0.1)))
	c.add_theme_stylebox_override("pressed", _estilo(NAVY))
	c.add_theme_stylebox_override("hover_pressed", _estilo(NAVY.lightened(0.1)))
	c.toggled.connect(func(si: bool) -> void:
		OpcionesPartido.guardar(clave, si)
		if extra.is_valid():
			extra.call(si))
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
	## EL SORTEO DE VERDAD (17-11): la moneda gira y cae; cara = saca el local. El resultado ya está decidido (`MenuPartido.saca_local`, semilla estable por partido).
	var gana: Club = m.partido.local if m.saca_local else m.partido.visita
	moneda.text = "C" if m.saca_local else "S"
	var t := EstiloAvanzar.etiqueta(Idiomas.t("SACA %s") % gana.nombre.to_upper(), 44, Color.WHITE, true)
	t.name = "SacaClub"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var n := nota(v, "Sorteo de campo: gana el sorteo tu club." if gana == m.mio else "Sorteo de campo: gana el sorteo el rival.")
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if not m.sorteo_visto and not Animar.reducidas():
		m.sorteo_visto = true
		t.modulate.a = 0.0
		n.modulate.a = 0.0
		moneda.pivot_offset = moneda.custom_minimum_size * 0.5
		var tw := moneda.create_tween()
		for i in 6:
			tw.tween_property(moneda, "scale:x", 0.06, 0.09)
			tw.tween_property(moneda, "scale:x", 1.0, 0.09)
		tw.tween_callback(func() -> void: Sonido.toca("clic"))
		tw.tween_property(t, "modulate:a", 1.0, 0.25)
		tw.parallel().tween_property(n, "modulate:a", 1.0, 0.25)
	m.sorteo_visto = true
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
	campo.custom_minimum_size = Vector2(300, 170)
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

const SECCIONES := [["modo", "Cómo jugarlo"], ["partido", "Partido"], ["pantalla", "En pantalla"], ["sonido", "Sonido"]]

## Opciones generales: cuatro secciones (cómo jugarlo, partido, en pantalla, sonido) con sus botones arriba; cada una enseña solo lo suyo.
static func opciones(m: MenuPartido, v: VBoxContainer, seccion := "modo") -> void:
	var cont := VBoxContainer.new()
	cont.add_theme_constant_override("separation", 6)
	var barra := chips(v, SECCIONES, seccion, func(c: String) -> void:
		for h in v.get_children():
			h.queue_free()
		opciones(m, v, c))
	barra.name = "Secciones"
	v.add_child(cont)
	match seccion:
		"modo":
			cap(cont, "Cómo quieres este partido")
			chips(cont, MODOS, m.opcion, func(c: String) -> void: m.opcion = c)
			cap(cont, "Si lo simulas")
			chips(cont, [["instantaneo", "Al instante"], ["resumen", "Resumen"], ["vivo", "En vivo"]], m.sim, func(c: String) -> void: m.sim = c)
			var rec := CheckBox.new()
			rec.text = Idiomas.t("No volver a preguntar (se cambia en Ajustes)")
			rec.button_pressed = m.recordar
			rec.toggled.connect(func(si: bool) -> void: m.recordar = si)
			cont.add_child(rec)
		"partido":
			cap(cont, "Dificultad de la CPU")
			var dif: Array = []
			for k: String in MotorJugable.ORDEN_DIFICULTAD:
				dif.append([k, String(MotorJugable.DIFICULTADES[k]["nombre"])])
			chips(cont, dif, VistaEstadio.dificultad_cpu_guardada(), func(c: String) -> void: OpcionesPartido.guardar("dificultad_cpu8", c))
			cap(cont, "Duración")
			chips(cont, OpcionesPartido.RITMOS, String(OpcionesPartido.leer("ritmo_partido", "normal")), func(c: String) -> void: OpcionesPartido.guardar("ritmo_partido", c))
			cap(cont, "Estilo de juego (jugabilidad)")
			var pre: Array = []
			for k: String in MotorJugable.ORDEN_PRESETS:
				pre.append([k, String(MotorJugable.PRESETS[k]["nombre"])])
			chips(cont, pre, VistaEstadio.preset_guardado(), func(c: String) -> void: OpcionesPartido.guardar("preset_juego", c))
			cap(cont, "Reglas y ayudas")
			for g: Array in OpcionesPartido.GENERALES:
				_interruptor(cont, String(g[0]), String(g[1]), bool(g[2]))
			_interruptor(cont, "control_equipo", "🎮 Controlar a mi equipo desde el inicio", false)
		"pantalla":
			_interruptor(cont, "nombres", "🏷 Nombres de los jugadores", PlayerSpawner.mostrar_nombres, func(si: bool) -> void: PlayerSpawner.mostrar_nombres = si)
			for g: Array in OpcionesPartido.PANTALLA:
				_interruptor(cont, String(g[0]), String(g[1]), bool(g[2]))
			_interruptor(cont, "calidad_auto", "⚡ Calidad automática", Calidad.adaptativa, func(si: bool) -> void: Calidad.adaptativa = si)
		"sonido":
			OpcionesPartido.construir_sonido(cont)

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
