class_name PreviaMenuPartido
extends RefCounted
## LA PREVIA DEL MENÚ DEL PARTIDO (17-11-2026, crítica de «Auditoría de sesiones» contra el PES 2020): la cabecera (los dos escudos con sombra y, en
## medio, el emblema con la competición y la jornada en una línea clara y debajo el estadio y la hora), las alineaciones en columnas (dorsal, nombre y
## puesto, el capitán marcado y la formación con la media bajo el nombre del club) y la fila de pestañas con su icono y el foco bien visible con mando.
## Lo monta `MenuPartido`.

## Iconos de trazo propios (24×24), dibujados en blanco y teñidos por el botón (los emoji salían con otra fuente y alguno como un recuadro).
const ICONOS := {
	"uniforme": '<path d="M8 3l-5 3 2 5 3-1v11h8V10l3 1 2-5-5-3c-1 2-2 3-4 3s-3-1-4-3z"/>',
	"estadio": '<ellipse cx="12" cy="14" rx="10" ry="5"/><ellipse cx="12" cy="14" rx="5" ry="2"/><path d="M2 14V9c0-3 4-5 10-5s10 2 10 5v5"/>',
	"saque": '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="6"/><path d="M12 9v6"/>',
	"plan": '<rect x="3" y="4" width="18" height="16" rx="1"/><path d="M12 4v16"/><circle cx="12" cy="12" r="2.5"/><path d="M6 9l2 2m0-2l-2 2M16 14l2 2m0-2l-2 2"/>',
	"opciones": '<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M4.9 19.1L7 17M17 7l2.1-2.1"/>',
	"camara": '<rect x="2" y="7" width="14" height="11" rx="2"/><path d="M16 11l6-3v9l-6-3z"/>',
}
static var _iconos := {}

static func icono(clave: String) -> Texture2D:
	if not _iconos.has(clave):
		var svg := '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="44" height="44" fill="none" stroke="#ffffff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">%s</svg>' % String(ICONOS.get(clave, ""))
		var img := Image.new()
		img.load_svg_from_string(svg)
		_iconos[clave] = ImageTexture.create_from_image(img)
	return _iconos[clave]
const SUAVE := Color(1, 1, 1, 0.62)
const ORO := Color("f5c542")

## La hora del saque, coherente con la luz del día del clima (noche, tarde, mediodía); con mal tiempo, una de las de siempre según el partido.
static func hora(p: Partido, clima: Dictionary) -> String:
	match String(clima.get("clave", "")):
		"noche": return "21:00"
		"tarde": return "18:00"
		"dia": return "13:00"
	return ["16:00", "17:30", "19:00", "20:30"][absi((p.local.id + p.visita.id).hash()) % 4]

## «Primera División · Jornada 12» (fuera de la liga, solo la competición).
static func linea_competicion(m: MenuPartido) -> String:
	var nombre := Nombres.visible(m.liga_rival.nombre) if m.liga_rival != null and m.competicion == "Liga" else Idiomas.t(m.competicion)
	if m.competicion == "Liga" and m.liga_rival != null:
		return "%s · %s" % [nombre, Idiomas.t("Jornada %d") % (m.liga_rival.jornada_actual + 1)]
	return nombre

static func linea_estadio(m: MenuPartido) -> String:
	var l := m.partido.local
	var est := l.estadio_nombre if l.estadio_nombre != "" else Idiomas.t("Estadio de %s") % l.nombre
	return "%s · %s" % [Nombres.visible(est), hora(m.partido, m.clima)]

## Un escudo con su sombra suave (una copia oscura y desplazada debajo): el mismo acabado para los dos.
static func escudo(c: Club, px: int) -> Control:
	var caja := Control.new()
	caja.custom_minimum_size = Vector2(px, px)
	caja.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for sombra in [true, false]:
		var t := TextureRect.new()
		t.texture = Escudo.textura(c, px)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.set_anchors_preset(Control.PRESET_FULL_RECT)
		if sombra:
			t.modulate = Color(0, 0, 0, 0.45)
			t.position = Vector2(5, 8)
		else:
			t.self_modulate = Color(0.94, 0.94, 0.94)   ## un punto menos de brillo: no gritan al lado del resto
		caja.add_child(t)
	return caja

static func cabecera(m: MenuPartido, l: Club, v: Club) -> void:
	var mv := m.movil   ## el teléfono: todo más pequeño (el lienzo es ~1067×480)
	var c := m._caja(0.25, 0.75, 0.015, 0.22) if mv else m._caja(0.25, 0.75, 0.025, 0.25)
	var f := HBoxContainer.new()
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	f.alignment = BoxContainer.ALIGNMENT_CENTER
	f.add_theme_constant_override("separation", 20 if mv else 40)
	c.add_child(f)
	f.add_child(escudo(l, 90 if mv else 150))
	var centro := VBoxContainer.new()
	centro.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_theme_constant_override("separation", 4)
	centro.custom_minimum_size = Vector2(240 if mv else 300, 0)
	f.add_child(centro)
	var em := MiniaturaMenu.new()
	em.tipo = MiniaturaMenu.Tipo.EMBLEMA
	em.custom_minimum_size = Vector2(36, 36) if mv else Vector2(64, 64)
	em.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	centro.add_child(em)
	for par: Array in [[linea_competicion(m), 16 if mv else 22, Color.WHITE, true], [linea_estadio(m), 13 if mv else 16, SUAVE, false]]:
		var e := EstiloAvanzar.etiqueta(String(par[0]), int(par[1]), par[2], bool(par[3]), bool(par[3]))
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		centro.add_child(e)
	f.add_child(escudo(v, 90 if mv else 150))

## Los dos onces en columnas: dorsal · nombre · puesto; bajo el nombre del club, la formación y la media.
static func alineaciones(m: MenuPartido, l: Club, v: Club) -> void:
	var mv := m.movil
	var c := m._caja(0.27, 0.73, 0.23, 0.845) if mv else m._caja(0.29, 0.71, 0.27, 0.83)
	var f := HBoxContainer.new()
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	f.alignment = BoxContainer.ALIGNMENT_CENTER
	f.add_theme_constant_override("separation", 24 if mv else 56)
	c.add_child(f)
	for club: Club in [l, v]:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 2)
		var n := EstiloAvanzar.etiqueta(Nombres.visible(club.nombre).to_upper(), 22 if mv else 40, Color.WHITE, true)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.clip_text = mv
		col.add_child(n)
		var sub := EstiloAvanzar.etiqueta("%s · %s %d" % [club.tactica.formacion, Idiomas.t("Media"), roundi(club.media())], 13 if mv else 16, ORO, true)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(sub)
		var g := GridContainer.new()
		g.columns = 3
		g.add_theme_constant_override("h_separation", 8 if mv else 14)
		g.add_theme_constant_override("v_separation", 0 if mv else 3)
		g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(g)
		var cinta := capitan_en_campo(club)
		for j: Jugador in club.once():
			var d := EstiloAvanzar.etiqueta(str(j.dorsal) if j.dorsal > 0 else "", 13 if mv else 18, SUAVE, true)
			d.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			d.custom_minimum_size = Vector2(20 if mv else 30, 0)
			g.add_child(d)
			g.add_child(_nombre(j, j.id == cinta, 14 if mv else 19))
			g.add_child(EstiloAvanzar.etiqueta(j.pos_e, 13 if mv else 16, SUAVE, true))
		f.add_child(col)

## Quién lleva la cinta en este once: la misma regla que el partido 3D (`Puente3D.once`): el capitán si juega; si no, el veterano de más media.
static func capitan_en_campo(c: Club) -> String:
	var once: Array[Jugador] = []
	once.assign(c.once())
	var mapa: Dictionary = load("res://visor/puente3d.gd").once(once)["jugadores"]
	for id: String in mapa:
		if bool((mapa[id] as Dictionary).get("capitan", false)):
			return id
	return ""

## «R. GUTIÉRREZ» y, si es el capitán, su brazalete «C» dorado al lado.
static func _nombre(j: Jugador, con_cinta: bool, letra := 19) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var txt := MenuPartido.linea_jugador(j).replace(" (POR)", "").replace(" (C)", "")
	h.add_child(EstiloAvanzar.etiqueta(txt, letra, Color(1, 1, 1, 0.94), true))
	if con_cinta:
		var c := EstiloAvanzar.etiqueta("C", 11, Color("1a1300"), true)
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		c.custom_minimum_size = Vector2(16, 16)
		var sb := Tema.caja(ORO, 3)
		sb.content_margin_top = 0
		sb.content_margin_bottom = 0
		sb.content_margin_left = 4
		sb.content_margin_right = 4
		c.add_theme_stylebox_override("normal", sb)
		c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(c)
	return h

## Una pestaña: su icono y su nombre; la elegida, blanca con la raya de acento; con el foco (mando), un borde claro grueso y un brillo.
static func pestana(clave: String, texto: String) -> Button:
	var b := Button.new()
	b.text = Idiomas.t(texto)
	b.icon = icono(clave)
	b.expand_icon = false
	b.add_theme_constant_override("icon_max_width", Tema.letra(24))
	b.add_theme_constant_override("h_separation", 10)
	for k in ["icon_normal_color", "icon_hover_color", "icon_focus_color"]:
		b.add_theme_color_override(k, Color("26304f"))
	for k in ["icon_pressed_color", "icon_hover_pressed_color"]:
		b.add_theme_color_override(k, PanelesMenuPartido.ROJO)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.toggle_mode = true
	b.add_theme_font_override("font", EstiloAvanzar.fuente_titulo())
	b.add_theme_font_size_override("font_size", Tema.letra(20))
	var n := PanelesMenuPartido._estilo(Color(0.86, 0.88, 0.94, 0.9))
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", PanelesMenuPartido._estilo(Color(0.93, 0.94, 0.98, 0.95)))
	var sel := PanelesMenuPartido._estilo(Color.WHITE)
	sel.border_color = PanelesMenuPartido.ROJO
	sel.border_width_bottom = 4
	sel.shadow_color = Color(1, 1, 1, 0.35)
	sel.shadow_size = 10
	for k in ["pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(k, sel)
	var foco := PanelesMenuPartido._estilo(Color(0, 0, 0, 0))
	foco.draw_center = false
	foco.border_color = ORO
	foco.set_border_width_all(4)
	foco.shadow_color = Color(ORO, 0.45)
	foco.shadow_size = 12
	foco.expand_margin_left = 3
	foco.expand_margin_right = 3
	foco.expand_margin_top = 3
	foco.expand_margin_bottom = 3
	b.add_theme_stylebox_override("focus", foco)
	for k in ["font_color", "font_hover_color", "font_focus_color"]:
		b.add_theme_color_override(k, Color("26304f"))
	for k in ["font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, PanelesMenuPartido.ROJO)
	return b

## La cabecera de cada pestaña a pantalla completa, como el PES: su icono, el nombre grande, a la derecha cómo pasar de pestaña y volver (con el aparato
## que se usa) y un «Volver» que se puede tocar. Nodos con nombre: «Icono» y «Titulo» (los rellena `MenuPartido._abrir`).
static func cabecera_panel(m: MenuPartido) -> HBoxContainer:
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 16)
	var ic := TextureRect.new()
	ic.name = "Icono"
	ic.custom_minimum_size = Vector2(Tema.letra(40), Tema.letra(40))
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.self_modulate = Color("e0309a")
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cab.add_child(ic)
	var t := EstiloAvanzar.etiqueta("", 26 if m.movil else 38, Color.WHITE, true, true)
	t.name = "Titulo"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(t)
	var guia := EstiloAvanzar.etiqueta(guia_pestanas() if not m.movil or Mando.hay_mando() else "", 15, SUAVE)
	guia.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cab.add_child(guia)
	var volver := Button.new()
	volver.text = "◂  " + Idiomas.t("Volver")
	volver.focus_mode = Control.FOCUS_NONE   ## con mando se vuelve con B: el foco se queda en el panel
	volver.add_theme_font_override("font", EstiloAvanzar.fuente_titulo())
	volver.add_theme_font_size_override("font_size", Tema.letra(18))
	volver.add_theme_stylebox_override("normal", PanelesMenuPartido._estilo(Color("243656")))
	volver.add_theme_stylebox_override("hover", PanelesMenuPartido._estilo(Color("34497a")))
	volver.pressed.connect(m.cerrar_panel)
	cab.add_child(volver)
	return cab

## «LB ◂ ▸ RB pestaña · B volver» con mando; «Q ◂ ▸ E pestaña · Esc volver» con teclado; nada en táctil (se tocan las pestañas).
static func guia_pestanas() -> String:
	if Mando.hay_mando():
		return Idiomas.t("LB ◂ ▸ RB pestaña · B volver")
	if DisplayServer.is_touchscreen_available():
		return ""
	return Idiomas.t("Q ◂ ▸ E pestaña · Esc volver")

## −1 / +1 si el evento pasa de pestaña (LB / RB del mando, Q / E del teclado); 0 si no.
static func paso_pestana(e: InputEvent) -> int:
	if e is InputEventJoypadButton and (e as InputEventJoypadButton).pressed:
		match (e as InputEventJoypadButton).button_index:
			JOY_BUTTON_LEFT_SHOULDER: return -1
			JOY_BUTTON_RIGHT_SHOULDER: return 1
	if e is InputEventKey and (e as InputEventKey).pressed and not (e as InputEventKey).echo:
		match (e as InputEventKey).keycode:
			KEY_Q: return -1
			KEY_E: return 1
	return 0

## La pestaña de al lado (en círculo). «Plan de juego» abre otra pantalla: al pasar con LB/RB se salta (se entra pulsándola).
static func vecina(actual: String, paso: int) -> String:
	var claves: Array = []
	for par: Array in MenuPartido.PESTANAS:
		if String(par[0]) != "plan":
			claves.append(String(par[0]))
	var i := claves.find(actual)
	if i < 0:
		return String(claves[0] if paso > 0 else claves[-1])
	return String(claves[posmod(i + paso, claves.size())])

## Con mando, el foco entra en el primer control del panel (si no hay ninguno, se queda en su pestaña).
static func enfocar_panel(cuerpo: Control, pestana: Control) -> void:
	for n in cuerpo.find_children("*", "Control", true, false):
		var c := n as Control
		if c.focus_mode == Control.FOCUS_ALL and c.is_visible_in_tree() and not c.is_queued_for_deletion():   ## (17-11) no los de la pestaña anterior, que se están borrando
			c.grab_focus()
			return
	if is_instance_valid(pestana):
		pestana.grab_focus()
