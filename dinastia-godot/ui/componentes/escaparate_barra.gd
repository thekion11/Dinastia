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
static func boton_pestana(texto: String, ancho := 150.0) -> Button:   ## `ancho`: ancho mínimo (los tres de la izquierda miden igual, los de la derecha también)
	var b := Button.new()
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_ALL
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN   ## (17-11) cada botón mide lo que su rótulo: el escudo queda centrado y nada se recorta
	var ancho_txt := ThemeDB.fallback_font.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	b.custom_minimum_size = Vector2(maxf(ancho, ancho_txt + 14.0), ALTO - 8)
	b.clip_contents = true
	b.tooltip_text = texto
	b.set_meta("rotulo", texto)
	## El rótulo es una Label propia (no el texto del botón): así la escala tipográfica de los menús no le cambia el tamaño.
	var l := EstiloAvanzar.etiqueta(texto, 17, Color(1, 1, 1, 0.8), true)
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

## Un botón de la barra que NO es una pestaña (Despacho, Mensajes, los atajos de la derecha): plano, blanco, con su contador si hay.
static func _accion(texto: String, al_pulsar: Callable, alerta := false) -> Button:
	var b := boton_pestana(texto, 150.0)
	b.toggle_mode = false
	if alerta:
		b.get_node("Rotulo").add_theme_color_override("font_color", Color("ffc857"))
	b.pressed.connect(al_pulsar)
	return b

## Después de la pestaña «Avanzar en el tiempo»: Despacho · N y Mensajes · N, el escudo en medio, los atajos de la derecha (lo que NO está en la barra lateral) y la caja con la fecha.
## (17-11, diseño del dueño) La barra lateral izquierda vuelve a estar siempre visible: aquí no se repite ningún menú del club.
static func completar(p: Principal, hb: HBoxContainer, tabs: Array[Button], c: Club) -> void:
	hb.set_meta("tabs", tabs)
	p._guia.nodos["escaparate_barra"] = hb   ## el tutorial señala la barra cuando lo que busca (estado, registro, tabla) queda tapado por el escaparate
	var n_desp: int = p._ui_despacho.asuntos_pendientes().size() if p._ui_despacho != null else 0
	var d := _accion(Idiomas.t("Despacho") + (" · %d" % n_desp if n_desp > 0 else ""), func() -> void: EscaparatePantalla.de(p).abrir_despacho(p), n_desp > 0)
	d.name = "BotonDespacho"
	hb.add_child(d)
	var n_msg := EscaparatePie.sin_leer(p)
	var m := _accion(Idiomas.t("Mensajes") + (" · %d" % n_msg if n_msg > 0 else ""), func() -> void: EscaparatePantalla.de(p).abrir_informe(p), n_msg > 0)
	m.name = "BotonMensajes"
	hb.add_child(m)
	var separador := Control.new()   ## empuja los atajos de la derecha: entre los dos grupos queda sitio de sobra para el escudo
	separador.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	separador.custom_minimum_size.x = 70   ## el hueco del escudo (que va centrado en el área útil, fuera de esta fila)
	separador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(separador)
	var pant: Control = EscaparatePantalla.de(p)
	var corona := Control.new()   ## (17-11) el escudo, centrado en el área útil (sin la barra lateral), colgando de la barra como en el PES
	corona.name = "Corona"
	corona.anchor_left = 0.5; corona.anchor_right = 0.5
	corona.offset_left = -33.0; corona.offset_right = 33.0; corona.offset_top = 2.0; corona.offset_bottom = 68.0   ## (17-11) el escudo DENTRO de la altura de la barra: no tapa ninguna tarjeta
	corona.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var esc := TextureRect.new()
	esc.texture = Escudo.textura(c, 96)
	esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	esc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	esc.set_anchors_preset(Control.PRESET_FULL_RECT)
	corona.add_child(esc)
	var tocar_esc := Button.new()   ## el escudo se pulsa: lleva a la identidad del club (colores, escudo, apodo)
	tocar_esc.flat = true
	tocar_esc.focus_mode = Control.FOCUS_ALL
	tocar_esc.set_anchors_preset(Control.PRESET_FULL_RECT)
	tocar_esc.tooltip_text = Idiomas.t("Identidad visual")
	tocar_esc.pressed.connect(func() -> void: TableroInicio.abrir(p, "Identidad visual"))
	corona.add_child(tocar_esc)
	pant.add_child(corona)
	for par: Array in [["Oficina del DT", "Mi carrera"], ["Base de datos", "Ligas y clubes"], ["Sistema", "*sistema"]]:
		var b := boton_pestana(Idiomas.t(String(par[0])), 90.0)
		b.toggle_mode = false
		var destino := String(par[1])
		if destino == "Ligas y clubes":   ## «Base de datos»: abre un cuadro con el BUSCADOR y la puerta a «Ligas y clubes»
			b.pressed.connect(func() -> void: EscaparatePantalla.de(p).abrir_busqueda(b))
		elif destino == "*sistema":   ## «Sistema»: guardar, cargar, salir, ayuda y glosario, créditos (los ajustes del juego están en la barra lateral)
			b.pressed.connect(func() -> void: EscaparatePantalla.de(p).abrir_sistema(p))
		else:
			b.pressed.connect(func() -> void: TableroInicio.abrir(p, destino))
		hb.add_child(b)
	var fecha := EstiloAvanzar.etiqueta("%d/%d/%d" % _fecha_corta(p), 13, Color(1, 1, 1, 0.9))   ## (17-11, dueño) el saldo ya no sale en el menú central (solo en Finanzas): en la barra queda la fecha
	fecha.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fecha.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fecha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(fecha)
	## ARRIBA A LA DERECHA, el sitio fijo de salida: dentro del PC de la oficina «Levantarse del PC» (también Esc; autoguarda); fuera, «Entrar al club».
	var pc := pc_de(p)
	var salir := _accion(Idiomas.t("Levantarse del PC") if pc != null else Idiomas.t("Entrar al club"),
		(func() -> void: pc.apagar()) if pc != null else (func() -> void: MenuLateral.ejecutar(p, "ciudad_pie" if InterruptorCiudad.activa else "ver_estadio")))
	salir.name = "BotonLevantarse" if pc != null else "BotonEntrarClub"
	salir.icon = IconosUI.textura("🚪" if pc != null else "🏟️", 22)   ## icono dibujado, no emoji
	salir.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	salir.add_theme_constant_override("h_separation", 8)
	salir.custom_minimum_size.x = 120
	hb.add_child(salir)
	_equilibrar(hb, separador)

## El PC de la oficina (`visor/pc_oficina.gd`): si el menú es su capa, su padre es el CanvasLayer del PC y el abuelo tiene `apagar` («🚪 Levantarse del PC»). Null si el menú va solo.
static func pc_de(p: Principal) -> Node:
	var capa := p.get_parent()
	if capa is CanvasLayer and capa.get_parent() != null and capa.get_parent().has_method("apagar"):
		return capa.get_parent()
	return null

## La fecha en corto (d/m/aaaa): la larga no cabe en la barra.
static func _fecha_corta(p: Principal) -> Array:
	var f := Calendario.fecha(p.mundo.anio, p.mundo.semana, p._dia_semana)
	return [int(f["day"]), int(f["month"]), int(f["year"])]

## Reparte la barra en DOS MITADES IGUALES a cada lado del escudo (que va en el centro real del ancho útil): a la izquierda las tres pestañas, a la derecha los tres atajos, la fecha y la salida;
## los botones de cada mitad se reparten el aire (mismo aire a ambos lados).
static func _equilibrar(hb: HBoxContainer, separador: Control) -> void:
	var izq := HBoxContainer.new()
	var der := HBoxContainer.new()
	var lado := izq
	for h in hb.get_children():
		hb.remove_child(h)
		if h == separador:
			lado = der
			continue
		lado.add_child(h)
	for g: HBoxContainer in [izq, der]:
		g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.size_flags_stretch_ratio = 1.0
		g.add_theme_constant_override("separation", 8)
		for h in g.get_children():
			if h is Button and not String(h.name).begins_with("BotonEntrar") and not String(h.name).begins_with("BotonLev"):
				(h as Button).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	der.alignment = BoxContainer.ALIGNMENT_END
	separador.size_flags_horizontal = Control.SIZE_FILL
	separador.custom_minimum_size.x = 76
	hb.add_child(izq)
	hb.add_child(separador)
	hb.add_child(der)
