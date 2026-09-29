class_name MenuLateral
extends Control
## EL PANEL LATERAL (29-9-2026, mapa de metas 23). Pedido del usuario, con
## Soccer Manager de ejemplo: un apartado a la izquierda del menú central, por
## encima de él, que se toca o se desliza, con los accesos a los menús grandes
## -Historia, Gente, Mi Carrera, Operaciones, Mi Vida, Editar, Ajustes, Ciudad
## 3D y Estadio 3D- y a cada uno de sus submenús. Tocar un menú o un submenú
## abre su `PantallaMenu`, a pantalla completa y con su fondo animado.
##
## Plegado es un riel de iconos; desplegado (tocando ☰, o arrastrando hacia la
## derecha) muestra cada menú con sus submenús. Arrastrar hacia la izquierda, o
## tocar fuera, lo vuelve a plegar.

const ANCHO_RIEL := 62.0
const ANCHO_ABIERTO := 310.0

## Cada menú: icono, nombre, estilo del fondo (`fondo_menu.gdshader`), sus tres
## colores y sus submenús -chips de siempre ({tab, secc, label}) o acciones-.
const MENUS := [
	{"id": "historia", "icono": "📜", "nombre": "Historia", "estilo": 0,
		"lema": "Lo que el club fue y lo que tú estás escribiendo.",
		"colores": ["#140d07", "#2a1d10", "#e0a95a"], "subs": [
		{"tab": "Legado", "label": "Historia del club", "icono": "🏛️", "desc": "Fundación, épocas doradas, clásicos y tu legado."},
		{"tab": "Récords", "secc": "records", "label": "Récords", "icono": "📈", "desc": "Goleadores, rachas y marcas de todos los tiempos."},
		{"tab": "Récords", "secc": "memoria", "label": "Memoria", "icono": "🕯️", "desc": "El salón de la fama y los que ya no están."},
		{"tab": "Récords", "secc": "rivales", "label": "Rivales", "icono": "⚔️", "desc": "Clásicos, cara a cara y cuentas pendientes."},
		{"tab": "Récords", "secc": "vitrina", "label": "Vitrina", "icono": "🏆", "desc": "Cada trofeo, con su año y su historia."},
		{"tab": "Cantera", "label": "Linaje", "icono": "🌱", "desc": "Las generaciones que salieron de casa."},
		{"tab": "Logros", "label": "Logros", "icono": "🎖️", "desc": "Lo que conseguiste como gestor."},
		{"tab": "Desafíos", "label": "Desafíos", "icono": "🎯", "desc": "Retos de temporada con premio."},
		{"tab": "Premios", "label": "Premios", "icono": "🥇", "desc": "Balones de oro, mejores DT y equipos ideales."},
		{"accion": "album", "label": "Álbum y museo", "icono": "📒", "desc": "Cromos y títulos de todas tus carreras."}]},
	{"id": "gente", "icono": "👥", "nombre": "Gente", "estilo": 1,
		"lema": "Las personas que hacen el club, dentro y fuera del campo.",
		"colores": ["#1a0f0c", "#2e1a14", "#ff9f5a"], "subs": [
		{"tab": "Club", "secc": "staff", "label": "Personal del club", "icono": "🧑‍💼", "desc": "Cuerpo técnico, médicos, ojeadores y analistas."},
		{"tab": "Gente", "secc": "personas", "label": "La gente del club", "icono": "🤝", "desc": "Utileros, cocineros, la señora del kiosco..."},
		{"tab": "Gente", "secc": "identidad", "label": "Identidad visual", "icono": "🎨", "desc": "Colores, escudo, apodo y tipografía."},
		{"tab": "Gente", "secc": "kits", "label": "Equipación", "icono": "👕", "desc": "El diseñador de camisetas, a pantalla completa."},
		{"tab": "Camarín", "label": "Camarín", "icono": "🚪", "desc": "Clima del vestuario, camarillas y capitanes."}]},
	{"id": "carrera", "icono": "🎓", "nombre": "Mi Carrera", "estilo": 2,
		"lema": "Tu camino como entrenador: rol, habilidades y reputación.",
		"colores": ["#0f0d06", "#211b0b", "#f2c84b"], "subs": [
		{"tab": "Club", "secc": "carrera", "label": "Mi carrera", "icono": "🧭", "desc": "Tu rol, tu currículum y el siguiente escalón."},
		{"tab": "Habilidades", "label": "Árbol de habilidades", "icono": "🌳", "desc": "Aprende técnicas y sube de nivel."},
		{"tab": "Correo", "label": "Correo", "icono": "✉️", "desc": "Mensajes del club, agentes y la federación."},
		{"tab": "Federación", "label": "Normas y federación", "icono": "⚖️", "desc": "Reglamento, licencias, votaciones y árbitros."}]},
	{"id": "operaciones", "icono": "📊", "nombre": "Operaciones", "estilo": 3,
		"lema": "La hinchada, los medios y los números del día a día.",
		"colores": ["#061218", "#0b2230", "#3fd0ff"], "subs": [
		{"tab": "Estadio", "label": "Hinchada y socios", "icono": "📣", "desc": "Ánimo, socios, peñas y días del hincha."},
		{"tab": "Redes", "secc": "redes", "label": "Feed de redes", "icono": "📱", "desc": "Lo que se dice del club en Tribuna."},
		{"tab": "Redes", "secc": "prensa", "label": "Sala de prensa", "icono": "🎙️", "desc": "Periodistas, medios propios y derechos de TV."},
		{"tab": "Redes", "secc": "debate", "label": "El ruido de fuera", "icono": "📺", "desc": "Mesas de debate y portadas."},
		{"tab": "Comparar", "label": "Comparar", "icono": "⚖️", "desc": "Jugadores cara a cara."}]},
	{"id": "vida", "icono": "🌅", "nombre": "Mi Vida", "estilo": 4,
		"lema": "Lo que pasa cuando se apagan los focos.",
		"colores": ["#1b0f1f", "#0d0a18", "#ff7e5f"], "subs": [
		{"tab": "Vida", "secc": "bienestar", "label": "Bienestar", "icono": "🧘", "desc": "Estrés, descanso y salud del entrenador."},
		{"tab": "Vida", "secc": "hogar", "label": "Casa y auto", "icono": "🏡", "desc": "Dónde vives y en qué te mueves."},
		{"tab": "Vida", "secc": "familia", "label": "Familia", "icono": "👨‍👩‍👧", "desc": "Los tuyos, sus planes y sus quejas."},
		{"accion": "casa", "label": "Ver tu casa", "icono": "🛋️", "desc": "Tu terraza en 3D, con café y paisaje."},
		{"accion": "movil", "label": "Abrir el móvil", "icono": "📲", "desc": "Tribuna, mensajes, banco y tus fotos."}]},
	{"id": "editar", "icono": "✏️", "nombre": "Editar", "estilo": 5, "ficha": false,
		"lema": "El mundo a tu medida: ligas, clubes y jugadores.",
		"colores": ["#06162e", "#0b2447", "#8fd3ff"], "subs": [
		{"tab": "Editor", "label": "Editor del mundo", "icono": "🛠️", "desc": "Competiciones, clubes, jugadores y CSV."}]},
	{"id": "ajustes", "icono": "⚙️", "nombre": "Ajustes", "estilo": 6, "ficha": false,
		"lema": "Cómo se ve, cómo suena y cómo se juega.",
		"colores": ["#0c0e12", "#171b22", "#a8b4c8"], "subs": [
		{"tab": "Ajustes", "secc": "pantalla", "label": "Dispositivo", "icono": "🖥️", "desc": "Pantalla, calidad gráfica, mando y fotogramas."},
		{"tab": "Ajustes", "secc": "audio", "label": "Sonido", "icono": "🔊", "desc": "Música, efectos y el ruido del estadio."},
		{"tab": "Ajustes", "secc": "aspecto", "label": "Interfaz", "icono": "🖌️", "desc": "Paletas, fondos, idioma y estilo del menú."}]},
	{"id": "ciudad", "icono": "🏙️", "nombre": "Ciudad 3D", "estilo": 7, "ficha": false,
		"lema": "La ciudad que rodea tu estadio.",
		"colores": ["#070a16", "#141a33", "#ffd27a"], "subs": [
		{"tab": "Ciudad", "label": "Diseño de la ciudad", "icono": "🗺️", "desc": "Terrenos, negocios, conciertos y el municipio."},
		{"accion": "ver_ciudad", "label": "Recorrerla en 3D", "icono": "🚗", "desc": "Vuela sobre tu ciudad, de día o de noche."}]},
	{"id": "estadio", "icono": "🏟️", "nombre": "Estadio 3D", "estilo": 8, "ficha": false,
		"lema": "Tu casa: cada tribuna, cada foco, cada butaca.",
		"colores": ["#060d09", "#1f6b38", "#e8f4ff"], "subs": [
		{"tab": "Estadio", "label": "Diseño del estadio", "icono": "📐", "desc": "Estilos completos y colores por sección."},
		{"tab": "Club", "secc": "infra", "label": "Infraestructura", "icono": "🏗️", "desc": "Obras, ciudad deportiva y academia."},
		{"accion": "ver_estadio", "label": "Verlo en 3D", "icono": "👁️", "desc": "Tu estadio tal y como se juega."}]},
]

## Un dato vivo para la tarjeta de cada submenú en la portada del menú.
static func dato(p: Principal, sub: Dictionary) -> String:
	var m := p.mundo
	if m == null or m.mi_club() == null:
		return ""
	var c := m.mi_club()
	match String(sub.get("label", "")):
		"Correo":
			var n := 0
			for x: Dictionary in p.get("_bandeja"):
				if not bool(x.get("leido", false)):
					n += 1
			return "%d sin leer" % n if n > 0 else "Al día"
		"Vitrina", "Historia del club":
			return "%d títulos" % (m.roles.trofeos.size() if m.roles != null else 0)
		"Hinchada y socios":
			return "%s socios" % p._miles(c.socios if c.socios > 0 else c.estadio_aforo)
		"Diseño del estadio":
			return "%s butacas" % p._miles(c.estadio_aforo)
		"Camarín", "Personal del club":
			return "%d jugadores" % c.plantilla.size()
		"Feed de redes":
			return "%s seguidores" % p._miles(m.prensa.seguidores) if m.prensa != null else ""
		"Mi carrera":
			return m.roles.nombre if m.roles != null else ""
	return ""

## Los grupos de la barra de arriba que ahora viven aquí (la barra se queda
## con CENTRAL y CLUB).
const EN_PANEL := ["gente", "historia", "operaciones", "vida", "ajustes"]

var _p: Principal
var _riel: VBoxContainer
var _cajon: PanelContainer
var _lista: VBoxContainer
var _velo: ColorRect
var _abierto := false
var _arrastre := 0.0
var pantalla_abierta: PantallaMenu
var _botones_riel := {}

static func crear(p: Principal) -> MenuLateral:
	var m := MenuLateral.new()
	m._p = p
	m.name = "MenuLateral"
	m._montar()
	return m

static func menu_por_id(id: String) -> Dictionary:
	for m: Dictionary in MENUS:
		if String(m["id"]) == id:
			return m
	return {}

## Las acciones que no son una pantalla de la interfaz.
static func ejecutar(p: Principal, accion: String) -> void:
	match accion:
		"casa":
			CasaEscena3D.abrir(p, p.mundo, p.get("_bandeja"))
		"movil":
			Telefono.abrir(p, p.mundo)
		"ver_estadio":
			p._ver_estadio_propio()
		"ver_ciudad":
			p._ver_ciudad_propia()
		"album":
			PanelMeta.abrir(p, p.mundo)

func _montar() -> void:
	set_anchors_preset(Control.PRESET_LEFT_WIDE)
	offset_right = ANCHO_RIEL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	## El velo oscurece el resto al abrir el cajón, y tocarlo lo cierra.
	_velo = ColorRect.new()
	_velo.color = Color(0, 0, 0, 0.0)
	_velo.visible = false
	_velo.mouse_filter = Control.MOUSE_FILTER_STOP
	_velo.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			plegar())
	add_child(_velo)
	var fondo_riel := PanelContainer.new()
	fondo_riel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	fondo_riel.offset_right = ANCHO_RIEL
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.02, 0.03, 0.04, 0.9)
	st.border_color = Color(1, 1, 1, 0.08)
	st.border_width_right = 1
	fondo_riel.add_theme_stylebox_override("panel", st)
	fondo_riel.mouse_filter = Control.MOUSE_FILTER_STOP
	fondo_riel.gui_input.connect(_al_arrastrar)
	add_child(fondo_riel)
	_riel = VBoxContainer.new()
	_riel.add_theme_constant_override("separation", 6)
	_riel.alignment = BoxContainer.ALIGNMENT_BEGIN
	fondo_riel.add_child(_riel)
	var hamb := _boton_riel("☰", "Abrir el panel (o deslizar hacia la derecha)")
	hamb.pressed.connect(alternar)
	_riel.add_child(hamb)
	_riel.add_child(HSeparator.new())
	for m: Dictionary in MENUS:
		var b := _boton_riel(String(m["icono"]), String(m["nombre"]))
		var id := String(m["id"])
		b.toggle_mode = true
		b.pressed.connect(func() -> void: abrir_menu(id, -1))
		_riel.add_child(b)
		_botones_riel[id] = b

	## EL CAJÓN: cada menú con sus submenús.
	_cajon = PanelContainer.new()
	_cajon.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_cajon.offset_left = ANCHO_RIEL
	_cajon.offset_right = ANCHO_RIEL + ANCHO_ABIERTO
	var sc := StyleBoxFlat.new()
	sc.bg_color = Color(0.03, 0.045, 0.06, 0.97)
	sc.border_color = Color(1, 1, 1, 0.1)
	sc.border_width_right = 1
	sc.shadow_color = Color(0, 0, 0, 0.5)
	sc.shadow_size = 18
	sc.content_margin_left = 10; sc.content_margin_right = 10; sc.content_margin_top = 12
	_cajon.add_theme_stylebox_override("panel", sc)
	_cajon.visible = false
	_cajon.mouse_filter = Control.MOUSE_FILTER_STOP
	_cajon.gui_input.connect(_al_arrastrar)
	add_child(_cajon)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_cajon.add_child(scroll)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 2)
	scroll.add_child(_lista)
	for m: Dictionary in MENUS:
		var id := String(m["id"])
		var cab := Button.new()
		cab.text = "%s  %s" % [String(m["icono"]), String(m["nombre"]).to_upper()]
		cab.alignment = HORIZONTAL_ALIGNMENT_LEFT
		cab.flat = true
		cab.add_theme_font_size_override("font_size", 15)
		cab.add_theme_color_override("font_color", Color(String((m["colores"] as Array)[2])).lightened(0.2))
		cab.pressed.connect(func() -> void: abrir_menu(id, -1))
		_lista.add_child(cab)
		var subs: Array = m["subs"]
		for i in subs.size():
			var sb := Button.new()
			sb.text = "      %s%s" % ["▶ " if (subs[i] as Dictionary).has("accion") else "", String(subs[i]["label"])]
			sb.alignment = HORIZONTAL_ALIGNMENT_LEFT
			sb.flat = true
			sb.add_theme_font_size_override("font_size", 12)
			sb.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
			var k := i
			sb.pressed.connect(func() -> void: abrir_menu(id, k))
			_lista.add_child(sb)
		_lista.add_child(HSeparator.new())

func _boton_riel(texto: String, tip: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.tooltip_text = tip
	b.flat = true
	## El del menú abierto queda marcado con una franja a la izquierda.
	var marcado := StyleBoxFlat.new()
	marcado.bg_color = Color(1, 1, 1, 0.1)
	marcado.border_color = Color(1, 1, 1, 0.85)
	marcado.border_width_left = 4
	b.add_theme_stylebox_override("pressed", marcado)
	b.add_theme_stylebox_override("hover_pressed", marcado)
	b.custom_minimum_size = Vector2(ANCHO_RIEL, 50)
	b.add_theme_font_size_override("font_size", 24)
	return b

func _al_arrastrar(e: InputEvent) -> void:
	var dx := 0.0
	if e is InputEventScreenDrag:
		dx = (e as InputEventScreenDrag).relative.x
	elif e is InputEventMouseMotion and ((e as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		dx = (e as InputEventMouseMotion).relative.x
	elif e is InputEventMouseButton and not (e as InputEventMouseButton).pressed:
		_arrastre = 0.0
		return
	if dx == 0.0:
		return
	_arrastre += dx
	if _arrastre > 40.0 and not _abierto:
		desplegar()
		_arrastre = 0.0
	elif _arrastre < -40.0 and _abierto:
		plegar()
		_arrastre = 0.0

func alternar() -> void:
	if _abierto:
		plegar()
	else:
		desplegar()

func desplegar() -> void:
	if _abierto:
		return
	_abierto = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_velo.visible = true
	_velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cajon.visible = true
	_cajon.modulate.a = 0.0
	_cajon.position.x = ANCHO_RIEL - 40.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_cajon, "modulate:a", 1.0, 0.18)
	tw.tween_property(_cajon, "position:x", ANCHO_RIEL, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_velo, "color:a", 0.45, 0.2)

func plegar() -> void:
	if not _abierto:
		return
	_abierto = false
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_cajon, "modulate:a", 0.0, 0.15)
	tw.tween_property(_velo, "color:a", 0.0, 0.15)
	tw.chain().tween_callback(func() -> void:
		_cajon.visible = false
		_velo.visible = false
		set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
		offset_right = ANCHO_RIEL)

func abierto() -> bool:
	return _abierto

## Abre el menú `id` a pantalla completa: en su portada (`sub` = -1) o
## directamente en el submenú `sub`. Si ya hay uno abierto se cierra antes
## (una sola mudanza a la vez); si es el mismo menú, solo cambia de submenú.
func abrir_menu(id: String, sub: int = -1) -> PantallaMenu:
	plegar()
	var m := menu_por_id(id)
	if m.is_empty() or _p.mundo == null:
		return null
	var subs: Array = m["subs"]
	var es_accion: bool = sub >= 0 and sub < subs.size() and (subs[sub] as Dictionary).has("accion")
	if is_instance_valid(pantalla_abierta) and String(pantalla_abierta.get_meta("id", "")) == id:
		if sub < 0:
			pantalla_abierta.portada()
		else:
			pantalla_abierta.elegir(sub)
		return pantalla_abierta
	if is_instance_valid(pantalla_abierta):
		pantalla_abierta.cerrar()
	pantalla_abierta = PantallaMenu.abrir(_p, m, -1 if es_accion else sub)
	pantalla_abierta.cerrada.connect(_marcar_riel.bind(""))
	## El panel queda por encima de la pantalla del menú.
	get_parent().move_child(self, get_parent().get_child_count() - 1)
	_marcar_riel(id)
	if es_accion:
		ejecutar(_p, String(subs[sub]["accion"]))
	return pantalla_abierta

func _marcar_riel(id: String) -> void:
	for k: String in _botones_riel:
		(_botones_riel[k] as Button).set_pressed_no_signal(k == id)

## El menú de al lado, en el orden del riel (L2/R2 con un menú abierto).
func menu_vecino(paso: int) -> void:
	var i := 0
	if is_instance_valid(pantalla_abierta):
		for k in MENUS.size():
			if String(MENUS[k]["id"]) == String(pantalla_abierta.get_meta("id", "")):
				i = k
	i = (i + paso + MENUS.size()) % MENUS.size()
	abrir_menu(String(MENUS[i]["id"]), -1)

## Hay algo del panel encima del menú central (el cajón o un menú abierto).
func ocupado() -> bool:
	return _abierto or is_instance_valid(pantalla_abierta)

func _unhandled_input(e: InputEvent) -> void:
	## Con el cajón abierto, Esc lo pliega antes que nada.
	if _abierto and e.is_action_pressed("ui_cancel"):
		plegar()
		get_viewport().set_input_as_handled()
