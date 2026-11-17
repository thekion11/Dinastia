class_name EscaparateIndice
extends RefCounted
## LA PESTAÑA «ÍNDICE» DEL MENÚ CENTRAL (17-11-2026, orden del dueño: «no quiero perder los mini menús antiguos; que NADA quede sin conectar»): cada menú del panel lateral (`MenusLaterales.MENUS`)
## con TODOS sus submenús como botones, tal cual están registrados (se leen de los datos, no de una lista aparte: un submenú nuevo aparece solo). Cada botón abre el submenú con
## `MenuLateral.abrir_menu(id, i)`, igual que la barra lateral. Además, «Buscar» (Base de datos) y «Panel lateral» (≡). Las acciones (ver la casa, el móvil, minijuegos…) también salen aquí.

## [id del menú, índice del submenú, rótulo] de TODO lo que enseña el índice (lo usa la prueba de conexión).
static func entradas() -> Array:
	var salida: Array = []
	for m: Dictionary in MenusLaterales.MENUS:
		var subs: Array = m["subs"]
		for i in subs.size():
			salida.append([String(m["id"]), i, String((subs[i] as Dictionary).get("label", ""))])
	return salida

static func pintar(p: Principal, cuerpo: VBoxContainer, c: Club, acento: Color) -> void:
	var desliza := ScrollContainer.new()   ## son ~100 botones: solo aquí se desliza (con mando, el foco arrastra el desplazamiento)
	desliza.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desliza.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cuerpo.add_child(desliza)
	var rejilla := GridContainer.new()
	rejilla.columns = 4
	rejilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rejilla.add_theme_constant_override("h_separation", TableroInicio.SEP)
	rejilla.add_theme_constant_override("v_separation", TableroInicio.SEP)
	desliza.add_child(rejilla)
	rejilla.add_child(_grupo(Idiomas.t("Accesos"), "", [
		[Idiomas.t("Buscar jugadores y clubes"), func() -> void: EscaparatePantalla.de(p).abrir_busqueda(rejilla)],
		[Idiomas.t("Panel lateral (todos los menús)"), func() -> void: p._menu_lateral.alternar()]], acento, c))
	for m: Dictionary in MenusLaterales.MENUS:
		var botones: Array = []
		var subs: Array = m["subs"]
		for i in subs.size():
			var idx := i
			var id := String(m["id"])
			botones.append([Idiomas.t(String((subs[i] as Dictionary).get("label", ""))), func() -> void: p._menu_lateral.abrir_menu(id, idx)])
		rejilla.add_child(_grupo(Idiomas.t(String(m["nombre"])), String(m.get("icono", "")), botones, acento, c))
	for h in rejilla.get_children():
		(h as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL

## Un menú: su cabecera y sus submenús como botones (`[rótulo, acción]`).
static func _grupo(nombre: String, icono: String, botones: Array, acento: Color, c: Club) -> Control:
	var pc := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.05, 0.07, 0.09, 0.92)
	st.border_color = Color(1, 1, 1, 0.12)
	st.set_border_width_all(1)
	st.border_width_top = 3
	st.border_color = EscaparateBarra.color_de(c)
	st.set_corner_radius_all(6)
	st.content_margin_left = 10; st.content_margin_right = 10; st.content_margin_top = 8; st.content_margin_bottom = 10
	pc.add_theme_stylebox_override("panel", st)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	pc.add_child(v)
	var t := EstiloAvanzar.etiqueta(nombre.to_upper(), 20, Color.WHITE, true)
	v.add_child(t)
	for b: Array in botones:
		var bt := Button.new()
		bt.text = String(b[0])
		bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
		bt.clip_text = true
		bt.focus_mode = Control.FOCUS_ALL
		bt.custom_minimum_size = Vector2(120, 32)
		bt.add_theme_font_size_override("font_size", Tema.letra(16))
		bt.add_theme_color_override("font_color", Color.WHITE)
		bt.pressed.connect(b[1])
		v.add_child(bt)
	return pc
