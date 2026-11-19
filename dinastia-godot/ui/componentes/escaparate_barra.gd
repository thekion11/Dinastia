class_name EscaparateBarra
extends RefCounted
## LA BARRA DE ARRIBA DEL MENÚ CENTRAL, COMO LA DE LA LIGA MASTER DEL PES 2020 (17-11-2026, orden del dueño vía Auditoría): UNA sola capa de navegación, a todo el
## ancho y con el COLOR DEL CLUB; las tres pestañas de siempre a la izquierda (Avanzar en el tiempo / Dirección del equipo / Información del club), el ESCUDO del
## club grande y centrado asomando sobre la barra, y a la derecha los atajos (Oficina del DT, Base de datos, Sistema) y la caja y la fecha. La cabecera con cifras, la
## tira de días y el riel de iconos dejan de verse en esta vista (la tira de días vive ahora en la pantalla «Avanzar»; el riel se abre con ☰).
## Las pestañas siguen siendo `mos.find_child("Botones").get_meta("tabs")` (L1/R1 las recorren, `TableroInicio.saltar`).

const ALTO := 64.0

## El color de la barra: el del club, ni tan claro que no se lea el blanco ni tan oscuro que parezca negro.
static func color_de(c: Club) -> Color:
	var col := Color(c.color1)
	var otro := Color(c.color2)
	if col.get_luminance() > 0.4 and otro.get_luminance() < col.get_luminance() - 0.15:
		col = otro   ## camiseta clara (blanca, amarilla): la barra toma el otro color del club
	if col.get_luminance() > 0.36:
		col = col.darkened(0.45)
	elif col.get_luminance() < 0.05:
		col = col.lightened(0.28)
	return col

## Crea la barra dentro de `mos` y devuelve el HBox donde se ponen las pestañas.
static func crear(mos: VBoxContainer, c: Club) -> HBoxContainer:
	var col := color_de(c)
	var panel := PanelContainer.new()
	panel.name = "Barra"
	panel.custom_minimum_size.y = ALTO
	var st := StyleBoxFlat.new()
	st.bg_color = col
	st.border_color = col.darkened(0.45)
	st.border_width_bottom = 4
	st.shadow_color = Color(0, 0, 0, 0.45)
	st.shadow_size = 10
	st.shadow_offset = Vector2(0, 4)
	st.content_margin_left = 14
	st.content_margin_right = 14
	panel.add_theme_stylebox_override("panel", st)
	mos.add_child(panel)
	var hb := HBoxContainer.new()
	hb.name = "Botones"
	hb.add_theme_constant_override("separation", 8)
	panel.add_child(hb)
	return hb

## Una pestaña de la barra: texto grande, plano, blanco; la activa lleva la raya blanca de abajo.
static func boton_pestana(texto: String, ancho := 1.35) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_ALL
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_stretch_ratio = ancho
	b.custom_minimum_size = Vector2(80, ALTO - 8)
	b.clip_contents = true
	b.tooltip_text = texto
	b.set_meta("rotulo", texto)
	## El rótulo es una Label propia (no el texto del botón): así la escala tipográfica de los menús no le cambia el tamaño.
	var l := EstiloAvanzar.etiqueta(texto, 19, Color(1, 1, 1, 0.8), true)
	l.name = "Rotulo"
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
	l.add_theme_constant_override("outline_size", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(l)
	b.toggled.connect(func(si: bool) -> void: l.add_theme_color_override("font_color", Color.WHITE if si else Color(1, 1, 1, 0.8)))
	var vacio := StyleBoxEmpty.new()
	var activa := StyleBoxFlat.new()
	activa.bg_color = Color(1, 1, 1, 0.12)
	activa.border_color = Color.WHITE
	activa.border_width_bottom = 5
	var foco := StyleBoxFlat.new()
	foco.bg_color = Color(1, 1, 1, 0.2)
	foco.border_color = Color.WHITE
	foco.set_border_width_all(2)
	b.add_theme_stylebox_override("normal", vacio)
	b.add_theme_stylebox_override("hover", foco)
	b.add_theme_stylebox_override("pressed", activa)
	b.add_theme_stylebox_override("hover_pressed", activa)
	b.add_theme_stylebox_override("focus", foco)
	return b

## Después de las tres pestañas: el escudo en medio, los atajos a la derecha y la caja con la fecha.
static func completar(p: Principal, hb: HBoxContainer, tabs: Array[Button], c: Club) -> void:
	hb.set_meta("tabs", tabs)
	p._guia.nodos["escaparate_barra"] = hb   ## el tutorial señala la barra cuando lo que busca (estado, registro, tabla) queda tapado por el escaparate
	var menu := Button.new()   ## ☰ abre el cajón de menús (el riel de iconos ya no se ve en esta vista)
	menu.flat = true
	menu.text = "☰"
	menu.focus_mode = Control.FOCUS_ALL
	menu.custom_minimum_size = Vector2(52, ALTO - 8)
	menu.add_theme_font_size_override("font_size", Tema.letra(28))
	menu.tooltip_text = Idiomas.t("Todos los menús")
	menu.pressed.connect(func() -> void: if p._menu_lateral != null: p._menu_lateral.alternar())
	hb.add_child(menu)
	hb.move_child(menu, 0)
	var hueco := Control.new()   ## el escudo asoma por encima de la barra: no empuja a nadie
	hueco.custom_minimum_size = Vector2(128, 0)
	hueco.clip_contents = false
	var esc := TextureRect.new()
	esc.texture = Escudo.textura(c, 112)
	esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	esc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	esc.z_index = 3   ## por encima de las tarjetas que tiene debajo
	esc.position = Vector2(8, 2)   ## pegado al borde de arriba y colgando por debajo de la barra, como en el PES
	esc.size = Vector2(112, 112)
	hueco.add_child(esc)
	hb.add_child(hueco)
	hb.move_child(hueco, 4)   ## ☰, las tres pestañas y, ahora, el escudo
	for par: Array in [["Oficina del DT", "Mi carrera"], ["Base de datos", "Ligas y clubes"], ["Sistema", "*sistema"]]:
		var b := boton_pestana(Idiomas.t(String(par[0])))
		b.toggle_mode = false
		var destino := String(par[1])
		if destino == "Ligas y clubes":   ## «Base de datos»: abre un cuadro con el BUSCADOR y la puerta a «Ligas y clubes»
			b.pressed.connect(func() -> void: EscaparatePantalla.de(p).abrir_busqueda(b))
		else:
			b.pressed.connect(func() -> void: TableroInicio.abrir(p, destino))
		hb.add_child(b)
	var caja := VBoxContainer.new()
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_theme_constant_override("separation", -4)
	caja.custom_minimum_size.x = 130
	## (18-11, veredicto del dueño sobre el boceto 2) el saldo NO va en el menú central: solo en Finanzas. Aquí queda la fecha.
	var fecha := EstiloAvanzar.etiqueta(p.fecha_larga(), 11, Color(1, 1, 1, 0.8))
	fecha.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	caja.add_child(fecha)
	hb.add_child(caja)
